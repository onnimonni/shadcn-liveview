import React from "react"
import fs from "node:fs/promises"
import path from "node:path"
import { renderToStaticMarkup } from "react-dom/server"
import { fixtures } from "./fixtures"
import { fixtureMinHeight } from "../assets/js/gallery-layout"

const stageClass = "preview-stage flex min-h-[120px] w-full items-center justify-center rounded-lg border border-dashed bg-background/50 p-6"

function gallery(mode: "react" | "liveview") {
  const title = mode === "react" ? "React" : "LiveView"
  return "<!DOCTYPE html>" + renderToStaticMarkup(
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{`${title} component gallery`}</title>
        <link rel="stylesheet" href="/assets/css/app.css" />
        <script type="module" src="/assets/js/gallery.js" />
      </head>
      <body className="min-h-screen bg-background text-foreground antialiased" data-gallery={mode}>
        <header className="sticky top-0 z-40 border-b bg-background/95 px-8 py-4 backdrop-blur">
          <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold tracking-tight">{title} Components Gallery</h1>
              <p className="text-sm text-muted-foreground">{fixtures.length} custom regression examples · Not official shadcn templates</p>
            </div>
            <nav className="flex gap-4 text-sm" aria-label="Compare implementations">
              <a className="underline" href="/preview/react-ssr.html">React</a>
              <a className="underline" href="/preview/liveview.html">LiveView</a>
              <a className="underline" href="/preview/react-static.html">Static React SSR</a>
              <a className="underline" href="/preview/phoenix-ssr.html">Static Phoenix SSR</a>
              <a className="underline" href="https://ui.shadcn.com/r/styles/radix-nova/registry.json" target="_blank" rel="noreferrer">Official registry</a>
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-7xl p-8">
          <div className="grid grid-cols-1 gap-8 md:grid-cols-2">
            {fixtures.map(fixture => <section key={fixture.name} id={fixture.name} className="rounded-xl border bg-card p-6 shadow-sm">
              <div className="mb-4 flex items-center justify-between gap-2 border-b pb-3">
                <div><h2 className="text-lg font-semibold tracking-tight">{fixture.title}</h2><span className="text-xs uppercase tracking-wider text-muted-foreground">{fixture.category}</span></div>
                <span className="rounded bg-muted px-2 py-0.5 font-mono text-xs text-muted-foreground">{fixture.name}</span>
                <a className="text-xs underline" href={`https://ui.shadcn.com/r/styles/radix-nova/${fixture.family || fixture.name}.json`} target="_blank" rel="noreferrer">Upstream source</a>
              </div>
              <iframe title={`${fixture.title} example`} data-fixture={fixture.name} data-family={fixture.family || fixture.name} loading="lazy" className="block w-full border-0" style={{height: `${fixtureMinHeight(fixture.family || fixture.name)}px`}} data-src={mode === "react" ? `/preview/react-fixture.html?fixture=${encodeURIComponent(fixture.name)}` : `/live-preview/${encodeURIComponent(fixture.name)}?embed=1`} />
            </section>)}
          </div>
          <noscript>Interactive examples require JavaScript. Use the static SSR comparison galleries to inspect rendering without JavaScript.</noscript>
        </main>
      </body>
    </html>,
  )
}

export async function buildInteractiveGalleries(): Promise<void> {
  const outDir = path.resolve("priv/static/preview")
  await fs.mkdir(outDir, { recursive: true })
  await Promise.all([
    fs.writeFile(path.join(outDir, "react-ssr.html"), gallery("react")),
    fs.writeFile(path.join(outDir, "liveview.html"), gallery("liveview")),
    fs.writeFile(path.join(outDir, "react-fixture.html"), `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>React component preview</title><link rel="stylesheet" href="/assets/css/app.css"><script type="module" src="/assets/js/react-preview.js"></script><script type="module" src="/assets/js/gallery-frame.js"></script></head><body class="bg-background text-foreground antialiased"><main id="fixture-stage" class="${stageClass}"></main></body></html>`),
  ])
}
