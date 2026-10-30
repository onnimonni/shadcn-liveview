defmodule ConsumerWeb.ShopOrderLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  alias Consumer.Shop.Store
  alias ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopComponents

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    socket = ShopCheckoutComponents.init(socket, session_id, "Order details · Northline")
    {:ok, assign(socket, :order, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    order = Store.order(socket.assigns.session_id, id)
    title = if order, do: order.number <> " · Northline", else: "Order not found · Northline"
    {:noreply, assign(socket, order: order, page_title: title)}
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
    <.shell shop={@shop} current="orders" title="Order details" flash={@flash}>
      <section :if={!@order} class="shop-empty">
        <p class="shop-eyebrow">Order unavailable</p><h1>We couldn’t find that order.</h1>
        <p class="shop-muted">
          It may not exist, or it may belong to another browser session. Only orders placed in this browser are shown here.
        </p>
        <.link navigate="/shop/orders" class="shop-link-button">View your orders</.link>
      </section>
      <div :if={@order} class="shop-order-receipt">
        <.link navigate="/shop/orders" class="shop-text-link shop-back-link">← All your orders</.link>
        <header class="shop-page-head shop-receipt-head">
          <span class="shop-receipt-check" aria-hidden="true">✓</span>
          <div>
            <p class="shop-eyebrow">Demo order confirmed</p><h1>Good choices, well kept.</h1>
            <p class="shop-muted">
              Order <strong>{@order.number}</strong> · {date(@order.inserted_at)}
            </p>
            <p>Your order has been saved locally. No payment was taken.</p>
          </div>
        </header>
        <div class="shop-checkout-layout">
          <section aria-labelledby="purchased-items-heading">
            <.card class="shop-receipt-card">
              <.card_header>
                <h2 id="purchased-items-heading">Your essentials</h2><p class="shop-muted">
                  Purchased quantities and prices, recorded when this order was placed.
                </p>
              </.card_header>
              <.card_content>
                <.purchased_lines lines={@order.lines} id="order-purchased-lines" />
              </.card_content>
            </.card>
            <div class="shop-order-customer-grid">
              <section
                class="shop-panel shop-order-detail-panel"
                aria-labelledby="order-customer-heading"
              >
                <h2 id="order-customer-heading">Customer</h2>
                <p>{@order.customer.full_name}</p>
                <p class="shop-order-wrap">{@order.customer.email}</p>
                <p :if={@order.customer.phone}>{@order.customer.phone}</p>
              </section>
              <section
                class="shop-panel shop-order-detail-panel"
                aria-labelledby="order-address-heading"
              >
                <h2 id="order-address-heading">Delivery address</h2>
                <address>
                  {@order.customer.full_name}<br />
                  {@order.customer.address}<br />
                  {@order.customer.postal_code} {@order.customer.city}<br />
                  {country_label(@order.customer.country)}
                </address>
              </section>
            </div>
            <section
              :if={@order.customer.delivery_notes}
              class="shop-panel shop-order-detail-panel shop-delivery-notes"
              aria-labelledby="order-notes-heading"
            >
              <h2 id="order-notes-heading">Delivery notes</h2><p>{@order.customer.delivery_notes}</p>
            </section>
          </section>
          <aside class="shop-checkout-sidebar" aria-labelledby="order-total-heading">
            <.card class="shop-summary-card">
              <.card_header>
                <h2 id="order-total-heading">Order details</h2><.badge variant="secondary">
                  Confirmed
                </.badge>
              </.card_header>
              <.card_content>
                <dl class="shop-order-metadata">
                  <div>
                    <dt>Order number</dt><dd>{@order.number}</dd>
                  </div>
                  <div>
                    <dt>Placed</dt><dd>
                      <time datetime={DateTime.to_iso8601(@order.inserted_at)}>{date(
                        @order.inserted_at
                      )}</time>
                    </dd>
                  </div>
                  <div>
                    <dt>Delivery</dt><dd>{shipping_label(@order.shipping_method)}</dd>
                  </div>
                  <div>
                    <dt>Payment</dt><dd>Local demo · no charge</dd>
                  </div>
                </dl>
                <.totals shop={@order} id="order-totals" />
                <p class="shop-muted">
                  These totals are saved with your order and do not change when the catalogue or your bag changes.
                </p>
              </.card_content>
            </.card>
            <.demo_notice />
            <.link navigate="/shop" class="shop-link-button shop-checkout-cta">Keep exploring →</.link>
          </aside>
        </div>
      </div>
    </.shell>
    """
  end
end
