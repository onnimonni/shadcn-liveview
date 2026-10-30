import type { Frame } from "@playwright/test"
import { overflowAmounts, rectOverlap, type Finding, type Rect, type RectOverlap, type OverflowAmounts } from "./screenshot-review-metrics"

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

export interface ResponsibleElement { element: string; domPath: string; rect: Rect }
export interface OverlapMeasurement extends RectOverlap {
  category: "panel-overlap" | "control-overlap"
  responsibleElements: [ResponsibleElement, ResponsibleElement]
}
export interface OcclusionMeasurement {
  element: string
  domPath: string
  rect: Rect
  sampledRect: Rect
  samples: { x: number; y: number; occluder: ResponsibleElement | null }[]
  blockedSamples: number
  testedSamples: number
  blockedFraction: number
  occluders: (ResponsibleElement & { overlap: RectOverlap | null; blockedSamples: number })[]
}
export interface SpacingMeasurement {
  category: "crowded-controls" | "navigation-misalignment"
  responsibleElements: [ResponsibleElement, ResponsibleElement]
  firstRect: Rect
  secondRect: Rect
  axis: "horizontal" | "vertical"
  distance: number
  threshold: number
  group?: ResponsibleElement
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
  overlaps: OverlapMeasurement[]
  occlusions: OcclusionMeasurement[]
  spacing: SpacingMeasurement[]
}

export async function inspectFixture(frame: Frame, implementation: "react" | "liveview") {
  const measurements: FixtureMeasurements = await frame.evaluate(({ overflowSource, overlapSource }) => {
    const overflow: typeof overflowAmounts = new Function(`return (${overflowSource})`)()
    const overlap: typeof rectOverlap = new Function(`return (${overlapSource})`)()
    const stage = document.getElementById("fixture-stage")!
    const rect = (el: Element): Rect => {
      const { x, y, width, height } = el.getBoundingClientRect()
      return { x, y, width, height }
    }
    const describe = (el: Element) => `${el.tagName.toLowerCase()}${el.id ? `#${el.id}` : ""}${el.getAttribute("data-slot") ? `[data-slot="${el.getAttribute("data-slot")}"]` : ""}${el.getAttribute("role") ? `[role="${el.getAttribute("role")}"]` : ""}`
    const hidden = (el: Element, visually = true, accessibility = true) => {
      if (el.matches('input[type="hidden"], script, style, link, meta, template, svg defs *, svg defs, svg clipPath *, svg clipPath')) return true
      for (let current: Element | null = el; current; current = current.parentElement) {
        const style = getComputedStyle(current)
        if (current.hasAttribute("hidden") || accessibility && current.getAttribute("aria-hidden") === "true" || style.display === "none" || style.visibility === "hidden" || style.visibility === "collapse" || visually && Number(style.opacity) === 0 || style.contentVisibility === "hidden") return true
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
    const establishesContainingBlock = (el: Element, style: CSSStyleDeclaration, position: "absolute" | "fixed") => {
      if (style.display === "none" || style.display === "contents") return false
      if (position === "absolute" && style.position !== "static") return true
      // Individual transforms establish the same containing blocks as transform,
      // even when computed transform is "none" (for example Tailwind translate).
      const transformable = style.display !== "inline" || el.matches("img, video, canvas, iframe, input, textarea, select, object, embed")
      if (transformable && [style.transform, style.translate, style.rotate, style.scale, style.perspective].some(value => value && value !== "none")) return true
      if (el !== document.documentElement && [style.filter, style.backdropFilter].some(value => value && value !== "none")) return true
      if (/\b(layout|paint|strict|content)\b/.test(style.contain) || style.contentVisibility === "auto") return true
      const anticipated = style.willChange.split(",").map(value => value.trim())
      return anticipated.some(property =>
        transformable && /^(transform|translate|rotate|scale|perspective)$/.test(property) ||
        el !== document.documentElement && /^(filter|backdrop-filter)$/.test(property) ||
        property === "contain"
      )
    }
    // Yield only overflow clips that apply to the element's painting chain.
    // An out-of-flow node (including a control's ancestor) bypasses overflow
    // between itself and its containing block; clipping resumes at that block.
    // Repeating this at each ancestor handles nested absolute/fixed subtrees.
    function* applicableClipAncestors(el: Element) {
      let escaping: "absolute" | "fixed" | null = null
      for (let node = el, parent = el.parentElement; parent; node = parent, parent = parent.parentElement) {
        if (!escaping) {
          const position = getComputedStyle(node).position
          if (position === "absolute" || position === "fixed") escaping = position
        }
        const style = getComputedStyle(parent)
        if (escaping && establishesContainingBlock(parent, style, escaping)) escaping = null
        if (escaping) continue
        const clipsX = /^(hidden|clip|auto|scroll)$/.test(style.overflowX)
        const clipsY = /^(hidden|clip|auto|scroll)$/.test(style.overflowY)
        if (!clipsX && !clipsY) continue
        const p = rect(parent)
        // The clipping edge is the client/padding box, not the border box.
        const clip = { x: p.x + parent.clientLeft, y: p.y + parent.clientTop, width: parent.clientWidth, height: parent.clientHeight }
        yield { parent, style, clipsX, clipsY, clip }
      }
    }
    const elements: ElementMeasurement[] = []
    const controlNodes: Element[] = []
    for (const el of all) {
      if (el === stage || !stage.contains(el) && !el.matches('[role], button, input, select, textarea, [data-slot]') || hidden(el)) continue
      const control = el.matches('button, input, select, textarea, a[href], [role="button"], [role="checkbox"], [role="radio"], [role="switch"], [role="slider"], [role="combobox"], [role="tab"], [role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"], [role="textbox"], [role="spinbutton"]')
      const r = rect(el)
      // Non-rendering wrappers (display:contents, defs, etc.) have no geometry.
      if (!control && (r.width === 0 || r.height === 0)) continue
      const frameOverflow = overflow(r, viewport)
      const stageOverflow = stage.contains(el) ? overflow(r, boundary) : { left: 0, right: 0, top: 0, bottom: 0 }
      const clipping: ElementMeasurement["clipping"] = []
      for (const { parent, style, clipsX, clipsY, clip } of applicableClipAncestors(el)) {
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
      if (control && r.width > 0 && r.height > 0) controlNodes.push(el)
    }
    const identify = (el: Element): ResponsibleElement => {
      const path: string[] = []
      for (let current: Element | null = el; current; current = current.parentElement) {
        if (current.id) { path.unshift(`#${CSS.escape(current.id)}`); break }
        const siblings = current.parentElement ? Array.from(current.parentElement.children).filter(node => node.tagName === current!.tagName) : [current]
        path.unshift(`${current.tagName.toLowerCase()}:nth-of-type(${siblings.indexOf(current) + 1})`)
      }
      return { element: describe(el), domPath: path.join(" > "), rect: rect(el) }
    }
    const modals = all.filter(el => el.matches('[aria-modal="true"], dialog:modal') && !hidden(el) && rect(el).width > 0 && rect(el).height > 0)
    const modalCoverage = (control: Element, covering: Element) => {
      for (const modal of modals) {
        if (modal.contains(control)) continue
        if (modal.contains(covering)) return true
        const slot = modal.getAttribute("data-slot")
        if (slot?.endsWith("-content") && covering.closest(`[data-slot="${slot.slice(0, -8)}-overlay"]`)) return true
      }
      return false
    }
    const related = (first: Element, second: Element) => {
      if (first.contains(second) || second.contains(first)) return true
      // All native labelable controls expose the same optional labels property.
      const firstInput = first as HTMLInputElement, secondInput = second as HTMLInputElement
      const firstLabels = Array.from(firstInput.labels || [])
      const secondLabels = Array.from(secondInput.labels || [])
      if (firstLabels.some(label => label.contains(second)) || secondLabels.some(label => label.contains(first))) return true
      if (first instanceof HTMLLabelElement && first.control === second || second instanceof HTMLLabelElement && second.control === first) return true
      // Some libraries retain a native backing input next to a styled control.
      // Exempt only non-hit-testable native checkbox/radio inputs with a matching
      // semantic sibling; ordinary independent inputs must still be inspected.
      for (const [native, custom] of [[first, second], [second, first]]) {
        if (native instanceof HTMLInputElement && /^(checkbox|radio)$/.test(native.type) && native.parentElement === custom.parentElement && getComputedStyle(native).pointerEvents === "none" && (custom.getAttribute("role") === native.type || native.type === "checkbox" && custom.getAttribute("role") === "switch")) return true
      }
      return false
    }
    const overlaps: OverlapMeasurement[] = []
    const panels = all.filter(el => el.matches('[role="menu"], [role="listbox"]') && !hidden(el) && rect(el).width > 0 && rect(el).height > 0)
    for (let i = 0; i < panels.length; i++) {
      for (let j = i + 1; j < panels.length; j++) {
        // A submenu can be a DOM descendant and still be a separate floating
        // panel. Ancestry/containment is deliberately NOT an exemption here.
        const geometry = overlap(rect(panels[i]), rect(panels[j]))
        if (geometry) overlaps.push({ category: "panel-overlap", ...geometry, responsibleElements: [identify(panels[i]), identify(panels[j])] })
      }
    }
    const spacing: SpacingMeasurement[] = []
    const compoundSelector = '[data-slot="button-group"], [data-slot="input-group"], [data-slot="navigation-menu-list"], [role="toolbar"], [role="tablist"], [role="menubar"], [role="menu"], [role="listbox"], nav, [role="navigation"]'
    for (let i = 0; i < controlNodes.length; i++) {
      for (let j = i + 1; j < controlNodes.length; j++) {
        const first = controlNodes[i], second = controlNodes[j]
        if (related(first, second) || modalCoverage(first, second) || modalCoverage(second, first)) continue
        const firstRect = rect(first), secondRect = rect(second)
        const geometry = overlap(firstRect, secondRect)
        if (geometry?.firstContainsSecond || geometry?.secondContainsFirst) continue
        if (geometry) {
          overlaps.push({ category: "control-overlap", ...geometry, responsibleElements: [identify(first), identify(second)] })
          continue
        }
        // Touching members of an explicit compound widget are intentional.
        const compound = first.closest(compoundSelector)
        if (compound && compound === second.closest(compoundSelector)) continue
        const gapX = Math.max(firstRect.x, secondRect.x) - Math.min(firstRect.x + firstRect.width, secondRect.x + secondRect.width)
        const gapY = Math.max(firstRect.y, secondRect.y) - Math.min(firstRect.y + firstRect.height, secondRect.y + secondRect.height)
        const axis = gapX >= 0 && gapX <= 2 && -gapY >= Math.min(firstRect.height, secondRect.height) / 2 ? "horizontal" : gapY >= 0 && gapY <= 2 && -gapX >= Math.min(firstRect.width, secondRect.width) / 2 ? "vertical" : null
        if (axis) spacing.push({ category: "crowded-controls", responsibleElements: [identify(first), identify(second)], firstRect, secondRect, axis, distance: axis === "horizontal" ? gapX : gapY, threshold: 2 })
      }
    }
    const navigationSelector = '[data-slot="navigation-menu-list"], [role="menubar"], nav, [role="navigation"], nav ul, nav ol, [role="navigation"] ul, [role="navigation"] ol'
    for (const group of all.filter(el => el.matches(navigationSelector) && !hidden(el))) {
      const style = getComputedStyle(group)
      if (!/flex/.test(style.display) || style.flexWrap !== "nowrap" || !/^row/.test(style.flexDirection) || group.getAttribute("aria-orientation") === "vertical" || group.getAttribute("data-orientation") === "vertical") continue
      const controls = controlNodes.filter(el => group.contains(el) && el.closest(navigationSelector) === group && !el.closest('[role="menu"], [role="listbox"], [role="dialog"], [data-slot="navigation-menu-content"]'))
      if (controls.length < 3) continue
      const centers = controls.map(el => { const r = rect(el); return r.y + r.height / 2 }).sort((a, b) => a - b)
      const median = centers[Math.floor(centers.length / 2)]
      const reference = controls.find(el => { const r = rect(el); return r.y + r.height / 2 === median })!
      for (const control of controls) {
        const firstRect = rect(control), secondRect = rect(reference)
        const distance = Math.abs(firstRect.y + firstRect.height / 2 - median)
        const threshold = Math.max(4, Math.min(firstRect.height, secondRect.height) * 0.2)
        if (distance > threshold) spacing.push({ category: "navigation-misalignment", responsibleElements: [identify(control), identify(reference)], firstRect, secondRect, axis: "horizontal", distance, threshold, group: identify(group) })
      }
    }
    const occlusions: OcclusionMeasurement[] = []
    for (const control of controlNodes) {
      const r = rect(control)
      let left = Math.max(0, r.x), top = Math.max(0, r.y), right = Math.min(innerWidth, r.x + r.width), bottom = Math.min(innerHeight, r.y + r.height)
      for (const { clipsX, clipsY, clip } of applicableClipAncestors(control)) {
        if (clipsX) { left = Math.max(left, clip.x); right = Math.min(right, clip.x + clip.width) }
        if (clipsY) { top = Math.max(top, clip.y); bottom = Math.min(bottom, clip.y + clip.height) }
      }
      if (right - left <= 2 || bottom - top <= 2) continue
      const samples: OcclusionMeasurement["samples"] = []
      const blockers = new Map<Element, number>()
      for (const fy of [0.2, 0.5, 0.8]) {
        for (const fx of [0.2, 0.5, 0.8]) {
          const x = left + (right - left) * fx, y = top + (bottom - top) * fy
          // aria-hidden excludes backing controls from our candidate set, but
          // does NOT make a painted overlay invisible to the user.
          const hit = document.elementsFromPoint(x, y).find(el => !hidden(el, true, false))
          // Hit testing includes expanded pseudo-elements outside the element's
          // border box; requiring rectangle overlap would miss intercepted input.
          const blocked = hit && !related(control, hit) && !modalCoverage(control, hit)
          const occluder = blocked ? identify(hit!) : null
          samples.push({ x, y, occluder })
          if (occluder) blockers.set(hit!, (blockers.get(hit!) || 0) + 1)
        }
      }
      const blockedSamples = samples.filter(sample => sample.occluder).length
      if (!blockedSamples) continue
      occlusions.push({
        element: describe(control), domPath: identify(control).domPath, rect: r,
        sampledRect: { x: left, y: top, width: right - left, height: bottom - top },
        samples, blockedSamples, testedSamples: samples.length, blockedFraction: blockedSamples / samples.length,
        occluders: Array.from(blockers, ([el, count]) => ({ ...identify(el), overlap: overlap(r, rect(el)), blockedSamples: count })),
      })
    }
    const charts = Array.from(document.querySelectorAll("svg.recharts-surface"), el => ({ element: describe(el), rect: rect(el), shapes: el.querySelectorAll("path, rect, circle, line, polyline, polygon").length, labels: el.querySelectorAll("text").length }))
    return {
      stage: boundary, frame: viewport,
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      connected: document.querySelector("[data-phx-main]")?.classList.contains("phx-connected") ?? null,
      fonts: document.fonts.status,
      charts, elements, overlaps, occlusions, spacing,
      failedImages: Array.from(document.images).filter(image => image.complete && image.naturalWidth === 0).map(image => image.currentSrc || image.src),
    }
  }, { overflowSource: overflowAmounts.toString(), overlapSource: rectOverlap.toString() })
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
  for (const item of measurements.overlaps) findings.push({
    category: item.category, severity: item.severity, implementation, element: item.responsibleElements[0].element,
    message: item.category === "panel-overlap" ? "Separate visible menu/listbox panels intersect (including nested submenu panels)" : "Independent visible controls intersect",
    details: { ...item, rect: item.firstRect, ratios: { first: item.firstFraction, second: item.secondFraction } },
  })
  for (const item of measurements.occlusions) findings.push({
    category: "control-occlusion", severity: item.blockedSamples < 3 ? "info" : item.blockedFraction >= 2 / 3 ? "error" : "warning", implementation, element: item.element,
    message: `${item.blockedSamples}/${item.testedSamples} interior hit-test samples of a visible control are covered by external elements`,
    details: { ...item, responsibleElements: [{ element: item.element, domPath: item.domPath, rect: item.rect }, ...item.occluders] },
  })
  for (const item of measurements.spacing) findings.push({
    category: item.category, severity: item.category === "crowded-controls" ? "info" : "warning", implementation, element: item.responsibleElements[0].element,
    message: item.category === "crowded-controls" ? "Independent controls touch or have at most 2 CSS px separation; check whether visual grouping is intentional" : "Top-level navigation controls have inconsistent cross-axis centers in a non-wrapping horizontal group",
    details: { ...item, rect: item.firstRect },
  })
  for (const url of measurements.failedImages) findings.push({ category: "browser-error", severity: "warning", implementation, message: "Image failed to decode", details: { url } })
  return { measurements, findings }
}
