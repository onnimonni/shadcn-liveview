import path from "node:path"
import type { ConvertResult } from "./convert"
import { familyRule, rules } from "./families"

const familyChecks: Record<string, string> = {
  dialog: "dialog: the trigger opens it, Escape/overlay/close button close it, focus returns to the trigger",
  alert_dialog: "alert dialog: action and cancel close it; focus returns to the trigger",
  sheet: "sheet: opens from the right side, Escape closes, the footer is reachable at 390x600",
  drawer: "drawer: opens/closes, content scrolls inside itself",
  dropdown_menu: "dropdown menu: opens on click, arrow keys move, selecting an item closes it, Escape returns focus",
  popover: "popover: opens/closes, Escape returns focus",
  tooltip: "tooltip: shows on hover/focus",
  hover_card: "hover card: shows on hover",
  context_menu: "context menu: opens on right click",
  select: "select: opens, choosing an option updates the trigger text and the server value",
  tabs: "tabs: clicking/arrow keys switch panels",
  accordion: "accordion: items expand/collapse",
  collapsible: "collapsible: the trigger toggles the content and aria-expanded",
  sidebar: "sidebar: the trigger collapses/expands (Ctrl/Cmd+B), the mobile drawer opens at 390px, the footer is reachable at 390x600 and 1280x600",
  toggle_group: "toggle group: pressing items updates aria-pressed",
  radio_group: "radio group: arrow keys move the selection; FormData matches",
  checkbox: "checkbox: FormData matches aria-checked after rapid clicks",
  switch: "switch: FormData matches aria-checked after rapid clicks",
  field: "forms: typing triggers phx-change, submit reaches the submit handler, clearing a required field shows an error",
  sonner: "toasts: the toast appears (assert_push_event in tests)",
  data_table: "data table: sorting, search, page size and paging change the rows; select-all is per page (indeterminate when partial) and selection survives paging; the columns menu hides/shows columns; row menu items reach the `{:action, ...}` clause",
}

export function markdownReport(result: ConvertResult, outPath?: string): string {
  const rel = (file: string) => (file.startsWith("/registry/") ? file.slice(10) : path.relative(process.cwd(), file) || file)
  const lines: string[] = [
    `# shadcn-to-liveview report: ${result.label}`,
    "",
    `- Module: \`${result.module}\`${outPath ? ` → \`${outPath}\`` : ""}`,
    `- Entry: \`${rel(result.entry)}\`; files with converted components: ${result.files.map(file => `\`${rel(file)}\``).join(", ")} (see Source completeness for what was not converted)`,
    `- Sub-components: ${result.components.length ? result.components.join(", ") : "none"}`,
    `- Assigns: ${result.assigns.length ? result.assigns.map(name => `\`@${name}\``).join(", ") : "none"}; events: ${result.events.length ? result.events.map(name => `\`${name}\``).join(", ") : "none"}`,
    `- **${result.todos.length} TODO(s)** (\`TODO(shadcn-to-liveview)\` comments in the output, including ${result.placeholders.length} placeholder handler(s)), **${result.skipped.length} skipped source part(s)** with no output at all, ${result.notes.length} note(s)`,
    "",
    "## Mapping",
    "",
    "| React | LiveView | Count |",
    "| --- | --- | --- |",
    ...result.mapping.map(entry => `| \`${entry.react}\` | \`${entry.liveview}\` | ${entry.count} |`),
    "",
    "## TODOs",
    "",
  ]
  if (result.todos.length) {
    lines.push("| # | Source | Issue | Follow |", "| --- | --- | --- | --- |")
    result.todos.forEach((todo, index) => lines.push(`| ${index + 1} | \`${rel(todo.file)}:${todo.line}\` | ${todo.reason.replace(/\|/g, "\\|")} | ${todo.rule} |`))
  } else {
    lines.push("None.")
  }
  lines.push("", "## Notes (automatic approximations)", "")
  if (result.notes.length) for (const note of result.notes) lines.push(`- \`${rel(note.file)}:${note.line}\`: ${note.message}`)
  else lines.push("None.")

  lines.push("", "## Source completeness", "")
  if (result.skipped.length) {
    lines.push(
      "These parts of the source produced **no output and no TODO comment**; the converted module does not implement them. Rebuild each one (or delete it deliberately) before comparing with the original.",
      "",
      "| # | Source | Kind | Not converted | Follow |",
      "| --- | --- | --- | --- | --- |",
    )
    result.skipped.forEach((part, index) => lines.push(`| ${index + 1} | \`${rel(part.file)}:${part.line}\` | ${part.kind} | ${part.message.replace(/\|/g, "\\|")} | ${part.rule} |`))
  } else {
    lines.push("Every component, callback and markup subtree in the source was either converted or reported as a TODO above.")
  }

  lines.push("", "## Required manual steps", "")
  lines.push(`1. Route it: \`live "/${result.label}", ${result.module.split(".").slice(1).join(".")}\` inside your browser scope (full-page templates render without \`<Layouts.app>\`; wrap them if you want the app shell).`)
  lines.push("2. Run `mix format`, then resolve every `TODO(shadcn-to-liveview)` (grep the output) using the linked usage-rules section, and every row under Source completeness.")
  if (result.assigns.includes("ui")) {
    lines.push(`3. Interactive state is in a generated \`@ui\` map (component id → open/value) updated by catch-all \`handle_event/3\` clauses (${rules.state}). Replace entries with domain assigns where the app cares about the state.`)
  }
  for (const placeholder of result.placeholders) lines.push(`- Implement the placeholder \`${placeholder.event}\` handler (\`${rel(placeholder.file)}:${placeholder.line}\`): it only re-assigns the params; validate with a changeset and persist/authenticate there (${rules.forms}).`)
  if (result.families.includes("sidebar")) lines.push(`- Sidebar: with several LiveViews, move the \`shadcn:sidebar-change\` handling and the \`sidebar_state\` cookie into an \`on_mount\` hook (${rules.sidebar}).`)
  if (result.families.includes("data_table")) lines.push(`- Data table: TanStack state became a \`ShadcnLiveview.DataTable.State\` assign updated by the generated \`handle_event/3\` + \`load_*\` functions (in-memory rows). Implement row menu actions in the \`{:action, value, row_id, table}\` branch (after a delete call \`DataTable.remove_row/2\` so focus lands on the next row), load rows from your context, and keep the query in the URL with \`DataTable.from_params/2\`/\`to_params/1\` (${rules.tables}).`)
  if (result.assigns.some(name => name.endsWith("_form"))) lines.push(`- Forms use \`to_form(params)\` placeholders: back them with an Ecto changeset, validate in \`validate_*\`, persist in \`submit_*\`, and render errors (\`form_field\`/\`field_error\`) (${rules.forms}).`)
  if (/\n {2}defp? \w+ do\n {4}[%[]/.test(result.code)) lines.push("- Sample data from the template is in zero-arity functions at the bottom of the module (public `def` when only TODOs need it, e.g. chart rows React computed); replace it with real data (assigns/contexts).")
  if (result.code.includes("template_icon")) lines.push("- Icons missing from `icon/1` were inlined as SVG in `template_icon/1`.")
  if (result.assets.length) {
    const entries = [...new Set(result.assets.map(asset => asset.path.split("/")[1]))]
    lines.push(`- Static assets: the template references ${result.assets.length} root-relative file(s) the app must serve (missing files are failed requests, not compile errors). Copy each to \`priv/static\` at the same path and add ${entries.map(entry => `\`${entry}\``).join(", ")} to \`static_paths/0\` in your web module (Phoenix default: \`~w(assets fonts images favicon.ico robots.txt)\`), or point the URLs at your own files:`)
    for (const asset of result.assets) lines.push(`  - \`${asset.path}\`${asset.url ? ` (original: ${asset.url})` : ""}`)
  }
  if (result.viewport) {
    lines.push("- `@is_mobile` replaces React's `useIsMobile()`/`useSidebar().isMobile` (max-width 767px). mount/3 reads it from the LiveSocket connect params (they arrive as strings, so it accepts `\"true\"`) and the colocated `.Viewport` hook (rendered at the top of the template) pushes `viewport` whenever the breakpoint flips while connected. Send it on connect so the first connected render already uses the mobile layout:")
    lines.push("", "  ```js", "  // assets/js/app.js", "  const liveSocket = new LiveSocket(\"/live\", Socket, {", "    params: () => ({_csrf_token: csrfToken, is_mobile: window.matchMedia(\"(max-width: 767px)\").matches}),", "    hooks: {...colocatedHooks, ...shadcnHooks},", "  })", "  ```", "")
    lines.push("  Several LiveViews: move the `viewport` handle_event/3 and the `is_mobile` assign into a shared `on_mount` hook (`attach_hook(socket, :viewport, :handle_event, ...)`).")
  }

  lines.push("", "## Verification checklist", "")
  lines.push("- [ ] `mix compile --warnings-as-errors` (unknown attrs and invalid enum values fail here)")
  lines.push(`- [ ] LiveViewTest: \`{:ok, view, html} = live(conn, "/${result.label}")\` renders (unknown icon names raise only at render) and contains the template's headings; exercise each generated event with \`render_click\`/\`render_change\`/\`render_submit\``)
  lines.push("- [ ] Browser (Playwright) at 1280px and 390px wide, side by side with the React original: layout, spacing, icons, no horizontal overflow")
  const families = new Set(result.families)
  if (result.assigns.some(name => name.endsWith("_form"))) families.add("field")
  for (const family of families) if (familyChecks[family]) lines.push(`- [ ] ${familyChecks[family]} (${familyRule(family)})`)
  if (result.viewport) lines.push("- [ ] viewport: resizing across 768px flips the mobile-only placements without a reload (`@is_mobile`)")
  lines.push("- [ ] Connected and disconnected (`liveSocket.disconnect()`): interacting logs no console errors")
  lines.push("")
  return lines.join("\n")
}

export function jsonReport(result: ConvertResult, outPath?: string): string {
  return JSON.stringify({ ...result, out: outPath, todoCount: result.todos.length, skippedCount: result.skipped.length }, null, 2) + "\n"
}
