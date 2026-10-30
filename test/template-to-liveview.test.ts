import test from "node:test"
import assert from "node:assert/strict"
import { convertTemplate, type ConvertResult } from "../tools/template-to-liveview/convert"
import { markdownReport } from "../tools/template-to-liveview/report"
import { normalizeMaps, type Term } from "../tools/template-to-liveview/elixir"
import { contextKey, fieldControls, modalFamilies, popupFamilies, qualifiedFunctions, yieldingRoots } from "../tools/template-to-liveview/families"
import { findLucide } from "../tools/template-to-liveview/lucide"
import { loadMetadata, lucideName } from "../tools/template-to-liveview/metadata"
import { loadPath, type SourceSet } from "../tools/template-to-liveview/source"

const meta = loadMetadata("lib/shadcn_liveview")
const lucide = findLucide(undefined, [process.cwd()])
const convert = (input: string, module = "DemoWeb.TemplateLive") => convertTemplate(loadPath(input), meta, { module, lucide })
/** In-memory template: `files` maps names under /virtual to their content; `page.tsx` is the entry. */
const convertFiles = (files: Record<string, string>) => {
  const set: SourceSet = { entry: "/virtual/page.tsx", files: new Map(Object.entries(files).map(([name, code]) => [`/virtual/${name}`, code])), roots: [], label: "fixture" }
  return convertTemplate(set, meta, { module: "DemoWeb.FixtureLive", lucide })
}

test("family recipes reference existing functions and attrs", () => {
  for (const [fn, recipe] of Object.entries(yieldingRoots)) {
    assert.ok(meta.functions.has(fn), `${fn}/1 missing`)
    assert.match(recipe.variable, /^\w+$/)
  }
  for (const [fn, recipe] of Object.entries(popupFamilies)) {
    const root = meta.functions.get(fn)!
    assert.ok(root.slots.has("trigger") && root.slots.has("content"), `${fn} lost its trigger/content slots`)
    assert.equal(meta.functions.get(recipe.contentFn)?.attrs.get("context")?.required, true, `${recipe.contentFn} needs context`)
  }
  for (const fn of Object.keys(modalFamilies)) {
    assert.ok(meta.functions.get(fn)!.slots.has("content"), `${fn} lost its content slot`)
    for (const part of ["content", "trigger", "title", "description"]) assert.ok(meta.functions.has(`${fn}_${part}`), `${fn}_${part}/1 missing`)
  }
  for (const fn of [...Object.keys(fieldControls), ...Object.keys(qualifiedFunctions)]) assert.ok(meta.functions.has(fn), `${fn}/1 missing`)
  for (const fn of Object.keys(fieldControls)) assert.ok(meta.functions.get(fn)!.attrs.has("field"), `${fn} has no field attr`)
  assert.equal(contextKey("accordion_trigger", "accordion", "context"), "accordion_item")
  assert.ok(meta.functions.get("sidebar")!.attrs.get("sidebar")?.required)
})

test("icons map through icon/1 names and aliases", () => {
  assert.equal(lucideName(meta, "ChevronRightIcon"), "chevron-right")
  assert.equal(lucideName(meta, "Trash2"), "trash")
  assert.equal(lucideName(meta, "NotARealIconIcon"), undefined)
})

test("sample data rows get every key the template reads", () => {
  const term = normalizeMaps({ t: "list", items: [{ t: "map", entries: [["title", { t: "raw", code: '"a"' }]] }] }, new Set(["is_active"]))
  assert.deepEqual(term, { t: "list", items: [{ t: "map", entries: [["title", { t: "raw", code: '"a"' }], ["is_active", { t: "raw", code: "nil" }]] }] })
})

test("login block: card/field mapping, form binding, sub-component", () => {
  const result = convert("vendor/shadcn/blocks/login-03")
  // The generated submit handler is a placeholder: counted as a TODO and listed as a manual step.
  assert.equal(result.todos.length, 1)
  assert.match(result.todos[0].reason, /`submit_login` is a generated placeholder/)
  assert.deepEqual(result.placeholders.map(placeholder => placeholder.event), ["submit_login"])
  assert.match(result.code, /def handle_event\("submit_login"[^\n]*\n\s+# TODO\(shadcn-to-liveview\): placeholder/)
  assert.match(markdownReport(result), /- Implement the placeholder `submit_login` handler \(`[^`]+login-form\.tsx:\d+`\)/)
  assert.deepEqual(result.skipped, [])
  assert.match(result.code, /use DemoWeb, :live_view/)
  assert.match(result.code, /<\.login_form login_form=\{@login_form\} \/>/)
  assert.match(result.code, /<\.form for=\{@login_form\} id="login-form" phx-change="validate_login" phx-submit="submit_login">/)
  assert.match(result.code, /<Input\.input id="email" type="email"[^>]*field=\{@login_form\[:email\]\}/)
  assert.match(result.code, /<\.field_label for="email">Email<\/\.field_label>/)
  assert.match(result.code, /<\.button type="submit" variant="default">Login<\/\.button>/)
  assert.match(result.code, /alias ShadcnLiveview\.Components\.\{Input\}|alias ShadcnLiveview\.Components\.Input/)
  assert.match(result.code, /def handle_event\("submit_login", %\{"login" => params\}, socket\)/)
})

test("sidebar block: provider context, data, links, collapsibles", () => {
  const result = convert("vendor/shadcn/blocks/sidebar-08")
  assert.match(result.code, /<\.sidebar_provider id="[\w-]+" open=\{Map\.get\(@ui, "[\w-]+", true\)\}[\s\S]*?:let=\{sidebar\}>/)
  assert.match(result.code, /<\.app_sidebar sidebar=\{sidebar\}/)
  assert.match(result.code, /attr :sidebar, :map, required: true/)
  assert.match(result.code, /<\.sidebar id="[\w-]+" sidebar=\{@sidebar\}/)
  assert.match(result.code, /<\.sidebar_trigger sidebar=\{sidebar\}/)
  assert.match(result.code, /<\.sidebar_menu_button tag="a" href=\{item\.url\}/)
  // Collapsible asChild around SidebarMenuItem: the li stays directly under the ul, the collapsible goes inside it.
  assert.match(result.code, /<\.sidebar_menu_item :for=\{\{item, index\} <- Enum\.with_index\(@items\)\}>\n\s+<\.collapsible id=\{"[\w-]+-#\{index\}"\} [^\n]*:let=\{collapsible\}>/)
  assert.doesNotMatch(result.code, /<\.sidebar_menu>\n\s+<\.collapsible\b/)
  assert.match(result.code, /phx-click=\{JS\.push\("control_open", value: %\{id: collapsible\.id, open: !collapsible\.open\}\)\}/)
  assert.match(result.code, /<\.dropdown_menu id=\{"[\w-]+-#\{index\}"\}[^>]*>\s*<:trigger :let=\{popup\}>/)
  assert.match(result.code, /\{popup\.trigger\}/)
  assert.match(result.code, /defp sidebar_data do\n\s+%\{/, "a generic `data` binding is named after its file")
  assert.match(result.code, /def handle_event\("shadcn:sidebar-change", %\{"id" => id, "open" => open\}, socket\)/)
  assert.match(result.code, /defp put_ui\(socket, id, value\)/)
})

test("dialog example: modal slots, trigger and close wiring", () => {
  const result = convert("vendor/shadcn/examples/dialog-example.tsx")
  assert.match(result.code, /<\.dialog id="[\w-]+" open=\{Map\.get\(@ui, "[\w-]+", false\)\}>/)
  assert.match(result.code, /<:trigger :let=\{modal\}>\s*<\.button[^>]*id=\{modal\.trigger_id\} phx-click=\{modal\.on_open\}/)
  assert.match(result.code, /<\.dialog_content context=\{modal\} aria-labelledby=\{modal\.title_id\}/)
  assert.match(result.code, /phx-click=\{modal\.on_close\}/)
  assert.match(result.code, /def handle_event\("shadcn:modal-close", %\{"id" => id\}, socket\)/)
})

test("tabs and select examples use uncontrolled defaults and option slots", () => {
  const tabs = convert("vendor/shadcn/examples/tabs-example.tsx")
  assert.match(tabs.code, /<\.tabs id="[\w-]+" default_value="\w+"[^>]*:let=\{tabs\}>/)
  assert.match(tabs.code, /<\.tabs_trigger context=\{tabs\} value="\w+"/)
  const select = convert("vendor/shadcn/examples/select-example.tsx")
  assert.match(select.code, /<\.select id="[\w-]+" open=\{Map\.get\(@ui/)
  assert.match(select.code, /<:option id="[\w-]+" value="[\w-]+" label="[^"]+">/)
  assert.match(select.code, /<\.select_trigger context=\{popup\}/)
})

test("version switcher: useState becomes an assign with a push handler", () => {
  const result = convert("vendor/shadcn/blocks/sidebar-01")
  assert.match(result.code, /selected_version: Enum\.at\(sidebar_data\(\)\.versions, 0\)/)
  assert.match(result.code, /phx-click=\{JS\.push\("set_selected_version", value: %\{selected_version: version\}\)\}/)
  assert.match(result.code, /def handle_event\("set_selected_version", %\{"selected_version" => selected_version\}, socket\)/)
})

test("unconvertible parts become TODO comments listed in the report", () => {
  const result = convert("vendor/shadcn/examples/combobox-example.tsx")
  assert.ok(result.todos.length > 0)
  for (const todo of result.todos) {
    assert.ok(todo.line > 0 || todo.reason.includes("Lucide"), `TODO without a source line: ${todo.reason}`)
    assert.match(todo.rule, /usage-rules/)
  }
  assert.match(result.code, /<%!-- TODO\(shadcn-to-liveview\): /)
  assert.doesNotMatch(result.code, /<\.combobox\b/, "half-converted comboboxes would not compile")
})

test("function component mode exposes state as attrs", () => {
  const result = convertTemplate(loadPath("vendor/shadcn/blocks/sidebar-03"), meta, { module: "DemoWeb.Sidebar", mode: "component" })
  assert.match(result.code, /use DemoWeb, :html/)
  assert.match(result.code, /attr :ui, :any, required: true\n {2}def page\(assigns\) do/)
  assert.doesNotMatch(result.code, /def mount/)
})

test("team switcher: object setters push a row key that handle_event looks up; early return becomes :if", () => {
  const result = convert("vendor/shadcn/blocks/sidebar-07")
  assert.equal(result.todos.length, 0, result.todos.map(todo => todo.reason).join("\n"))
  // The whole atom-key map never travels through JSON: the payload is the unique `name`.
  assert.match(result.code, /phx-click=\{JS\.push\("set_active_team", value: %\{active_team: team\.name\}\)\}/)
  assert.match(result.code, /def handle_event\("set_active_team", %\{"active_team" => active_team\}, socket\),\n\s+do: \{:noreply, assign\(socket, active_team: Enum\.find\(sidebar_data\(\)\.teams, &\(&1\.name == active_team\)\) \|\| socket\.assigns\.active_team\)\}/)
  assert.match(result.code, /active_team: Enum\.at\(sidebar_data\(\)\.teams, 0\)/)
  assert.match(result.code, /<\.sidebar_menu :if=\{@active_team\}>/)
})

test("object setters: index payload without a unique key, id preferred, literal maps are TODOs", () => {
  const result = convertFiles({
    "page.tsx": `import * as React from "react"
import { Button } from "@/components/ui/button"
const plans = [{ tier: "Free", price: 0 }, { tier: "Free", price: 10 }]
const people = [{ id: 7, label: "Ann" }, { id: 9, label: "Bo" }]
export default function Page() {
  const [plan, setPlan] = React.useState(plans[0])
  const [person, setPerson] = React.useState(people[0])
  const [options, setOptions] = React.useState({ dense: false })
  return (
    <div>
      {plans.map((item, index) => <Button key={index} onClick={() => setPlan(item)}>{item.tier}</Button>)}
      {people.map((entry) => <Button key={entry.id} onClick={() => setPerson(entry)}>{entry.label}</Button>)}
      <Button onClick={() => setOptions({ dense: true })}>Dense</Button>
      <span>{plan.tier} {person.label} {String(options.dense)}</span>
    </div>
  )
}`,
  })
  assert.match(result.code, /JS\.push\("set_plan", value: %\{plan: index\}\)/)
  assert.match(result.code, /assign\(socket, plan: Enum\.at\(plans\(\), plan\) \|\| socket\.assigns\.plan\)/)
  assert.match(result.code, /JS\.push\("set_person", value: %\{person: entry\.id\}\)/)
  assert.match(result.code, /assign\(socket, person: Enum\.find\(people\(\), &\(&1\.id == person\)\) \|\| socket\.assigns\.person\)/)
  assert.doesNotMatch(result.code, /set_options/)
  assert.ok(result.todos.some(todo => /map\/list literal/.test(todo.reason)), "literal map payload must be a TODO")
})

test("static JSON imports become data functions (default and named)", () => {
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.match(dashboard.code, /<\.data_table_section data=\{data\(\)\}/)
  assert.match(dashboard.code, /defp data do\n\s+\[\n\s+%\{\n\s+id: 1,\n\s+header: "Cover page",/)
  assert.match(dashboard.code, /\n\s+data: data\(\),/, "DataTable's useState(() => data) starts from the JSON")
  assert.ok(!dashboard.todos.some(todo => /unknown identifier `data`|initial value of `data`/.test(todo.reason)))

  const named = convertFiles({
    "page.tsx": `import { rows } from "./stats.json"
export default function Page() {
  return <ul>{rows.map((row) => <li key={row.day}>{row.day}: {row.visits}</li>)}</ul>
}`,
    "stats.json": `{"rows": [{"day": "Mon", "visits": 3}, {"day": "Tue", "visits": 5}], "unused": true}`,
  })
  assert.equal(named.todos.length, 0, named.todos.map(todo => todo.reason).join("\n"))
  assert.match(named.code, /<li :for=\{row <- rows\(\)\}>\{row\.day\}: \{row\.visits\}<\/li>/)
  assert.match(named.code, /defp rows do\n\s+\[%\{day: "Mon", visits: 3\}, %\{day: "Tue", visits: 5\}\]/)
})

test("source completeness lists every skipped component, column, callback, markup and library", () => {
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  const columns = dashboard.skipped.filter(part => part.kind === "column").map(part => part.message.match(/column `(\w+)`/)?.[1])
  // Every other TanStack column became a data_table slot; the dnd-kit drag handle stays out (reported).
  assert.deepEqual(columns, ["drag"])
  assert.match(dashboard.skipped.find(part => part.kind === "column")!.message, /dnd-kit drag handle: row reordering is not converted/)
  const components = dashboard.skipped.filter(part => part.kind === "component").map(part => part.message.match(/component `(\w+)`/)?.[1])
  assert.deepEqual(components, ["DragHandle", "DraggableRow"])
  assert.ok(dashboard.skipped.some(part => part.kind === "callback" && part.message.includes("handleDragEnd")))
  for (const library of ["@dnd-kit/core", "@dnd-kit/sortable"]) {
    assert.ok(dashboard.skipped.some(part => part.kind === "library" && part.message.startsWith(`\`${library}\``)), `${library} not reported`)
  }
  assert.ok(!dashboard.skipped.some(part => part.message.startsWith("`@tanstack/react-table`")), "converted TanStack imports are not reported")
  for (const part of dashboard.skipped) assert.ok(part.line > 0 && part.endLine >= part.line && /usage-rules/.test(part.rule), JSON.stringify(part))
  const report = markdownReport(dashboard)
  assert.match(report, /\*\*\d+ skipped source part\(s\)\*\*/)
  assert.match(report, /## Source completeness\n\nThese parts of the source produced \*\*no output and no TODO comment\*\*/)
  assert.match(report, /\| `[^`]*data-table\.tsx:156` \| column \| TanStack column `drag`/)

  const fixture = convertFiles({
    "page.tsx": `import { Badge } from "@/components/ui/badge"
import { useReactTable } from "@tanstack/react-table"
function Unused() {
  return <p>never</p>
}
const columns = [
  { accessorKey: "email", header: "Email", cell: ({ row }) => <Badge>{row.original.email}</Badge> },
  { id: "actions", cell: () => <span>menu</span> },
]
export default function Page() {
  const spare = <em>spare</em>
  function save() {
    console.log("saved")
  }
  return <div><Badge>ok</Badge></div>
}`,
  })
  assert.deepEqual(fixture.skipped.map(part => [part.kind, part.line]), [
    ["library", 2], ["component", 3], ["column", 7], ["column", 8], ["markup", 11], ["callback", 12],
  ])
  assert.match(fixture.skipped[2].message, /column `email` \(lines 7-7\) with cell renderer/)
  // Converted parts are never listed.
  assert.equal(fixture.todos.length, 0)
})

test("TanStack tables (v9 useTable, v8 useReactTable + ColumnDef[]) become data_table with DataTable state", () => {
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  const code = dashboard.code
  assert.match(code, /alias ShadcnLiveview\.DataTable/)
  assert.match(code, /table: DataTable\.new\(id: "data-table", event: "data-table"\),\n\s+table_rows: \[\]\n\s+\)\n\s+\|> load_table\(\)\}/)
  assert.match(code, /<\.data_table state=\{@table\} rows=\{@table_rows\} selectable header_class="sticky top-0 z-10 bg-muted" row_label="header">/)
  assert.deepEqual([...code.matchAll(/<:col (?::let=\{row\} )?field="(\w+)"/g)].map(match => match[1]), ["header", "type", "status", "target", "limit", "reviewer"])
  assert.match(code, /<:col :let=\{row\} field="status" label="Status"><\.badge[^\n]*\{row\.status\}/)
  assert.match(code, /<:col :let=\{row\} field="target" label="Target" head_class="text-right">/)
  // The cell's own component renders once per row: its generated ids carry the row key.
  assert.match(code, /<\.table_cell_viewer item=\{row\}[^\n]* item_key=\{"#\{row\.id\}"\} \/>/)
  assert.match(code, /<\.drawer id=\{"table-cell-viewer-drawer-#\{@item_key\}"\}/)
  assert.match(code, /<\.form for=\{@data_table_form\} id=\{"data-table-form-#\{row\.id\}"\}/)
  assert.match(code, /<:row_actions class="w-32">\n\s+<\.dropdown_menu_item>Edit<\/\.dropdown_menu_item>/)
  assert.match(code, /<\.data_table_view_options state=\{@table\} columns=\{\["type", "status", "target", "limit", "reviewer"\]\} content_class="w-32" \/>/)
  assert.match(code, /<\.data_table_pagination state=\{@table\} selectable class="flex items-center justify-between px-4" \/>/)
  assert.match(code, /def handle_event\("data-table", params, socket\) do\n\s+case DataTable\.handle_event\(params, socket\.assigns\.table\) do\n\s+\{:query, table, _opts\} -> \{:noreply, socket \|> assign\(:table, table\) \|> load_table\(\)\}/)
  assert.match(code, /defp load_table\(socket\) do\n\s+\{rows, table\} = DataTable\.apply\(socket\.assigns\.table, socket\.assigns\.data\)\n\s+assign\(socket, table: table, table_rows: rows\)/)
  assert.doesNotMatch(code, /getHeaderGroups|getRowModel|row_selection|column_visibility|pagination: %\{/)
  assert.ok(!dashboard.todos.some(todo => /useTable|getHeaderGroups|getRowModel|getPageCount|nextPage|getAllColumns/.test(todo.reason)))
  // dnd-kit row reordering stays a TODO plus completeness rows.
  assert.ok(dashboard.todos.some(todo => todo.reason.includes("<DndContext>")))
  assert.ok(dashboard.families.includes("data_table"))
  assert.match(markdownReport(dashboard), /- \[ \] data table: sorting, search, page size and paging change the rows/)

  const guide = convert("test/fixtures/tanstack-data-table", "DemoWeb.PaymentsLive")
  assert.equal(guide.todos.length, 0, guide.todos.map(todo => todo.reason).join("\n"))
  assert.equal(guide.skipped.length, 0, guide.skipped.map(part => part.message).join("\n"))
  assert.match(guide.code, /table: DataTable\.new\(id: "data-table", event: "data-table", sortable: \["email"\], sort: "email", page_size: 5, searchable: \["email"\]\)/)
  // The consumed `columns`/`data` props are not passed; rows come from the page's data.
  assert.match(guide.code, /<\.data_table_section table=\{@table\} table_rows=\{@table_rows\} \/>/)
  assert.match(guide.code, /DataTable\.apply\(socket\.assigns\.table, payments\(\)\)/)
  assert.match(guide.code, /<\.data_table_search state=\{@table\} placeholder="Filter emails\.\.\." input_class="max-w-sm" \/>/)
  assert.match(guide.code, /<\.data_table_view_options state=\{@table\} columns=\{\["status", "email", "amount"\]\} \/>/)
  assert.match(guide.code, /<:col :let=\{row\} field="status" label="Status">\n\s+<div class="capitalize">\{row\.status\}<\/div>/)
  assert.match(guide.code, /<:col field="amount" label="Amount" head_class="text-right" \/>/)
  assert.match(guide.code, /<:row_actions :let=\{row\}>[\s\S]*<\.dropdown_menu_item variant="destructive">Delete \{row\.email\}<\/\.dropdown_menu_item>/)
  assert.match(guide.code, /<\.data_table_pagination state=\{@table\} selectable class="flex items-center justify-end space-x-2 py-4" \/>/)
  assert.doesNotMatch(guide.code, /actions: nil|attr :columns|attr :data/)
})

test("useIsMobile/useSidebar().isMobile become @is_mobile from connect params plus a viewport hook", () => {
  const sidebar = convert("vendor/shadcn/blocks/sidebar-07")
  assert.equal(sidebar.viewport, true)
  assert.match(sidebar.code, /is_mobile: get_connect_params\(socket\)\["is_mobile"\] in \[true, "true"\]/, "LiveSocket params arrive as strings")
  assert.match(sidebar.code, /if \(this\.liveSocket\.isConnected\(\) && String\(this\.media\.matches\) !== this\.el\.dataset\.mobile\) \{\n\s+this\.sendEvent\("viewport", \{is_mobile: this\.media\.matches\}\)/)
  assert.match(sidebar.code, /\n\s+push\.catch\(\(\) => \{\}\);/, "rejected viewport pushes are handled")
  assert.match(sidebar.code, /reconnected\(\) \{\n\s+this\.sync\(\)/)
  assert.match(sidebar.code, /def handle_event\("viewport", %\{"is_mobile" => is_mobile\}, socket\),\n\s+do: \{:noreply, assign\(socket, :is_mobile, is_mobile == true\)\}/)
  assert.match(sidebar.code, /<div id="sidebar-07-viewport" phx-hook="\.Viewport" data-mobile=\{to_string\(@is_mobile\)\} hidden><\/div>\n\s+<script :type=\{Phoenix\.LiveView\.ColocatedHook\} name="\.Viewport">/)
  assert.match(sidebar.code, /side=\{if\(@is_mobile, do: "bottom", else: "right"\)\}/)
  assert.match(sidebar.code, /<\.team_switcher [^>]*is_mobile=\{@is_mobile\}/)
  assert.match(markdownReport(sidebar), /is_mobile: window\.matchMedia\("\(max-width: 767px\)"\)\.matches/)

  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.ok(!dashboard.todos.some(todo => todo.reason.includes("useIsMobile")))
  assert.ok(!dashboard.skipped.some(part => part.message.includes("useIsMobile")))
})

test("Recharts charts with static data become chart_canvas; others one TODO without orphan markup", () => {
  const examples = convert("vendor/shadcn/examples/chart-example.tsx")
  assert.match(examples.code, /<\.chart_container id="[\w-]+" config=\{area_chart_config\(\)\} :let=\{chart\}>\n\s+<\.chart_canvas id="[\w-]+" context=\{chart\} kind="area" data=\{area_chart_data\(\)\} series=\{\["desktop"\]\} x_key="month" curve="natural" fill_opacity=\{0\.4\} grid="horizontal" axis_line=\{false\} tick_line=\{false\} tick_margin=\{8\} tick_format=\{fn value -> String\.slice\(value, 0\.\.\(3 - 1\)\/\/1\) end\} cursor=\{false\} \/>/)
  assert.match(examples.code, /kind="bar" data=\{bar_chart_data\(\)\} series=\{\["desktop", "mobile"\]\} x_key="month" grid="horizontal" axis_line=\{false\} tick_line=\{false\} tick_margin=\{10\} tick_format=\{fn value -> [^}]+ end\} cursor=\{false\} \/>/)
  assert.match(examples.code, /kind="line" data=\{line_chart_data\(\)\} series=\{\["desktop", "mobile"\]\} x_key="month" curve="monotone" grid="horizontal"/)
  const notes = examples.notes.map(note => note.message).filter(message => message.startsWith("chart_canvas"))
  assert.deepEqual(notes, [
    'chart_canvas kind="area" approximates AreaChart; no equivalent for: <AreaChart margin>, <ChartTooltipContent indicator="line">.',
    'chart_canvas kind="bar" approximates BarChart; no equivalent for: <ChartTooltipContent indicator="dashed">, <Bar radius>.',
    'chart_canvas kind="line" approximates LineChart; no equivalent for: <LineChart margin>, <Line strokeWidth>, <Line dot>.',
  ], "only props without a chart_canvas attr are listed")
  assert.match(examples.code, /<\.chart_container [^>]*>\n\s+<%!-- TODO\(shadcn-to-liveview\): chart_canvas draws a single Recharts [^\n]*<PieChart>/)
  assert.doesNotMatch(examples.code, /<(defs|linearGradient|CartesianGrid|XAxis)\b/)

  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.doesNotMatch(dashboard.code, /<(defs|linearGradient|stop)\b/)
  // dashboard-01's stacked natural gradient chart: the canvas is complete; only React's date filter is a TODO.
  assert.match(dashboard.code, /<\.chart_canvas id="chart-area-interactive-chart-canvas" context=\{chart\} kind="area" data=\{@filtered_data\} series=\{\[%\{key: "mobile", gradient_opacity: \[0\.8, 0\.1\]\}, %\{key: "desktop", gradient_opacity: \[1\.0, 0\.1\]\}\]\} x_key="date" stack curve="natural" fill="gradient" grid="horizontal" axis_line=\{false\} tick_line=\{false\} tick_margin=\{8\} min_tick_gap=\{32\} tick_format="date_short" tooltip_label_format="date_short" cursor=\{false\} \/>/)
  assert.ok(!dashboard.todos.some(todo => todo.reason.includes("AreaChart")))
  const filterTodos = dashboard.todos.filter(todo => todo.reason.includes("filteredData"))
  assert.equal(filterTodos.length, 1)
  assert.match(filterTodos[0].reason, /^`filteredData` is computed in React \([^)]*\); `@filtered_data` starts as all of `chart_data\(\)`\. Port the computation and reassign `@filtered_data` in mount\/3 and wherever @time_range changes\.$/)
  assert.match(dashboard.code, /\n\s+filtered_data: chart_data\(\),/)
  assert.match(dashboard.code, /<\.chart_area_interactive [^>]*filtered_data=\{@filtered_data\}/)
  assert.ok(dashboard.notes.some(note => note.message === 'chart_canvas kind="area" approximates AreaChart; no equivalent for: <AreaChart margin>.'))
  // A hidden X axis keeps no tick options.
  assert.match(dashboard.code, /data=\{data_table_chart_data\(\)\} series=\{\[%\{key: "mobile", fill_opacity: 0\.6\}, %\{key: "desktop", fill_opacity: 0\.4\}\]\} x_key="month" axes=\{false\} stack curve="natural" grid="horizontal" cursor=\{false\} \/>/)

  const fixture = convertFiles({
    "page.tsx": `import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { Bar, BarChart, XAxis } from "recharts"
import stats from "./stats.json"
const config = { visits: { label: "Visits", color: "var(--chart-1)" } }
export default function Page() {
  return (
    <ChartContainer config={config}>
      <BarChart data={stats.rows}>
        <XAxis dataKey="day" hide />
        <Bar dataKey="visits" />
      </BarChart>
    </ChartContainer>
  )
}`,
    "stats.json": `{"rows": [{"day": "Mon", "visits": 3}]}`,
  })
  assert.equal(fixture.todos.length, 0)
  assert.match(fixture.code, /<\.chart_canvas id="[\w-]+" context=\{chart\} kind="bar" data=\{stats\(\)\.rows\} series=\{\["visits"\]\} x_key="day" axes=\{false\} tooltip=\{false\} \/>/)
  assert.ok(!fixture.skipped.some(part => part.message.includes("recharts")), "converted recharts imports are not reported")
})

test("Recharts props map onto chart_canvas attrs; props without one stay in the note", () => {
  const chart = (body: string, data = "rows") => convertFiles({
    "page.tsx": `import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { Area, AreaChart, CartesianGrid, Line, LineChart, XAxis, YAxis } from "recharts"
const rows = [{ day: "2024-04-01", a: 1, b: 2 }]
const config = { a: { label: "A", color: "var(--chart-1)" }, b: { label: "B", color: "var(--chart-2)" } }
export default function Page() {
  return <ChartContainer config={config}>${body.replace("DATA", data)}</ChartContainer>
}`,
  })
  const canvas = (result: ConvertResult) => result.code.match(/<\.chart_canvas [^\n]*\/>/)?.[0] ?? ""
  const note = (result: ConvertResult) => result.notes.find(entry => entry.message.startsWith("chart_canvas"))?.message ?? ""

  // Different stackIds stay per series; a non-vertical gradient with other stops is still a gradient, noted.
  const stacks = chart(`<AreaChart data={DATA}>
  <defs><linearGradient id="fa" x1="0" y1="0" x2="1" y2="0"><stop offset="0%" stopColor="var(--color-a)" stopOpacity={0.5} /><stop offset="100%" stopColor="var(--color-a)" stopOpacity={0} /></linearGradient></defs>
  <CartesianGrid />
  <XAxis dataKey="day" tickFormatter={(value) => new Date(value).toLocaleDateString("en-US", { month: "short", day: "numeric" })} interval={0} />
  <ChartTooltip cursor={false} content={<ChartTooltipContent hideLabel labelFormatter={(value) => { const date = new Date(value); return date.toLocaleDateString(undefined, { month: "short", day: "numeric" }) }} />} />
  <Area dataKey="a" type="basis" stackId="x" fill="url(#fa)" />
  <Area dataKey="b" type="step" stackId="y" fillOpacity={0.3} strokeWidth={2} />
</AreaChart>`)
  assert.equal(stacks.todos.length, 0, stacks.todos.map(todo => todo.reason).join("\n"))
  assert.equal(canvas(stacks), '<.chart_canvas id="page-chart-canvas" context={chart} kind="area" data={rows()} series={[%{key: "a", stack: "x", gradient_opacity: [0.5, 0.0]}, %{key: "b", stack: "y", fill_opacity: 0.3}]} x_key="day" curve="step" fill="gradient" grid="both" tick_format="date_short" tooltip_label_format="date_short" cursor={false} />')
  for (const dropped of ['<Area type="basis">', '<linearGradient id="fa"> direction', '<linearGradient id="fa"> stop offsets', "<XAxis interval>", "<ChartTooltipContent hideLabel>", "<Area strokeWidth>", "solid <Area fill> beside gradient series"]) {
    assert.ok(note(stacks).includes(dropped), `${dropped} missing from: ${note(stacks)}`)
  }

  // Unconvertible formatters and line stacks are noted; grid and YAxis variants.
  const lines = chart(`<LineChart data={DATA}>
  <CartesianGrid horizontal={false} strokeDasharray="3 3" />
  <YAxis />
  <XAxis dataKey="day" tickFormatter={(value) => format(value, "PP")} />
  <ChartTooltip />
  <Line dataKey="a" type="monotoneX" stackId="s" stroke="var(--color-a)" />
</LineChart>`)
  assert.equal(canvas(lines), '<.chart_canvas id="page-chart-canvas" context={chart} kind="line" data={rows()} series={["a"]} x_key="day" curve="monotone" grid="vertical" />')
  for (const dropped of ["<CartesianGrid strokeDasharray>", "<YAxis>", "<XAxis tickFormatter>", "<Line stackId>"]) assert.ok(note(lines).includes(dropped), `${dropped} missing from: ${note(lines)}`)

  // Rows computed from a constant without state inputs: assign seeded from the rows, TODO for the computation only.
  const computed = chart(`<AreaChart data={DATA}><XAxis dataKey="day" hide /><Area dataKey="a" /></AreaChart>`, "rows.filter((row) => { return row.a > 0 })")
  assert.match(canvas(computed), /data=\{@page_chart_data\} series=\{\["a"\]\} x_key="day" axes=\{false\} tooltip=\{false\} \/>/)
  assert.match(computed.code, /page_chart_data: rows\(\)/)
  assert.deepEqual(computed.todos.map(todo => todo.reason), ["`rows.filter((row) => { return row.a > 0 })` is computed in React (callback with a block body); `@page_chart_data` starts as all of `rows()`. Port the computation and reassign `@page_chart_data` in mount/3."])
})

test("sidebar menu tooltips become a title shown only while the sidebar is collapsed", () => {
  const result = convert("vendor/shadcn/blocks/sidebar-07")
  assert.match(result.code, /<\.sidebar_menu_button title=\{if\(@sidebar\.open, do: nil, else: item\.title\)\}/)
  assert.ok(result.notes.some(note => /set only while the sidebar is collapsed/.test(note.message)))
})

test("data functions: one key set per list, named after the binding/file, never padded with other lists' keys", () => {
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.match(dashboard.code, /defp data do\n\s+\[\n\s+%\{\n\s+id: 1,\n\s+header: "Cover page",\n\s+type: "Cover page",\n\s+status: "In Process",\n\s+target: "18",\n\s+limit: "5",\n\s+reviewer: "Eddie Lake"\n\s+\},/)
  assert.match(dashboard.code, /defp sidebar_data do\n\s+%\{\n\s+user: %\{name: "shadcn", email: "m@example\.com", avatar: "\/avatars\/shadcn\.jpg"\},\n\s+nav_main: \[\n\s+%\{title: "Dashboard", url: "#", icon: "layout-dashboard"\},/)
  assert.match(dashboard.code, /<\.chart_canvas [^>]*data=\{data_table_chart_data\(\)\}/, "a taken name is qualified by its file")
  assert.doesNotMatch(dashboard.code, /\b\w+_data_data\b|defp data_data\b|nav_main: nil|header: nil/)

  const fixture = convertFiles({
    "page.tsx": `const links = [{ title: "A", url: "#" }, { title: "B", url: "#" }]
const people = [{ name: "Ann" }]
export default function Page() {
  return (
    <div>
      <ul>{links.map((link) => <li key={link.title}><a href={link.url}>{link.title}</a>{link.badge}</li>)}</ul>
      <ul>{people.map((person) => <li key={person.name}>{person.name}</li>)}</ul>
    </div>
  )
}`,
  })
  assert.match(fixture.code, /defp links do\n\s+\[%\{title: "A", url: "#", badge: nil\}, %\{title: "B", url: "#", badge: nil\}\]/, "a key read on a list's rows that no row has")
  assert.match(fixture.code, /defp people do\n\s+\[%\{name: "Ann"\}\]/)

  const rows: Term = { t: "list", items: [{ t: "map", entries: [["a", { t: "raw", code: "1" }]] }] }
  const other: Term = { t: "list", items: [{ t: "map", entries: [["b", { t: "raw", code: "2" }]] }] }
  const listKeys = new Map([[rows, new Set(["c"])]])
  assert.deepEqual(normalizeMaps({ t: "map", entries: [["rows", rows], ["other", other]] }, new Set(), listKeys), {
    t: "map",
    entries: [
      ["rows", { t: "list", items: [{ t: "map", entries: [["a", { t: "raw", code: "1" }], ["c", { t: "raw", code: "nil" }]] }] }],
      ["other", { t: "list", items: [{ t: "map", entries: [["b", { t: "raw", code: "2" }]] }] }],
    ],
  })
})

test("literal chart rows are always emitted as data functions: seeding computed rows or named by the TODO", () => {
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  const rows = dashboard.code.match(/\n {2}defp chart_data do\n {4}\[\n([\s\S]*?)\n {4}\]\n {2}end/)?.[1] ?? ""
  assert.equal(rows.split("\n").length, 91)
  assert.match(rows, /^\s+%\{date: "2024-04-01", desktop: 222, mobile: 150\},/)

  const examples = convert("vendor/shadcn/examples/chart-example.tsx")
  assert.match(examples.code, /TODO\(shadcn-to-liveview\): chart_canvas draws [^\n]*<PieChart>; its source rows are in `pie_chart_data\(\)`/)
  assert.match(examples.code, /\n {2}def pie_chart_data do\n/)
})

test("Select: SelectTrigger id stays the trigger id (Label htmlFor), content placement and item classes map", () => {
  const result = convertFiles({
    "page.tsx": `import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
export default function Page() {
  return (
    <div>
      <Label htmlFor="rows-per-page">Rows</Label>
      <Select defaultValue="10">
        <SelectTrigger id="rows-per-page"><SelectValue placeholder="Pick" /></SelectTrigger>
        <SelectContent side="top" align="end" sideOffset={8} className="rounded-xl">
          <SelectItem value="10" className="rounded-lg">10</SelectItem>
        </SelectContent>
      </Select>
    </div>
  )
}`,
  })
  assert.match(result.code, /<\.label for="rows-per-page">Rows<\/\.label>/)
  assert.match(result.code, /<\.select id="[\w-]+" trigger_id="rows-per-page" [^\n]*side="top" align="end" side_offset=\{8\}/)
  assert.doesNotMatch(result.code, /<\.select id="rows-per-page"/)
  assert.match(result.code, /<:option id="[\w-]+-10" value="10" label="10" class="rounded-lg">/)
  assert.ok(result.notes.some(note => /SelectContent equivalent for `className="rounded-xl"`/.test(note.message)), "unmapped SelectContent props are listed, not silently dropped")

  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.match(dashboard.code, /<\.label for="view-selector" class="sr-only">View<\/\.label>\s*<\.select id="[\w-]+" trigger_id="view-selector"/)
})

test("single toggle group over a non-empty state ignores the deselect payload", () => {
  const result = convertFiles({
    "page.tsx": `import * as React from "react"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
export default function Page() {
  const [range, setRange] = React.useState("90d")
  const [view, setView] = React.useState("")
  return (
    <div>
      <ToggleGroup type="single" value={range} onValueChange={setRange}><ToggleGroupItem value="90d">90</ToggleGroupItem><ToggleGroupItem value="7d">7</ToggleGroupItem></ToggleGroup>
      <ToggleGroup type="single" value={view} onValueChange={setView}><ToggleGroupItem value="a">A</ToggleGroupItem></ToggleGroup>
    </div>
  )
}`,
  })
  assert.match(result.code, /def handle_event\("change_range", %\{"value" => ""\}, socket\),\n\s+do: \{:noreply, socket\}\n\n\s+def handle_event\("change_range", %\{"value" => value\}, socket\)/)
  assert.doesNotMatch(result.code, /"change_view", %\{"value" => ""\}/, "a state that starts empty may be emptied")
  assert.ok(result.notes.some(note => /clicking the pressed item sends/.test(note.message)))
  const dashboard = convert("vendor/shadcn/blocks/dashboard-01")
  assert.match(dashboard.code, /def handle_event\("change_time_range", %\{"value" => ""\}, socket\)/)
})

test("root-relative asset URLs are listed as required static files with their shadcn original", () => {
  const login = convert("vendor/shadcn/blocks/login-04")
  assert.deepEqual(login.assets, [{ path: "/placeholder.svg", url: "https://ui.shadcn.com/placeholder.svg" }])
  const report = markdownReport(login)
  assert.match(report, /- Static assets: [^\n]*add `placeholder\.svg` to `static_paths\/0`/)
  assert.match(report, /\n {2}- `\/placeholder\.svg` \(original: https:\/\/ui\.shadcn\.com\/placeholder\.svg\)/)
  assert.deepEqual(convert("vendor/shadcn/blocks/sidebar-07").assets.map(asset => asset.path), ["/avatars/shadcn.jpg"])

  const own = convertFiles({ "page.tsx": `export default function Page() {\n  return <img src="/logo.png" alt="Logo" />\n}` })
  assert.deepEqual(own.assets, [{ path: "/logo.png", url: undefined }])
  assert.doesNotMatch(markdownReport(convertFiles({ "page.tsx": `export default function Page() {\n  return <p>Hi</p>\n}` })), /Static assets/)
})
