import test from "node:test"
import assert from "node:assert/strict"
import { area, curveLinear, curveMonotoneX, curveNatural, curveStep, line } from "victory-vendor/d3-shape"
import { chartHook } from "../tools/converters/chart-hook"

// The colocated hook's curve helpers run before its default export.
const curvePath = new Function(`${chartHook.slice(0, chartHook.indexOf("export default"))}; return curvePath`)() as
  (name: string, top: number[][], base?: number[][]) => string

const factories = { linear: curveLinear, natural: curveNatural, monotone: curveMonotoneX, step: curveStep }
const top = [[5, 120.5], [47.07, 30], [89.14, 180.25], [131.21, 180.25], [173.28, 12.125], [215.34, 99]]
const base = top.map(([x], index) => [x, 200 - index * 7.5])

test("chart hook curves match Recharts' d3-shape lines and stacked areas", () => {
  for (const [name, curve] of Object.entries(factories)) {
    for (const points of [top, top.slice(0, 1), top.slice(0, 2), top.slice(0, 3)]) {
      const lower = base.slice(0, points.length)
      assert.equal(curvePath(name, points), line().curve(curve)(points as [number, number][]), `${name} line of ${points.length}`)
      assert.equal(
        curvePath(name, points, lower),
        area<number[]>().x(p => p[0]).y1(p => p[1]).y0((_, index) => lower[index][1]).curve(curve)(points),
        `${name} area of ${points.length}`,
      )
    }
  }
})
