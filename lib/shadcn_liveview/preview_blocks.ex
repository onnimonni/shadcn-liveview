defmodule ShadcnLiveview.Preview.BlocksLive do
  @moduledoc false
  # Connected harness for findings from converting shadcn blocks (login-04, sidebar-07,
  # dashboard-01): avatar load states, popups inside `relative z-0` table rows, pointer vs
  # keyboard menu focus, and modal controls inside a LiveComponent that inherits phx-target.
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  @avatar ~s(data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="%23e11d48"/></svg>)
  # Decodes as an image request that fails without a network round trip.
  @broken "data:image/png;base64,AAAA"
  @rows ~w(alpha beta gamma delta epsilon)
  @statuses ~w(Done Pending Blocked Review Archived)

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       tick: 0,
       avatar_src: @avatar,
       broken_src: @broken,
       open: %{},
       values: Map.new(@rows, &{"status-" <> &1, "Pending"}),
       rows: @rows,
       statuses: @statuses
     )}
  end

  @impl true
  def handle_event("tick", _params, socket), do: {:noreply, update(socket, :tick, &(&1 + 1))}

  def handle_event("swap-avatar", _params, socket),
    do: {:noreply, assign(socket, avatar_src: @broken, broken_src: @avatar)}

  def handle_event("shadcn:popup-change", %{"id" => id, "action" => action} = params, socket) do
    socket = update(socket, :open, &Map.put(&1, id, action == "open"))

    case {action, params} do
      {"select", %{"value" => value}} ->
        {:noreply, update(socket, :values, &Map.put(&1, id, value))}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="space-y-10 p-6">
      <button id="tick" type="button" phx-click="tick">Tick {@tick}</button>
      <section class="flex items-center gap-6">
        <.avatar id="avatar-loaded">
          <.avatar_image src={@avatar_src} alt="@loaded" />
          <.avatar_fallback>CN</.avatar_fallback>
        </.avatar>
        <span id="avatar-name">shadcn</span>
        <.avatar id="avatar-broken">
          <.avatar_image src={@broken_src} alt="@broken" />
          <.avatar_fallback>ER</.avatar_fallback>
        </.avatar>
        <button id="swap-avatar" type="button" phx-click="swap-avatar">Swap avatars</button>
      </section>

      <section class="flex items-center gap-6">
        <.dropdown_menu id="focus-menu" open={Map.get(@open, "focus-menu", false)}>
          <:trigger :let={popup}>
            <.button variant="outline" {popup.trigger}>Actions</.button>
          </:trigger>
          <:content :let={popup}>
            <.dropdown_menu_content context={popup}>
              <.dropdown_menu_item>Edit</.dropdown_menu_item>
              <.dropdown_menu_item>Copy</.dropdown_menu_item>
              <.dropdown_menu_item>Delete</.dropdown_menu_item>
            </.dropdown_menu_content>
          </:content>
        </.dropdown_menu>
      </section>

      <.table id="status-table">
        <.table_body>
          <.table_row :for={row <- @rows} id={"row-" <> row} class="relative z-0">
            <.table_cell>{row}</.table_cell>
            <.table_cell>
              <.select
                id={"status-" <> row}
                position="popper"
                open={Map.get(@open, "status-" <> row, false)}
                value={@values["status-" <> row]}
              >
                <:trigger :let={popup}>
                  <.select_trigger context={popup} class="w-32">
                    <.select_value context={popup} />
                  </.select_trigger>
                </:trigger>
                <:option
                  :for={status <- @statuses}
                  id={"status-" <> row <> "-" <> String.downcase(status)}
                  value={status}
                  label={status}
                >
                  {status}
                </:option>
              </.select>
            </.table_cell>
          </.table_row>
        </.table_body>
      </.table>

      <.live_component module={ShadcnLiveview.Preview.BlocksChild} id="blocks-child" />
    </main>
    """
  end
end

defmodule ShadcnLiveview.Preview.BlocksChild do
  @moduledoc false
  # The drawer has no `target`: its controls inherit the wrapper's phx-target. The parent
  # LiveView has no shadcn:modal-* clauses, so a misrouted push crashes it visibly.
  use Phoenix.LiveComponent
  use ShadcnLiveview

  @impl true
  def mount(socket), do: {:ok, assign(socket, open: false, events: [])}

  @impl true
  def handle_event("shadcn:modal-" <> action, %{"id" => "child-drawer"}, socket),
    do:
      {:noreply, socket |> assign(:open, action == "open") |> update(:events, &(&1 ++ [action]))}

  @impl true
  def render(assigns) do
    ~H"""
    <section id={@id} phx-target={@myself} class="space-y-4 border p-6">
      <output id="child-drawer-events">{Enum.join(@events, ",")}</output>
      <.drawer id="child-drawer" open={@open} direction="right">
        <:trigger :let={modal}>
          <.drawer_trigger context={modal}>Open details</.drawer_trigger>
        </:trigger>
        <:content :let={modal}>
          <.drawer_content context={modal}>
            <.drawer_header>
              <.drawer_title context={modal}>Details</.drawer_title>
              <.drawer_description context={modal}>Edit the section.</.drawer_description>
            </.drawer_header>
            <div class="p-4">
              <.input id="child-drawer-header" name="header" value="Cover page" />
            </div>
            <.drawer_footer>
              <.drawer_close context={modal} variant="outline">Done</.drawer_close>
              <.drawer_close context={modal} id="child-drawer-plain">Plain</.drawer_close>
            </.drawer_footer>
          </.drawer_content>
        </:content>
      </.drawer>
    </section>
    """
  end
end
