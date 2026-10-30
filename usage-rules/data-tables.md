# Data tables: search, filters, sorting, pagination, selection and row actions

Use `ShadcnLiveview.DataTable` (`data_table`, `data_table_search`, `data_table_view_options`,
`data_table_pagination`, imported by `use ShadcnLiveview`) instead of rebuilding TanStack Table
behaviour by hand. The server owns everything in a `ShadcnLiveview.DataTable.State` assign; the
`table` family stays available for markup-only tables.

## URL-backed table in a LiveView

```elixir
alias ShadcnLiveview.DataTable

def mount(_params, _session, socket) do
  table = DataTable.new(id: "tasks", sortable: ~w(title status), filterable: ~w(status), searchable: ~w(title))
  {:ok, assign(socket, table: table, tasks: [])}
end

# Query state (q, sort, dir, page, page_size, filterable fields) lives in the URL, so Back,
# reload and shared links restore it. Selection, hidden columns and open menus are kept.
def handle_params(params, _uri, socket) do
  table = DataTable.from_params(params, socket.assigns.table)
  {tasks, table} = DataTable.apply(table, Tasks.list_tasks())
  {:noreply, assign(socket, table: table, tasks: tasks)}
end

def handle_event("shadcn:data-table", params, socket) do
  case DataTable.handle_event(params, socket.assigns.table) do
    # opts is [replace: true] for search keystrokes, [] for sort/page/page size (Back steps through them)
    {:query, table, opts} -> {:noreply, push_patch(socket, [to: ~p"/tasks?#{DataTable.to_params(table)}"] ++ opts)}
    {:ok, table} -> {:noreply, assign(socket, :table, table)}
    {:action, "delete", id, table} -> {:noreply, delete_task(socket, id, table)}
    {:action, "edit", id, table} -> {:noreply, socket |> assign(:table, table) |> push_navigate(to: ~p"/tasks/#{id}/edit")}
  end
end

defp delete_task(socket, id, table) do
  Tasks.delete_task!(id)
  # remove_row/2 drops the id from the selection and focuses the next row's menu trigger.
  {tasks, table} = DataTable.apply(DataTable.remove_row(table, id), Tasks.list_tasks())
  assign(socket, table: table, tasks: tasks)
end
```

```heex
<div class="flex items-center justify-between gap-2">
  <.data_table_search state={@table} placeholder="Filter tasks...">
    <%!-- facet inputs go inside the search form, named after :filterable fields --%>
    <.native_select :let={selected} name="status" size="sm" value={@table.filters["status"] || ""} aria-label="Status">
      <.native_select_option value="" selected={"" in selected}>All</.native_select_option>
      <.native_select_option value="done" selected={"done" in selected}>Done</.native_select_option>
    </.native_select>
  </.data_table_search>
  <.data_table_view_options state={@table} columns={[{"status", "Status"}, {"due", "Due"}]} />
</div>
<div class="overflow-hidden rounded-lg border">
  <.data_table state={@table} rows={@tasks} selectable row_label="title">
    <:col :let={task} field="title" label="Title" class="font-medium">{task.title}</:col>
    <:col field="status" label="Status" />
    <:col :let={task} field="due" label="Due" head_class="text-right" class="text-right">{task.due}</:col>
    <:row_actions class="w-32">
      <.dropdown_menu_item value="edit">Edit</.dropdown_menu_item>
      <.dropdown_menu_separator />
      <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
    </:row_actions>
    <:empty>No tasks match. <.button variant="link" patch={~p"/tasks"}>Clear filters</.button></:empty>
  </.data_table>
</div>
<.data_table_pagination state={@table} selectable />
```

- `DataTable.new/1` options: `id` (DOM id prefix), `event` (default `"shadcn:data-table"`),
  `sortable`/`filterable` (whitelists; invalid URL values fall back to the defaults),
  `searchable` (fields the text search reads; default every scalar value), `sort`, `dir`,
  `page_size`, `page_sizes`, `hidden`, `row_key` (default `:id`), `param_prefix`.
- A column is sortable when its `field` is in `sortable`: the header becomes a ghost button that
  cycles ascending → descending → unsorted and the `<th>` carries `aria-sort`.
- `:col` without content renders `DataTable.value(row, field)` (string- or atom-keyed maps and
  structs). `class` styles cells, `head_class` the header cell.
- `handle_event/2` results: `{:query, table, opts}` (sort, search, facets, page, page size),
  `{:ok, table}` (selection, column visibility, menu open/close) and
  `{:action, value, row_id, table}` (row menu item; `value` falls back to the item text).
  Unknown payloads return `{:ok, table}` unchanged.
- LiveView keeps a focused input's typed value across patches: Back while the search box still
  has focus updates the rows but leaves the typed text until the input loses focus.

## Database-backed tables

`apply/2` is for in-memory lists. With Ecto apply the same state in the query:

```elixir
def load_tasks(socket) do
  table = socket.assigns.table
  query = Tasks.filtered_query(table.filter, table.filters)       # your WHERE clauses
  table = DataTable.put_total(table, Repo.aggregate(query, :count)) # clamps the page
  tasks = query |> order_by(^DataTable.order_by(table)) |> limit(^table.page_size) |> offset(^DataTable.offset(table)) |> Repo.all()
  assign(socket, table: DataTable.put_rows(table, tasks), tasks: tasks) # page ids drive select-all and focus
end
```

`order_by/1` turns the whitelisted sort field into an existing atom (`[desc: :title]`).

## Selection

- `table.selected` is a `MapSet` of row ids as strings (`to_string/1` of `row_key`). It survives
  paging, sorting and filtering; act on it for bulk actions and clear it yourself afterwards
  (`%{table | selected: MapSet.new()}`).
- The header checkbox selects or clears the current page only and shows `aria-checked="mixed"`
  when the page is partly selected. `data_table_pagination selectable` shows
  "N of TOTAL row(s) selected." (`total` = rows matching the filters).

## Row menus and focus after delete

- `<:row_actions>` content (dropdown_menu items) fills each row's menu; the trigger, its
  `aria-label` ("Open menu for <row_label>") and open state are built in. Menu ids are
  `"<table id>-row-<row id>-actions"`, trigger ids add `-trigger` (use it as `trigger_id` for a
  confirmation `alert_dialog` opened from the menu).
- After deleting a row call `DataTable.remove_row(table, id)` before reloading: the next render
  focuses the menu trigger (or select checkbox) of the row now at that position, the new last row
  when the page emptied, else the table root — never `<body>`.

## LiveComponents, several tables, streams

- Inside a LiveComponent pass `target={@myself}` to every data table component and handle the
  event in the component. URL state belongs to the parent LiveView; without it, re-run `apply/2`
  on `{:query, table, _opts}`.
- Several tables on one page need distinct `id`s and `event`s (and `param_prefix` when both
  are URL-backed).
- Plain list assigns are recommended: the server pages the rows anyway. `rows={@streams.tasks}`
  also works (the body gets `phx-update="stream"`), but streamed rows only re-render when you
  `stream_insert` them: re-insert the affected rows after selection or row-menu `{:ok, table}`
  results, reset the stream only when the query changes, and record the page with
  `put_total/2` + `put_rows/2`.

## Markup-only tables

For read-only tables use `table`, `table_header`, `table_row`, `table_head scope="col"` and
`table_cell` directly. Sort headers: `<.button variant="ghost" patch={...}>` inside `table_head`
with `aria-sort="ascending|descending|none"`; pagination with `pagination_link patch=...`.

## Tests

- LiveViewTest: `render_patch(view, ~p"/tasks?sort=title&dir=desc")` and assert rows;
  `view |> element("#tasks th button[phx-value-sort=title]") |> render_click()` then
  `assert_patch(view, ~p"/tasks?sort=title")`; `view |> form("#tasks-search", %{q: "x"}) |> render_change()`.
- Browser: sort and page, then Back; type in the search box and check that Back skips the
  keystrokes; select a row, change page, come back; toggle a column from the keyboard; open a row
  menu with the keyboard, delete, and assert focus on the next row's trigger.
