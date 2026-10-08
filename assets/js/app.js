// Phoenix LiveView colocated hooks
let hooks = {}
try {
  const colocated = await import("phoenix-colocated/shadcn_liveview")
  hooks = colocated.hooks || {}
} catch (e) {
  // Colocated hooks extracted by phoenix_live_view compiler
}

export { hooks }
