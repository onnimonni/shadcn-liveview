defmodule ShadcnLiveview.DataTable do
  @moduledoc """
  Server-side data table: sortable headers (`aria-sort`), text search and facet filters,
  pagination with a page-size select, row selection with per-page select-all, a column
  visibility menu, row action menus and focus after deleting a row. Hand-written (not
  generated) and composed from `table`, `checkbox`, `button`, `dropdown_menu`,
  `native_select` and `input`; it replaces TanStack Table's client-side state with a
  `ShadcnLiveview.DataTable.State` assign.

  Components: `data_table/1` (the grid), `data_table_search/1` (search form; facet inputs go
  inside it), `data_table_view_options/1` (column visibility menu) and
  `data_table_pagination/1`. Pure functions: `new/1`, `from_params/2`, `to_params/1`,
  `apply/2` (in-memory lists), `put_total/2` + `offset/1` + `order_by/1` + `put_rows/2`
  (database queries), `handle_event/2` and `remove_row/2`.

      def mount(_params, _session, socket) do
        table = DataTable.new(id: "tasks", sortable: ~w(title status), filterable: ~w(status))
        {:ok, assign(socket, table: table, rows: [])}
      end

      def handle_params(params, _uri, socket) do
        table = DataTable.from_params(params, socket.assigns.table)
        {rows, table} = DataTable.apply(table, MyApp.Tasks.list())
        {:noreply, assign(socket, table: table, rows: rows)}
      end

      def handle_event("shadcn:data-table", params, socket) do
        case DataTable.handle_event(params, socket.assigns.table) do
          {:query, table, opts} -> {:noreply, push_patch(socket, [to: ~p"/tasks?\#{DataTable.to_params(table)}"] ++ opts)}
          {:ok, table} -> {:noreply, assign(socket, :table, table)}
          {:action, "delete", id, table} -> {:noreply, delete(socket, id, table)}
          {:action, _action, _id, table} -> {:noreply, assign(socket, :table, table)}
        end
      end

  ```heex
  <.data_table_search state={@table} placeholder="Filter tasks..." />
  <div class="overflow-hidden rounded-lg border">
    <.data_table state={@table} rows={@rows} selectable row_label="title">
      <:col :let={task} field="title" label="Title">{task.title}</:col>
      <:col field="status" label="Status" />
      <:row_actions>
        <.dropdown_menu_item value="edit">Edit</.dropdown_menu_item>
        <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
      </:row_actions>
    </.data_table>
  </div>
  <.data_table_pagination state={@table} selectable />
  ```

  Every control pushes `state.event` (default `"shadcn:data-table"`; give each table on a
  page its own `event:`) to the nearest `target` (`@myself` inside a LiveComponent).
  `handle_event/2` returns `{:query, state, opts}` when sort, search, facets, page or page
  size changed (`opts` is `[replace: true]` for search keystrokes; push_patch with them, or
  re-run `apply/2` when the state is not URL-backed), `{:ok, state}` for selection,
  visibility and menu changes, and `{:action, value, row_id, state}` when a row menu item is
  chosen. Payloads it understands: `%{"sort" => field}`, `%{"page" => page}`,
  `%{"page_size" => size}`, `%{"q" => text}` plus facet fields, checkbox
  `%{"id" => id, "value" => checked}` and menu `%{"id" => id, "action" => action, "value" => value}`.

  Row ids are strings (`to_string/1` of the `row_key` field). After deleting a row call
  `remove_row/2`, then reload the rows: the next render focuses the row action trigger
  (or checkbox) of the row now in its place, the previous row, or the table root.
  """
  use Phoenix.Component
  import Kernel, except: [apply: 2]
  import ShadcnLiveview.Helpers, only: [classes: 1]
  import ShadcnLiveview.Components.Button, only: [button: 1]
  import ShadcnLiveview.Components.Checkbox, only: [checkbox: 1]
  import ShadcnLiveview.Components.DropdownMenu
  import ShadcnLiveview.Components.Icon, only: [icon: 1]
  import ShadcnLiveview.Components.Input, only: [input: 1]
  import ShadcnLiveview.Components.Label, only: [label: 1]
  import ShadcnLiveview.Components.NativeSelect
  import ShadcnLiveview.Components.Table
  alias Phoenix.LiveView.JS
  alias ShadcnLiveview.DataTable.State

  @new_options [
    id: "data-table",
    event: "shadcn:data-table",
    sort: nil,
    dir: :asc,
    filter: "",
    filters: %{},
    page_size: 10,
    page_sizes: [10, 20, 30, 40, 50],
    sortable: [],
    filterable: [],
    searchable: nil,
    hidden: [],
    row_key: :id,
    param_prefix: ""
  ]

  @doc """
  Builds the table state. Options: `:id`, `:event`, `:sortable`, `:filterable`,
  `:searchable`, `:sort`, `:dir`, `:filter`, `:filters`, `:page_size`, `:page_sizes`,
  `:hidden`, `:row_key` (default `:id`) and `:param_prefix` (URL key prefix when several
  tables share a page). The initial query values are also the defaults that
  `from_params/2` falls back to and `to_params/1` omits. Fields may be atoms or strings.
  """
  def new(opts \\ []) do
    opts = Keyword.validate!(opts, @new_options)
    sortable = fields(opts[:sortable])
    filterable = fields(opts[:filterable])
    sort = opts[:sort] && to_string(opts[:sort])
    page_size = opts[:page_size]

    filters =
      Map.new(opts[:filters], fn {field, value} -> {to_string(field), to_string(value)} end)

    unless is_nil(sort) or sort in sortable,
      do: raise(ArgumentError, "DataTable.new/1: sort #{inspect(sort)} is not in :sortable")

    unless opts[:dir] in [:asc, :desc],
      do: raise(ArgumentError, "DataTable.new/1: dir must be :asc or :desc")

    unless is_integer(page_size) and page_size > 0,
      do: raise(ArgumentError, "DataTable.new/1: page_size must be a positive integer")

    %State{
      id: opts[:id],
      event: opts[:event],
      sort: sort,
      dir: opts[:dir],
      filter: opts[:filter],
      filters: filters,
      page_size: page_size,
      page_sizes: Enum.sort(Enum.uniq([page_size | opts[:page_sizes]])),
      sortable: sortable,
      filterable: filterable,
      searchable: opts[:searchable] && fields(opts[:searchable]),
      hidden: MapSet.new(fields(opts[:hidden])),
      row_key: to_string(opts[:row_key]),
      param_prefix: opts[:param_prefix],
      defaults: %{
        sort: sort,
        dir: opts[:dir],
        filter: opts[:filter],
        filters: filters,
        page_size: page_size
      }
    }
  end

  @doc """
  Reads the query state from URL params (`q`, `sort`, `dir`, `page`, `page_size` and one key
  per `:filterable` field, each prefixed with `:param_prefix`). Missing or invalid values fall
  back to the defaults given to `new/1`; selection, hidden columns and open menus are kept.
  """
  def from_params(params, %State{} = state) when is_map(params) do
    defaults = state.defaults
    param = &Map.get(params, state.param_prefix <> &1)

    sort =
      case param.("sort") do
        "" -> nil
        field when is_binary(field) -> if field in state.sortable, do: field, else: defaults.sort
        _ -> defaults.sort
      end

    filters =
      facets(state, fn field -> param.(field) || Map.get(defaults.filters, field) end)

    %{
      state
      | sort: sort,
        dir: parse_dir(param.("dir"), defaults.dir),
        filter: if(is_binary(param.("q")), do: param.("q"), else: defaults.filter),
        filters: filters,
        page: positive_integer(param.("page")) || 1,
        page_size: page_size(param.("page_size"), state) || defaults.page_size
    }
  end

  @doc """
  URL params for the query state, omitting values equal to the defaults, so
  `~p"/tasks?\#{DataTable.to_params(table)}"` round-trips through `from_params/2`.
  """
  def to_params(%State{} = state) do
    defaults = state.defaults

    facets =
      for field <- state.filterable,
          Map.get(state.filters, field) != Map.get(defaults.filters, field),
          do: {field, Map.get(state.filters, field, "")}

    [
      {"q", state.filter, defaults.filter},
      {"sort", state.sort || "", defaults.sort || ""},
      {"dir", state.sort && state.dir, state.sort && defaults.dir},
      {"page", state.page, 1},
      {"page_size", state.page_size, defaults.page_size}
    ]
    |> Enum.reject(fn {_key, value, default} -> value == default end)
    |> Enum.map(fn {key, value, _default} -> {key, to_string(value)} end)
    |> Kernel.++(facets)
    |> Map.new(fn {key, value} -> {state.param_prefix <> key, value} end)
  end

  @doc """
  Filters, sorts and paginates an in-memory list. Returns `{page_rows, state}` with `total`,
  a page clamped to the last page, and the page's row ids. Database-backed tables apply the
  same state in their query instead (`put_total/2`, `offset/1`, `order_by/1`, `put_rows/2`).
  """
  def apply(%State{} = state, rows) when is_list(rows) do
    matching = rows |> Enum.filter(&matches?(&1, state)) |> sort_rows(state)
    state = put_total(state, length(matching))
    page_rows = Enum.slice(matching, offset(state), state.page_size)
    {page_rows, put_rows(state, page_rows)}
  end

  @doc "Records the number of matching rows and clamps the page to the last page."
  def put_total(%State{} = state, total) when is_integer(total) and total >= 0 do
    state = %{state | total: total}
    %{state | page: state.page |> min(page_count(state)) |> max(1)}
  end

  @doc "Records the current page's rows (their ids drive select-all and focus after delete)."
  def put_rows(%State{} = state, rows),
    do: %{state | page_ids: Enum.map(rows, &row_id(state, &1))}

  @doc "Rows to skip for the current page (`offset:` in an Ecto query)."
  def offset(%State{page: page, page_size: size}), do: (page - 1) * size

  @doc """
  Ecto `order_by` keyword for the current sort, e.g. `[desc: :title]` (`[]` when unsorted).
  The field is whitelisted by `:sortable`; it must exist as an atom (a schema field).
  """
  def order_by(%State{sort: nil}), do: []
  def order_by(%State{sort: sort, dir: dir}), do: [{dir, String.to_existing_atom(sort)}]

  @doc "Number of pages for the current total (at least 1)."
  def page_count(%State{total: total, page_size: size}), do: max(1, div(total + size - 1, size))

  @doc "A row's id as a string, read from the `row_key` field."
  def row_id(%State{row_key: key}, row), do: to_string(value(row, key))

  @doc "Reads `field` (string or atom) from a map or struct row with string or atom keys."
  def value(row, field) when is_map(row) and is_atom(field), do: Map.get(row, field)

  def value(row, field) when is_map(row) and is_binary(field) do
    case Map.fetch(row, field) do
      {:ok, value} -> value
      :error -> Map.get(row, existing_atom(field))
    end
  end

  @doc """
  Applies a table event. Returns `{:query, state, opts}`, `{:ok, state}` or
  `{:action, value, row_id, state}` (see the module docs); unknown payloads return
  `{:ok, state}` unchanged.
  """
  def handle_event(%{"sort" => field}, %State{} = state) when is_binary(field) do
    if field in state.sortable,
      do: {:query, %{next_sort(state, field) | page: 1}, []},
      else: {:ok, state}
  end

  def handle_event(%{"page" => page}, %State{} = state) do
    case positive_integer(page) do
      nil -> {:ok, state}
      page -> {:query, %{state | page: min(page, page_count(state))}, []}
    end
  end

  def handle_event(%{"page_size" => size}, %State{} = state) do
    case page_size(size, state) do
      nil -> {:ok, state}
      size -> {:query, %{state | page_size: size, page: 1}, []}
    end
  end

  def handle_event(%{"q" => filter} = params, %State{} = state) when is_binary(filter) do
    filters =
      facets(state, &params[&1])

    {:query, %{state | filter: filter, filters: filters, page: 1}, [replace: true]}
  end

  def handle_event(%{"id" => menu, "action" => action} = params, %State{} = state) do
    columns = state.id <> "-columns"

    case {menu, action, row_part(menu, state, "-actions")} do
      {_menu, "open", row} when menu == columns or row != nil ->
        {:ok, %{state | open: menu}}

      {_menu, "close", _row} when state.open == menu ->
        {:ok, %{state | open: nil}}

      {^columns, "select", nil} ->
        {:ok, toggle_hidden(state, params["value"], params["checked"])}

      {_menu, "select", row} when row != nil ->
        {:action, params["value"], row, %{state | open: nil}}

      _other ->
        {:ok, state}
    end
  end

  def handle_event(%{"id" => id, "value" => checked}, %State{} = state)
      when is_boolean(checked) do
    cond do
      id == state.id <> "-select-all" ->
        page = MapSet.new(state.page_ids)

        selected =
          if checked,
            do: MapSet.union(state.selected, page),
            else: MapSet.difference(state.selected, page)

        {:ok, %{state | selected: selected}}

      row = row_part(id, state, "-select") ->
        selected =
          if checked,
            do: MapSet.put(state.selected, row),
            else: MapSet.delete(state.selected, row)

        {:ok, %{state | selected: selected}}

      true ->
        {:ok, state}
    end
  end

  def handle_event(_params, %State{} = state), do: {:ok, state}

  @doc """
  Forgets a deleted row (selection, page ids, open menu) and schedules focus for the next
  render: the row action trigger (or select checkbox) of the row now at its position, else
  the new last row (also when the page emptied and moved back), else the table root.
  Reload or `apply/2` the rows afterwards.
  """
  def remove_row(%State{} = state, row_id) do
    id = to_string(row_id)
    index = Enum.find_index(state.page_ids, &(&1 == id)) || 0
    seq = if state.focus, do: state.focus.seq + 1, else: 1

    %{
      state
      | selected: MapSet.delete(state.selected, id),
        page_ids: List.delete(state.page_ids, id),
        open: nil,
        focus: %{index: index, page: state.page, seq: seq}
    }
  end

  @doc """
  Server-side data table over the current page's `rows` (a list, or a stream such as
  `@streams.tasks` whose rows you `stream_insert` again when their selection changes).

  Each `:col` renders `field` with `value/2`, or its own content with `:let={row}`; a column
  is sortable when its field is in the state's `:sortable` list and hidden when it is in
  `state.hidden`. `selectable` adds the checkbox column (select-all covers the current page and
  shows the indeterminate state). `:row_actions` content (dropdown_menu items) fills each row's
  action menu; choosing an item pushes `%{"id" => menu_id, "action" => "select", "value" => value}`.
  `row_label` (field name or function) names rows in checkbox and menu labels (default: row id).
  """
  attr :state, State, required: true
  attr :rows, :any, required: true, doc: "current page rows: a list or a LiveView stream"
  attr :selectable, :boolean, default: false
  attr :row_label, :any, default: nil, doc: "field name or `fn row -> label end`"
  attr :target, :any, default: nil, doc: "phx-target for every control, e.g. `@myself`"
  attr :header_class, :any, default: nil
  attr :empty_text, :string, default: "No results."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :col, required: true do
    attr :field, :string, required: true
    attr :label, :string
    attr :class, :any
    attr :head_class, :any
  end

  slot :row_actions do
    attr :class, :any
    attr :label, :string
  end

  slot :empty

  def data_table(assigns) do
    state = assigns.state
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)
    cols = Enum.reject(assigns.col, &(&1.field in state.hidden))

    assigns =
      assign(assigns,
        stream?: stream?,
        cols: cols,
        entries:
          if(stream?,
            do: assigns.rows,
            else: Enum.map(assigns.rows, &{row_dom_id(state, &1), &1})
          ),
        empty?: if(stream?, do: state.total == 0, else: assigns.rows == []),
        colspan: length(cols) + Enum.count([assigns.selectable, assigns.row_actions != []], & &1),
        page_selection: page_selection(state),
        focus: focus_target(state, assigns.row_actions != [], assigns.selectable)
      )

    ~H"""
    <div
      id={@state.id}
      tabindex="-1"
      phx-target={@target}
      data-slot="data-table"
      class={classes(["outline-none", @class])}
      {@rest}
    >
      <.table>
        <.table_header class={@header_class}>
          <.table_row>
            <.table_head :if={@selectable} scope="col" class="w-8">
              <div class="flex items-center justify-center">
                <.checkbox
                  id={@state.id <> "-select-all"}
                  checked={@page_selection}
                  disabled={@state.page_ids == []}
                  on_change={@state.event}
                  aria-label="Select all"
                />
              </div>
            </.table_head>
            <.table_head
              :for={col <- @cols}
              scope="col"
              class={col[:head_class]}
              aria-sort={aria_sort(@state, col.field)}
            >
              <.button
                :if={col.field in @state.sortable}
                type="button"
                variant="ghost"
                size="sm"
                class="-ml-2.5 h-8"
                phx-click={@state.event}
                phx-value-sort={col.field}
                phx-target={@target}
              >
                {col[:label]}<.icon name={sort_icon(@state, col.field)} aria-hidden="true" />
              </.button>
              <span :if={col.field not in @state.sortable}>{col[:label]}</span>
            </.table_head>
            <.table_head :if={@row_actions != []} scope="col" class="w-8">
              <span class="sr-only">Actions</span>
            </.table_head>
          </.table_row>
        </.table_header>
        <.table_body id={@state.id <> "-rows"} phx-update={@stream? && "stream"}>
          <.table_row
            :for={{dom_id, row} <- @entries}
            id={dom_id}
            data-state={MapSet.member?(@state.selected, row_id(@state, row)) && "selected"}
          >
            <.table_cell :if={@selectable} class="w-8">
              <div class="flex items-center justify-center">
                <.checkbox
                  id={row_dom_id(@state, row) <> "-select"}
                  checked={MapSet.member?(@state.selected, row_id(@state, row))}
                  on_change={@state.event}
                  aria-label={"Select #{row_label(@row_label, @state, row)}"}
                />
              </div>
            </.table_cell>
            <.table_cell :for={col <- @cols} class={col[:class]}>
              <%= if col.inner_block do %>
                {render_slot(col, row)}
              <% else %>
                {value(row, col.field)}
              <% end %>
            </.table_cell>
            <.table_cell :if={@row_actions != []} class="w-8">
              <.dropdown_menu
                id={row_dom_id(@state, row) <> "-actions"}
                open={@state.open == row_dom_id(@state, row) <> "-actions"}
                align="end"
                on_change={@state.event}
                target={@target}
              >
                <:trigger :let={popup}>
                  <.button
                    variant="ghost"
                    size="icon"
                    class="flex size-8 text-muted-foreground data-[state=open]:bg-muted"
                    aria-label={"#{actions_label(@row_actions)} #{row_label(@row_label, @state, row)}"}
                    {popup.trigger}
                  >
                    <.icon name="ellipsis-vertical" aria-hidden="true" />
                  </.button>
                </:trigger>
                <:content :let={popup}>
                  <.dropdown_menu_content
                    context={popup}
                    class={Enum.map(@row_actions, & &1[:class])}
                  >
                    {render_slot(@row_actions, row)}
                  </.dropdown_menu_content>
                </:content>
              </.dropdown_menu>
            </.table_cell>
          </.table_row>
          <.table_row
            :if={@empty?}
            id={@state.id <> "-empty"}
            class={@stream? && "hidden only:table-row"}
          >
            <.table_cell colspan={@colspan} class="h-24 text-center">
              <%= if @empty != [] do %>
                {render_slot(@empty)}
              <% else %>
                {@empty_text}
              <% end %>
            </.table_cell>
          </.table_row>
        </.table_body>
      </.table>
      <span
        :if={@focus}
        id={"#{@state.id}-focus-#{elem(@focus, 1)}"}
        phx-mounted={JS.focus(to: ~s([id="#{elem(@focus, 0)}"]))}
        hidden
      ></span>
    </div>
    """
  end

  @doc """
  Search form for the table's text filter: a debounced `q` input pushing
  `%{"q" => text}` (plus any facet inputs you put inside, named after `:filterable` fields).
  Handle it with `handle_event/2`; push_patch the `{:query, state, [replace: true]}` result.
  """
  attr :state, State, required: true
  attr :target, :any, default: nil
  attr :placeholder, :string, default: "Search..."
  attr :label, :string, default: "Search"
  attr :debounce, :string, default: "300"
  attr :class, :any, default: nil
  attr :input_class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def data_table_search(assigns) do
    ~H"""
    <form
      id={@state.id <> "-search"}
      role="search"
      phx-change={@state.event}
      phx-submit={@state.event}
      phx-target={@target}
      data-slot="data-table-search"
      class={classes(["flex items-center gap-2", @class])}
      {@rest}
    >
      <.input
        type="search"
        id={@state.id <> "-q"}
        name="q"
        value={@state.filter}
        placeholder={@placeholder}
        aria-label={@label}
        autocomplete="off"
        phx-debounce={@debounce}
        class={classes(["h-8 w-[150px] lg:w-[250px]", @input_class])}
      />
      {render_slot(@inner_block)}
    </form>
    """
  end

  @doc """
  Column visibility menu: one checkbox item per entry of `columns` (fields, or
  `{field, label}` tuples). Toggling pushes the menu payload with `"checked"`;
  `handle_event/2` updates `state.hidden`.
  """
  attr :state, State, required: true
  attr :columns, :list, required: true
  attr :target, :any, default: nil
  attr :label, :string, default: "Columns"
  attr :align, :string, default: "end", values: ~w(start center end)
  attr :class, :any, default: nil
  attr :content_class, :any, default: nil

  def data_table_view_options(assigns) do
    assigns =
      assign(assigns,
        menu_id: assigns.state.id <> "-columns",
        columns:
          Enum.map(assigns.columns, fn
            {field, label} -> {to_string(field), label}
            field -> {to_string(field), to_string(field)}
          end)
      )

    ~H"""
    <.dropdown_menu
      id={@menu_id}
      open={@state.open == @menu_id}
      align={@align}
      on_change={@state.event}
      target={@target}
    >
      <:trigger :let={popup}>
        <.button variant="outline" size="sm" class={@class} {popup.trigger}>
          <.icon name="columns-3" data-icon="inline-start" aria-hidden="true" />{@label}<.icon
            name="chevron-down"
            data-icon="inline-end"
            aria-hidden="true"
          />
        </.button>
      </:trigger>
      <:content :let={popup}>
        <.dropdown_menu_content context={popup} class={classes(["w-32", @content_class])}>
          <.dropdown_menu_checkbox_item
            :for={{field, label} <- @columns}
            value={field}
            checked={field not in @state.hidden}
            class="capitalize"
          >
            {label}
          </.dropdown_menu_checkbox_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  @doc """
  Pagination footer: selected-row count (with `selectable`), rows-per-page select
  (`state.page_sizes`), "Page x of y" and first/previous/next/last buttons that are
  disabled at the boundaries. Buttons push `%{"page" => page}`, the select `%{"page_size" => size}`.
  """
  attr :state, State, required: true
  attr :target, :any, default: nil
  attr :selectable, :boolean, default: false
  attr :page_size_label, :string, default: "Rows per page"
  attr :class, :any, default: nil
  attr :rest, :global

  def data_table_pagination(assigns) do
    assigns = assign(assigns, :page_count, page_count(assigns.state))

    ~H"""
    <div
      id={@state.id <> "-pagination"}
      data-slot="data-table-pagination"
      class={classes(["flex items-center justify-between", @class])}
      {@rest}
    >
      <div
        id={@state.id <> "-selection"}
        class="hidden flex-1 text-sm text-muted-foreground lg:flex"
        aria-live="polite"
      >
        <span :if={@selectable}>
          {MapSet.size(@state.selected)} of {@state.total} row(s) selected.
        </span>
      </div>
      <div class="flex w-full items-center gap-8 lg:w-fit">
        <form
          id={@state.id <> "-page-size-form"}
          class="hidden items-center gap-2 lg:flex"
          phx-change={@state.event}
          phx-target={@target}
        >
          <.label for={@state.id <> "-page-size"} class="text-sm font-medium">
            {@page_size_label}
          </.label>
          <.native_select
            id={@state.id <> "-page-size"}
            name="page_size"
            size="sm"
            value={@state.page_size}
            class="w-20"
          >
            <.native_select_option
              :for={size <- @state.page_sizes}
              value={size}
              selected={size == @state.page_size}
            >
              {size}
            </.native_select_option>
          </.native_select>
        </form>
        <div
          id={@state.id <> "-page"}
          class="flex w-fit items-center justify-center text-sm font-medium"
        >
          Page {@state.page} of {@page_count}
        </div>
        <div class="ml-auto flex items-center gap-2 lg:ml-0">
          <.button
            :for={
              {page, icon, label, class, disabled} <- [
                {1, "chevrons-left", "Go to first page", "hidden lg:flex", @state.page <= 1},
                {@state.page - 1, "chevron-left", "Go to previous page", nil, @state.page <= 1},
                {@state.page + 1, "chevron-right", "Go to next page", nil,
                 @state.page >= @page_count},
                {@page_count, "chevrons-right", "Go to last page", "hidden lg:flex",
                 @state.page >= @page_count}
              ]
            }
            type="button"
            variant="outline"
            size="icon"
            class={["size-8", class]}
            disabled={disabled}
            phx-click={@state.event}
            phx-value-page={page}
            phx-target={@target}
            aria-label={label}
          >
            <.icon name={icon} aria-hidden="true" />
          </.button>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------- helpers

  defp fields(list), do: Enum.map(list, &to_string/1)

  # Non-empty facet values of the `:filterable` fields.
  defp facets(%State{filterable: filterable}, fetch) do
    filterable
    |> Enum.map(&{&1, fetch.(&1)})
    |> Enum.filter(fn {_field, value} -> is_binary(value) and value != "" end)
    |> Map.new()
  end

  defp existing_atom(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> nil
  end

  defp parse_dir("asc", _default), do: :asc
  defp parse_dir("desc", _default), do: :desc
  defp parse_dir(_other, default), do: default

  defp positive_integer(value) when is_integer(value) and value > 0, do: value

  defp positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp positive_integer(_value), do: nil

  defp page_size(value, state) do
    size = positive_integer(value)
    if size in state.page_sizes, do: size
  end

  defp next_sort(%State{sort: field, dir: :asc} = state, field), do: %{state | dir: :desc}
  defp next_sort(%State{sort: field} = state, field), do: %{state | sort: nil, dir: :asc}
  defp next_sort(state, field), do: %{state | sort: field, dir: :asc}

  defp toggle_hidden(state, field, checked) when is_binary(field) and is_boolean(checked) do
    hidden =
      if checked,
        do: MapSet.delete(state.hidden, field),
        else: MapSet.put(state.hidden, field)

    %{state | hidden: hidden}
  end

  defp toggle_hidden(state, _field, _checked), do: state

  # "<id>-row-<row id><suffix>" -> row id
  defp row_part(dom_id, %State{id: id}, suffix) when is_binary(dom_id) do
    prefix = id <> "-row-"

    with true <- String.starts_with?(dom_id, prefix) and String.ends_with?(dom_id, suffix),
         row when row != "" <-
           binary_part(
             dom_id,
             byte_size(prefix),
             byte_size(dom_id) - byte_size(prefix) - byte_size(suffix)
           ) do
      row
    else
      _ -> nil
    end
  end

  defp row_part(_dom_id, _state, _suffix), do: nil

  defp row_dom_id(state, row), do: "#{state.id}-row-#{row_id(state, row)}"

  defp row_label(nil, state, row), do: row_id(state, row)
  defp row_label(fun, _state, row) when is_function(fun, 1), do: fun.(row)
  defp row_label(field, _state, row), do: value(row, to_string(field))

  defp actions_label(row_actions),
    do: Enum.find_value(row_actions, "Open menu for", & &1[:label])

  defp page_selection(%State{page_ids: []}), do: false

  defp page_selection(%State{page_ids: ids, selected: selected}) do
    case Enum.count(ids, &MapSet.member?(selected, &1)) do
      0 -> false
      count when count == length(ids) -> true
      _some -> "indeterminate"
    end
  end

  defp aria_sort(%State{sortable: sortable, sort: sort, dir: dir}, field) do
    cond do
      field not in sortable -> nil
      field != sort -> "none"
      dir == :asc -> "ascending"
      true -> "descending"
    end
  end

  defp sort_icon(%State{sort: field, dir: :asc}, field), do: "arrow-up"
  defp sort_icon(%State{sort: field, dir: :desc}, field), do: "arrow-down"
  defp sort_icon(_state, _field), do: "chevrons-up-down"

  defp focus_target(%State{focus: nil}, _actions?, _selectable?), do: nil

  defp focus_target(%State{focus: focus} = state, actions?, selectable?) do
    %{index: index, page: page, seq: seq} = focus

    row =
      (state.page == page && Enum.at(state.page_ids, index)) || List.last(state.page_ids)

    prefix = "#{state.id}-row-#{row}"

    target =
      cond do
        is_nil(row) -> state.id
        actions? -> prefix <> "-actions-trigger"
        selectable? -> prefix <> "-select"
        true -> state.id
      end

    {target, seq}
  end

  defp matches?(row, state) do
    text_match?(row, state) and
      Enum.all?(state.filters, fn {field, wanted} -> to_string(value(row, field)) == wanted end)
  end

  defp text_match?(row, state) do
    case state.filter |> String.trim() |> String.downcase() do
      "" ->
        true

      needle ->
        row
        |> search_values(state)
        |> Enum.any?(&String.contains?(String.downcase(&1), needle))
    end
  end

  defp search_values(row, %State{searchable: nil}) do
    row
    |> plain_map()
    |> Map.values()
    |> Enum.flat_map(&text/1)
  end

  defp search_values(row, %State{searchable: fields}),
    do: Enum.flat_map(fields, &text(value(row, &1)))

  defp plain_map(%_{} = struct), do: Map.from_struct(struct)
  defp plain_map(map), do: map

  defp text(value) when is_binary(value), do: [value]
  defp text(value) when is_number(value), do: [to_string(value)]
  defp text(value) when is_atom(value) and value not in [nil, true, false], do: [to_string(value)]
  defp text(_value), do: []

  defp sort_rows(rows, %State{sort: nil}), do: rows

  defp sort_rows(rows, %State{sort: field, dir: dir}) do
    {present, missing} = Enum.split_with(rows, &(not is_nil(value(&1, field))))

    sorted =
      Enum.sort(present, fn a, b ->
        order = order(value(a, field), value(b, field))
        if dir == :asc, do: order != :gt, else: order != :lt
      end)

    sorted ++ missing
  end

  defp order(%module{} = a, %module{} = b) do
    if function_exported?(module, :compare, 2), do: module.compare(a, b), else: term_order(a, b)
  end

  defp order(a, b) when is_binary(a) and is_binary(b),
    do: term_order(String.downcase(a), String.downcase(b))

  defp order(a, b), do: term_order(a, b)

  defp term_order(a, b) when a < b, do: :lt
  defp term_order(a, b) when a > b, do: :gt
  defp term_order(_a, _b), do: :eq
end
