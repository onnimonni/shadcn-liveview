import fs from "node:fs/promises"
import path from "node:path"
import * as parse5 from "parse5"
import { isValidElement, type ReactNode } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import { fixtures, type ComponentFixture } from "./fixtures"

export interface ParityResult {
  name: string
  title: string
  passed: boolean
  differences?: string[]
}

interface CleanNode {
  tag?: string
  type: "element" | "text"
  value?: string
  attrs: Record<string, string>
  classes: Set<string>
  children: CleanNode[]
}

function cleanDom(node: parse5.DefaultTreeAdapterMap["node"]): CleanNode | null {
  if (parse5.defaultTreeAdapter.isTextNode(node)) {
    const text = node.value.replace(/\s+/g, " ").trim()
    return text ? { type: "text", value: text, attrs: {}, classes: new Set(), children: [] } : null
  }

  if (!parse5.defaultTreeAdapter.isElementNode(node)) {
    return null
  }

  const attrs: Record<string, string> = {}
  let classes = new Set<string>()

  for (const attr of node.attrs) {
    if (attr.name.startsWith("phx-") || attr.name.startsWith("data-vaul-")) continue
    let attrName = attr.name === "htmlFor" ? "for" : attr.name
    const ignored: Record<string, true> = {
      tabler: true,
      hugeicons: true,
      phosphor: true,
      remixicon: true,
      lucide: true,
      "data-radix-collection-item": true,
    }
    if (ignored[attrName]) continue
    let val = attr.value.trim()
    if (attrName === "class") {
      classes = new Set(val.split(/\s+/).filter(Boolean))
      attrs[attrName] = [...classes].sort().join(" ")
    } else if (attrName === "style") {
      const decls = val
        .split(";")
        .map((s) => s.trim().replace(/\s*:\s*/g, ":"))
        .filter(Boolean)
        .sort()
        .join(";")
      attrs[attrName] = decls
    } else {
      // IDs are resolved document-wide after cleaning, not independently per attribute.
      attrs[attrName] = val
    }
  }

  const children: CleanNode[] = []
  for (const child of node.childNodes) {
    const c = cleanDom(child)
    if (c) children.push(c)
  }

  return {
    tag: node.nodeName.toLowerCase(),
    type: "element",
    attrs,
    classes,
    children,
  }
}

const idReferenceAttributes = new Set([
  "aria-controls",
  "aria-describedby",
  "aria-labelledby",
  "aria-activedescendant",
  "aria-details",
  "aria-errormessage",
  "aria-flowto",
  "aria-owns",
  "for",
  "form",
  "list",
  "headers",
  "itemref",
  "popovertarget",
  "commandfor",
])

function explicitFixtureIds(node: ReactNode, ids = new Set<string>()): Set<string> {
  if (Array.isArray(node)) {
    for (const child of node) explicitFixtureIds(child, ids)
  } else if (isValidElement<{ id?: string; children?: ReactNode }>(node)) {
    if (typeof node.props.id === "string") ids.add(node.props.id.trim())
    // Caller-supplied references can target elements outside this SSR fragment.
    for (const [prop, value] of Object.entries(node.props)) {
      if (typeof value !== "string") continue
      const attribute = prop === "htmlFor" ? "for" : prop.toLowerCase()
      if (idReferenceAttributes.has(attribute)) {
        for (const id of value.split(/\s+/).filter(Boolean)) ids.add(id)
      } else if ((attribute === "href" || attribute === "xlinkhref") && value.startsWith("#")) {
        ids.add(value.slice(1))
      }
    }
    explicitFixtureIds(node.props.children, ids)
  }
  return ids
}

function isGeneratedId(id: string, explicitIds: Set<string>): boolean {
  if (explicitIds.has(id)) return false
  return /^radix-\S+$/.test(id) ||
    /^:[Rr][0-9a-zA-Z]+:(?:-\S+)?$/.test(id) ||
    /^_[Rr]_[0-9a-zA-Z]+_(?:-\S+)?$/.test(id)
}

function cleanDocument(
  fragment: parse5.DefaultTreeAdapterMap["documentFragment"],
  explicitIds: Set<string>,
  source: string,
  diffs: string[]
): CleanNode[] {
  const roots = fragment.childNodes.map(cleanDom).filter((node): node is CleanNode => node !== null)
  const elements: { node: CleanNode; path: string }[] = []
  function visit(node: CleanNode, nodePath: string): void {
    if (node.type === "element") elements.push({ node, path: nodePath })
    node.children.forEach((child, i) => visit(child, `${nodePath}/${child.tag || "text"}[${i}]`))
  }
  roots.forEach((node, i) => visit(node, `${source}[${i}]`))

  // Anchor generated identities to declarations first, so a forward reference cannot
  // disguise a swapped target. Literal IDs stay literal, including supplied radix IDs.
  const declarations = new Map<string, string>()
  const generated = new Map<string, string>()
  for (const { node, path: nodePath } of elements) {
    const id = node.attrs.id
    if (id === undefined) continue
    const firstPath = declarations.get(id)
    if (firstPath !== undefined) {
      diffs.push(`${nodePath}: duplicate ID "${id}" in ${source} (first declared at ${firstPath})`)
    } else {
      declarations.set(id, nodePath)
      if (isGeneratedId(id, explicitIds)) {
        generated.set(id, JSON.stringify(["generated", generated.size]))
      }
    }
  }

  // Closed portals can reference generated identities absent from SSR. Keep those
  // distinct and shared across references, but never equate them to mounted targets.
  const unmounted = new Map<string, string>()
  function identity(id: string): string {
    const declared = generated.get(id)
    if (declared !== undefined) return declared
    if (isGeneratedId(id, explicitIds)) {
      let absent = unmounted.get(id)
      if (absent === undefined) {
        absent = JSON.stringify(["unmounted-generated", unmounted.size])
        unmounted.set(id, absent)
      }
      return absent
    }
    return JSON.stringify(["literal", id])
  }

  for (const { node } of elements) {
    for (const [name, value] of Object.entries(node.attrs)) {
      if (name === "id") {
        node.attrs[name] = identity(value)
      } else if (idReferenceAttributes.has(name)) {
        node.attrs[name] = JSON.stringify(value.split(/\s+/).filter(Boolean).map(identity))
      } else if ((name === "href" || name === "xlink:href") && value.startsWith("#")) {
        node.attrs[name] = `#${identity(value.slice(1))}`
      }
    }
  }
  return roots
}

function compareDom(r: CleanNode, p: CleanNode, diffs: string[], pathStr = ""): void {
  if (r.type !== p.type) {
    diffs.push(`${pathStr}: node type mismatch (${r.type} vs ${p.type})`)
    return
  }

  if (r.type === "text") {
    if (r.value !== p.value) {
      diffs.push(`${pathStr}: text mismatch ("${r.value}" vs "${p.value}")`)
    }
    return
  }

  if (r.tag !== p.tag) {
    diffs.push(`${pathStr}: tag mismatch (<${r.tag}> vs <${p.tag}>)`)
    return
  }

  // Compare classes as sets of tokens
  const missingInP = [...r.classes].filter((c) => !p.classes.has(c))
  const extraInP = [...p.classes].filter((c) => !r.classes.has(c))
  if (missingInP.length > 0 || extraInP.length > 0) {
    diffs.push(
      `${pathStr}: class mismatch (missing in Phoenix: [${missingInP.join(", ")}], extra: [${extraInP.join(", ")}])`
    )
  }

  // Compare non-class attributes
  const rKeys = Object.keys(r.attrs).filter((k) => k !== "class")
  const pKeys = Object.keys(p.attrs).filter((k) => k !== "class")

  for (const k of rKeys) {
    if (!(k in p.attrs)) {
      diffs.push(`${pathStr}: attribute "${k}" missing in Phoenix (expected "${r.attrs[k]}")`)
    } else if (r.attrs[k] !== p.attrs[k]) {
      diffs.push(`${pathStr}: attribute "${k}" value mismatch ("${r.attrs[k]}" vs "${p.attrs[k]}")`)
    }
  }

  for (const k of pKeys) {
    if (!(k in r.attrs)) {
      diffs.push(`${pathStr}: unexpected attribute "${k}" in Phoenix ("${p.attrs[k]}")`)
    }
  }

  // Compare children count and structure
  if (r.children.length !== p.children.length) {
    diffs.push(
      `${pathStr}: children count mismatch (<${r.tag}> has ${r.children.length} in React vs ${p.children.length} in Phoenix)`
    )
    return
  }

  for (let i = 0; i < r.children.length; i++) {
    compareDom(r.children[i], p.children[i], diffs, `${pathStr}/${r.children[i].tag || "text"}[${i}]`)
  }
}

export async function compareComponentParity(
  fixture: ComponentFixture,
  phoenixHtml: string
): Promise<ParityResult> {
  const reactElement = fixture.renderReact()
  const explicitIds = explicitFixtureIds(reactElement)
  const reactHtml = renderToStaticMarkup(reactElement)
  const diffs: string[] = []

  const rFrag = parse5.parseFragment(reactHtml)
  const pFrag = parse5.parseFragment(phoenixHtml)

  const rNodes = cleanDocument(rFrag, explicitIds, "React", diffs)
  const pNodes = cleanDocument(pFrag, explicitIds, "Phoenix", diffs)

  if (rNodes.length !== pNodes.length) {
    diffs.push(`Root node count mismatch: ${rNodes.length} in React vs ${pNodes.length} in Phoenix`)
  } else {
    for (let i = 0; i < rNodes.length; i++) {
      compareDom(rNodes[i], pNodes[i], diffs, `${fixture.name}[${i}]`)
    }
  }

  return {
    name: fixture.name,
    title: fixture.title,
    passed: diffs.length === 0,
    differences: diffs.length > 0 ? diffs : undefined,
  }
}

export async function runParitySuite(): Promise<{
  passedCount: number
  totalCount: number
  passedFamilyCount: number
  totalFamilyCount: number
  results: ParityResult[]
}> {
  const jsonPath = path.resolve("priv/phoenix_ssr.json")
  let phoenixMap: Record<string, string> = {}
  try {
    const raw = await fs.readFile(jsonPath, "utf8")
    phoenixMap = JSON.parse(raw) as Record<string, string>
  } catch (err) {
    console.error(`Could not read ${jsonPath}. Run "mix run -e 'File.write!("priv/phoenix_ssr.json", ShadcnLiveview.Gallery.dump_all())'" first.`)
    throw err
  }

  // Build Phoenix SSR preview HTML page for visual comparison
  const cssPath = path.resolve("priv/static/assets/css/app.css")
  const cssContent = await fs.readFile(cssPath, "utf8")

  const sectionsHtml = fixtures
    .map((f) => {
      const pHtml = phoenixMap[f.name] || '<div class="text-destructive">Missing Phoenix component</div>'
      return `
    <section id="${f.name}" class="rounded-xl border bg-card p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between border-b pb-3">
        <div>
          <h2 class="text-lg font-semibold tracking-tight">${f.title}</h2>
          <span class="text-xs uppercase tracking-wider text-muted-foreground">${f.category}</span>
        </div>
        <span class="rounded bg-muted px-2 py-0.5 text-xs font-mono text-muted-foreground">${f.name}</span>
      </div>
      <div class="preview-stage flex min-h-[120px] w-full items-center justify-center rounded-lg border border-dashed bg-background/50 p-6">
        ${pHtml}
      </div>
    </section>`
    })
    .join("\n")

  const previewHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Phoenix LiveView Components SSR Preview (Zero JavaScript)</title>
  <style>
${cssContent}
    .preview-stage .fixed {
      position: static !important;
      transform: none !important;
      translate: none !important;
      max-width: 100% !important;
    }
    .preview-stage [data-slot$=-overlay] {
      display: none !important;
    }
  </style>
</head>
<body class="bg-background text-foreground min-h-screen antialiased">
  <header class="sticky top-0 z-40 border-b bg-background/95 backdrop-blur px-8 py-4">
    <div class="mx-auto flex max-w-7xl items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight">Phoenix LiveView Components SSR Gallery</h1>
        <p class="text-sm text-muted-foreground">Server-rendered static HTML via Phoenix LiveView with Tailwind v4 styling &bull; Zero client-side JavaScript</p>
      </div>
      <div class="rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
        ${fixtures.length} Fixture Cases Rendered
      </div>
    </div>
  </header>
  <main class="mx-auto max-w-7xl p-8">
    <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
      ${sectionsHtml}
    </div>
  </main>
</body>
</html>`

  const outDir = path.resolve("priv/static/preview")
  await fs.mkdir(outDir, { recursive: true })
  await fs.writeFile(path.join(outDir, "phoenix-ssr.html"), previewHtml, "utf8")

  const results: ParityResult[] = []
  let passedCount = 0

  for (const fixture of fixtures) {
    const pHtml = phoenixMap[fixture.name]
    if (!pHtml) {
      results.push({
        name: fixture.name,
        title: fixture.title,
        passed: false,
        differences: ["Component missing from Phoenix SSR dump"],
      })
      continue
    }

    const res = await compareComponentParity(fixture, pHtml)
    if (res.passed) {
      passedCount++
    }
    results.push(res)
  }

  const families = new Map<string, boolean>()
  fixtures.forEach((fixture, i) => {
    const family = fixture.family ?? fixture.name
    families.set(family, (families.get(family) ?? true) && results[i].passed)
  })

  return {
    passedCount,
    totalCount: fixtures.length,
    passedFamilyCount: [...families.values()].filter(Boolean).length,
    totalFamilyCount: families.size,
    results,
  }
}

async function runCli(): Promise<void> {
  const summary = await runParitySuite()

  console.log("\n========================================================")
  console.log(`  SHADCN vs PHOENIX LIVEVIEW SSR PARITY RESULTS`)
  console.log("========================================================")
  console.log(`  Cases: ${summary.passedCount} / ${summary.totalCount} passed parity`)
  console.log(`  Families: ${summary.passedFamilyCount} / ${summary.totalFamilyCount} passed all cases`)
  console.log("--------------------------------------------------------\n")

  for (const res of summary.results) {
    const icon = res.passed ? "✓ PASS" : "✗ FAIL"
    console.log(`  [${icon}] ${res.title.padEnd(25)} (${res.name})`)
    if (!res.passed && res.differences) {
      for (const diff of res.differences.slice(0, 3)) {
        console.log(`         -> ${diff}`)
      }
      if (res.differences.length > 3) {
        console.log(`         -> ... and ${res.differences.length - 3} more differences`)
      }
    }
  }

  console.log("\nGenerated previews for visual comparison:")
  console.log("  - React SSR:   priv/static/preview/react-static.html")
  console.log("  - Phoenix SSR: priv/static/preview/phoenix-ssr.html\n")

  const caseDiscrepancies = summary.totalCount - summary.passedCount
  const caseMatchRate = ((summary.passedCount / summary.totalCount) * 100).toFixed(1)
  const familyDiscrepancies = summary.totalFamilyCount - summary.passedFamilyCount
  const familyMatchRate = ((summary.passedFamilyCount / summary.totalFamilyCount) * 100).toFixed(1)

  console.log(`\nMETRIC parity_case_score=${summary.passedCount}`)
  console.log(`METRIC case_discrepancies=${caseDiscrepancies}`)
  console.log(`METRIC case_match_rate=${caseMatchRate}`)
  console.log(`METRIC parity_family_score=${summary.passedFamilyCount}`)
  console.log(`METRIC family_discrepancies=${familyDiscrepancies}`)
  console.log(`METRIC family_match_rate=${familyMatchRate}`)
  if (summary.passedCount !== summary.totalCount || summary.passedFamilyCount !== summary.totalFamilyCount) {
    process.exitCode = 1
  }
}

const isDirect = process.argv[1]?.endsWith("parity.tsx") || process.argv[1]?.endsWith("parity.ts")
if (isDirect) {
  runCli().catch((err) => {
    console.error("Parity test failed with error:", err)
    process.exit(1)
  })
}
