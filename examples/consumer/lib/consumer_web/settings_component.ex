defmodule ConsumerWeb.SettingsComponent do
  use Phoenix.LiveComponent
  alias ConsumerWeb.{SettingsView, SettingsWorkflow}

  @impl true
  def update(%{snapshot: snapshot}, socket) do
    {:ok, SettingsWorkflow.receive_snapshot(socket, snapshot)}
  end

  def update(%{id: id, session_id: session_id}, socket) do
    socket =
      if Map.has_key?(socket.assigns, :form) do
        socket
      else
        SettingsWorkflow.init(socket, session_id, id)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    {:noreply, SettingsWorkflow.handle_event(event, params, socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id <> "-component"}>
      <SettingsView.editor
        id={@id}
        form={@form}
        saved={@saved}
        revision={@revision}
        pending={@pending}
        dialog_open={@dialog_open}
        status={@status}
        target={@myself}
      />
    </div>
    """
  end
end
