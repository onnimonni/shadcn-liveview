defmodule ConsumerWeb.SettingsBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility

  @moduletag :browser_test
  @moduletag browser_context_opts: [viewport: %{width: 390, height: 844}]

  for mode <- ["direct", "component"] do
    test "#{mode}: settings survive validation, save, reset, server patches, reconnect and reload",
         %{conn: conn} do
      settings_flow(conn, unquote(mode))
    end
  end

  defp settings_flow(conn, mode) do
    prefix = "settings-#{mode}"
    route = if mode == "direct", do: "/settings", else: "/settings/component"
    email = "##{prefix}_email"
    notify = "##{prefix}_notifications"
    dialog = "[role=dialog]"
    address = "#{mode}@example.com"
    bio = "A real LiveView consumer <script>not executable</script>"
    saved = fn field -> "##{prefix}-result [data-saved=#{field}]" end

    conn =
      conn
      |> visit(route)
      |> assert_has("[data-phx-main].phx-connected")
      |> refute_has("##{prefix}-form [role=alert]")
      |> snapshot(prefix <> "-initial")
      |> fill_in("Email", with: "invalid", exact: false)
      |> assert_has(email <> "[aria-invalid=true]")
      |> assert_has("##{prefix}_email-errors")
      |> assert_has(email <> "[aria-describedby~='#{prefix}_email-errors']")
      |> assert_has("label[for='#{prefix}_email']")
      |> snapshot(prefix <> "-invalid")
      |> fill_in("Email", with: address, exact: false)
      |> fill_in("Display name", with: "Onni #{mode}", exact: false)
      |> select("Timezone", option: "Europe/Helsinki", exact: false)
      |> fill_in("Bio", with: bio, exact: true)
      |> unchecked(notify)
      |> assert_has(notify <> "[aria-checked=false]")
      |> click_button("Review and save")
      |> assert_has(dialog, text: "Confirm settings save")
      |> snapshot(prefix <> "-confirm-dialog")
      |> press(dialog, "Escape")
      |> refute_has(dialog)
      |> assert_has("##{prefix}-save:focus")
      |> click_button("Review and save")
      |> assert_has(dialog, text: "Confirm settings save")
      |> click_button("Confirm save")
      |> refute_has(dialog)
      |> assert_has(saved.("email"), text: address, exact: true)
      |> assert_has(saved.("notifications"), text: "false", exact: true)
      |> assert_has(saved.("timezone"), text: "Europe/Helsinki", exact: true)
      |> assert_has("##{prefix}_bio", value: bio)
      |> assert_has(saved.("bio"), text: bio, exact: true)
      |> assert_has("[data-sonner-toast]")
      |> snapshot(prefix <> "-saved")
      |> fill_in("Email", with: "unsaved@example.com", exact: false)
      |> click_button("Reset to saved")
      |> assert_has(email, value: address)
      |> assert_has(notify <> "[aria-checked=false]")
      |> click_button("Apply server update")
      |> assert_has("##{prefix}_timezone", value: "Asia/Tokyo")
      |> assert_has(notify <> "[aria-checked=true]")
      |> assert_has(saved.("notifications"), text: "true", exact: true)

    draft = "recovered-#{mode}@example.com"

    conn
    |> fill_in("Email", with: draft, exact: false)
    |> refute_has(email <> "[aria-invalid=true]")
    |> evaluate("window.liveSocket.disconnect()")
    |> assert_has(".settings-offline")
    |> evaluate("window.liveSocket.connect()")
    |> refute_has(".settings-offline")
    |> assert_has("##{prefix}-status",
      text: "Unsaved edits recovered after reconnect.",
      exact: true
    )
    |> assert_has(email, value: draft)
    |> click_button("Review and save")
    |> assert_has(dialog, text: "Confirm settings save")
    |> click_button("Confirm save")
    |> assert_has(saved.("email"), text: draft, exact: true)
    |> PhoenixTest.Playwright.unwrap(fn %{frame_id: frame_id} ->
      assert {:ok, _} =
               PlaywrightEx.Frame.wait_for_function(frame_id,
                 expression: "document.documentElement.scrollWidth <= 390",
                 timeout: timeout()
               )
    end)
    |> PhoenixTest.Playwright.reload_page()
    |> assert_has("[data-phx-main].phx-connected")
    |> assert_has(email, value: draft)
  end

  defp unchecked(conn, selector) do
    evaluate(
      conn,
      "document.querySelector(#{Jason.encode!(selector)}).getAttribute('aria-checked')",
      fn
        "true" -> press(conn, selector, "Space")
        _ -> :ok
      end
    )
  end

  defp snapshot(conn, name) do
    evaluate(conn, "document.documentElement.outerHTML", fn html ->
      stylesheet = "file://" <> Application.app_dir(:shadcn_liveview, "priv/static/shadcn.css")

      html =
        html
        |> Floki.parse_document!()
        |> Floki.traverse_and_update(fn
          {"link", attrs, children} ->
            attrs =
              Enum.map(attrs, fn
                {"href", "/shadcn/shadcn.css"} -> {"href", stylesheet}
                attr -> attr
              end)

            {"link", attrs, children}

          node ->
            node
        end)
        |> Floki.raw_html()

      html_snapshot(html, name: name <> ".html", prompt_on_diff: false)
    end)
  end
end
