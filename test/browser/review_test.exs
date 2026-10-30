defmodule ShadcnLiveview.ReviewBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  setup %{conn: conn} do
    {:ok,
     conn: conn |> visit("/review-preview") |> connected() |> snapshot("review-initial.html")}
  end

  test "uncontrolled values survive patches changed defaults and reset mounted defaults", %{
    conn: conn
  } do
    conn
    |> click("#uncontrolled-check")
    |> click("#uncontrolled-switch")
    |> focus("#uncontrolled-slider [role=slider]")
    |> key("ArrowRight")
    |> assert_form("#uncontrolled-form", [["check", "on"], ["switch", "on"], ["amount", "26"]])
    |> click("#review-patch")
    |> assert_text("#review-tick", "1")
    |> click("#review-defaults")
    |> assert_checked("#uncontrolled-check")
    |> assert_attribute("#uncontrolled-slider [role=slider]", "aria-valuenow", "26")
    |> assert_form("#uncontrolled-form", [["check", "on"], ["switch", "on"], ["amount", "26"]])
    |> click("#uncontrolled-reset")
    |> assert_form("#uncontrolled-form", [["amount", "25"]])
    |> assert_checked("#uncontrolled-check", false)
    |> assert_checked("#uncontrolled-switch", false)
  end

  test "controlled server values remain authoritative", %{conn: conn} do
    conn
    |> click("#review-controlled")
    |> assert_form("#controlled-form", [["check", "on"], ["switch", "on"], ["amount", "80"]])
    |> click("#review-controlled")
    |> assert_form("#controlled-form", [["amount", "20"]])
    |> assert_checked("#controlled-check", false)
  end

  test "released controlled ranges retain structure and reset mounted scalar defaults", %{
    conn: conn
  } do
    conn
    |> click("#review-value-mode")
    |> assert_form("#transition-form", [
      ["check", "on"],
      ["switch", "on"],
      ["amount[]", "20"],
      ["amount[]", "80"]
    ])
    |> assert_count("#transition-slider [role=slider]", 2)
    |> focus(nth("#transition-slider [role=slider]", 1))
    |> key("ArrowRight")
    |> assert_form("#transition-form", [
      ["check", "on"],
      ["switch", "on"],
      ["amount[]", "20"],
      ["amount[]", "81"]
    ])
    |> click("#transition-reset")
    |> assert_js(
      "(() => {const d=new FormData(document.querySelector('#transition-form'));return JSON.stringify({scalar:d.getAll('amount'),range:d.getAll('amount[]')})===JSON.stringify({scalar:['25'],range:[]});})()"
    )
    |> assert_count("#transition-slider [role=slider]:visible", 1)
  end

  test "textarea native defaults escaping slot precedence and server patches", %{conn: conn} do
    original = "Existing <biography> & notes"
    updated = "\nUpdated </textarea><script>unsafe()</script> & notes"

    conn
    |> assert_value("#review-bio", original)
    |> assert_value("#review-notes", original)
    |> assert_form("#textarea-form", [
      ["bio", original],
      ["notes", original],
      ["empty", ""],
      ["group-empty", ""],
      ["slot", "Slot fallback"],
      ["precedence", ""]
    ])
    |> click("#textarea-update")
    |> assert_value("#review-bio", updated)
    |> assert_value("#review-notes", updated)
    |> assert_js(
      "new FormData(document.querySelector('#textarea-form')).get('bio')===#{Jason.encode!(updated)}"
    )
    |> assert_count("#textarea-form script", 0)
  end

  test "combobox root and child disabled ownership survives patches", %{conn: conn} do
    conn
    |> assert_disabled("#review-combo-input")
    |> click("#combo-root-toggle")
    |> assert_enabled("#review-combo-input")
    |> click("#combo-child-toggle")
    |> assert_disabled("#review-combo-input")
    |> click("#combo-root-toggle")
    |> click("#combo-child-toggle")
    |> assert_disabled("#review-combo-input")
    |> click("#combo-root-toggle")
    |> assert_enabled("#review-combo-input")
  end

  test "nested disclosure pointer descendants and keyboard belong only to nearest root", %{
    conn: conn
  } do
    conn
    |> click("#nested-inner [data-slot=collapsible-trigger] span")
    |> assert_text("#disclosure-events", "{\"inner\":1}")
    |> assert_attribute("#nested-outer", "data-state", "open")
    |> assert_attribute("#nested-inner", "data-state", "closed")
    |> focus("#nested-inner [data-slot=collapsible-trigger]")
    |> key("Enter")
    |> assert_text("#disclosure-events", "{\"inner\":2}")
    |> assert_attribute("#nested-outer", "data-state", "open")
  end

  test "scroll area native wheel both axes keyboard no IDs and patches", %{conn: conn} do
    viewport = "#review-scroll [data-slot=scroll-area-viewport]"
    no_id = "[data-review-no-id] [data-slot=scroll-area-viewport]"

    conn
    |> hover(viewport)
    |> wheel(150, 200)
    |> assert_js(
      "document.querySelector('#{viewport}').scrollTop>0&&document.querySelector('#{viewport}').scrollLeft>0"
    )
    |> focus(viewport)
    |> key("Home")
    |> key("Control+Home")
    |> assert_js("document.querySelector('#{viewport}').scrollTop===0", stable_frames: 3)
    |> key("ArrowDown")
    |> assert_js("document.querySelector('#{viewport}').scrollTop>0")
    |> click("#review-patch")
    |> assert_text("#review-tick", "1")
    |> assert_js("getComputedStyle(document.querySelector('#{viewport}')).overflowY==='auto'")
    |> hover(no_id)
    |> wheel(0, 200)
    |> assert_js("document.querySelector('#{no_id}').scrollTop>0")
  end

  test "all control hooks reach LiveComponent targets including OTP completion callback", %{
    conn: conn
  } do
    conn =
      conn
      |> click("#child-check")
      |> received("child-change")
      |> click("#child-switch")
      |> received("child-change", 2)
      |> focus("#child-slider [role=slider]")
      |> key("ArrowRight")
      |> received("child-slider")
      |> click("#child-toggle")
      |> received("child-toggle")
      |> click("#child-collapse [data-slot=collapsible-trigger]")
      |> received("control_open")
      |> click("#child-radio-b")
      |> received("child-radio")
      |> click(nth("#child-group [data-slot=toggle-group-item]", 1))
      |> received("child-group")
      |> click("#child-command-chosen")
      |> received("shadcn:command-change")
      |> fill("#child-otp", "1234")
      |> received("child-otp-change")
      |> received("child-otp-complete")
      |> click("#child-carousel [data-slot=carousel-next]")
      |> click("#child-combo-input")
      |> received("shadcn:combobox-open")
      |> click(role("option", "Beta"))
      |> received("shadcn:combobox-change")
      |> received("shadcn:carousel-change")

    connected(conn)
  end

  test "popup modal native calendar and keyboard crossing month target LiveComponent", %{
    conn: conn
  } do
    conn
    |> click(role("button", "Targeted popup"))
    |> received("shadcn:popup-change")
    |> click(role("menuitem", "Alpha"))
    |> received("shadcn:popup-change", 3)
    |> click(role("button", "Targeted dialog"))
    |> received("shadcn:modal-open")
    |> key("Escape")
    |> received("shadcn:modal-close")
    |> click("#child-calendar button[aria-label='Go to the Next Month']")
    |> received("calendar-month")
    |> click("#child-calendar td[data-day='2024-03-15'] button")
    |> received("calendar-select")
    |> focus("#child-calendar td[data-day='2024-03-31'] button")
    |> key("ArrowRight")
    |> received("calendar-month", 2)
    |> assert_text("#child-calendar [role=status]", "April 2024")
    |> connected()
  end

  @tag browser_context_opts: [
         has_touch: true,
         is_mobile: true,
         viewport: %{width: 390, height: 844}
       ]
  test "overflow content responds to native touch scroll gesture", %{conn: conn} do
    selector = "[data-review-no-id] [data-slot=scroll-area-viewport]"

    conn
    |> touch_scroll(selector)
    |> assert_js("document.querySelector('#{selector}').scrollTop>0")
  end

  defp received(conn, event, count \\ 1) do
    assert_js(
      conn,
      "JSON.parse(document.querySelector('#child-events').innerText)[#{Jason.encode!(event)}]===#{count}"
    )
  end
end
