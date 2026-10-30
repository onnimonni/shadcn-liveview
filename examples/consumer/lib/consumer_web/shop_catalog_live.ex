defmodule ConsumerWeb.ShopCatalogLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview
  import ConsumerWeb.ShopComponents
  import ConsumerWeb.ShopCatalogComponents, only: [product_grid: 1]
  alias Consumer.Shop.{Catalog, Store}

  @page_size 6
  @sorts [
    {"Featured", "featured"},
    {"Price: low to high", "price-asc"},
    {"Price: high to low", "price-desc"},
    {"Name: A–Z", "name"}
  ]

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
       categories: Catalog.categories(),
       sorts: @sorts,
       filters: nil,
       filter_action: nil,
       draft: %{"q" => "", "category" => "", "sort" => "featured"},
       status: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)

    same_filters =
      socket.assigns.filters == filters &&
        socket.assigns.filter_action == socket.assigns.live_action

    draft = if same_filters, do: socket.assigns.draft, else: filters
    page = positive_integer(Map.get(params, "page", "1"))

    socket =
      socket
      |> assign(
        filters: filters,
        draft: draft,
        filter_action: socket.assigns.live_action,
        page: page,
        page_title:
          if(socket.assigns.live_action == :saved,
            do: "Saved items · Northline",
            else: "The collection · Northline"
          )
      )
      |> assign(:filter_form, to_form(draft, as: :filters))
      |> results()

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter-draft", %{"filters" => params}, socket) do
    draft = normalize_filters(params, false)
    {:noreply, assign(socket, draft: draft, filter_form: to_form(draft, as: :filters))}
  end

  def handle_event("apply-filters", %{"filters" => params}, socket) do
    filters = normalize_filters(params)
    socket = assign(socket, draft: filters, filter_form: to_form(filters, as: :filters))
    {:noreply, push_patch(socket, to: catalog_path(socket.assigns.live_action, filters, 1))}
  end

  def handle_event("reset-filters", _params, socket) do
    filters = normalize_filters(%{})
    socket = assign(socket, draft: filters, filter_form: to_form(filters, as: :filters))
    {:noreply, push_patch(socket, to: catalog_path(socket.assigns.live_action, filters, 1))}
  end

  def handle_event("toggle-saved", %{"id" => id}, socket) do
    case Store.toggle_wishlist(socket.assigns.session_id, id) do
      {:ok, shop} ->
        saved = id in shop.wishlist

        message =
          if saved, do: "Added to your saved items.", else: "Removed from your saved items."

        {:noreply, socket |> assign(shop: shop, status: message) |> results() |> notify(message)}

      {:error, reason} ->
        {:noreply, assign(socket, :status, error_message(reason))}
    end
  end

  @impl true
  def handle_info({:shop_updated, session_id, shop}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, socket |> assign(:shop, shop) |> results()}
  end

  def handle_info(:inventory_updated, socket) do
    {:noreply, socket |> assign(:shop, Store.snapshot(socket.assigns.session_id)) |> results()}
  end

  defp results(socket) do
    products = Catalog.filter(socket.assigns.filters)

    products =
      if socket.assigns.live_action == :saved,
        do: Enum.filter(products, &(&1.id in socket.assigns.shop.wishlist)),
        else: products

    count = length(products)
    pages = max(div(count + @page_size - 1, @page_size), 1)
    page = min(socket.assigns.page, pages)

    assign(socket,
      products: Enum.slice(products, (page - 1) * @page_size, @page_size),
      result_count: count,
      pages: pages,
      page: page
    )
  end

  defp normalize_filters(params, trim_query \\ true) do
    category = Map.get(params, "category", "")
    sort = Map.get(params, "sort", "featured")
    query = text_query(Map.get(params, "q", ""))

    %{
      "q" => if(trim_query, do: String.trim(query), else: query),
      "category" => if(category in Catalog.categories(), do: category, else: ""),
      "sort" => if(sort in Enum.map(@sorts, &elem(&1, 1)), do: sort, else: "featured")
    }
  end

  defp text_query(value) when is_binary(value), do: String.slice(value, 0, 120)
  defp text_query(_value), do: ""

  defp positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} when number > 0 -> number
      _ -> 1
    end
  end

  defp positive_integer(_value), do: 1

  defp catalog_path(action, filters, page) do
    path = if action == :saved, do: "/shop/saved", else: "/shop"

    params =
      filters
      |> Map.put("page", to_string(page))
      |> Enum.reject(fn {key, value} ->
        value == "" || (key == "sort" && value == "featured") || (key == "page" && value == "1")
      end)

    if params == [], do: path, else: path <> "?" <> URI.encode_query(params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.shell shop={@shop} current={if @live_action == :saved, do: "saved", else: "shop"} flash={@flash}>
      <section
        :if={@live_action != :saved}
        class="northline-hero"
        aria-labelledby="collection-heading"
      >
        <div class="northline-hero-copy">
          <p class="shop-eyebrow">Less, but better · The everyday collection</p>
          <h1 id="collection-heading">Made for the<br />long way home.</h1>
          <p>
            Considered essentials for a slower rhythm. Useful shapes, honest materials, and a little room for the unexpected.
          </p>
          <a class="shop-link-button" href="#collection">Explore the collection
          <span aria-hidden="true">↘</span></a>
          <div class="northline-hero-note">
            <span aria-hidden="true">○</span> Clothing, objects & everyday companions
          </div>
        </div>
        <div class="northline-hero-art" aria-hidden="true">
          <div class="northline-hero-circle"></div>
          <img
            class="northline-hero-jacket"
            src="/assets/products/field-jacket.svg"
            alt=""
            width="640"
            height="760"
          />
          <img
            class="northline-hero-tote"
            src="/assets/products/canvas-tote.svg"
            alt=""
            width="640"
            height="760"
          />
          <span class="northline-hero-caption">NORTHLINE / EVERYDAY GOODS</span>
        </div>
      </section>
      <section
        id="collection"
        class="shop-section northline-collection"
        aria-labelledby="catalog-heading"
      >
        <div class="shop-page-head">
          <div>
            <p class="shop-eyebrow">
              {if @live_action == :saved,
                do: "A collection of your own",
                else: "Thoughtfully selected"}
            </p>
            <h1 :if={@live_action == :saved} id="catalog-heading">Your saved items</h1>
            <h2 :if={@live_action != :saved} id="catalog-heading">The everyday collection</h2>
            <p class="shop-muted">
              {if @live_action == :saved,
                do: "Keep your favorites close. Saved in this browser, ready when you are.",
                else: "Good things for the days in between."}
            </p>
          </div>
          <.link
            :if={@live_action == :saved}
            navigate="/shop"
            class="shop-link-button northline-outline-link"
          >Browse all goods</.link>
        </div>
        <.form
          for={@filter_form}
          id="catalog-filters"
          class="northline-filters"
          phx-change="filter-draft"
          phx-submit="apply-filters"
          phx-auto-recover="filter-draft"
        >
          <.form_field
            :let={attrs}
            field={@filter_form[:q]}
            label="Find your everyday essential"
            class="northline-search-field"
          >
            <.input
              {attrs}
              type="search"
              placeholder="Search goods, materials…"
              maxlength="120"
              phx-debounce="250"
            />
          </.form_field>
          <.form_field :let={attrs} field={@filter_form[:category]} label="Category">
            <.native_select :let={selection} {attrs}>
              <option value="" selected={"" in selection}>All goods</option>
              <option :for={category <- @categories} value={category} selected={category in selection}>
                {category}
              </option>
            </.native_select>
          </.form_field>
          <.form_field :let={attrs} field={@filter_form[:sort]} label="Sort by">
            <.native_select :let={selection} {attrs}>
              <option :for={{label, value} <- @sorts} value={value} selected={value in selection}>
                {label}
              </option>
            </.native_select>
          </.form_field>
          <div class="northline-filter-actions">
            <.button type="submit" phx-disable-with="Finding…">Find goods</.button>
            <.button type="button" variant="outline" phx-click="reset-filters">Clear filters</.button>
          </div>
        </.form>
        <div class="northline-results-bar">
          <p id="catalog-result-count" role="status">
            {@result_count} {if @result_count == 1, do: "essential", else: "essentials"}{if @filters[
                                                                                              "q"
                                                                                            ] != "",
                                                                                            do:
                                                                                              " matching “#{@filters["q"]}”"}
          </p>
          <span :if={@draft != @filters} class="shop-muted">Select Find goods to apply your changes.</span>
        </div>
        <p :if={@status} id="catalog-status" class="northline-status" role="status" aria-live="polite">
          {@status}
        </p>
        <.product_grid products={@products} shop={@shop} />
        <div :if={@products == []} class="shop-empty northline-empty">
          <span class="northline-empty-mark" aria-hidden="true">♡</span>
          <h3>
            {if @live_action == :saved && @shop.wishlist == [],
              do: "Make room for your favorites",
              else: "Nothing here just yet"}
          </h3>
          <p>
            {if @live_action == :saved && @shop.wishlist == [],
              do: "Tap the heart on a product to start your own collection.",
              else: "Try a different search or clear your filters to see more goods."}
          </p>
          <.link
            :if={@live_action == :saved && @shop.wishlist == []}
            navigate="/shop"
            class="shop-link-button"
          >Explore the collection</.link>
          <.button
            :if={!(@live_action == :saved && @shop.wishlist == [])}
            type="button"
            variant="outline"
            phx-click="reset-filters"
          >Show all {if @live_action == :saved, do: "saved items", else: "goods"}</.button>
        </div>
        <nav :if={@pages > 1} class="northline-pagination" aria-label="Collection pages">
          <.link
            :if={@page > 1}
            patch={catalog_path(@live_action, @filters, @page - 1)}
            class="northline-page-link"
            aria-label="Previous page"
          >← Previous</.link>
          <span :if={@page == 1} class="northline-page-disabled">← Previous</span>
          <.link
            :for={page <- 1..@pages}
            patch={catalog_path(@live_action, @filters, page)}
            class="northline-page-number"
            aria-label={"Page #{page}"}
            aria-current={if page == @page, do: "page"}
          >{page}</.link>
          <.link
            :if={@page < @pages}
            patch={catalog_path(@live_action, @filters, @page + 1)}
            class="northline-page-link"
            aria-label="Next page"
          >Next →</.link>
          <span :if={@page == @pages} class="northline-page-disabled">Next →</span>
        </nav>
      </section>
      <section
        :if={@live_action != :saved}
        class="northline-editorial"
        aria-labelledby="fewer-heading"
      >
        <p class="shop-eyebrow">The Northline approach</p>
        <h2 id="fewer-heading">Fewer things.<br />More meaning.</h2>
        <p>
          Choose what you reach for again and again. Our collection brings practical details and quiet character to the everyday.
        </p>
        <div>
          <span>01 / Honest materials</span><span>02 / Useful by design</span><span>03 / Everyday, not ordinary</span>
        </div>
      </section>
    </.shell>
    """
  end
end
