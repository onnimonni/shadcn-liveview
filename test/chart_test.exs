defmodule ShadcnLiveview.ChartTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import ShadcnLiveview.Components.Chart

  alias Phoenix.HTML.Safe

  test "instance contexts isolate colors and serialize real signed chart data" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container :let={chart} id="first" config={%{sales: %{label: "First", color: "#123"}}}>
        <.chart_canvas
          id="first-canvas"
          context={chart}
          data={[%{name: "A", sales: -5}]}
          series={[:sales]}
        />
      </.chart_container>
      <.chart_container :let={chart} id="second" config={%{sales: %{label: "Second", color: "#456"}}}>
        <.chart_canvas
          id="second-canvas"
          context={chart}
          data={[%{name: "B", sales: 20}]}
          series={[:sales]}
          kind="line"
        />
      </.chart_container>
      """)

    assert Floki.attribute(document, "[data-slot=chart]", "data-chart") == [
             "chart-first",
             "chart-second"
           ]

    [first] = Floki.attribute(document, "#first-canvas", "phx-value-chart")
    [second] = Floki.attribute(document, "#second-canvas", "phx-value-chart")
    first_data = Jason.decode!(first)
    second_data = Jason.decode!(second)
    assert first_data["data"] == [%{"name" => "A", "sales" => -5}]

    assert first_data["series"] == [
             %{
               "key" => "sales",
               "label" => "First",
               "color" => "var(--color-sales, currentColor)"
             }
           ]

    assert second_data["kind"] == "line"
    assert hd(second_data["series"])["label"] == "Second"

    assert document |> Floki.find("[data-chart=chart-first] style") |> Floki.text() =~
             "--color-sales: #123;"

    assert document |> Floki.find("[data-chart=chart-second] style") |> Floki.text() =~
             "--color-sales: #456;"

    assert Floki.find(document, "svg") == []
  end

  test "theme stylesheet preserves ordered config and does not emit label-only colors" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_style
        id="chart-themed"
        config={[
          mobile: %{theme: %{light: "#111", dark: "#222"}},
          desktop: %{color: "var(--primary)"},
          label: %{label: "No color"}
        ]}
      />
      """)

    css = document |> Floki.find("style") |> Floki.text()
    assert css =~ "[data-chart=chart-themed]"
    assert css =~ ".dark [data-chart=chart-themed]"
    assert css =~ "--color-mobile: #111;"
    assert css =~ "--color-mobile: #222;"
    assert css =~ "--color-desktop: var(--primary);"
    assert css =~ ~r/--color-mobile: #111;\s+--color-desktop: var\(--primary\);/
    assert css =~ ~r/--color-mobile: #222;\s+--color-desktop: var\(--primary\);/
    refute css =~ "--color-label"
  end

  test "tooltip resolves payload name keys, filters none and formats through value slots" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container :let={chart} id="tooltip" config={%{desktop: %{label: "Desktop"}}}>
        <.chart_tooltip_content
          context={chart}
          active
          name_key="kind"
          label="January"
          payload={[
            %{name: "sales", value: 25, payload: %{kind: "desktop"}},
            %{name: "hidden", value: 99, type: "none"}
          ]}
        >
          <:value :let={item}>{item.payload.value}%</:value>
        </.chart_tooltip_content>
      </.chart_container>
      """)

    text = Floki.text(document)
    assert text =~ "January"
    assert text =~ "Desktop"
    assert text =~ "25%"
    refute text =~ "hidden"
    refute text =~ "99"
  end

  test "canvas boundary preserves the empty initial geometry and custom dimensions" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container
        :let={chart}
        id="geometry"
        config={%{}}
        initial_dimension={%{width: 480, height: 260}}
      >
        <.chart_canvas id="geometry-canvas" context={chart} kind="area" />
      </.chart_container>
      """)

    [{"div", _attributes, children} = geometry] =
      Floki.find(document, "#geometry-canvas > .recharts-wrapper")

    assert Floki.attribute([geometry], "width") == ["480"]
    assert Floki.attribute([geometry], "height") == ["260"]

    assert Floki.attribute([geometry], "style") == [
             "position:relative;cursor:default;width:480px;height:260px"
           ]

    assert children == []
    assert Floki.find(document, "style") == []
  end

  test "tooltip label keys resolve nested config and preserve zero values" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container :let={chart} id="nested" config={%{desktop: %{label: "Desktop"}}}>
        <.chart_tooltip_content
          context={chart}
          active
          indicator="dashed"
          label_key="kind"
          name_key="kind"
          payload={[%{name: "sales", value: 0, payload: %{kind: "desktop", fill: "#123"}}]}
        />
      </.chart_container>
      """)

    assert Floki.text(document) =~ "Desktop"
    value = document |> Floki.find("span.font-mono") |> Floki.text() |> String.trim()
    assert Integer.parse(value) == {0, ""}

    assert Floki.attribute(document, ".border-dashed", "style") == [
             "--color-bg:#123;--color-border:#123"
           ]
  end

  test "hidden and inactive tooltip labels do not invoke label content" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container :let={chart} id="hidden" config={%{desktop: %{label: "Desktop"}}}>
        <.chart_tooltip_content
          context={chart}
          active
          hide_label
          hide_indicator
          label="January"
          payload={[%{name: "desktop", value: 12}]}
        >
          <:label_content>Hidden label formatter</:label_content>
        </.chart_tooltip_content>
        <.chart_tooltip_content
          context={chart}
          payload={[%{name: "desktop", value: 99}]}
        >
          <:label_content>Inactive label formatter</:label_content>
        </.chart_tooltip_content>
      </.chart_container>
      """)

    text = Floki.text(document)
    assert text =~ "Desktop"
    assert text =~ "12"
    refute text =~ "January"
    refute text =~ "formatter"
    refute text =~ "99"
    assert Floki.find(document, "[style^='--color-bg']") == []
  end

  test "color declarations cannot escape their scoped stylesheet" do
    assigns = %{config: %{sales: %{color: "red;} </style><script>bad()</script>"}}}

    assert_raise ArgumentError, "invalid chart color", fn ->
      parse(~H"""
      <.chart_style id="chart-safe" config={@config} />
      """)
    end
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
