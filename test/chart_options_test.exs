defmodule ShadcnLiveview.ChartOptionsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import ShadcnLiveview.Components.Chart

  alias Phoenix.HTML.Safe

  @rows [
    %{date: "2024-04-05", desktop: 373, mobile: 290},
    %{date: ~D[2024-06-30], desktop: 446, mobile: 400}
  ]

  test "default canvas payload carries no optional chart features" do
    assigns = %{rows: @rows}

    payload =
      canvas_payload(~H"""
      <.chart_container :let={chart} id="defaults" config={%{desktop: %{label: "Desktop"}}}>
        <.chart_canvas
          id="defaults-canvas"
          context={chart}
          data={@rows}
          series={[:desktop]}
          x_key="date"
        />
      </.chart_container>
      """)

    assert payload |> Map.keys() |> Enum.sort() ==
             ~w(axes data kind label legend series tooltip xKey)

    assert payload["series"] == [
             %{
               "key" => "desktop",
               "label" => "Desktop",
               "color" => "var(--color-desktop, currentColor)"
             }
           ]
  end

  test "dashboard area options serialize stacks, curves, fills, grid, axis and server-formatted labels" do
    assigns = %{rows: @rows}

    payload =
      canvas_payload(~H"""
      <.chart_container
        :let={chart}
        id="visitors"
        config={%{desktop: %{label: "Desktop"}, mobile: %{label: "Mobile"}}}
      >
        <.chart_canvas
          id="visitors-canvas"
          context={chart}
          kind="area"
          data={@rows}
          x_key="date"
          series={[
            %{key: "mobile", gradient_opacity: [0.8, 0.1]},
            %{key: "desktop", gradient_opacity: [1.0, 0.1], fill_opacity: 0.4},
            %{key: "other", stack: false}
          ]}
          stack
          curve="natural"
          fill="gradient"
          grid="horizontal"
          axis_line={false}
          tick_line={false}
          tick_margin={8}
          min_tick_gap={32}
          tick_format="date_short"
          tooltip_label_format={&"Day #{&1}"}
          cursor={false}
        />
      </.chart_container>
      """)

    assert Enum.map(
             payload["series"],
             &{&1["key"], &1["stack"], &1["gradientOpacity"], &1["fillOpacity"]}
           ) == [
             {"mobile", "stack", [0.8, 0.1], nil},
             {"desktop", "stack", [1.0, 0.1], 0.4},
             {"other", nil, nil, nil}
           ]

    assert Map.take(payload, ~w(curve fill grid axisLine tickLine tickMargin minTickGap cursor)) ==
             %{
               "curve" => "natural",
               "fill" => "gradient",
               "grid" => "horizontal",
               "axisLine" => false,
               "tickLine" => false,
               "tickMargin" => 8,
               "minTickGap" => 32,
               "cursor" => false
             }

    assert payload["ticks"] == ["Apr 5", "Jun 30"]
    assert payload["tooltipLabels"] == ["Day 2024-04-05", "Day 2024-06-30"]
    refute Map.has_key?(payload, "fillOpacity")
  end

  test "named stack IDs and invalid options are validated on the server" do
    assigns = %{rows: @rows}

    payload =
      canvas_payload(~H"""
      <.chart_container :let={chart} id="bars" config={%{}}>
        <.chart_canvas
          id="bars-canvas"
          context={chart}
          data={@rows}
          series={[:desktop, %{key: :mobile, stack: :other}]}
          stack={:sales}
          fill_opacity={1}
        />
      </.chart_container>
      """)

    assert Enum.map(payload["series"], & &1["stack"]) == ["sales", "other"]
    assert payload["fillOpacity"] == 1

    for {attr, value, message} <- [
          {:stack, 3, "chart stack must be a boolean or a stack ID"},
          {:gradient_opacity, [1], "chart gradient_opacity must be two numbers"},
          {:fill_opacity, "0.5", "chart opacities must be numbers"},
          {:tick_format, "iso", "unsupported chart label format: \"iso\""}
        ] do
      assigns = %{rows: @rows, options: %{attr => value}}

      assert_raise ArgumentError, message, fn ->
        canvas_payload(~H"""
        <.chart_container :let={chart} id="invalid" config={%{}}>
          <.chart_canvas
            id="invalid-canvas"
            context={chart}
            data={@rows}
            series={[:desktop]}
            x_key="date"
            {@options}
          />
        </.chart_container>
        """)
      end
    end
  end

  test "caller aspect ratio replaces the container's aspect-video like tailwind-merge" do
    assigns = %{}

    [class] =
      ~H"""
      <.chart_container id="dashboard" config={%{}} class="aspect-auto h-[250px] w-full">
        <p>Chart</p>
      </.chart_container>
      """
      |> parse()
      |> Floki.attribute("[data-slot=chart]", "class")

    classes = String.split(class)
    assert "aspect-auto" in classes
    refute "aspect-video" in classes
  end

  test "custom slot fills the responsive container while default slots keep the zero-size shell" do
    assigns = %{}

    document =
      parse(~H"""
      <.chart_container id="plain" config={%{}}>
        <p>Parity</p>
      </.chart_container>
      <.chart_container id="custom" config={%{}}>
        <:custom :let={chart}>
          <div id="custom-child" data-context={chart.id}></div>
        </:custom>
      </.chart_container>
      <.chart_container id="mixed" config={%{}}>
        <p>Recharts content</p>
        <:custom><svg id="mixed-svg"></svg></:custom>
      </.chart_container>
      """)

    plain = Floki.find(document, "[data-chart=chart-plain] .recharts-responsive-container > div")
    assert Floki.attribute(plain, "style") == ["width:0;height:0;overflow:visible"]
    assert Floki.text(plain) =~ "Parity"

    custom = Floki.find(document, "[data-chart=chart-custom] [data-slot=chart-custom]")
    assert Floki.attribute(custom, "style") == ["position:relative;width:100%;height:100%"]
    assert Floki.attribute(custom, "#custom-child", "data-context") == ["chart-custom"]

    assert document
           |> Floki.find("[data-chart=chart-mixed] .recharts-responsive-container > div")
           |> Enum.map(&Floki.attribute(&1, "style")) == [
             ["width:0;height:0;overflow:visible"],
             ["position:relative;width:100%;height:100%"]
           ]
  end

  defp canvas_payload(rendered) do
    rendered
    |> parse()
    |> Floki.attribute("[phx-value-chart]", "phx-value-chart")
    |> hd()
    |> Jason.decode!()
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
