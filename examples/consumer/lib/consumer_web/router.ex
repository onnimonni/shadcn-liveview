defmodule ConsumerWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, html: {ConsumerWeb.Layouts, :root}
    plug :ensure_example_session
  end

  scope "/" do
    pipe_through :browser
    live "/", ConsumerWeb.ShopCatalogLive, :index
    live "/shop", ConsumerWeb.ShopCatalogLive, :index
    live "/shop/saved", ConsumerWeb.ShopCatalogLive, :saved
    live "/shop/products/:slug", ConsumerWeb.ShopProductLive
    live "/shop/cart", ConsumerWeb.ShopCartLive
    live "/shop/checkout", ConsumerWeb.ShopCheckoutLive
    live "/shop/orders", ConsumerWeb.ShopOrdersLive
    live "/shop/orders/:id", ConsumerWeb.ShopOrderLive
    live "/settings", ConsumerWeb.SettingsLive, :direct
    live "/settings/component", ConsumerWeb.SettingsLive, :component
  end

  defp ensure_example_session(conn, _opts) do
    if get_session(conn, :settings_session) do
      conn
    else
      put_session(
        conn,
        :settings_session,
        Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
      )
    end
  end
end
