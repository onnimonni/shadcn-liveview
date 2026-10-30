defmodule ShadcnLiveview.Preview.DataTableLive do
  @moduledoc false
  # Connected harness for ShadcnLiveview.DataTable: a URL-backed table owned by this LiveView
  # and a second, non-URL table owned by a LiveComponent (events routed with phx-target).
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview
  alias ShadcnLiveview.DataTable

  @statuses ~w(todo in-progress done)

  def rows do
    for n <- 1..32 do
      %{
        id: n,
        title: "Task #{String.pad_leading(to_string(n), 2, "0")}",
        status: Enum.at(@statuses, rem(n, 3)),
        owner: Enum.at(~w(Ada Grace Linus Barbara), rem(n, 4)),
        points: rem(n * 7, 13)
      }
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    table =
      DataTable.new(
        id: "tasks",
        sortable: ~w(title status owner points),
        filterable: ~w(status),
        searchable: ~w(title owner)
      )

    {:ok, assign(socket, all: rows(), table: table, rows: [], last_action: nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket |> assign(:table, DataTable.from_params(params, socket.assigns.table)) |> load()}
  end

  @impl true
  def handle_event("shadcn:data-table", params, socket) do
    case DataTable.handle_event(params, socket.assigns.table) do
      {:query, table, opts} ->
        {:noreply, push_patch(socket, [to: path(table)] ++ opts)}

      {:ok, table} ->
        {:noreply, assign(socket, :table, table)}

      {:action, "delete", id, table} ->
        all = Enum.reject(socket.assigns.all, &(to_string(&1.id) == id))
        table = DataTable.remove_row(table, id)

        {:noreply,
         socket |> assign(all: all, table: table, last_action: "delete #{id}") |> load()}

      {:action, action, id, table} ->
        {:noreply, assign(socket, table: table, last_action: "#{action} #{id}")}
    end
  end

  defp path(table) do
    case DataTable.to_params(table) do
      params when params == %{} -> "/data-table-preview"
      params -> "/data-table-preview?" <> URI.encode_query(params)
    end
  end

  defp load(socket) do
    {rows, table} = DataTable.apply(socket.assigns.table, socket.assigns.all)
    assign(socket, rows: rows, table: table)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-5xl space-y-6 p-8">
      <h1 id="tasks-heading" class="text-2xl font-semibold">Data table</h1>
      <section class="space-y-4">
        <div class="flex items-center justify-between gap-2">
          <.data_table_search state={@table} placeholder="Filter tasks...">
            <.native_select
              :let={selection}
              name="status"
              size="sm"
              value={@table.filters["status"] || ""}
              aria-label="Status"
            >
              <.native_select_option value="" selected={"" in selection}>
                All statuses
              </.native_select_option>
              <.native_select_option
                :for={status <- ~w(todo in-progress done)}
                value={status}
                selected={status in selection}
              >
                {status}
              </.native_select_option>
            </.native_select>
          </.data_table_search>
          <.data_table_view_options
            state={@table}
            columns={[{"status", "Status"}, {"owner", "Owner"}, {"points", "Points"}]}
          />
        </div>
        <div class="overflow-hidden rounded-lg border">
          <.data_table
            state={@table}
            rows={@rows}
            selectable
            row_label="title"
            header_class="bg-muted"
          >
            <:col :let={task} field="title" label="Title" class="font-medium">{task.title}</:col>
            <:col :let={task} field="status" label="Status">
              <.badge variant="outline">{task.status}</.badge>
            </:col>
            <:col field="owner" label="Owner" />
            <:col field="points" label="Points" head_class="w-24" />
            <:row_actions class="w-32">
              <.dropdown_menu_item value="edit">Edit</.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
            </:row_actions>
          </.data_table>
        </div>
        <.data_table_pagination state={@table} selectable class="px-2" />
        <output id="tasks-last-action" class="block text-xs">{@last_action}</output>
      </section>
      <.live_component module={ShadcnLiveview.Preview.DataTableComponent} id="archive" />
    </main>
    """
  end
end

defmodule ShadcnLiveview.Preview.DataTableComponent do
  @moduledoc false
  # Non-URL table inside a LiveComponent: every control targets @myself, and the parent
  # LiveView has no clause for this table's event name.
  use Phoenix.LiveComponent
  use ShadcnLiveview
  alias ShadcnLiveview.DataTable
  alias ShadcnLiveview.Preview.DataTableLive

  @impl true
  def mount(socket) do
    table = DataTable.new(id: "archive", event: "archive-table", sortable: ~w(title points))

    {:ok, socket |> assign(all: DataTableLive.rows(), table: table) |> load()}
  end

  @impl true
  def handle_event("archive-table", params, socket) do
    case DataTable.handle_event(params, socket.assigns.table) do
      {:query, table, _opts} ->
        {:noreply, socket |> assign(:table, table) |> load()}

      {:ok, table} ->
        {:noreply, assign(socket, :table, table)}

      {:action, "delete", id, table} ->
        all = Enum.reject(socket.assigns.all, &(to_string(&1.id) == id))
        {:noreply, socket |> assign(all: all, table: DataTable.remove_row(table, id)) |> load()}

      {:action, _action, _id, table} ->
        {:noreply, assign(socket, :table, table)}
    end
  end

  defp load(socket) do
    {rows, table} = DataTable.apply(socket.assigns.table, socket.assigns.all)
    assign(socket, rows: rows, table: table)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section id="archive-section" class="space-y-4">
      <h2 class="text-lg font-semibold">Archive (LiveComponent)</h2>
      <div class="flex items-center justify-between gap-2">
        <.data_table_search state={@table} target={@myself} placeholder="Filter archive..." />
        <.data_table_view_options state={@table} target={@myself} columns={[{"points", "Points"}]} />
      </div>
      <div class="overflow-hidden rounded-lg border">
        <.data_table state={@table} rows={@rows} selectable row_label="title" target={@myself}>
          <:col field="title" label="Title" />
          <:col field="points" label="Points" />
          <:row_actions>
            <.dropdown_menu_item value="delete" variant="destructive">Delete</.dropdown_menu_item>
          </:row_actions>
        </.data_table>
      </div>
      <.data_table_pagination state={@table} selectable target={@myself} class="px-2" />
    </section>
    """
  end
end
