import fs from "node:fs/promises"
import path from "node:path"

// Builds usage-rules/components.md, a compact always-loadable index for AI agents,
// from the formatted generated component modules so it cannot drift from them.

export const componentIndexPath = "usage-rules/components.md"
const componentsDir = "lib/shadcn_liveview/components"
const formModulePath = "lib/shadcn_liveview/form.ex"
const dataTableModulePath = "lib/shadcn_liveview/data_table.ex"
/** Hand-written families outside `components/`: family → [module, path]. */
const handWritten: Record<string, [string, string]> = {
  form: ["ShadcnLiveview.Form", formModulePath],
  data_table: ["ShadcnLiveview.DataTable", dataTableModulePath],
}
const maxLines = 250

export function upstreamDocsUrl(registry: { meta?: { links?: { docs?: string } } }, family: string): string {
  return registry.meta?.links?.docs ?? `https://ui.shadcn.com/r/styles/radix-nova/${family}.json`
}

interface Attr {
  name: string
  type: string
  required: boolean
  defaultValue?: string
  values?: string[]
}

interface ComponentFn {
  name: string
  attrs: Attr[]
  requiredSlots: string[]
}

interface FamilyIndex {
  family: string
  module: string
  functions: ComponentFn[]
  helpers: string[]
  hooks: string[]
  payloads: string[]
  serverPushes: { event: string; keys: string[] }[]
  docsUrl: string
}

export function statements(source: string): string[] {
  const lines = source.split("\n")
  const result: string[] = []
  let inHeredoc = false
  let current: string[] | undefined
  const flush = () => {
    if (current) result.push(current.join(" "))
    current = undefined
  }
  for (const line of lines) {
    const trimmed = line.trim()
    const indent = line.length - line.trimStart().length
    if (inHeredoc) {
      if (trimmed === '"""') inHeredoc = false
      continue
    }
    if (trimmed === "") {
      flush()
    } else if (indent === 2) {
      flush()
      current = [trimmed]
    } else if (indent > 2 && current) {
      current.push(trimmed)
    } else {
      flush()
    }
    if (trimmed.endsWith('"""') && trimmed !== '"""') {
      flush()
      inHeredoc = true
    }
  }
  flush()
  return result
}

function literal(raw: string): string {
  const value = raw.trim()
  return value.startsWith('"') ? JSON.parse(value) : value
}

function parseValues(raw: string): string[] {
  const sigil = raw.match(/^~w\(([^)]*)\)/)
  if (sigil) return sigil[1].trim().split(/\s+/)
  const list = raw.match(/^\[([^\]]*)\]/)
  if (!list) throw new Error(`Unsupported attr values: ${raw}`)
  return list[1].split(",").map(literal)
}

function parseAttr(statement: string): Attr {
  const match = statement.match(/^attr :(\w+|"[^"]+"), ([\w.:]+)(.*)$/)
  if (!match) throw new Error(`Unparsable attr: ${statement}`)
  const [, rawName, type, rest] = match
  const name = rawName.replace(/^"|"$/g, "")
  const defaultMatch = rest.match(/\bdefault: ("(?:[^"\\]|\\.)*"|%\w*\{[^}]*\}|[^,\s]+)/)
  const valuesMatch = rest.match(/\bvalues: (~w\([^)]*\)|\[[^\]]*\])/)
  return {
    name,
    type,
    required: /\brequired: true\b/.test(rest),
    defaultValue: defaultMatch?.[1],
    values: valuesMatch ? parseValues(valuesMatch[1]) : undefined,
  }
}

function docStrings(source: string): string[] {
  const docs = [...source.matchAll(/@(?:module)?doc (?:~S)?"""\n([\s\S]*?)\n\s*"""/g)].map(match => match[1])
  for (const match of source.matchAll(/@doc "((?:[^"\\]|\\.)*)"/g)) docs.push(JSON.parse(`"${match[1]}"`))
  return docs
}

function mapKeys(map: string): string[] {
  return map.slice(2, -1).split(",").map(entry => entry.trim().split(/\s*(?:=>|:\s)\s*/)[0].replace(/^"|"$/g, "").replace(/:$/, ""))
    .filter(key => /^\w+$/.test(key))
}

function arity(args: string): number {
  if (!args.trim()) return 0
  let depth = 0
  let count = 1
  for (const char of args) {
    if ("([{".includes(char)) depth++
    else if (")]}".includes(char)) depth--
    else if (char === "," && depth === 0) count++
  }
  return count
}

export function parseFamily(family: string, module: string, source: string, docsUrl: string): FamilyIndex {
  const functions: ComponentFn[] = []
  const helpers = new Set<string>()
  const hiddenHelpers = new Set<string>()
  let pending: Attr[] = []
  let pendingSlots: string[] = []
  let hidden = false
  for (const statement of statements(source)) {
    if (statement === "@doc false") {
      hidden = true
    } else if (statement.startsWith("attr :")) {
      pending.push(parseAttr(statement))
    } else if (statement.startsWith("slot :")) {
      const head = statement.split(/\sdo\b/)[0]
      const slot = head.match(/^slot :(\w+)/)![1]
      if (/\brequired: true\b/.test(head)) pendingSlots.push(slot)
    } else if (/^defp? \w+\(/.test(statement)) {
      const [, kind, name, args] = statement.match(/^(defp?) (\w+)\(([^)]*)/)!
      if (kind === "def" && /\bassigns\s*$/.test(args)) {
        if (!functions.some(fn => fn.name === name)) functions.push({ name, attrs: pending, requiredSlots: pendingSlots })
      } else if (kind === "def" && !name.startsWith("_")) {
        const helper = `${name}/${arity(args)}`
        if (hidden) hiddenHelpers.add(helper)
        else if (!hiddenHelpers.has(helper)) helpers.add(helper)
      }
      pending = []
      pendingSlots = []
      hidden = false
    }
  }
  if (!functions.length) throw new Error(`No function components found for ${family}`)

  const hooks = new Set<string>()
  for (const match of source.matchAll(/ColocatedHook\} name="\.(\w+)"/g)) hooks.add(`${module}.${match[1]}`)
  for (const match of source.matchAll(/"phx-hook" => "ShadcnLiveview\.Components\.([\w.]+)"/g)) hooks.add(match[1])

  const payloads = new Set<string>()
  const serverPushes: FamilyIndex["serverPushes"] = []
  for (const doc of docStrings(source)) {
    for (const match of doc.matchAll(/push_event\(\w+, "([^"]+)", (%\{[^{}]*\})\)/g)) {
      serverPushes.push({ event: match[1], keys: mapKeys(match[2]) })
    }
    for (const match of doc.matchAll(/%\{[^{}]*\}/g)) {
      if (doc.slice(Math.max(0, match.index! - 40), match.index).includes("push_event(")) continue
      const keys = mapKeys(match[0])
      if (keys.includes("id")) payloads.add(`%{${keys.join(", ")}}`)
    }
  }
  return { family, module, functions, helpers: [...helpers], hooks: [...hooks].sort(), payloads: [...payloads], serverPushes, docsUrl }
}

const skippedAttrs: Record<string, true> = { class: true, rest: true }
const stateName = /^(open|checked|pressed|default_\w+)$/

function prefixed(fn: ComponentFn, root: string, text: string): string {
  return fn.name === root ? text : `${fn.name}.${text}`
}

function row(index: FamilyIndex): string {
  const root = index.functions.some(fn => fn.name === index.family) ? index.family : index.functions[0].name
  const required: string[] = []
  const enums: string[] = []
  const state: string[] = []
  const events: string[] = []
  for (const fn of index.functions) {
    const reqs = [
      ...fn.attrs.filter(attr => attr.required && !skippedAttrs[attr.name]).map(attr => attr.name),
      ...fn.requiredSlots.filter(slot => slot !== "inner_block").map(slot => `<:${slot}>`),
    ]
    if (reqs.length) required.push(`${fn.name}(${reqs.join(", ")})`)
    // `value` is controlled state for event-emitting widgets, but the submitted value on checked/pressed controls.
    const valueIsState = fn.attrs.some(attr => attr.name.startsWith("on_")) && !fn.attrs.some(attr => attr.name === "checked" || attr.name === "pressed")
    for (const attr of fn.attrs) {
      if (skippedAttrs[attr.name]) continue
      if (attr.values) {
        const def = attr.defaultValue === undefined ? undefined : literal(attr.defaultValue)
        enums.push(prefixed(fn, root, `${attr.name}=${attr.values.map(value => (value === def ? `${value}*` : value)).join("/")}`))
      }
      if (!attr.required && (stateName.test(attr.name) || (attr.name === "value" && valueIsState))) {
        state.push(prefixed(fn, root, attr.name))
      }
      if (attr.name.startsWith("on_")) {
        const def = attr.defaultValue && attr.defaultValue !== "nil" && attr.type !== "JS" ? `="${literal(attr.defaultValue)}"` : ""
        events.push(prefixed(fn, root, attr.type === "JS" ? `${attr.name}(JS)` : `${attr.name}${def}`))
      }
    }
  }
  if (index.payloads.length) events.push(`payload ${index.payloads.join(" / ")}`)
  for (const push of index.serverPushes) events.push(`server push_event "${push.event}" %{${push.keys.join(", ")}}`)
  const cells = [
    handWritten[index.family] ? `\`${index.family}\` (\`${handWritten[index.family][0]}\`, \`${handWritten[index.family][1]}\`)` : `\`${index.family}\``,
    index.functions.map(fn => fn.name).join(", "),
    required.join("; "),
    enums.join("; "),
    state.join(", "),
    events.join("; "),
    index.hooks.join(", "),
    index.docsUrl,
  ].map(cell => (cell || "-").replace(/\|/g, "\\|"))
  return `| ${cells.join(" | ")} |`
}

interface Alias {
  terms: string
  targets: [family: string, fn: string][]
  note: string
}

const aliases: Alias[] = [
  { terms: "toast, notification, snackbar, flash popup", targets: [["sonner", "toaster"]], note: "mount `<.toaster id=\"toaster\" />` once, then `push_event(socket, \"shadcn:toast\", %{toaster: \"toaster\", message: ...})` from the LiveView" },
  { terms: "modal, popup window, lightbox", targets: [["dialog", "dialog"]], note: "server-controlled `open`; handle `shadcn:modal-open`/`shadcn:modal-close`" },
  { terms: "confirm, are-you-sure, destructive confirmation", targets: [["alert_dialog", "alert_dialog"]], note: "same `open`/modal events contract as `dialog`, with action/cancel buttons" },
  { terms: "select, dropdown (form field)", targets: [["native_select", "native_select"], ["select", "select"]], note: "`native_select` = real `<select>` bound with `field={@form[:x]}`; `select` = styled listbox with hook + `on_change`" },
  { terms: "autocomplete, typeahead, searchable select", targets: [["combobox", "combobox"]], note: "filterable input + listbox" },
  { terms: "command palette, spotlight, cmd+k", targets: [["command", "command"]], note: "put it inside `dialog` for a modal palette" },
  { terms: "menu, actions menu, kebab/overflow menu", targets: [["dropdown_menu", "dropdown_menu"], ["context_menu", "context_menu"], ["menubar", "menubar"]], note: "`dropdown_menu` from a trigger; `context_menu` on right-click; `menubar` for app menus" },
  { terms: "drawer, bottom sheet", targets: [["drawer", "drawer"]], note: "slides from an edge (bottom by default)" },
  { terms: "side panel, off-canvas, slide-over", targets: [["sheet", "sheet"]], note: "dialog anchored to a side" },
  { terms: "datatable, data grid, sortable table", targets: [["data_table", "data_table"], ["table", "table"]], note: "`data_table` = server-side sorting, search, pagination, selection, column visibility and row menus (state in `ShadcnLiveview.DataTable.State`, see usage-rules/data-tables.md); `table` = markup only" },
  { terms: "link button, button link", targets: [["button", "button"]], note: "`navigate=` / `patch=` / `href=` render `Phoenix.Component.link/1` with button styling" },
  { terms: "icons, lucide, heroicons", targets: [["icon", "icon"]], note: "Lucide subset listed under Icons below; unknown names raise" },
  { terms: "form, labeled input, form group, validation errors", targets: [["form", "form_field"], ["field", "field"]], note: "`form_field` wraps input/textarea/native_select/checkbox/switch/radio_group with label, description, errors; pass `label=\"...\"` or a `<:label_content>` slot for rich label markup (exactly one); `field_*` for manual layouts" },
  { terms: "toggle switch, on/off", targets: [["switch", "switch"], ["checkbox", "checkbox"], ["toggle", "toggle"]], note: "`toggle` is a pressed button, not a form checkbox" },
  { terms: "segmented control, button toggle set", targets: [["toggle_group", "toggle_group"], ["tabs", "tabs"]], note: "`tabs` when it switches panels" },
  { terms: "expandable, disclosure, FAQ", targets: [["accordion", "accordion"], ["collapsible", "collapsible"]], note: "" },
  { terms: "date picker", targets: [["calendar", "calendar"], ["popover", "popover"]], note: "calendar inside a popover" },
  { terms: "loading, loader", targets: [["spinner", "spinner"], ["skeleton", "skeleton"], ["progress", "progress"]], note: "" },
  { terms: "chip, tag, pill, status label", targets: [["badge", "badge"]], note: "" },
  { terms: "tooltip, hint, hover info", targets: [["tooltip", "tooltip"], ["hover_card", "hover_card"]], note: "" },
  { terms: "navbar, top navigation, mega menu", targets: [["navigation_menu", "navigation_menu"], ["sidebar", "sidebar"], ["breadcrumb", "breadcrumb"]], note: "" },
  { terms: "pin code, OTP, verification code", targets: [["input_otp", "input_otp"]], note: "" },
  { terms: "chat, conversation", targets: [["message", "message"], ["bubble", "bubble"], ["message_scroller", "message_scroller"]], note: "" },
  { terms: "range, volume slider", targets: [["slider", "slider"]], note: "" },
  { terms: "divider, hr", targets: [["separator", "separator"]], note: "" },
  { terms: "keyboard shortcut, hotkey", targets: [["kbd", "kbd"]], note: "" },
  { terms: "empty state, zero state, no results", targets: [["empty", "empty"]], note: "" },
  { terms: "callout, banner, inline alert", targets: [["alert", "alert"]], note: "" },
]

function aliasLines(indexes: FamilyIndex[]): string[] {
  return aliases.map(alias => {
    const targets = alias.targets.map(([family, fn]) => {
      const index = indexes.find(entry => entry.family === family)
      if (!index?.functions.some(component => component.name === fn)) {
        throw new Error(`Component index alias "${alias.terms}" points at missing ${family}.${fn}/1`)
      }
      return `\`${family}\` (\`${fn}/1\`)`
    })
    return `- ${alias.terms} → ${targets.join(", ")}${alias.note ? `: ${alias.note}` : ""}`
  })
}

function qualifiedModule(index: FamilyIndex): string {
  return handWritten[index.family]?.[0] ?? `ShadcnLiveview.Components.${index.module}`
}

export function renderComponentIndex(indexes: FamilyIndex[], icons: string[]): string {
  const sorted = [...indexes].sort((a, b) => a.family.localeCompare(b.family))
  const sonner = sorted.find(index => index.family === "sonner")
  if (!sonner?.serverPushes.some(push => push.event === "shadcn:toast")) throw new Error("Component index: sonner shadcn:toast push not documented")
  if (!icons.length) throw new Error("Component index: no Lucide icon names found")
  const helpers = sorted.flatMap(index => index.helpers.map(helper => `\`${qualifiedModule(index)}.${helper}\``))
  const lines = [
    "<!-- GENERATED by `bun run generate` (tools/generator/component-index.ts) from lib/shadcn_liveview/components/*.ex. Do not edit; regenerate. -->",
    "# shadcn_liveview component index",
    "",
    "One row per family. `use ShadcnLiveview` imports every function component; call them as `<.name ...>`.",
    `Module: \`ShadcnLiveview.Components.<CamelFamily>\` in \`${componentsDir}/<family>.ex\` (\`form\` is \`ShadcnLiveview.Form\` in \`${formModulePath}\`, \`data_table\` is \`ShadcnLiveview.DataTable\` in \`${dataTableModulePath}\`). Full docs: \`h Module\` / moduledoc.`,
    "",
    "How to read a row:",
    "- Functions: every public function component of the family (arity 1).",
    "- Required: `fn(attr, <:slot>)` must be passed; `context` comes from the parent's `:let` slot.",
    "- Enums: `attr=a*/b/c` allowed values, `*` = default; `fn.attr` when not on the root function.",
    "- State: controlled attrs kept in your assigns (`open`, `value`, `checked`, `pressed`); `default_*` = uncontrolled initial value.",
    "- Events: `on_*=\"name\"` LiveView event pushed by default (no default = set it to receive events); `(JS)` takes `Phoenix.LiveView.JS`; `payload` keys arrive as string keys in `handle_event/3`.",
    "- Hook: colocated hook name (`<Module>.<Hook>`); interactive families need a stable `id`. Register hooks via `priv/static/shadcn-hooks.js`.",
    "- Docs: upstream shadcn/ui reference for behavior and composition.",
    "",
    "| Family | Functions | Required | Enums | State | Events | Hook | Docs |",
    "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ...sorted.map(row),
    "",
    "## Module helpers",
    "",
    `Not imported by \`use ShadcnLiveview\`; call them module-qualified (or \`import\` them with \`only:\`): ${helpers.join(", ")}.`,
    "",
    "## Icons",
    "",
    `\`<.icon name=\"...\">\` Lucide names: ${icons.join(", ")}. Lucide aliases (\`trash-2\`, \`home\`, \`more-horizontal\`, ...) and PascalCase (\`Trash2Icon\`) are accepted; \`hero-*\` names pass through to Phoenix Heroicons; other names raise \`ArgumentError\`.`,
    "",
    "## Aliases",
    "",
    "Common names → family (`function/1`).",
    "",
    ...aliasLines(sorted),
    "",
  ]
  if (lines.length > maxLines) throw new Error(`Component index has ${lines.length} lines; keep it under ${maxLines}`)
  return lines.join("\n")
}

function iconNames(source: string): string[] {
  const block = source.match(/@icon_classes %\{([\s\S]*?)\n  \}/)
  if (!block) throw new Error("Component index: @icon_classes not found in icon.ex")
  return [...block[1].matchAll(/^\s*"([a-z0-9-]+)" =>/gm)].map(match => match[1]).sort()
}

export async function buildComponentIndex(): Promise<string> {
  const files = (await fs.readdir(componentsDir)).filter(file => file.endsWith(".ex")).sort()
  const indexes: FamilyIndex[] = []
  let icons: string[] = []
  for (const file of files) {
    const family = file.replace(/\.ex$/, "")
    const source = await fs.readFile(path.join(componentsDir, file), "utf8")
    const module = source.match(/^defmodule ShadcnLiveview\.Components\.(\w+) do/)?.[1]
    if (!module) throw new Error(`Unexpected module in ${file}`)
    const registryPath = path.join("vendor/shadcn/registry", family.replace(/_/g, "-") + ".json")
    const registry = await fs.readFile(registryPath, "utf8").then(JSON.parse, () => undefined)
    const docsUrl = registry ? upstreamDocsUrl(registry, family.replace(/_/g, "-")) : family === "icon" ? "https://lucide.dev/icons" : "-"
    indexes.push(parseFamily(family, module, source, docsUrl))
    if (family === "icon") icons = iconNames(source)
  }
  indexes.push(parseFamily("form", "Form", await fs.readFile(formModulePath, "utf8"), "-"))
  indexes.push(parseFamily("data_table", "DataTable", await fs.readFile(dataTableModulePath, "utf8"), "-"))
  return renderComponentIndex(indexes, icons)
}

export async function writeComponentIndex(): Promise<void> {
  const content = await buildComponentIndex()
  await fs.mkdir(path.dirname(componentIndexPath), { recursive: true })
  await fs.writeFile(componentIndexPath, content, "utf8")
  console.log(`Generated ${componentIndexPath} (${content.split("\n").length} lines).`)
}

if (process.argv[1]?.endsWith("component-index.ts")) {
  writeComponentIndex().catch((err) => {
    console.error("Component index generation failed:", err)
    process.exit(1)
  })
}
