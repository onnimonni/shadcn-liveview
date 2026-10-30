defmodule ConsumerWeb.ShopCheckoutComponents do
  use Phoenix.Component
  use ShadcnLiveview

  import ConsumerWeb.ShopComponents, only: [money: 1]
  alias Consumer.Shop.{Checkout, Store}

  def init(socket, session_id, title) do
    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.subscribe(Consumer.PubSub, Store.topic(session_id))
      Phoenix.PubSub.subscribe(Consumer.PubSub, Store.inventory_topic())
    end

    assign(socket,
      session_id: session_id,
      page_title: title,
      shop: Store.snapshot(session_id)
    )
  end

  def receive_snapshot(socket, snapshot) do
    if snapshot.revision >= socket.assigns.shop.revision,
      do: assign(socket, :shop, snapshot),
      else: socket
  end

  def refresh(socket), do: receive_snapshot(socket, Store.snapshot(socket.assigns.session_id))

  def shipping_label("express"), do: "Express delivery"
  def shipping_label(_method), do: "Standard delivery"

  def date(%DateTime{} = date), do: Calendar.strftime(date, "%d %b %Y")

  def country_label(code) do
    Enum.find_value(Checkout.countries(), code, fn {label, country} ->
      if country == code, do: label
    end)
  end

  def quantity_options(line, stock) do
    available = min(Map.get(stock, line.variant.id, 0), 10)
    quantities = if available > 0, do: Enum.to_list(1..available), else: []
    Enum.sort(Enum.uniq([line.quantity | quantities]))
  end

  attr :shop, :map, required: true
  attr :id, :string, default: "shop-totals"

  def totals(assigns) do
    ~H"""
    <dl id={@id} class="shop-totals" aria-live="polite" aria-atomic="true">
      <div>
        <dt>Subtotal</dt><dd>{money(@shop.subtotal_cents)}</dd>
      </div>
      <div :if={@shop.discount_cents > 0} class="shop-discount">
        <dt>Welcome discount</dt><dd>−{money(@shop.discount_cents)}</dd>
      </div>
      <div>
        <dt>{shipping_label(@shop.shipping_method)}</dt>
        <dd>{if @shop.shipping_cents == 0, do: "Free", else: money(@shop.shipping_cents)}</dd>
      </div>
      <div class="shop-total">
        <dt>Total <span class="shop-muted">EUR</span></dt><dd>{money(@shop.total_cents)}</dd>
      </div>
    </dl>
    """
  end

  attr :shop, :map, required: true
  attr :id, :string, default: "shop-shipping"

  def shipping_choice(assigns) do
    ~H"""
    <form id={@id <> "-form"} phx-change="set-shipping" class="shop-shipping-choice">
      <label for={@id}>Delivery method</label>
      <.native_select :let={selection} id={@id} name="method" value={@shop.shipping_method}>
        <option value="standard" selected={"standard" in selection}>
          Standard · €4.90 / free from €100
        </option>
        <option value="express" selected={"express" in selection}>Express · €9.90</option>
      </.native_select>
      <p class="shop-muted">
        Standard: 3–5 business days. Express: 1–2 business days. Demo estimates only; no parcel is shipped.
      </p>
    </form>
    """
  end

  attr :lines, :list, required: true
  attr :id, :string, default: "purchased-lines"
  attr :compact, :boolean, default: false

  def purchased_lines(assigns) do
    ~H"""
    <ul id={@id} class={["shop-purchased-lines", @compact && "shop-purchased-compact"]}>
      <li :for={line <- @lines}>
        <img src={line.product.image} alt="" width="96" height="112" />
        <div>
          <.link navigate={"/shop/products/" <> line.product.slug} class="shop-line-name">{line.product.name}</.link>
          <p class="shop-muted">{line.variant.label}</p>
          <p class="shop-muted">{line.quantity} × {money(line.unit_price_cents)}</p>
        </div>
        <strong>{money(line.line_total_cents)}</strong>
      </li>
    </ul>
    """
  end

  attr :title, :string, default: "Your bag is waiting for something good."
  attr :description, :string, default: "Explore considered essentials for everyday living."

  def empty_cart(assigns) do
    ~H"""
    <section class="shop-empty shop-checkout-empty">
      <span class="shop-empty-symbol" aria-hidden="true">↗</span>
      <h2>{@title}</h2>
      <p class="shop-muted">{@description}</p>
      <.link navigate="/shop" class="shop-link-button">Explore the collection</.link>
    </section>
    """
  end

  def demo_notice(assigns) do
    ~H"""
    <aside class="shop-demo-notice" aria-label="About demo orders">
      <strong>A real order in a local demo.</strong>
      <p>
        No payment is collected, no card details are needed, and nothing is shipped. Your order is saved locally for this browser session.
      </p>
    </aside>
    """
  end
end
