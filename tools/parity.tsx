import fs from "node:fs/promises"
import path from "node:path"
import * as parse5 from "parse5"
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
    if (attr.name.startsWith("phx-")) continue
    let attrName = attr.name === "htmlFor" ? "for" : attr.name
    const ignored: Record<string, true> = {
      tabler: true,
      hugeicons: true,
      phosphor: true,
      remixicon: true,
      lucide: true,
    }
    if (ignored[attrName]) continue
    let val = attr.value.trim()
    if (attrName === "class") {
      classes = new Set(val.split(/\s+/).filter(Boolean))
      attrs[attrName] = [...classes].sort().join(" ")
    } else {
      if (
        (attrName === "id" || attrName === "aria-controls" || attrName === "aria-describedby" || attrName === "for") &&
        (val.includes("radix-") || /^:r[0-9a-z]+:$/.test(val))
      ) {
        val = "radix-id"
      }
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
  const reactHtml = renderToStaticMarkup(fixture.renderReact())
  const diffs: string[] = []

  const rFrag = parse5.parseFragment(reactHtml)
  const pFrag = parse5.parseFragment(phoenixHtml)

  const rNodes = (rFrag.childNodes || []).map(cleanDom).filter((n): n is CleanNode => n !== null)
  const pNodes = (pFrag.childNodes || []).map(cleanDom).filter((n): n is CleanNode => n !== null)

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
  results: ParityResult[]
}> {
  const jsonPath = path.resolve("priv/phoenix_ssr.json")
  let phoenixMap: Record<string, string> = {}
  try {
    const raw = await fs.readFile(jsonPath, "utf8")
    phoenixMap = JSON.parse(raw) as Record<string, string>
  } catch (err) {
    console.error(`Could not read ${jsonPath}. Run "mix run -e 'File.write!(\"priv/phoenix_ssr.json\", ShadcnLiveview.Gallery.dump_all())'" first.`)
    throw err
  }

  // Build Phoenix SSR preview HTML page for visual comparison
  const cssPath = path.resolve("priv/static/assets/css/app.css")
  let cssContent = ""
  try {
    cssContent = await fs.readFile(cssPath, "utf8")
  } catch {
    // optional
  }

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
        ${fixtures.length} Components Rendered
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

  return {
    passedCount,
    totalCount: fixtures.length,
    results,
  }
}

async function runCli(): Promise<void> {
  const summary = await runParitySuite()

  console.log("\n========================================================")
  console.log(`  SHADCN vs PHOENIX LIVEVIEW SSR PARITY RESULTS`)
  console.log("========================================================")
  console.log(`  Overall: ${summary.passedCount} / ${summary.totalCount} passed parity`)
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
  console.log("  - React SSR:   priv/static/preview/react-ssr.html")
  console.log("  - Phoenix SSR: priv/static/preview/phoenix-ssr.html\n")

  if (summary.passedCount < summary.totalCount) {
    console.log(`Parity suite completed with ${summary.totalCount - summary.passedCount} component diffs to resolve.`)
  } else {
    console.log("All components achieved 100% SSR parity!")
  }
}

const isDirect = process.argv[1]?.endsWith("parity.tsx") || process.argv[1]?.endsWith("parity.ts")
if (isDirect) {
  runCli().catch((err) => {
    console.error("Parity test failed with error:", err)
    process.exit(1)
  })
}
