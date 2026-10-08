import fs from "node:fs/promises"
import path from "node:path"
import { renderToStaticMarkup } from "react-dom/server"
import { fixtures, type ComponentFixture } from "./fixtures"

export interface SSRRenderResult {
  name: string
  title: string
  category: string
  html: string
  heex: string
}

export function renderReactFixture(name: string): SSRRenderResult | undefined {
  const fixture = fixtures.find((f) => f.name === name)
  if (!fixture) return undefined
  const html = renderToStaticMarkup(fixture.renderReact())
  return {
    name: fixture.name,
    title: fixture.title,
    category: fixture.category,
    html,
    heex: fixture.heex,
  }
}

export function renderAllReactFixtures(): SSRRenderResult[] {
  return fixtures.map((fixture) => ({
    name: fixture.name,
    title: fixture.title,
    category: fixture.category,
    html: renderToStaticMarkup(fixture.renderReact()),
    heex: fixture.heex,
  }))
}

export async function buildSSRPreviewPage(): Promise<string> {
  const results = renderAllReactFixtures()
  const cssPath = path.resolve("priv/static/assets/css/app.css")
  const cssContent = await fs.readFile(cssPath, "utf8")

  const sectionsHtml = results
    .map(
      (r) => `
    <section id="${r.name}" class="rounded-xl border bg-card p-6 shadow-sm">
      <div class="mb-4 flex items-center justify-between border-b pb-3">
        <div>
          <h2 class="text-lg font-semibold tracking-tight">${r.title}</h2>
          <span class="text-xs uppercase tracking-wider text-muted-foreground">${r.category}</span>
        </div>
        <span class="rounded bg-muted px-2 py-0.5 text-xs font-mono text-muted-foreground">${r.name}</span>
      </div>
      <div class="preview-stage flex min-h-[120px] w-full items-center justify-center rounded-lg border border-dashed bg-background/50 p-6">
        ${r.html}
      </div>
    </section>`
    )
    .join("\n")

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Shadcn Components SSR Preview (Zero JavaScript)</title>
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
        <h1 class="text-2xl font-bold tracking-tight">Shadcn Components SSR Gallery</h1>
        <p class="text-sm text-muted-foreground">Server-rendered static HTML with Tailwind v4 styling &bull; Zero client-side JavaScript</p>
      </div>
      <div class="rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
        ${results.length} Fixture Cases Rendered
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
  const outPath = path.join(outDir, "react-ssr.html")
  await fs.writeFile(outPath, html, "utf8")
  return outPath
}

async function runCli(): Promise<void> {
  const isDirect = process.argv[1]?.endsWith("ssr.tsx") || process.argv[1]?.endsWith("ssr.ts")
  if (isDirect) {
    const previewPath = await buildSSRPreviewPage()
    console.log(`Generated SSR preview gallery: ${previewPath}`)
  }
}

runCli().catch((err) => {
  console.error("SSR generation failed:", err)
  process.exit(1)
})
