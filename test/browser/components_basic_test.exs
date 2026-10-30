defmodule ShadcnLiveview.ComponentsBasicBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: [click_button: 4]
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  test "button acknowledges pointer and native keyboard activation", %{conn: conn} do
    conn
    |> open_fixture("button")
    |> click(role("button"))
    |> assert_text(role("button"), "Clicked 1 times")
    |> focus(role("button"))
    |> key("Space")
    |> assert_text(role("button"), "Clicked 2 times")
    |> open_fixture("button-destructive-default")
    |> assert_disabled(role("button"))
  end

  test "field label focuses an editable input with associated help", %{conn: conn} do
    conn =
      conn
      |> open_fixture("field")
      |> click("[data-slot=field-label]")
      |> assert_focused(role("textbox", "Email address"))
      |> fill_in("Email address", with: "onni@example.test")
      |> assert_value(role("textbox", "Email address"), "onni@example.test")
      |> assert_inside_stage("[data-slot=field-set]")

    assert_js(
      conn,
      "(() => {const el=document.querySelector('input'), ids=el.getAttribute('aria-describedby').split(/\\s+/);return ids.some(id=>document.getElementById(id).textContent.includes('never share'));})()"
    )
  end

  test "input group editing does not overlap prefix", %{conn: conn} do
    conn =
      conn
      |> open_fixture("input-group")
      |> fill(role("textbox"), "example.test")
      |> assert_value(role("textbox"), "example.test")
      |> assert_inside_stage("[data-slot=input-group]")

    assert_js(
      conn,
      "document.querySelector('[data-slot=input-group-addon]').getBoundingClientRect().right <= document.querySelector('input').getBoundingClientRect().x + 1"
    )
  end

  test "input native email validity and disabled boundaries", %{conn: conn} do
    conn
    |> open_fixture("input")
    |> fill(role("textbox"), "not-an-email")
    |> assert_js("document.querySelector('input').validity.typeMismatch")
    |> fill(role("textbox"), "onni@example.test")
    |> assert_js("document.querySelector('input').validity.valid")
    |> open_fixture("input-invalid-disabled")
    |> assert_disabled(role("textbox"))
  end

  test "label pointer activation focuses its associated field", %{conn: conn} do
    conn
    |> open_fixture("label")
    |> click("label")
    |> assert_focused(role("textbox", "Your email address"))
    |> fill_in("Your email address", with: "onni@example.test")
    |> assert_value(role("textbox"), "onni@example.test")
  end

  test "pagination next previous numbered links and upper boundary", %{conn: conn} do
    conn
    |> open_fixture("pagination")
    |> assert_text("[aria-current=page]", "1")
    |> click_link("Go to next page")
    |> assert_text("[aria-current=page]", "2")
    |> click(role("link", "3"))
    |> assert_text("[aria-current=page]", "3")
    |> click_link("Go to next page")
    |> assert_text("[aria-current=page]", "3")
    |> click_link("Go to previous page")
    |> assert_text("[aria-current=page]", "2")
  end

  test "notifications preserve literal text, keyboard dismissal and expiry", %{conn: conn} do
    conn =
      conn
      |> open_fixture("sonner")
      |> fill_in("Notification message", with: "Saved <script> & details")
      |> click_button(nil, "Show notification", exact: true)
      |> assert_contains("[data-sonner-toast]", "Saved <script> & details")
      |> assert_count("[data-sonner-toast] script", 0)
      |> assert_popup("[data-sonner-toast]")
      |> key("Alt+t")
      |> assert_focused(role("button", "Dismiss notification"))
      |> snapshot("sonner-visible.html")
      |> click_button("Dismiss notification")
      |> assert_count("[data-sonner-toast]", 0)
      |> click_button("Show brief notification")
      |> assert_visible("[data-sonner-toast]")

    assert_count(conn, "[data-sonner-toast]", 0)
  end

  test "textarea preserves multiline escaped native values and readonly state", %{conn: conn} do
    conn
    |> open_fixture("textarea")
    |> fill(role("textbox"), "First line\nSecond <line> & notes")
    |> assert_value(role("textbox"), "First line\nSecond <line> & notes")
    |> open_fixture("textarea-native-form")
    |> assert_attribute(role("textbox"), "readonly", "")
    |> assert_value(role("textbox"), "Saved notes")
  end

  test "toggle pointer Space and Enter update acknowledged pressed state", %{conn: conn} do
    button = role("button", "Toggle italic")

    conn
    |> open_fixture("toggle")
    |> click(button)
    |> assert_attribute(button, "aria-pressed", "true")
    |> focus(button)
    |> key("Space")
    |> assert_attribute(button, "aria-pressed", "false")
    |> key("Enter")
    |> assert_attribute(button, "aria-pressed", "true")
  end
end
