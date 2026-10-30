defmodule ConsumerWeb.ShopCatalogComponents do
  use Phoenix.Component
  use ShadcnLiveview
  import ConsumerWeb.ShopComponents, only: [money: 1]

  attr :products, :list, required: true
  attr :shop, :map, required: true
  attr :id, :string, default: "catalog-products"

  def product_grid(assigns) do
    ~H"""
    <div id={@id} class="northline-product-grid">
      <.card :for={product <- @products} class="northline-product-card" id={@id <> "-" <> product.id}>
        <div class="northline-product-art">
          <.link
            navigate={"/shop/products/" <> product.slug}
            class="northline-product-image-link"
            aria-label={"View " <> product.name}
          >
            <img src={product.image} alt={product.name} width="640" height="760" loading="lazy" />
          </.link>
          <.badge :if={product.badge} variant="secondary" class="northline-product-badge">
            {product.badge}
          </.badge>
          <.button
            type="button"
            variant="outline"
            class="northline-save"
            phx-click="toggle-saved"
            phx-value-id={product.id}
            aria-label={
              if product.id in @shop.wishlist,
                do: "Remove " <> product.name <> " from saved items",
                else: "Save " <> product.name
            }
            aria-pressed={to_string(product.id in @shop.wishlist)}
          >
            <svg
              viewBox="0 0 24 24"
              fill={if product.id in @shop.wishlist, do: "currentColor", else: "none"}
              stroke="currentColor"
              stroke-width="1.5"
              aria-hidden="true"
            >
              <path d="M20.8 4.8a5.5 5.5 0 0 0-7.8 0L12 5.9l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.4a5.5 5.5 0 0 0 0-7.8Z" />
            </svg>
          </.button>
        </div>
        <.card_content class="northline-product-copy">
          <p class="northline-product-category">{product.category}</p>
          <h3><.link navigate={"/shop/products/" <> product.slug}>{product.name}</.link></h3>
          <div class="northline-product-meta">
            <span class="shop-price">{money(product.price_cents)}</span>
            <span :if={sold_out?(product, @shop)} class="northline-stock-note">Sold out</span>
            <span :if={!sold_out?(product, @shop)} class="northline-stock-note">{variant_summary(
              product
            )}</span>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end

  def stock(variant, shop), do: Map.get(shop.stock, variant.id, variant.stock)

  def remaining(variant, shop) do
    in_cart = Enum.find(shop.cart, &(&1.variant.id == variant.id))
    quantity = if in_cart, do: in_cart.quantity, else: 0
    max(min(stock(variant, shop) - quantity, 10 - quantity), 0)
  end

  def sold_out?(product, shop), do: Enum.all?(product.variants, &(stock(&1, shop) <= 0))

  defp variant_summary(product) do
    colors = product.variants |> Enum.map(& &1.color) |> Enum.uniq() |> length()
    if colors == 1, do: "One color", else: "#{colors} colors"
  end
end
