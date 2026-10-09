import test from "node:test"
import assert from "node:assert/strict"
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import { ChartStyle } from "../login-preview/src/components/ui/chart"

const render = (id: string, config: Parameters<typeof ChartStyle>[0]["config"]) =>
  renderToStaticMarkup(createElement(ChartStyle, { id, config }))

test("chart style identifiers cannot escape their scoped selector or property", () => {
  assert.throws(() => render("chart-x] {body{display:none}", { desktop: { color: "red" } }), Error)
  assert.throws(() => render("chart-safe", { "desktop;bad": { color: "red" } }), Error)
})

test("chart colors cannot inject HTML or an additional CSS rule", () => {
  assert.throws(() => render("chart-safe", { desktop: { color: "</style><script>alert(1)</script>" } }), Error)
  assert.throws(() => render("chart-safe", { desktop: { color: "red;} body {display:none}" } }), Error)
})

