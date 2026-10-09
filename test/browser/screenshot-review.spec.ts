import { test, expect } from "@playwright/test"
import { awaitFixture, awaitStableGeometry, inspectFixture } from "../../tools/screenshot-review-browser"

test("independent overflow inspection catches a shared broken narrow chart geometry", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 320 })
  await page.setContent('<body style="margin:0"><main id="fixture-stage" style="width:390px;height:290px;display:flex;align-items:center;justify-content:center"><section id="chart" style="flex-shrink:0;width:426.656px;height:240px"><svg width="426" height="240"><rect width="100" height="100" /></svg></section></main></body>')
  for (const implementation of ["react", "liveview"] as const) {
    const result = await inspectFixture(page.mainFrame(), implementation)
    expect(result.findings).toContainEqual(expect.objectContaining({ category: "overflow-frame", implementation, element: "section#chart" }))
    expect(result.findings).toContainEqual(expect.objectContaining({ category: "overflow-stage", implementation, element: "section#chart" }))
    const chart = result.measurements.elements.find(element => element.element === "section#chart")!
    expect(chart.frameOverflow.left).toBeGreaterThan(18)
    expect(chart.frameOverflow.right).toBeGreaterThan(18)
  }
})

test("ARIA-only radio names do not hide absent visible labels; hidden backing controls are excluded", async ({ page }) => {
  await page.setContent('<main id="fixture-stage"><div><button id="bare" role="radio" aria-label="Standard" style="width:16px;height:16px"></button></div><div><button id="labelled" role="radio" aria-label="Express" style="width:16px;height:16px"></button><span>Express shipping</span></div><button id="zero" style="width:0;height:0;padding:0;border:0">Zero</button><button id="hidden" hidden>Hidden</button><input id="backing" style="position:absolute;width:1px;height:1px;clip:rect(0,0,0,0)" /></main>')
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "react")
  expect(findings).toContainEqual(expect.objectContaining({ category: "missing-visible-label", element: 'button#bare[role="radio"]' }))
  expect(findings.some(finding => finding.category === "missing-accessible-name" && finding.element?.includes("#bare"))).toBe(false)
  expect(findings.some(finding => finding.category === "missing-visible-label" && finding.element?.includes("#labelled"))).toBe(false)
  expect(findings).toContainEqual(expect.objectContaining({ category: "zero-size-control", element: "button#zero" }))
  expect(measurements.elements.some(element => /#hidden|#backing/.test(element.element))).toBe(false)
})

test("ancestor clipping distinguishes intentional scroll access from inaccessible clipping", async ({ page }) => {
  await page.setContent('<main id="fixture-stage"><div id="clipped" style="width:50px;height:50px;overflow:hidden"><button id="cut" style="width:100px;height:100px">Cut</button></div><div id="scrollable" style="width:50px;height:50px;overflow:auto"><button id="scroll" style="width:100px;height:100px">Scroll</button></div></main>')
  const { findings } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({ category: "ancestor-clipping", severity: "warning", element: "button#cut" }))
  expect(findings).toContainEqual(expect.objectContaining({ category: "ancestor-clipping", severity: "info", element: "button#scroll" }))
})

test("chart readiness waits for changing SVG attributes, not merely mounted chart containers", async ({ page }) => {
  await page.setContent('<main id="fixture-stage"><div class="recharts-wrapper" style="width:200px;height:100px"><svg class="recharts-surface" width="200" height="100"><path id="series" d="M0,0L0,0" /></svg></div></main>')
  await page.evaluate(() => {
    let frame = 0
    const animate = () => {
      document.getElementById("series")!.setAttribute("d", `M0,0L${++frame},${frame}`)
      if (frame < 30) requestAnimationFrame(animate)
      else document.getElementById("series")!.setAttribute("data-finished", "true")
    }
    requestAnimationFrame(animate)
  })
  const stable = await awaitStableGeometry(page.mainFrame())
  expect(stable.chartSurfaces).toBe(1)
  expect(stable.stableFrames).toBeGreaterThanOrEqual(12)
  await expect(page.locator("#series")).toHaveAttribute("data-finished", "true")
})

test("portal-only React fixtures become capture-ready after commit without mount children", async ({ page }) => {
  await page.goto("/preview/react-fixture.html?fixture=dialog")
  await awaitFixture(page.mainFrame(), "react", "dialog")
  await expect(page.getByRole("dialog")).toBeVisible()
})

test("React asChild popup triggers survive controlled-tree binding and remain operable", async ({ page }) => {
  await page.goto("/preview/react-fixture.html?fixture=popover")
  await awaitFixture(page.mainFrame(), "react", "popover")
  const trigger = page.getByRole("button", { name: "Open popover", exact: true })
  await expect(trigger).toHaveAttribute("aria-expanded", "true")
  await expect(page.getByRole("dialog")).toBeVisible()
  await page.keyboard.press("Escape")
  await expect(trigger).toHaveAttribute("aria-expanded", "false")
  await expect(page.getByRole("dialog")).toBeHidden()
  await trigger.click()
  await expect(page.getByRole("dialog")).toBeVisible()
})
