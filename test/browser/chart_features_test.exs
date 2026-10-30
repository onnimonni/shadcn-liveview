defmodule ShadcnLiveview.ChartFeaturesBrowserTest do
  use PhoenixTest.Playwright.Case, async: false
  use Excessibility
  import ShadcnLiveview.BrowserHelpers
  alias PlaywrightEx.{BrowserContext, Page}
  @moduletag :browser_test

  @canvas "#visitors-chart"
  # June 2024 rows of dashboard-01's chart-area-interactive: {mobile, desktop}.
  @visitors [
    {200, 178},
    {410, 470},
    {160, 103},
    {380, 439},
    {140, 88},
    {250, 294},
    {370, 323},
    {320, 385},
    {480, 438},
    {200, 155},
    {150, 92},
    {420, 492},
    {130, 81},
    {380, 426},
    {350, 307},
    {310, 371},
    {520, 475},
    {170, 107},
    {290, 341},
    {450, 408},
    {210, 169},
    {270, 317},
    {530, 480},
    {180, 132},
    {190, 141},
    {380, 434},
    {490, 448},
    {200, 149},
    {160, 103},
    {400, 446}
  ]

  @geometry """
  (() => {
    const root = document.querySelector('#fixture-stage [data-slot=chart]');
    const all = selector => Array.from(root.querySelectorAll(selector));
    return {
      areas: all('.recharts-area-area').map(e => ({d: e.getAttribute('d'), fill: e.getAttribute('fill'), opacity: e.getAttribute('fill-opacity')})),
      curves: all('.recharts-area-curve').map(e => e.getAttribute('d')),
      commands: all('.recharts-area-curve').map(e => e.getAttribute('d').replace(/[^MLCZ]/g, '')),
      grid: all('.recharts-cartesian-grid-horizontal line').map(e => [Number(e.getAttribute('y1')), Number(e.getAttribute('x1')), Number(e.getAttribute('x2')), e.getAttribute('stroke')]),
      verticalGrid: all('.recharts-cartesian-grid-vertical line').length,
      gridStroke: all('.recharts-cartesian-grid-horizontal line').map(e => getComputedStyle(e).stroke),
      ticks: all('.recharts-cartesian-axis-tick-value').map(e => { const b = e.getBBox(); return {text: e.textContent, x: Number(e.getAttribute('x')), y: Number(e.getAttribute('y')), left: b.x, right: b.x + b.width}; }),
      tickLines: all('.recharts-cartesian-axis-tick-line').length,
      axisLines: all('.recharts-cartesian-axis-line').length,
      gradients: all('linearGradient').map(g => Array.from(g.querySelectorAll('stop')).map(s => [s.getAttribute('offset'), Number(s.getAttribute('stop-opacity'))]))
    };
  })()
  """

  test "dashboard-01 stacked natural gradient area chart matches Recharts geometry", %{conn: conn} do
    conn =
      conn
      |> open_fixture("chart-area-interactive")
      |> assert_count(@canvas <> " .recharts-area-area", 2)

    actual = stable_geometry(conn)

    # Stacking: mobile sits on 0, desktop's top line passes through mobile + desktop.
    [mobile_curve, desktop_curve] = actual["curves"]
    assert actual["commands"] == List.duplicate("M" <> String.duplicate("C", 29), 2)
    [bottom | _] = ys = actual["grid"] |> Enum.map(&hd/1) |> Enum.sort(:desc)
    top = List.last(ys)
    assert length(ys) == 5
    # Five nice ticks for max 1010: 0, 300, 600, 900, 1200.
    y = fn value -> bottom - value / 1200 * (bottom - top) end

    for {points, values} <- [
          {curve_points(mobile_curve), Enum.map(@visitors, &elem(&1, 0))},
          {curve_points(desktop_curve), Enum.map(@visitors, fn {m, d} -> m + d end)}
        ] do
      assert length(points) == 30

      for {{_x, py}, value} <- Enum.zip(points, values),
          do: assert_in_delta(py, y.(value), 0.01)
    end

    # Gradient fills: one linearGradient per series, source stop opacities, area fill-opacity 0.6.
    assert actual["gradients"] == [[["5%", 0.8], ["95%", 0.1]], [["5%", 1.0], ["95%", 0.1]]]

    assert Enum.map(actual["areas"], & &1["opacity"]) == ["0.6", "0.6"]
    assert Enum.all?(actual["areas"], &String.starts_with?(&1["fill"], "url(#"))

    # Horizontal-only grid styled by chart_container's stroke-border/50 rule.
    assert actual["verticalGrid"] == 0
    assert Enum.all?(actual["grid"], fn [_, _, _, stroke] -> stroke == "#ccc" end)
    assert Enum.all?(actual["gridStroke"], &(&1 != "rgb(204, 204, 204)"))

    # Axis: no axis/tick lines, labels "Jun 1" style, thinned with >= 32px gaps.
    assert actual["tickLines"] == 0 and actual["axisLines"] == 0
    ticks = actual["ticks"]
    assert length(ticks) > 2 and length(ticks) < 30
    assert Enum.all?(ticks, &(&1["text"] =~ ~r/^Jun \d{1,2}$/))
    assert List.last(ticks)["text"] == "Jun 30"
    assert Enum.all?(ticks, &(&1["y"] == bottom + 14))

    for [a, b] <- Enum.chunk_every(ticks, 2, 1, :discard),
        do: assert(b["left"] - a["right"] >= 31.5)

    # Exactly Recharts' getTicksEnd (interval="preserveEnd", minTickGap=32) over the
    # rendered labels' widths in the loaded font.
    expected =
      value(conn, """
      (() => {
        const svg = document.querySelector('#visitors-chart svg'), width = Number(svg.getAttribute('width'));
        const font = getComputedStyle(svg.querySelector('.recharts-cartesian-axis-tick-value'));
        const span = document.createElement('span');
        Object.assign(span.style, {position: 'absolute', whiteSpace: 'pre', fontSize: font.fontSize, fontFamily: font.fontFamily, letterSpacing: font.letterSpacing});
        document.body.append(span);
        let end = width; const shown = [];
        for (let i = 29; i >= 0; i--) {
          span.textContent = 'Jun ' + (i + 1);
          const size = span.getBoundingClientRect().width, coordinate = 5 + i * (width - 10) / 29;
          const tick = i === 29 ? Math.min(coordinate, end - size / 2) : coordinate;
          if (tick - size / 2 < 0 || tick + size / 2 > end) continue;
          end = tick - size / 2 - 32;
          shown.unshift([span.textContent, tick]);
        }
        span.remove();
        return shown;
      })()
      """)

    assert Enum.map(ticks, & &1["text"]) == Enum.map(expected, &hd/1)

    for {tick, [_, x]} <- Enum.zip(ticks, expected),
        do: assert_in_delta(tick["x"], x, 0.01)

    # Same geometry as the React source rendered by Recharts 3. Tick selection is not
    # compared: Recharts caches label widths measured before the web font loads.
    reference = react_geometry(conn, "chart-area-interactive")
    assert Enum.all?(reference["ticks"], &(&1["y"] == bottom + 14))

    # Paths are byte-identical to Recharts' d3-shape output (3-digit rounding).
    assert actual["curves"] == reference["curves"]
    assert Enum.map(actual["areas"], & &1["d"]) == Enum.map(reference["areas"], & &1["d"])

    assert Enum.map(actual["areas"], & &1["opacity"]) ==
             Enum.map(reference["areas"], & &1["opacity"])

    assert Enum.sort(actual["gradients"]) == Enum.sort(reference["gradients"])
    assert reference["verticalGrid"] == 0

    for {[ya, x1a, x2a, _], [yb, x1b, x2b, _]} <-
          Enum.zip(Enum.sort(actual["grid"]), Enum.sort(reference["grid"])) do
      assert_in_delta ya, yb, 0.01
      assert_in_delta x1a, x1b, 0.01
      assert_in_delta x2a, x2b, 0.01
    end

    # Tooltip: formatted label, raw values, stacked active dots, no cursor.
    tooltip = @canvas <> " .recharts-tooltip-wrapper"

    conn
    |> focus(within(@canvas, role("application", "Total visitors")))
    |> assert_visible(tooltip)
    |> assert_contains(tooltip, "Jun 1")
    |> assert_contains(tooltip, "Mobile200")
    |> assert_contains(tooltip, "Desktop178")
    |> assert_count(@canvas <> " .recharts-tooltip-cursor", 0)
    |> assert_js(
      "(() => {const d=Array.from(document.querySelectorAll('#visitors-chart .recharts-active-dot circle')).map(c=>Number(c.getAttribute('cy')));return d.length===2&&Math.abs(d[0]-#{y.(200)})<.01&&Math.abs(d[1]-#{y.(378)})<.01;})()"
    )
  end

  describe "chart harness" do
    setup %{conn: conn} do
      {:ok, conn: conn |> visit("/chart-preview") |> connected()}
    end

    test "custom slot children size to the chart container, beside Recharts-parity content", %{
      conn: conn
    } do
      for {chart, child} <- [
            {"custom-fill", "#custom-fill-child"},
            {"custom-mixed", "#custom-mixed-svg"}
          ] do
        container = box(conn, "[data-chart=chart-#{chart}]")
        responsive = box(conn, "[data-chart=chart-#{chart}] .recharts-responsive-container")
        actual = box(conn, child)
        assert container["width"] > 500 and container["height"] == 200

        for key <- ~w(x y width height) do
          assert_in_delta actual[key], responsive[key], 0.5
          assert_in_delta actual[key], container[key], 0.5
        end
      end

      assert_attribute(conn, "#custom-fill-child", "data-context", "chart-custom-fill")
      assert_count(conn, "[data-chart=chart-custom-mixed] [data-slot=chart-custom]", 1)
    end

    test "stacked bars share one slot, gradients fill bars, grid follows both axes", %{conn: conn} do
      canvas = "#stacked-bars-canvas"

      conn
      |> assert_count(canvas <> " .recharts-bar-rectangles path", 8)
      |> assert_count(canvas <> " linearGradient", 2)
      |> assert_count(canvas <> " .recharts-cartesian-grid-horizontal line", 5)
      |> assert_count(canvas <> " .recharts-cartesian-grid-vertical line", 6)
      |> assert_js(
        "(() => {const g=Array.from(document.querySelectorAll('#{canvas} .recharts-bar')).map(s=>Array.from(s.querySelectorAll('path')).map(p=>({x:+p.getAttribute('x'),y:+p.getAttribute('y'),w:+p.getAttribute('width'),h:+p.getAttribute('height'),f:p.getAttribute('fill')})));return g.length===2&&g[0].every((a,i)=>{const b=g[1][i];return a.x===b.x&&a.w===b.w&&Math.abs(b.y+b.h-a.y)<.01&&a.f.startsWith('url(#')&&b.f.startsWith('url(#');});})()"
      )
      |> assert_js(
        "(() => {const s=document.querySelector('#{canvas} .recharts-bar-rectangles path').getBoundingClientRect(),c=document.querySelector('#{canvas} svg').getBoundingClientRect(),step=(c.width-10)/4;return Math.abs(s.width-Math.floor(step*0.8))<.01;})()"
      )
    end

    test "monotone and step curves and function tick formats", %{conn: conn} do
      conn
      |> assert_js(
        "/^M[^LZ]+C/.test(document.querySelector('#monotone-line .recharts-line-curve').getAttribute('d'))"
      )
      |> assert_js(
        "Array.from(document.querySelectorAll('#monotone-line .recharts-cartesian-axis-tick-value')).map(e=>e.textContent).join() === 'Feb,Mar,Apr'"
      )
      |> assert_js(
        "(() => {const d=document.querySelector('#step-area .recharts-area-curve').getAttribute('d');return !/C/.test(d)&&d.split('L').length===8;})()"
      )
      |> assert_count("#monotone-line .recharts-line-dot", 4)
    end
  end

  # Waits for loaded web fonts (tick thinning measures text) and settled paths and ticks.
  defp stable_geometry(conn) do
    PhoenixTest.Playwright.evaluate(conn, "document.fonts.ready.then(() => true)")

    assert_js(
      conn,
      "(() => {const q=s=>Array.from(document.querySelectorAll('#fixture-stage '+s));const d=q('.recharts-area-area').map(e=>e.getAttribute('d')).join()+q('.recharts-cartesian-axis-tick-value').map(e=>e.textContent+e.getAttribute('x')).join();const k=document.fonts.status==='loaded'&&window.__chartGeometry===d&&d.length>0;window.__chartGeometry=d;return k;})()",
      stable_frames: 20
    )

    value(conn, @geometry)
  end

  defp react_geometry(conn, fixture) do
    assert {:ok, page} = BrowserContext.new_page(conn.context_id, timeout: 5_000)
    reference = Map.merge(conn, %{page_id: page.guid, frame_id: page.main_frame.guid})

    try do
      reference
      |> visit("/preview/react-fixture.html?fixture=#{fixture}")
      |> assert_count("#fixture-stage .recharts-area-area", 2)
      |> stable_geometry()
    after
      assert {:ok, _} = Page.close(page.guid, timeout: 5_000)
    end
  end

  # Endpoints of an "M x,y C c1 c2 x,y ..." path.
  defp curve_points(d) do
    numbers =
      ~r/-?[\d.]+(?:e-?\d+)?/
      |> Regex.scan(d)
      |> Enum.map(fn [n] -> n |> Float.parse() |> elem(0) end)

    [x0, y0 | rest] = numbers
    [{x0, y0} | rest |> Enum.chunk_every(6) |> Enum.map(fn [_, _, _, _, x, y] -> {x, y} end)]
  end
end
