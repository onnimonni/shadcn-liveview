import Config

if config_env() != :test do
  port = String.to_integer(System.get_env("CONSUMER_PORT") || System.get_env("PORT") || "4001")

  config :consumer,
         :shop_storage,
         System.get_env("SHOP_DATA_PATH") ||
           Path.join(
             System.get_env("XDG_DATA_HOME") || Path.join(System.user_home!(), ".local/share"),
             "shadcn-consumer/shop.dets"
           )

  config :consumer, ConsumerWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: port],
    server: config_env() == :dev or System.get_env("PHX_SERVER") in ["true", "1"]
end

if config_env() == :prod do
  secret = System.fetch_env!("SECRET_KEY_BASE")

  if byte_size(secret) < 64 do
    raise "SECRET_KEY_BASE must contain at least 64 bytes"
  end

  host = System.get_env("PHX_HOST") || "localhost"

  config :consumer, ConsumerWeb.Endpoint,
    secret_key_base: secret,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}],
    check_origin: ["https://#{host}"]
end
