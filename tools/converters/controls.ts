import type { ComponentSpec } from "../generate"

const nativeStyle = "position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
const thumbClass = "relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50"
const switchThumbClass = "pointer-events-none block rounded-full bg-background ring-0 transition-transform group-data-[size=default]/switch:size-4 group-data-[size=sm]/switch:size-3 group-data-[size=default]/switch:data-checked:translate-x-[calc(100%-2px)] group-data-[size=sm]/switch:data-checked:translate-x-[calc(100%-2px)] dark:data-checked:bg-primary-foreground group-data-[size=default]/switch:data-unchecked:translate-x-0 group-data-[size=sm]/switch:data-unchecked:translate-x-0 dark:data-unchecked:bg-foreground"
const indicatorClass = "grid place-content-center text-current transition-none [&>svg]:size-3.5"

const binaryHook = `      export default {
        mounted() {
          this.input = this.el.nextElementSibling;
          this.initial = this.el.getAttribute("phx-value-initial");
          this.click = () => {
            if (this.el.disabled) return;
            this.setState(this.el.getAttribute("data-state") === "checked" ? "unchecked" : "checked", true);
          };
          this.reset = () => { this.resetFrame = requestAnimationFrame(() => this.setState(this.initial, true)); };
          this.invalid = () => this.el.focus();
          this.el.addEventListener("click", this.click);
          this.input.addEventListener("invalid", this.invalid);
          this.updated();
        },
        updated() {
          const input = this.el.nextElementSibling;
          if (input !== this.input) {
            this.input.removeEventListener("invalid", this.invalid);
            input.addEventListener("invalid", this.invalid);
            this.input = input;
          }
          this.serverState = this.el.getAttribute("phx-value-state");
          this.serverChildren = Array.from(this.el.childNodes);
          if (this.form !== this.input.form) {
            if (this.form) this.form.removeEventListener("reset", this.reset);
            this.form = this.input.form;
            if (this.form) this.form.addEventListener("reset", this.reset);
          }
          this.setState(this.serverState, false);
        },
        beforeUpdate() {
          this.el.replaceChildren(...this.serverChildren);
          this.setState(this.serverState, false);
        },
        setState(state, notify) {
          const checked = state === "checked";
          this.el.setAttribute("data-state", state);
          this.el.setAttribute("aria-checked", state === "indeterminate" ? "mixed" : String(checked));
          this.input.checked = checked;
          this.input.indeterminate = state === "indeterminate";
          let child = this.el.firstElementChild;
          if (this.el.getAttribute("role") === "checkbox") {
            if (state === "unchecked") { if (child) child.remove(); }
            else if (!child) {
              child = document.createElement("span");
              child.setAttribute("data-slot", "checkbox-indicator");
              child.className = ${JSON.stringify(indicatorClass)};
              child.style.pointerEvents = "none";
              const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
              for (const [key, value] of Object.entries({viewBox:"0 0 24 24",width:"24",height:"24",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"})) svg.setAttribute(key,value);
              const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
              path.setAttribute("d", "M20 6 9 17l-5-5");
              svg.append(path); child.append(svg); this.el.append(child);
            }
          }
          if (child && state !== "unchecked") child.setAttribute("data-state", state);
          if (child && this.el.getAttribute("role") === "switch") child.setAttribute("data-state", state);
          if (!notify) return;
          this.input.dispatchEvent(new Event("input", {bubbles:true}));
          this.input.dispatchEvent(new Event("change", {bubbles:true}));
          const event = this.el.getAttribute("phx-value-change");
          if (event) this.pushEvent(event, {id:this.el.id, value:checked});
        },
        destroyed() {
          cancelAnimationFrame(this.resetFrame);
          this.el.removeEventListener("click", this.click);
          this.input.removeEventListener("invalid", this.invalid);
          if (this.form) this.form.removeEventListener("reset", this.reset);
        }
      }`

function binary(spec: ComponentSpec): string {
  const checkbox = spec.name === "checkbox"
  const name = checkbox ? "checkbox" : "switch"
  const base = JSON.stringify(spec.functions.find(fn => fn.name === name)?.baseClasses ?? "")
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Native-form ${name} with a stable caller ID. checked controls server state;
  default_checked supplies the initial uncontrolled state. Form reset restores
  the mounted initial state, even after server patches. on_change receives
  %{id => id, value => boolean}. Labels target the button ID.
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
      phx-value-state={@state} phx-value-initial={@initial} {@rest}>
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

const sliderHook = `      export default {
        mounted() {
          this.initial = JSON.parse(this.el.getAttribute("phx-value-initial"));
          this.keydown = event => {
            const index = this.thumbs.indexOf(event.target);
            if (index < 0 || this.disabled) return;
            const key = event.key;
            if (!["ArrowLeft","ArrowRight","ArrowUp","ArrowDown","PageUp","PageDown","Home","End"].includes(key)) return;
            event.preventDefault();
            let next = this.values[index];
            if (key === "Home") next = this.min;
            else if (key === "End") next = this.max;
            else {
              let forward = key === "ArrowUp" || key === "ArrowRight" || key === "PageUp";
              const reverseKey = this.vertical
                ? this.inverted && ["ArrowUp","ArrowDown"].includes(key)
                : this.reverse && ["ArrowLeft","ArrowRight"].includes(key);
              if (reverseKey) forward = !forward;
              next += (forward ? 1 : -1) * this.step * (key.startsWith("Page") || event.shiftKey ? 10 : 1);
            }
            this.change(index, next);
          };
          this.pointerdown = event => {
            if (this.disabled || event.button !== 0 || !this.values.length) return;
            event.preventDefault();
            const value = this.pointerValue(event);
            const targetIndex = this.thumbs.indexOf(event.target.closest('[data-slot="slider-thumb"]'));
            this.active = targetIndex >= 0 && targetIndex < this.values.length ? targetIndex : this.values.reduce((best, item, index) => Math.abs(item-value) < Math.abs(this.values[best]-value) ? index : best, 0);
            this.el.setPointerCapture(event.pointerId);
            this.thumbs[this.active].focus();
            this.change(this.active, value);
          };
          this.pointermove = event => { if (this.el.hasPointerCapture(event.pointerId)) this.change(this.active, this.pointerValue(event)); };
          this.pointerup = event => { if (this.el.hasPointerCapture(event.pointerId)) this.el.releasePointerCapture(event.pointerId); };
          this.reset = () => { this.resetFrame = requestAnimationFrame(() => { this.values = [...this.initial]; this.render(); this.notify(); }); };
          this.el.addEventListener("keydown", this.keydown);
          this.el.addEventListener("pointerdown", this.pointerdown);
          this.el.addEventListener("pointermove", this.pointermove);
          this.el.addEventListener("pointerup", this.pointerup);
          this.updated();
        },
        updated() {
          this.values = JSON.parse(this.el.getAttribute("phx-value-values"));
          this.min = Number(this.el.getAttribute("phx-value-min"));
          this.max = Number(this.el.getAttribute("phx-value-max"));
          this.step = Number(this.el.getAttribute("phx-value-step"));
          this.distance = Number(this.el.getAttribute("phx-value-distance")) * this.step;
          this.vertical = this.el.getAttribute("data-orientation") === "vertical";
          this.inverted = this.el.getAttribute("phx-value-inverted") === "true";
          this.reverse = (this.el.getAttribute("dir") === "rtl") !== this.inverted;
          this.disabled = this.el.getAttribute("aria-disabled") === "true";
          this.thumbs = Array.from(this.el.querySelectorAll('[data-slot="slider-thumb"]'));
          this.inputs = Array.from(this.el.querySelectorAll("input"));
          this.render();
          const form = this.inputs[0]?.form;
          if (this.form !== form) {
            if (this.form) this.form.removeEventListener("reset", this.reset);
            this.form = form;
            if (this.form) this.form.addEventListener("reset", this.reset);
          }
        },
        pointerValue(event) {
          const box = this.el.getBoundingClientRect();
          let fraction = this.vertical ? (box.bottom-event.clientY)/box.height : (event.clientX-box.left)/box.width;
          if (this.vertical ? this.inverted : this.reverse) fraction = 1-fraction;
          return this.min + fraction*(this.max-this.min);
        },
        change(index, value) {
          const [digits, exponent] = String(this.step).split("e");
          const precision = Math.max(0, (digits.split(".")[1] || "").length - Number(exponent || 0));
          const snapped = Number((Math.round((value-this.min)/this.step)*this.step+this.min).toFixed(precision));
          const lower = index ? this.values[index-1]+this.distance : this.min;
          const upper = index < this.values.length-1 ? this.values[index+1]-this.distance : this.max;
          const next = Math.max(lower, Math.min(upper, snapped));
          if (next === this.values[index]) return;
          this.values[index] = next;
          this.render(); this.notify();
        },
        render() {
          const start = this.vertical ? (this.inverted ? "top" : "bottom") : (this.reverse ? "right" : "left");
          const end = this.vertical ? (this.inverted ? "bottom" : "top") : (this.reverse ? "left" : "right");
          const percents = this.values.map(value => Math.max(0, Math.min(100, 100/(this.max-this.min)*(value-this.min))));
          this.thumbs.forEach((thumb,index) => {
            if (this.values[index] === undefined) {
              thumb.style.display = "none";
              if (this.inputs[index]) this.inputs[index].value = "";
              return;
            }
            thumb.style.display = "";
            thumb.setAttribute("aria-valuenow", String(this.values[index]));
            const label = this.values.length > 2 ? "Value " + (index+1) + " of " + this.values.length : this.values.length === 2 ? ["Minimum","Maximum"][index] : null;
            if (label) thumb.setAttribute("aria-label", label);
            else thumb.removeAttribute("aria-label");
            thumb.setAttribute("aria-valuemin", String(index ? this.values[index-1]+this.distance : this.min));
            thumb.setAttribute("aria-valuemax", String(index < this.values.length-1 ? this.values[index+1]-this.distance : this.max));
            thumb.parentElement.style[start] = percents[index] + "%";
            const input = this.inputs[index];
            if (input) {
              input.type = "hidden";
              input.disabled = this.disabled;
              input.value = String(this.values[index]);
              const form = this.el.getAttribute("phx-value-form");
              if (form) input.setAttribute("form", form);
              else input.removeAttribute("form");
            }
          });
          const range = this.el.querySelector('[data-slot="slider-range"]');
          range.style[start] = (percents.length > 1 ? Math.min(...percents) : 0) + "%";
          range.style[end] = (100-Math.max(...percents)) + "%";
        },
        notify() {
          this.inputs.forEach(input => { input.dispatchEvent(new Event("input",{bubbles:true})); input.dispatchEvent(new Event("change",{bubbles:true})); });
          const event = this.el.getAttribute("phx-value-change");
          if (event) this.pushEvent(event,{id:this.el.id,value:this.values});
        },
        destroyed() {
          cancelAnimationFrame(this.resetFrame);
          this.el.removeEventListener("keydown",this.keydown);
          this.el.removeEventListener("pointerdown",this.pointerdown);
          this.el.removeEventListener("pointermove",this.pointermove);
          this.el.removeEventListener("pointerup",this.pointerup);
          if (this.form) this.form.removeEventListener("reset",this.reset);
        }
      }`

function slider(spec: ComponentSpec): string {
  const base = JSON.stringify(spec.functions.find(fn => fn.name === "slider")?.baseClasses ?? "")
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Slider with native submitted values, pointer capture, and keyboard stepping.
  Supply a stable ID; value/default_value are numeric lists. on_change receives
  %{\"id\" => id, \"value\" => values}. Form reset restores the mounted initial
  value (default_value when supplied), not the latest server-patched value.
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
      phx-value-form={@form} phx-value-change={@on_change} {@rest}>
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
  content. on_open_change receives %{\"id\" => id, \"open\" => boolean}; assign
  the returned open value on the next render. Closed content has no child markup.
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
            if (!trigger || !this.el.contains(trigger) || trigger.disabled) return;
            this.pushEvent(this.el.getAttribute("phx-value-change"), {id:this.el.id, open:this.el.getAttribute("data-state") !== "open"});
          };
          this.el.addEventListener("click", this.click);
        },
        updated() {},
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
const navigationHook = `      export default {
        mounted() {
          this.click = event => {
            const trigger = event.target.closest('[data-slot="navigation-menu-trigger"]');
            if (trigger && this.el.contains(trigger) && !trigger.disabled) {
              event.preventDefault();
              const value = trigger.getAttribute("phx-value-item");
              this.select(trigger.getAttribute("aria-expanded") === "true" ? "" : value);
            }
            const link = event.target.closest('[data-slot="navigation-menu-link"]');
            if (link && this.el.contains(link)) this.select("");
          };
          this.over = event => {
            const trigger = event.target.closest('[data-slot="navigation-menu-trigger"]');
            clearTimeout(this.timer);
            if (trigger && !trigger.disabled && event.pointerType !== "touch") {
              this.timer = setTimeout(() => this.select(trigger.getAttribute("phx-value-item")), 200);
            }
          };
          this.leave = () => { clearTimeout(this.timer); this.timer = setTimeout(() => this.select(""), 300); };
          this.enter = () => clearTimeout(this.timer);
          this.outside = event => { if (!this.el.contains(event.target)) this.select(""); };
          this.keydown = event => {
            const target = event.target;
            const trigger = target.closest('[data-slot="navigation-menu-trigger"]');
            if (event.key === "Escape") {
              event.preventDefault();
              const active = this.el.querySelector('[data-slot="navigation-menu-trigger"][aria-expanded="true"]');
              this.pendingFocus = false;
              this.select(""); if (active) active.focus(); return;
            }
            const content = target.closest('[data-slot="navigation-menu-content"]');
            const forward = this.el.getAttribute("data-orientation") === "vertical" ? "ArrowDown" : "ArrowRight";
            const backward = this.el.getAttribute("data-orientation") === "vertical" ? "ArrowUp" : "ArrowLeft";
            if (trigger && event.key === (forward === "ArrowDown" ? "ArrowRight" : "ArrowDown")) {
              event.preventDefault();
              this.pendingFocus = trigger.getAttribute("phx-value-item");
              this.select(this.pendingFocus);
              this.focusContent(); return;
            }
            const keys = content ? ["ArrowUp","ArrowDown","ArrowLeft","ArrowRight","Home","End"] : [forward,backward,"Home","End"];
            if (!keys.includes(event.key)) return;
            const scope = content || this.el.querySelector('[data-slot="navigation-menu-list"]');
            const items = Array.from(scope.querySelectorAll('a[href],button:not(:disabled),[tabindex="0"]')).filter(item => item.getAttribute("aria-hidden") !== "true" && (content || !item.closest('[data-slot="navigation-menu-content"]')));
            if (!items.length) return;
            event.preventDefault();
            let direction = event.key === backward || event.key === "ArrowUp" ? -1 : 1;
            if (!content && forward === "ArrowRight" && this.el.getAttribute("dir") === "rtl") direction *= -1;
            const index = event.key === "Home" ? 0 : event.key === "End" ? items.length-1 : (items.indexOf(target)+direction+items.length)%items.length;
            items[index].focus();
          };
          this.el.addEventListener("click",this.click);
          this.el.addEventListener("pointerover",this.over);
          this.el.addEventListener("pointerleave",this.leave);
          this.el.addEventListener("pointerenter",this.enter);
          this.el.addEventListener("keydown",this.keydown);
          document.addEventListener("pointerdown",this.outside);
          this.updated();
        },
        select(value) {
          const event = this.el.getAttribute("phx-value-change");
          if (event) this.pushEvent(event,{id:this.el.id,value});
        },
        focusContent() {
          const content = document.getElementById("radix-" + this.el.id + "-content-" + this.pendingFocus);
          const first = content?.querySelector('a[href],button:not(:disabled),[tabindex="0"]');
          if (first) { first.focus(); this.pendingFocus = false; }
        },
        restoreContent() {
          for (const {content, placeholder} of this.relocated || []) {
            if (placeholder.parentNode) placeholder.replaceWith(content);
          }
          this.relocated = [];
        },
        beforeUpdate() {
          this.restoreContent();
          this.el.querySelectorAll('[data-slot="navigation-menu-indicator"]').forEach(item => item.remove());
        },
        updated() {
          this.restoreContent();
          const viewport = this.el.querySelector('[data-slot="navigation-menu-viewport"]');
          const contents = Array.from(this.el.querySelectorAll('[data-slot="navigation-menu-content"]'));
          const activeContent = contents.find(content => content.getAttribute("data-state") === "open");
          if (viewport) {
            for (const content of contents) {
              if (content.parentElement === viewport) continue;
              const placeholder = document.createComment("navigation-content-origin");
              content.before(placeholder);
              this.relocated.push({content, placeholder});
              viewport.append(content);
            }
            if (activeContent) {
              viewport.style.setProperty("--radix-navigation-menu-viewport-width", activeContent.scrollWidth+"px");
              viewport.style.setProperty("--radix-navigation-menu-viewport-height", activeContent.scrollHeight+"px");
            }
          }
          if (this.pendingFocus) this.focusContent();
          const indicatorConfig = JSON.parse(this.el.getAttribute("phx-value-indicator") || "[]");
          const active = this.el.querySelector('[data-slot="navigation-menu-trigger"][aria-expanded="true"]');
          const list = this.el.querySelector('[data-slot="navigation-menu-list"]');
          this.el.querySelectorAll('[data-slot="navigation-menu-indicator"]').forEach(item => item.remove());
          indicatorConfig.forEach(config => {
            if (!active && !config.force_mount) return;
            const indicator = document.createElement("div");
            indicator.setAttribute("data-slot", "navigation-menu-indicator");
            indicator.setAttribute("data-state", active ? "visible" : "hidden");
            indicator.setAttribute("data-orientation", this.el.getAttribute("data-orientation"));
            indicator.className = "top-full z-1 flex h-1.5 items-end justify-center overflow-hidden data-[state=hidden]:animate-out data-[state=hidden]:fade-out data-[state=visible]:animate-in data-[state=visible]:fade-in " + (config.class || "");
            indicator.style.position = "absolute";
            if (active) {
              const vertical = this.el.getAttribute("data-orientation") === "vertical";
              indicator.style[vertical ? "top" : "left"] = (vertical ? active.offsetTop : active.offsetLeft) + "px";
              indicator.style[vertical ? "height" : "width"] = (vertical ? active.offsetHeight : active.offsetWidth) + "px";
            }
            const arrow = document.createElement("div");
            arrow.className = "relative top-[60%] h-2 w-2 rotate-45 rounded-tl-sm bg-border shadow-md";
            indicator.append(arrow); list.append(indicator);
          });
        },
        destroyed() {
          this.restoreContent();
          clearTimeout(this.timer);
          this.el.removeEventListener("click",this.click);
          this.el.removeEventListener("pointerover",this.over);
          this.el.removeEventListener("pointerleave",this.leave);
          this.el.removeEventListener("pointerenter",this.enter);
          this.el.removeEventListener("keydown",this.keydown);
          document.removeEventListener("pointerdown",this.outside);
        }
      }`

function navigation(spec: ComponentSpec): string {
  const style = (name: string) => JSON.stringify(spec.functions.find(fn => fn.name === name)?.baseClasses ?? "")
  const triggerStyle = "group/navigation-menu-trigger inline-flex h-9 w-max items-center justify-center rounded-lg px-2.5 py-1.5 text-sm font-medium transition-all outline-none hover:bg-muted focus:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-1 disabled:pointer-events-none disabled:opacity-50 data-popup-open:bg-muted/50 data-popup-open:hover:bg-muted data-open:bg-muted/50 data-open:hover:bg-muted data-open:focus:bg-muted group"
  const viewportStyle = "origin-top-center relative mt-1.5 h-(--radix-navigation-menu-viewport-height) w-full overflow-hidden rounded-lg bg-popover text-popover-foreground shadow ring-1 ring-foreground/10 duration-100 md:w-(--radix-navigation-menu-viewport-width) data-open:animate-in data-open:zoom-in-90 data-closed:animate-out data-closed:zoom-out-90"
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Server-owned navigation selection. Pass the root's :let context to the list
  and items; each item's :let context goes to its trigger and content.
  on_value_change receives %{"id" => id, "value" => item_value}; an empty
  value closes the menu. Links remain native anchors. IDs are caller-scoped.
  Optional <:indicator class="..." force_mount={false} /> is measured by the
  mounted hook, matching Radix's initially absent SSR indicator.
  Viewport relocation preserves the original DOM position and is undone before
  every LiveView patch and on destruction, leaving content server-owned.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :viewport, :boolean, default: true
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"
  attr :on_value_change, :string, default: "control_change"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :indicator do
    attr :class, :string
    attr :force_mount, :boolean
  end

  def navigation_menu(assigns) do
    context = Map.take(assigns, [:id, :value, :viewport, :orientation, :dir])
    assigns = assign(assigns, :context, context)
    assigns = assign(assigns, :indicator_config, Enum.map(assigns.indicator, &Map.take(&1, [:class, :force_mount])))

    ~H"""
    <nav id={@id} aria-label="Main" data-orientation={@orientation} dir={@dir}
      data-slot="navigation-menu" data-viewport={to_string(@viewport)} class={classes([${style("navigation_menu")}, @class])}
      phx-hook=".NavigationMenu" phx-value-change={@on_value_change} phx-value-indicator={Jason.encode!(@indicator_config)} {@rest}>
      {render_slot(@inner_block, @context)}
      <.navigation_menu_viewport :if={@viewport} context={@context} />
    </nav>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".NavigationMenu">
${navigationHook}
    </script>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_list(assigns) do
    ~H"""
    <div style="position:relative">
      <ul data-orientation={@context.orientation} data-slot="navigation-menu-list"
        class={classes([${style("navigation_menu_list")}, @class])} dir={@context.dir} {@rest}>
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_item(assigns) do
    assigns = assign(assigns, :item, Map.merge(assigns.context, %{item: assigns.value, open: assigns.context.value == assigns.value}))

    ~H"""
    <li data-slot="navigation-menu-item" class={classes([${style("navigation_menu_item")}, @class])} {@rest}>
      {render_slot(@inner_block, @item)}
    </li>
    """
  end

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_trigger(assigns) do
    ~H"""
    <button id={"radix-" <> @context.id <> "-trigger-" <> @context.item}
      data-state={if @context.open, do: "open", else: "closed"} aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: "radix-" <> @context.id <> "-content-" <> @context.item}
      disabled={@disabled} data-disabled={if @disabled, do: ""} data-slot="navigation-menu-trigger"
      class={classes([${JSON.stringify(triggerStyle)}, @class])} data-radix-collection-item=""
      phx-value-item={@context.item} {@rest}>
      {render_slot(@inner_block)}<%= " " %><ShadcnLiveview.Components.Icon.icon name="chevron-down"
        class="relative top-px ml-1 size-3 transition duration-300 group-data-popup-open/navigation-menu-trigger:rotate-180 group-data-open/navigation-menu-trigger:rotate-180"
        aria-hidden="true" />
    </button>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_content(assigns) do
    assigns = assign(assigns, :content_style, if(assigns.context.open, do: %{}, else: %{style: "pointer-events:none"}))

    ~H"""
    <%= if @context.open || @force_mount do %>
      <span :if={@context.open} aria-hidden="true" tabindex="0" style="position:absolute;border:0;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;word-wrap:normal" />
      <div id={"radix-" <> @context.id <> "-content-" <> @context.item}
        aria-labelledby={"radix-" <> @context.id <> "-trigger-" <> @context.item}
        data-orientation={@context.orientation} data-state={if @context.open, do: "open", else: "closed"}
        data-slot="navigation-menu-content" class={classes([${style("navigation_menu_content")}, @class])}
        {@content_style} dir={@context.dir} {@rest}>{render_slot(@inner_block)}</div>
    <% end %>
    """
  end

  attr :active, :boolean, default: false
  attr :href, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(target rel download)
  slot :inner_block, required: true

  def navigation_menu_link(assigns) do
    ~H"""
    <a data-active={if @active, do: ""} aria-current={if @active, do: "page"}
      data-slot="navigation-menu-link" class={classes([${style("navigation_menu_link")}, @class])}
      href={@href} data-radix-collection-item="" {@rest}>{render_slot(@inner_block)}</a>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def navigation_menu_viewport(assigns) do
    ~H"""
    <div class="absolute top-full left-0 isolate z-50 flex justify-center">
      <div :if={@context.value != "" || @force_mount} data-state={if @context.value != "", do: "open", else: "closed"}
        data-orientation={@context.orientation} data-slot="navigation-menu-viewport"
        class={classes([${JSON.stringify(viewportStyle)}, @class])} {@rest}>{render_slot(@inner_block)}</div>
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
