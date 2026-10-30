defmodule Consumer.SettingsStore do
  @moduledoc "Per-browser example state. Survives LiveView reconnects, not application restarts."
  use GenServer
  alias Consumer.Settings

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def topic(session_id), do: "settings:#{session_id}"
  def get(session_id), do: GenServer.call(__MODULE__, {:get, session_id})

  def save(session_id, %Settings{} = settings),
    do: GenServer.call(__MODULE__, {:save, session_id, settings})

  def server_update(session_id), do: GenServer.call(__MODULE__, {:server_update, session_id})

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_call({:get, id}, _from, state) do
    snapshot = Map.get(state, id, %{settings: %Settings{}, revision: 0})
    {:reply, snapshot, Map.put(state, id, snapshot)}
  end

  def handle_call({:save, id, settings}, _from, state) do
    persist(id, settings, state)
  end

  def handle_call({:server_update, id}, _from, state) do
    saved = Map.get(state, id, %{settings: %Settings{}, revision: 0}).settings

    settings = %Settings{
      saved
      | display_name:
          if(saved.display_name == "Server updated", do: "Alex Morgan", else: "Server updated"),
        timezone: if(saved.timezone == "Asia/Tokyo", do: "UTC", else: "Asia/Tokyo"),
        notifications: not saved.notifications,
        bio: "These values were updated by the server, not browser input."
    }

    persist(id, settings, state)
  end

  defp persist(id, settings, state) do
    revision = Map.get(state, id, %{revision: 0}).revision + 1
    snapshot = %{settings: settings, revision: revision}
    Phoenix.PubSub.broadcast(Consumer.PubSub, topic(id), {:settings_saved, id, snapshot})
    {:reply, snapshot, Map.put(state, id, snapshot)}
  end
end
