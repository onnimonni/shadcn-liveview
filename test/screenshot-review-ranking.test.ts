import test from "node:test"
import assert from "node:assert/strict"
import type { Finding } from "../tools/screenshot-review-metrics"
import { rankSuspects, type RankingCase } from "../tools/screenshot-review-ranking"

function fixture(name: string, findings: Finding[], width = 390): RankingCase {
  return {
    fixture: name, title: name, family: "example", category: "Example", width, state: "initial", findings,
    captures: ["react", "liveview"].map(implementation => ({
      implementation: implementation as "react" | "liveview", status: "captured",
      url: `http://localhost:4000/${implementation}/${name}`, image: `images/${name}-${width}-${implementation}.png`,
    })),
    pixelComparison: null, diffImage: null,
  }
}
function finding(category: Finding["category"], implementation: Finding["implementation"] = "liveview", severity: Finding["severity"] = "warning"): Finding {
  return { category, severity, implementation, message: category }
}

test("capture and broken geometry outrank pixel differences and arbitrarily many labels", () => {
  const labels = Array.from({ length: 500 }, () => finding("missing-visible-label", "liveview", "info"))
  const names = Array.from({ length: 500 }, () => finding("missing-accessible-name"))
  const results = [
    fixture("labels", labels), fixture("names", names), fixture("pixels", [finding("visual-difference", undefined)]),
    fixture("geometry", [finding("panel-overlap")]),
    fixture("failed", [finding("capture-failure", "react", "error")]),
  ]
  assert.deepEqual(rankSuspects(results).map(suspect => suspect.fixture), ["failed", "geometry", "pixels", "names", "labels"])
  assert.equal(rankSuspects([fixture("geometry-with-labels", [finding("panel-overlap"), ...labels, ...names])])[0].score, rankSuspects([results[3]])[0].score)
})

test("ancestor and repeated overflow cascades collapse without changing scores or raw findings", () => {
  const root: Finding = { ...finding("overflow-frame"), element: "div#panel", details: { rect: { x: -10, y: 0, width: 400, height: 100 } } }
  const cascades = Array.from({ length: 200 }, (_, index) => ({ ...finding(index % 2 ? "overflow-stage" : "ancestor-clipping"), element: `span#child-${index}`, details: { ancestor: "div#panel" } }))
  const original = fixture("cascade", [root, ...cascades])
  const before = JSON.stringify(original)
  const ranked = rankSuspects([original])[0]
  assert.equal(ranked.score, rankSuspects([fixture("root", [root])])[0].score)
  assert.equal(ranked.reasons.length, 1)
  assert.equal(ranked.reasons[0].signal, "boundary")
  assert.equal(ranked.reasons[0].rawFindings, 201)
  assert.equal(ranked.reasons[0].collapsedFindings, 200)
  assert.equal(ranked.reasons[0].evidence[0].findingIndex, 0)
  assert.deepEqual(ranked.reasons[0].evidence[0].details, root.details)
  assert.equal(JSON.stringify(original), before)
})

test("overlap and occlusion of the same controls corroborate only once; independent boundaries can support", () => {
  const occlusion = finding("control-occlusion")
  const single = rankSuspects([fixture("single", [occlusion])])[0]
  const repeated = rankSuspects([fixture("overlap", [occlusion, finding("control-overlap"), finding("panel-overlap"), occlusion])])[0]
  const independent = rankSuspects([fixture("independent", [occlusion, finding("overflow-frame")])])[0]
  assert.equal(repeated.score, single.score)
  assert.equal(repeated.reasons.length, 1)
  assert.equal(independent.score, single.score + 3)
})

test("shared reference defects retain priority even with identical screenshots", () => {
  const only = fixture("liveview-only", [finding("panel-overlap")])
  const shared = fixture("shared", [finding("panel-overlap", "react"), finding("panel-overlap", "liveview")])
  shared.pixelComparison = { width: 390, height: 100, pixels: 39000, changedPixels: 0, changedRatio: 0, meanChannelDelta: 0, maxChannelDelta: 0, changedBounds: null, threshold: 24 }
  const ranked = rankSuspects([shared])[0]
  assert.equal(ranked.score, rankSuspects([only])[0].score)
  assert.deepEqual(ranked.implementations, ["react", "liveview"])
  assert.equal(ranked.reasons[0].context, "shared")
  assert.deepEqual(ranked.comparison.sharedCategories, ["panel-overlap"])
  assert.deepEqual(ranked.comparison.liveviewOnlyCategories, [])
  assert.equal(ranked.comparison.pixelChangedRatio, 0)
  assert.equal(ranked.links[0].fixtureURL, shared.captures[0].url)
  assert.equal(ranked.links[1].imageURL, shared.captures[1].image)
  assert.deepEqual(ranked.reasons[0].evidence.map(evidence => evidence.implementation), ["react", "liveview"])
})

test("navigation geometry outranks low-confidence crowding; informational clipping stays weak", () => {
  const ranked = rankSuspects([
    fixture("scroll", [finding("ancestor-clipping", "liveview", "info")]),
    fixture("crowded", [finding("crowded-controls", "liveview", "info")]),
    fixture("navigation", [finding("navigation-misalignment")]),
    fixture("pixels", [finding("visual-difference")]),
  ])
  assert.equal(ranked[0].fixture, "navigation")
  assert.equal(ranked[1].fixture, "pixels")
  assert.ok(ranked.slice(2).every(suspect => suspect.score <= 8))
})

test("thin shared panel edge contacts stay below substantial geometry without hiding the original signal", () => {
  const edge: Finding = { ...finding("panel-overlap"), details: { intersection: { x: 140, y: 4, width: 4, height: 32 }, firstFraction: 0.025, secondFraction: 0.028 } }
  const substantial: Finding = { ...finding("panel-overlap"), details: { intersection: { x: 80, y: 4, width: 64, height: 32 }, firstFraction: 0.4, secondFraction: 0.44 } }
  const shared = fixture("shared-edge", [edge, { ...edge, implementation: "react" }])
  const ranked = rankSuspects([shared, fixture("substantial", [substantial]), fixture("pixels", [finding("visual-difference")])])
  assert.deepEqual(ranked.map(suspect => suspect.fixture), ["substantial", "pixels", "shared-edge"])
  assert.equal(ranked[2].score, 12)
  assert.equal(ranked[2].reasons[0].context, "shared")
  assert.equal(ranked[2].reasons[0].rawFindings, 2)
  assert.deepEqual(ranked[2].comparison.sharedCategories, ["panel-overlap"])
  const thinButBlocking = { ...edge, details: { intersection: { width: 4, height: 32 }, firstFraction: 0.9, secondFraction: 0.028 } }
  assert.equal(rankSuspects([fixture("thin-control", [thinButBlocking])])[0].score, ranked[0].score)
})

test("failed capture slots stay ranked without synthetic changes to raw results; ties use fixture and width", () => {
  const failed = fixture("failed-slot", [])
  failed.captures[1] = { implementation: "liveview", status: "failed", url: failed.captures[1].url, error: "readiness timeout" }
  const ranked = rankSuspects([fixture("b", [finding("overflow-frame")]), fixture("a", [finding("overflow-frame")], 1100), fixture("a", [finding("overflow-frame")], 390), failed, fixture("clean", [])])
  assert.deepEqual(ranked.map(suspect => [suspect.rank, suspect.fixture, suspect.width]), [[1, "failed-slot", 390], [2, "a", 390], [3, "a", 1100], [4, "b", 390]])
  assert.equal(ranked[0].links[1].imageURL, null)
  assert.equal(ranked[0].links[1].status, "failed")
  assert.equal(ranked[0].reasons[0].evidence[0].message, "readiness timeout")
  assert.equal(failed.findings.length, 0)
})

test("paired geometry displacement outranks sparse pixel differences", () => {
  const results = [fixture("sparse-pixels", [finding("visual-difference", undefined, "info")]), fixture("displaced-demo", [finding("paired-geometry-drift", undefined)])]
  assert.deepEqual(rankSuspects(results).map(item => item.fixture), ["displaced-demo", "sparse-pixels"])
  assert.equal(rankSuspects(results)[0].strongestSignal, "paired-layout")
})
