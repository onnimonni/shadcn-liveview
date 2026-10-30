defmodule ConsumerWeb.ShopComponents do
  use Phoenix.Component
  use ShadcnLiveview

  attr :shop, :map, required: true
  attr :current, :string, default: "shop"
  attr :title, :string, default: "Northline"
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  def shell(assigns) do
    ~H"""
    <div class="shop-app">
      <a href="#shop-main" class="shop-skip">Skip to content</a>
      <div class="shop-announcement">Thoughtful essentials. Free standard delivery over €100.</div>
      <header class="shop-header shop-container">
        <.link navigate="/shop" class="shop-brand" aria-label="Northline home">
          <svg viewBox="0 0 32 32" width="32" height="32" aria-hidden="true"><path
            d="M4 27V5h5l14 17V5h5v22h-5L9 10v17Z"
            fill="currentColor"
          /></svg>
          <span>NORTHLINE<small>GOODS FOR EVERYDAY</small></span>
        </.link>
        <nav class="shop-nav" aria-label="Store navigation">
          <.link navigate="/shop" aria-current={if @current == "shop", do: "page"}>Shop</.link>
          <.link navigate="/shop/saved" aria-current={if @current == "saved", do: "page"}>Saved
          <span class="shop-nav-count">{length(@shop.wishlist)}</span></.link>
          <.link navigate="/shop/orders" aria-current={if @current == "orders", do: "page"}>Orders</.link>
          <.link
            navigate="/shop/cart"
            class="shop-bag"
            aria-current={if @current == "cart", do: "page"}
          >Bag
          <.badge aria-label={"#{@shop.cart_count} items in bag"}>{@shop.cart_count}</.badge></.link>
        </nav>
      </header>
      <div class="shop-demo-strip">
        <.badge variant="outline">DEMO STORE</.badge><span>Browse, build a bag and place an order. No payment collected or goods dispatched.</span>
      </div>
      <div class="shop-connection shop-container" role="status">
        <span class="shop-offline">Connection lost. Checkout is unavailable until we reconnect; your form edits will be recovered.</span>
      </div>
      <div class="shop-container shop-flash" aria-live="polite">
        <p :if={Phoenix.Flash.get(@flash, :info)} class="shop-notice">
          {Phoenix.Flash.get(@flash, :info)}
        </p>
        <p :if={Phoenix.Flash.get(@flash, :error)} class="shop-error" role="alert">
          {Phoenix.Flash.get(@flash, :error)}
        </p>
      </div>
      <main id="shop-main" class="shop-container shop-main" tabindex="-1" aria-label={@title}>
        {render_slot(@inner_block)}
      </main>
      <footer class="shop-footer">
        <div class="shop-container shop-footer-grid">
          <div>
            <p class="shop-footer-brand">Less, but better.</p><p>
              Considered essentials for the everyday.<br />An independent Phoenix LiveView component example.
            </p>
          </div>
          <nav aria-label="Footer navigation">
            <.link navigate="/shop">Explore the collection</.link><.link navigate="/shop/orders">Your demo orders</.link><a href="/settings">Component form example</a>
          </nav>
          <div>
            <p class="shop-eyebrow">THE DETAILS</p><p>
              Prices in EUR · VAT included<br />Original product illustrations<br />Single-node demo; not a production shop
            </p>
          </div>
        </div>
        <div class="shop-container shop-footer-bottom">
          <span>Northline / shadcn LiveView</span><span>Designed to be used, not just rendered.</span>
        </div>
      </footer>
      <.toaster id="shop-toaster" />
    </div>
    """
  end

  def money(cents) when is_integer(cents) do
    sign = if cents < 0, do: "−", else: ""
    value = abs(cents)

    sign <>
      "€" <>
      Integer.to_string(div(value, 100)) <>
      "." <> String.pad_leading(Integer.to_string(rem(value, 100)), 2, "0")
  end

  def error_message(reason) do
    case reason do
      :out_of_stock ->
        "That quantity is no longer available. Please update your bag."

      :quantity_limit ->
        "You can add up to 10 of each option to your bag."

      :invalid_quantity ->
        "Choose a quantity between 1 and 10."

      :invalid_coupon ->
        "That code is not valid. Try WELCOME10 for 10% off."

      :empty_cart ->
        "Your bag is empty. Add an item before checking out."

      :invalid_shipping ->
        "Choose one of the available delivery methods."

      :product_not_found ->
        "That product is no longer available."

      :variant_not_found ->
        "Choose an available product option."

      :item_not_found ->
        "That item is no longer in your bag."

      :invalid_session ->
        "Your browser session is unavailable. Reload the page to continue."

      :invalid_request_id ->
        "Checkout could not be verified. Reload the page and try again."

      :storage_unavailable ->
        "Your change could not be confirmed. Reload and check your bag or orders before retrying."

      _ ->
        "We could not complete that change. Please check your selections and try again."
    end
  end

  def notify(socket, message) do
    Phoenix.LiveView.push_event(socket, "shadcn:toast", %{
      toaster: "shop-toaster",
      message: message
    })
  end
end
