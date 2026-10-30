defmodule ConsumerWeb.SettingsWorkflow do
  import Phoenix.Component, only: [assign: 2, assign: 3, to_form: 2]
  import Phoenix.LiveView, only: [push_event: 3]
  alias Consumer.{Settings, SettingsStore}

  def init(socket, session_id, id) do
    snapshot = SettingsStore.get(session_id)

    socket
    |> assign(
      id: id,
      session_id: session_id,
      saved: snapshot.settings,
      revision: snapshot.revision,
      pending: nil,
      dialog_open: false,
      status: "Ready to edit."
    )
    |> put_form(Settings.changeset(snapshot.settings, %{}))
  end

  def handle_event(event, %{"settings" => params}, socket)
      when event in ["validate", "recover"] do
    changeset = Settings.changeset(socket.assigns.saved, params)

    status =
      if event == "recover",
        do: "Unsaved edits recovered after reconnect.",
        else: "Editing unsaved settings."

    socket
    |> put_form(%{changeset | action: :validate})
    |> assign(pending: nil, dialog_open: false, status: status)
  end

  def handle_event("save", %{"settings" => params}, socket) do
    changeset = Settings.changeset(socket.assigns.saved, params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, settings} ->
        socket
        |> put_form(%{changeset | action: :insert})
        |> assign(
          pending: settings,
          dialog_open: true,
          status: "Review your settings before saving."
        )

      {:error, changeset} ->
        socket
        |> put_form(changeset)
        |> assign(
          pending: nil,
          dialog_open: false,
          status: "Settings were not saved. Correct the highlighted fields."
        )
    end
  end

  def handle_event(
        "confirm-save",
        _params,
        %{assigns: %{pending: %Settings{} = settings}} = socket
      ) do
    snapshot = SettingsStore.save(socket.assigns.session_id, settings)

    socket
    |> replace_with_saved(snapshot, "Settings saved on the server.")
    |> push_event("shadcn:toast", %{
      toaster: socket.assigns.id <> "-toaster",
      message: "Settings saved",
      description: "Your preferences are now stored in this example's server process."
    })
  end

  # Reject stale/double confirmation events after cancellation or a completed save.
  def handle_event("confirm-save", _params, %{assigns: %{pending: nil}} = socket), do: socket

  def handle_event("reset", _params, socket) do
    snapshot = SettingsStore.get(socket.assigns.session_id)

    replace_with_saved(
      socket,
      snapshot,
      "Unsaved edits reset to the latest server-saved settings."
    )
  end

  def handle_event("server-update", _params, socket) do
    snapshot = SettingsStore.server_update(socket.assigns.session_id)

    replace_with_saved(
      socket,
      snapshot,
      "Server update applied to every controlled field. Notifications were toggled."
    )
  end

  def handle_event("shadcn:modal-close", _params, socket) do
    assign(socket,
      dialog_open: false,
      pending: nil,
      status: "Continue editing; nothing was saved."
    )
  end

  # PubSub is handled by the owning LiveView, which forwards snapshots to its component.
  # Other tabs update the saved result without throwing away this tab's unsaved draft.
  def receive_snapshot(socket, snapshot) do
    if snapshot.revision > socket.assigns.revision do
      assign(socket, saved: snapshot.settings, revision: snapshot.revision)
    else
      socket
    end
  end

  defp replace_with_saved(socket, snapshot, status) do
    socket
    |> assign(
      saved: snapshot.settings,
      revision: snapshot.revision,
      pending: nil,
      dialog_open: false,
      status: status
    )
    |> put_form(Settings.changeset(snapshot.settings, %{}))
  end

  defp put_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :settings, id: socket.assigns.id))
  end
end
