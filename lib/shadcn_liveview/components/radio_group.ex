defmodule ShadcnLiveview.Components.RadioGroup do
  @moduledoc """
  Native-form-compatible radio groups with explicit slot contexts.

  The root yields its context through :let; pass it to each radio_group_item.
  IDs belong to the caller. value enables server control and on_value_change
  names a LiveView event receiving %{id, value}. Without value, default_value
  initializes local selection. Arrow keys select, Space checks, and form reset
  restores the initial value. SSR focus stops are activated by the colocated hook.
  Hook events honor phx-target on the root or nearest containing element.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :orientation, :string, default: nil, values: [nil, "horizontal", "vertical"]
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :loop, :boolean, default: true
  attr :on_value_change, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Yields the radio selection and native form context to its item slot."
  def radio_group(assigns) do
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value

    assigns =
      assign(assigns,
        context: %{
          value: value,
          name: assigns.name,
          form: assigns.form,
          required: assigns.required,
          disabled: assigns.disabled,
          orientation: assigns.orientation
        },
        values: if(is_nil(value), do: [], else: [value])
      )

    ~H"""
    <div
      id={@id}
      role="radiogroup"
      aria-required={to_string(@required)}
      aria-orientation={@orientation}
      data-disabled={if @disabled, do: ""}
      dir={@dir}
      data-slot="radio-group"
      tabindex="-1"
      data-orientation={@orientation}
      style="outline:none"
      class={classes(["grid w-full gap-2", @class])}
      phx-hook=".RadioGroup"
      phx-values={Jason.encode!(@values)}
      phx-controlled={to_string(not is_nil(@value))}
      phx-orientation={@orientation}
      phx-loop={to_string(@loop)}
      phx-roving="true"
      phx-form={@form}
      phx-change-event={@on_value_change}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".RadioGroup">
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          this.radio = this.el.dataset.slot === "radio-group";
          this.controlled = this.el.getAttribute("phx-controlled") === "true";
          this.values = JSON.parse(this.el.getAttribute("phx-values"));
          this.initial = [...this.values];
          this.click = e => {
            const item = e.target.closest(this.radio ? '[data-slot="radio-group-item"]' : '[data-slot="toggle-group-item"]');
            if (!item || !this.el.contains(item) || item.disabled) return;
            const value = this.value(item);
            let next;
            if (this.radio) next = [value];
            else if (this.el.getAttribute("phx-selection-type") === "single") next = this.values.includes(value) ? [] : [value];
            else next = this.values.includes(value) ? this.values.filter(v => v !== value) : [...this.values, value];
            this.change(next, item);
          };
          this.key = e => {
            const items = this.items().filter(i => !i.disabled);
            const index = items.indexOf(e.target);
            if (index < 0 || this.el.getAttribute("phx-roving") === "false") return;
            if (this.radio && e.key === "Enter") { e.preventDefault(); return; }
            const orientation = this.el.getAttribute("phx-orientation");
            let delta = 0;
            if (orientation !== "vertical" && e.key === "ArrowRight") delta = this.el.dir === "rtl" ? -1 : 1;
            if (orientation !== "vertical" && e.key === "ArrowLeft") delta = this.el.dir === "rtl" ? 1 : -1;
            if (orientation !== "horizontal" && e.key === "ArrowDown") delta = 1;
            if (orientation !== "horizontal" && e.key === "ArrowUp") delta = -1;
            let target;
            if (e.key === "Home") target = items[0];
            else if (e.key === "End") target = items.at(-1);
            else if (delta) {
              let n = index + delta;
              if (this.el.getAttribute("phx-loop") === "true") n = (n + items.length) % items.length;
              target = items[n];
            } else return;
            e.preventDefault();
            if (target) { this.tabstop(target); target.focus(); if (this.radio) this.change([this.value(target)], target); }
          };
          this.focus = e => { if (this.items().includes(e.target)) this.tabstop(e.target); };
          this.el.addEventListener("click", this.click);
          this.el.addEventListener("keydown", this.key);
          this.el.addEventListener("focusin", this.focus);
          this.form = this.radio ? (document.getElementById(this.el.getAttribute("phx-form")) || this.el.closest("form")) : null;
          this.reset = () => {
            if (this.controlled) this.change([...this.initial], null);
            else { this.values = [...this.initial]; this.paint(); }
          };
          this.form?.addEventListener("reset", this.reset);
          this.paint();
        },
        items() { return [...this.el.querySelectorAll(this.radio ? '[data-slot="radio-group-item"]' : '[data-slot="toggle-group-item"]')].filter(i => i.closest('[data-slot="radio-group"], [data-slot="toggle-group"]') === this.el); },
        value(item) { return this.radio ? item.value : item.getAttribute("phx-value"); },
        tabstop(item) { if (this.el.getAttribute("phx-roving") === "false") return; this.items().forEach(i => i.tabIndex = i === item && !i.disabled ? 0 : -1); },
        change(next, item) {
          if (JSON.stringify(next) === JSON.stringify(this.values)) return;
          if (!this.controlled) { this.values = next; this.paint(); }
          const value = this.radio || this.el.getAttribute("phx-selection-type") === "single" ? (next[0] || "") : next;
          const event = this.el.getAttribute("phx-change-event");
          if (event) this.sendEvent(event, {id: this.el.id, value});
          this.el.dispatchEvent(new CustomEvent("selection-change", {bubbles: true, detail: {value}}));
          if (this.radio && !this.controlled) {
            const input = item.nextElementSibling;
            input?.dispatchEvent(new Event("input", {bubbles: true}));
            input?.dispatchEvent(new Event("change", {bubbles: true}));
          }
        },
        paint() {
          const items = this.items();
          for (const item of items) {
            const checked = this.values.includes(this.value(item));
            item.dataset.state = this.radio ? (checked ? "checked" : "unchecked") : (checked ? "on" : "off");
            item.setAttribute(this.radio || this.el.getAttribute("phx-selection-type") === "single" ? "aria-checked" : "aria-pressed", String(checked));
            if (this.radio) {
              const input = item.nextElementSibling;
              if (input?.type === "radio") { input.checked = checked; const box = item.getBoundingClientRect(); input.style.width = box.width + "px"; input.style.height = box.height + "px"; }
              const indicator = item.querySelector('[data-slot="radio-group-indicator"]');
              if (!checked) indicator?.remove();
              else if (!indicator) {
                const indicator = document.createElement("span");
                indicator.dataset.slot = "radio-group-indicator";
                indicator.dataset.state = "checked";
                if (item.disabled) indicator.setAttribute("data-disabled", "");
                indicator.className = "flex size-4 items-center justify-center";
                const dot = document.createElement("span");
                dot.className = "absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary-foreground";
                indicator.appendChild(dot);
                item.appendChild(indicator);
              }
            }
          }
          if (this.el.getAttribute("phx-roving") !== "false") {
            this.el.tabIndex = items.some(i => !i.disabled) ? 0 : -1;
            this.tabstop(items.find(i => i === document.activeElement && !i.disabled) || items.find(i => this.values.includes(this.value(i)) && !i.disabled) || items.find(i => !i.disabled));
            if (items.some(i => i.tabIndex === 0)) this.el.tabIndex = -1;
          }
        },
        updated() { this.controlled = this.el.getAttribute("phx-controlled") === "true"; if (this.controlled) this.values = JSON.parse(this.el.getAttribute("phx-values")); this.paint(); },
        destroyed() { this.el.removeEventListener("click", this.click); this.el.removeEventListener("keydown", this.key); this.el.removeEventListener("focusin", this.focus); this.form?.removeEventListener("reset", this.reset); }
      }
    </script>
    """
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(aria-invalid)

  @doc "Renders a radio button and its real, successful native radio input."
  def radio_group_item(assigns) do
    assigns =
      assign(assigns,
        checked: assigns.context.value == assigns.value,
        disabled: assigns.disabled or assigns.context.disabled
      )

    ~H"""
    <button
      id={@id}
      type="button"
      role="radio"
      aria-checked={to_string(@checked)}
      data-state={if @checked, do: "checked", else: "unchecked"}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      value={@value}
      data-slot="radio-group-item"
      tabindex="-1"
      data-orientation={@context.orientation}
      class={
        classes([
          "group/radio-group-item peer relative flex aspect-square size-4 shrink-0 rounded-full border border-input outline-none group-has-[:focus-visible]/field-label:ring-0 group-has-[:focus-visible]/field-label:not-data-checked:border-input after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 aria-invalid:aria-checked:border-primary dark:bg-input/30 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:border-primary data-checked:bg-primary data-checked:text-primary-foreground group-has-[:focus-visible]/field-label:data-checked:border-primary dark:data-checked:bg-primary",
          @class
        ])
      }
      {@rest}
    >
      <.indicator :if={@checked} disabled={@disabled} />
    </button>
    <input
      type="radio"
      aria-hidden="true"
      tabindex="-1"
      name={@context.name}
      form={@context.form}
      value={@value}
      checked={@checked}
      required={@context.required}
      disabled={@disabled}
      style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
    />
    """
  end

  attr :disabled, :boolean, default: false

  defp indicator(assigns) do
    ~H"""
    <span
      data-state="checked"
      data-disabled={if @disabled, do: ""}
      data-slot="radio-group-indicator"
      class="flex size-4 items-center justify-center"
    ><span class="absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary-foreground"></span></span>
    """
  end
end
