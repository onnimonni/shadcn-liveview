import test from "node:test"
import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { globSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import path from "node:path"

const root = path.resolve(import.meta.dirname, "..")
const entry = path.join(root, "priv/static/shadcn.tailwind.css")
const cli = path.join(root, "node_modules/@tailwindcss/cli/dist/index.mjs")
// Real path: Tailwind's scanner skips sources reached through macOS's /var -> /private/var link.
const tmp = realpathSync(tmpdir())

// Compiles like a consumer app: the input lives outside the repo, so only the
// entry's own @source rules (resolved relative to the entry) and the listed ones apply.
function compile(input: string, ...flags: string[]): string {
  const dir = mkdtempSync(path.join(tmp, "shadcn-tailwind-"))
  try {
    writeFileSync(path.join(dir, "app.css"), input)
    execFileSync(process.execPath, [cli, "-i", "app.css", "-o", "out.css", ...flags], { cwd: dir, stdio: "pipe" })
    return readFileSync(path.join(dir, "out.css"), "utf8")
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
}

const tailwind = path.join(root, "node_modules/tailwindcss/index.css")
const consumer = (...lines: string[]) =>
  [`@import ${JSON.stringify(tailwind)} source(none);`, `@import ${JSON.stringify(entry)};`, ...lines].join("\n")

// Absolute paths of a stylesheet's @source rules, which Tailwind resolves against the file's directory.
const sourcesOf = (css: string, base: string) =>
  [...css.matchAll(/@source "([^"]+)";/g)].map((match) => path.resolve(base, match[1]))

test("shipped entry is a Tailwind source without its own preflight or theme", () => {
  const css = readFileSync(entry, "utf8")
  assert.doesNotMatch(css, /^\s*@import\s/m, "imports must be inlined; the app's @import \"tailwindcss\" provides preflight")
  assert.match(css, /@custom-variant data-open\b/)
  assert.match(css, /@custom-variant dark \(&:is\(\.dark, \.dark \*, \[data-theme=dark\], \[data-theme=dark\] \*\)\);/)
  assert.match(css, /@theme inline\s*\{[^}]*--color-primary: var\(--primary\)/)
  assert.match(css, /@utility fade-in\b/)
})

test("prebuilt shadcn.css is Tailwind plus the entry, and the shipped entry is current", () => {
  // Anything added to shadcn.css itself (a variant, token or keyframe) would be
  // missing for Tailwind consumers, so the prebuilt entry may only add sources.
  const prebuilt = path.join(root, "assets/css/shadcn.css")
  const css = readFileSync(prebuilt, "utf8")
  assert.match(
    css.replace(/\/\*[\s\S]*?\*\//g, ""),
    /^\s*@import "tailwindcss" source\(none\);\s*@import "\.\/shadcn\.tailwind\.css";(\s*@source "[^"]+";)*\s*$/,
  )
  const sources = sourcesOf(css, path.dirname(prebuilt)).map((dir) => `@source ${JSON.stringify(dir)};`)
  // Minified, so esbuild's whitespace changes inside custom property values do not count.
  const shipped = compile(consumer(...sources), "--minify")
  assert.equal(shipped, compile(`@import ${JSON.stringify(prebuilt)};`, "--minify"), "run mix assets.package")
})

test("entry scans every published library file that renders markup, and only published files", () => {
  const files = readFileSync(path.join(root, "mix.exs"), "utf8").match(/files:\s*\[([\s\S]*?)\]/)![1]
  assert.match(files, /"priv\/static\/shadcn\.tailwind\.css"/, "publish the entry")
  const published = new Set(
    [...files.matchAll(/"(lib\/[^"]+)"/g)].flatMap((match) =>
      globSync(match[1], { cwd: root }).map((file) => path.join(root, file)),
    ),
  )
  const scanned = sourcesOf(readFileSync(entry, "utf8"), path.dirname(entry))
  for (const source of scanned) {
    const inside = globSync("**/*", { cwd: source, withFileTypes: true }).filter((dirent) => dirent.isFile())
    const scannedFiles = inside.length ? inside.map((dirent) => path.join(dirent.parentPath, dirent.name)) : [source]
    for (const file of scannedFiles) {
      assert.ok(published.has(file), `${path.relative(root, file)} is scanned but not published`)
    }
  }
  for (const file of published) {
    if (!readFileSync(file, "utf8").includes('~H"""')) continue
    assert.ok(
      scanned.some((source) => file === source || file.startsWith(source + path.sep)),
      `${path.relative(root, file)} renders markup but the entry does not @source it`,
    )
  }
})

test("app utilities share one layer with component utilities", () => {
  const dir = mkdtempSync(path.join(tmp, "shadcn-tailwind-app-"))
  try {
    writeFileSync(
      path.join(dir, "page.heex"),
      `<td class="hidden md:table-cell"></td><.input class="pl-8" /><.card_title class="text-2xl" /><div class="bg-primary/10 ring-primary"></div>`,
    )
    const css = compile(consumer(`@source ${JSON.stringify(dir)};`))
    const at = (selector: string) => {
      const index = css.indexOf(` ${selector} {`)
      assert.notEqual(index, -1, `${selector} must be generated`)
      return index
    }
    assert.ok(at(".md\\:table-cell") > at(".hidden"), "responsive app class must follow .hidden")
    assert.ok(at(".pl-8") > at(".px-2\\.5"), "app padding must follow component padding")
    at(".bg-primary\\/10")
    at(".ring-primary")
    at(".text-2xl")
    assert.equal(css.match(/@layer utilities\s*\{/g)?.length, 1, "one utilities layer")
  } finally {
    rmSync(dir, { recursive: true, force: true })
  }
})

test("font tokens stay variables so an app's :root override reaches html, utilities and titles", () => {
  const css = compile(consumer(), "--minify")
  assert.match(css, /--font-sans:ui-sans-serif, ?system-ui, ?sans-serif[;}]/)
  assert.match(css, /--font-heading:var\(--font-sans\)[;}]/)
  assert.match(css, /html\{font-family:var\(--font-sans\)\}/)
  assert.match(css, /\.font-sans\{font-family:var\(--font-sans\)\}/)
  assert.match(css, /\.cn-font-heading\{font-family:var\(--font-heading\)\}/)
})
