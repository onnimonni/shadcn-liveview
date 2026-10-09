import { expect, test } from "@playwright/test"
import { openFixture, expectInsideStage } from "./component-helpers"

const staticExamples = [
  ["alert", '[role="alert"]'],
  ["aspect-ratio", '[data-slot="aspect-ratio"]'],
  ["attachment", '[data-slot="attachment"]'],
  ["avatar", '[data-slot="avatar"]'],
  ["badge", '[data-slot="badge"]'],
  ["breadcrumb", 'nav[aria-label="breadcrumb"]'],
  ["bubble", '[data-slot="bubble"]'],
  ["button-group", '[data-slot="button-group"]'],
  ["card", '[data-slot="card"]'],
  ["direction", '#fixture-stage .p-2'],
  ["empty", '[data-slot="empty"]'],
  ["item", '[data-slot="item"]'],
  ["kbd", 'kbd'],
  ["marker", '[data-slot="marker"]'],
  ["message", '[data-slot="message"]'],
  ["separator", '[data-slot="separator"]'],
  ["skeleton", '[data-slot="skeleton"]'],
  ["spinner", '[role="status"]'],
  ["table", 'table'],
] as const

for (const [family, selector] of staticExamples) {
  test(`phoenix ${family}: preserves the React example's usable layout and content`, async ({ page, context }) => {
    await openFixture(page, family)
    const react = await context.newPage()
    await react.goto(`/preview/react-fixture.html?fixture=${family}`)
    for (const target of [page, react]) {
      await target.evaluate(() => document.fonts.ready)
      await target.addStyleTag({ content: "*,*::before,*::after{animation:none!important;transition:none!important}" })
    }
    await expectInsideStage(page, selector)
    await expect(react.locator(selector)).toBeVisible()
    const actual = await page.locator(selector).boundingBox()
    const reference = await react.locator(selector).boundingBox()
    expect(actual!.width).toBeCloseTo(reference!.width, 0)
    expect(actual!.height).toBeCloseTo(reference!.height, 0)
    if (family === "aspect-ratio") expect(actual!.width / actual!.height).toBeCloseTo(16 / 9, 3)
    if (family === "table") {
      const headers = await page.getByRole("columnheader").all()
      const cells = await page.locator("tbody tr").getByRole("cell").all()
      expect(cells.length).toBe(headers.length)
      for (let index = 0; index < headers.length; index++) {
        const header = await headers[index].boundingBox()
        const cell = await cells[index].boundingBox()
        expect(cell!.x).toBeCloseTo(header!.x, 0)
        expect(cell!.width).toBeCloseTo(header!.width, 0)
      }
    }
    await react.close()
  })
}

test("phoenix button: native activation reaches LiveView and acknowledges repeated clicks", async ({ page }) => {
  await openFixture(page, "button")
  const button = page.getByRole("button")
  await button.click()
  await expect(button).toHaveText("Clicked 1 times")
  await button.press("Space")
  await expect(button).toHaveText("Clicked 2 times")
  await openFixture(page, "button-destructive-default")
  await expect(page.getByRole("button")).toBeDisabled()
})

test("phoenix field: label targets a usable input with associated help text", async ({ page }) => {
  await openFixture(page, "field")
  const input = page.getByRole("textbox", { name: "Email address" })
  await page.locator('[data-slot="field-label"]').click()
  await expect(input).toBeFocused()
  await input.fill("onni@example.test")
  await expect(input).toHaveValue("onni@example.test")
  await expect(input).toHaveAccessibleDescription(/never share/)
  await expectInsideStage(page, '[data-slot="field-set"]')
})

test("phoenix input-group: editable value does not overlap its prefix", async ({ page }) => {
  await openFixture(page, "input-group")
  const input = page.getByRole("textbox")
  await input.fill("example.test")
  await expect(input).toHaveValue("example.test")
  const prefix = await page.locator('[data-slot="input-group-addon"]').boundingBox()
  const bounds = await input.boundingBox()
  expect(prefix!.x + prefix!.width).toBeLessThanOrEqual(bounds!.x + 1)
  await expectInsideStage(page, '[data-slot="input-group"]')
})

test("phoenix input: editing and native validity work; disabled value is immutable", async ({ page }) => {
  await openFixture(page, "input")
  const input = page.getByRole("textbox")
  await input.fill("not-an-email")
  expect(await input.evaluate((el: HTMLInputElement) => el.validity.typeMismatch)).toBe(true)
  await input.fill("onni@example.test")
  expect(await input.evaluate((el: HTMLInputElement) => el.validity.valid)).toBe(true)
  await openFixture(page, "input-invalid-disabled")
  await expect(page.getByRole("textbox")).toBeDisabled()
})

test("phoenix label: pointer activation focuses its associated field", async ({ page }) => {
  await openFixture(page, "label")
  const input = page.getByRole("textbox", { name: "Your email address" })
  await page.locator("label").click()
  await expect(input).toBeFocused()
  await input.fill("onni@example.test")
  await expect(input).toHaveValue("onni@example.test")
})

test("phoenix pagination: next, previous and numbered links update the current page", async ({ page }) => {
  await openFixture(page, "pagination")
  const current = page.locator('[aria-current="page"]')
  await expect(current).toHaveText("1")
  await page.getByRole("link", { name: "Go to next page" }).click()
  await expect(current).toHaveText("2")
  await page.getByRole("link", { name: "3", exact: true }).click()
  await expect(current).toHaveText("3")
  await page.getByRole("link", { name: "Go to next page" }).click()
  await expect(current).toHaveText("3")
  await page.getByRole("link", { name: "Go to previous page" }).click()
  await expect(current).toHaveText("2")
})

test("phoenix sonner: server notifications preserve literal text, dismiss and expire", async ({ page }) => {
  await openFixture(page, "sonner")
  const message = "Saved <script> & details"
  await page.getByRole("textbox", { name: "Notification message" }).fill(message)
  await page.getByRole("button", { name: "Show notification", exact: true }).click()
  const toast = page.locator("[data-sonner-toast]")
  await expect(toast).toContainText(message)
  await expect(toast.locator("script")).toHaveCount(0)
  const box = await toast.boundingBox()
  expect(box!.x).toBeGreaterThanOrEqual(0)
  expect(box!.x + box!.width).toBeLessThanOrEqual(page.viewportSize()!.width)
  await page.keyboard.press("Alt+t")
  await expect(page.getByRole("button", { name: "Dismiss notification" })).toBeFocused()
  await page.getByRole("button", { name: "Dismiss notification" }).click()
  await expect(toast).toHaveCount(0)
  await page.getByRole("button", { name: "Show brief notification" }).click()
  await expect(toast).toBeVisible()
  await expect(toast).toHaveCount(0)
})

test("phoenix textarea: multiline editing and readonly native form values are preserved", async ({ page }) => {
  await openFixture(page, "textarea")
  const input = page.getByRole("textbox")
  await input.fill("First line\nSecond <line> & notes")
  await expect(input).toHaveValue("First line\nSecond <line> & notes")
  await openFixture(page, "textarea-native-form")
  await expect(page.getByRole("textbox")).toHaveAttribute("readonly", "")
  await expect(page.getByRole("textbox")).toHaveValue("Saved notes")
})

test("phoenix toggle: pointer and keyboard update acknowledged pressed state", async ({ page }) => {
  await openFixture(page, "toggle")
  const button = page.getByRole("button", { name: "Toggle italic" })
  await button.click()
  await expect(button).toHaveAttribute("aria-pressed", "true")
  await button.press("Space")
  await expect(button).toHaveAttribute("aria-pressed", "false")
  await button.press("Enter")
  await expect(button).toHaveAttribute("aria-pressed", "true")
})
