defmodule ShadcnLiveview.GalleryBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import ShadcnLiveview.BrowserHelpers, except: [click: 2, click: 3]
  alias ShadcnLiveview.BrowserHelpers, as: Browser

  @moduletag :browser_test

  test "shipping labels and submission remain usable in a narrow gallery iframe", %{conn: conn} do
    fixture = "radio-group-required-vertical"
    owner = owner(fixture)
    standard = framed(fixture, role("radio", "Standard"))
    express = framed(fixture, role("radio", "Express"))
    overnight = framed(fixture, role("radio", "Overnight"))
    submit = framed(fixture, role("button", "Submit shipping"))
    status = framed(fixture, "#shipping-form output")

    conn =
      conn
      |> visit("/preview/liveview.html")
      |> hover(owner)
      |> evaluate("document.querySelector(#{Jason.encode!(owner)}).style.width = '240px'")
      |> frame_connected(fixture)

    for name <- ["standard", "express", "overnight"] do
      assert_visible(conn, framed(fixture, "label[for=#{name}]"))
    end

    conn =
      conn
      |> assert_attribute(framed(fixture, role("radiogroup")), "aria-required", "true")
      |> assert_checked(standard)
      |> assert_disabled(express)
      |> Browser.click(submit)
      |> assert_text(status, "Submitted shipping: standard")
      |> Browser.click(framed(fixture, "label[for=overnight]"))
      |> assert_checked(overnight)
      |> assert_checked(standard, false)

    disabled_label = frame_box(conn, fixture, "label[for=express]")

    conn =
      conn
      |> pointer_click(
        disabled_label["x"] + disabled_label["width"] / 2,
        disabled_label["y"] + disabled_label["height"] / 2
      )
      |> assert_checked(express, false)
      |> assert_checked(overnight)
      |> assert_js(
        "JSON.stringify(Array.from(new FormData(#{document(fixture)}.querySelector('#shipping-form')).entries())) === #{Jason.encode!(Jason.encode!([["shipping", "overnight"]]))}"
      )
      |> Browser.click(submit)
      |> assert_text(status, "Submitted shipping: overnight")
      |> focus(standard)
      |> key("ArrowDown")
      |> assert_focused(overnight)
      |> assert_checked(overnight)

    button_bounds = frame_box(conn, fixture, "button[type=submit]")
    status_bounds = frame_box(conn, fixture, "#shipping-form output")
    frame_bounds = box(conn, owner)
    assert status_bounds["y"] >= button_bounds["y"] + button_bounds["height"] + 8

    for bounds <- [button_bounds, status_bounds] do
      assert bounds["x"] >= frame_bounds["x"]
      assert bounds["x"] + bounds["width"] <= frame_bounds["x"] + frame_bounds["width"] + 1
    end
  end

  test "controlled tabs update without affecting another gallery example", %{conn: conn} do
    first = "tabs-history"
    other = "tabs"

    conn
    |> visit("/preview/liveview.html")
    |> hover(owner(first))
    |> frame_connected(first)
    |> assert_attribute(framed(first, role("tab", "History")), "aria-selected", "true")
    |> Browser.click(framed(first, role("tab", "Overview")))
    |> assert_attribute(framed(first, role("tab", "Overview")), "aria-selected", "true")
    |> assert_attribute(framed(first, role("tab", "History")), "aria-selected", "false")
    |> hover(owner(other))
    |> frame_connected(other)
    |> assert_attribute(framed(other, role("tab", "Account")), "aria-selected", "true")
  end

  test "independent tab instances retain their selections", %{conn: conn} do
    fixture = "tabs-instances"

    conn
    |> visit("/preview/liveview.html")
    |> hover(owner(fixture))
    |> frame_connected(fixture)
    |> Browser.click(framed(fixture, within("#tabs-first", role("tab", "History"))))
    |> assert_attribute(
      framed(fixture, within("#tabs-first", role("tab", "History"))),
      "aria-selected",
      "true"
    )
    |> assert_attribute(
      framed(fixture, within("#tabs-second", role("tab", "Settings"))),
      "aria-selected",
      "true"
    )
  end

  test "dialog portals remain in their frame and close and reopen", %{conn: conn} do
    fixture = "dialog-closed"
    trigger = framed(fixture, "[data-slot=dialog-trigger]")
    dialog = framed(fixture, role("dialog"))

    conn =
      conn
      |> visit("/preview/liveview.html")
      |> hover(owner(fixture))
      |> frame_connected(fixture)
      |> Browser.click(trigger)
      |> assert_visible(dialog)
      |> assert_js(
        "(() => { const d = #{document(fixture)}; const r = d.querySelector('[role=dialog]').getBoundingClientRect(); return r.x >= 0 && r.right <= d.defaultView.innerWidth && r.y >= 0 && r.bottom <= d.defaultView.innerHeight; })()"
      )

    conn
    |> press(dialog, "Escape")
    |> assert_count(dialog, 0)
    |> Browser.click(trigger)
    |> assert_visible(dialog)
    |> assert_count(role("dialog"), 0)
  end

  test "separator keyboard steps and double-click reset retain vendor sizing", %{conn: conn} do
    separator = role("separator")

    conn
    |> open_fixture("resizable-vertical")
    |> assert_attribute(separator, "aria-valuenow", "30")
    |> focus(separator)
    |> key("ArrowDown")
    |> assert_attribute(separator, "aria-valuenow", "35")
    |> key("Shift+ArrowDown")
    |> assert_attribute(separator, "aria-valuenow", "40")
    |> Browser.click(separator, click_count: 2)
    |> assert_attribute(separator, "aria-valuenow", "30")
  end

  test "multiple questionnaire answers survive submission and clearing", %{conn: conn} do
    good = "input[value=good]"
    great = "input[value=great]"
    receipt = "output[aria-live=polite]"
    submitted = ~s(Submitted answers: {"rating":["good","great"],"comment":["Nice visit!"]})

    conn
    |> open_fixture("questionnaire-invalid-multiple")
    |> Browser.click(good)
    |> Browser.click(great)
    |> assert_count(role("alert"), 0)
    |> click_button("Next")
    |> fill("#questionnaire-invalid-comment-input", "Nice visit!")
    |> click_button("Submit")
    |> assert_text(receipt, submitted)
    |> click_button("Previous")
    |> assert_text(receipt, submitted)
    |> Browser.click(good)
    |> assert_count(receipt, 0)
    |> Browser.click(great)
    |> click_button("Next")
    |> assert_js(
      "!document.querySelector('#{good}').checked && !document.querySelector('#{great}').checked"
    )
    |> assert_visible(role("alert"))
  end

  test "loading a dialog preserves its allocated gallery viewport", %{conn: conn} do
    test_pid = self()

    PhoenixTest.Playwright.unwrap(conn, fn %{page_id: page_id} ->
      assert {:ok, _} =
               PlaywrightEx.Page.route(
                 page_id,
                 "**/live-preview/dialog?embed=1",
                 fn route, _request ->
                   send(test_pid, {:dialog_request_held, self()})

                   receive do
                     :release_dialog -> assert {:ok, _} = PlaywrightEx.Route.continue(route)
                   after
                     5_000 -> flunk("Dialog iframe request was never released")
                   end
                 end,
                 timeout: timeout()
               )
    end)

    conn =
      conn
      |> PhoenixTest.Playwright.visit("/preview/liveview.html", wait_until: "domcontentloaded")
      |> hover(owner("dialog"))

    assert_receive {:dialog_request_held, request_pid}, 5_000
    before = box(conn, owner("dialog"))

    conn =
      evaluate(conn, """
      (() => {
        const owner = document.querySelector('iframe[data-fixture="dialog"]');
        window.__dialogFrameMeasured = false;
        window.addEventListener('message', event => {
          if (event.source === owner.contentWindow && event.data?.type === 'shadcn:frame-size') {
            window.__dialogFrameMeasured = true;
          }
        });
      })()
      """)

    send(request_pid, :release_dialog)

    conn =
      conn
      |> assert_js("window.__dialogFrameMeasured === true")
      |> frame_connected("dialog")
      |> assert_visible(framed("dialog", role("dialog")))

    assert box(conn, owner("dialog"))["height"] == before["height"]
  end

  test "multiple sidebars stay bounded and the mobile drawer dismisses independently", %{
    conn: conn
  } do
    provider = "#sidebar-inset"
    static = "#sidebar-static-panel"
    panel = "#sidebar-inset-panel"
    main = "#sidebar-inset main"
    trigger = within(main, role("button", "Toggle Sidebar"))
    desktop = "#sidebar-inset [data-slot=sidebar][data-state]"
    dialog = role("dialog", "Sidebar")

    conn =
      conn
      |> viewport(1100, 640)
      |> open_fixture("sidebar-multiple")
      |> assert_attribute(desktop, "data-state", "expanded")

    provider_bounds = box(conn, provider)
    panel_bounds = box(conn, panel)
    static_bounds = box(conn, static)
    assert_in_delta panel_bounds["x"], provider_bounds["x"], 0.5
    assert_in_delta panel_bounds["y"], provider_bounds["y"], 0.5
    assert_in_delta panel_bounds["height"], provider_bounds["height"], 0.5
    assert provider_bounds["y"] + provider_bounds["height"] <= 640
    assert panel_bounds["x"] + panel_bounds["width"] < static_bounds["x"]
    main_before = box(conn, main)["width"]

    conn =
      conn
      |> Browser.click(trigger)
      |> assert_attribute(desktop, "data-state", "collapsed")
      |> assert_js(
        "document.querySelector('#sidebar-inset main').getBoundingClientRect().width > #{main_before + 200}"
      )

    assert box(conn, static)["width"] == static_bounds["width"]
    conn = conn |> viewport(390, 640) |> assert_hidden(panel)
    mobile_main = box(conn, main)
    mobile_static = box(conn, static)
    assert mobile_main["width"] > 300
    assert mobile_static["y"] + mobile_static["height"] <= 640
    assert mobile_static["y"] > mobile_main["y"] + mobile_main["height"]

    conn
    |> assert_js("document.documentElement.scrollWidth === 390")
    |> Browser.click(trigger)
    |> assert_visible(dialog)
    |> assert_contains(dialog, "Navigation")
    |> key("Escape")
    |> assert_hidden(dialog)
    |> assert_focused(trigger)
    |> assert_visible(static)
    |> Browser.click(trigger)
    |> assert_visible(dialog)
    |> assert_focused(dialog)
    |> pointer_click(380, 100)
    |> assert_hidden(dialog)
    |> assert_focused(trigger)
  end

  test "bar chart shrinks inside a narrow frame before and after data patches", %{conn: conn} do
    conn =
      conn
      |> viewport(390, 360)
      |> open_fixture("chart-bar-series")
      |> assert_visible("[data-slot=chart] svg.recharts-surface")

    for changed <- [false, true] do
      conn =
        if changed do
          conn
          |> click_button("Change chart data")
          |> assert_contains("[data-slot=chart] svg.recharts-surface", "May")
        else
          conn
        end

      bounds = box(conn, "[data-slot=chart]")
      button_bounds = box(conn, "button")
      assert bounds["x"] >= 24
      assert bounds["x"] + bounds["width"] <= 366
      assert button_bounds["x"] >= 24

      assert_js(conn, """
      (() => {
        if (document.documentElement.scrollWidth !== 390) return false;
        const chart = document.querySelector('[data-slot=chart]').getBoundingClientRect();
        return Array.from(document.querySelectorAll('[data-slot=chart] .recharts-rectangle')).every(node => {
          const bar = node.getBoundingClientRect();
          return bar.x >= chart.x && bar.right <= chart.right + 1 && bar.top >= chart.y && bar.bottom <= chart.bottom + 1;
        });
      })()
      """)
    end
  end

  defp owner(fixture), do: "iframe[data-fixture='#{fixture}']"

  defp framed(fixture, selector),
    do: within(owner(fixture), "internal:control=enter-frame >> " <> selector)

  defp document(fixture),
    do: "document.querySelector(#{Jason.encode!(owner(fixture))}).contentDocument"

  defp frame_connected(conn, fixture) do
    conn
    |> assert_attribute(framed(fixture, "[data-phx-main]"), "class", ~r/phx-connected/)
    |> evaluate("#{document(fixture)}.documentElement.outerHTML", fn html ->
      html_snapshot(html, name: "gallery-#{fixture}.html", prompt_on_diff: false)
    end)
  end

  defp frame_box(conn, fixture, selector) do
    value(conn, """
    (() => {
      const owner = document.querySelector(#{Jason.encode!(owner(fixture))});
      const outer = owner.getBoundingClientRect();
      const rect = owner.contentDocument.querySelector(#{Jason.encode!(selector)}).getBoundingClientRect();
      return {x: outer.x + owner.clientLeft + rect.x, y: outer.y + owner.clientTop + rect.y, width: rect.width, height: rect.height};
    })()
    """)
  end
end
