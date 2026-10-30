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

test("fixed submenu controls escape positioned overflow ancestors and remain hit-testable outside them", async ({ page }) => {
  await page.setViewportSize({ width: 600, height: 400 })
  await page.setContent(`<body style="margin:0"><main id="fixture-stage" style="display:flow-root;position:relative;width:600px;height:400px">
    <div id="clip" role="menu" style="position:relative;margin:20px;width:100px;height:80px;overflow:hidden">
      <div id="submenu" role="menu" style="position:fixed;left:180px;top:40px;width:120px;height:40px">
        <button id="escaped" role="menuitem" style="display:block;width:120px;height:40px;border:0;padding:0" onclick="this.dataset.clicked='true'">Escaped</button>
      </div>
    </div>
  </main></body>`)
  for (const implementation of ["react", "liveview"] as const) {
    const { findings } = await inspectFixture(page.mainFrame(), implementation)
    expect(findings.filter(item => item.category === "ancestor-clipping" || item.category === "control-occlusion")).toHaveLength(0)
  }
  await page.getByRole("menuitem", { name: "Escaped" }).click()
  await expect(page.locator("#escaped")).toHaveAttribute("data-clicked", "true")
  await page.locator("#fixture-stage").evaluate(stage => {
    const cover = document.createElement("div")
    cover.id = "cover"
    cover.style.cssText = "position:fixed;left:180px;top:40px;width:120px;height:40px;background:red;z-index:2"
    stage.append(cover)
  })
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({ category: "control-occlusion", severity: "error", element: 'button#escaped[role="menuitem"]' }))
  expect(measurements.occlusions).toEqual([expect.objectContaining({
    element: 'button#escaped[role="menuitem"]', blockedSamples: 9, testedSamples: 9,
    sampledRect: { x: 180, y: 40, width: 120, height: 40 },
    occluders: [expect.objectContaining({ element: "div#cover" })],
  })])
})

for (const containingBlockStyle of [
  "transform:translate(0)",
  "translate:0px",
  "rotate:0deg",
  "scale:1",
  "filter:blur(0)",
  "backdrop-filter:blur(0)",
  "perspective:1000px",
  "contain:layout",
  "contain:paint",
  "contain:content",
  "contain:strict",
  "will-change:transform",
  "will-change:translate",
  "will-change:rotate",
  "will-change:scale",
  "will-change:perspective",
  "will-change:filter",
]) {
  test(`fixed descendants respect containing-block clipping from ${containingBlockStyle}`, async ({ page }) => {
    await page.setViewportSize({ width: 600, height: 400 })
    await page.setContent(`<body style="margin:0"><main id="fixture-stage" style="display:flow-root;width:600px;height:400px">
      <div id="clip" style="position:relative;margin:20px;width:100px;height:80px;overflow:hidden;${containingBlockStyle}">
        <div id="bypassed" style="width:10px;height:10px;overflow:hidden">
          <div id="submenu" role="menu" style="position:fixed;left:80px;top:20px;width:120px;height:40px">
            <button id="cut" role="menuitem" style="display:block;width:120px;height:40px;border:0;padding:0">Cut</button>
          </div>
        </div>
        <div id="cover" style="position:absolute;left:80px;top:20px;width:20px;height:40px;background:red;z-index:2"></div>
      </div>
    </main></body>`)
    if (containingBlockStyle === "translate:0px") {
      expect(await page.locator("#clip").evaluate(el => ({ transform: getComputedStyle(el).transform, translate: getComputedStyle(el).translate }))).toEqual({ transform: "none", translate: "0px" })
    }
    const outsideHit = await page.evaluate(() => document.elementFromPoint(160, 60)?.id)
    expect(outsideHit).not.toBe("cut")
    const { findings, measurements } = await inspectFixture(page.mainFrame(), "liveview")
    expect(findings).toContainEqual(expect.objectContaining({
      category: "ancestor-clipping", severity: "warning", element: 'button#cut[role="menuitem"]',
      details: expect.objectContaining({ ancestor: "div#clip", overflow: { left: 0, right: 100, top: 0, bottom: 0 } }),
    }))
    expect(measurements.elements.flatMap(item => item.clipping).filter(clip => clip.ancestor === "div#bypassed")).toHaveLength(0)
    expect(measurements.occlusions).toEqual([expect.objectContaining({
      element: 'button#cut[role="menuitem"]', blockedSamples: 9, testedSamples: 9,
      sampledRect: { x: 100, y: 40, width: 20, height: 40 },
      occluders: [expect.objectContaining({ element: "div#cover" })],
    })])
  })
}

test("absolute submenu controls bypass static overflow ancestors below their containing block", async ({ page }) => {
  await page.setViewportSize({ width: 600, height: 400 })
  await page.setContent(`<body style="margin:0"><main id="fixture-stage" style="display:flow-root;position:relative;width:600px;height:400px">
    <div id="clip" style="margin:20px;width:100px;height:80px;overflow:hidden">
      <div id="submenu" role="menu" style="position:absolute;left:180px;top:40px;width:120px;height:40px">
        <button id="escaped" style="display:block;width:120px;height:40px;border:0;padding:0" onclick="this.dataset.clicked='true'">Escaped</button>
      </div>
    </div>
  </main></body>`)
  const initial = await inspectFixture(page.mainFrame(), "react")
  expect(initial.findings.filter(item => item.category === "ancestor-clipping" || item.category === "control-occlusion")).toHaveLength(0)
  await page.getByRole("button", { name: "Escaped" }).click()
  await expect(page.locator("#escaped")).toHaveAttribute("data-clicked", "true")
  await page.locator("#fixture-stage").evaluate(stage => {
    const cover = document.createElement("div")
    cover.id = "cover"
    cover.style.cssText = "position:absolute;left:180px;top:40px;width:120px;height:40px;background:red;z-index:2"
    stage.append(cover)
  })
  const { measurements } = await inspectFixture(page.mainFrame(), "react")
  expect(measurements.occlusions).toEqual([expect.objectContaining({
    element: "button#escaped", blockedSamples: 9, testedSamples: 9,
    sampledRect: { x: 180, y: 40, width: 120, height: 40 },
    occluders: [expect.objectContaining({ element: "div#cover" })],
  })])
})

test("ordinary flow controls retain overflow and scroll clips in occlusion sample regions", async ({ page }) => {
  await page.setViewportSize({ width: 600, height: 400 })
  await page.setContent(`<body style="margin:0"><main id="fixture-stage" style="display:flow-root;position:relative;width:600px;height:400px">
    <div id="clip" style="margin:20px;width:100px;height:80px;overflow:hidden">
      <button id="cut" style="display:block;margin-left:80px;width:140px;height:40px;border:0;padding:0">Cut</button>
    </div>
    <div id="scrollable" style="margin:20px;width:100px;height:80px;overflow:auto">
      <button id="scroll" style="display:block;width:140px;height:40px;border:0;padding:0">Scroll</button>
    </div>
    <div id="cover" style="position:absolute;left:100px;top:20px;width:20px;height:40px;background:red"></div>
    <div id="scroll-cover" style="position:absolute;left:20px;top:120px;width:100px;height:40px;background:red"></div>
  </main></body>`)
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({ category: "ancestor-clipping", severity: "warning", element: "button#cut" }))
  expect(findings).toContainEqual(expect.objectContaining({ category: "ancestor-clipping", severity: "info", element: "button#scroll" }))
  expect(measurements.occlusions).toEqual([
    expect.objectContaining({ element: "button#cut", blockedSamples: 9, sampledRect: { x: 100, y: 20, width: 20, height: 40 } }),
    expect.objectContaining({ element: "button#scroll", blockedSamples: 9, sampledRect: { x: 20, y: 120, width: 100, height: 40 } }),
  ])
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

test("nested submenu panels report material overlap independently of React matching LiveView", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;width:500px;height:300px"><div id="parent" role="menu" style="position:absolute;left:20px;top:20px;width:160px;height:120px;background:white"><button role="menuitem">More</button><div id="child" role="menu" style="position:absolute;left:80px;top:20px;width:160px;height:80px;background:white"><button role="menuitem">Nested</button></div></div></main>')
  for (const implementation of ["react", "liveview"] as const) {
    const { findings, measurements } = await inspectFixture(page.mainFrame(), implementation)
    const finding = findings.find(item => item.category === "panel-overlap")!
    expect(finding).toMatchObject({ severity: "error", implementation, element: 'div#parent[role="menu"]' })
    expect(measurements.overlaps.filter(item => item.category === "panel-overlap")).toHaveLength(1)
    const details = finding.details as Record<string, unknown>
    expect(details).toMatchObject({
      intersection: { width: 80, height: 80 }, intersectionArea: 6400,
      firstFraction: 1 / 3, secondFraction: 0.5,
      responsibleElements: [
        { element: 'div#parent[role="menu"]', domPath: "#parent", rect: { width: 160, height: 120 } },
        { element: 'div#child[role="menu"]', domPath: "#child", rect: { width: 160, height: 80 } },
      ],
    })
  }
})

test("disjoint nested menu/listbox panels and hidden panels are not overlapping", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;width:600px;height:300px"><div id="parent" role="menu" style="position:absolute;left:20px;top:20px;width:120px;height:100px"><div id="child" role="menu" style="position:absolute;left:121px;top:0;width:120px;height:100px"></div><div role="menu" hidden style="position:absolute;inset:0;width:120px;height:100px"></div><div role="listbox" aria-hidden="true" style="position:absolute;inset:0;width:120px;height:100px"></div></div><div role="listbox" style="position:absolute;left:400px;top:20px;width:120px;height:100px"></div></main>')
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings.filter(item => item.category === "panel-overlap")).toHaveLength(0)
  expect(measurements.overlaps).toHaveLength(0)
})

test("panel overlap ignores one-pixel rounding and retains two-pixel border evidence as info", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;height:300px"><div role="menu" style="position:absolute;left:0;top:0;width:100px;height:100px"></div><div id="edge" role="menu" style="position:absolute;left:99px;top:0;width:100px;height:100px"></div></main>')
  let result = await inspectFixture(page.mainFrame(), "react")
  expect(result.findings.filter(item => item.category === "panel-overlap")).toHaveLength(0)
  await page.locator("#edge").evaluate(el => { if (el instanceof HTMLElement) el.style.left = "98px" })
  result = await inspectFixture(page.mainFrame(), "react")
  expect(result.findings.filter(item => item.category === "panel-overlap")).toEqual([
    expect.objectContaining({ severity: "info", details: expect.objectContaining({ intersection: expect.objectContaining({ width: 2, height: 100 }) }) }),
  ])
})

test("independent intersecting controls report geometry and sampled external occlusion", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;height:200px"><button id="first" style="position:absolute;left:20px;top:20px;width:100px;height:40px">First</button><button id="second" style="position:absolute;left:60px;top:20px;width:100px;height:40px">Second</button></main>')
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "react")
  expect(findings).toContainEqual(expect.objectContaining({
    category: "control-overlap", severity: "error", element: "button#first",
    details: expect.objectContaining({ intersection: expect.objectContaining({ width: 60, height: 40 }), firstFraction: 0.6, secondFraction: 0.6 }),
  }))
  expect(findings).toContainEqual(expect.objectContaining({ category: "control-occlusion", severity: "error", element: "button#first" }))
  const evidence = measurements.occlusions.find(item => item.element === "button#first")!
  expect(evidence.blockedSamples).toBe(6)
  expect(evidence.testedSamples).toBe(9)
  expect(evidence.samples.filter(sample => sample.occluder)).toHaveLength(6)
  expect(evidence.occluders).toEqual([expect.objectContaining({ element: "button#second", domPath: "#second", blockedSamples: 6, overlap: expect.objectContaining({ firstFraction: 0.6 }) })])
})

test("partial external coverage records three of nine samples as a warning", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;height:200px"><button id="partial" style="position:absolute;left:20px;top:20px;width:100px;height:40px">Partial</button><div id="cover" style="position:absolute;left:90px;top:20px;width:30px;height:40px;background:red"></div></main>')
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "react")
  expect(findings).toContainEqual(expect.objectContaining({ category: "control-occlusion", severity: "warning", element: "button#partial" }))
  expect(measurements.occlusions[0]).toMatchObject({ blockedSamples: 3, testedSamples: 9, blockedFraction: 1 / 3 })
})

test("aria-hidden painted overlays still occlude controls and report responsible geometry", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;height:200px"><button id="covered" style="position:absolute;left:20px;top:20px;width:100px;height:40px">Covered</button><div id="cover" aria-hidden="true" style="position:absolute;left:20px;top:20px;width:100px;height:40px;background:red"></div></main>')
  const { findings, measurements } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({ category: "control-occlusion", severity: "error", element: "button#covered" }))
  expect(measurements.occlusions[0]).toMatchObject({
    blockedFraction: 1, blockedSamples: 9,
    occluders: [{ element: "div#cover", domPath: "#cover", rect: { width: 100, height: 40 }, overlap: { intersectionArea: 4000, firstFraction: 1, secondFraction: 1 } }],
  })
})

test("single blocked samples do not turn tiny obstructions into occlusion warnings", async ({ page }) => {
  await page.setContent('<main id="fixture-stage" style="position:relative;height:200px"><button id="control" style="position:absolute;left:20px;top:20px;width:100px;height:100px">Control</button><div style="position:absolute;left:65px;top:65px;width:10px;height:10px;background:red"></div></main>')
  const { findings } = await inspectFixture(page.mainFrame(), "react")
  expect(findings.filter(item => item.category === "control-occlusion")).toEqual([
    expect.objectContaining({ severity: "info", details: expect.objectContaining({ blockedSamples: 1 }) }),
  ])
})

test("hidden, associated label, native backing, contained and parent-child controls avoid false overlaps and occlusion", async ({ page }) => {
  await page.setContent(`<main id="fixture-stage" style="position:relative;height:400px">
    <div id="parent" role="button" aria-label="Parent" style="position:absolute;left:0;top:0;width:100px;height:40px"><button id="child" style="width:100px;height:40px">Child</button></div>
    <label id="label" role="button" for="native" style="position:absolute;left:150px;top:0;width:100px;height:40px">Native</label><input id="native" type="checkbox" style="position:absolute;left:150px;top:0;width:100px;height:40px;margin:0" />
    <div style="position:absolute;left:300px;top:0;width:100px;height:40px"><button id="custom" role="checkbox" aria-label="Custom" style="position:absolute;left:0;top:0;width:60px;height:40px"></button><input id="backing" type="checkbox" style="position:absolute;left:20px;top:0;width:60px;height:40px;pointer-events:none;margin:0" /></div>
    <button hidden style="position:absolute;left:0;top:0;width:100px;height:40px">Hidden</button><button aria-hidden="true" style="display:none;position:absolute;left:0;top:0;width:100px;height:40px">Hidden backing</button>
    <button id="large" style="position:absolute;left:0;top:150px;width:100px;height:80px">Large</button><button id="contained" style="position:absolute;left:20px;top:170px;width:40px;height:30px">Small</button>
  </main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "react")
  expect(findings.filter(item => item.category === "control-overlap")).toHaveLength(0)
  expect(findings.filter(item => item.category === "control-occlusion" && !/large/.test(item.element || ""))).toHaveLength(0)
})

test("intentional modal coverage excludes background controls but still detects broken controls inside the modal", async ({ page }) => {
  await page.setContent(`<main id="fixture-stage" style="position:relative;height:300px">
    <button id="background" style="position:absolute;left:20px;top:20px;width:100px;height:40px">Background</button>
    <div data-slot="dialog-overlay" style="position:absolute;inset:0;background:#0006"></div>
    <section role="dialog" aria-modal="true" data-slot="dialog-content" style="position:absolute;left:10px;top:10px;width:220px;height:150px;background:white">
      <button id="inside" style="position:absolute;left:10px;top:10px;width:100px;height:40px">Inside</button>
      <div id="broken" style="position:absolute;left:10px;top:10px;width:100px;height:40px;background:red"></div>
    </section>
  </main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings.filter(item => (item.category === "control-occlusion" || item.category === "control-overlap") && item.element === "button#background")).toHaveLength(0)
  expect(findings).toContainEqual(expect.objectContaining({ category: "control-occlusion", element: "button#inside" }))
})

test("opening inline navigation content exposes shifted top-level triggers while ignoring dropdown links", async ({ page }) => {
  await page.setContent(`<main id="fixture-stage"><nav><ul data-slot="navigation-menu-list" style="display:flex;align-items:center;list-style:none;margin:0;padding:0">
    <li><a id="docs" href="#" style="display:block;width:60px;height:36px">Docs</a></li>
    <li><button id="about" style="display:block;width:60px;height:36px">About</button><div id="dropdown" data-slot="navigation-menu-content" hidden style="height:50px"><a href="#" style="display:block;height:20px">Company</a></div></li>
    <li><a id="home" href="#" style="display:block;width:60px;height:36px">Home</a></li>
  </ul></nav></main>`)
  let result = await inspectFixture(page.mainFrame(), "react")
  expect(result.findings.filter(item => item.category === "navigation-misalignment")).toHaveLength(0)
  await page.locator("#dropdown").evaluate(el => { el.removeAttribute("hidden") })
  for (const implementation of ["react", "liveview"] as const) {
    result = await inspectFixture(page.mainFrame(), implementation)
    expect(result.findings.filter(item => item.category === "navigation-misalignment")).toEqual([
      expect.objectContaining({ element: "button#about", implementation, severity: "warning", details: expect.objectContaining({ distance: 25, axis: "horizontal", group: expect.objectContaining({ element: 'ul[data-slot="navigation-menu-list"]' }) }) }),
    ])
  }
})

test("explicit wrapping and vertical navigation do not report cross-axis misalignment", async ({ page }) => {
  await page.setContent(`<main id="fixture-stage">
    <nav style="display:flex;flex-wrap:wrap"><a href="#" style="height:20px">One</a><a href="#" style="height:40px">Two</a><a href="#" style="height:60px">Three</a></nav>
    <nav aria-orientation="vertical" style="display:flex;flex-direction:column"><a href="#">One</a><a href="#">Two</a><a href="#">Three</a></nav>
  </main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings.filter(item => item.category === "navigation-misalignment")).toHaveLength(0)
})

test("touching switch and reset controls produce info evidence but compound groups and separated controls do not", async ({ page }) => {
  await page.setContent(`<main id="fixture-stage">
    <form style="display:flex"><button id="switch" role="switch" aria-label="Enabled" style="width:40px;height:30px">Switch</button><button id="reset" type="reset" style="width:50px;height:30px">Reset</button></form>
    <div data-slot="button-group" role="group" style="display:flex;margin-top:20px"><button>One</button><button>Two</button></div>
    <div style="display:flex;gap:3px;margin-top:20px"><button>Separate</button><button>Controls</button></div>
  </main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "react")
  const crowding = findings.filter(item => item.category === "crowded-controls")
  expect(crowding).toContainEqual(expect.objectContaining({ severity: "info", element: 'button#switch[role="switch"]', details: expect.objectContaining({ distance: 0, threshold: 2, responsibleElements: [expect.objectContaining({ domPath: "#switch" }), expect.objectContaining({ domPath: "#reset" })] }) }))
  expect(crowding).toHaveLength(1)
})

test("expanded pseudo-element hit areas report interception even when control rectangles do not overlap", async ({ page }) => {
  await page.setContent(`<style>#switch::after{content:"";position:absolute;inset:0 -12px;z-index:1}</style>
    <main id="fixture-stage"><form style="display:flex">
      <button id="switch" role="switch" aria-label="Enabled" style="position:relative;width:32px;height:24px;border:0;padding:0">On</button>
      <button id="reset" type="reset" style="width:48px;height:24px;border:0;padding:0">Reset</button>
    </form></main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({
    category: "control-occlusion",
    element: "button#reset",
    severity: "warning",
    details: expect.objectContaining({ blockedSamples: 3, occluders: [expect.objectContaining({ element: 'button#switch[role="switch"]', overlap: null })] }),
  }))
})

test("partial expanded checkbox hit areas retain two blocked samples as low-confidence evidence", async ({ page }) => {
  await page.setContent(`<style>#checkbox::after{content:"";position:absolute;inset:-8px -12px;z-index:1}</style>
    <main id="fixture-stage"><form style="display:flex;flex-direction:column;align-items:flex-start">
      <button id="checkbox" role="checkbox" aria-label="Enabled" style="position:relative;width:20px;height:20px;border:0;padding:0">On</button>
      <button id="reset" type="reset" style="width:42px;height:24px;border:0;padding:0">Reset</button>
    </form></main>`)
  const { findings } = await inspectFixture(page.mainFrame(), "liveview")
  expect(findings).toContainEqual(expect.objectContaining({
    category: "control-occlusion",
    element: "button#reset",
    severity: "info",
    details: expect.objectContaining({ blockedSamples: 2, occluders: [expect.objectContaining({ element: 'button#checkbox[role="checkbox"]', overlap: null })] }),
  }))
})
