import { expect, test, type Locator } from "@playwright/test"
import { openFixture } from "./component-helpers"

async function scrollState(viewport: Locator) {
  return viewport.evaluate(element => ({
    top: element.scrollTop,
    remaining: element.scrollHeight - element.clientHeight - element.scrollTop,
    height: element.clientHeight,
    contentHeight: element.scrollHeight,
  }))
}

test("phoenix carousel: keyboard and pointer navigation reveal slides and respect end boundaries", async ({ page }) => {
  await openFixture(page, "carousel-vertical")
  const carousel = page.locator("#carousel-vertical-demo")
  const viewport = carousel.locator('[data-slot="carousel-content"]')
  const slides = carousel.locator('[role="group"][aria-roledescription="slide"]')
  const previous = carousel.getByRole("button", { name: "Previous slide" })
  const next = carousel.getByRole("button", { name: "Next slide" })
  await expect(previous).toBeDisabled()
  await expect(next).toBeEnabled()
  await expect(slides).toHaveCount(3)
  const bounds = (await viewport.boundingBox())!
  expect(bounds.width).toBeGreaterThan(200)
  expect(bounds.height).toBeGreaterThan(150)
  expect(bounds.height).toBeLessThan(220)

  await next.click()
  await expect(carousel).toHaveAttribute("phx-value-start-index", "1")
  await expect(previous).toBeEnabled()
  await previous.focus()
  await page.keyboard.press("ArrowRight")
  await expect(carousel).toHaveAttribute("phx-value-start-index", "2")
  await expect(next).toBeDisabled()
  await expect(previous).toBeFocused()
  await expect.poll(async () => {
    const slide = (await slides.nth(2).boundingBox())!
    return Math.abs(slide.y + slide.height - bounds.y - bounds.height)
  }).toBeLessThan(1)
  await page.keyboard.press("ArrowRight")
  await expect(carousel).toHaveAttribute("phx-value-start-index", "2")

  await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + 25)
  await page.mouse.down()
  await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height - 20, { steps: 12 })
  await page.mouse.up()
  await expect(carousel).toHaveAttribute("phx-value-start-index", "1")
  await expect(next).toBeEnabled()
  await expect.poll(async () => {
    const slide = (await slides.nth(1).boundingBox())!
    return Math.abs(slide.y + slide.height - bounds.y - bounds.height)
  }).toBeLessThan(1)
})

test("phoenix resizable: pointer and keyboard resizing preserve panel geometry and enforce constraints", async ({ page }) => {
  await openFixture(page, "resizable-vertical")
  const group = page.locator("#resizable-vertical-demo")
  const first = page.locator("#resizable-vertical-one")
  const second = page.locator("#resizable-vertical-two")
  const handle = page.getByRole("separator")
  await expect(handle).toHaveAttribute("aria-orientation", "horizontal")
  await expect(handle).toHaveAttribute("aria-controls", "resizable-vertical-one")
  await expect(handle).toHaveAttribute("aria-valuenow", "30")
  const initial = (await first.boundingBox())!
  const groupBounds = (await group.boundingBox())!
  expect(groupBounds.height).toBeGreaterThanOrEqual(256)
  expect(groupBounds.width).toBeGreaterThan(250)
  const separator = (await handle.boundingBox())!
  await page.mouse.move(separator.x + separator.width / 2, separator.y + separator.height / 2)
  await page.mouse.down()
  await page.mouse.move(separator.x + separator.width / 2, separator.y + 50, { steps: 10 })
  await page.mouse.up()
  await expect.poll(async () => Number(await handle.getAttribute("aria-valuenow"))).toBeGreaterThan(45)
  await expect(group).toHaveAttribute("phx-value-layout", /resizable-vertical-one/)
  expect((await first.boundingBox())!.height).toBeGreaterThan(initial.height + 40)

  await handle.focus()
  await page.keyboard.press("End")
  await expect(handle).toHaveAttribute("aria-valuenow", "80")
  await expect.poll(async () => JSON.parse((await group.getAttribute("phx-value-layout"))!)["resizable-vertical-one"]).toBeCloseTo(80, 0)
  const large = (await first.boundingBox())!
  const small = (await second.boundingBox())!
  expect(large.height / (large.height + small.height)).toBeCloseTo(0.8, 2)
  expect(small.y).toBeCloseTo(large.y + large.height + separator.height, 0)
  expect(large.height + small.height + separator.height).toBeCloseTo(groupBounds.height - 2, 0)
  await page.keyboard.press("Home")
  await expect(handle).toHaveAttribute("aria-valuenow", "10")
  await page.keyboard.press("ArrowDown")
  await expect(handle).toHaveAttribute("aria-valuenow", "15")
  await expect(handle).toBeFocused()

  await openFixture(page, "resizable-multiple")
  const disabled = page.locator("#resize-fixed-h")
  await expect(disabled).toHaveAttribute("aria-disabled", "true")
  const fixedWidth = (await page.locator("#resize-fixed-a").boundingBox())!.width
  const fixedHandle = (await disabled.boundingBox())!
  await page.mouse.move(fixedHandle.x + fixedHandle.width / 2, fixedHandle.y + fixedHandle.height / 2)
  await page.mouse.down()
  await page.mouse.move(fixedHandle.x + 40, fixedHandle.y + fixedHandle.height / 2, { steps: 8 })
  await page.mouse.up()
  expect((await page.locator("#resize-fixed-a").boundingBox())!.width).toBeCloseTo(fixedWidth, 1)
})

test("phoenix sidebar: desktop toggle and shortcut resize navigation and mobile drawer restores focus", async ({ page }) => {
  await page.setViewportSize({ width: 1100, height: 800 })
  await openFixture(page, "sidebar-collapsed-icon")
  const provider = page.locator("#sidebar-icon")
  const panel = page.locator("#sidebar-icon-panel")
  const trigger = page.locator('[data-slot="sidebar-trigger"]')
  await expect(trigger).toHaveAttribute("aria-expanded", "false")
  const collapsedWidth = (await panel.boundingBox())!.width
  expect(collapsedWidth).toBeGreaterThan(40)
  expect(collapsedWidth).toBeLessThan(100)
  await expect(panel.getByRole("link", { name: "Details" })).toBeHidden()
  await trigger.click()
  await expect(provider).toHaveAttribute("phx-value-open", "true")
  await expect(trigger).toHaveAttribute("aria-expanded", "true")
  await expect.poll(async () => (await panel.boundingBox())!.width).toBeGreaterThan(250)
  await expect(panel.getByRole("link", { name: "Details" })).toBeVisible()
  const expanded = (await panel.boundingBox())!
  expect(expanded.x + expanded.width).toBeCloseTo(1100, 0)
  expect(expanded.height).toBe(800)
  await trigger.focus()
  await page.keyboard.press("Control+b")
  await expect(provider).toHaveAttribute("phx-value-open", "false")
  await expect.poll(async () => (await panel.boundingBox())!.width).toBeLessThan(100)

  await page.setViewportSize({ width: 390, height: 700 })
  await expect(trigger).toHaveAttribute("aria-expanded", "false")
  await trigger.click()
  const dialog = page.getByRole("dialog", { name: "Sidebar" })
  await expect(dialog).toBeVisible()
  await expect(dialog).toHaveAttribute("aria-modal", "true")
  await expect(provider).toHaveAttribute("phx-value-mobile-open", "true")
  const mobileBounds = (await dialog.boundingBox())!
  expect(mobileBounds.width).toBeGreaterThan(240)
  expect(mobileBounds.width).toBeLessThanOrEqual(358)
  expect(mobileBounds.x + mobileBounds.width).toBeCloseTo(390, 0)
  await expect(dialog).toBeFocused()
  await page.keyboard.press("Tab")
  await expect(dialog.getByRole("button", { name: "Overview" })).toBeFocused()
  await page.keyboard.press("Escape")
  await expect(dialog).toBeHidden()
  await expect(provider).toHaveAttribute("phx-value-mobile-open", "false")
  await expect(trigger).toBeFocused()
  await expect.poll(() => page.evaluate(() => document.body.style.overflow)).not.toBe("hidden")
})

test("phoenix chart: signed series geometry and keyboard tooltips update from server data", async ({ page }) => {
  await openFixture(page, "chart-bar-series")
  const canvas = page.locator("#sales-bars-canvas")
  const chart = canvas.getByRole("application", { name: "Monthly desktop and mobile sales" })
  const tooltip = canvas.locator(".recharts-tooltip-wrapper")
  await expect(chart).toBeVisible()
  const bounds = (await chart.boundingBox())!
  expect(bounds.width).toBeGreaterThan(250)
  expect(bounds.height).toBe(240)
  const bars = canvas.locator(".recharts-bar-rectangles path")
  await expect(bars).toHaveCount(6)
  await expect.poll(() => bars.evaluateAll(elements => elements.every(element => {
    const box = (element as SVGGraphicsElement).getBBox()
    return box.width > 5 && box.height > 5
  }))).toBe(true)
  const geometry = await bars.evaluateAll(elements => elements.map(element => {
    const { x, y, width, height } = (element as SVGGraphicsElement).getBBox()
    return { x, y, width, height }
  }))
  expect(geometry[1].height).toBeGreaterThan(geometry[0].height)
  expect(geometry[2].y).toBeCloseTo(geometry[0].y + geometry[0].height, 0)
  for (const bar of geometry) {
    expect(bar.x).toBeGreaterThanOrEqual(0)
    expect(bar.x + bar.width).toBeLessThanOrEqual(bounds.width)
    expect(bar.y).toBeGreaterThanOrEqual(0)
    expect(bar.y + bar.height).toBeLessThanOrEqual(bounds.height)
  }
  await chart.focus()
  await expect(tooltip).toBeVisible()
  await expect(tooltip).toContainText("January")
  await expect(tooltip).toContainText("186")
  await page.keyboard.press("ArrowRight")
  await expect(tooltip).toContainText("February")
  await expect(tooltip).toContainText("305")
  await page.keyboard.press("ArrowRight")
  await expect(tooltip).toContainText("March")
  await expect(tooltip).toContainText("-45")
  await page.keyboard.press("ArrowRight")
  await expect(tooltip).toContainText("April")
  await expect(tooltip.getByText("0", { exact: true })).toHaveCount(2)
  await page.keyboard.press("Escape")
  await expect(tooltip).toBeHidden()

  await page.getByRole("button", { name: "Change chart data" }).click()
  await expect(canvas).toContainText("May")
  await expect(canvas).toContainText("June")
  await expect(canvas).not.toContainText("January")
  await expect(bars).toHaveCount(4)
  await chart.focus()
  await expect(tooltip).toContainText("May")
  await expect(tooltip).toContainText("300")
  await page.keyboard.press("ArrowRight")
  await expect(tooltip).toContainText("June")
  await expect(tooltip).toContainText("-30")
})

test("phoenix message-scroller: appends follow the latest message but preserve readers scrolling earlier", async ({ page }) => {
  await openFixture(page, "message-scroller-end")
  const root = page.locator("#stream-end")
  const viewport = root.locator('[data-slot="message-scroller-viewport"]')
  await page.getByRole("button", { name: "Append messages", exact: true }).click()
  await expect(root.getByText("Added message 8", { exact: true })).toBeVisible()
  await expect(root.locator('[data-slot="message-scroller-item"]')).toHaveCount(8)
  await expect.poll(async () => (await scrollState(viewport)).remaining).toBeLessThanOrEqual(1)
  const state = await scrollState(viewport)
  expect(state.height).toBeGreaterThan(80)
  expect(state.height).toBeLessThan(170)
  expect(state.contentHeight).toBeGreaterThan(state.height * 3)

  await root.getByRole("button", { name: "Earlier", exact: true }).click()
  await expect.poll(async () => (await scrollState(viewport)).top).toBeLessThanOrEqual(1)
  await page.getByRole("button", { name: "Append more", exact: true }).click()
  await expect(root.locator('[data-slot="message-scroller-item"]')).toHaveCount(12)
  await expect.poll(async () => (await scrollState(viewport)).top).toBeLessThanOrEqual(1)
  await expect(root.getByText("First message", { exact: true })).toBeVisible()
  await root.getByRole("button", { name: "Latest", exact: true }).click()
  await expect.poll(async () => (await scrollState(viewport)).remaining).toBeLessThanOrEqual(1)
  const last = (await root.getByText("Added message 12", { exact: true }).boundingBox())!
  const visible = (await viewport.boundingBox())!
  expect(last.y).toBeGreaterThanOrEqual(visible.y)
  expect(last.y + last.height).toBeLessThanOrEqual(visible.y + visible.height + 1)
})

test("phoenix questionnaire: required validation, keyboard choices, back navigation and submission preserve answers", async ({ page }) => {
  await openFixture(page, "questionnaire-flow")
  const form = page.locator("#questionnaire-flow")
  const rating = form.locator('[data-slot="questionnaire-item"][phx-value-name="rating"]')
  await expect(form.locator('[data-slot="questionnaire-progress"]')).toHaveText("Question 1 of 2")
  await expect(form.getByRole("radio", { name: "Unavailable" })).toBeDisabled()
  await form.getByRole("button", { name: "Next", exact: true }).click()
  await expect(rating).toHaveAttribute("aria-invalid", "true")
  await expect(form.getByRole("alert")).toHaveText("Choose an answer to continue.")
  await expect(form.locator('[data-slot="questionnaire-progress"]')).toHaveText("Question 1 of 2")
  await page.keyboard.press("b")
  await expect(form.getByRole("radio", { name: "Great", exact: true })).toBeChecked()
  await expect(form.getByRole("alert")).toHaveCount(0)
  await form.getByRole("button", { name: "Next", exact: true }).click()
  await expect(form.locator('[data-slot="questionnaire-progress"]')).toHaveText("Question 2 of 2")
  await expect(rating).toBeHidden()
  const input = form.getByRole("textbox", { name: "Your feedback" })
  await input.fill("Excellent visit")
  await form.getByRole("button", { name: "Previous", exact: true }).click()
  await expect(form.getByRole("radio", { name: "Great", exact: true })).toBeChecked()
  await form.getByRole("button", { name: "Next", exact: true }).click()
  await expect(input).toHaveValue("Excellent visit")
  await form.getByRole("button", { name: "Submit", exact: true }).click()
  await expect(page.locator("output")).toContainText("Submitted answers:")
  await expect.poll(async () => JSON.parse((await page.locator("output").innerText()).replace("Submitted answers: ", ""))).toEqual({ rating: ["great"], comment: ["Excellent visit"] })
  await expect(form.getByText("Archived question", { exact: true })).toBeHidden()
})

test("phoenix scroll-area: bounded viewport supports wheel and keyboard scrolling without scrolling the page", async ({ page }) => {
  await openFixture(page, "scroll-area")
  const root = page.locator("#scroll-area-demo")
  const viewport = root.locator('[data-slot="scroll-area-viewport"]')
  await expect(viewport).toHaveAttribute("tabindex", "0")
  const rootBounds = (await root.boundingBox())!
  const bounds = (await viewport.boundingBox())!
  expect(rootBounds.width).toBe(192)
  expect(rootBounds.height).toBe(128)
  expect(bounds.width).toBeGreaterThan(100)
  expect(bounds.height).toBeGreaterThan(60)
  expect(bounds.x).toBeGreaterThanOrEqual(rootBounds.x)
  expect(bounds.y + bounds.height).toBeLessThanOrEqual(rootBounds.y + rootBounds.height)
  expect((await scrollState(viewport)).contentHeight).toBeGreaterThan(bounds.height * 3)
  const pageTop = await page.evaluate(() => window.scrollY)
  await viewport.hover()
  await page.mouse.wheel(0, 180)
  await expect.poll(async () => (await scrollState(viewport)).top).toBeGreaterThan(100)
  await viewport.focus()
  await page.keyboard.press("End")
  await expect.poll(async () => (await scrollState(viewport)).remaining).toBeLessThanOrEqual(1)
  const last = (await root.getByText("Item 20", { exact: true }).boundingBox())!
  expect(last.y).toBeGreaterThanOrEqual(bounds.y)
  expect(last.y + last.height).toBeLessThanOrEqual(bounds.y + bounds.height + 1)
  await page.keyboard.press("Home")
  await expect.poll(async () => (await scrollState(viewport)).top).toBeLessThanOrEqual(1)
  expect(await page.evaluate(() => window.scrollY)).toBe(pageTop)
  await expect(viewport).toBeFocused()
})
