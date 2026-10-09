import { expect, test, type Page } from "@playwright/test"

async function formValues(page: Page, id: string) {
  return page.locator(`#${id}`).evaluate((form: HTMLFormElement) =>
    Object.fromEntries(new FormData(form).entries()),
  )
}

async function childEvents(page: Page) {
  return JSON.parse(await page.locator("#child-events").innerText()) as Record<string, number>
}

async function received(page: Page, event: string, count = 1) {
  await expect.poll(async () => (await childEvents(page))[event]).toBe(count)
}

test.beforeEach(async ({ page, request }) => {
  await expect.poll(async () => {
    try { return (await request.get("/review-preview")).status() }
    catch { return 0 }
  }, { timeout: 25_000 }).toBe(200)
  await page.goto("/review-preview")
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
})

test("uncontrolled values survive patches and changed defaults; reset restores mounted defaults", async ({ page }) => {
  await page.locator("#uncontrolled-check").click()
  await page.locator("#uncontrolled-switch").click()
  await page.locator("#uncontrolled-slider [role=slider]").press("ArrowRight")
  await expect.poll(() => formValues(page, "uncontrolled-form")).toEqual({ check: "on", switch: "on", amount: "26" })
  await page.locator("#review-patch").click()
  await expect(page.locator("#review-tick")).toHaveText("1")
  await page.locator("#review-defaults").click()
  await expect(page.locator("#uncontrolled-check")).toHaveAttribute("aria-checked", "true")
  await expect(page.locator("#uncontrolled-slider [role=slider]")).toHaveAttribute("aria-valuenow", "26")
  expect(await formValues(page, "uncontrolled-form")).toEqual({ check: "on", switch: "on", amount: "26" })
  await page.locator("#uncontrolled-reset").click()
  await expect.poll(() => formValues(page, "uncontrolled-form")).toEqual({ amount: "25" })
  await expect(page.locator("#uncontrolled-check")).toHaveAttribute("aria-checked", "false")
  await expect(page.locator("#uncontrolled-switch")).toHaveAttribute("aria-checked", "false")
})

test("controlled server values remain authoritative", async ({ page }) => {
  await page.locator("#review-controlled").click()
  await expect.poll(() => formValues(page, "controlled-form")).toEqual({ check: "on", switch: "on", amount: "80" })
  await page.locator("#review-controlled").click()
  await expect.poll(() => formValues(page, "controlled-form")).toEqual({ amount: "20" })
  await expect(page.locator("#controlled-check")).toHaveAttribute("aria-checked", "false")
})

test("releasing controlled values retains range structure; reset restores mounted scalar defaults", async ({ page }) => {
  const values = () => page.locator("#transition-form").evaluate((form: HTMLFormElement) => Array.from(new FormData(form).entries()))
  await page.locator("#review-value-mode").click()
  await expect.poll(values).toEqual([["check", "on"], ["switch", "on"], ["amount[]", "20"], ["amount[]", "80"]])
  await expect(page.locator("#transition-slider [role=slider]")).toHaveCount(2)
  await page.locator("#transition-slider [role=slider]").last().press("ArrowRight")
  await expect.poll(values).toEqual([["check", "on"], ["switch", "on"], ["amount[]", "20"], ["amount[]", "81"]])
  await page.locator("#transition-reset").click()
  await expect.poll(() => page.locator("#transition-form").evaluate((form: HTMLFormElement) => {
    const data = new FormData(form)
    return { scalar: data.getAll("amount"), range: data.getAll("amount[]") }
  })).toEqual({ scalar: ["25"], range: [] })
  await expect(page.locator("#transition-slider [role=slider]:visible")).toHaveCount(1)
})

test("textarea content, empty defaults, escaping and server patches use native values", async ({ page }) => {
  const text = "Existing <biography> & notes"
  await expect(page.locator("#review-bio")).toHaveValue(text)
  await expect(page.locator("#review-notes")).toHaveValue(text)
  expect(await formValues(page, "textarea-form")).toEqual({ bio: text, notes: text, empty: "", "group-empty": "", slot: "Slot fallback", precedence: "" })
  await page.locator("#textarea-update").click()
  const updated = "\nUpdated </textarea><script>unsafe()</script> & notes"
  await expect(page.locator("#review-bio")).toHaveValue(updated)
  await expect(page.locator("#review-notes")).toHaveValue(updated)
  expect((await formValues(page, "textarea-form")).bio).toBe(updated)
  await expect(page.locator("#textarea-form script")).toHaveCount(0)
})

test("root or child disabled state disables the editable combobox input across patches", async ({ page }) => {
  const input = page.locator("#review-combo-input")
  await expect(input).toBeDisabled()
  await page.locator("#combo-root-toggle").click()
  await expect(input).toBeEnabled()
  await page.locator("#combo-child-toggle").click()
  await expect(input).toBeDisabled()
  await page.locator("#combo-root-toggle").click()
  await page.locator("#combo-child-toggle").click()
  await expect(input).toBeDisabled()
  await page.locator("#combo-root-toggle").click()
  await expect(input).toBeEnabled()
})

test("nested disclosure events belong only to their nearest root", async ({ page }) => {
  await page.locator("#nested-inner [data-slot=collapsible-trigger] span").click()
  await expect(page.locator("#disclosure-events")).toHaveText('{"inner":1}')
  await expect(page.locator("#nested-outer")).toHaveAttribute("data-state", "open")
  await expect(page.locator("#nested-inner")).toHaveAttribute("data-state", "closed")
  await page.locator("#nested-inner [data-slot=collapsible-trigger]").press("Enter")
  await expect(page.locator("#disclosure-events")).toHaveText('{"inner":2}')
  await expect(page.locator("#nested-outer")).toHaveAttribute("data-state", "open")
})

test("ScrollArea supports wheel, keyboard and both axes without IDs, after patches", async ({ page }) => {
  const viewport = page.locator("#review-scroll [data-slot=scroll-area-viewport]")
  await viewport.hover()
  await page.mouse.wheel(150, 200)
  await expect.poll(() => viewport.evaluate(el => el.scrollTop)).toBeGreaterThan(0)
  await expect.poll(() => viewport.evaluate(el => el.scrollLeft)).toBeGreaterThan(0)
  await viewport.evaluate(el => { el.scrollTop = 0; el.scrollLeft = 0 })
  await viewport.press("ArrowDown")
  await expect.poll(() => viewport.evaluate(el => el.scrollTop)).toBeGreaterThan(0)
  await page.locator("#review-patch").click()
  await expect(page.locator("#review-tick")).toHaveText("1")
  await expect.poll(() => viewport.evaluate(el => getComputedStyle(el).overflowY)).toBe("auto")
  const noId = page.locator("[data-review-no-id] [data-slot=scroll-area-viewport]")
  await noId.hover()
  await page.mouse.wheel(0, 200)
  await expect.poll(() => noId.evaluate(el => el.scrollTop)).toBeGreaterThan(0)
})

test("hook events reach LiveComponent targets, including callback-based OTP completion", async ({ page }) => {
  await page.locator("#child-check").click()
  await received(page, "child-change")
  await page.locator("#child-switch").click()
  await received(page, "child-change", 2)
  await page.locator("#child-slider [role=slider]").press("ArrowRight")
  await received(page, "child-slider")
  await page.locator("#child-toggle").click()
  await received(page, "child-toggle")
  await page.locator("#child-collapse [data-slot=collapsible-trigger]").click()
  await received(page, "control_open")
  await page.locator("#child-radio-b").click()
  await received(page, "child-radio")
  await page.locator("#child-group [data-slot=toggle-group-item]").last().click()
  await received(page, "child-group")
  await page.locator("#child-command-chosen").click()
  await received(page, "shadcn:command-change")
  await page.locator("#child-otp").fill("1234")
  await received(page, "child-otp-change")
  await received(page, "child-otp-complete")
  await page.locator("#child-carousel [data-slot=carousel-next]").click()
  await page.locator("#child-combo-input").click()
  await received(page, "shadcn:combobox-open")
  await page.getByRole("option", { name: "Beta", exact: true }).click()
  await received(page, "shadcn:combobox-change")
  await received(page, "shadcn:carousel-change")
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
})

test("popup, modal and calendar native and hook events target their LiveComponent", async ({ page }) => {
  await page.getByRole("button", { name: "Targeted popup", exact: true }).click()
  await received(page, "shadcn:popup-change")
  await page.getByRole("menuitem", { name: "Alpha", exact: true }).click()
  await received(page, "shadcn:popup-change", 3)
  await page.getByRole("button", { name: "Targeted dialog", exact: true }).click()
  await received(page, "shadcn:modal-open")
  await page.keyboard.press("Escape")
  await received(page, "shadcn:modal-close")
  await page.locator("#child-calendar button[aria-label='Go to the Next Month']").click()
  await received(page, "calendar-month")
  await page.locator('#child-calendar td[data-day="2024-03-15"] button').click()
  await received(page, "calendar-select")
  await page.locator('#child-calendar td[data-day="2024-03-31"] button').press("ArrowRight")
  await received(page, "calendar-month", 2)
  await expect(page.locator("#child-calendar [role=status]")).toHaveText("April 2024")
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
})

test.describe("touch scrolling", () => {
  test.use({ hasTouch: true, isMobile: true, viewport: { width: 390, height: 844 } })

  test("overflow content responds to native touch gestures", async ({ page, context }) => {
    const viewport = page.locator("[data-review-no-id] [data-slot=scroll-area-viewport]")
    await viewport.scrollIntoViewIfNeeded()
    const box = await viewport.boundingBox()
    expect(box).not.toBeNull()
    const session = await context.newCDPSession(page)
    await session.send("Input.synthesizeScrollGesture", {
      x: box!.x + box!.width / 2,
      y: box!.y + box!.height / 2,
      yDistance: -180,
      gestureSourceType: "touch",
      speed: 600,
    })
    await expect.poll(() => viewport.evaluate(el => el.scrollTop)).toBeGreaterThan(0)
    await session.detach()
  })
})
