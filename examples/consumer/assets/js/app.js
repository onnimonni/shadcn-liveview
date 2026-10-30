import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks} from "/shadcn/shadcn-hooks.js"

const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})
liveSocket.connect()
// Exposed for Phoenix's official debug/latency and disconnect/connect APIs.
window.liveSocket = liveSocket

// Only animate this in-page anchor, never LiveView navigation or history restoration.
document.addEventListener("click", event => {
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  const link = event.target.closest?.('.northline-hero a[href="#collection"]')
  const collection = link && document.getElementById("collection")
  if (!collection) return

  event.preventDefault()
  // Match native fragment navigation without copying LiveView's page-history metadata.
  if (location.hash !== link.hash) history.pushState(null, "", link.hash)
  collection.scrollIntoView({
    behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth",
    block: "start"
  })
})
