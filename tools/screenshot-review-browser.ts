import type { Frame } from "@playwright/test"
import { overflowAmounts, type Finding, type Rect, type OverflowAmounts } from "./screenshot-review-metrics"

export const readinessTimeout = 20_000

export async function awaitFixture(frame: Frame, implementation: "react" | "liveview", fixture: string) {
  if (implementation === "liveview") {
    await frame.waitForFunction(() => {
      const root = document.querySelector("[data-phx-main]")
      const socket = Reflect.get(window, "liveSocket")
      return root?.classList.contains("phx-connected") && socket && typeof socket.isConnected === "function" && socket.isConnected()
    }, undefined, { timeout: readinessTimeout })
  } else {
    await frame.waitForFunction(name => document.body.dataset.fixtureReady === name, fixture, { timeout: readinessTimeout })
  }
  await frame.waitForFunction(() => document.fonts.status === "loaded" && Array.from(document.images).every(image => image.complete), undefined, { timeout: readinessTimeout })
  await frame.evaluate(async () => {
    await document.fonts.ready
    // Failed images are recorded separately; pending images must complete first.
    await Promise.all(Array.from(document.images, image => image.decode().catch(() => undefined)))
  })
  return awaitStableGeometry(frame)
}

export interface GeometryStability { stableFrames: number; chartSurfaces: number; stage: Rect; frame: Rect }

export async function awaitStableGeometry(frame: Frame) {
  // Stability requires live geometry AND SVG paths/attributes to stop changing.
  // Merely waiting for mount, an SVG wrapper, or a stable container is insufficient
  // for Recharts' JavaScript-driven interpolation.
  return frame.evaluate(({ timeout }) => new Promise<GeometryStability>((resolve, reject) => {
    const stage = document.getElementById("fixture-stage")
    if (!stage) return reject(new Error("Missing #fixture-stage"))
    const started = performance.now()
    let mutations = 0, lastMutation = -1, previous = "", consecutive = 0
    const observer = new MutationObserver(() => { mutations++ })
    observer.observe(document.body, { subtree: true, attributes: true, childList: true, characterData: true })
    const rect = (el: Element): Rect => {
      const { x, y, width, height } = el.getBoundingClientRect()
      return { x, y, width, height }
    }
    const sample = () => {
      try {
        if (performance.now() - started > timeout) throw new Error("Render did not stabilize: changing DOM/geometry or missing chart surface")
        // CSS animations are disabled by the init stylesheet. Finish remaining
        // finite Web Animations, cancel infinite ones (e.g. progress spinners).
        for (const animation of document.getAnimations()) {
          if (animation.playState !== "running") continue
          if (animation.effect?.getComputedTiming().iterations === Infinity) animation.cancel()
          else { try { animation.finish() } catch { animation.cancel() } }
        }
        const canvases = Array.from(document.querySelectorAll('[phx-hook$="ChartCanvas"], .recharts-wrapper'))
          .filter(el => getComputedStyle(el).display !== "none" && getComputedStyle(el).visibility !== "hidden")
        const surfaces = canvases.map(el => el.querySelector("svg.recharts-surface"))
        const chartsReady = surfaces.every(svg => svg && svg.getBoundingClientRect().width > 0 && svg.getBoundingClientRect().height > 0)
        // Include all rendered rectangles: font completion, ResizeObserver-driven
        // layouts, portals, transforms and iframe resizing can move controls.
        const geometry = Array.from(document.body.querySelectorAll("*"), el => {
          const r = el.getBoundingClientRect()
          return [r.x, r.y, r.width, r.height].map(n => Math.round(n * 100) / 100)
        })
        const signature = JSON.stringify([innerWidth, innerHeight, document.documentElement.scrollWidth, document.documentElement.scrollHeight, geometry])
        consecutive = chartsReady && previous === signature && lastMutation === mutations ? consecutive + 1 : 0
        previous = signature; lastMutation = mutations
        if (consecutive >= 12) {
          observer.disconnect()
          resolve({ stableFrames: consecutive, chartSurfaces: surfaces.length, stage: rect(stage), frame: { x: 0, y: 0, width: innerWidth, height: innerHeight } })
        } else requestAnimationFrame(sample)
      } catch (error) { observer.disconnect(); reject(error) }
    }
    requestAnimationFrame(sample)
  }), { timeout: readinessTimeout })
}

export interface ElementMeasurement {
  element: string
  rect: Rect
  stageOverflow: OverflowAmounts
  frameOverflow: OverflowAmounts
  clipping: { ancestor: string; rect: Rect; overflow: OverflowAmounts; scrollable: boolean }[]
  control: boolean
  accessibleName: string
  visibleLabel: string
}

export interface FixtureMeasurements {
  stage: Rect
  frame: Rect
  document: { scrollWidth: number; scrollHeight: number }
  connected: boolean | null
  fonts: string
  charts: { element: string; rect: Rect; shapes: number; labels: number }[]
  elements: ElementMeasurement[]
  failedImages: string[]
}

export async function inspectFixture(frame: Frame, implementation: "react" | "liveview") {
  const measurements: FixtureMeasurements = await frame.evaluate(({ overflowSource }) => {
    const overflow: typeof overflowAmounts = new Function(`return (${overflowSource})`)()
    const stage = document.getElementById("fixture-stage")!
    const rect = (el: Element): Rect => {
      const { x, y, width, height } = el.getBoundingClientRect()
      return { x, y, width, height }
    }
    const describe = (el: Element) => `${el.tagName.toLowerCase()}${el.id ? `#${el.id}` : ""}${el.getAttribute("data-slot") ? `[data-slot="${el.getAttribute("data-slot")}"]` : ""}${el.getAttribute("role") ? `[role="${el.getAttribute("role")}"]` : ""}`
    const hidden = (el: Element, visually = true) => {
      if (el.matches('input[type="hidden"], script, style, link, meta, template, svg defs *, svg defs, svg clipPath *, svg clipPath')) return true
      for (let current: Element | null = el; current; current = current.parentElement) {
        const style = getComputedStyle(current)
        if (current.hasAttribute("hidden") || current.getAttribute("aria-hidden") === "true" || style.display === "none" || style.visibility === "hidden" || style.visibility === "collapse" || visually && Number(style.opacity) === 0 || style.contentVisibility === "hidden") return true
        // Screen-reader-only native backing inputs are intentional, not failed
        // zero-size controls. Do not exempt unstyled zero-size visible nodes.
        if (visually && (style.clip !== "auto" || /inset\(50%/.test(style.clipPath))) return true
      }
      const details = el.closest("details:not([open])")
      return Boolean(details && !details.querySelector("summary")?.contains(el))
    }
    const text = (el: Element | null, visually = true) => {
      if (!el || hidden(el, visually)) return ""
      const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT)
      const parts: string[] = []
      while (walker.nextNode()) {
        const parent = walker.currentNode.parentElement
        if (parent && !hidden(parent, visually)) parts.push(walker.currentNode.textContent || "")
      }
      return parts.join(" ").replace(/\s+/g, " ").trim()
    }
    const all = Array.from(document.body.querySelectorAll("*"))
    const boundary = rect(stage)
    const viewport = { x: 0, y: 0, width: innerWidth, height: innerHeight }
    // Use the same tested edge/tolerance algorithm in the browser.
    const hasOverflow = (amounts: OverflowAmounts) => Object.values(amounts).some(value => value > 0)
    const elements: ElementMeasurement[] = []
    for (const el of all) {
      if (el === stage || !stage.contains(el) && !el.matches('[role], button, input, select, textarea, [data-slot]') || hidden(el)) continue
      const control = el.matches('button, input, select, textarea, a[href], [role="button"], [role="checkbox"], [role="radio"], [role="switch"], [role="slider"], [role="combobox"], [role="tab"], [role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"], [role="textbox"], [role="spinbutton"]')
      const r = rect(el)
      // Non-rendering wrappers (display:contents, defs, etc.) have no geometry.
      if (!control && (r.width === 0 || r.height === 0)) continue
      const frameOverflow = overflow(r, viewport)
      const stageOverflow = stage.contains(el) ? overflow(r, boundary) : { left: 0, right: 0, top: 0, bottom: 0 }
      const clipping: ElementMeasurement["clipping"] = []
      for (let parent = el.parentElement; parent; parent = parent.parentElement) {
        const style = getComputedStyle(parent)
        const clipsX = /^(hidden|clip|auto|scroll)$/.test(style.overflowX)
        const clipsY = /^(hidden|clip|auto|scroll)$/.test(style.overflowY)
        if (!clipsX && !clipsY) continue
        const p = rect(parent)
        // The clipping edge is the client/padding box, not the border box.
        const clip = { x: p.x + parent.clientLeft, y: p.y + parent.clientTop, width: parent.clientWidth, height: parent.clientHeight }
        const amounts = overflow(r, clip)
        if (!clipsX) { amounts.left = 0; amounts.right = 0 }
        if (!clipsY) { amounts.top = 0; amounts.bottom = 0 }
        if (hasOverflow(amounts)) clipping.push({ ancestor: describe(parent), rect: clip, overflow: amounts, scrollable: /^(auto|scroll)$/.test(clipsX && (amounts.left || amounts.right) ? style.overflowX : style.overflowY) })
      }
      let accessibleName = "", visibleLabel = ""
      if (control) {
        const labelled = (el.getAttribute("aria-labelledby") || "").split(/\s+/).filter(Boolean).map(id => document.getElementById(id))
        // All controls share the optional native labels/value DOM properties.
        const input = el as HTMLInputElement
        const labels = Array.from(input.labels || [])
        const nameFromContent = !el.matches('input, select, textarea, [role="textbox"], [role="combobox"], [role="spinbutton"]')
        const ownText = nameFromContent ? text(el) : ""
        accessibleName = labelled.map(node => node?.textContent || "").join(" ").trim() || el.getAttribute("aria-label") || labels.map(node => node.textContent || "").join(" ").trim() || el.getAttribute("alt") || (nameFromContent ? text(el, false) : "") || el.getAttribute("title") || ""
        if (el.matches('input[type="submit"], input[type="button"], input[type="reset"]')) accessibleName ||= input.value || (el.matches('[type="submit"]') ? "Submit" : el.matches('[type="reset"]') ? "Reset" : "")
        visibleLabel = [...labelled, ...labels].map(node => text(node)).filter(Boolean).join(" ") || ownText
        // A labelled radio can still look like a bare circle. Nearby actual text
        // counts as context, an aria-label or SVG icon alone does not.
        if (!visibleLabel) {
          const wrapper = el.closest("label") || el.parentElement
          const nearby = wrapper ? Array.from(wrapper.childNodes).filter(node => node !== el && !(node instanceof Element && (node.contains(el) || node.matches('button, input, select, textarea, svg, [role="radio"], [role="checkbox"], [role="switch"]')))) : []
          visibleLabel = nearby.map(node => node instanceof Element ? text(node) : node.textContent || "").join(" ").replace(/\s+/g, " ").trim()
        }
      }
      if (control || hasOverflow(frameOverflow) || hasOverflow(stageOverflow) || clipping.length) elements.push({ element: describe(el), rect: r, frameOverflow, stageOverflow, clipping, control, accessibleName, visibleLabel })
    }
    const charts = Array.from(document.querySelectorAll("svg.recharts-surface"), el => ({ element: describe(el), rect: rect(el), shapes: el.querySelectorAll("path, rect, circle, line, polyline, polygon").length, labels: el.querySelectorAll("text").length }))
    return {
      stage: boundary, frame: viewport,
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      connected: document.querySelector("[data-phx-main]")?.classList.contains("phx-connected") ?? null,
      fonts: document.fonts.status,
      charts, elements,
      failedImages: Array.from(document.images).filter(image => image.complete && image.naturalWidth === 0).map(image => image.currentSrc || image.src),
    }
  }, { overflowSource: overflowAmounts.toString() })
  const findings: Finding[] = []
  for (const item of measurements.elements) {
    const add = (category: Finding["category"], severity: Finding["severity"], message: string, details: unknown) => findings.push({ category, severity, message, implementation, element: item.element, details })
    if (Object.values(item.frameOverflow).some(Boolean)) add("overflow-frame", "warning", "Rendered element extends beyond its iframe viewport", { rect: item.rect, boundary: measurements.frame, amounts: item.frameOverflow })
    if (Object.values(item.stageOverflow).some(Boolean)) add("overflow-stage", "warning", "Rendered element extends beyond the fixture stage", { rect: item.rect, boundary: measurements.stage, amounts: item.stageOverflow })
    for (const clip of item.clipping) add("ancestor-clipping", clip.scrollable ? "info" : "warning", clip.scrollable ? "Content extends beyond a scrollable ancestor (may be intentional)" : "Content is clipped by an overflow-constrained ancestor", { rect: item.rect, ...clip })
    if (item.control && (item.rect.width === 0 || item.rect.height === 0)) add("zero-size-control", "warning", "Otherwise visible control has a zero-size bounding rectangle", { rect: item.rect })
    if (item.control && !item.accessibleName.trim()) add("missing-accessible-name", "warning", "Control has no name from ARIA references, associated labels, visible text, alt, title or button value (name heuristic)", { rect: item.rect })
    if (item.control && !item.visibleLabel.trim()) add("missing-visible-label", "info", "Control has no visible text label or nearby label context; icon-only and intentionally bare controls may be valid", { rect: item.rect, accessibleName: item.accessibleName })
  }
  for (const url of measurements.failedImages) findings.push({ category: "browser-error", severity: "warning", implementation, message: "Image failed to decode", details: { url } })
  return { measurements, findings }
}
