import Config

config :consumer, :shop_storage, :memory

config :consumer, ConsumerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4101],
  check_origin: false,
  server: true,
  secret_key_base:
    "consumer-test-only-secret-key-base-do-not-use-in-production-01234567890123456789"

config :phoenix_test,
  otp_app: :consumer,
  endpoint: ConsumerWeb.Endpoint,
  playwright: [
    assets_dir: Path.expand("../../..", __DIR__),
    browser_pools: [[id: :default_pool, size: 1]],
    browser_launch_opts:
      if(System.get_env("PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH"),
        do: [executable_path: System.get_env("PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH")],
        else: []
      ),
    timeout: 5_000
  ]

config :excessibility,
  endpoint: ConsumerWeb.Endpoint,
  head_render_path: "/settings",
  node_modules_path: Path.expand("../../../node_modules", __DIR__),
  prompt_on_diff: false

config :logger, level: :warning
