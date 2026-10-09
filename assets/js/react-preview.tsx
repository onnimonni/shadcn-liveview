import React from "react"
import { createRoot } from "react-dom/client"
import { fixtures } from "../../tools/fixtures"

function FixtureReady({ name, children }: { name: string; children: React.ReactNode }) {
  React.useEffect(() => {
    document.body.dataset.fixtureReady = name
    return () => { delete document.body.dataset.fixtureReady }
  }, [name])
  return children
}

const stage = document.getElementById("fixture-stage")
if (!stage) throw new Error("React fixture preview requires #fixture-stage.")

const name = new URLSearchParams(window.location.search).get("fixture")
const fixture = fixtures.find((entry) => entry.name === name)

if (fixture) {
  document.title = `${fixture.title} — React fixture`
  document.body.dataset.family = fixture.family ?? fixture.name
  document.body.dataset.fixture = fixture.name
  createRoot(stage).render(
    <FixtureReady name={fixture.name}>
      {fixture.renderLiveReact ? fixture.renderLiveReact() : fixture.renderReact()}
    </FixtureReady>
  )
} else {
  document.title = "React fixture not found"
  createRoot(stage).render(
    <div role="alert" className="space-y-2 text-sm">
      <h1 className="font-semibold">React fixture not found</h1>
      <p>{name ? `No fixture named “${name}” exists.` : "Supply an existing fixture name in the fixture query parameter."}</p>
      <a className="underline" href="/preview/react-ssr.html">Return to the React gallery</a>
    </div>
  )
}
