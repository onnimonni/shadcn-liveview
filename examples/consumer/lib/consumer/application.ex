defmodule Consumer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Consumer.PubSub},
      Consumer.SettingsStore,
      Consumer.Shop.Store,
      ConsumerWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Consumer.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ConsumerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
