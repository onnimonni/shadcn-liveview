export type Severity = "info" | "warning" | "error"
export interface Rect { x: number; y: number; width: number; height: number }
export interface OverflowAmounts { left: number; right: number; top: number; bottom: number }
export interface Finding {
  category: "visual-difference" | "paired-geometry-drift" | "overflow-frame" | "overflow-stage" | "ancestor-clipping" | "zero-size-control" | "missing-accessible-name" | "missing-visible-label" | "capture-failure" | "browser-error" | "panel-overlap" | "control-overlap" | "control-occlusion" | "navigation-misalignment" | "crowded-controls"
  severity: Severity
  message: string
  implementation?: "react" | "liveview"
  element?: string
  details?: unknown
}

// A CSS-pixel tolerance avoids flagging subpixel rounding at shared edges.
export function overflowAmounts(rect: Rect, boundary: Rect, tolerance = 1) {
  const raw = {
    left: boundary.x - rect.x,
    right: rect.x + rect.width - boundary.x - boundary.width,
    top: boundary.y - rect.y,
    bottom: rect.y + rect.height - boundary.y - boundary.height,
  }
  return Object.fromEntries(Object.entries(raw).map(([side, value]) => [side, value > tolerance ? value : 0])) as OverflowAmounts
}

export interface RectOverlap {
  firstRect: Rect
  secondRect: Rect
  intersection: Rect
  intersectionArea: number
  firstFraction: number
  secondFraction: number
  firstContainsSecond: boolean
  secondContainsFirst: boolean
  severity: Severity
}

// Shared by unit tests and the DOM detector. Fractions use the full rectangles,
// not their union, so a small panel covered by a large one remains significant.
export function rectOverlap(firstRect: Rect, secondRect: Rect): RectOverlap | null {
  if (firstRect.width <= 0 || firstRect.height <= 0 || secondRect.width <= 0 || secondRect.height <= 0) return null
  const x = Math.max(firstRect.x, secondRect.x), y = Math.max(firstRect.y, secondRect.y)
  const width = Math.min(firstRect.x + firstRect.width, secondRect.x + secondRect.width) - x
  const height = Math.min(firstRect.y + firstRect.height, secondRect.y + secondRect.height) - y
  // Shared borders and subpixel collisions are not evidence of broken layout.
  if (width <= 1 || height <= 1) return null
  const intersectionArea = width * height
  const firstFraction = intersectionArea / (firstRect.width * firstRect.height)
  const secondFraction = intersectionArea / (secondRect.width * secondRect.height)
  const fraction = Math.max(firstFraction, secondFraction)
  return {
    firstRect, secondRect, intersection: { x, y, width, height }, intersectionArea, firstFraction, secondFraction,
    firstContainsSecond: firstRect.x <= secondRect.x && firstRect.y <= secondRect.y && firstRect.x + firstRect.width >= secondRect.x + secondRect.width && firstRect.y + firstRect.height >= secondRect.y + secondRect.height,
    secondContainsFirst: secondRect.x <= firstRect.x && secondRect.y <= firstRect.y && secondRect.x + secondRect.width >= firstRect.x + firstRect.width && secondRect.y + secondRect.height >= firstRect.y + firstRect.height,
    severity: width <= 2 || height <= 2 || fraction < 0.05 ? "info" : fraction >= 0.5 ? "error" : "warning",
  }
}

interface GeometrySnapshot {
  stage: Rect
  elements: { element: string; rect: Rect; control: boolean; accessibleName: string }[]
}

// Sparse demos can move completely while changing very few viewport pixels.
// Match only unique role/name pairs; duplicate labels are ambiguous evidence.
export function pairedGeometryFinding(react: GeometrySnapshot, liveview: GeometrySnapshot): Finding | null {
  const differs = (a: Rect, b: Rect, tolerance: number) =>
    (["x", "y", "width", "height"] as const).some(key => Math.abs(a[key] - b[key]) > tolerance)
  const controls = (snapshot: GeometrySnapshot) => {
    const matches = new Map<string, GeometrySnapshot["elements"]>()
    for (const item of snapshot.elements) {
      if (!item.control || !item.accessibleName.trim()) continue
      const role = item.element.match(/\[role="([^"]+)"\]/)?.[1] || item.element.match(/^[a-z]+/)?.[0]
      if (!role) continue
      const key = role + ":" + item.accessibleName.trim().replace(/\s+/g, " ")
      const items = matches.get(key) || []
      items.push(item)
      matches.set(key, items)
    }
    return matches
  }
  const left = controls(react), right = controls(liveview)
  const moved: { identity: string; react: GeometrySnapshot["elements"][number]; liveview: GeometrySnapshot["elements"][number] }[] = []
  for (const [identity, items] of left) {
    const other = right.get(identity)
    if (items.length === 1 && other?.length === 1 && differs(items[0].rect, other[0].rect, 4)) {
      moved.push({ identity, react: items[0], liveview: other[0] })
    }
  }
  const stageChanged = differs(react.stage, liveview.stage, 1)
  if (!stageChanged && !moved.length) return null
  return {
    category: "paired-geometry-drift", severity: "warning",
    message: "Paired stage or uniquely named control geometry differs; sparse pixels cannot establish alignment",
    details: { stageChanged, stage: { react: react.stage, liveview: liveview.stage }, controls: moved },
  }
}

export interface PixelMetrics {
  width: number
  height: number
  pixels: number
  changedPixels: number
  changedRatio: number
  meanChannelDelta: number
  maxChannelDelta: number
  changedBounds: Rect | null
  threshold: number
}

// This function also runs inside Chromium on browser-decoded PNG RGBA buffers.
export function comparePixels(a: ArrayLike<number>, b: ArrayLike<number>, width: number, height: number, threshold = 24) {
  if (!Number.isInteger(width) || !Number.isInteger(height) || width <= 0 || height <= 0 || a.length !== width * height * 4 || b.length !== a.length) {
    throw new Error("Pixel comparison requires equally sized, nonempty RGBA images")
  }
  const diff = new Uint8ClampedArray(a.length)
  let changedPixels = 0, totalDelta = 0, maxChannelDelta = 0
  let left = width, top = height, right = -1, bottom = -1
  for (let offset = 0; offset < a.length; offset += 4) {
    let delta = 0
    for (let channel = 0; channel < 3; channel++) {
      // Composite transparency over white before comparing the visible colors.
      const av = a[offset + channel] * a[offset + 3] / 255 + 255 - a[offset + 3]
      const bv = b[offset + channel] * b[offset + 3] / 255 + 255 - b[offset + 3]
      const distance = Math.abs(av - bv)
      totalDelta += distance
      delta = Math.max(delta, distance)
    }
    maxChannelDelta = Math.max(maxChannelDelta, delta)
    const changed = delta > threshold
    if (changed) {
      changedPixels++
      const pixel = offset / 4, x = pixel % width, y = Math.floor(pixel / width)
      left = Math.min(left, x); top = Math.min(top, y); right = Math.max(right, x); bottom = Math.max(bottom, y)
    }
    const gray = Math.round((a[offset] + a[offset + 1] + a[offset + 2]) / 3)
    diff[offset] = changed ? 255 : Math.round(gray * 0.25 + 191)
    diff[offset + 1] = changed ? 0 : diff[offset]
    diff[offset + 2] = changed ? 120 : diff[offset]
    diff[offset + 3] = 255
  }
  const pixels = width * height
  const metrics: PixelMetrics = {
    width, height, pixels, changedPixels, changedRatio: changedPixels / pixels,
    meanChannelDelta: totalDelta / (pixels * 3), maxChannelDelta,
    changedBounds: changedPixels ? { x: left, y: top, width: right - left + 1, height: bottom - top + 1 } : null,
    threshold,
  }
  return { metrics, diff }
}

export function pixelFinding(metrics: PixelMetrics): Finding | null {
  if (metrics.changedPixels === 0) return null
  // Low-level antialiasing/SSR-vs-client drift remains available for review.
  const severity: Severity = metrics.changedRatio >= 0.05 ? "warning" : "info"
  return {
    category: "visual-difference", severity,
    message: `${(metrics.changedRatio * 100).toFixed(2)}% of pixels differ by more than ${metrics.threshold}/255 in a color channel`,
    details: metrics,
  }
}
