import { fixtureMinHeight } from "./gallery-layout"

const stage = document.getElementById("fixture-stage")
if (stage && window.parent !== window) {
  const family = window.frameElement?.dataset.family || document.body.dataset.family || stage.dataset.family
  const floor = fixtureMinHeight(family)
  // Keep the floor outside LiveView's stage patches.
  document.documentElement.style.setProperty("--fixture-min-height", `${floor}px`)
  const liveView = document.querySelector("[data-phx-main]")
  let previous = 0
  let queued = false
  const report = () => {
    queued = false
    // Measure the connected component, not its transient SSR-to-hook layout.
    if (liveView && !liveView.classList.contains("phx-connected")) return
    // Sidebar's viewport-sized layout must not drive a circular iframe resize.
    const height = family === "sidebar" ? floor : Math.ceil(Math.max(floor, stage.getBoundingClientRect().height, stage.scrollHeight))
    if (height !== previous) {
      previous = height
      window.parent.postMessage({ type: "shadcn:frame-size", height }, window.location.origin)
    }
  }
  const schedule = () => {
    if (!queued) { queued = true; requestAnimationFrame(report) }
  }
  if (liveView && !liveView.classList.contains("phx-connected")) {
    const connected = new MutationObserver(() => {
      if (!liveView.classList.contains("phx-connected")) return
      connected.disconnect()
      schedule()
    })
    connected.observe(liveView, { attributes: true, attributeFilter: ["class"] })
  }
  new ResizeObserver(schedule).observe(stage)
  new MutationObserver(schedule).observe(document.body, { attributes: true, attributeFilter: ["data-family"] })
  window.addEventListener("load", schedule)
  document.fonts.ready.then(schedule)
  schedule()
}
