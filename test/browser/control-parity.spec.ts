import { expect, test, type Page } from "@playwright/test"

async function fixture(page: Page, mode: "react" | "liveview", name: string) {
  await page.goto(mode === "react" ? `/preview/react-fixture.html?fixture=${encodeURIComponent(name)}` : `/live-preview/${encodeURIComponent(name)}?embed=1`)
  if (mode === "liveview") await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
  return page
}

async function formEntries(frame: Page, id: string) {
  return frame.locator(`#${id}`).evaluate((form: HTMLFormElement) => Array.from(new FormData(form).entries()))
}

for (const mode of ["react", "liveview"] as const) {
  test(`${mode}: consecutive slider keyboard commands preserve focus after acknowledgements`, async ({ page }) => {
    const frame = await fixture(page, mode, "slider-external-form")
    const slider = frame.locator("#slider-external")
    const thumb = slider.getByRole("slider")
    await expect(thumb).toHaveAttribute("aria-valuenow", "2")
    await thumb.focus()

    for (const [key, value] of [["ArrowRight", "2.25"], ["End", "10"], ["Home", "0"], ["ArrowRight", "0.25"]]) {
      // Locator.press would refocus a lost thumb and conceal this regression.
      await page.keyboard.press(key)
      if (mode === "liveview") await expect(slider).toHaveAttribute("phx-value-values", `[${value}]`)
      await expect(thumb).toHaveAttribute("aria-valuenow", value)
      await expect(thumb).toBeFocused()
      expect(await formEntries(frame, "slider-external-form")).toEqual([["quantity", value]])
    }
  })

  test(`${mode}: disabled sliders remain submitted but cannot be changed or tabbed into`, async ({ page }) => {
    const frame = await fixture(page, mode, "slider-disabled")
    const slider = frame.locator("#slider-disabled")
    const thumbs = slider.getByRole("slider")
    await expect(thumbs).toHaveCount(2)
    await expect(thumbs.first()).toHaveAttribute("aria-valuenow", "30")
    await slider.click({ position: { x: 4, y: 1 } })
    await page.keyboard.press("ArrowRight")
    await page.keyboard.press("End")
    await expect(thumbs.first()).toHaveAttribute("aria-valuenow", "30")
    await expect(thumbs.last()).toHaveAttribute("aria-valuenow", "60")
    await page.keyboard.press("Tab")
    await expect(frame.locator('#slider-disabled-form button[type="reset"]')).toBeFocused()
    expect(await formEntries(frame, "slider-disabled-form")).toEqual([["amount[]", "30"], ["amount[]", "60"]])
  })

  test(`${mode}: external checkbox reset changes native submission without resetting the visual state`, async ({ page }) => {
    const frame = await fixture(page, mode, "checkbox-multiple-external-form")
    const write = frame.locator("#permission-write")
    await expect(write).toHaveAttribute("aria-checked", "false")
    await write.click()
    if (mode === "liveview") await expect(write).toHaveAttribute("phx-value-state", "checked")
    await expect(write).toHaveAttribute("aria-checked", "true")
    expect(await formEntries(frame, "checkbox-external")).toEqual([["permissions[]", "read"], ["permissions[]", "write"]])
    await frame.locator("#checkbox-external").evaluate((form: HTMLFormElement) => form.reset())
    await expect.poll(() => formEntries(frame, "checkbox-external")).toEqual([["permissions[]", "read"]])
    await expect(write).toHaveAttribute("aria-checked", "true")
    await expect(frame.locator("#permission-read")).toHaveAttribute("aria-checked", "true")
    await write.click()
    if (mode === "liveview") await expect(write).toHaveAttribute("phx-value-state", "unchecked")
    await expect(write).toHaveAttribute("aria-checked", "false")
    expect(await formEntries(frame, "checkbox-external")).toEqual([["permissions[]", "read"]])
  })

  test(`${mode}: external switch reset restores mounted visual and submitted defaults`, async ({ page }) => {
    const frame = await fixture(page, mode, "switch-multiple-external-form")
    const mail = frame.locator("#switch-mail")
    const sms = frame.locator("#switch-sms")
    await expect(mail).toHaveAttribute("aria-checked", "true")
    await mail.click()
    await sms.click()
    if (mode === "liveview") {
      await expect(mail).toHaveAttribute("phx-value-state", "unchecked")
      await expect(sms).toHaveAttribute("phx-value-state", "checked")
    }
    await expect(mail).toHaveAttribute("aria-checked", "false")
    await expect(sms).toHaveAttribute("aria-checked", "true")
    expect(await formEntries(frame, "switch-settings")).toEqual([["sms", "on"]])
    await frame.locator("#switch-settings").evaluate((form: HTMLFormElement) => form.reset())
    if (mode === "liveview") {
      await expect(mail).toHaveAttribute("phx-value-state", "checked")
      await expect(sms).toHaveAttribute("phx-value-state", "unchecked")
    }
    await expect(mail).toHaveAttribute("aria-checked", "true")
    await expect(sms).toHaveAttribute("aria-checked", "false")
    await expect.poll(() => formEntries(frame, "switch-settings")).toEqual([["mail", "on"]])
  })
}
