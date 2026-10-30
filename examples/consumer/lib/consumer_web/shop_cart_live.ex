defmodule ConsumerWeb.ShopCartLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  alias Consumer.Shop.Store
  alias ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopComponents

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    socket = ShopCheckoutComponents.init(socket, session_id, "Your bag · Northline")

    {:ok,
     assign(socket,
       coupon_input: socket.assigns.shop.coupon || "",
       coupon_error: nil,
       cart_error: nil
     )}
  end

  @impl true
  def handle_event(
        "update-quantity",
        %{"variant_id" => variant_id, "quantity" => quantity},
        socket
      ) do
    result =
      case Integer.parse(quantity) do
        {number, ""} -> Store.update_quantity(socket.assigns.session_id, variant_id, number)
        _ -> {:error, :invalid_quantity}
      end

    {:noreply, mutation_result(socket, result, "Bag updated.")}
  end

  def handle_event("remove-item", %{"variant_id" => variant_id}, socket) do
    result = Store.remove_item(socket.assigns.session_id, variant_id)
    {:noreply, mutation_result(socket, result, "Item removed from your bag.")}
  end

  def handle_event("apply-coupon", %{"code" => code}, socket) do
    socket = assign(socket, :coupon_input, code)
    result = Store.apply_coupon(socket.assigns.session_id, code)
    {:noreply, coupon_result(socket, result, "Discount updated.")}
  end

  def handle_event("remove-coupon", _params, socket) do
    result = Store.apply_coupon(socket.assigns.session_id, "")
    {:noreply, coupon_result(socket, result, "Discount removed.")}
  end

  def handle_event("set-shipping", %{"method" => method}, socket) do
    result = Store.set_shipping(socket.assigns.session_id, method)
    {:noreply, mutation_result(socket, result, "Delivery updated.")}
  end

  @impl true
  def handle_info({:shop_updated, session_id, snapshot}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, receive_snapshot(socket, snapshot)}
  end

  def handle_info(:inventory_updated, socket), do: {:noreply, refresh(socket)}

  defp mutation_result(socket, {:ok, snapshot}, message) do
    socket
    |> receive_snapshot(snapshot)
    |> assign(cart_error: nil, coupon_error: nil, coupon_input: snapshot.coupon || "")
    |> notify(message)
  end

  defp mutation_result(socket, {:error, error}, _message) do
    socket |> refresh() |> assign(:cart_error, error_message(error))
  end

  defp coupon_result(socket, {:ok, snapshot}, message) do
    mutation_result(socket, {:ok, snapshot}, message)
  end

  defp coupon_result(socket, {:error, error}, _message) do
    socket |> refresh() |> assign(:coupon_error, error_message(error))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.shell shop={@shop} current="cart" title="Your bag" flash={@flash}>
      <header class="shop-page-head shop-bag-head">
        <div>
          <p class="shop-eyebrow">Made for your everyday</p><h1>
            Your bag<span class="shop-muted"> ({@shop.cart_count})</span>
          </h1>
        </div>
        <.link navigate="/shop" class="shop-text-link">Continue exploring →</.link>
      </header>
      <p :if={@cart_error} id="cart-error" class="shop-checkout-error" role="alert">{@cart_error}</p>
      <.empty_cart :if={@shop.cart == []} />
      <div :if={@shop.cart != []} class="shop-checkout-layout">
        <section class="shop-bag-items" aria-label="Items in your bag">
          <article
            :for={line <- @shop.cart}
            id={"cart-line-" <> line.variant.id}
            class="shop-cart-line"
          >
            <.link
              navigate={"/shop/products/" <> line.product.slug}
              tabindex="-1"
              aria-hidden="true"
              class="shop-cart-image-link"
            >
              <img src={line.product.image} alt="" width="180" height="216" />
            </.link>
            <div class="shop-cart-line-details">
              <p class="shop-eyebrow">{line.product.category}</p>
              <h2>
                <.link navigate={"/shop/products/" <> line.product.slug}>{line.product.name}</.link>
              </h2>
              <p class="shop-muted">{line.variant.label}</p>
              <p class="shop-muted">{money(line.unit_price_cents)} each</p>
              <p
                :if={line.quantity > Map.get(@shop.stock, line.variant.id, 0)}
                class="shop-stock-warning"
                role="status"
              >
                Only {Map.get(@shop.stock, line.variant.id, 0)} left. Reduce the quantity or remove this item before checkout.
              </p>
              <div class="shop-line-controls">
                <form
                  id={"quantity-form-" <> line.variant.id}
                  phx-submit="update-quantity"
                  class="shop-quantity-form"
                >
                  <input type="hidden" name="variant_id" value={line.variant.id} />
                  <label for={"quantity-" <> line.variant.id} class="shop-sr-only">Quantity for {line.product.name}, {line.variant.label}</label>
                  <.native_select
                    :let={selection}
                    id={"quantity-" <> line.variant.id}
                    name="quantity"
                    value={line.quantity}
                  >
                    <option
                      :for={quantity <- quantity_options(line, @shop.stock)}
                      value={quantity}
                      selected={to_string(quantity) in selection}
                    >
                      {quantity}
                    </option>
                  </.native_select>
                  <.button type="submit" variant="outline" phx-disable-with="Updating…">Update</.button>
                </form>
                <.button
                  type="button"
                  variant="ghost"
                  phx-click="remove-item"
                  phx-value-variant_id={line.variant.id}
                  aria-label={"Remove " <> line.product.name <> ", " <> line.variant.label}
                  phx-disable-with="Removing…"
                >Remove</.button>
              </div>
            </div>
            <strong class="shop-cart-line-total">{money(line.line_total_cents)}</strong>
          </article>
          <p class="shop-bag-footnote shop-muted">
            Thoughtfully chosen. Carefully made. Yours to use every day.
          </p>
        </section>
        <aside class="shop-checkout-sidebar" aria-labelledby="cart-summary-heading">
          <.card class="shop-summary-card">
            <.card_header>
              <h2 id="cart-summary-heading">Order summary</h2>
            </.card_header>
            <.card_content>
              <.shipping_choice shop={@shop} />
              <div class="shop-coupon-section">
                <form id="coupon-form" phx-submit="apply-coupon" class="shop-coupon-form">
                  <label for="coupon-code">Have a discount code?</label>
                  <div>
                    <.input
                      id="coupon-code"
                      name="code"
                      value={@coupon_input}
                      aria-invalid={if @coupon_error, do: "true", else: "false"}
                      aria-describedby={if @coupon_error, do: "coupon-error"}
                      autocomplete="off"
                      maxlength="40"
                      placeholder="WELCOME10"
                    />
                    <.button type="submit" variant="outline" phx-disable-with="Applying…">Apply</.button>
                  </div>
                </form>
                <p :if={@coupon_error} id="coupon-error" class="shop-checkout-error" role="alert">
                  {@coupon_error}
                </p>
                <p class="shop-muted">A little welcome: use WELCOME10 for 10% off.</p>
                <div :if={@shop.coupon} class="shop-applied-coupon">
                  <.badge variant="secondary">{@shop.coupon} applied</.badge>
                  <.button type="button" variant="ghost" phx-click="remove-coupon">Remove code</.button>
                </div>
              </div>
              <.totals shop={@shop} />
              <.link navigate="/shop/checkout" class="shop-link-button shop-checkout-cta">Continue to checkout →</.link>
              <p class="shop-muted shop-summary-note">
                All amounts are in EUR. Final stock is checked when you place your demo order.
              </p>
            </.card_content>
          </.card>
          <.demo_notice />
        </aside>
      </div>
    </.shell>
    """
  end
end
