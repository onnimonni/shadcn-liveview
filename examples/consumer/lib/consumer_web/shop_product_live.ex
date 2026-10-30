defmodule ConsumerWeb.ShopProductLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview
  import ConsumerWeb.ShopComponents
  import ConsumerWeb.ShopCatalogComponents, only: [product_grid: 1, stock: 2, remaining: 2]
  alias Consumer.Shop.{Catalog, Store}
  alias ShadcnLiveview.Components.Accordion

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Consumer.PubSub, Store.topic(session_id))
      Phoenix.PubSub.subscribe(Consumer.PubSub, Store.inventory_topic())
    end

    {:ok,
     assign(socket,
       session_id: session_id,
       shop: Store.snapshot(session_id),
       product: nil,
       selection: %{"variant" => "", "quantity" => "1"},
       expanded: "details",
       status: nil
     )}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _uri, socket) do
    product = Catalog.by_slug(slug)
    same_product = product && socket.assigns.product && product.id == socket.assigns.product.id

    socket =
      if same_product do
        socket
      else
        selection = initial_selection(product, socket.assigns.shop)

        assign(socket,
          product: product,
          selection: selection,
          product_form: to_form(selection, as: :product),
          expanded: "details",
          status: nil
        )
      end

    related =
      if product,
        do:
          Catalog.all()
          |> Enum.reject(&(&1.id == product.id))
          |> Enum.sort_by(&(&1.category != product.category))
          |> Enum.take(3),
        else: []

    {:noreply,
     assign(socket,
       related: related,
       page_title:
         if(product, do: product.name <> " · Northline", else: "Product not found · Northline")
     )}
  end

  @impl true
  def handle_event("select-product", %{"product" => params}, socket) do
    selection = Map.take(params, ["variant", "quantity"])

    {:noreply,
     assign(socket,
       selection: selection,
       product_form: to_form(selection, as: :product),
       status: nil
     )}
  end

  def handle_event("add-to-cart", %{"product" => params}, socket) do
    selection = Map.take(params, ["variant", "quantity"])
    socket = assign(socket, selection: selection, product_form: to_form(selection, as: :product))
    product = socket.assigns.product
    variant = selected_variant(product, selection)
    quantity = parse_quantity(selection["quantity"])

    cond do
      is_nil(product) || is_nil(variant) ->
        {:noreply, assign(socket, :status, "Choose an available product option.")}

      is_nil(quantity) ->
        {:noreply, assign(socket, :status, "Choose a whole-number quantity from 1 to 10.")}

      true ->
        case Store.add_item(socket.assigns.session_id, product.id, variant.id, quantity) do
          {:ok, shop} ->
            message = "#{quantity} × #{product.name} added to your bag."
            {:noreply, socket |> assign(shop: shop, status: message) |> notify(message)}

          {:error, reason} ->
            {:noreply,
             assign(socket,
               shop: Store.snapshot(socket.assigns.session_id),
               status: error_message(reason)
             )}
        end
    end
  end

  def handle_event("toggle-saved", %{"id" => id}, socket) do
    case Store.toggle_wishlist(socket.assigns.session_id, id) do
      {:ok, shop} ->
        message =
          if id in shop.wishlist,
            do: "Added to your saved items.",
            else: "Removed from your saved items."

        {:noreply, socket |> assign(shop: shop, status: message) |> notify(message)}

      {:error, reason} ->
        {:noreply, assign(socket, :status, error_message(reason))}
    end
  end

  def handle_event("product-section", %{"item" => item}, socket)
      when item in ["details", "care", "delivery"] do
    {:noreply,
     assign(
       socket,
       :expanded,
       Accordion.accordion_next_value(socket.assigns.expanded, item, "single", true)
     )}
  end

  @impl true
  def handle_info({:shop_updated, session_id, shop}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, assign(socket, :shop, shop)}
  end

  def handle_info(:inventory_updated, socket) do
    {:noreply, assign(socket, :shop, Store.snapshot(socket.assigns.session_id))}
  end

  defp initial_selection(nil, _shop), do: %{"variant" => "", "quantity" => "1"}

  defp initial_selection(product, shop) do
    variant = Enum.find(product.variants, &(remaining(&1, shop) > 0)) || hd(product.variants)
    %{"variant" => variant.id, "quantity" => "1"}
  end

  defp selected_variant(nil, _selection), do: nil

  defp selected_variant(product, selection),
    do: Enum.find(product.variants, &(&1.id == selection["variant"]))

  defp parse_quantity(value) when is_binary(value) do
    case Integer.parse(value) do
      {quantity, ""} when quantity in 1..10 -> quantity
      _ -> nil
    end
  end

  defp parse_quantity(_value), do: nil

  defp can_add?(product, selection, shop) do
    variant = selected_variant(product, selection)
    quantity = parse_quantity(selection["quantity"])
    variant != nil && quantity != nil && quantity <= remaining(variant, shop)
  end

  defp availability(nil, _shop), do: "Choose an option to see availability."

  defp availability(variant, shop) do
    cond do
      stock(variant, shop) <= 0 ->
        "This option is sold out. Please choose another."

      remaining(variant, shop) <= 0 ->
        "This option is already at the available limit in your bag."

      stock(variant, shop) <= 3 ->
        "Only #{stock(variant, shop)} left · #{remaining(variant, shop)} available to add"

      true ->
        "In stock · #{remaining(variant, shop)} available to add"
    end
  end

  defp care("Clothing"),
    do:
      "Wash gently with similar colors and air dry. Check the garment label before washing; avoid high heat to help the fabric keep its shape."

  defp care("Bags"),
    do:
      "Brush away loose dirt and spot clean with a damp cloth. Let dry naturally. Avoid machine washing and store in a dry place."

  defp care("Home"),
    do:
      "For textiles, use a gentle wash and air dry. For ceramics, wash with a soft sponge and mild soap. Avoid sudden changes in temperature."

  defp care("Accessories"),
    do:
      "Handle gently and keep dry when stored. Spot clean textiles; wipe metal pieces with a soft cloth. Avoid harsh cleaners."

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :variant, selected_variant(assigns.product, assigns.selection))

    ~H"""
    <.shell shop={@shop} current="shop" flash={@flash}>
      <nav class="northline-breadcrumb" aria-label="Breadcrumb">
        <.link navigate="/shop">The collection</.link><span aria-hidden="true">/</span>
        <span>{if @product, do: @product.name, else: "Product not found"}</span>
      </nav>
      <section :if={!@product} class="shop-empty northline-empty">
        <p class="shop-eyebrow">A different direction</p>
        <h1>We couldn’t find that essential.</h1>
        <p>
          The product address may have changed. Explore the collection to find something you’ll love.
        </p>
        <.link navigate="/shop" class="shop-link-button">Back to the collection</.link>
      </section>
      <div :if={@product} class="northline-product-detail">
        <div class="northline-detail-image">
          <img src={@product.image} alt={@product.name} width="640" height="760" fetchpriority="high" />
          <.badge :if={@product.badge} variant="secondary" class="northline-detail-badge">
            {@product.badge}
          </.badge>
          <span class="northline-image-caption">NORTHLINE / {@product.category}</span>
        </div>
        <section class="northline-detail-copy" aria-labelledby="product-heading">
          <p class="shop-eyebrow">{@product.category} / Everyday essentials</p>
          <h1 id="product-heading">{@product.name}</h1>
          <p class="northline-detail-price">{money(@product.price_cents)} <span>EUR</span></p>
          <p class="northline-description">{@product.description}</p>
          <p class="northline-material"><span aria-hidden="true">◌</span> {@product.material}</p>
          <.form
            for={@product_form}
            id={"product-selection-" <> @product.id}
            class="northline-product-form"
            phx-change="select-product"
            phx-submit="add-to-cart"
            phx-auto-recover="select-product"
          >
            <.form_field :let={attrs} field={@product_form[:variant]} label="Color & size" required>
              <.native_select :let={selection} {attrs}>
                <option
                  :for={variant <- @product.variants}
                  value={variant.id}
                  selected={variant.id in selection}
                  disabled={remaining(variant, @shop) <= 0}
                >
                  {variant.label}{cond do
                    stock(variant, @shop) <= 0 -> " — Sold out"
                    remaining(variant, @shop) <= 0 -> " — Already in your bag (limit reached)"
                    true -> ""
                  end}
                </option>
              </.native_select>
            </.form_field>
            <p id="product-availability" class="northline-availability" role="status">
              {availability(@variant, @shop)}
            </p>
            <div class="northline-purchase-row">
              <.form_field
                :let={attrs}
                field={@product_form[:quantity]}
                label="Quantity"
                class="northline-quantity"
                required
              >
                <.input
                  {attrs}
                  type="number"
                  min="1"
                  max={if @variant, do: max(remaining(@variant, @shop), 1), else: 1}
                  step="1"
                  inputmode="numeric"
                />
              </.form_field>
              <.button
                type="submit"
                class="northline-add"
                disabled={!can_add?(@product, @selection, @shop)}
                phx-disable-with="Adding…"
              >{if @variant && stock(@variant, @shop) <= 0, do: "Sold out", else: "Add to bag"}
              <span aria-hidden="true">↗</span></.button>
            </div>
          </.form>
          <.button
            type="button"
            variant="outline"
            class="northline-save-detail"
            phx-click="toggle-saved"
            phx-value-id={@product.id}
            aria-pressed={to_string(@product.id in @shop.wishlist)}
          >
            <span aria-hidden="true">{if @product.id in @shop.wishlist, do: "♥", else: "♡"}</span>
            {if @product.id in @shop.wishlist, do: "Saved to your collection", else: "Save for later"}
          </.button>
          <div
            :if={@status}
            id="product-status"
            class="northline-status"
            role="status"
            aria-live="polite"
          >
            <p>{@status}</p><.link :if={@shop.cart_count > 0} navigate="/shop/cart">View your bag ({@shop.cart_count}) →</.link>
          </div>
          <p class="northline-delivery-note">
            Standard delivery €4.90 · Free from €100 after discounts.<br /><span class="shop-muted">A local demo store. No real payment or physical shipment.</span>
          </p>
          <.accordion
            :let={context}
            id="product-information"
            value={@expanded}
            collapsible
            on_change="product-section"
            class="northline-product-accordion"
          >
            <.accordion_item :let={item} context={context} value="details">
              <.accordion_trigger context={item}>The details</.accordion_trigger>
              <.accordion_content context={item}>
                <p>{@product.description}</p>
                <dl class="northline-details-list">
                  <dt>Material</dt><dd>{@product.material}</dd><dt>Collection</dt><dd>
                    {@product.category}
                  </dd><dt>Option</dt><dd>{if @variant, do: @variant.label, else: "Choose above"}</dd>
                </dl>
              </.accordion_content>
            </.accordion_item>
            <.accordion_item :let={item} context={context} value="care">
              <.accordion_trigger context={item}>Keep it going · Care</.accordion_trigger>
              <.accordion_content context={item}>
                <p>{care(@product.category)}</p>
              </.accordion_content>
            </.accordion_item>
            <.accordion_item :let={item} context={context} value="delivery">
              <.accordion_trigger context={item}>Delivery & the demo</.accordion_trigger>
              <.accordion_content context={item}>
                <p>
                  Standard delivery is €4.90, or free for orders of €100 or more after discounts. Express is €9.90. Choose your delivery method in the bag.
                </p>
                <p>
                  This is a working local demo: placing an order saves an order record and updates stock, but does not charge you or ship physical goods. Order history is available in this browser.
                </p>
                <.link navigate="/shop/orders">View your demo orders →</.link>
              </.accordion_content>
            </.accordion_item>
          </.accordion>
        </section>
      </div>
      <section :if={@product} class="shop-section northline-related" aria-labelledby="related-heading">
        <div class="shop-page-head">
          <div>
            <p class="shop-eyebrow">Good company</p><h2 id="related-heading">Better together</h2>
          </div><.link navigate="/shop">Explore all goods →</.link>
        </div>
        <.product_grid products={@related} shop={@shop} id="related-products" />
      </section>
    </.shell>
    """
  end
end
