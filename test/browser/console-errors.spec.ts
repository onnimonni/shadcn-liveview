import { expect, test, type Page } from "@playwright/test"

// Every connected LiveView fixture must load and survive basic interaction without console
// errors, uncaught exceptions, unhandled promise rejections or failed requests.

async function liveviewFixtures(page: Page): Promise<string[]> {
  await page.goto("/preview/liveview.html")
  const names = await page.locator("iframe[data-fixture]").evaluateAll(frames =>
    frames.map(frame => frame.getAttribute("data-fixture")!))
  expect(names.length).toBeGreaterThan(300)
  return [...new Set(names)]
}

async function awaitConnected(page: Page) {
  await page.waitForFunction(() => {
    const root = document.querySelector("[data-phx-main]")
    const socket = Reflect.get(window, "liveSocket")
    return root?.classList.contains("phx-connected") && socket?.isConnected?.()
  })
}

// Small, deterministic interaction pass: open the first trigger, dismiss, tab around, type.
async function exercise(page: Page) {
  const trigger = page.locator('[data-slot$="-trigger"]:visible:not([disabled]):not([aria-disabled="true"])').first()
  if (await trigger.count()) {
    await trigger.click({ timeout: 2_000 }).catch(() => {})
    await page.keyboard.press("Escape")
  }
  for (let i = 0; i < 3; i++) await page.keyboard.press("Tab")
  const textbox = page.locator('input[type="text"]:visible:not([disabled]):not([readonly]), textarea:visible:not([disabled]):not([readonly])').first()
  if (await textbox.count()) await textbox.fill("Console check", { timeout: 2_000 }).catch(() => {})
  // Let pushes, patches and animation frames settle.
  await page.evaluate(() => {
    const { promise, resolve } = Promise.withResolvers<void>()
    requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
    return promise
  })
  await page.waitForTimeout(150)
}

// Same interactions while the socket is down: hook pushes must not throw or reject unhandled.
async function exerciseDisconnected(page: Page) {
  await page.evaluate(() => Reflect.get(window, "liveSocket").disconnect())
  await page.waitForFunction(() => !Reflect.get(window, "liveSocket").isConnected())
  await exercise(page)
  await page.evaluate(() => Reflect.get(window, "liveSocket").connect())
  await awaitConnected(page)
}

test("components log no console errors, page errors or failed requests, connected or not", async ({ browser }) => {
  test.setTimeout(15 * 60_000)
  const listing = await browser.newPage()
  const fixtures = await liveviewFixtures(listing)
  await listing.close()

  const failures: string[] = []
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } })
  let current = ""
  page.on("console", message => {
    if (message.type() === "error") failures.push(`${current}: console.error ${message.text()}`)
  })
  page.on("pageerror", error => failures.push(`${current}: ${error.name}: ${error.message}`))
  page.on("requestfailed", request => failures.push(`${current}: request failed ${request.url()} ${request.failure()?.errorText}`))
  page.on("response", response => {
    if (response.status() >= 400) failures.push(`${current}: HTTP ${response.status()} ${response.url()}`)
  })
  await page.addInitScript(() => {
    window.addEventListener("unhandledrejection", event => console.error(`unhandledrejection: ${event.reason}`))
  })

  // Gallery fixtures plus hand-written harness pages (not gallery fixtures).
  const pages = [...fixtures.map(fixture => [fixture, `/live-preview/${encodeURIComponent(fixture)}?embed=1`]), ["data-table", "/data-table-preview"]]
  for (const [fixture, url] of pages) {
    current = fixture
    await page.goto(url)
    await awaitConnected(page)
    await exercise(page)
    // A fresh load gives the disconnected pass the same starting state.
    await page.goto(url)
    await awaitConnected(page)
    current = `${fixture} (disconnected)`
    await exerciseDisconnected(page)
  }

  expect(failures, failures.join("\n")).toEqual([])
})
