import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.25.12",
    path: Path.expand("../node_modules/.bin/esbuild", __DIR__),
    shadcn_liveview: [
      args:
        ~w(js/app.js js/preview.js js/gallery.js js/gallery-frame.js --bundle --format=esm --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
    ]
end

config :shadcn_liveview, :preview, System.get_env("SHADCN_PREVIEW") == "1"

config :shadcn_liveview, ShadcnLiveview.Preview.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "127.0.0.1"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  server: true,
  render_errors: [formats: [html: ShadcnLiveview.Preview.ErrorHTML], layout: false],
  secret_key_base: Base.encode64(:crypto.strong_rand_bytes(48)),
  pubsub_server: ShadcnLiveview.Preview.PubSub,
  live_view: [signing_salt: "component-preview"]

if config_env() == :test do
  import_config "test.exs"
end
