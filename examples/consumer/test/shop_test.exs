defmodule Consumer.ShopTest do
  use ExUnit.Case, async: false

  alias Consumer.Shop.{Checkout, Store}

  setup do
    store = start_supervised!({Store, name: nil, storage: :memory})
    unique = System.unique_integer([:positive, :monotonic])
    %{store: store, owner: "shop-test-#{unique}-a", other: "shop-test-#{unique}-b"}
  end

  test "concurrent checkout can sell the final unit only once, without partial stock changes",
       ctx do
    for session <- [ctx.owner, ctx.other] do
      assert {:ok, _} =
               Store.add_item(session, "weekend-duffel", "weekend-duffel-midnight", 1, ctx.store)

      assert {:ok, _} = Store.add_item(session, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)
    end

    results =
      [ctx.owner, ctx.other]
      |> Enum.map(fn session ->
        Task.async(fn ->
          {session, Store.checkout(session, valid_attrs(), "final-stock-#{session}", ctx.store)}
        end)
      end)
      |> Enum.map(&Task.await/1)

    assert [{winner, {:ok, order, _}}] =
             Enum.filter(results, fn {_session, result} -> match?({:ok, _, _}, result) end)

    assert [{loser, {:error, :out_of_stock}}] =
             Enum.filter(results, fn {_session, result} -> match?({:error, _}, result) end)

    winner_shop = Store.snapshot(winner, ctx.store)
    loser_shop = Store.snapshot(loser, ctx.store)
    assert winner_shop.stock["weekend-duffel-midnight"] == 0
    assert winner_shop.stock["ceramic-mug-chalk"] == 7
    assert loser_shop.stock == winner_shop.stock
    assert winner_shop.cart_count == 0
    assert winner_shop.orders == [order]
    assert loser_shop.cart_count == 2
    assert loser_shop.orders == []
    assert loser_shop.revision == 2
    assert Store.order(loser, order.id, ctx.store) == nil

    assert {:error, :out_of_stock} =
             Store.update_quantity(loser, "weekend-duffel-midnight", 1, ctx.store)

    assert {:ok, shop} = Store.remove_item(loser, "weekend-duffel-midnight", ctx.store)
    assert shop.cart_count == 1
  end

  test "concurrent duplicate tokens return one order and replay does not consume a later cart",
       ctx do
    assert {:ok, _} =
             Store.add_item(ctx.owner, "canvas-tote", "canvas-tote-natural", 2, ctx.store)

    assert {:ok, _} = Store.apply_coupon(ctx.owner, "WELCOME10", ctx.store)

    results =
      1..2
      |> Enum.map(fn _ ->
        Task.async(fn -> Store.checkout(ctx.owner, valid_attrs(), "same-token", ctx.store) end)
      end)
      |> Enum.map(&Task.await/1)

    assert [{:ok, first, first_shop}, {:ok, duplicate, duplicate_shop}] = results
    assert duplicate == first
    assert duplicate_shop == first_shop
    assert first_shop.stock["canvas-tote-natural"] == 7
    assert first_shop.orders == [first]
    assert first_shop.revision == 3
    assert first_shop.cart == []
    assert first_shop.coupon == nil

    assert {:ok, later_shop} =
             Store.add_item(ctx.owner, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)

    assert {:ok, ^first, ^later_shop} = Store.checkout(ctx.owner, %{}, "same-token", ctx.store)
    assert Store.snapshot(ctx.owner, ctx.store) == later_shop
    assert later_shop.stock["ceramic-mug-chalk"] == 8
  end

  test "prices, discounts, and delivery are server authoritative integer cents", ctx do
    assert {:ok, shop} =
             Store.add_item(ctx.owner, "wool-beanie", "wool-beanie-moss", 3, ctx.store)

    assert shop.subtotal_cents == 10_500
    assert shop.shipping_cents == 0
    assert shop.total_cents == 10_500

    assert {:ok, shop} = Store.apply_coupon(ctx.owner, "  welcome10  ", ctx.store)
    assert shop.coupon == "WELCOME10"
    assert shop.discount_cents == 1_050
    assert shop.shipping_cents == 490
    assert shop.total_cents == 9_940

    assert {:ok, shop} = Store.set_shipping(ctx.owner, "express", ctx.store)
    assert shop.shipping_cents == 990
    assert shop.total_cents == 10_440
    assert {:error, :invalid_shipping} = Store.set_shipping(ctx.owner, "free", ctx.store)
    assert {:error, :invalid_coupon} = Store.apply_coupon(ctx.owner, "FREE100", ctx.store)
    assert Store.snapshot(ctx.owner, ctx.store) == shop

    assert {:ok, shop} = Store.update_quantity(ctx.owner, "wool-beanie-moss", 4, ctx.store)
    assert shop.discount_cents == 1_400
    assert shop.shipping_cents == 990
    assert shop.total_cents == 13_590
    assert {:ok, shop} = Store.set_shipping(ctx.owner, "standard", ctx.store)
    assert shop.shipping_cents == 0
    assert shop.total_cents == 12_600
    assert {:ok, shop} = Store.apply_coupon(ctx.owner, "  ", ctx.store)
    assert shop.coupon == nil
    assert shop.discount_cents == 0
    assert shop.total_cents == 14_000
    assert {:ok, _} = Store.apply_coupon(ctx.owner, "WELCOME10", ctx.store)

    attrs =
      Map.merge(valid_attrs(), %{
        "unit_price_cents" => 1,
        "subtotal_cents" => 1,
        "discount_cents" => 99_999,
        "shipping_method" => "express",
        "payment_method" => "card",
        "stock" => %{"wool-beanie-moss" => 1_000}
      })

    assert {:ok, order, empty} = Store.checkout(ctx.owner, attrs, "price-check", ctx.store)
    assert order.subtotal_cents == 14_000
    assert order.discount_cents == 1_400
    assert order.shipping_cents == 0
    assert order.total_cents == 12_600
    assert order.shipping_method == "standard"
    assert order.payment_method == "demo"
    assert [%{quantity: 4, unit_price_cents: 3_500, line_total_cents: 14_000}] = order.lines
    assert empty.cart_count == 0
    assert empty.coupon == nil
    assert empty.subtotal_cents == 0
    assert empty.shipping_cents == 0
    assert empty.total_cents == 0
  end

  test "cart quantities are bounded by both the line limit and available variant stock", ctx do
    for quantity <- [0, -1, "2", 1.5, nil] do
      assert {:error, :invalid_quantity} =
               Store.add_item(
                 ctx.owner,
                 "everyday-tee",
                 "everyday-tee-chalk-medium",
                 quantity,
                 ctx.store
               )
    end

    assert {:error, :quantity_limit} =
             Store.add_item(ctx.owner, "everyday-tee", "everyday-tee-chalk-medium", 11, ctx.store)

    assert {:error, :product_not_found} =
             Store.add_item(ctx.owner, "unknown", "unknown", 1, ctx.store)

    assert {:error, :variant_not_found} =
             Store.add_item(ctx.owner, "everyday-tee", "canvas-tote-natural", 1, ctx.store)

    assert {:error, :out_of_stock} =
             Store.add_item(ctx.owner, "brass-keyring", "brass-keyring-brass", 1, ctx.store)

    assert {:error, :out_of_stock} =
             Store.add_item(ctx.owner, "weekend-duffel", "weekend-duffel-midnight", 2, ctx.store)

    assert Store.snapshot(ctx.owner, ctx.store).cart_count == 0

    assert {:ok, shop} =
             Store.add_item(ctx.owner, "everyday-tee", "everyday-tee-chalk-medium", 10, ctx.store)

    assert shop.cart_count == 10

    assert {:error, :quantity_limit} =
             Store.add_item(ctx.owner, "everyday-tee", "everyday-tee-chalk-medium", 1, ctx.store)

    assert {:error, :invalid_quantity} =
             Store.update_quantity(ctx.owner, "everyday-tee-chalk-medium", 0, ctx.store)

    assert {:error, :item_not_found} =
             Store.update_quantity(ctx.owner, "ceramic-mug-chalk", 1, ctx.store)

    assert {:error, :item_not_found} =
             Store.remove_item(ctx.owner, "ceramic-mug-chalk", ctx.store)

    assert Store.snapshot(ctx.owner, ctx.store) == shop
    assert {:ok, empty} = Store.remove_item(ctx.owner, "everyday-tee-chalk-medium", ctx.store)
    assert empty.cart == []
    assert empty.shipping_cents == 0
    assert {:error, :empty_cart} = Store.checkout(ctx.owner, valid_attrs(), "empty", ctx.store)
  end

  test "orders, checkout tokens, and browser notifications never cross session ownership", ctx do
    Phoenix.PubSub.subscribe(Consumer.PubSub, Store.topic(ctx.owner))
    Phoenix.PubSub.subscribe(Consumer.PubSub, Store.topic(ctx.other))
    Phoenix.PubSub.subscribe(Consumer.PubSub, Store.inventory_topic())

    assert {:ok, shop} =
             Store.add_item(ctx.owner, "everyday-tee", "everyday-tee-chalk-small", 1, ctx.store)

    assert_receive {:shop_updated, owner, ^shop}
    assert owner == ctx.owner
    other_session = ctx.other
    refute_receive {:shop_updated, ^other_session, _}
    refute_receive :inventory_updated

    assert {:ok, _} = Store.toggle_wishlist(ctx.owner, "linen-throw", ctx.store)
    assert Store.snapshot(ctx.other, ctx.store).wishlist == []
    assert Store.snapshot(ctx.other, ctx.store).cart == []

    assert {:error, :empty_cart} =
             Store.checkout(
               ctx.other,
               Map.put(valid_attrs(), "session_id", ctx.owner),
               "shared-token",
               ctx.store
             )

    assert {:ok, order, shop} =
             Store.checkout(ctx.owner, valid_attrs(), "shared-token", ctx.store)

    assert_receive {:shop_updated, owner, ^shop}
    assert owner == ctx.owner
    assert_receive :inventory_updated
    refute_receive {:shop_updated, ^other_session, _}
    assert Store.order(ctx.owner, order.id, ctx.store) == order
    assert Store.order(ctx.other, order.id, ctx.store) == nil
    assert Store.order(nil, order.id, ctx.store) == nil
    assert Store.order(ctx.owner, "not-an-order", ctx.store) == nil
    assert Store.snapshot(ctx.other, ctx.store).orders == []

    assert {:ok, _} = Store.add_item(ctx.other, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)

    assert {:ok, other_order, _} =
             Store.checkout(ctx.other, valid_attrs(), "shared-token", ctx.store)

    refute other_order.id == order.id
    assert Store.order(ctx.owner, other_order.id, ctx.store) == nil

    assert {:error, :invalid_session} =
             Store.add_item(nil, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)

    assert {:error, :invalid_session} = Store.snapshot("", ctx.store)
    assert {:error, :invalid_request_id} = Store.checkout(ctx.owner, valid_attrs(), "", ctx.store)
  end

  test "invalid shipping details and unaccepted terms leave the cart and stock unchanged", ctx do
    assert {:ok, original} =
             Store.add_item(ctx.owner, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)

    attrs = %{
      "full_name" => "A",
      "email" => "not-an-email",
      "address" => "x",
      "city" => "x",
      "postal_code" => "x",
      "country" => "US",
      "phone" => "not a phone",
      "delivery_notes" => String.duplicate("x", 501),
      "terms" => "false"
    }

    assert {:error, changeset} = Store.checkout(ctx.owner, attrs, "invalid-fields", ctx.store)
    assert %Ecto.Changeset{valid?: false, action: :insert} = changeset

    for field <- [
          :full_name,
          :email,
          :address,
          :city,
          :postal_code,
          :country,
          :phone,
          :delivery_notes,
          :terms
        ] do
      assert Keyword.has_key?(changeset.errors, field)
    end

    assert Store.snapshot(ctx.owner, ctx.store) == original

    assert {:error, %Ecto.Changeset{}} =
             Store.checkout(ctx.owner, %{email: %{}}, "malformed-fields", ctx.store)

    assert Store.snapshot(ctx.owner, ctx.store) == original

    assert {:error, :invalid_request_id} =
             Store.checkout(ctx.owner, valid_attrs(), nil, ctx.store)

    assert Store.snapshot(ctx.owner, ctx.store) == original

    for attrs <- [Map.delete(valid_attrs(), "terms"), Map.put(valid_attrs(), "terms", "false")] do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Store.checkout(ctx.owner, attrs, "unaccepted-terms", ctx.store)

      assert Keyword.has_key?(changeset.errors, :terms)
      assert Store.snapshot(ctx.owner, ctx.store) == original
    end

    for {country, postal_code} <- [
          {"FI", "00100"},
          {"SE", "111 22"},
          {"DK", "1050"},
          {"DE", "10115"},
          {"NL", "1012 AB"}
        ] do
      attrs = Map.merge(valid_attrs(), %{"country" => country, "postal_code" => postal_code})
      assert Checkout.changeset(attrs).valid?
    end

    refute Checkout.changeset(Map.put(valid_attrs(), "postal_code", "ABCDE")).valid?

    assert {:ok, customer} =
             valid_attrs()
             |> Map.put("email", "  ALEX@EXAMPLE.COM  ")
             |> Checkout.changeset()
             |> Ecto.Changeset.apply_action(:insert)

    assert customer.email == "alex@example.com"
    assert customer.phone == nil
    assert customer.terms
    assert Enum.map(Checkout.countries(), &elem(&1, 1)) == ["FI", "SE", "DK", "DE", "NL"]
  end

  test "checkout preserves unused input tracking without weakening submit validation", ctx do
    assert {:ok, original} =
             Store.add_item(ctx.owner, "ceramic-mug", "ceramic-mug-chalk", 1, ctx.store)

    fields = Checkout.__schema__(:fields)
    unused_fields = fields -- [:full_name]
    unused_keys = Enum.map(unused_fields, &("_unused_" <> Atom.to_string(&1)))

    attrs =
      fields
      |> Map.new(&{Atom.to_string(&1), ""})
      |> Map.put("full_name", " A ")
      |> Map.merge(Map.new(unused_keys, &{&1, ""}))

    changeset = attrs |> Checkout.changeset() |> Map.put(:action, :validate)
    form = Phoenix.Component.to_form(changeset, as: :checkout)

    refute changeset.valid?
    assert form[:full_name].value == "A"
    assert form[:full_name].errors != []
    assert Phoenix.Component.used_input?(form[:full_name])

    for field <- unused_fields do
      refute Phoenix.Component.used_input?(form[field])
    end

    for field <- [:email, :address, :city, :postal_code, :terms] do
      assert form[field].errors != []
    end

    assert {:error, %Ecto.Changeset{valid?: false}} =
             Store.checkout(ctx.owner, attrs, "unused-required-fields", ctx.store)

    assert Store.snapshot(ctx.owner, ctx.store) == original

    # An ordinary LiveView submit includes every field without unused markers.
    submitted_attrs = Map.drop(attrs, unused_keys)

    assert {:error, %Ecto.Changeset{valid?: false, action: :insert} = submitted_changeset} =
             Store.checkout(ctx.owner, submitted_attrs, "submitted-required-fields", ctx.store)

    submitted_form = Phoenix.Component.to_form(submitted_changeset, as: :checkout)

    for field <- fields do
      assert Phoenix.Component.used_input?(submitted_form[field])
    end

    for field <- [:full_name, :email, :address, :city, :postal_code, :terms] do
      assert submitted_form[field].errors != []
    end

    assert Store.snapshot(ctx.owner, ctx.store) == original
  end

  test "closing and reopening DETS preserves inventory, carts, saved items, orders, and replay receipts",
       ctx do
    directory =
      Path.join(
        System.tmp_dir!(),
        "northline-shop-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    path = Path.join(directory, "shop.dets")
    on_exit(fn -> File.rm_rf!(directory) end)
    child = Supervisor.child_spec({Store, name: nil, storage: path}, id: :shop_disk)
    disk = start_supervised!(child)

    assert {:ok, _} = Store.add_item(ctx.owner, "ceramic-mug", "ceramic-mug-chalk", 2, disk)
    assert {:ok, _} = Store.apply_coupon(ctx.owner, "WELCOME10", disk)
    assert {:ok, _} = Store.set_shipping(ctx.owner, "express", disk)
    assert {:ok, order, _} = Store.checkout(ctx.owner, valid_attrs(), "durable-token", disk)

    assert {:ok, _} =
             Store.add_item(ctx.owner, "everyday-tee", "everyday-tee-chalk-medium", 3, disk)

    assert {:ok, _} = Store.apply_coupon(ctx.owner, "WELCOME10", disk)
    assert {:ok, expected} = Store.toggle_wishlist(ctx.owner, "linen-throw", disk)
    assert {:ok, other_expected} = Store.toggle_wishlist(ctx.other, "weekend-duffel", disk)
    assert expected.stock["ceramic-mug-chalk"] == 6
    assert expected.orders == [order]
    stop_supervised!(:shop_disk)

    reopened = start_supervised!(child)
    assert Store.snapshot(ctx.owner, reopened) == expected
    assert Store.snapshot(ctx.other, reopened) == other_expected
    assert Store.order(ctx.owner, order.id, reopened) == order
    assert Store.order(ctx.other, order.id, reopened) == nil
    assert {:ok, ^order, ^expected} = Store.checkout(ctx.owner, %{}, "durable-token", reopened)
    assert Store.snapshot(ctx.owner, reopened) == expected
    stop_supervised!(:shop_disk)
  end

  defp valid_attrs do
    %{
      "full_name" => "Alex Morgan",
      "email" => "alex@example.com",
      "address" => "Example Street 12",
      "city" => "Helsinki",
      "postal_code" => "00100",
      "country" => "FI",
      "phone" => "",
      "delivery_notes" => "Leave by the door",
      "terms" => "true"
    }
  end
end
