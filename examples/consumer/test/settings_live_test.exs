defmodule ConsumerWeb.SettingsLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint ConsumerWeb.Endpoint

  for {route, prefix} <- [
        {"/settings", "settings-direct"},
        {"/settings/component", "settings-component"}
      ] do
    test "#{route} validates, confirms saves, resets and patches native controls" do
      assert_settings_flow(unquote(route), unquote(prefix))
    end

    test "#{route} preserves unsaved drafts while receiving saved PubSub snapshots" do
      assert_draft_and_pubsub(unquote(route), unquote(prefix))
    end
  end

  defp session_conn do
    id = Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
    {init_test_session(build_conn(), %{settings_session: id}), id}
  end

  defp attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "email" => "saved@example.com",
        "display_name" => "Saved Person",
        "timezone" => "Europe/Helsinki",
        "notifications" => "false",
        "bio" => "Saved from a real form."
      },
      overrides
    )
  end

  defp assert_settings_flow(route, prefix) do
    {conn, session_id} = session_conn()
    {:ok, view, _html} = live(conn, route)
    form_id = "##{prefix}-form"
    assert has_element?(view, form_id <> "[phx-auto-recover=recover]")
    assert has_element?(view, "label[for='#{prefix}_email']", "Email")

    view |> form(form_id, settings: attrs(%{"email" => "bad"})) |> render_submit()
    assert has_element?(view, "##{prefix}_email[aria-invalid=true]")
    assert has_element?(view, "##{prefix}_email-errors", "must be a valid email address")
    refute has_element?(view, "##{prefix}-save-dialog")

    view |> form(form_id, settings: attrs()) |> render_submit()
    assert has_element?(view, "##{prefix}-save-dialog[role=dialog]")
    view |> element("##{prefix}-confirm") |> render_click()
    assert_push_event(view, "shadcn:toast", %{toaster: toaster, message: "Settings saved"})
    assert toaster == prefix <> "-toaster"
    assert has_element?(view, "[data-saved=email]", "saved@example.com")
    assert has_element?(view, "[data-saved=notifications]", "false")
    refute Consumer.SettingsStore.get(session_id).settings.notifications

    view |> form(form_id, settings: attrs(%{"email" => "draft@example.com"})) |> render_change()
    view |> element("##{prefix}-reset") |> render_click()
    assert has_element?(view, "##{prefix}_email[value='saved@example.com']")

    view |> element("##{prefix}-server-update") |> render_click()
    assert has_element?(view, "##{prefix}_timezone option[value='Asia/Tokyo'][selected]")
    assert has_element?(view, "##{prefix}_notifications[aria-checked=true]")
    assert has_element?(view, "[data-saved=notifications]", "true")
    assert has_element?(view, "[data-saved=display_name]", "Server updated")

    {:ok, reloaded, _html} = live(conn, route)
    assert has_element?(reloaded, "##{prefix}_timezone option[value='Asia/Tokyo'][selected]")
    assert has_element?(reloaded, "[data-saved=email]", "saved@example.com")
  end

  defp assert_draft_and_pubsub(route, prefix) do
    {conn, session_id} = session_conn()
    {:ok, view, _html} = live(conn, route)
    draft = attrs(%{"email" => "draft@example.com"})
    view |> form("##{prefix}-form", %{"settings" => draft}) |> render_change()
    assert has_element?(view, "##{prefix}_email[value='draft@example.com']")

    Consumer.SettingsStore.server_update(session_id)
    # Drain the parent callback before asserting its queued LiveComponent update.
    render(view)
    assert has_element?(view, "[data-saved=timezone]", "Asia/Tokyo")
    assert has_element?(view, "##{prefix}_email[value='draft@example.com']")
    view |> element("##{prefix}-reset") |> render_click()
    assert has_element?(view, "##{prefix}_email[value='alex@example.com']")
  end
end
