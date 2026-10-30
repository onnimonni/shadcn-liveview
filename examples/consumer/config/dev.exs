import Config

config :consumer, ConsumerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  debug_errors: true,
  code_reloader: false,
  secret_key_base:
    "consumer-development-only-secret-key-base-do-not-use-in-production-0123456789",
  watchers: [esbuild: {Esbuild, :install_and_run, [:consumer, ~w(--sourcemap=inline --watch)]}]

config :logger, :console, format: "[$level] $message\n"
