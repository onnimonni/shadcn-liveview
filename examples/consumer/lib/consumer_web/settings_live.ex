defmodule ConsumerWeb.SettingsLive do
  use Phoenix.LiveView, layout: false
  alias Consumer.SettingsStore
  alias ConsumerWeb.{SettingsComponent, SettingsView, SettingsWorkflow}

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(Consumer.PubSub, SettingsStore.topic(session_id))

    socket = assign(socket, :session_id, session_id)

    socket =
      if socket.assigns.live_action == :direct do
        SettingsWorkflow.init(socket, session_id, "settings-direct")
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    {:noreply, SettingsWorkflow.handle_event(event, params, socket)}
  end

  @impl true
  def handle_info({:settings_saved, session_id, snapshot}, socket)
      when session_id == socket.assigns.session_id do
    if socket.assigns.live_action == :component do
      send_update(SettingsComponent, id: "settings-component", snapshot: snapshot)
      {:noreply, socket}
    else
      {:noreply, SettingsWorkflow.receive_snapshot(socket, snapshot)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="settings-shell">
      <header class="settings-header">
        <nav class="settings-nav" aria-label="Settings implementations">
          <a href="/settings" aria-current={if @live_action == :direct, do: "page"}>Direct LiveView</a>
          <a href="/settings/component" aria-current={if @live_action == :component, do: "page"}>Stateful LiveComponent</a>
        </nav>
        <h1>Account settings</h1>
        <p>
          Real Phoenix forms, validation, controlled native inputs, confirmation dialog and toast.
          <span class="settings-online">Connected to the server.</span>
          <span class="settings-offline" role="status">Disconnected. Phoenix will recover unsaved form edits when the connection returns.</span>
        </p>
        <p id="settings-implementation">
          {if @live_action == :component,
            do: "LiveComponent: events target @myself; its owning LiveView forwards PubSub updates.",
            else: "Direct LiveView: the page owns form state and handles events itself."}
        </p>
      </header>
      <.live_component
        :if={@live_action == :component}
        module={SettingsComponent}
        id="settings-component"
        session_id={@session_id}
      />
      <SettingsView.editor
        :if={@live_action == :direct}
        id={@id}
        form={@form}
        saved={@saved}
        revision={@revision}
        pending={@pending}
        dialog_open={@dialog_open}
        status={@status}
      />
    </main>
    """
  end
end
