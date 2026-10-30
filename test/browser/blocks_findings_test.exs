defmodule ShadcnLiveview.BlocksFindingsBrowserTest do
  # Regressions from converting shadcn blocks (login-04, sidebar-07, dashboard-01).
  use PhoenixTest.Playwright.Case, async: false
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  setup %{conn: conn} do
    {:ok, conn: conn |> visit("/blocks-preview") |> connected()}
  end

  defp visible?(selector),
    do:
      "(() => {const e=document.querySelector(#{Jason.encode!(selector)});const s=getComputedStyle(e);const r=e.getBoundingClientRect();return s.display!=='none'&&s.opacity!=='0'&&r.width>0&&r.height>0;})()"

  defp hidden?(selector), do: "!" <> visible?(selector)

  test "avatar shows a loaded image without its fallback and the fallback for a broken image",
       %{conn: conn} do
    loaded_image = "#avatar-loaded [data-slot=avatar-image]"
    loaded_fallback = "#avatar-loaded [data-slot=avatar-fallback]"
    broken_image = "#avatar-broken [data-slot=avatar-image]"
    broken_fallback = "#avatar-broken [data-slot=avatar-fallback]"

    conn
    |> assert_attribute(loaded_image, "data-status", "loaded")
    |> assert_js(visible?(loaded_image))
    |> assert_js(hidden?(loaded_fallback))
    |> assert_attribute(broken_image, "data-status", "error")
    |> assert_js(hidden?(broken_image))
    |> assert_js(visible?(broken_fallback))
    # The avatar stays one avatar wide: the fallback no longer pushes the name aside.
    |> assert_js(
      "document.querySelector('#avatar-name').getBoundingClientRect().left - document.querySelector('#avatar-loaded').getBoundingClientRect().right < 40"
    )
    # An unrelated patch keeps the client-owned load status.
    |> click("#tick")
    |> assert_text("#tick", "Tick 1")
    |> assert_attribute(loaded_image, "data-status", "loaded")
    |> assert_js(hidden?(loaded_fallback), stable_frames: 3)
    # A server src change restarts the lifecycle for both images.
    |> click("#swap-avatar")
    |> assert_attribute(loaded_image, "data-status", "error")
    |> assert_js(visible?(loaded_fallback))
    |> assert_attribute(broken_image, "data-status", "loaded")
    |> assert_js(hidden?(broken_fallback))
  end

  test "a select inside relative z-0 table rows escapes the row stacking context", %{conn: conn} do
    option = "#status-alpha-archived"

    conn
    |> click("#status-alpha-trigger")
    |> assert_visible("[role=listbox]")
    # The listbox reaches over later rows; the topmost element at its options is the listbox.
    |> assert_js("""
    (() => {
      const r = document.querySelector(#{Jason.encode!(option)}).getBoundingClientRect();
      const row = document.querySelector('#row-gamma').getBoundingClientRect();
      const hit = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
      return r.bottom > row.top && hit?.closest('[role=listbox]') !== null;
    })()
    """)
    |> click(option)
    |> assert_count("[role=listbox]", 0)
    |> assert_text("#status-alpha-trigger", "Archived")
    |> assert_text("#status-beta-trigger", "Pending")
  end

  test "menus focus their content on pointer open and the first item on keyboard open", %{
    conn: conn
  } do
    trigger = "#focus-menu-trigger"
    menu = "[role=menu]"

    conn
    |> click(trigger)
    |> assert_visible(menu)
    |> assert_focused(menu)
    |> assert_count("[role=menuitem][data-highlighted]", 0)
    |> key("ArrowDown")
    |> assert_focused(role("menuitem", "Edit"))
    |> key("Escape")
    |> assert_count(menu, 0)
    |> assert_focused(trigger)
    |> key("Enter")
    |> assert_focused(role("menuitem", "Edit"))
    |> assert_attribute(role("menuitem", "Edit"), "data-highlighted", "")
    |> key("Escape")
    |> assert_count(menu, 0)
    |> key("ArrowUp")
    |> assert_focused(role("menuitem", "Delete"))
    |> key("Escape")
    |> assert_count(menu, 0)
  end

  test "drawer controls inherit the LiveComponent phx-target and the drawer focuses itself", %{
    conn: conn
  } do
    drawer = "#child-drawer"
    done = within(drawer, role("button", "Done"))

    conn
    |> click(role("button", "Open details"))
    |> assert_visible(drawer)
    |> assert_text("#child-drawer-events", "open")
    # Vaul (autoFocus=false) does not focus the first control.
    |> assert_focused(drawer)
    |> assert_attribute(done, "data-variant", "outline")
    |> assert_js(
      "getComputedStyle(document.querySelector('#child-drawer [data-variant=outline]')).borderTopWidth === '1px'"
    )
    |> assert_js("!document.querySelector('#child-drawer-plain').hasAttribute('data-variant')")
    |> click(done)
    |> assert_count(drawer, 0)
    |> assert_text("#child-drawer-events", "open,close")
    |> assert_focused(role("button", "Open details"))
    # The parent LiveView never received the drawer events, so it is still connected.
    |> connected()
    |> click(role("button", "Open details"))
    |> assert_visible(drawer)
    |> click("#child-drawer-plain")
    |> assert_count(drawer, 0)
    |> assert_text("#child-drawer-events", "open,close,open,close")
  end
end
