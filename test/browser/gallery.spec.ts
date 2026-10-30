import { expect, test, type Page } from "@playwright/test"

test("react: shipping labels and submission remain usable in a narrow gallery iframe", async ({ page }) => {
    await page.goto("/preview/react-ssr.html")
    const owner = page.locator('iframe[data-fixture="radio-group-required-vertical"]')
    await owner.scrollIntoViewIfNeeded()
    await owner.evaluate(iframe => { iframe.style.width = "240px" })
    const frame = page.frameLocator('iframe[data-fixture="radio-group-required-vertical"]')
    const standard = frame.getByRole("radio", { name: "Standard", exact: true })
    const express = frame.getByRole("radio", { name: "Express", exact: true })
    const overnight = frame.getByRole("radio", { name: "Overnight", exact: true })
    const submit = frame.getByRole("button", { name: "Submit shipping", exact: true })
    const status = frame.locator("#shipping-form output")
    for (const name of ["Standard", "Express", "Overnight"]) {
      await expect(frame.locator(`label[for="${name.toLowerCase()}"]`)).toBeVisible()
    }
    await expect(frame.getByRole("radiogroup")).toHaveAttribute("aria-required", "true")
    await expect(standard).toBeChecked()
    await expect(express).toBeDisabled()
    await submit.click()
    await expect(status).toHaveText("Submitted shipping: standard")
    await frame.locator('label[for="overnight"]').click()
    await expect(overnight).toBeChecked()
    await expect(standard).not.toBeChecked()
    const disabledLabel = (await frame.locator('label[for="express"]').boundingBox())!
    await page.mouse.click(disabledLabel.x + disabledLabel.width / 2, disabledLabel.y + disabledLabel.height / 2)
    await expect(express).not.toBeChecked()
    await expect(overnight).toBeChecked()
    expect(await frame.locator("#shipping-form").evaluate((form: HTMLFormElement) => Array.from(new FormData(form).entries()))).toEqual([["shipping", "overnight"]])
    await submit.click()
    await expect(status).toHaveText("Submitted shipping: overnight")
    await standard.focus()
    await standard.press("ArrowDown")
    await expect(overnight).toBeFocused()
    await expect(overnight).toBeChecked()
    const buttonBounds = await submit.boundingBox()
    const statusBounds = await status.boundingBox()
    const frameBounds = await owner.boundingBox()
    expect(statusBounds!.y).toBeGreaterThanOrEqual(buttonBounds!.y + buttonBounds!.height + 8)
    for (const bounds of [buttonBounds!, statusBounds!]) {
      expect(bounds.x).toBeGreaterThanOrEqual(frameBounds!.x)
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(frameBounds!.x + frameBounds!.width + 1)
    }
  })

  test("react: controlled tabs update without affecting another example", async ({ page }) => {
    await page.goto("/preview/react-ssr.html")
    await page.locator('iframe[data-fixture="tabs-history"]').scrollIntoViewIfNeeded()
    const first = page.frameLocator('iframe[data-fixture="tabs-history"]')
    const other = page.frameLocator('iframe[data-fixture="tabs"]')
    await expect(first.getByRole("tab", { name: "History", exact: true })).toHaveAttribute("aria-selected", "true")
    await first.getByRole("tab", { name: "Overview", exact: true }).click()
    await expect(first.getByRole("tab", { name: "Overview", exact: true })).toHaveAttribute("aria-selected", "true")
    await expect(first.getByRole("tab", { name: "History", exact: true })).toHaveAttribute("aria-selected", "false")
    await expect(other.getByRole("tab", { name: "Account", exact: true })).toHaveAttribute("aria-selected", "true")
  })

  test("react: independent tab instances retain their selections", async ({ page }) => {
    await page.goto("/preview/react-ssr.html")
    await page.locator('iframe[data-fixture="tabs-instances"]').scrollIntoViewIfNeeded()
    const frame = page.frameLocator('iframe[data-fixture="tabs-instances"]')
    await frame.locator("#tabs-first").getByRole("tab", { name: "History", exact: true }).click()
    await expect(frame.locator("#tabs-first").getByRole("tab", { name: "History", exact: true })).toHaveAttribute("aria-selected", "true")
    await expect(frame.locator("#tabs-second").getByRole("tab", { name: "Settings", exact: true })).toHaveAttribute("aria-selected", "true")
  })

  test("react: dialog portals stay within their frame and can close and reopen", async ({ page }) => {
    await page.goto("/preview/react-ssr.html")
    const owner = page.locator('iframe[data-fixture="dialog-closed"]')
    await owner.scrollIntoViewIfNeeded()
    const frame = page.frameLocator('iframe[data-fixture="dialog-closed"]')
    await frame.locator('[data-slot="dialog-trigger"]').click()
    const dialog = frame.getByRole("dialog")
    await expect(dialog).toBeVisible()
    const bounds = await dialog.boundingBox()
    const frameBounds = await owner.boundingBox()
    expect(bounds!.x).toBeGreaterThanOrEqual(frameBounds!.x)
    expect(bounds!.x + bounds!.width).toBeLessThanOrEqual(frameBounds!.x + frameBounds!.width)
    expect(bounds!.y).toBeGreaterThanOrEqual(frameBounds!.y)
    expect(bounds!.y + bounds!.height).toBeLessThanOrEqual(frameBounds!.y + frameBounds!.height)
    await frame.getByRole("dialog").press("Escape")
    await expect(dialog).toHaveCount(0)
    await frame.locator('[data-slot="dialog-trigger"]').click()
    await expect(dialog).toBeVisible()
    await expect(page.getByRole("dialog")).toHaveCount(0)
  })

  test("react: separator keyboard steps and double-click reset match vendor sizing", async ({ page }) => {
    await page.goto("/preview/react-fixture.html?fixture=resizable-vertical")
    const separator = page.getByRole("separator")
    await expect(separator).toHaveAttribute("aria-valuenow", "30")
    await separator.focus()
    await page.keyboard.press("ArrowDown")
    await expect(separator).toHaveAttribute("aria-valuenow", "35")
    await page.keyboard.press("Shift+ArrowDown")
    await expect(separator).toHaveAttribute("aria-valuenow", "40")
    await separator.dblclick()
    await expect(separator).toHaveAttribute("aria-valuenow", "30")
  })

  test("react: multiple questionnaire answers survive submission and clearing", async ({ page }) => {
    await page.goto("/preview/react-fixture.html?fixture=questionnaire-invalid-multiple")
    const good = page.locator('input[value="good"]')
    const great = page.locator('input[value="great"]')
    const receipt = page.locator('output[aria-live="polite"]')
    await good.check()
    await great.check()
    await expect(page.getByRole("alert")).toHaveCount(0)
    await page.getByRole("button", { name: "Next", exact: true }).click()
    await page.locator("#questionnaire-invalid-comment-input").fill("Nice visit!")
    await page.getByRole("button", { name: "Submit", exact: true }).click()
    await expect(receipt).toHaveText('Submitted answers: {"rating":["good","great"],"comment":["Nice visit!"]}')
    await page.getByRole("button", { name: "Previous", exact: true }).click()
    await expect(receipt).toHaveText('Submitted answers: {"rating":["good","great"],"comment":["Nice visit!"]}')
    await good.uncheck()
    await expect(receipt).toHaveCount(0)
    await great.uncheck()
    await page.getByRole("button", { name: "Next", exact: true }).click()
    await expect(good).not.toBeChecked()
    await expect(great).not.toBeChecked()
    await expect(page.getByRole("alert")).toBeVisible()
  })

test("half-width carousel snaps and loop wraps retain React geometry after server patches", async ({ page, context }) => {
  const react = page
  const liveview = await context.newPage()
  const positions = (target: Page, id: string) => target.locator(`#${id} [data-slot="carousel-content"]`).evaluate(viewport => {
    const bounds = viewport.getBoundingClientRect()
    return Array.from(viewport.querySelectorAll('[data-slot="carousel-item"]')).map(item => {
      const rect = item.getBoundingClientRect()
      return { text: item.textContent?.trim(), x: Math.round((rect.left - bounds.left) * 100) / 100, width: rect.width }
    })
  })
  await react.goto("/preview/react-fixture.html?fixture=carousel-multiple")
  await liveview.goto("/live-preview/carousel-multiple?embed=1")
  await expect(liveview.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
  for (const target of [react, liveview]) await expect(target.locator('#carousel-left [data-slot="carousel-next"]')).toBeEnabled()
  await expect.poll(async () => positions(liveview, "carousel-left")).toEqual(await positions(react, "carousel-left"))
  const sibling = await positions(liveview, "carousel-right")
  for (const index of [2, 3, 0, 1]) {
    for (const target of [react, liveview]) await target.locator('#carousel-left [data-slot="carousel-next"]').click()
    await expect(liveview.locator("#carousel-left")).toHaveAttribute("phx-value-start-index", String(index))
    await expect.poll(async () => {
      const actual = await positions(liveview, "carousel-left")
      const expected = await positions(react, "carousel-left")
      return actual.length === expected.length && actual.every((item, i) => item.text === expected[i]?.text && Math.abs(item.x - expected[i].x) < 0.1 && item.width === expected[i].width)
    }).toBe(true)
    await expect.poll(async () => positions(liveview, "carousel-right")).toEqual(sibling)
  }
  await liveview.close()
})


  test("react: sidebar-multiple stays bounded and its mobile drawer dismisses independently", async ({ page }) => {
    const url = "/preview/react-fixture.html?fixture=sidebar-multiple"
    await page.setViewportSize({ width: 1100, height: 640 })
    await page.goto(url)
    const provider = page.locator("#sidebar-inset")
    const staticPanel = page.locator("#sidebar-static-panel")
    const panel = page.locator("#sidebar-inset-panel")
    const trigger = provider.locator("main").getByRole("button", { name: "Toggle Sidebar" })
    const desktopSidebar = provider.locator('[data-slot="sidebar"][data-state]')
    await expect(desktopSidebar).toHaveAttribute("data-state", "expanded")
    const providerBounds = (await provider.boundingBox())!
    const panelBounds = (await panel.boundingBox())!
    const staticBounds = (await staticPanel.boundingBox())!
    expect(panelBounds.x).toBeCloseTo(providerBounds.x, 0)
    expect(panelBounds.y).toBeCloseTo(providerBounds.y, 0)
    expect(panelBounds.height).toBeCloseTo(providerBounds.height, 0)
    expect(providerBounds.y + providerBounds.height).toBeLessThanOrEqual(640)
    expect(panelBounds.x + panelBounds.width).toBeLessThan(staticBounds.x)
    const mainBefore = (await provider.locator("main").boundingBox())!.width
    await trigger.click()
    await expect(desktopSidebar).toHaveAttribute("data-state", "collapsed")
    await expect.poll(async () => (await provider.locator("main").boundingBox())!.width).toBeGreaterThan(mainBefore + 200)
    expect((await staticPanel.boundingBox())!.width).toBe(staticBounds.width)

    await page.setViewportSize({ width: 390, height: 640 })
    await expect(panel).toBeHidden()
    const mobileMain = (await provider.locator("main").boundingBox())!
    expect(mobileMain.width).toBeGreaterThan(300)
    const mobileStatic = (await staticPanel.boundingBox())!
    expect(mobileStatic.y + mobileStatic.height).toBeLessThanOrEqual(640)
    expect((await staticPanel.boundingBox())!.y).toBeGreaterThan(mobileMain.y + mobileMain.height)
    expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(390)
    await trigger.click()
    const dialog = page.getByRole("dialog", { name: /Sidebar/i })
    await expect(dialog).toBeVisible()
    await expect(dialog).toContainText("Navigation")
    await page.keyboard.press("Escape")
    await expect(dialog).toBeHidden()
    await expect(staticPanel).toBeVisible()
    await trigger.click()
    await expect(dialog).toBeVisible()
    await expect(dialog).toBeFocused()
    await page.locator('[data-slot="sheet-overlay"]').click({ position: { x: 380, y: 100 } })
    await expect(dialog).toBeHidden()
  })

  test("react: chart-bar-series shrinks inside a narrow frame before and after data patches", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 360 })
    await page.goto("/preview/react-fixture.html?fixture=chart-bar-series")
    const chart = page.locator('[data-slot="chart"]')
    const svg = chart.locator("svg.recharts-surface")
    const button = page.getByRole("button", { name: "Change chart data" })
    await expect(svg).toBeVisible()
    for (const changed of [false, true]) {
      if (changed) {
        await button.click()
        await expect(svg).toContainText("May")
      }
      const bounds = (await chart.boundingBox())!
      const buttonBounds = (await button.boundingBox())!
      expect(bounds.x).toBeGreaterThanOrEqual(24)
      expect(bounds.x + bounds.width).toBeLessThanOrEqual(366)
      expect(buttonBounds.x).toBeGreaterThanOrEqual(24)
      expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(390)
      const bars = await chart.locator(".recharts-rectangle").evaluateAll(nodes =>
        nodes.map(node => {
          const box = node.getBoundingClientRect()
          return { x: box.x, right: box.right, top: box.top, bottom: box.bottom }
        }))
      for (const bar of bars) {
        expect(bar.x).toBeGreaterThanOrEqual(bounds.x)
        expect(bar.right).toBeLessThanOrEqual(bounds.x + bounds.width + 1)
        expect(bar.top).toBeGreaterThanOrEqual(bounds.y)
        expect(bar.bottom).toBeLessThanOrEqual(bounds.y + bounds.height + 1)
      }
    }
  })
