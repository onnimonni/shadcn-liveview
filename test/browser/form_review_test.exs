defmodule ShadcnLiveview.FormReviewBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import PhoenixTest.Playwright, only: []
  import ShadcnLiveview.BrowserHelpers
  @moduletag :browser_test

  # Native inputs must match the visible control, including the checked attribute that
  # LiveView uses to restore checkedness when it applies patches.
  @controls_agree "[...document.querySelectorAll('#settings-form [role=switch],#settings-form [role=checkbox],#settings-form [role=radio]')].every(b=>{const i=b.nextElementSibling;return String(i.checked)===b.getAttribute('aria-checked')&&b.dataset.state===(i.checked?'checked':'unchecked')&&(b.getAttribute('role')==='radio'||i.hasAttribute('checked')===i.checked);})"

  setup %{conn: conn} do
    {:ok, conn: conn |> visit("/form-review-preview") |> connected()}
  end

  test "field-bound switch and checkbox submit visible state after rapid toggles and typing", %{
    conn: conn
  } do
    conn
    |> click(role("switch", "Push"))
    |> click(role("checkbox", "Comments"))
    |> fill("#settings_bio", "a")
    |> fill("#settings_bio", "ab")
    |> assert_text("#settings-changes", "4")
    |> assert_attribute(role("switch", "Push"), "aria-checked", "false")
    |> assert_attribute(role("checkbox", "Comments"), "aria-checked", "true")
    |> assert_js(@controls_agree, stable_frames: 3)
    |> assert_form("#settings-form", [
      ["settings[push]", "false"],
      ["settings[comments]", "false"],
      ["settings[comments]", "true"],
      ["settings[bio]", "ab"],
      ["settings[plan]", "basic"]
    ])
    |> click(role("checkbox", "Comments"))
    |> click(role("switch", "Push"))
    |> fill("#settings_bio", "abc")
    |> assert_text("#settings-changes", "7")
    |> assert_js(@controls_agree, stable_frames: 3)
    |> assert_form("#settings-form", [
      ["settings[push]", "false"],
      ["settings[push]", "true"],
      ["settings[comments]", "false"],
      ["settings[bio]", "abc"],
      ["settings[plan]", "basic"]
    ])
    |> click(role("switch", "Push"))
    |> click(role("checkbox", "Comments"))
    |> fill("#settings_bio", "done")
    |> click("#settings-save")
    |> assert_contains("#settings-saved", ~s("push":"false"))
    |> assert_contains("#settings-saved", ~s("comments":"true"))
    |> assert_attribute(role("switch", "Push"), "aria-checked", "false")
    |> assert_attribute(role("checkbox", "Comments"), "aria-checked", "true")
    |> assert_js(@controls_agree, stable_frames: 3)
  end

  test "field-bound radio group is labelled and controlled changes reach phx-change", %{
    conn: conn
  } do
    conn
    |> assert_visible(role("radiogroup", "Plan"))
    |> assert_attribute("#plan-pro + input", "name", "settings[plan]")
    |> click(role("radio", "Pro"))
    |> fill("#settings_bio", "x")
    |> assert_text("#settings-changes", "2")
    |> assert_checked(role("radio", "Pro"))
    |> assert_js(@controls_agree, stable_frames: 3)
    |> assert_form("#settings-form", [
      ["settings[push]", "false"],
      ["settings[push]", "true"],
      ["settings[comments]", "false"],
      ["settings[bio]", "x"],
      ["settings[plan]", "pro"]
    ])
    |> focus(role("radio", "Pro"))
    |> key("ArrowUp")
    |> assert_text("#settings-changes", "3")
    |> assert_checked(role("radio", "Basic"))
    |> assert_focused(role("radio", "Basic"))
    |> assert_js(@controls_agree, stable_frames: 3)
    |> click("#settings-save")
    |> assert_contains("#settings-saved", ~s("plan":"basic"))
  end
end
