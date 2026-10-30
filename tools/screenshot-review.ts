import { chromium, type Browser, type BrowserContext, type Frame, type Page } from "@playwright/test"
import fs from "node:fs/promises"
import path from "node:path"
import { fixtures } from "./fixtures"
import { fixtureMinHeight } from "../assets/js/gallery-layout.js"
import { awaitFixture, inspectFixture, readinessTimeout, type FixtureMeasurements, type GeometryStability } from "./screenshot-review-browser"
import { comparePixels, pairedGeometryFinding, pixelFinding, type Finding, type PixelMetrics } from "./screenshot-review-metrics"
import { rankSuspects, rankingHeuristics, type RankedSuspect } from "./screenshot-review-ranking"

interface Options { fixtures: string[]; widths: number[]; url: string; out: string; strict: boolean }
interface Capture {
  implementation: "react" | "liveview"
  url: string
  status: "captured" | "failed"
  image?: string
  measurements?: FixtureMeasurements
  stability?: GeometryStability
  error?: string
}
interface FixtureReview {
  fixture: string
  title: string
  family: string
  category: string
  width: number
  state: "initial"
  height: number | null
  captures: Capture[]
  pixelComparison: PixelMetrics | null
  diffImage: string | null
  findings: Finding[]
}
interface ReviewReport {
  schemaVersion: 1
  generatedAt: string
  options: Options
  heuristics: string[]
  coverage: {
    availableFixtures: number
    selectedFixtures: number
    widths: number[]
    plannedPairs: number
    completedPairs: number
    plannedCaptures: number
    successfulCaptures: number
    failedCaptures: number
    unattemptedPairs: number
  }
  summary: { findings: number; bySeverity: Record<string, number>; byCategory: Record<string, number>; pairsWithFindings: number }
  fatalError: string | null
  results: FixtureReview[]
  rankedSuspects?: RankedSuspect[]
}
interface BrowserPixelComparison { metrics: PixelMetrics; diffDataURL: string }
interface PendingCapture { page: Page; frame?: Frame; capture: Capture; findings: Finding[] }

export function parseOptions(args: string[], knownFixtures: string[]): Options {
  const options: Options = { fixtures: [...knownFixtures], widths: [390, 1100], url: "http://127.0.0.1:4000", out: "parity/visual-audit", strict: false }
  for (let i = 0; i < args.length; i++) {
    const flag = args[i]
    if (flag === "--strict") { options.strict = true; continue }
    if (!["--fixtures", "--widths", "--url", "--out"].includes(flag)) throw new Error(`Unknown option: ${flag}`)
    const value = args[++i]
    if (!value || value.startsWith("--")) throw new Error(`Missing value for ${flag}`)
    if (flag === "--fixtures") {
      const names = value.split(",").map(name => name.trim())
      if (names.some(name => !name || !knownFixtures.includes(name))) throw new Error(`Unknown or empty fixture in ${value}; available fixtures come from tools/fixtures.tsx`)
      options.fixtures = [...new Set(names)]
    } else if (flag === "--widths") {
      const widths = value.split(",").map(part => /^\d+$/.test(part.trim()) ? Number(part.trim()) : NaN)
      if (widths.some(width => !Number.isInteger(width) || width < 100 || width > 4096)) throw new Error("Widths must be comma-separated integer CSS pixels between 100 and 4096")
      options.widths = [...new Set(widths)]
    } else if (flag === "--url") {
      const url = new URL(value)
      if (!["http:", "https:"].includes(url.protocol) || url.search || url.hash) throw new Error("--url must be an HTTP(S) base URL without query or fragment")
      options.url = url.href.replace(/\/$/, "")
    } else options.out = value
  }
  return options
}

const heuristics = [
  "Each dynamically discovered fixture is rendered in its own real gallery-style iframe in React and connected LiveView, at every requested width. These are initial demo states, not an interaction crawl.",
  "Readiness requires a React commit signal (including portal-only content) or an actually connected LiveView socket, loaded fonts and decoded images, initialized positive-size chart SVGs, then 12 consecutive animation frames without DOM/geometry changes. CSS/Web Animations are disabled/finished; JavaScript chart interpolation must genuinely settle. Timeouts are capture failures, never blank successes.",
  "Screenshots use light color scheme, UTC/en-US, seeded Math.random, device scale 1 and identical CSS-pixel width and paired capture height. Chromium decodes both PNGs to RGBA; pixels differing by more than 24/255 in any visible color channel are highlighted magenta. At least 5% changed pixels is a warning; smaller differences are informational. This is genuine image comparison, not an aesthetic judgment or perceptual model.",
  "Geometry checks are independent for BOTH implementations: frame/stage overflow greater than 1 CSS pixel and ancestor overflow clipping are reported even if both screenshots match. Scrollable clipping is informational. Portals, intentional scroll areas, large demos and fixed overlays can produce legitimate findings; no per-fixture exemptions exist.",
  "Hidden, transparent, screen-reader-only and non-rendering nodes are excluded. Otherwise visible zero-size controls, missing DOM-derived accessible names and absent visible label context are review heuristics, not a full accessibility audit. Icon-only controls and intentionally bare demo controls can be valid; ARIA names alone do not provide a visible label.",
  "Differences may be intentional: React/client IDs, anti-aliasing, separate implementations, error/disabled/empty demo states and chart rendering algorithms. A matching image is not proof of usability, and image/DOM findings are not aesthetic certainty. Review paired images and measurements before deciding a fix.",
  ...rankingHeuristics,
  "Default exit is 0 after producing a report, including demo findings and fixture capture failures. --strict exits 1 for warning/error findings (not info-only). CLI/setup/report-writing failures exit 2. Failed or unattempted coverage is explicit.",
]

export function renderReport(report: ReviewReport, images: Map<string, string>) {
  const escape = (value: unknown) => String(value).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]!)
  const ranked = report.rankedSuspects ?? rankSuspects(report.results)
  const imageHTML = (label: string, file: string | null | undefined, fixture: string, width: number) => `<figure><figcaption>${escape(label)}${file ? ` · <a href="${escape(file)}">PNG</a>` : " · unavailable"}</figcaption>${file && images.has(file) ? `<a href="${images.get(file)}" download="${escape(path.basename(file))}"><img loading="lazy" src="${images.get(file)}" alt="${escape(label)} ${escape(fixture)} at ${width}px"></a>` : `<p>No successful image capture. See failure details.</p>`}</figure>`
  const suspects = ranked.map(suspect => `<article class="suspect"><h3><span class="score">#${suspect.rank} · score ${suspect.score}</span> <a href="#result-${suspect.resultIndex}">${escape(suspect.fixture)} · ${suspect.width}px</a></h3><p>${escape(suspect.title)} · ${escape(suspect.state)} state · ${escape(suspect.implementations.join(" + ") || "paired")}</p><ul>${suspect.reasons.map(reason => `<li><strong>${escape(reason.signal)} (${reason.score}) · ${escape(reason.context)}</strong> — ${escape(reason.categories.join(", "))}${reason.collapsedFindings ? ` · ${reason.collapsedFindings} repeated/correlated findings collapsed` : ""}<ul>${reason.evidence.map(evidence => `<li>${escape(evidence.implementation || "paired")} ${escape(evidence.element || "")}: ${escape(evidence.message)}</li>`).join("")}</ul></li>`).join("")}</ul><p><strong>Reference context:</strong> shared: ${escape(suspect.comparison.sharedCategories.join(", ") || "none")}; React only: ${escape(suspect.comparison.reactOnlyCategories.join(", ") || "none")}; LiveView only: ${escape(suspect.comparison.liveviewOnlyCategories.join(", ") || "none")}. Pixels: ${suspect.comparison.pixelChangedRatio === null ? "unavailable" : `${(suspect.comparison.pixelChangedRatio * 100).toFixed(2)}% changed`}. Shared findings retain full priority.</p><p>${suspect.links.map(link => `<a href="${escape(link.fixtureURL)}" target="_blank" rel="noreferrer">Use ${escape(link.implementation)} fixture</a> · ${escape(link.status)}${link.imageURL ? ` · <a href="${escape(link.imageURL)}">${escape(link.implementation)} PNG</a>` : ""}`).join(" · ")} · <a href="#result-${suspect.resultIndex}">All raw evidence</a></p><div class="images paired">${imageHTML("React", suspect.links.find(link => link.implementation === "react")?.imageURL, suspect.fixture, suspect.width)}${imageHTML("LiveView", suspect.links.find(link => link.implementation === "liveview")?.imageURL, suspect.fixture, suspect.width)}</div></article>`).join("\n")
  const cards = report.results.map((result, index) => {
    const findings = result.findings.map(finding => `<li class="${finding.severity}"><strong>${escape(finding.severity)} · ${escape(finding.category)}</strong> ${escape(finding.implementation || "paired")} ${escape(finding.element || "")} — ${escape(finding.message)}${finding.details ? `<details><summary>Measurements/details</summary><pre>${escape(JSON.stringify(finding.details, null, 2))}</pre></details>` : ""}</li>`).join("")
    return `<section id="result-${index}"><h2><a href="#result-${index}">${escape(result.fixture)} · ${result.width}px</a></h2><p>${escape(result.title)} · ${escape(result.family)} · ${escape(result.category)} · ${escape(result.state)} state · ${result.findings.length} findings</p><p>${result.captures.map(capture => `<a href="${escape(capture.url)}" target="_blank" rel="noreferrer">Open ${escape(capture.implementation)} fixture</a>`).join(" · ")}</p><div class="images">${imageHTML("React", result.captures.find(capture => capture.implementation === "react")?.image, result.fixture, result.width)}${imageHTML("LiveView", result.captures.find(capture => capture.implementation === "liveview")?.image, result.fixture, result.width)}${imageHTML("Pixel difference (magenta)", result.diffImage, result.fixture, result.width)}</div><ul>${findings || "<li>No findings under these heuristics.</li>"}</ul><details><summary>Capture state, geometry and controls</summary><pre>${escape(JSON.stringify(result.captures, null, 2))}</pre></details></section>`
  }).join("\n")
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Component screenshot anomaly review</title><style>body{margin:0;padding:24px;background:#f8fafc;color:#0f172a;font:14px/1.5 system-ui,sans-serif}a{color:#1d4ed8}h1,h2{line-height:1.2}section{margin:24px 0;padding:20px;background:white;border:1px solid #cbd5e1;border-radius:8px;scroll-margin-top:12px}.images{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.images.paired{grid-template-columns:repeat(2,minmax(0,1fr))}figure{margin:0;min-width:0}figcaption{font-weight:600;overflow-wrap:anywhere}img{display:block;max-width:100%;height:auto;border:1px solid #cbd5e1}pre{padding:12px;background:#f1f5f9;overflow:auto;max-height:600px}li{margin:8px 0}.warning>strong{color:#92400e}.error>strong{color:#b91c1c}.suspect{padding:16px 0;border-top:1px solid #cbd5e1}.score{display:inline-block;padding:4px 8px;background:#0f172a;color:white;border-radius:4px}nav{max-height:300px;overflow:auto;columns:3}details{margin:8px 0}summary{cursor:pointer}@media(max-width:800px){.images,.images.paired{grid-template-columns:1fr}nav{columns:1}}</style></head><body><h1>Component screenshot anomaly review</h1><p>Generated ${escape(report.generatedAt)} · ${escape(report.options.url)}</p><p><strong>Heuristics, not aesthetic certainty.</strong> This file embeds all PNGs and works offline without a server or external model API. Fixture links open the running application for manual interaction; automated captures cover initial demo states only.</p>${report.fatalError ? `<p class="error"><strong>Run setup failure: ${escape(report.fatalError)}</strong></p>` : ""}<h2>Coverage and summary</h2><pre>${escape(JSON.stringify({ selection: { fixtures: report.options.fixtures, widths: report.options.widths, state: "initial" }, coverage: report.coverage, summary: report.summary, rankedCases: ranked.length }, null, 2))}</pre><details open><summary>How to interpret findings and false positives</summary><ul>${report.heuristics.map(item => `<li>${escape(item)}</li>`).join("")}</ul></details><section id="ranked-suspects"><h2>Ranked likely-broken cases</h2><p>${ranked.length} cases with signals, ordered by strongest independent evidence, not DOM element count. Scores are review priorities, not probabilities. Inspect both implementations; shared problems are still problems.</p>${suspects || "<p>No suspects under these heuristics. This does not establish interaction correctness; check coverage above.</p>"}</section><h2>Detailed raw results</h2><nav aria-label="Fixture results">${report.results.map((result, index) => `<div><a href="#result-${index}">${escape(result.fixture)} · ${result.width}px (${result.findings.length})</a></div>`).join("")}</nav>${cards}</body></html>`
}

async function openCapture(context: BrowserContext, options: Options, fixture: string, family: string, width: number, implementation: "react" | "liveview"): Promise<PendingCapture> {
  const page = await context.newPage()
  const url = implementation === "react"
    ? `${options.url}/preview/react-fixture.html?fixture=${encodeURIComponent(fixture)}`
    : `${options.url}/live-preview/${encodeURIComponent(fixture)}?embed=1`
  const capture: Capture = { implementation, url, status: "failed" }
  const findings: Finding[] = []
  const pending: PendingCapture = { page, capture, findings }
  const floor = fixtureMinHeight(family)
  page.on("pageerror", error => findings.push({ category: "browser-error", severity: "warning", implementation, message: error.message }))
  page.on("console", message => {
    if (message.type() === "error") findings.push({ category: "browser-error", severity: "warning", implementation, message: message.text() })
  })
  page.on("requestfailed", request => findings.push({ category: "browser-error", severity: "warning", implementation, message: "Browser request failed", details: { url: request.url(), failure: request.failure() } }))
  page.on("response", response => {
    if (response.status() >= 400) findings.push({ category: "browser-error", severity: "warning", implementation, message: `HTTP ${response.status()}`, details: { url: response.url() } })
  })
  try {
    const hostURL = `${options.url}/__screenshot-review__/${implementation}/${encodeURIComponent(fixture)}`
    // A browser-only routed host uses the application's actual gallery sizing
    // code. Nothing is added to the Phoenix application or shell-launched here.
    await page.route(hostURL, route => route.fulfill({ contentType: "text/html", body: `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="${options.url}/assets/css/app.css"><script type="module" src="${options.url}/assets/js/gallery.js"></script></head><body class="bg-background text-foreground" style="margin:0"><iframe title="${implementation} fixture" data-fixture="${fixture}" data-family="${family}" src="${url.replace(/&/g, "&amp;")}" style="display:block;border:0;width:100%;height:${floor}px"></iframe></body></html>` }))
    await page.setViewportSize({ width, height: Math.max(800, floor) })
    await page.goto(hostURL, { waitUntil: "load", timeout: readinessTimeout })
    const handle = await page.locator("iframe").elementHandle()
    const frame = await handle?.contentFrame()
    if (!frame) throw new Error("Fixture iframe did not attach")
    pending.frame = frame
    capture.stability = await awaitFixture(frame, implementation, fixture)
    const inspected = await inspectFixture(frame, implementation)
    capture.measurements = inspected.measurements
    findings.push(...inspected.findings)
  } catch (error) {
    capture.error = error instanceof Error ? error.stack || error.message : String(error)
    findings.push({ category: "capture-failure", severity: "error", implementation, message: "Fixture did not reach connected, font-loaded, chart-initialized stable rendering", details: { url, error: capture.error } })
    // Partial geometry is useful evidence for a zero-width chart/time-out. It
    // must never turn an unsuccessful render into a successful blank screenshot.
    if (pending.frame) {
      try {
        const inspected = await inspectFixture(pending.frame, implementation)
        capture.measurements = inspected.measurements
        findings.push(...inspected.findings)
      } catch { /* Missing stage/navigation failures already have an error finding. */ }
    }
  }
  return pending
}

async function capturePair(browser: Browser, options: Options, fixture: typeof fixtures[number], width: number, images: Map<string, string>, decoder: Page): Promise<FixtureReview> {
  const family = fixture.family || fixture.name
  const result: FixtureReview = { fixture: fixture.name, title: fixture.title, family, category: fixture.category, width, state: "initial", height: null, captures: [], pixelComparison: null, diffImage: null, findings: [] }
  let context: BrowserContext | undefined
  try {
    context = await browser.newContext({ viewport: { width, height: 800 }, deviceScaleFactor: 1, colorScheme: "light", reducedMotion: "reduce", locale: "en-US", timezoneId: "UTC" })
  await context.addInitScript(() => {
    // Upstream skeletons use random widths; seed random calls for reproducibility.
    let randomState = 0x51adc0de
    Math.random = () => {
      randomState ^= randomState << 13
      randomState ^= randomState >>> 17
      randomState ^= randomState << 5
      return (randomState >>> 0) / 4294967296
    }
    // Run before component mount. This does not alter component markup, sizes,
    // visibility or data; JS-rendered chart animation is separately awaited.
    const install = () => {
      if (!document.documentElement) return
      const style = document.createElement("style")
      style.textContent = "*,*::before,*::after{animation:none!important;transition:none!important;caret-color:transparent!important;scroll-behavior:auto!important}"
      document.documentElement.append(style)
    }
    if (document.documentElement) install()
    else new MutationObserver((_, observer) => { if (document.documentElement) { observer.disconnect(); install() } }).observe(document, { childList: true })
  })
    // Sequential starts keep the shared Phoenix CSRF session established before
    // LiveView connects. Both pages remain alive for matching paired capture.
    const pending = [await openCapture(context, options, fixture.name, family, width, "react"), await openCapture(context, options, fixture.name, family, width, "liveview")]
    result.captures = pending.map(item => item.capture)
    const sizes = await Promise.all(pending.map(item => item.page.locator("iframe").boundingBox().catch(() => null)))
    const height = Math.ceil(Math.max(fixtureMinHeight(family), ...sizes.map(size => size?.height || 0)))
    result.height = height
    if (height > 12000) throw new Error(`Capture height ${height}px exceeds gallery safety limit 12000px`)
    for (const item of pending) {
      const { page, capture, frame } = item
      if (capture.error || !frame) continue
      try {
        // Changing the parent viewport must not change the iframe's own height.
        // Recheck geometry because media queries/fixed-position demos can move.
        await page.setViewportSize({ width, height })
        capture.stability = await awaitFixture(frame, capture.implementation, fixture.name)
        const inspected = await inspectFixture(frame, capture.implementation)
        capture.measurements = inspected.measurements
        // Replace initial geometry findings with final screenshot-time geometry.
        item.findings.splice(0, item.findings.length, ...item.findings.filter(finding => finding.category === "browser-error"))
        item.findings.push(...inspected.findings)
        const image = `images/${fixture.name}-${width}-${capture.implementation}.png`
        const png = await page.screenshot({ animations: "disabled", caret: "hide", scale: "css", clip: { x: 0, y: 0, width, height }, timeout: readinessTimeout })
        await fs.writeFile(path.join(options.out, image), png)
        images.set(image, `data:image/png;base64,${png.toString("base64")}`)
        capture.image = image
        capture.status = "captured"
      } catch (error) {
        capture.error = error instanceof Error ? error.stack || error.message : String(error)
        item.findings.push({ category: "capture-failure", severity: "error", implementation: capture.implementation, message: "Stable screenshot capture failed", details: { error: capture.error } })
      }
    }
    result.findings.push(...pending.flatMap(item => item.findings))
    const [react, liveview] = result.captures
    if (react.measurements && liveview.measurements) {
      const geometry = pairedGeometryFinding(react.measurements, liveview.measurements)
      if (geometry) result.findings.push(geometry)
    }
    if (react.image && liveview.image) {
      const comparison: BrowserPixelComparison = await decoder.evaluate(async ({ a, b, compareSource }) => {
        const decode = async (src: string) => {
          const image = new Image()
          image.src = src
          await image.decode()
          const canvas = document.createElement("canvas")
          canvas.width = image.naturalWidth; canvas.height = image.naturalHeight
          const context = canvas.getContext("2d", { willReadFrequently: true })!
          context.drawImage(image, 0, 0)
          return { width: canvas.width, height: canvas.height, data: context.getImageData(0, 0, canvas.width, canvas.height).data }
        }
        const [left, right] = await Promise.all([decode(a), decode(b)])
        if (left.width !== right.width || left.height !== right.height) throw new Error("Paired PNG dimensions do not match")
        // Serialize the exact tested pure algorithm, not a separate browser copy.
        const compare: typeof comparePixels = new Function(`return (${compareSource})`)()
        const { metrics, diff } = compare(left.data, right.data, left.width, left.height)
        const canvas = document.createElement("canvas")
        canvas.width = left.width; canvas.height = left.height
        canvas.getContext("2d")!.putImageData(new ImageData(diff, left.width, left.height), 0, 0)
        return { metrics, diffDataURL: canvas.toDataURL("image/png") }
      }, { a: images.get(react.image)!, b: images.get(liveview.image)!, compareSource: comparePixels.toString() })
      result.pixelComparison = comparison.metrics
      result.diffImage = `images/${fixture.name}-${width}-diff.png`
      images.set(result.diffImage, comparison.diffDataURL)
      await fs.writeFile(path.join(options.out, result.diffImage), Buffer.from(comparison.diffDataURL.split(",")[1], "base64"))
      const finding = pixelFinding(comparison.metrics)
      if (finding) result.findings.push(finding)
    }
  } catch (error) {
    result.findings.push({ category: "capture-failure", severity: "error", message: "Paired capture/image comparison failed", details: { error: error instanceof Error ? error.stack || error.message : String(error) } })
    // A pair-level browser failure must retain both planned implementation slots.
    for (const implementation of ["react", "liveview"] as const) {
      if (!result.captures.some(capture => capture.implementation === implementation)) result.captures.push({ implementation, url: implementation === "react" ? `${options.url}/preview/react-fixture.html?fixture=${encodeURIComponent(fixture.name)}` : `${options.url}/live-preview/${encodeURIComponent(fixture.name)}?embed=1`, status: "failed", error: "Pair failed before this capture could start; see paired failure details" })
    }
  } finally {
    try { await context?.close() }
    catch (error) { result.findings.push({ category: "browser-error", severity: "warning", message: "Browser context cleanup failed", details: { error: String(error) } }) }
  }
  return result
}

export async function runReview(options: Options) {
  const selected = fixtures.filter(fixture => options.fixtures.includes(fixture.name))
  const plannedPairs = selected.length * options.widths.length
  const report: ReviewReport = {
    schemaVersion: 1, generatedAt: new Date().toISOString(), options, heuristics,
    coverage: { availableFixtures: fixtures.length, selectedFixtures: selected.length, widths: options.widths, plannedPairs, completedPairs: 0, plannedCaptures: plannedPairs * 2, successfulCaptures: 0, failedCaptures: 0, unattemptedPairs: plannedPairs },
    summary: { findings: 0, bySeverity: { info: 0, warning: 0, error: 0 }, byCategory: {}, pairsWithFindings: 0 },
    fatalError: null, results: [], rankedSuspects: [],
  }
  await fs.mkdir(path.join(options.out, "images"), { recursive: true })
  const images = new Map<string, string>()
  let browser: Browser | undefined
  try {
    browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } : {}) })
    const decodeContext = await browser.newContext()
    const decoder = await decodeContext.newPage()
    for (const fixture of selected) {
      for (const width of options.widths) {
        const result = await capturePair(browser, options, fixture, width, images, decoder)
        report.results.push(result)
        console.log(`${report.results.length}/${plannedPairs} ${fixture.name} @ ${width}px: ${result.captures.filter(capture => capture.status === "captured").length}/2 captures, ${result.findings.length} findings`)
      }
    }
  } catch (error) {
    report.fatalError = error instanceof Error ? error.stack || error.message : String(error)
  } finally {
    if (browser) await browser.close()
  }
  report.coverage.completedPairs = report.results.filter(result => result.pixelComparison !== null).length
  report.coverage.successfulCaptures = report.results.flatMap(result => result.captures).filter(capture => capture.status === "captured").length
  report.coverage.failedCaptures = report.results.flatMap(result => result.captures).filter(capture => capture.status === "failed").length
  report.coverage.unattemptedPairs = plannedPairs - report.results.length
  for (const result of report.results) {
    if (result.findings.length) report.summary.pairsWithFindings++
    for (const finding of result.findings) {
      report.summary.findings++
      report.summary.bySeverity[finding.severity]++
      report.summary.byCategory[finding.category] = (report.summary.byCategory[finding.category] || 0) + 1
    }
  }
  report.rankedSuspects = rankSuspects(report.results)
  await fs.writeFile(path.join(options.out, "report.json"), JSON.stringify(report, null, 2) + "\n")
  await fs.writeFile(path.join(options.out, "index.html"), renderReport(report, images))
  console.log(JSON.stringify({ coverage: report.coverage, summary: report.summary, fatalError: report.fatalError, report: path.resolve(options.out, "index.html"), json: path.resolve(options.out, "report.json") }, null, 2))
  return report.fatalError ? 2 : options.strict && (report.summary.bySeverity.warning > 0 || report.summary.bySeverity.error > 0) ? 1 : 0
}

if (import.meta.main) {
  if (process.argv.slice(2).includes("--help")) {
    console.log("Usage: bun run audit:visual [--fixtures name,name] [--widths 390,1100] [--url http://127.0.0.1:4000] [--out parity/visual-audit] [--strict]\nRequires already-built assets/generated galleries and a running SHADCN_PREVIEW=1 server. Uses PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH when set; otherwise the installed Playwright Chromium. Never starts subprocesses. Default: all fixture definitions at both widths. Exit: 0 report generated; 1 strict warning/error findings; 2 CLI/setup/report failure.")
  } else {
    try { process.exitCode = await runReview(parseOptions(process.argv.slice(2), fixtures.map(fixture => fixture.name))) }
    catch (error) { console.error(error instanceof Error ? error.message : String(error)); process.exitCode = 2 }
  }
}
