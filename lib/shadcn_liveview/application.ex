defmodule ShadcnLiveview.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Application.get_env(:shadcn_liveview, :preview, false) do
        [
          {Phoenix.PubSub, name: ShadcnLiveview.Preview.PubSub},
          ShadcnLiveview.Preview.Endpoint
        ]
      else
        []
      end

    opts = [strategy: :one_for_one, name: ShadcnLiveview.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
