import test from "node:test"
import assert from "node:assert/strict"
import { comparePixels, overflowAmounts, pixelFinding } from "../tools/screenshot-review-metrics"

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
