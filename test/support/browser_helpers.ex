defmodule ShadcnLiveview.BrowserHelpers do
  @moduledoc false
  import ExUnit.Assertions
  import Excessibility, only: [html_snapshot: 2]
  alias PhoenixTest.Playwright, as: Browser
  alias PlaywrightEx.{Frame, Page}

  @timeout 5_000

  def open_fixture(conn, fixture) do
    conn
    |> PhoenixTest.visit("/live-preview/#{URI.encode(fixture)}?embed=1")
    |> connected()
    |> snapshot(fixture <> ".html")
  end

  def connected(conn), do: assert_attribute(conn, "[data-phx-main]", "class", ~r/phx-connected/)

  def snapshot(conn, name) do
    Browser.evaluate(conn, "document.documentElement.outerHTML", fn html ->
      html_snapshot(html, name: name, prompt_on_diff: false)
    end)
  end

  def role(role, name \\ nil) do
    "internal:role=#{role}" <> if(name, do: "[name=#{Jason.encode!(name)}s]", else: "")
  end

  def text(text), do: "internal:text=#{Jason.encode!(text)}s"
  def within(parent, child), do: parent <> " >> " <> child
  def nth(selector, index), do: selector <> " >> nth=#{index}"

  def command(conn, scope, method, params \\ %{}) do
    Browser.unwrap(conn, fn ids ->
      id = Map.fetch!(ids, String.to_existing_atom("#{scope}_id"))

      response = PlaywrightEx.send(%{guid: id, method: method, params: params}, timeout: @timeout)
      assert {:ok, _} = PlaywrightEx.ChannelResponse.unwrap(response, &Function.identity/1)
    end)
  end

  def click(conn, selector, opts \\ []) do
    frame_action(conn, &Frame.click(&1, [selector: selector, timeout: @timeout] ++ opts))
  end

  def fill(conn, selector, value),
    do: frame_action(conn, &Frame.fill(&1, selector: selector, value: value, timeout: @timeout))

  def focus(conn, selector),
    do: frame_action(conn, &Frame.focus(&1, selector: selector, timeout: @timeout))

  def blur(conn, selector),
    do: frame_action(conn, &Frame.blur(&1, selector: selector, timeout: @timeout))

  def hover(conn, selector),
    do: frame_action(conn, &Frame.hover(&1, selector: selector, timeout: @timeout))

  def select_values(conn, selector, values),
    do:
      frame_action(
        conn,
        &Frame.select_option(&1,
          selector: selector,
          options: Enum.map(List.wrap(values), fn value -> %{value: value} end),
          timeout: @timeout
        )
      )

  # Page-level keyboard commands deliberately never refocus the target: refocusing
  # would hide regressions where an acknowledged LiveView patch loses focus.
  def key(conn, key), do: command(conn, :page, :keyboardPress, %{key: key})

  def viewport(conn, width, height),
    do: command(conn, :page, :setViewportSize, %{viewportSize: %{width: width, height: height}})

  def wheel(conn, x, y), do: command(conn, :page, :mouseWheel, %{deltaX: x, deltaY: y})
  def pointer_click(conn, x, y), do: command(conn, :page, :mouseClick, %{x: x, y: y})

  def move(conn, x, y) do
    Browser.unwrap(conn, fn %{page_id: id} ->
      assert {:ok, _} = Page.mouse_move(id, x: x, y: y, timeout: @timeout)
    end)
  end

  def drag_pointer(conn, {x, y}, {to_x, to_y}, steps \\ 12) do
    conn = move(conn, x, y)

    Browser.unwrap(conn, fn %{page_id: id} ->
      assert {:ok, _} = Page.mouse_down(id, timeout: @timeout)

      for step <- 1..steps do
        assert {:ok, _} =
                 Page.mouse_move(id,
                   x: x + (to_x - x) * step / steps,
                   y: y + (to_y - y) * step / steps,
                   timeout: @timeout
                 )
      end

      assert {:ok, _} = Page.mouse_up(id, timeout: @timeout)
    end)
  end

  def value(conn, expression) do
    ref = make_ref()
    Browser.evaluate(conn, expression, fn result -> send(self(), {ref, result}) end)

    receive do
      {^ref, result} -> result
    end
  end

  def assert_js(conn, expression, opts \\ []) do
    stable_frames = Keyword.get(opts, :stable_frames, 1)

    Browser.unwrap(conn, fn %{frame_id: id} ->
      assert {:ok, _} =
               Frame.wait_for_function(id,
                 expression:
                   "(() => {let frames=0;return () => {frames=(#{expression})?frames+1:0;return frames>=#{stable_frames};};})()",
                 is_function: true,
                 timeout: @timeout
               )
    end)
  end

  def box(conn, selector),
    do:
      value(
        conn,
        "(() => { const r = document.querySelector(#{Jason.encode!(selector)}).getBoundingClientRect(); return {x:r.x,y:r.y,width:r.width,height:r.height}; })()"
      )

  def form_entries(conn, selector),
    do:
      value(
        conn,
        "Array.from(new FormData(document.querySelector(#{Jason.encode!(selector)})).entries())"
      )

  def assert_form(conn, selector, expected),
    do:
      assert_js(
        conn,
        "JSON.stringify(Array.from(new FormData(document.querySelector(#{Jason.encode!(selector)})).entries())) === #{Jason.encode!(Jason.encode!(expected))}"
      )

  def assert_visible(conn, selector), do: expect(conn, selector, "to.be.visible")
  def assert_hidden(conn, selector), do: expect(conn, selector, "to.be.hidden")
  def assert_focused(conn, selector), do: expect(conn, selector, "to.be.focused")
  def assert_disabled(conn, selector), do: expect(conn, selector, "to.be.disabled")
  def assert_enabled(conn, selector), do: expect(conn, selector, "to.be.enabled")

  def assert_count(conn, selector, count),
    do: expect(conn, selector, "to.have.count", expected_number: count)

  def assert_value(conn, selector, value),
    do: expect(conn, selector, "to.have.value", expected_text: expected_text(value))

  def assert_text(conn, selector, text),
    do: expect(conn, selector, "to.have.text", expected_text: expected_text(text, false, true))

  def assert_contains(conn, selector, text),
    do: expect(conn, selector, "to.have.text", expected_text: expected_text(text, true, true))

  def assert_attribute(conn, selector, name, value),
    do:
      expect(conn, selector, "to.have.attribute.value",
        expression_arg: name,
        expected_text: expected_text(value)
      )

  def assert_no_attribute(conn, selector, name),
    do: expect(conn, selector, "to.have.attribute", expression_arg: name, is_not: true)

  def assert_checked(conn, selector, checked \\ true),
    do:
      expect(conn, selector, "to.be.checked",
        expected_value: PlaywrightEx.Serialization.serialize_arg(%{checked: checked})
      )

  def refute_attribute(conn, selector, name, value),
    do:
      expect(conn, selector, "to.have.attribute.value",
        expression_arg: name,
        expected_text: expected_text(value),
        is_not: true
      )

  def assert_popup(conn, selector, min_width \\ 80, min_height \\ 24) do
    conn |> assert_visible(selector)
    # Geometry is observed, not changed, in the browser.
    assert_js(
      conn,
      "(() => { const el = document.querySelector(#{Jason.encode!(selector)}); if (!el) return false; const r = el.getBoundingClientRect(); return r.width >= #{min_width} && r.height >= #{min_height} && r.x >= -1 && r.y >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1; })()"
    )
  end

  def assert_inside_stage(conn, selector) do
    conn |> assert_visible(selector)

    assert_js(
      conn,
      "(() => { const r = document.querySelector(#{Jason.encode!(selector)}).getBoundingClientRect(), s = document.querySelector('#fixture-stage').getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.x >= s.x && r.right <= s.right + 1 && r.y >= s.y && r.bottom <= s.bottom + 1; })()"
    )
  end

  def touch_scroll(conn, selector) do
    conn = hover(conn, selector)
    bounds = box(conn, selector)

    Browser.unwrap(conn, fn %{context_id: context, page_id: page} ->
      assert %{result: %{session: %{guid: session}}} =
               PlaywrightEx.send(
                 %{guid: context, method: :newCDPSession, params: %{page: %{guid: page}}},
                 timeout: @timeout
               )

      try do
        response =
          PlaywrightEx.send(
            %{
              guid: session,
              method: :send,
              params: %{
                method: "Input.synthesizeScrollGesture",
                params: %{
                  x: bounds["x"] + bounds["width"] / 2,
                  y: bounds["y"] + bounds["height"] / 2,
                  yDistance: -180,
                  gestureSourceType: "touch",
                  speed: 600
                }
              }
            },
            timeout: @timeout
          )

        assert {:ok, _} = PlaywrightEx.ChannelResponse.unwrap(response, &Function.identity/1)
      after
        PlaywrightEx.send(%{guid: session, method: :detach, params: %{}}, timeout: @timeout)
      end
    end)
  end

  defp frame_action(conn, fun),
    do: Browser.unwrap(conn, fn %{frame_id: id} -> assert {:ok, _} = fun.(id) end)

  defp expected_text(%Regex{} = regex, _substring, _normalize),
    do: [%{regex_source: regex.source, regex_flags: to_string(Regex.opts(regex))}]

  defp expected_text(text, substring, normalize),
    do: [%{string: text, match_substring: substring, normalize_white_space: normalize}]

  defp expected_text(text), do: expected_text(text, false, false)

  defp expect(conn, selector, expression, opts \\ []) do
    Browser.unwrap(conn, fn %{frame_id: id} ->
      assert {:ok, matches?} =
               Frame.expect(
                 id,
                 [selector: selector, expression: expression, timeout: @timeout] ++ opts
               )

      assert matches? != Keyword.get(opts, :is_not, false), "#{expression} failed for #{selector}"
    end)
  end
end
