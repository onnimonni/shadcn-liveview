window.addEventListener("message", event => {
  if (event.origin !== window.location.origin || event.data?.type !== "shadcn:frame-size") return
  const height = event.data.height
  if (!Number.isFinite(height) || height < 120 || height > 12000) return
  const frame = [...document.querySelectorAll("iframe[data-fixture]")].find(frame => frame.contentWindow === event.source)
  if (frame && frame.style.height !== `${height}px`) frame.style.height = `${height}px`
})

// Establish one session before concurrent iframe requests create CSRF tokens.
const frames = [...document.querySelectorAll("iframe[data-src]")]
if (frames.length) {
  if (document.body.dataset.gallery === "liveview") {
    const response = await fetch(frames[0].dataset.src, { credentials: "same-origin" })
    if (!response.ok) throw new Error(`LiveView gallery session failed: ${response.status}`)
  }
  const observer = new IntersectionObserver(entries => {
    for (const { target: frame, isIntersecting } of entries) {
      if (!isIntersecting) continue
      frame.src = frame.dataset.src
      observer.unobserve(frame)
    }
  }, { rootMargin: "1200px 0px" })
  for (const frame of frames) observer.observe(frame)
}
