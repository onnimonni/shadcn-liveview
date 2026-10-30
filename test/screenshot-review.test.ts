import test from "node:test"
import assert from "node:assert/strict"
import { comparePixels, overflowAmounts, pairedGeometryFinding, pixelFinding, rectOverlap } from "../tools/screenshot-review-metrics"

const frame = { x: 0, y: 0, width: 390, height: 290 }

test("overflow reports both negative-left and right-edge min-content chart spill", () => {
  const amounts = overflowAmounts({ x: -18.328, y: 20, width: 426.656, height: 240 }, frame)
  assert.ok(Math.abs(amounts.left - 18.328) < 1e-8)
  assert.ok(Math.abs(amounts.right - 18.328) < 1e-8)
  assert.equal(amounts.top, 0)
  assert.equal(amounts.bottom, 0)
})

test("overflow tolerance excludes rounding but not actual clipping on any edge", () => {
  assert.deepEqual(overflowAmounts({ x: -1, y: -0.5, width: 392, height: 291 }, frame), { left: 0, right: 0, top: 0, bottom: 0 })
  assert.deepEqual(overflowAmounts({ x: 0, y: -2, width: 390, height: 295 }, frame), { left: 0, right: 0, top: 2, bottom: 3 })
})

test("overlap ignores disjoint, shared-edge, subpixel and exactly one-pixel collisions on either axis", () => {
  const first = { x: 0, y: 0, width: 100, height: 100 }
  for (const x of [101, 100, 99.5, 99]) assert.equal(rectOverlap(first, { ...first, x }), null)
  for (const y of [101, 100, 99.5, 99]) assert.equal(rectOverlap(first, { ...first, y }), null)
  assert.equal(rectOverlap(first, { x: 0, y: 0, width: 0, height: 100 }), null)
})

test("overlap border and fraction severity boundaries are deterministic", () => {
  const first = { x: 0, y: 0, width: 100, height: 100 }
  assert.equal(rectOverlap(first, { ...first, x: 98 })?.severity, "info")
  assert.equal(rectOverlap(first, { ...first, x: 97.999 })?.severity, "info")
  assert.equal(rectOverlap(first, { ...first, x: 95.001 })?.severity, "info")
  assert.equal(rectOverlap(first, { ...first, x: 95 })?.severity, "warning")
  assert.equal(rectOverlap(first, { ...first, x: 50.001 })?.severity, "warning")
  assert.equal(rectOverlap(first, { ...first, x: 50 })?.severity, "error")
  assert.equal(rectOverlap(first, { ...first, y: 98 })?.severity, "info")
  assert.equal(rectOverlap(first, { ...first, y: 95 })?.severity, "warning")
})

test("overlap reports exact rectangles, area, both fractions and containment without discarding nested panels", () => {
  const firstRect = { x: 10, y: 20, width: 100, height: 80 }
  const secondRect = { x: 60, y: 30, width: 100, height: 40 }
  assert.deepEqual(rectOverlap(firstRect, secondRect), {
    firstRect, secondRect, intersection: { x: 60, y: 30, width: 50, height: 40 }, intersectionArea: 2000,
    firstFraction: 0.25, secondFraction: 0.5, firstContainsSecond: false, secondContainsFirst: false, severity: "error",
  })
  const inner = { x: 20, y: 30, width: 20, height: 20 }
  const contained = rectOverlap(firstRect, inner)!
  assert.equal(contained.firstContainsSecond, true)
  assert.equal(contained.secondContainsFirst, false)
  assert.equal(contained.secondFraction, 1)
  assert.equal(contained.severity, "error")
  assert.equal(rectOverlap(inner, firstRect)?.secondContainsFirst, true)
})

test("equal decoded pixels produce no visual finding and no changed bounds", () => {
  const pixels = new Uint8ClampedArray([0, 50, 100, 255, 255, 255, 255, 255])
  const result = comparePixels(pixels, pixels, 2, 1)
  assert.equal(result.metrics.changedPixels, 0)
  assert.equal(result.metrics.changedBounds, null)
  assert.equal(pixelFinding(result.metrics), null)
  assert.equal(result.diff.length, 8)
})

test("channel threshold is exclusive and changed pixels are marked magenta", () => {
  const a = new Uint8ClampedArray([0, 0, 0, 255, 0, 0, 0, 255])
  const b = new Uint8ClampedArray([24, 0, 0, 255, 25, 0, 0, 255])
  const result = comparePixels(a, b, 2, 1)
  assert.equal(result.metrics.changedPixels, 1)
  assert.equal(result.metrics.changedRatio, 0.5)
  assert.deepEqual(result.metrics.changedBounds, { x: 1, y: 0, width: 1, height: 1 })
  assert.deepEqual(Array.from(result.diff.slice(4)), [255, 0, 120, 255])
  assert.equal(pixelFinding(result.metrics)?.severity, "warning")
})

test("transparent pixels are compared as visible colors composited over white", () => {
  const result = comparePixels([0, 0, 0, 0], [255, 255, 255, 255], 1, 1)
  assert.equal(result.metrics.changedPixels, 0)
  assert.equal(result.metrics.meanChannelDelta, 0)
})

test("minor differences remain informational and mismatched buffers cannot compare", () => {
  const a = new Uint8ClampedArray(100 * 4).fill(255)
  const b = a.slice()
  b[0] = 0
  const result = comparePixels(a, b, 100, 1)
  assert.equal(pixelFinding(result.metrics)?.severity, "info")
  assert.throws(() => comparePixels([0, 0, 0, 255], [], 1, 1), /equally sized/)
  assert.throws(() => comparePixels([], [], 0, 0), /nonempty/)
})

test("paired stage drift remains a warning even when sparse screenshots change few pixels", () => {
  const react = { stage: { x: 0, y: 0, width: 390, height: 320 }, elements: [] }
  const liveview = { stage: { ...react.stage, height: 120 }, elements: [] }
  assert.equal(pairedGeometryFinding(react, liveview)?.category, "paired-geometry-drift")
  assert.equal(pairedGeometryFinding(react, liveview)?.severity, "warning")
  assert.equal(pairedGeometryFinding(react, { ...react, stage: { ...react.stage, height: 319 } }), null)
})

test("paired controls match unique role/name identities across IDs and ignore ambiguous repeated names", () => {
  const stage = { x: 0, y: 0, width: 390, height: 320 }
  const control = { element: 'button#react[role="tab"]', rect: { x: 20, y: 40, width: 50, height: 30 }, control: true, accessibleName: "About" }
  const left = { stage, elements: [control] }
  const shifted = { ...control, element: 'button#live[role="tab"]', rect: { ...control.rect, y: 140 } }
  const finding = pairedGeometryFinding(left, { stage, elements: [shifted] })
  assert.equal(finding?.severity, "warning")
  assert.equal(pairedGeometryFinding(left, { stage, elements: [{ ...shifted, rect: { ...control.rect, y: 44 } }] }), null)
  assert.equal(pairedGeometryFinding({ stage, elements: [control, { ...control, element: 'button#other[role="tab"]' }] }, { stage, elements: [shifted] }), null)
})
