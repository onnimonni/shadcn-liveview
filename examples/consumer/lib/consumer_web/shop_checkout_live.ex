defmodule ConsumerWeb.ShopCheckoutLive do
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  alias Consumer.Shop.{Checkout, Store}
  alias ConsumerWeb.ShopCheckoutComponents
  alias Phoenix.LiveView.JS
  import ConsumerWeb.ShopCheckoutComponents
  import ConsumerWeb.ShopComponents

  @token_salt "northline-checkout-request"

  @impl true
  def mount(_params, %{"settings_session" => session_id}, socket) do
    nonce = Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
    request_token = Phoenix.Token.sign(ConsumerWeb.Endpoint, @token_salt, {session_id, nonce})

    socket =
      socket
      |> ShopCheckoutComponents.init(session_id, "Checkout · Northline")
      |> assign(
        form: to_form(Checkout.changeset(), as: :checkout),
        countries: Checkout.countries(),
        request_token: request_token,
        checkout_error: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"checkout" => attrs}, socket) do
    changeset = Checkout.changeset(attrs) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(changeset, as: :checkout), checkout_error: nil)}
  end

  def handle_event("recover", %{"checkout" => attrs} = params, socket) do
    changeset = Checkout.changeset(attrs) |> Map.put(:action, :validate)
    socket = socket |> refresh() |> assign(:form, to_form(changeset, as: :checkout))

    socket =
      if valid_token?(params["request_token"], socket.assigns.session_id) do
        assign(socket, request_token: params["request_token"], checkout_error: nil)
      else
        assign(socket, :checkout_error, %{
          kind: :invalid_request_token,
          message:
            "Your details were recovered. Please review them before placing your demo order."
        })
      end

    {:noreply, socket}
  end

  def handle_event("set-shipping", %{"method" => method}, socket) do
    case Store.set_shipping(socket.assigns.session_id, method) do
      {:ok, snapshot} ->
        {:noreply, socket |> receive_snapshot(snapshot) |> assign(:checkout_error, nil)}

      {:error, error} ->
        {:noreply,
         socket
         |> refresh()
         |> assign(:checkout_error, %{kind: error, message: error_message(error)})}
    end
  end

  def handle_event("place-order", %{"checkout" => attrs} = params, socket) do
    token = params["request_token"]

    if valid_token?(token, socket.assigns.session_id) do
      submit_order(socket, attrs, token)
    else
      {:noreply,
       assign(socket, :checkout_error, %{
         kind: :invalid_request_token,
         message:
           "This checkout request could not be verified. Reload checkout before placing an order."
       })}
    end
  end

  defp submit_order(socket, attrs, token) do
    case Store.checkout(socket.assigns.session_id, attrs, token) do
      {:ok, order, snapshot} ->
        {:noreply,
         socket
         |> receive_snapshot(snapshot)
         |> assign(:checkout_error, nil)
         |> push_navigate(to: "/shop/orders/" <> order.id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        changeset = %{changeset | action: :insert}

        {:noreply,
         assign(socket,
           form: to_form(changeset, as: :checkout),
           checkout_error: %{
             kind: :validation,
             message: "Please correct the highlighted details. Your order has not been placed."
           }
         )}

      {:error, error} ->
        message =
          case error do
            :out_of_stock ->
              "An item in your bag no longer has enough stock. Your order has not been placed. Open your bag in another tab to reduce the quantity or remove the item, keeping this form open to retain your delivery details."

            :storage_unavailable ->
              error_message(error)

            _ ->
              error_message(error) <> " Your order has not been placed."
          end

        changeset = Checkout.changeset(attrs) |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> refresh()
         |> assign(
           form: to_form(changeset, as: :checkout),
           checkout_error: %{kind: error, message: message}
         )}
    end
  end

  defp valid_token?(token, session_id) when is_binary(token) do
    case Phoenix.Token.verify(ConsumerWeb.Endpoint, @token_salt, token, max_age: 604_800) do
      {:ok, {^session_id, nonce}} when is_binary(nonce) -> true
      _ -> false
    end
  end

  defp valid_token?(_token, _session_id), do: false

  @impl true
  def handle_info({:shop_updated, session_id, snapshot}, socket)
      when session_id == socket.assigns.session_id do
    {:noreply, receive_snapshot(socket, snapshot)}
  end

  def handle_info(:inventory_updated, socket), do: {:noreply, refresh(socket)}

  @impl true
  def render(assigns) do
    ~H"""
    <.shell shop={@shop} current="cart" title="Checkout" flash={@flash}>
      <header class="shop-page-head shop-checkout-page-head">
        <p class="shop-eyebrow">One more step</p><h1>Make it yours.</h1>
        <p class="shop-muted">
          Your delivery details, your considered essentials. No payment required.
        </p>
      </header>
      <p :if={@checkout_error} id="checkout-error" class="shop-checkout-error" role="alert">
        {@checkout_error.message}
      </p>
      <a
        :if={@checkout_error && @checkout_error.kind == :out_of_stock && @shop.cart != []}
        href="/shop/cart"
        target="_blank"
        rel="noopener"
        class="shop-text-link shop-error-action"
      >Review your bag in a new tab ↗</a>
      <.empty_cart
        :if={@shop.cart == []}
        title="There’s nothing to check out just yet."
        description="Add something you love, then return here to place your demo order."
      />
      <div :if={@shop.cart != []} class="shop-checkout-layout">
        <section class="shop-checkout-details" aria-labelledby="delivery-details-heading">
          <.link navigate="/shop/cart" class="shop-text-link shop-back-link">← Back to your bag</.link>
          <h2 id="delivery-details-heading">Delivery details</h2>
          <p class="shop-muted shop-form-intro">
            Fields marked * are required. These details are saved with your local demo order.
          </p>
          <.form
            for={@form}
            id="checkout-form"
            phx-change="validate"
            phx-submit="place-order"
            phx-auto-recover="recover"
            novalidate
          >
            <input type="hidden" name="request_token" value={@request_token} />
            <div class="shop-checkout-fields">
              <.form_field :let={attrs} field={@form[:full_name]} label="Full name" required>
                <.input {attrs} autocomplete="name" maxlength="100" />
              </.form_field>
              <.form_field
                :let={attrs}
                field={@form[:email]}
                label="Email address"
                description="Saved with your demo order. No email will be sent."
                required
              >
                <.input {attrs} type="email" autocomplete="email" maxlength="254" />
              </.form_field>
              <.form_field :let={attrs} field={@form[:address]} label="Street address" required>
                <.input {attrs} autocomplete="street-address" maxlength="200" />
              </.form_field>
              <div class="shop-field-pair">
                <.form_field :let={attrs} field={@form[:city]} label="City" required>
                  <.input {attrs} autocomplete="address-level2" maxlength="100" />
                </.form_field>
                <.form_field :let={attrs} field={@form[:postal_code]} label="Postal code" required>
                  <.input {attrs} autocomplete="postal-code" maxlength="20" />
                </.form_field>
              </div>
              <.form_field :let={attrs} field={@form[:country]} label="Country" required>
                <.native_select :let={selection} {attrs} autocomplete="country">
                  <option value="" selected={"" in selection or selection == []}>
                    Choose a country
                  </option>
                  <option :for={{label, code} <- @countries} value={code} selected={code in selection}>
                    {label}
                  </option>
                </.native_select>
              </.form_field>
              <.form_field :let={attrs} field={@form[:phone]} label="Phone (optional)">
                <.input {attrs} type="tel" autocomplete="tel" maxlength="40" />
              </.form_field>
              <.form_field
                :let={attrs}
                field={@form[:delivery_notes]}
                label="Delivery notes (optional)"
                description="Anything helpful to keep with this demo order."
              >
                <.textarea {attrs} rows="3" maxlength="500" />
              </.form_field>
              <.form_field
                :let={attrs}
                field={@form[:terms]}
                label="I understand this is a local demo order."
                description="No payment is taken and no goods are dispatched. My delivery details will be stored locally for this browser’s order history."
                orientation="horizontal"
                class="shop-terms-field"
                required
              >
                <.checkbox {attrs} />
              </.form_field>
            </div>
            <.button
              id="place-demo-order"
              type="submit"
              class="shop-place-order"
              phx-disable-with="Saving your order…"
              phx-disconnected={JS.set_attribute({"disabled", "disabled"})}
              phx-connected={JS.remove_attribute("disabled")}
            >Place demo order · {money(@shop.total_cents)}</.button>
            <p class="shop-muted shop-recovery-note">
              Unsaved form edits are recovered if the connection drops and reconnects without a page reload.
            </p>
          </.form>
        </section>
        <aside class="shop-checkout-sidebar" aria-labelledby="checkout-summary-heading">
          <.card class="shop-summary-card">
            <.card_header>
              <h2 id="checkout-summary-heading">Your selection</h2><p class="shop-muted">
                {@shop.cart_count} {if @shop.cart_count == 1, do: "item", else: "items"}
              </p>
            </.card_header>
            <.card_content>
              <.purchased_lines lines={@shop.cart} compact />
              <.shipping_choice shop={@shop} id="checkout-shipping" />
              <p :if={@shop.coupon} class="shop-discount">
                <.badge variant="secondary">{@shop.coupon} applied</.badge>
              </p>
              <.totals shop={@shop} id="checkout-totals" />
              <.link navigate="/shop/cart" class="shop-text-link">Edit your bag or discount code</.link>
            </.card_content>
          </.card>
          <.demo_notice />
        </aside>
      </div>
    </.shell>
    """
  end
end
