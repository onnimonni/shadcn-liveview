import Config

config :shadcn_liveview, :preview, true

config :shadcn_liveview, ShadcnLiveview.Preview.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4100],
  check_origin: false,
  server: true

config :phoenix_test,
  otp_app: :shadcn_liveview,
  endpoint: ShadcnLiveview.Preview.Endpoint,
  playwright: [
    assets_dir: Path.expand("..", __DIR__),
    browser_pools: [[id: :default_pool, size: 1]],
    browser_launch_opts:
      if(System.get_env("PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH"),
        do: [executable_path: System.get_env("PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH")],
        else: []
      ),
    timeout: 5_000
  ]

config :excessibility,
  endpoint: ShadcnLiveview.Preview.Endpoint,
  head_render_path: "/live-preview/button?embed=1",
  node_modules_path: Path.expand("../node_modules", __DIR__),
  prompt_on_diff: false

config :logger, level: :warning
