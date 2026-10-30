defmodule ShadcnLiveview.HookDisconnectBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  # LiveView rejects hook pushes while disconnected. Hooks must swallow that
  # rejection, keep server-controlled state, and work again after reconnecting.
  test "hook pushes while disconnected raise no page errors and recover after reconnect", %{
    conn: conn
  } do
    intro = role("button", "Introduction")
    edit = role("button", "Edit")
    profile = role("button", "Edit profile")
    terms = role("checkbox", "Accept terms")

    conn
    |> open_fixture("accordion-closed")
    |> disconnect()
    |> click(intro)
    |> assert_stable_without_errors(
      "document.querySelector('[data-slot=accordion-trigger]').getAttribute('aria-expanded') === 'false'"
    )
    |> reconnect()
    |> click(intro)
    |> assert_attribute(intro, "aria-expanded", "true")
    |> open_fixture("popover-closed")
    |> disconnect()
    |> click(edit)
    |> assert_stable_without_errors("!document.querySelector('[role=dialog]')")
    |> reconnect()
    |> click(edit)
    |> assert_visible(role("dialog"))
    |> open_fixture("dialog-closed")
    |> click(profile)
    |> assert_visible(role("dialog", "Edit profile"))
    |> disconnect()
    |> key("Escape")
    |> assert_stable_without_errors("!!document.querySelector('[role=dialog]')")
    |> reconnect()
    |> click(profile)
    |> assert_visible(role("dialog", "Edit profile"))
    |> key("Escape")
    |> assert_count(role("dialog"), 0)
    |> open_fixture("checkbox")
    |> disconnect()
    |> click(terms)
    |> assert_stable_without_errors(
      "document.querySelector('[role=checkbox]').getAttribute('aria-checked') === 'false'"
    )
    |> reconnect()
    |> click(terms)
    |> assert_attribute(terms, "aria-checked", "true")
  end

  defp disconnect(conn) do
    conn
    |> PhoenixTest.Playwright.evaluate("""
    window.__pageErrors = [];
    addEventListener("error", event => __pageErrors.push(String(event.message)));
    addEventListener("unhandledrejection", event => __pageErrors.push(String(event.reason)));
    liveSocket.disconnect();
    """)
    |> assert_js("!liveSocket.isConnected() && !liveSocket.main.isConnected()")
  end

  defp reconnect(conn) do
    conn
    |> PhoenixTest.Playwright.evaluate("liveSocket.connect()")
    |> connected()
    |> assert_js("liveSocket.main.isConnected()")
  end

  defp assert_stable_without_errors(conn, expression) do
    conn = assert_js(conn, "(#{expression}) && __pageErrors.length === 0", stable_frames: 10)
    assert value(conn, "__pageErrors") == []
    conn
  end
end
