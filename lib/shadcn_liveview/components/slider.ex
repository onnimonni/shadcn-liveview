defmodule ShadcnLiveview.Components.Slider do
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
    <span
      id={@id}
      dir={@dir}
      data-orientation={@orientation}
      aria-disabled={to_string(@disabled)}
      data-disabled={if @disabled, do: ""}
      data-slot="slider"
      style={"--radix-slider-thumb-transform:" <> @transform}
      class={
        classes([
          "relative flex w-full touch-none items-center select-none data-disabled:opacity-50 data-vertical:h-full data-vertical:min-h-40 data-vertical:w-auto data-vertical:flex-col",
          @class
        ])
      }
      phx-hook=".Slider"
      phx-value-values={Jason.encode!(@control_values)}
      phx-value-initial={Jason.encode!(@initial)}
      phx-value-min={@min}
      phx-value-max={@max}
      phx-value-step={@step}
      phx-value-distance={@min_steps_between_thumbs}
      phx-value-inverted={to_string(@inverted)}
      phx-value-form={@form}
      phx-value-name={@name}
      phx-value-change={@on_change}
      phx-value-controlled={to_string(!is_nil(@value))}
      {@rest}
    >
      <span
        data-disabled={if @disabled, do: ""}
        data-orientation={@orientation}
        data-slot="slider-track"
        class="relative grow overflow-hidden rounded-full bg-muted data-horizontal:h-1 data-horizontal:w-full data-vertical:h-full data-vertical:w-1"
      >
        <span
          data-orientation={@orientation}
          data-disabled={if @disabled, do: ""}
          data-slot="slider-range"
          class="absolute bg-primary select-none data-horizontal:h-full data-vertical:w-full"
          style={@range_style}
        />
      </span>
      <%= for _value <- @values do %>
        <span style={"transform:var(--radix-slider-thumb-transform);position:absolute;" <> @start_side <> ":calc(0% + 0px)"}>
          <span
            role="slider"
            aria-label={@thumb_label}
            aria-valuemin={@min}
            aria-valuemax={@max}
            aria-orientation={@orientation}
            data-orientation={@orientation}
            data-disabled={if @disabled, do: ""}
            tabindex={if !@disabled, do: "0"}
            data-slot="slider-thumb"
            class="relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50"
            style="display:none"
            data-radix-collection-item=""
          />
        </span><input style="display:none" name={@input_name} form={@form} />
      <% end %>
    </span>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Slider">
      export default {
        mounted() {
          this.initial = JSON.parse(this.el.getAttribute("phx-value-initial"));
          this.keydown = event => {
            const index = this.thumbs.indexOf(event.target);
            if (index < 0 || index >= this.values.length || this.disabled) return;
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
          this.pointermove = event => { if (!this.disabled && this.active < this.values.length && this.el.hasPointerCapture(event.pointerId)) this.change(this.active, this.pointerValue(event)); };
          this.pointerup = event => { if (this.el.hasPointerCapture(event.pointerId)) this.el.releasePointerCapture(event.pointerId); };
          this.reset = () => { this.resetFrame = requestAnimationFrame(() => { this.values = [...this.initial]; this.render(); this.notify(); }); };
          this.el.addEventListener("keydown", this.keydown);
          this.el.addEventListener("pointerdown", this.pointerdown);
          this.el.addEventListener("pointermove", this.pointermove);
          this.el.addEventListener("pointerup", this.pointerup);
          this.updated();
        },
        beforeUpdate() {
          this.focusedThumbIndex = this.thumbs.indexOf(this.el.ownerDocument.activeElement);
          this.el.replaceChildren(...this.serverChildren);
          for (const {element, attributes} of this.serverAttributes) {
            for (const attribute of Array.from(element.attributes)) element.removeAttribute(attribute.name);
            for (const [name, value] of attributes) element.setAttribute(name, value);
          }
        },
        updated() {
          if (this.el.getAttribute("phx-value-controlled") === "true" || this.values === undefined) {
            this.values = JSON.parse(this.el.getAttribute("phx-value-values"));
          }
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
          // Restore the server's DOM before a patch without replacing local values.
          this.serverChildren = Array.from(this.el.childNodes);
          this.serverAttributes = [
            ...this.thumbs.flatMap(thumb => [thumb, thumb.parentElement]),
            ...this.inputs,
            this.el.querySelector('[data-slot="slider-range"]')
          ].map(element => ({element, attributes:Array.from(element.attributes, attribute => [attribute.name, attribute.value])}));
          this.render();
          const focusedThumb = this.thumbs[this.focusedThumbIndex];
          const activeElement = this.el.ownerDocument.activeElement;
          if (!this.disabled && this.focusedThumbIndex < this.values.length && focusedThumb &&
              (activeElement === this.el.ownerDocument.body || activeElement === focusedThumb)) {
            focusedThumb.focus({preventScroll:true});
          }
          this.focusedThumbIndex = -1;
          const formId = this.el.getAttribute("phx-value-form");
          const form = this.inputs[0]?.form || (formId ? document.getElementById(formId) : this.el.closest("form"));
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
          // Uncontrolled values can outlive a server-side thumb-count change.
          while (this.thumbs.length < this.values.length) {
            const wrapper = document.createElement("span");
            wrapper.style.cssText = "transform:var(--radix-slider-thumb-transform);position:absolute";
            const thumb = document.createElement("span");
            thumb.setAttribute("role", "slider");
            thumb.setAttribute("data-slot", "slider-thumb");
            thumb.setAttribute("data-radix-collection-item", "");
            thumb.className = "relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50";
            const input = document.createElement("input");
            input.style.display = "none";
            wrapper.append(thumb);
            this.el.append(wrapper, input);
            this.thumbs.push(thumb);
            this.inputs.push(input);
          }
          const start = this.vertical ? (this.inverted ? "top" : "bottom") : (this.reverse ? "right" : "left");
          const end = this.vertical ? (this.inverted ? "bottom" : "top") : (this.reverse ? "left" : "right");
          const percents = this.values.map(value => Math.max(0, Math.min(100, 100/(this.max-this.min)*(value-this.min))));
          this.thumbs.forEach((thumb,index) => {
            if (this.values[index] === undefined) {
              thumb.style.display = "none";
              if (this.inputs[index]) {
                this.inputs[index].value = "";
                this.inputs[index].disabled = true;
              }
              return;
            }
            thumb.style.display = "";
            thumb.setAttribute("data-orientation", this.vertical ? "vertical" : "horizontal");
            thumb.setAttribute("aria-orientation", this.vertical ? "vertical" : "horizontal");
            if (this.disabled) {
              thumb.setAttribute("data-disabled", "");
              thumb.removeAttribute("tabindex");
            } else {
              thumb.removeAttribute("data-disabled");
              thumb.setAttribute("tabindex", "0");
            }
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
              // Radix disables interaction, not the submitted slider inputs.
              input.disabled = false;
              input.value = String(this.values[index]);
              const name = this.el.getAttribute("phx-value-name");
              if (name !== null) input.name = name + (this.values.length > 1 ? "[]" : "");
              else input.removeAttribute("name");
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
          if (event) this.sendEvent(event,{id:this.el.id,value:this.values});
        },
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute('phx-target');
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        destroyed() {
          cancelAnimationFrame(this.resetFrame);
          this.el.removeEventListener("keydown",this.keydown);
          this.el.removeEventListener("pointerdown",this.pointerdown);
          this.el.removeEventListener("pointermove",this.pointermove);
          this.el.removeEventListener("pointerup",this.pointerup);
          if (this.form) this.form.removeEventListener("reset",this.reset);
        }
      }
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
    reverse = if vertical, do: assigns.inverted, else: assigns.dir == "rtl" != assigns.inverted
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
