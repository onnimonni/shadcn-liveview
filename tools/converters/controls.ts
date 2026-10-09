import type { ComponentSpec } from "../generate"
import { binaryHook, sliderHook, thumbClass, indicatorClass } from "./controls-hooks"
import { navigation } from "./controls-navigation"

const nativeStyle = "position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
const switchThumbClass = "pointer-events-none block rounded-full bg-background ring-0 transition-transform group-data-[size=default]/switch:size-4 group-data-[size=sm]/switch:size-3 group-data-[size=default]/switch:data-checked:translate-x-[calc(100%-2px)] group-data-[size=sm]/switch:data-checked:translate-x-[calc(100%-2px)] dark:data-checked:bg-primary-foreground group-data-[size=default]/switch:data-unchecked:translate-x-0 group-data-[size=sm]/switch:data-unchecked:translate-x-0 dark:data-unchecked:bg-foreground"


function binary(spec: ComponentSpec): string {
  const checkbox = spec.name === "checkbox"
  const name = checkbox ? "checkbox" : "switch"
  const base = JSON.stringify(spec.functions.find(fn => fn.name === name)?.baseClasses ?? "")
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Native-form ${name} with a stable caller ID. checked controls server state;
  default_checked supplies the initial uncontrolled state. Uncontrolled values
  survive unrelated patches and retain their current value when checked becomes
  nil. Explicit checked values are authoritative on every patch.
  ${checkbox ? "Reset of the containing form restores the mounted initial state, even after\n  server patches. As in Radix, form= associates only the hidden input: reset of\n  an external form resets its submitted value but leaves the visual state unchanged." : "Reset of the containing or explicitly associated form restores the mounted\n  initial state, even after server patches."}
  on_change receives %{id => id, value => boolean} and respects the nearest phx-target.
  Labels target the button ID.
  Inline layout is preserved when placed beside other native controls.
  ${checkbox ? 'Use checked="indeterminate" for mixed state; its native input is unchecked.' : 'Space and Enter use native button activation.'}
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :checked, :any, default: nil
  attr :default_checked, :any, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: "on"
  attr :form, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :on_change, :string, default: nil
${checkbox ? "" : '  attr :size, :string, values: ~w(default sm), default: "default"\n'}  attr :class, :string, default: nil
  attr :rest, :global

  def ${name}(assigns) do
    checked = if is_nil(assigns.checked), do: assigns.default_checked, else: assigns.checked
    assigns = assign(assigns, state: state(checked), initial: state(checked))

    ~H"""
    <button id={@id} type="button" role="${name}" aria-checked={if @state == "indeterminate", do: "mixed", else: to_string(@state == "checked")}
      aria-required={if @required, do: "true"} data-state={@state} data-disabled={if @disabled, do: ""}
      disabled={@disabled} value={@value} data-slot="${name}" ${checkbox ? "" : 'data-size={@size}'}
      class={classes([${base}, @class])} phx-hook=".BinaryControl" phx-value-change={@on_change}
      phx-value-state={@state} phx-value-initial={@initial} phx-value-controlled={to_string(!is_nil(@checked))} {@rest}>
${checkbox ? `      <span :if={@state != "unchecked"} data-state={@state} data-disabled={if @disabled, do: ""}
        data-slot="checkbox-indicator" class="${indicatorClass}" style="pointer-events:none">
        <ShadcnLiveview.Components.Icon.icon name="check" />
      </span>` : `      <span data-state={@state} data-disabled={if @disabled, do: ""} data-slot="switch-thumb" class="${switchThumbClass}" />`}
    <script :type={Phoenix.LiveView.ColocatedHook} name=".BinaryControl">
${binaryHook}
    </script>
    </button><input type="checkbox" aria-hidden="true" required={@required} disabled={@disabled} form={@form}
      tabindex="-1" style="${nativeStyle}" name={@name} checked={@state == "checked"} value={@value} />
    """
  end

${checkbox ? '  defp state("indeterminate"), do: "indeterminate"\n  defp state(:indeterminate), do: "indeterminate"\n' : ""}  defp state(true), do: "checked"
  defp state(_value), do: "unchecked"
end
`
}


function slider(spec: ComponentSpec): string {
  const base = JSON.stringify(spec.functions.find(fn => fn.name === "slider")?.baseClasses ?? "")
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Slider with native submitted values, pointer capture, and keyboard stepping.
  Supply a stable ID; value/default_value are numeric lists. value is authoritative
  on every patch; uncontrolled values survive unrelated patches and keep their
  current value when value becomes nil. on_change receives
  %{"id" => id, "value" => values} and respects the nearest phx-target.
  Form reset restores the mounted initial value (default_value when supplied),
  not the latest server-patched value. Native submission follows current values,
  including when a patch changes the default list's thumb count. Disabled sliders
  ignore pointer and keyboard input but still submit their values, as in Radix.
  Focus stays on the same thumb index across patches while that thumb remains
  present and enabled; removed or disabled thumbs do not receive restored focus.
  SSR follows Radix's unmeasured thumbs; the hook measures the rendered values.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :value, :list, default: nil
  attr :default_value, :list, default: nil
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :min_steps_between_thumbs, :integer, default: 0
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"
  attr :inverted, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :on_change, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def slider(assigns) do
    assigns =
      assigns
      |> assign_slider_values()
      |> assign_slider_form()
      |> assign_slider_layout()

    ~H"""
    <span id={@id} dir={@dir} data-orientation={@orientation}
      aria-disabled={to_string(@disabled)} data-disabled={if @disabled, do: ""} data-slot="slider"
      style={"--radix-slider-thumb-transform:" <> @transform} class={classes([${base}, @class])}
      phx-hook=".Slider" phx-value-values={Jason.encode!(@control_values)} phx-value-initial={Jason.encode!(@initial)}
      phx-value-min={@min} phx-value-max={@max} phx-value-step={@step}
      phx-value-distance={@min_steps_between_thumbs} phx-value-inverted={to_string(@inverted)}
      phx-value-form={@form} phx-value-name={@name} phx-value-change={@on_change}
      phx-value-controlled={to_string(!is_nil(@value))} {@rest}>
      <span data-disabled={if @disabled, do: ""} data-orientation={@orientation} data-slot="slider-track"
        class="relative grow overflow-hidden rounded-full bg-muted data-horizontal:h-1 data-horizontal:w-full data-vertical:h-full data-vertical:w-1">
        <span data-orientation={@orientation} data-disabled={if @disabled, do: ""} data-slot="slider-range"
          class="absolute bg-primary select-none data-horizontal:h-full data-vertical:w-full" style={@range_style} />
      </span>
      <%= for _value <- @values do %>
        <span style={"transform:var(--radix-slider-thumb-transform);position:absolute;" <> @start_side <> ":calc(0% + 0px)"}>
          <span role="slider" aria-label={@thumb_label} aria-valuemin={@min} aria-valuemax={@max} aria-orientation={@orientation}
            data-orientation={@orientation} data-disabled={if @disabled, do: ""} tabindex={if !@disabled, do: "0"}
            data-slot="slider-thumb" class="${thumbClass}" style="display:none" data-radix-collection-item="" />
        </span><input style="display:none" name={@input_name} form={@form} />
      <% end %>
    </span>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Slider">
${sliderHook}
    </script>
    """
  end

  defp assign_slider_values(assigns) do
    values = assigns.value || assigns.default_value || [assigns.min, assigns.max]
    control_values = assigns.value || assigns.default_value || [assigns.min]

    assign(assigns,
      values: values,
      control_values: control_values,
      initial: assigns.default_value || control_values,
      thumb_label: unmeasured_thumb_label(length(control_values))
    )
  end

  defp assign_slider_form(assigns) do
    assign(assigns, :input_name, slider_input_name(assigns.name, assigns.control_values))
  end

  defp slider_input_name(nil, _values), do: nil
  defp slider_input_name(name, [_value]), do: name
  defp slider_input_name(name, []), do: name
  defp slider_input_name(name, _values), do: name <> "[]"

  defp unmeasured_thumb_label(count) when count > 2, do: "Value 0 of #{count}"
  defp unmeasured_thumb_label(_count), do: nil

  defp assign_slider_layout(assigns) do
    vertical = assigns.orientation == "vertical"
    reverse = if vertical, do: assigns.inverted, else: (assigns.dir == "rtl") != assigns.inverted
    {start_side, end_side} = sides(vertical, reverse)
    percentages = Enum.map(assigns.control_values, &percentage(&1, assigns.min, assigns.max))
    start = if length(percentages) > 1, do: Enum.min(percentages), else: 0
    finish = range_finish(percentages)

    assign(assigns,
      range_style: "#{start_side}:#{number(start)}%;#{end_side}:#{finish}%",
      start_side: start_side,
      transform: if(vertical, do: "translateY(50%)", else: "translateX(-50%)")
    )
  end

  defp range_finish([]), do: "Infinity"
  defp range_finish(percentages), do: number(100 - Enum.max(percentages))

  defp sides(true, false), do: {"bottom", "top"}
  defp sides(true, true), do: {"top", "bottom"}
  defp sides(false, false), do: {"left", "right"}
  defp sides(false, true), do: {"right", "left"}

  defp percentage(value, min, max), do: max(0, min(100, 100 / (max - min) * (value - min)))
  defp number(value) when is_integer(value), do: Integer.to_string(value)
  defp number(value) when value == trunc(value), do: Integer.to_string(trunc(value))
  defp number(value), do: Float.to_string(value)
end
`
}

function collapsible(spec: ComponentSpec): string {
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Server-controlled disclosure. Pass the root's :let context to its trigger and
  content. on_open_change receives %{"id" => id, "open" => boolean}; assign
  the returned open value on the next render. Events respect the nearest
  phx-target, and nested triggers operate only their nearest collapsible root.
  Closed content has no child markup.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :on_open_change, :string, default: "control_open"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def collapsible(assigns) do
    context = %{id: assigns.id, open: assigns.open, disabled: assigns.disabled}
    assigns = assign(assigns, :context, context)

    ~H"""
    <div id={@id} data-state={if @open, do: "open", else: "closed"} data-disabled={if @disabled, do: ""}
      data-slot="collapsible" class={classes([@class])} phx-hook=".Collapsible"
      phx-value-change={@on_open_change} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Collapsible">
      export default {
        mounted() {
          this.click = event => {
            const trigger = event.target.closest('[data-slot="collapsible-trigger"]');
            if (!trigger || trigger.closest('[data-slot="collapsible"]') !== this.el || trigger.disabled) return;
            this.sendEvent(this.el.getAttribute("phx-value-change"), {id:this.el.id, open:this.el.getAttribute("data-state") !== "open"});
          };
          this.el.addEventListener("click", this.click);
        },
        updated() {},
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute('phx-target');
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        destroyed() { this.el.removeEventListener("click", this.click); }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block, required: true

  def collapsible_trigger(assigns) do
    ~H"""
    <button type="button" aria-controls={if @context.open, do: "radix-" <> @context.id <> "-content"}
      aria-expanded={to_string(@context.open)} data-state={if @context.open, do: "open", else: "closed"}
      data-disabled={if @context.disabled, do: ""} disabled={@context.disabled}
      data-slot="collapsible-trigger" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def collapsible_content(assigns) do
    ~H"""
    <div id={"radix-" <> @context.id <> "-content"} data-state={if @context.open, do: "open", else: "closed"}
      data-disabled={if @context.disabled, do: ""} hidden={!@context.open && !@force_mount}
      data-slot="collapsible-content" class={classes([@class])} {@rest}>
      <%= if @context.open || @force_mount do %>{render_slot(@inner_block)}<% end %>
    </div>
    """
  end
end
`
}


export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name === "checkbox" || spec.name === "switch") return binary(spec)
  if (spec.name === "slider") return slider(spec)
  if (spec.name === "collapsible") return collapsible(spec)
  if (spec.name === "navigation-menu") return navigation(spec)
  return undefined
}
