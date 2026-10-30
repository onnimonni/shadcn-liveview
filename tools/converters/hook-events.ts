// The one push helper every colocated hook emits. It honors the nearest
// phx-target (the hook root's own included), so LiveComponent CIDs and
// selectors receive their events.
//
// LiveView rejects hook pushes while the socket is disconnected and when the
// server errors. The returned promise is pre-handled, so a failed push never
// surfaces as an unhandled rejection. It resolves with the reply and rejects
// with the push error; hooks that optimistically repaint server-controlled
// state chain `.catch` to restore the last server-rendered state. `onReply`
// receives the reply only after a successful push, and its exceptions still
// surface.
export function sendEventMethod(indent: string): string {
  return [
    "sendEvent(event, payload, onReply) {",
    "  const target = this.el.closest('[phx-target]')?.getAttribute(\"phx-target\");",
    "  const push = target",
    "    ? this.pushEventTo(target, event, payload).then(results => {",
    "        const failed = results.find(result => result.status === \"rejected\");",
    "        if (failed) throw failed.reason;",
    "        return results[0]?.value.reply;",
    "      })",
    "    : this.pushEvent(event, payload);",
    "  push.catch(() => {});",
    "  if (onReply) push.then(onReply, () => {});",
    "  return push;",
    "},",
  ].map(line => indent + line).join("\n")
}
