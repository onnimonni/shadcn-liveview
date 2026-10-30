defmodule Consumer.Shop.Store do
  @moduledoc """
  Single-node demo commerce state owned by signed browser sessions.

  One GenServer serializes stock checks and checkout. A single DETS record keeps
  inventory, browser state, orders, and checkout receipts together; every write
  is synced before returning success or notifying subscribers. Carts do not
  reserve inventory. All prices and order lines come from the server catalog.
  """
  use GenServer

  alias Consumer.Shop.{Catalog, Checkout}

  @customer_fields [
    :full_name,
    :email,
    :address,
    :city,
    :postal_code,
    :country,
    :phone,
    :delivery_notes,
    :terms
  ]

  def start_link(opts \\ []) do
    case Keyword.get(opts, :name, __MODULE__) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  def topic(session_id), do: "shop:session:#{session_id}"
  def inventory_topic, do: "shop:inventory"

  def snapshot(session_id, server \\ __MODULE__),
    do: GenServer.call(server, {:snapshot, session_id})

  def add_item(session_id, product_id, variant_id, quantity, server \\ __MODULE__),
    do: mutate(server, session_id, {:add_item, product_id, variant_id, quantity})

  def update_quantity(session_id, variant_id, quantity, server \\ __MODULE__),
    do: mutate(server, session_id, {:update_quantity, variant_id, quantity})

  def remove_item(session_id, variant_id, server \\ __MODULE__),
    do: mutate(server, session_id, {:remove_item, variant_id})

  def apply_coupon(session_id, code, server \\ __MODULE__),
    do: mutate(server, session_id, {:apply_coupon, code})

  def set_shipping(session_id, method, server \\ __MODULE__),
    do: mutate(server, session_id, {:set_shipping, method})

  def toggle_wishlist(session_id, product_id, server \\ __MODULE__),
    do: mutate(server, session_id, {:toggle_wishlist, product_id})

  def checkout(session_id, attrs, request_id, server \\ __MODULE__),
    do: GenServer.call(server, {:checkout, session_id, attrs, request_id})

  def order(session_id, order_id, server \\ __MODULE__),
    do: GenServer.call(server, {:order, session_id, order_id})

  defp mutate(server, session_id, operation),
    do: GenServer.call(server, {:mutate, session_id, operation})

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    storage =
      Keyword.get_lazy(opts, :storage, fn ->
        Application.get_env(:consumer, :shop_storage) || default_storage()
      end)

    case open_storage(storage) do
      {:ok, storage, data} -> {:ok, %{storage: storage, data: data, writable?: true}}
      {:error, reason} -> {:stop, {:shop_storage, reason}}
    end
  end

  @impl true
  def handle_call({:snapshot, session_id}, _from, state) do
    if valid_session?(session_id) do
      {:reply, build_snapshot(state.data, session_id), state}
    else
      {:reply, {:error, :invalid_session}, state}
    end
  end

  def handle_call({:order, session_id, order_id}, _from, state) do
    order =
      if valid_session?(session_id) and is_binary(order_id),
        do: find_order(session(state.data, session_id), order_id)

    {:reply, order, state}
  end

  def handle_call({:mutate, session_id, operation}, _from, state) do
    with :ok <- validate_session(session_id),
         :ok <- writable(state),
         {:ok, updated} <-
           apply_mutation(session(state.data, session_id), operation, state.data.stock) do
      data = put_session(state.data, session_id, updated)
      commit(state, data, session_id, false)
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:checkout, session_id, attrs, request_id}, _from, state) do
    with :ok <- validate_session(session_id),
         :ok <- validate_request_id(request_id) do
      current = session(state.data, session_id)

      case Map.get(current.requests, request_id) do
        nil ->
          place_order(state, session_id, current, attrs, request_id)

        order_id ->
          {:reply, {:ok, find_order(current, order_id), build_snapshot(state.data, session_id)},
           state}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def terminate(_reason, %{storage: {:dets, table}}), do: :dets.close(table)
  def terminate(_reason, _state), do: :ok

  defp apply_mutation(current, {:add_item, product_id, variant_id, quantity}, stock) do
    with :ok <- validate_quantity(quantity),
         {:ok, product} <- fetch_product(product_id),
         {:ok, _variant} <- fetch_variant(product, variant_id) do
      existing = Enum.find(current.cart, &(&1.variant_id == variant_id))
      final_quantity = quantity + if(existing, do: existing.quantity, else: 0)

      with :ok <- validate_quantity(final_quantity),
           :ok <- available(stock, variant_id, final_quantity) do
        line = %{product_id: product_id, variant_id: variant_id, quantity: final_quantity}

        cart =
          if existing,
            do:
              Enum.map(current.cart, fn item ->
                if item.variant_id == variant_id, do: line, else: item
              end),
            else: current.cart ++ [line]

        {:ok, %{current | cart: cart}}
      end
    end
  end

  defp apply_mutation(current, {:update_quantity, variant_id, quantity}, stock) do
    with :ok <- validate_quantity(quantity),
         {:ok, _line} <- fetch_cart_line(current, variant_id),
         :ok <- available(stock, variant_id, quantity) do
      cart =
        Enum.map(current.cart, fn item ->
          if item.variant_id == variant_id, do: %{item | quantity: quantity}, else: item
        end)

      {:ok, %{current | cart: cart}}
    end
  end

  defp apply_mutation(current, {:remove_item, variant_id}, _stock) do
    with {:ok, _line} <- fetch_cart_line(current, variant_id) do
      {:ok, %{current | cart: Enum.reject(current.cart, &(&1.variant_id == variant_id))}}
    end
  end

  defp apply_mutation(current, {:apply_coupon, code}, _stock) when is_binary(code) do
    case code |> String.trim() |> String.upcase() do
      "" -> {:ok, %{current | coupon: nil}}
      "WELCOME10" -> {:ok, %{current | coupon: "WELCOME10"}}
      _code -> {:error, :invalid_coupon}
    end
  end

  defp apply_mutation(_current, {:apply_coupon, _code}, _stock), do: {:error, :invalid_coupon}

  defp apply_mutation(current, {:set_shipping, method}, _stock)
       when method in ["standard", "express"],
       do: {:ok, %{current | shipping_method: method}}

  defp apply_mutation(_current, {:set_shipping, _method}, _stock), do: {:error, :invalid_shipping}

  defp apply_mutation(current, {:toggle_wishlist, product_id}, _stock) do
    with {:ok, _product} <- fetch_product(product_id) do
      wishlist =
        if product_id in current.wishlist,
          do: List.delete(current.wishlist, product_id),
          else: current.wishlist ++ [product_id]

      {:ok, %{current | wishlist: wishlist}}
    end
  end

  defp place_order(state, session_id, current, attrs, request_id) do
    with :ok <- writable(state),
         :ok <- nonempty_cart(current),
         {:ok, customer} <- attrs |> Checkout.changeset() |> Ecto.Changeset.apply_action(:insert),
         :ok <- check_inventory(current.cart, state.data.stock) do
      snapshot = build_snapshot(state.data, session_id)

      order = %{
        id: Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false),
        number: "NL-" <> String.pad_leading(Integer.to_string(state.data.next_order), 6, "0"),
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
        status: "confirmed",
        lines: snapshot.cart,
        customer: Map.take(customer, @customer_fields),
        subtotal_cents: snapshot.subtotal_cents,
        discount_cents: snapshot.discount_cents,
        shipping_cents: snapshot.shipping_cents,
        total_cents: snapshot.total_cents,
        shipping_method: snapshot.shipping_method,
        payment_method: "demo"
      }

      stock =
        Enum.reduce(current.cart, state.data.stock, fn line, inventory ->
          Map.update!(inventory, line.variant_id, &(&1 - line.quantity))
        end)

      updated = %{
        current
        | cart: [],
          coupon: nil,
          orders: [order | current.orders],
          requests: Map.put(current.requests, request_id, order.id)
      }

      data =
        state.data
        |> put_session(session_id, updated)
        |> Map.put(:stock, stock)
        |> Map.update!(:next_order, &(&1 + 1))

      commit(state, data, session_id, true, order)
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp commit(state, data, session_id, inventory_changed?, order \\ nil) do
    case persist(state.storage, data) do
      :ok ->
        snapshot = build_snapshot(data, session_id)

        Phoenix.PubSub.broadcast(
          Consumer.PubSub,
          topic(session_id),
          {:shop_updated, session_id, snapshot}
        )

        if inventory_changed?,
          do: Phoenix.PubSub.broadcast(Consumer.PubSub, inventory_topic(), :inventory_updated)

        result = if order, do: {:ok, order, snapshot}, else: {:ok, snapshot}
        {:reply, result, %{state | data: data}}

      {:error, _reason} ->
        # A failed sync must not become an acknowledged write. Restore the last
        # committed record; if storage remains broken, reject further writes.
        writable? = persist(state.storage, state.data) == :ok
        {:reply, {:error, :storage_unavailable}, %{state | writable?: writable?}}
    end
  end

  defp build_snapshot(data, session_id) do
    current = session(data, session_id)

    cart =
      Enum.map(current.cart, fn item ->
        product = Catalog.get(item.product_id)
        variant = Enum.find(product.variants, &(&1.id == item.variant_id))

        %{
          product: product,
          variant: %{variant | stock: Map.fetch!(data.stock, item.variant_id)},
          quantity: item.quantity,
          unit_price_cents: product.price_cents,
          line_total_cents: product.price_cents * item.quantity
        }
      end)

    {subtotal, count} =
      Enum.reduce(cart, {0, 0}, fn line, {subtotal, count} ->
        {subtotal + line.line_total_cents, count + line.quantity}
      end)

    discount = if current.coupon == "WELCOME10", do: div(subtotal * 10, 100), else: 0
    shipping = shipping_cost(current.shipping_method, subtotal - discount, count)

    %{
      cart: cart,
      cart_count: count,
      subtotal_cents: subtotal,
      discount_cents: discount,
      shipping_cents: shipping,
      total_cents: subtotal - discount + shipping,
      coupon: current.coupon,
      shipping_method: current.shipping_method,
      wishlist: current.wishlist,
      stock: data.stock,
      orders: current.orders,
      revision: current.revision
    }
  end

  defp shipping_cost(_method, _discounted_subtotal, 0), do: 0
  defp shipping_cost("express", _discounted_subtotal, _count), do: 990

  defp shipping_cost("standard", discounted_subtotal, _count) when discounted_subtotal >= 10_000,
    do: 0

  defp shipping_cost("standard", _discounted_subtotal, _count), do: 490

  defp session(data, session_id) do
    Map.get(data.sessions, session_id, %{
      cart: [],
      coupon: nil,
      shipping_method: "standard",
      wishlist: [],
      orders: [],
      requests: %{},
      revision: 0
    })
  end

  defp put_session(data, session_id, current) do
    current = %{current | revision: current.revision + 1}
    %{data | sessions: Map.put(data.sessions, session_id, current)}
  end

  defp find_order(current, order_id), do: Enum.find(current.orders, &(&1.id == order_id))

  defp fetch_product(product_id) do
    case Catalog.get(product_id) do
      nil -> {:error, :product_not_found}
      product -> {:ok, product}
    end
  end

  defp fetch_variant(product, variant_id) do
    case Enum.find(product.variants, &(&1.id == variant_id)) do
      nil -> {:error, :variant_not_found}
      variant -> {:ok, variant}
    end
  end

  defp fetch_cart_line(current, variant_id) do
    case Enum.find(current.cart, &(&1.variant_id == variant_id)) do
      nil -> {:error, :item_not_found}
      line -> {:ok, line}
    end
  end

  defp available(stock, variant_id, quantity) do
    if Map.get(stock, variant_id, 0) >= quantity, do: :ok, else: {:error, :out_of_stock}
  end

  defp check_inventory(cart, stock) do
    Enum.reduce_while(cart, :ok, fn line, :ok ->
      case available(stock, line.variant_id, line.quantity) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp nonempty_cart(%{cart: []}), do: {:error, :empty_cart}
  defp nonempty_cart(_current), do: :ok

  defp validate_quantity(quantity) when not is_integer(quantity) or quantity < 1,
    do: {:error, :invalid_quantity}

  defp validate_quantity(quantity) when quantity > 10, do: {:error, :quantity_limit}
  defp validate_quantity(_quantity), do: :ok

  defp valid_session?(session_id),
    do: is_binary(session_id) and byte_size(session_id) in 1..256

  defp validate_session(session_id),
    do: if(valid_session?(session_id), do: :ok, else: {:error, :invalid_session})

  defp validate_request_id(request_id)
       when is_binary(request_id) and byte_size(request_id) in 1..4096,
       do: :ok

  defp validate_request_id(_request_id), do: {:error, :invalid_request_id}
  defp writable(%{writable?: true}), do: :ok
  defp writable(_state), do: {:error, :storage_unavailable}

  defp default_storage do
    root = System.get_env("XDG_DATA_HOME") || Path.join(System.user_home!(), ".local/share")
    Path.join(root, "shadcn-consumer/shop.dets")
  end

  defp initial_data do
    stock =
      for product <- Catalog.all(),
          variant <- product.variants,
          into: %{},
          do: {variant.id, variant.stock}

    %{version: 1, stock: stock, sessions: %{}, next_order: 1}
  end

  defp open_storage(:memory), do: {:ok, :memory, initial_data()}

  defp open_storage(path) when is_binary(path) and byte_size(path) > 0 do
    table = {__MODULE__, make_ref()}

    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, ^table} <- :dets.open_file(table, file: String.to_charlist(path), type: :set) do
      case load_data(table) do
        {:ok, data} ->
          {:ok, {:dets, table}, data}

        {:error, reason} ->
          :dets.close(table)
          {:error, reason}
      end
    end
  end

  defp open_storage(_storage), do: {:error, :invalid_storage}

  defp load_data(table) do
    case :dets.lookup(table, :shop_state) do
      [] ->
        data = initial_data()

        case persist({:dets, table}, data) do
          :ok -> {:ok, data}
          error -> error
        end

      [{:shop_state, %{version: 1, stock: stock, sessions: sessions, next_order: number} = data}]
      when is_map(stock) and is_map(sessions) and is_integer(number) and number > 0 ->
        {:ok, data}

      {:error, reason} ->
        {:error, reason}

      _data ->
        {:error, :invalid_shop_data}
    end
  end

  defp persist(:memory, _data), do: :ok

  defp persist({:dets, table}, data) do
    try do
      with :ok <- :dets.insert(table, {:shop_state, data}),
           :ok <- :dets.sync(table),
           do: :ok
    catch
      kind, reason -> {:error, {kind, reason}}
    end
  end
end
