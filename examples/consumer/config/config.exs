import Config

config :consumer, ConsumerWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [formats: [html: ConsumerWeb.ErrorHTML], layout: false],
  pubsub_server: Consumer.PubSub,
  live_view: [signing_salt: "consumer-settings"]

config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.25.12",
  consumer: [
    args:
      ~w(js/app.js --bundle --format=esm --target=es2022 --outdir=../priv/static/assets --external:/shadcn/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{config_env()}.exs"
