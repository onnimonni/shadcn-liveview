---
name: shadcn-template-to-liveview
description: Convert a shadcn/ui template (block, page, example, registry item, v0 output; React/TSX) into a Phoenix LiveView that uses shadcn_liveview. Use when asked to "convert/port this shadcn block/template/example/v0 output to LiveView", to add a shadcn login/signup/sidebar/dashboard page to a Phoenix app, or when given a ui.shadcn.com/r/... registry URL.
---

# shadcn/ui template → LiveView

A deterministic converter ships with the library. It does the mechanical 80%: component and prop
mapping, icons, `asChild` links, loops/conditionals, sample data, sub-components, compound
families (dialog, sheet, dropdown menu, popover, tooltip, select, tabs, accordion, collapsible,
sidebar, toggle/radio groups) with stable ids, `:let` contexts and generated `handle_event/3`
clauses, `useState` → assigns, forms → `to_form`. Everything it cannot convert confidently becomes
a `<%!-- TODO(shadcn-to-liveview): ... --%>` comment plus a report row. Your job is the rest.

## Workflow

1. **Locate the source.** A block directory (`page.tsx` + `components/*.tsx`), a single `.tsx`
   page/example, a saved registry item `.json`, or a URL such as
   `https://ui.shadcn.com/r/styles/radix-nova/login-03.json`. `npx shadcn` is not needed.
2. **Run the converter** (node ≥ 18 or bun):
   ```sh
   node deps/shadcn_liveview/priv/shadcn-to-liveview.mjs <input> \
     --module MyAppWeb.LoginLive --out lib/my_app_web/live/login_live.ex --report tmp/login_live.md
   ```
   `deps/shadcn_liveview` is the Hex/git location. A path dependency is not copied into `deps/`;
   use its directory instead (`mix run --no-start -e 'IO.puts Mix.Project.deps_paths()[:shadcn_liveview]'`
   prints it).
   `--component` emits a function component module instead (events listed in the report);
   `--json` prints the machine-readable report; `--lucide <node_modules/lucide-react>` inlines
   Lucide icons that `icon/1` lacks (otherwise they become TODOs). Re-run instead of hand-editing
   whenever the source changes.
3. **Read the report**: mapping, TODOs with `file:line` and the usage-rules section to follow,
   the **Source completeness** table (parts that produced no output and no TODO: unrendered
   components, TanStack column/cell renderers, dropped handlers/render props, local functions,
   runtime libraries such as @tanstack, @dnd-kit, recharts), notes (automatic approximations),
   manual steps and a verification checklist. Generated `submit_*` handlers are placeholders and
   count as TODOs (`# TODO(shadcn-to-liveview): placeholder`). Clear every TODO **and** every
   completeness row.
4. **Resolve every TODO** with `deps/shadcn_liveview/usage-rules.md`, `usage-rules/components.md`
   (exact attrs/enums/events), `overlays.md`, `forms.md`, `data-tables.md`. Never invent attrs or
   icon names; never reintroduce React/Radix.
5. **State and events.** The converter keeps interactive state in a generated `@ui` map (id →
   open/value) with catch-all clauses, and React `useState` in named assigns. Replace `@ui`
   entries with domain assigns where the app cares; back forms with Ecto changesets; move sidebar
   state to `on_mount` when several LiveViews share it (overlays.md#sidebar); replace the sample
   data functions at the bottom of the module with real data (`import x from "./data.json"`
   already became a `defp x` data function). Row selection (`setTeam(team)`) travels as a key
   (id/name/… or index) looked up on the server, never as a map through JSON. `useIsMobile()` /
   `useSidebar().isMobile` became `@is_mobile`, kept current by a generated colocated `.Viewport`
   hook; for the right layout on first connect add
   `is_mobile: window.matchMedia("(max-width: 767px)").matches` to the LiveSocket `params`
   function (overlays.md#sidebar shows the params function).
6. **Route and compile:** add `live "/login", LoginLive`, run `mix format` and
   `mix compile --warnings-as-errors` (the raw output already compiles; keep it that way).
7. **Test:** a `Phoenix.LiveViewTest` that mounts the route (unknown icon names raise only at
   render) and drives each generated event (`render_click`, `render_change`, `render_submit`).
8. **Compare in a browser** (Playwright) at 1280px and 390px against the React original. A
   recipe that worked for a Codex run (dashboard-01, sidebar-07, login-04): a scratch directory
   outside your app with `react`, `react-dom` and the registry item's `dependencies`. Pin the
   major version whose API the source imports (dashboard-01 uses TanStack v9: `tableFeatures`,
   `useTable`, `FlexRender`; the shadcn data-table guide uses v8), an esbuild entry that imports
   the untouched page and aliases `@/registry/radix-nova/*` / `@/components/ui/*` to the shadcn
   sources, a single React copy (esbuild `alias` for `react`/`react-dom`), the providers the page
   assumes (`TooltipProvider`, `Toaster`), Tailwind scanning the source directory, and the same
   fonts/tokens as your app; serve it on another port and screenshot both pages with identical
   viewport, theme and reduced motion. Check the family items in the report checklist: dialogs
   open, close on Escape and return focus; menus select and close; tabs switch; sidebar collapses
   and its footer is reachable at 390×600; forms submit; no console errors connected or
   disconnected.
9. **Report** what was converted, the remaining TODOs you resolved or left (with reasons) and the
   checks you actually ran.

A report with zero TODOs means the markup converted; it does not mean behavior did. Read every
generated `handle_event/3` and every item in the report's source-completeness list (callbacks,
column/cell renderers, hooks) before calling a page done.

## Known gaps (convert by hand)

Combobox, calendar/date pickers, command palettes, menubar and dropdown submenus, Pie/Radar/
Radial charts, drag-and-drop (dnd-kit, including TanStack drag-handle columns),
`useEffect`/`useRef`/custom hooks, callback props between components, and arbitrary event
handlers (setter/toast handlers are converted). Sidebar menu tooltips become a native `title`
shown only while the desktop sidebar is collapsed.

Area/Bar/LineCharts convert to `chart_canvas` including stacking, curves, gradients, grid, axis
ticks and `date_short` formatters; unmapped props (margin, YAxis, strokeWidth, dot, radius) are
listed as notes. When React computes the rows (`filteredData`), the canvas is already bound to
`@filtered_data`; port only the computation (one TODO). Custom chart renderers go in
`chart_container`'s `<:custom :let={ctx}>` slot: anything sized 100% in the default slot
renders 0×0.

TanStack tables (`useReactTable` v8 / `useTable` v9 with literal `ColumnDef[]` or
`columnHelper` columns) convert to `ShadcnLiveview.DataTable`: `data_table` with one `:col`
per accessor/display column (cells keep their markup with `:let={row}`), a checkbox select
column becomes `selectable`, a DropdownMenu actions column becomes `<:row_actions>`, and the
pagination footer, `getAllColumns()` menu and `getColumn(x).getFilterValue()` input become
`data_table_pagination`, `data_table_view_options` and `data_table_search`. The state is a
`DataTable.new(...)` assign plus generated `handle_event/3` and `load_*/1` (in-memory rows, not
URL-backed). Still by hand: row menu actions (the `{:action, value, row_id, table}` branch),
loading rows from your context, URL state (`usage-rules/data-tables.md`), column groups,
custom `filterFn`/`sortingFn`, and anything the report lists.
