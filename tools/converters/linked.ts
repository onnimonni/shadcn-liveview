import type { ComponentSpec } from "../generate"
import { sendEventMethod } from "./hook-events"

const hook = (family: "accordion" | "tabs") => `      export default {
${sendEventMethod("        ")}
        mounted() {
          this.pending = null;
          this.click = event => {
            const trigger = this.trigger(event.target);
            if (trigger && !trigger.disabled) this.select(trigger);
          };
          this.focus = event => {
            const trigger = this.trigger(event.target);
            if (trigger && this.el.getAttribute("phx-value-activation-mode") === "automatic") this.select(trigger);
          };
          this.keydown = event => {
            const trigger = this.trigger(event.target);
            if (!trigger || trigger.disabled || event.altKey || event.ctrlKey || event.metaKey) return;
            const items = this.triggers().filter(item => !item.disabled);
            const index = items.indexOf(trigger);
            const orientation = this.el.getAttribute("phx-value-navigation-orientation");
            const rtl = this.el.getAttribute("phx-value-dir") === "rtl";
            let next;
            if (event.key === "Home") next = 0;
            else if (event.key === "End") next = items.length - 1;
            else if (orientation === "vertical" && event.key === "ArrowDown") next = index + 1;
            else if (orientation === "vertical" && event.key === "ArrowUp") next = index - 1;
            else if (orientation === "horizontal" && event.key === "ArrowRight") next = index + (rtl ? -1 : 1);
            else if (orientation === "horizontal" && event.key === "ArrowLeft") next = index + (rtl ? 1 : -1);
            else return;
            event.preventDefault();
            if (!items.length) return;
            const loop = this.el.getAttribute("phx-value-loop") !== "false";
            if (!loop && (next < 0 || next >= items.length)) return;
            const target = items[(next + items.length) % items.length];
            ${family === "tabs" ? "items.forEach(item => item.tabIndex = item === target ? 0 : -1);" : ""}
            target.focus();
          };
          this.el.addEventListener("click", this.click);
          this.el.addEventListener("keydown", this.keydown);
          ${family === "tabs" ? 'this.el.addEventListener("focusin", this.focus);' : ""}
          this.sync();
        },
        updated() { this.pending = null; this.sync(); },
        destroyed() {
          this.el.removeEventListener("click", this.click);
          this.el.removeEventListener("keydown", this.keydown);
          ${family === "tabs" ? 'this.el.removeEventListener("focusin", this.focus);' : ""}
        },
        trigger(target) {
          const trigger = target.closest('[data-slot="${family}-trigger"]');
          return trigger && trigger.closest('[data-slot="${family}"]') === this.el ? trigger : null;
        },
        triggers() {
          return Array.from(this.el.querySelectorAll('[data-slot="${family}-trigger"]')).filter(trigger => this.trigger(trigger) === trigger);
        },
        select(trigger) {
          ${family === "accordion" ? 'if (trigger.getAttribute("aria-disabled") === "true") return;' : 'if (trigger.disabled || trigger.getAttribute("aria-selected") === "true" || this.pending === trigger.id) return; this.pending = trigger.id;'}
          const event = this.el.getAttribute("phx-value-on-change");
          const payload = {id: this.el.id, value: trigger.getAttribute("phx-value-value")};
          ${family === "accordion" ? `const current = JSON.parse(this.el.getAttribute("phx-value-selected"));
          const item = payload.value;
          payload.item = item;
          if (this.el.getAttribute("phx-value-type") === "multiple") {
            payload.value = current.includes(item) ? current.filter(value => value !== item) : [...current, item];
          } else {
            payload.value = current.includes(item) && this.el.getAttribute("phx-value-collapsible") === "true" ? null : item;
          }` : ""}
          // A failed push leaves the server-rendered selection untouched.
          ${family === "tabs" ? "this.sendEvent(event, payload).catch(() => { if (this.pending === trigger.id) this.pending = null; });" : "this.sendEvent(event, payload);"}
        },
        sync() {
          ${family === "tabs" ? `const items = this.triggers().filter(trigger => !trigger.disabled);
          const focused = items.includes(document.activeElement) ? document.activeElement : null;
          const selected = items.find(trigger => trigger.getAttribute("aria-selected") === "true");
          const current = focused || selected || items[0];
          this.triggers().forEach(trigger => trigger.tabIndex = trigger === current ? 0 : -1);
          this.el.querySelectorAll('[data-slot="tabs-list"]').forEach(list => {
            if (list.closest('[data-slot="tabs"]') === this.el) list.tabIndex = items.length ? 0 : -1;
          });
          this.el.querySelectorAll('[data-slot="tabs-content"]').forEach(panel => {
            if (panel.closest('[data-slot="tabs"]') === this.el && panel.style.animationDuration === "0s") panel.style.removeProperty("animation-duration");
          });` : `this.el.querySelectorAll('[data-slot="accordion-content"]').forEach(panel => {
            if (panel.closest('[data-slot="accordion"]') !== this.el || panel.hidden) return;
            panel.style.setProperty("--radix-collapsible-content-height", panel.scrollHeight + "px");
            panel.style.setProperty("--radix-collapsible-content-width", panel.scrollWidth + "px");
          });`}
        }
      }`

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name !== "accordion" && spec.name !== "tabs") return undefined
  const klass = (name: string) => {
    const fn = spec.functions.find(component => component.name === name)
    if (!fn) throw new Error(`Missing linked component spec: ${name}`)
    return JSON.stringify(fn.baseClasses)
  }
  if (spec.name === "accordion") return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Linked, server-controlled accordion components.

  Give each root a stable unique \`id\`, bind its \`:let\` context to each item,
  and bind each item's \`:let\` context to its trigger and content. \`value\`
  controls selection; \`default_value\` is used when \`value\` is not supplied.
  Single accordions accept a string or nil; multiple accordions accept a list.

  The colocated hook pushes \`on_change\` (default \`shadcn:accordion-change\`)
  with \`%{"id" => root_id, "item" => clicked_item, "value" => next_value}\`.
  Handle that event in the owning LiveView or \`target\` LiveComponent and
  assign the result of \`accordion_next_value/4\` back to \`value\`. This renders
  previously closed slots, whose children Radix deliberately omits in SSR.
  Slots are retained as render functions, never discarded or cached HTML.
  \`use ShadcnLiveview\` imports components only, so call the helper through its
  module (or \`import ShadcnLiveview.Components.Accordion, only: [accordion_next_value: 4]\`):

      alias ShadcnLiveview.Components.Accordion

      def handle_event("shadcn:accordion-change", %{"item" => item}, socket) do
        value = Accordion.accordion_next_value(socket.assigns.expanded, item, "single", true)
        {:noreply, assign(socket, :expanded, value)}
      end

  Click/Enter/Space use native buttons. Arrow/Home/End navigation skips disabled
  items, respects orientation/direction, and never crosses nested roots.
  LiveView patches refresh dimensions and state without accumulating listeners.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string, required: true
  attr :type, :string, values: ~w(single multiple), default: "single"
  attr :value, :any, default: :uncontrolled
  attr :default_value, :any, default: nil
  attr :collapsible, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :orientation, :string, values: ~w(vertical horizontal), default: "vertical"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"
  attr :on_change, :string, default: "shadcn:accordion-change"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders an accordion root and passes its selection context to its slot."
  def accordion(assigns) do
    value = if assigns.value == :uncontrolled, do: assigns.default_value, else: assigns.value
    selected = List.wrap(value)
    context = Map.take(assigns, [:id, :type, :collapsible, :disabled, :orientation, :dir]) |> Map.put(:selected, selected)
    assigns = assign(assigns, :context, context)
    ~H"""
    <div id={@id} data-slot="accordion" data-orientation={@orientation}
      phx-hook=".Accordion" phx-target={@target} phx-value-on-change={@on_change}
      phx-value-navigation-orientation={@orientation} phx-value-dir={@dir}
      phx-value-selected={Jason.encode!(@context.selected)} phx-value-type={@type}
      phx-value-collapsible={to_string(@collapsible)}
      class={classes([${klass("accordion")}, @class])} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Accordion">
${hook("accordion")}
    </script>
    """
  end

  @doc "Computes the selected value for an accordion change event on the server."
  def accordion_next_value(current, item, "multiple", _collapsible) do
    values = List.wrap(current)
    if item in values, do: List.delete(values, item), else: values ++ [item]
  end
  def accordion_next_value(current, item, "single", collapsible) do
    if current == item && collapsible, do: nil, else: item
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :trigger_id, :string, default: nil
  attr :content_id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders an item and passes its linked IDs and state to trigger/content slots."
  def accordion_item(assigns) do
    context = assigns.context
    item = Map.merge(context, %{
      value: assigns.value,
      open: assigns.value in context.selected,
      disabled: context.disabled || assigns.disabled,
      trigger_id: assigns.trigger_id || context.id <> "-" <> URI.encode_www_form(assigns.value) <> "-trigger",
      content_id: assigns.content_id || context.id <> "-" <> URI.encode_www_form(assigns.value) <> "-content"
    })
    assigns = assign(assigns, :item, item)
    ~H"""
    <div data-slot="accordion-item" data-state={state(@item.open)} data-orientation={@item.orientation}
      data-disabled={if @item.disabled, do: ""} class={classes([${klass("accordion_item")}, @class])} {@rest}>
      {render_slot(@inner_block, @item)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(name value form)
  slot :inner_block, required: true

  @doc "Renders an item's accessible native button and disclosure icons."
  def accordion_trigger(assigns) do
    ~H"""
    <h3 class="flex" data-state={state(@context.open)} data-orientation={@context.orientation}
      data-disabled={if @context.disabled, do: ""}>
      <button type="button" id={@context.trigger_id} data-slot="accordion-trigger"
        data-state={state(@context.open)} data-orientation={@context.orientation}
        data-disabled={if @context.disabled, do: ""} disabled={@context.disabled}
        aria-expanded={to_string(@context.open)}
        aria-disabled={if @context.open && @context.type == "single" && !@context.collapsible, do: "true"}
        aria-controls={if @context.open, do: @context.content_id} data-radix-collection-item=""
        phx-value-value={@context.value} class={classes([${klass("accordion_trigger")}, @class])} {@rest}>
        {render_slot(@inner_block)}
        <ShadcnLiveview.Components.Icon.icon name="chevron-down" data-slot="accordion-trigger-icon"
          class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:hidden" />
        <ShadcnLiveview.Components.Icon.icon name="chevron-up" data-slot="accordion-trigger-icon"
          class="pointer-events-none hidden shrink-0 group-aria-expanded/accordion-trigger:inline" />
      </button>
    </h3>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: false

  @doc "Renders an item's region; closed content children mount after a server selection."
  def accordion_content(assigns) do
    ~H"""
    <div id={@context.content_id} role="region" aria-labelledby={@context.trigger_id}
      data-slot="accordion-content" data-state={state(@context.open)} data-orientation={@context.orientation}
      data-disabled={if @context.disabled, do: ""} hidden={not (@context.open || @force_mount)}
      class=${klass("accordion_content")}
      style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"
      {@rest}>
      <div :if={@context.open || @force_mount}
        class={classes(["h-(--radix-accordion-content-height) pt-0 pb-2.5 [&_a]:underline [&_a]:underline-offset-3 [&_a]:hover:text-foreground [&_p:not(:last-child)]:mb-4", @class])}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp state(true), do: "open"
  defp state(false), do: "closed"
end
`
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Linked tabs with explicit stable IDs and server-owned selection.

  Pass the root's \`:let\` context to list, triggers and panels. \`value\` is
  the current selected string (nil means no selection); \`default_value\` is
  used only when the caller omits \`value\`. The hook pushes \`on_change\`
  (default \`shadcn:tabs-change\`) with \`%{"id" => root_id, "value" => value}\`.
  Assign this value in your owning LiveView or \`target\` LiveComponent:

      def handle_event("shadcn:tabs-change", %{"value" => value}, socket) do
        {:noreply, assign(socket, :selected_tab, value)}
      end

  Unselected panels omit children in SSR, but their render slots remain on the
  server and are rendered by the resulting patch. \`force_mount\` retains
  inactive panel children. IDs and both ARIA directions derive from root ID
  plus value, so instances cannot alias each other's relationships.

  Initial SSR deliberately has -1 roving tabindex, matching Radix before
  registration. On mount and updates the hook chooses the selected/first
  enabled tab; arrows/Home/End move focus, automatic mode selects on focus,
  manual mode selects on click/Enter/Space. Disabled tabs are skipped and
  listeners are removed when destroyed. Nested roots remain independent.

  The vendored shadcn Tabs wrapper consumes \`orientation\` without forwarding
  it to Radix: its root can be visually vertical while its descendants and
  keyboard navigation stay horizontal. \`navigation_orientation\` defaults
  to horizontal to preserve that verified SSR behavior; set it explicitly to
  vertical when you want semantic vertical tabs.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string, required: true
  attr :value, :any, default: :uncontrolled
  attr :default_value, :string, default: nil
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :navigation_orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"
  attr :activation_mode, :string, values: ~w(automatic manual), default: "automatic"
  attr :loop, :boolean, default: true
  attr :on_change, :string, default: "shadcn:tabs-change"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders the tabs root and passes its selected value and ID context to its slot."
  def tabs(assigns) do
    value = if assigns.value == :uncontrolled, do: assigns.default_value, else: assigns.value
    context = %{id: assigns.id, value: value, orientation: assigns.navigation_orientation}
    assigns = assign(assigns, :context, context)
    ~H"""
    <div id={@id} dir={@dir} data-slot="tabs" data-orientation={@orientation}
      phx-hook=".Tabs" phx-target={@target} phx-value-on-change={@on_change}
      phx-value-activation-mode={@activation_mode} phx-value-loop={to_string(@loop)}
      phx-value-navigation-orientation={@navigation_orientation} phx-value-dir={@dir}
      class={classes([${klass("tabs")}, @class])} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Tabs">
${hook("tabs")}
    </script>
    """
  end

  attr :context, :map, required: true
  attr :variant, :string, values: ~w(default line), default: "default"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a tablist with default or line styling."
  def tabs_list(assigns) do
    ~H"""
    <div role="tablist" aria-orientation={@context.orientation} tabindex="-1"
      data-orientation={@context.orientation} data-slot="tabs-list" data-variant={@variant}
      style="outline:none"
      class={classes([${klass("tabs_list")}, if(@variant == "line", do: "gap-1 bg-transparent", else: "bg-muted"), @class])}
      {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(name form)
  slot :inner_block, required: true

  @doc "Renders a tab button linked to its panel through the root context."
  def tabs_trigger(assigns) do
    assigns = assign(assigns, :active, assigns.value == assigns.context.value)
    ~H"""
    <button type="button" role="tab" id={tab_id(@context, @value, "trigger")}
      aria-selected={to_string(@active)} aria-controls={tab_id(@context, @value, "content")}
      data-state={if @active, do: "active", else: "inactive"} data-disabled={if @disabled, do: ""}
      disabled={@disabled} tabindex="-1" data-orientation={@context.orientation}
      data-slot="tabs-trigger" data-radix-collection-item="" phx-value-value={@value}
      class={classes([${klass("tabs_trigger")}, @class])} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: false

  @doc "Renders a tabpanel; inactive children mount on selection unless force-mounted."
  def tabs_content(assigns) do
    assigns = assign(assigns, :active, assigns.value == assigns.context.value)
    ~H"""
    <div id={tab_id(@context, @value, "content")} role="tabpanel"
      aria-labelledby={tab_id(@context, @value, "trigger")} tabindex="0"
      data-state={if @active, do: "active", else: "inactive"} data-orientation={@context.orientation}
      data-slot="tabs-content" hidden={not (@active || @force_mount)}
      {if @active, do: %{style: "animation-duration:0s"}, else: %{}}
      class={classes([${klass("tabs_content")}, @class])} {@rest}>
      <%= if @active || @force_mount do %>{render_slot(@inner_block)}<% end %>
    </div>
    """
  end

  defp tab_id(context, value, suffix), do: context.id <> "-" <> URI.encode_www_form(value) <> "-" <> suffix
end
`
}
