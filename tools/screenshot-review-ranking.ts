import type { Finding, PixelMetrics } from "./screenshot-review-metrics"

type Implementation = "react" | "liveview"
export interface RankingCase {
  fixture: string
  title: string
  family: string
  category: string
  width: number
  state: "initial"
  captures: { implementation: Implementation; url: string; status: "captured" | "failed"; image?: string; error?: string }[]
  findings: Finding[]
  pixelComparison: PixelMetrics | null
  diffImage: string | null
}
export interface RankedReason {
  signal: string
  categories: string[]
  score: number
  implementations: Implementation[]
  context: "shared" | "react-only" | "liveview-only" | "paired"
  rawFindings: number
  collapsedFindings: number
  evidence: { findingIndex: number; implementation?: Implementation; element?: string; message: string; details?: unknown }[]
}
export interface RankedSuspect {
  rank: number
  resultIndex: number
  fixture: string
  title: string
  family: string
  category: string
  width: number
  state: "initial"
  score: number
  strongestSignal: string
  implementations: Implementation[]
  reasons: RankedReason[]
  links: { implementation: Implementation; fixtureURL: string; imageURL: string | null; status: "captured" | "failed"; error?: string }[]
  diffImageURL: string | null
  comparison: {
    sharedCategories: string[]
    reactOnlyCategories: string[]
    liveviewOnlyCategories: string[]
    pixelChangedRatio: number | null
    note: string
  }
}

export const rankingHeuristics = [
  "The likely-broken queue ranks fixture/width initial-state cases, not individual DOM nodes. Score is the strongest signal plus at most 9 points of independent corroboration; it is a review priority, not a probability. Capture failures lead, then broken geometry, runtime errors, pixel differences and name/label heuristics. Informational findings and thin edge contacts (at most 6 CSS pixels and at most 10% of either overlapping surface) remain low priority.",
  "Repeated categories and ancestor cascades cannot increase scores: frame/stage overflow and ancestor clipping form one boundary signal, and panel/control overlap, occlusion and crowding form one collision signal. Only the strongest finding per signal scores, regardless of element count or implementation count. This conservative grouping may merge distinct causes; every raw finding remains in the detailed results.",
  "Paired context matches finding categories, not equivalent DOM identities or proven root causes. Shared React and LiveView signals are not dismissed or discounted: the original can also be broken. Pixel similarity does not cancel geometry; missing labels alone cannot outweigh strong broken geometry. Initial demo states can differ (for example, only one implementation initially opens a submenu), so pixel differences are not proven regressions. Representative evidence retains raw finding indexes for inspection.",
  "Only requested fixtures and widths are captured, in their initial rendered demo states. An already-open navigation fixture can reveal open-state geometry, but this audit does not click triggers, traverse focus/keyboard states or establish that every interaction works. Direct fixture links allow manual interaction review; failed and unattempted coverage are explicit.",
]

const signals: Record<string, { group: string; score: number }> = {
  "capture-failure": { group: "capture", score: 100 },
  "control-occlusion": { group: "collision", score: 90 },
  "control-overlap": { group: "collision", score: 85 },
  "navigation-misalignment": { group: "navigation-layout", score: 82 },
  "panel-overlap": { group: "collision", score: 80 },
  "paired-geometry-drift": { group: "paired-layout", score: 75 },
  "overflow-frame": { group: "boundary", score: 70 },
  "overflow-stage": { group: "boundary", score: 70 },
  "ancestor-clipping": { group: "boundary", score: 70 },
  "zero-size-control": { group: "control-size", score: 65 },
  "browser-error": { group: "runtime", score: 35 },
  "visual-difference": { group: "pixels", score: 25 },
  "missing-accessible-name": { group: "label", score: 15 },
  "crowded-controls": { group: "collision", score: 12 },
  "missing-visible-label": { group: "label", score: 2 },
}
const implementations: Implementation[] = ["react", "liveview"]
const sorted = (values: Iterable<string>) => [...new Set(values)].sort()
const findingScore = (finding: Finding) => {
  let base = signals[finding.category]?.score ?? 1
  if (finding.category === "panel-overlap" || finding.category === "control-overlap") {
    const details = finding.details as { intersection?: { width: number; height: number }; firstFraction?: number; secondFraction?: number } | undefined
    if (details?.intersection && Math.min(details.intersection.width, details.intersection.height) <= 6 && typeof details.firstFraction === "number" && typeof details.secondFraction === "number" && Math.max(details.firstFraction, details.secondFraction) <= 0.1) {
      base = 12
    }
  }
  return finding.severity === "info" ? Math.min(base, 8) : base
}

export function rankSuspects(results: RankingCase[]): RankedSuspect[] {
  const suspects: RankedSuspect[] = []
  for (const [resultIndex, result] of results.entries()) {
    const groups = new Map<string, { finding: Finding; index: number; score: number }[]>()
    for (const [index, finding] of result.findings.entries()) {
      const group = signals[finding.category]?.group ?? finding.category
      const entries = groups.get(group) ?? []
      entries.push({ finding, index, score: findingScore(finding) })
      groups.set(group, entries)
    }
    // Retain a failed capture even if an upstream failure supplied no Finding.
    for (const capture of result.captures.filter(capture => capture.status === "failed")) {
      const entries = groups.get("capture") ?? []
      if (!entries.some(entry => entry.finding.implementation === capture.implementation)) {
        entries.push({ index: -1, score: 100, finding: { category: "capture-failure", severity: "error", implementation: capture.implementation, message: capture.error || "Capture failed; no screenshot available", details: { url: capture.url } } })
        groups.set("capture", entries)
      }
    }
    if (!groups.size) continue
    const reasons: RankedReason[] = [...groups].map(([signal, entries]) => {
      entries.sort((a, b) => b.score - a.score || a.index - b.index)
      const affected = implementations.filter(implementation => entries.some(entry => entry.finding.implementation === implementation))
      // At most one representative per implementation; no descendant count bonus.
      const representatives = affected.length ? affected.map(implementation => entries.find(entry => entry.finding.implementation === implementation)!) : [entries[0]]
      return {
        signal, categories: sorted(entries.map(entry => entry.finding.category)), score: entries[0].score,
        implementations: affected,
        context: affected.length === 2 ? "shared" : affected[0] === "react" ? "react-only" : affected[0] === "liveview" ? "liveview-only" : "paired",
        rawFindings: entries.filter(entry => entry.index >= 0).length,
        collapsedFindings: Math.max(0, entries.filter(entry => entry.index >= 0).length - 1),
        evidence: representatives.map(({ finding, index }) => ({ findingIndex: index, implementation: finding.implementation, element: finding.element, message: finding.message, details: finding.details })),
      }
    }).sort((a, b) => b.score - a.score || a.signal.localeCompare(b.signal))
    const strongest = reasons[0].score
    // Only genuinely strong supporting groups corroborate strong evidence. Neither
    // informational nodes nor hundreds of missing names can boost broken geometry.
    const supporting = reasons.slice(1).filter(reason => reason.score >= 25).length
    const score = strongest + Math.min(9, supporting * 3)
    const react = new Set(result.findings.filter(finding => finding.implementation === "react").map(finding => finding.category))
    const liveview = new Set(result.findings.filter(finding => finding.implementation === "liveview").map(finding => finding.category))
    suspects.push({
      rank: 0, resultIndex, fixture: result.fixture, title: result.title, family: result.family, category: result.category, width: result.width, state: result.state,
      score, strongestSignal: reasons[0].signal,
      implementations: implementations.filter(implementation => reasons.some(reason => reason.context === "paired" || reason.implementations.includes(implementation))), reasons,
      links: result.captures.map(capture => ({ implementation: capture.implementation, fixtureURL: capture.url, imageURL: capture.image ?? null, status: capture.status, ...(capture.error ? { error: capture.error } : {}) })),
      diffImageURL: result.diffImage,
      comparison: {
        sharedCategories: sorted([...react].filter(category => liveview.has(category))),
        reactOnlyCategories: sorted([...react].filter(category => !liveview.has(category))),
        liveviewOnlyCategories: sorted([...liveview].filter(category => !react.has(category))),
        pixelChangedRatio: result.pixelComparison?.changedRatio ?? null,
        note: "Category-level comparison only; shared findings retain full priority. Matching React is not evidence that either implementation is correct. Initial demo states may differ, so changed pixels alone are not proven regressions.",
      },
    })
  }
  suspects.sort((a, b) => b.score - a.score || a.fixture.localeCompare(b.fixture) || a.width - b.width || a.resultIndex - b.resultIndex)
  return suspects.map((suspect, index) => ({ ...suspect, rank: index + 1 }))
}
