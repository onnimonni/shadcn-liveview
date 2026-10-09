export type Severity = "info" | "warning" | "error"
export interface Rect { x: number; y: number; width: number; height: number }
export interface OverflowAmounts { left: number; right: number; top: number; bottom: number }
export interface Finding {
  category: "visual-difference" | "overflow-frame" | "overflow-stage" | "ancestor-clipping" | "zero-size-control" | "missing-accessible-name" | "missing-visible-label" | "capture-failure" | "browser-error"
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
