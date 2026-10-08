import type { ComponentSpec } from "../generate"

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name !== "chart") return undefined
  const baseClasses = spec.functions.find((fn) => fn.name === "chart_container")?.baseClasses
  if (!baseClasses) throw new Error("ChartContainer classes were not extracted")
  return String.raw`defmodule ShadcnLiveview.Components.Chart do
  @moduledoc """
  Responsive charts without a React runtime. Give each container a stable caller ID and
  use its :let context for chart_canvas, tooltip and legend content.

  Config maps associate series keys with label, a Lucide icon name, and either
  color or theme: %{light: color, dark: color}. An ordered list of key/config
  pairs may be used when CSS declaration order matters. Data is a list of row maps;
  series is a list of keys or maps with key, optional label and color.

  The canvas supports grouped bars, lines and areas, signed values, missing samples,
  axes, a pointer/keyboard tooltip and an optional legend. Its colocated SVG hook
  observes the responsive container and redraws after LiveView data patches. It uses
  only DOM/SVG APIs. chart_canvas creates a stable identified LiveView shell around
  its server-owned geometry wrapper; the hook redraws only that wrapper's SVG,
  tooltip and legend children. Caller attrs and the shell survive data updates.
  A sized browser mounts the SVG; initial SSR deliberately emits the same empty
  geometry wrapper as Recharts 3, whose layout is initialized in effects.
  Ordinary container slots render on SSR when initial dimensions are positive.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  @type series_key :: atom() | String.t()
  @type series_config :: %{optional(:label) => term(), optional(:icon) => String.t(),
    optional(:color) => String.t(), optional(:theme) => %{light: String.t(), dark: String.t()}}
  @type chart_config :: %{optional(series_key()) => series_config()} | [{series_key(), series_config()}]
  @type chart_context :: %{id: String.t(), config: chart_config(), width: number(), height: number()}

  attr :id, :string, required: true
  attr :config, :any, required: true
  attr :initial_dimension, :map, default: %{width: 320, height: 200}
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "Wraps responsive content and passes explicit configuration/dimensions through the slot."
  def chart_container(assigns) do
    config = validate_config!(assigns.config)
    id = "chart-" <> safe_key!(assigns.id)
    width = field(assigns.initial_dimension, :width, 320)
    height = field(assigns.initial_dimension, :height, 200)
    unless is_number(width) and is_number(height), do: raise(ArgumentError, "chart dimensions must be numbers")
    assigns = assign(assigns, chart_id: id, config: config,
      context: %{id: id, config: config, width: width, height: height}, visible: width > 0 and height > 0)
    ~H"""
    <div data-slot="chart" data-chart={@chart_id} class={classes([__BASE__, @class])} {@rest}>
      <.chart_style id={@chart_id} config={@config} />
      <div class="recharts-responsive-container" style="width:100%;height:100%;min-width:0">
        <div style="width:0;height:0;overflow:visible">
          {if @visible, do: render_slot(@inner_block, @context)}
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :config, :any, required: true

  @doc "Emits scoped light/dark CSS custom properties for configured colors."
  def chart_style(assigns) do
    entries = assigns.config |> validate_config!() |> Enum.filter(&color_config?/1)
    assigns = assign(assigns, :css, chart_css(assigns.id, entries))
    ~H"""
    <style :if={@css}><%= Phoenix.HTML.raw(@css) %></style>
    """
  end

  defp color_config?({_, item}), do: field(item, :theme) || field(item, :color)

  defp chart_css(_, []), do: nil
  defp chart_css(id, entries) do
    id = safe_key!(id)
    Enum.map_join([{:light, ""}, {:dark, ".dark"}], "\n", &theme_css(id, entries, &1))
  end

  defp theme_css(id, entries, {theme, prefix}) do
    declarations = Enum.map_join(entries, "\n", &color_declaration(&1, theme))
    "\n#{prefix} [data-chart=#{id}] {\n#{declarations}\n}\n"
  end

  defp color_declaration({key, item}, theme) do
    color = field(field(item, :theme, %{}), theme) || field(item, :color)
    "  --color-#{key}: #{color};"
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :data, :list, default: []
  attr :series, :list, default: []
  attr :kind, :string, default: "bar", values: ~w(bar line area)
  attr :x_key, :string, default: "name"
  attr :label, :string, default: "Chart"
  attr :axes, :boolean, default: true
  attr :tooltip, :boolean, default: true
  attr :legend, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  @doc "Renders data-driven SVG on mount/resize; each canvas requires its own stable DOM ID."
  def chart_canvas(assigns) do
    unless Enum.all?(assigns.data, &is_map/1), do: raise(ArgumentError, "chart data must contain row maps")
    config = Map.new(assigns.context.config)
    series = Enum.map(assigns.series, fn item ->
      key = safe_key!(if is_map(item), do: field(item, :key), else: item)
      item_config = config_item(config, key)
      %{key: key, label: if(is_map(item), do: field(item, :label), else: nil) || field(item_config, :label, key),
        color: if(is_map(item), do: field(item, :color), else: nil) || "var(--color-#{key}, currentColor)"}
    end)
    payload = %{data: assigns.data, series: series, kind: assigns.kind, xKey: assigns.x_key,
      label: assigns.label, axes: assigns.axes, tooltip: assigns.tooltip, legend: assigns.legend}
    assigns = assign(assigns, width: assigns.context.width, height: assigns.context.height, payload: Jason.encode!(payload))
    ~H"""
    <div id={@id} phx-hook=".ChartCanvas" phx-value-chart={@payload}>
      <div width={@width} height={@height} class={classes(["recharts-wrapper", @class])}
        style={"position:relative;cursor:default;width:#{@width}px;height:#{@height}px"} {@rest}></div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChartCanvas">
      export default {
        mounted() {
          this.container = this.el.closest(".recharts-responsive-container");
          this.resize = () => this.draw();
          this.observer = new ResizeObserver(this.resize);
          this.observer.observe(this.container);
          this.draw();
        },
        updated() { this.draw(); },
        destroyed() {
          this.observer.disconnect();
          this.cleanListeners();
        },
        cleanListeners() {
          for (const [node, event, handler] of this.listeners || []) node.removeEventListener(event, handler);
          this.listeners = [];
        },
        draw() {
          this.cleanListeners();
          const options = JSON.parse(this.el.getAttribute("phx-value-chart"));
          this.canvas = this.el.querySelector(".recharts-wrapper");
          const box = this.container.getBoundingClientRect();
          if (box.width <= 0 || box.height <= 0) { this.canvas.replaceChildren(); return; }
          const width = Math.round(box.width), height = Math.round(box.height);
          this.canvas.style.width = width + "px";
          this.canvas.style.height = height + "px";
          this.canvas.setAttribute("width", width);
          this.canvas.setAttribute("height", height);
          const svgNode = (tag, attrs, text) => {
            const node = document.createElementNS("http://www.w3.org/2000/svg", tag);
            for (const [key, value] of Object.entries(attrs || {})) node.setAttribute(key, String(value));
            if (text !== undefined) node.textContent = String(text);
            return node;
          };
          const svg = svgNode("svg", {width, height, viewBox: "0 0 " + width + " " + height,
            role: "img", "aria-label": options.label, class: "recharts-surface"});
          svg.append(svgNode("title", {}, options.label));
          this.canvas.replaceChildren(svg);
          const data = options.data, series = options.series;
          if (!data.length || !series.length) {
            svg.append(svgNode("text", {x: width / 2, y: height / 2, "text-anchor": "middle", fill: "currentColor"}, "No data"));
            return;
          }
          const left = options.axes ? 44 : 8, top = 12;
          const bottom = Math.max(top + 1, height - (options.axes ? 30 : 8) - (options.legend ? 24 : 0));
          const right = Math.max(left + 1, width - 12), plotWidth = right - left, plotHeight = bottom - top;
          const number = (row, key) => typeof row[key] === "number" && Number.isFinite(row[key]) ? row[key] : null;
          const values = data.flatMap(row => series.map(item => number(row, item.key))).filter(value => value !== null);
          const minimum = Math.min(0, ...values), maximum = Math.max(0, ...values);
          const span = maximum - minimum || 1;
          const y = value => bottom - (value - minimum) / span * plotHeight;
          const step = plotWidth / data.length;
          const x = index => left + step * (index + 0.5);
          const zero = y(0);
          if (options.axes) {
            for (let index = 0; index <= 4; index++) {
              const value = minimum + span * index / 4, yy = y(value);
              svg.append(svgNode("line", {x1: left, y1: yy, x2: right, y2: yy, stroke: "var(--border, #ccc)", "stroke-opacity": 0.5}));
              svg.append(svgNode("text", {x: left - 6, y: yy + 4, "text-anchor": "end", fill: "currentColor", "font-size": 10}, Number(value.toFixed(2)).toLocaleString()));
            }
            const interval = Math.max(1, Math.ceil(data.length / Math.max(1, Math.floor(plotWidth / 60))));
            data.forEach((row, index) => {
              if (index % interval === 0) svg.append(svgNode("text", {x: x(index), y: bottom + 18, "text-anchor": "middle", fill: "currentColor", "font-size": 10}, row[options.xKey] ?? index + 1));
            });
          }
          const tooltip = document.createElement("div");
          tooltip.className = "rounded-lg border bg-background px-2.5 py-1.5 text-xs shadow-xl";
          Object.assign(tooltip.style, {position: "absolute", pointerEvents: "none", zIndex: "1", display: "none"});
          if (options.tooltip) this.canvas.append(tooltip);
          const show = index => {
            if (!options.tooltip) return;
            tooltip.replaceChildren();
            const heading = document.createElement("div");
            heading.className = "font-medium";
            heading.textContent = String(data[index][options.xKey] ?? index + 1);
            tooltip.append(heading);
            series.forEach(item => {
              const value = number(data[index], item.key);
              if (value === null) return;
              const row = document.createElement("div");
              row.textContent = item.label + ": " + value.toLocaleString();
              tooltip.append(row);
            });
            tooltip.style.display = "block";
            tooltip.style.left = Math.min(x(index), Math.max(0, width - tooltip.offsetWidth)) + "px";
            tooltip.style.top = top + "px";
          };
          const listen = (node, event, handler) => {
            node.addEventListener(event, handler);
            this.listeners.push([node, event, handler]);
          };
          series.forEach((item, seriesIndex) => {
            if (options.kind === "bar") {
              const barWidth = step * 0.8 / series.length;
              data.forEach((row, index) => {
                const value = number(row, item.key);
                if (value === null) return;
                const rect = svgNode("rect", {x: x(index) - step * 0.4 + seriesIndex * barWidth,
                  y: Math.min(zero, y(value)), width: Math.max(0.5, barWidth - 1),
                  height: Math.abs(zero - y(value)), fill: item.color, class: "recharts-rectangle"});
                rect.append(svgNode("title", {}, item.label + ": " + value.toLocaleString()));
                svg.append(rect);
              });
            } else {
              let segment = [];
              const flush = () => {
                if (!segment.length) return;
                const points = segment.map(point => point.join(",")).join(" ");
                if (options.kind === "area") {
                  const areaPoints = segment[0][0] + "," + zero + " " + points + " " + segment[segment.length - 1][0] + "," + zero;
                  svg.append(svgNode("polygon", {points: areaPoints, fill: item.color, "fill-opacity": 0.2}));
                }
                svg.append(svgNode("polyline", {points, fill: "none", stroke: item.color, "stroke-width": 2, class: "recharts-curve"}));
                segment = [];
              };
              data.forEach((row, index) => {
                const value = number(row, item.key);
                if (value === null) { flush(); return; }
                segment.push([x(index), y(value)]);
                const dot = svgNode("circle", {cx: x(index), cy: y(value), r: 3, fill: item.color, class: "recharts-dot"});
                dot.append(svgNode("title", {}, item.label + ": " + value.toLocaleString()));
                svg.append(dot);
              });
              flush();
            }
          });
          const targets = data.map((row, index) => {
            const target = svgNode("rect", {x: left + index * step, y: top, width: step, height: plotHeight,
              fill: "transparent", tabindex: 0, role: "graphics-symbol", "aria-label": String(row[options.xKey] ?? index + 1) + ": " + series.map(item => item.label + " " + (number(row, item.key) ?? "No data")).join(", ")});
            svg.append(target);
            listen(target, "pointerenter", () => show(index));
            listen(target, "focus", () => show(index));
            listen(target, "keydown", event => {
              if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
                event.preventDefault();
                targets[(index + (event.key === "ArrowRight" ? 1 : data.length - 1)) % data.length].focus();
              } else if (event.key === "Escape") tooltip.style.display = "none";
            });
            return target;
          });
          listen(svg, "pointerleave", () => tooltip.style.display = "none");
          listen(svg, "focusout", event => { if (!svg.contains(event.relatedTarget)) tooltip.style.display = "none"; });
          if (options.legend) {
            const legend = document.createElement("div");
            legend.className = "flex items-center justify-center gap-4 pt-3";
            Object.assign(legend.style, {position: "absolute", bottom: "0", width: "100%"});
            series.forEach(item => {
              const entry = document.createElement("span"), swatch = document.createElement("span");
              entry.className = "flex items-center gap-1.5";
              swatch.className = "h-2 w-2 shrink-0 rounded-[2px]";
              swatch.style.backgroundColor = item.color;
              entry.append(swatch, document.createTextNode(item.label));
              legend.append(entry);
            });
            this.canvas.append(legend);
          }
        }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :payload, :list, default: []
  attr :vertical_align, :string, default: "bottom"
  attr :hide_icon, :boolean, default: false
  attr :name_key, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :icon
  slot :label

  @doc "Renders a configured legend; icon and label slots receive the payload/config pair."
  def chart_legend_content(assigns) do
    assigns = assign(assigns, :items, payload_items(assigns.context.config, assigns.payload, assigns.name_key, :dataKey))
    ~H"""
    <div :if={@payload != []} class={classes(["flex items-center justify-center gap-4", if(@vertical_align == "top", do: "pb-3", else: "pt-3"), @class])} {@rest}>
      <div :for={item <- @items} class="flex items-center gap-1.5 [&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground">
        <%= if !@hide_icon && (field(item.config, :icon) || @icon != []) do %>
          <%= if @icon != [] do %>{render_slot(@icon, item)}<% else %>
            <ShadcnLiveview.Components.Icon.icon name={field(item.config, :icon)} />
          <% end %>
        <% else %>
          <div class="h-2 w-2 shrink-0 rounded-[2px]" style={css_property("background-color", field(item.payload, :color))}></div>
        <% end %>
        {if @label != [], do: render_slot(@label, item), else: field(item.config, :label)}
      </div>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :active, :boolean, default: false
  attr :payload, :list, default: []
  attr :indicator, :string, default: "dot", values: ~w(dot line dashed)
  attr :hide_label, :boolean, default: false
  attr :hide_indicator, :boolean, default: false
  attr :label, :any, default: nil
  attr :name_key, :string, default: nil
  attr :label_key, :string, default: nil
  attr :color, :string, default: nil
  attr :label_class, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :label_content
  slot :value
  slot :item
  slot :icon

  @doc "Renders active tooltip payload. Formatting slots replace label, value, item or icon markup."
  def chart_tooltip_content(assigns) do
    label = resolve_tooltip_label(assigns)
    assigns = assign(assigns, tooltip_label: label, nested: length(assigns.payload) == 1 && assigns.indicator != "dot",
      items: payload_items(assigns.context.config, assigns.payload, assigns.name_key, :name),
      label_content: if(assigns.hide_label, do: [], else: assigns.label_content))
    ~H"""
    <div :if={@active && @payload != []} class={classes(["grid min-w-32 items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl", @class])} {@rest}>
      <.tooltip_label :if={!@nested} label={@tooltip_label} class={@label_class} content={@label_content} payload={@payload} />
      <div class="grid gap-1.5">
        <div :for={item <- @items} class={classes(["flex w-full flex-wrap gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5 [&>svg]:text-muted-foreground", if(@indicator == "dot", do: "items-center", else: "items-stretch")])}>
          <%= if @item != [] do %>{render_slot(@item, item)}<% else %>
            <%= if field(item.config, :icon) || @icon != [] do %>
              <%= if @icon != [] do %>{render_slot(@icon, item)}<% else %>
                <ShadcnLiveview.Components.Icon.icon name={field(item.config, :icon)} />
              <% end %>
            <% else %>
              <div :if={!@hide_indicator} class={classes(["shrink-0 rounded-[2px] border-(--color-border)", if(@indicator != "dashed", do: "bg-(--color-bg)"), indicator_class(@indicator), if(@nested && @indicator == "dashed", do: "my-0.5")])}
                style={indicator_style(@color || field(field(item.payload, :payload, %{}), :fill) || field(item.payload, :color))}></div>
            <% end %>
            <div class={classes(["flex flex-1 justify-between leading-none", if(@nested, do: "items-end", else: "items-center")])}>
              <div class="grid gap-1.5">
                <.tooltip_label :if={@nested} label={@tooltip_label} class={@label_class} content={@label_content} payload={@payload} />
                <span class="text-muted-foreground">{field(item.config, :label, field(item.payload, :name))}</span>
              </div>
              <span :if={!is_nil(field(item.payload, :value))} class="font-mono font-medium text-foreground tabular-nums">
                {if @value != [], do: render_slot(@value, item), else: format_value(field(item.payload, :value))}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp resolve_tooltip_label(%{hide_label: true}), do: nil
  defp resolve_tooltip_label(%{payload: []}), do: nil
  defp resolve_tooltip_label(%{label_key: nil, label: label, context: context}) when is_binary(label) do
    field(config_item(context.config, label), :label, label)
  end
  defp resolve_tooltip_label(assigns) do
    first = hd(assigns.payload)
    key = assigns.label_key || field(first, :dataKey) || field(first, :name) || "value"
    assigns.context.config |> payload_config(first, to_string(key)) |> field(:label)
  end

  attr :label, :any, default: nil
  attr :class, :string, default: nil
  attr :content, :list, default: []
  attr :payload, :list, default: []

  defp tooltip_label(assigns) do
    ~H"""
    <div :if={@label || @content != []} class={classes(["font-medium", @class])}>
      {if @content != [], do: render_slot(@content, %{label: @label, payload: @payload}), else: @label}
    </div>
    """
  end

  defp indicator_class("dot"), do: "h-2.5 w-2.5"
  defp indicator_class("line"), do: "w-1"
  defp indicator_class("dashed"), do: "w-0 border-[1.5px] border-dashed bg-transparent"
  defp indicator_style(nil), do: nil
  defp indicator_style(color), do: "--color-bg:#{safe_color!(color)};--color-border:#{safe_color!(color)}"
  defp css_property(_, nil), do: nil
  defp css_property(key, color), do: "#{key}:#{safe_color!(color)}"

  defp payload_items(config, payload, name_key, default_key) do
    payload |> Enum.reject(&(field(&1, :type) == "none")) |> Enum.map(fn item ->
      key = name_key || field(item, default_key) || field(item, :dataKey) || "value"
      %{payload: item, config: payload_config(config, item, to_string(key))}
    end)
  end

  defp payload_config(config, payload, key) do
    nested = field(payload, :payload, %{})
    label_key = cond do
      is_binary(field(payload, key)) -> field(payload, key)
      is_binary(field(nested, key)) -> field(nested, key)
      true -> key
    end
    config_item(config, label_key) || config_item(config, key) || %{}
  end

  defp config_item(config, key) do
    Enum.find_value(config, fn {config_key, value} -> if to_string(config_key) == to_string(key), do: value end)
  end

  defp field(map, key, default \\ nil)
  defp field(map, key, default) when is_map(map) do
    case Enum.find(map, fn {candidate, _} -> to_string(candidate) == to_string(key) end) do
      {_, value} -> value
      nil -> default
    end
  end
  defp field(_, _, default), do: default

  defp validate_config!(config) when is_map(config) or is_list(config) do
    Enum.map(config, fn {key, item} ->
      key = safe_key!(key)
      unless is_map(item), do: raise(ArgumentError, "chart series config must be a map")
      color = field(item, :color)
      theme = field(item, :theme)
      if color && theme, do: raise(ArgumentError, "chart config uses either color or theme, not both")
      if color, do: safe_color!(color)
      validate_theme!(theme)
      {key, item}
    end)
  end
  defp validate_config!(_), do: raise(ArgumentError, "chart config must be a map or ordered pairs")

  defp validate_theme!(nil), do: :ok
  defp validate_theme!(theme) do
    Enum.each([:light, :dark], fn name -> safe_color!(field(theme, name)) end)
  end

  defp safe_key!(key) when is_atom(key), do: safe_key!(Atom.to_string(key))
  defp safe_key!(key) when is_binary(key) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]+$/, key), do: key, else: raise(ArgumentError, "chart IDs and series keys must be CSS identifiers")
  end
  defp safe_key!(_), do: raise(ArgumentError, "chart IDs and series keys must be strings or atoms")

  defp safe_color!(color) when is_binary(color) do
    if color != "" && !Regex.match?(~r/[;{}<>\r\n]/, color), do: color, else: raise(ArgumentError, "invalid chart color")
  end
  defp safe_color!(_), do: raise(ArgumentError, "chart theme colors must be strings")

  defp format_value(value) when is_number(value) do
    [integer | decimals] = String.split(to_string(value), ".", parts: 2)
    grouped = Regex.replace(~r/(\d)(?=(\d{3})+(?!\d))/, integer, "\\1,")
    Enum.join([grouped | decimals], ".")
  end
  defp format_value(value), do: to_string(value)
end
`.replace("__BASE__", JSON.stringify(baseClasses))
}
