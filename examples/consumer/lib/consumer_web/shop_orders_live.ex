defmodule ConsumerWeb.ShopOrdersLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  alias ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopComponents

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    {:ok, ShopCheckoutComponents.init(socket, session_id, "Your orders · Northline")}
  end

  @impl true
  def handle_info({:shop_updated, session_id, snapshot}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, receive_snapshot(socket, snapshot)}
  end

  def handle_info(:inventory_updated, socket), do: {:noreply, refresh(socket)}

  @impl true
  def render(assigns) do
    ~H"""
    <.shell shop={@shop} current="orders" title="Your orders" flash={@flash}>
      <header class="shop-page-head shop-checkout-page-head">
        <p class="shop-eyebrow">A collection of good choices</p><h1>Your orders.</h1>
        <p class="shop-muted">
          Local demo orders placed in this browser. This is not an account; another browser or a cleared session has its own history.
        </p>
      </header>
      <.empty_cart
        :if={@shop.orders == []}
        title="Your story starts here."
        description="Once you place a demo order, its details will be saved here for this browser."
      />
      <div :if={@shop.orders != []} id="order-history" class="shop-order-history">
        <.card :for={order <- @shop.orders} id={"order-" <> order.id} class="shop-history-card">
          <.card_header>
            <div class="shop-history-heading">
              <div>
                <p class="shop-eyebrow">{date(order.inserted_at)}</p><h2>
                  <.link navigate={"/shop/orders/" <> order.id}>{order.number}</.link>
                </h2>
              </div>
              <.badge variant="secondary">Confirmed · demo</.badge>
            </div>
          </.card_header>
          <.card_content>
            <div class="shop-history-body">
              <div class="shop-order-thumbnails" aria-hidden="true">
                <img
                  :for={line <- Enum.take(order.lines, 3)}
                  src={line.product.image}
                  alt=""
                  width="92"
                  height="108"
                />
              </div>
              <div class="shop-history-description">
                <p>{Enum.map_join(order.lines, ", ", & &1.product.name)}</p>
                <p class="shop-muted">
                  {Enum.reduce(order.lines, 0, &(&1.quantity + &2))} items · {shipping_label(
                    order.shipping_method
                  )}
                </p>
              </div>
              <div class="shop-history-total">
                <strong>{money(order.total_cents)}</strong><.link
                  navigate={"/shop/orders/" <> order.id}
                  class="shop-text-link"
                  aria-label={"View order " <> order.number}
                >View order →</.link>
              </div>
            </div>
          </.card_content>
        </.card>
      </div>
      <.demo_notice />
    </.shell>
    """
  end
end
