defmodule ShadcnLiveview.Components.ToggleGroup do
  @moduledoc """
  Single- and multiple-selection toggle buttons with explicit :let contexts.

  Pass the root context to each item. Root variant, size, spacing and disabled
  state propagate without hidden render state. value enables server control;
  on_value_change names a LiveView event receiving %{id, value}. Single values
  are strings (empty when deselected); multiple values are lists. Native buttons
  retain Space/Enter activation while the hook provides directional roving focus.
  Hook events honor phx-target on the root or nearest containing element.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :type, :string, required: true, values: ["single", "multiple"]
  attr :value, :any, default: nil

  attr :default_value, :any,
    default: nil,
    doc: "Uncontrolled initial `value`; ignored once `value` is supplied."

  attr :variant, :string, default: nil, values: [nil, "default", "outline"]
  attr :size, :string, default: nil, values: [nil, "default", "sm", "lg"]
  attr :spacing, :integer, default: 2
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :disabled, :boolean, default: false
  attr :roving_focus, :boolean, default: true
  attr :loop, :boolean, default: true

  attr :on_value_change, :string,
    default: nil,
    doc:
      "LiveView event name pushed on value change; the payload is described in the module docs. `nil` pushes no event."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a radiogroup or toolbar and yields its item context."
  def toggle_group(assigns) do
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value

    values =
      if assigns.type == "multiple",
        do: value || [],
        else: if(value in [nil, ""], do: [], else: [value])

    assigns =
      assign(assigns,
        values: values,
        context: %{
          values: values,
          type: assigns.type,
          disabled: assigns.disabled,
          variant: assigns.variant,
          size: assigns.size,
          spacing: assigns.spacing,
          roving_focus: assigns.roving_focus
        }
      )

    ~H"""
    <div
      id={@id}
      dir={@dir}
      role={if @type == "single", do: "radiogroup", else: "toolbar"}
      data-slot="toggle-group"
      data-variant={@variant}
      data-size={@size}
      data-spacing={@spacing}
      data-orientation={@orientation}
      style={if @roving_focus, do: "outline:none;--gap:#{@spacing}", else: "--gap:#{@spacing}"}
      tabindex={if @roving_focus, do: "-1"}
      class={
        classes([
          "group/toggle-group flex w-fit flex-row items-center gap-[--spacing(var(--gap))] rounded-lg data-[size=sm]:rounded-[min(var(--radius-md),10px)] data-vertical:flex-col data-vertical:items-stretch",
          @class
        ])
      }
      phx-hook=".ToggleGroup"
      phx-values={Jason.encode!(@values)}
      phx-controlled={to_string(not is_nil(@value))}
      phx-selection-type={@type}
      phx-orientation={@orientation}
      phx-loop={to_string(@loop)}
      phx-roving={to_string(@roving_focus)}
      phx-change-event={@on_value_change}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ToggleGroup">
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          const push = target
            ? this.pushEventTo(target, event, payload).then(results => {
                const failed = results.find(result => result.status === "rejected");
                if (failed) throw failed.reason;
                return results[0]?.value.reply;
              })
            : this.pushEvent(event, payload);
          push.catch(() => {});
          if (onReply) push.then(onReply, () => {});
          return push;
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
          // Reset after the native form reset so native inputs match the restored selection.
          this.reset = () => {
            cancelAnimationFrame(this.resetFrame);
            this.resetFrame = requestAnimationFrame(() => {
              if (this.controlled) this.change([...this.initial], null);
              else { this.values = [...this.initial]; this.paint(); }
            });
          };
          this.form?.addEventListener("reset", this.reset);
          this.paint();
        },
        items() { return [...this.el.querySelectorAll(this.radio ? '[data-slot="radio-group-item"]' : '[data-slot="toggle-group-item"]')].filter(i => i.closest('[data-slot="radio-group"], [data-slot="toggle-group"]') === this.el); },
        value(item) { return this.radio ? item.value : item.getAttribute("phx-value"); },
        tabstop(item) { if (this.el.getAttribute("phx-roving") === "false") return; this.items().forEach(i => i.tabIndex = i === item && !i.disabled ? 0 : -1); },
        change(next, item) {
          if (JSON.stringify(next) === JSON.stringify(this.values)) return;
          // Radio selections are optimistic like checkbox and switch; updated() applies server values.
          if (!this.controlled || this.radio) { this.values = next; this.paint(); }
          const value = this.radio || this.el.getAttribute("phx-selection-type") === "single" ? (next[0] || "") : next;
          const event = this.el.getAttribute("phx-change-event");
          // Controlled values come from the server, so a failed push restores them.
          if (event) this.sendEvent(event, {id: this.el.id, value}).catch(() => {
            if (this.controlled) { this.values = JSON.parse(this.el.getAttribute("phx-values")); this.paint(); }
          });
          this.el.dispatchEvent(new CustomEvent("selection-change", {bubbles: true, detail: {value}}));
          if (this.radio && item) {
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
        destroyed() { cancelAnimationFrame(this.resetFrame); this.el.removeEventListener("click", this.click); this.el.removeEventListener("keydown", this.key); this.el.removeEventListener("focusin", this.focus); this.form?.removeEventListener("reset", this.reset); }
      }
    </script>
    """
  end

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :variant, :string, default: "default", values: ["default", "outline"]
  attr :size, :string, default: "default", values: ["default", "sm", "lg"]
  attr :disabled, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a selected or unselected native toggle button within its context."
  def toggle_group_item(assigns) do
    assigns =
      assign(assigns,
        pressed: assigns.value in assigns.context.values,
        disabled: assigns.disabled or assigns.context.disabled,
        variant: assigns.context.variant || assigns.variant,
        size: assigns.context.size || assigns.size
      )

    ~H"""
    <button
      id={@id}
      type="button"
      data-state={if @pressed, do: "on", else: "off"}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      role={if @context.type == "single", do: "radio"}
      aria-checked={if @context.type == "single", do: to_string(@pressed)}
      aria-pressed={if @context.type == "multiple", do: to_string(@pressed)}
      data-slot="toggle-group-item"
      data-variant={@variant}
      data-size={@size}
      data-spacing={@context.spacing}
      tabindex={if @context.roving_focus, do: "-1"}
      class={classes([item_classes(@variant, @size), @class])}
      phx-value={@value}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp item_classes("default", "default"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-transparent h-8 min-w-8 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2"

  defp item_classes("default", "sm"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-transparent h-7 min-w-7 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5"

  defp item_classes("default", "lg"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-transparent h-9 min-w-9 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2"

  defp item_classes("outline", "default"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border border-input bg-transparent hover:bg-muted h-8 min-w-8 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2"

  defp item_classes("outline", "sm"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border border-input bg-transparent hover:bg-muted h-7 min-w-7 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5"

  defp item_classes("outline", "lg"),
    do:
      "shrink-0 group-data-[spacing=0]/toggle-group:rounded-none group-data-[spacing=0]/toggle-group:px-2 focus:z-10 focus-visible:z-10 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-end]:pr-1.5 group-data-[spacing=0]/toggle-group:has-data-[icon=inline-start]:pl-1.5 group-data-horizontal/toggle-group:data-[spacing=0]:first:rounded-l-lg group-data-vertical/toggle-group:data-[spacing=0]:first:rounded-t-lg group-data-horizontal/toggle-group:data-[spacing=0]:last:rounded-r-lg group-data-vertical/toggle-group:data-[spacing=0]:last:rounded-b-lg group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:border-l-0 group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:border-t-0 group-data-horizontal/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-l group-data-vertical/toggle-group:data-[spacing=0]:data-[variant=outline]:first:border-t group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border border-input bg-transparent hover:bg-muted h-9 min-w-9 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2"
end
