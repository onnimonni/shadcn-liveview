defmodule ConsumerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :consumer

  @session_options [
    store: :cookie,
    key: "_shadcn_consumer",
    signing_salt: "consumer-session",
    same_site: "Lax",
    http_only: true,
    secure: Application.compile_env(:consumer, :secure_cookies, false)
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  plug Plug.Static,
    at: "/shadcn",
    from: :shadcn_liveview,
    gzip: Application.compile_env(:consumer, :gzip_static, false),
    only: ~w(shadcn.css shadcn-hooks.js)

  plug Plug.Static,
    at: "/",
    from: :consumer,
    gzip: Application.compile_env(:consumer, :gzip_static, false),
    only: ~w(assets)

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug ConsumerWeb.Router
end
