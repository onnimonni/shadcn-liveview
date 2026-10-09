import { expect, type Page } from "@playwright/test"

export async function openFixture(page: Page, fixture: string) {
  await page.goto(`/live-preview/${encodeURIComponent(fixture)}?embed=1`)
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/)
}

export async function expectInsideStage(page: Page, selector: string) {
  await expect(page.locator(selector)).toBeVisible()
  const bounds = await page.locator(selector).boundingBox()
  const stage = await page.locator("#fixture-stage").boundingBox()
  expect(bounds!.width).toBeGreaterThan(0)
  expect(bounds!.height).toBeGreaterThan(0)
  expect(bounds!.x).toBeGreaterThanOrEqual(stage!.x)
  expect(bounds!.x + bounds!.width).toBeLessThanOrEqual(stage!.x + stage!.width + 1)
  expect(bounds!.y).toBeGreaterThanOrEqual(stage!.y)
  expect(bounds!.y + bounds!.height).toBeLessThanOrEqual(stage!.y + stage!.height + 1)
}
