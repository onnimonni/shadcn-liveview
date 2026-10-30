import Config

config :consumer, :secure_cookies, true
config :consumer, :gzip_static, true

config :consumer, ConsumerWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

config :logger, level: :info
