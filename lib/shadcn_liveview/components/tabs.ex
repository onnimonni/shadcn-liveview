defmodule ShadcnLiveview.Components.Tabs do
  @moduledoc """
  Linked tabs with explicit stable IDs and server-owned selection.

  Pass the root's `:let` context to list, triggers and panels. `value` is
  the current selected string (nil means no selection); `default_value` is
  used only when the caller omits `value`. The hook pushes `on_change`
  (default `shadcn:tabs-change`) with `%{"id" => root_id, "value" => value}`.
  Assign this value in your owning LiveView or `target` LiveComponent:

      def handle_event("shadcn:tabs-change", %{"value" => value}, socket) do
        {:noreply, assign(socket, :selected_tab, value)}
      end

  Unselected panels omit children in SSR, but their render slots remain on the
  server and are rendered by the resulting patch. `force_mount` retains
  inactive panel children. IDs and both ARIA directions derive from root ID
  plus value, so instances cannot alias each other's relationships.

  Initial SSR deliberately has -1 roving tabindex, matching Radix before
  registration. On mount and updates the hook chooses the selected/first
  enabled tab; arrows/Home/End move focus, automatic mode selects on focus,
  manual mode selects on click/Enter/Space. Disabled tabs are skipped and
  listeners are removed when destroyed. Nested roots remain independent.

  The vendored shadcn Tabs wrapper consumes `orientation` without forwarding
  it to Radix: its root can be visually vertical while its descendants and
  keyboard navigation stay horizontal. `navigation_orientation` defaults
  to horizontal to preserve that verified SSR behavior; set it explicitly to
  vertical when you want semantic vertical tabs.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :value, :any, default: :uncontrolled

  attr :default_value, :string,
    default: nil,
    doc: "Uncontrolled initial `value`; ignored once `value` is supplied."

  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :navigation_orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"
  attr :activation_mode, :string, values: ~w(automatic manual), default: "automatic"
  attr :loop, :boolean, default: true

  attr :on_change, :string,
    default: "shadcn:tabs-change",
    doc: "LiveView event name pushed on change; the payload is described in the module docs."

  attr :target, :any,
    default: nil,
    doc: "Event target such as `@myself`; equivalent to `phx-target` on the root."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders the tabs root and passes its selected value and ID context to its slot."
  def tabs(assigns) do
    value = if assigns.value == :uncontrolled, do: assigns.default_value, else: assigns.value
    context = %{id: assigns.id, value: value, orientation: assigns.navigation_orientation}
    assigns = assign(assigns, :context, context)

    ~H"""
    <div
      id={@id}
      dir={@dir}
      data-slot="tabs"
      data-orientation={@orientation}
      phx-hook=".Tabs"
      phx-target={@target}
      phx-value-on-change={@on_change}
      phx-value-activation-mode={@activation_mode}
      phx-value-loop={to_string(@loop)}
      phx-value-navigation-orientation={@navigation_orientation}
      phx-value-dir={@dir}
      class={classes(["group/tabs flex gap-2 data-horizontal:flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Tabs">
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
            items.forEach(item => item.tabIndex = item === target ? 0 : -1);
            target.focus();
          };
          this.el.addEventListener("click", this.click);
          this.el.addEventListener("keydown", this.keydown);
          this.el.addEventListener("focusin", this.focus);
          this.sync();
        },
        updated() { this.pending = null; this.sync(); },
        destroyed() {
          this.el.removeEventListener("click", this.click);
          this.el.removeEventListener("keydown", this.keydown);
          this.el.removeEventListener("focusin", this.focus);
        },
        trigger(target) {
          const trigger = target.closest('[data-slot="tabs-trigger"]');
          return trigger && trigger.closest('[data-slot="tabs"]') === this.el ? trigger : null;
        },
        triggers() {
          return Array.from(this.el.querySelectorAll('[data-slot="tabs-trigger"]')).filter(trigger => this.trigger(trigger) === trigger);
        },
        select(trigger) {
          if (trigger.disabled || trigger.getAttribute("aria-selected") === "true" || this.pending === trigger.id) return; this.pending = trigger.id;
          const event = this.el.getAttribute("phx-value-on-change");
          const payload = {id: this.el.id, value: trigger.getAttribute("phx-value-value")};
          
          // A failed push leaves the server-rendered selection untouched.
          this.sendEvent(event, payload).catch(() => { if (this.pending === trigger.id) this.pending = null; });
        },
        sync() {
          const items = this.triggers().filter(trigger => !trigger.disabled);
          const focused = items.includes(document.activeElement) ? document.activeElement : null;
          const selected = items.find(trigger => trigger.getAttribute("aria-selected") === "true");
          const current = focused || selected || items[0];
          this.triggers().forEach(trigger => trigger.tabIndex = trigger === current ? 0 : -1);
          this.el.querySelectorAll('[data-slot="tabs-list"]').forEach(list => {
            if (list.closest('[data-slot="tabs"]') === this.el) list.tabIndex = items.length ? 0 : -1;
          });
          this.el.querySelectorAll('[data-slot="tabs-content"]').forEach(panel => {
            if (panel.closest('[data-slot="tabs"]') === this.el && panel.style.animationDuration === "0s") panel.style.removeProperty("animation-duration");
          });
        }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :variant, :string, values: ~w(default line), default: "default"

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a tablist with default or line styling."
  def tabs_list(assigns) do
    ~H"""
    <div
      role="tablist"
      aria-orientation={@context.orientation}
      tabindex="-1"
      data-orientation={@context.orientation}
      data-slot="tabs-list"
      data-variant={@variant}
      style="outline:none"
      class={
        classes([
          "group/tabs-list inline-flex w-fit items-center justify-center rounded-lg p-[3px] text-muted-foreground group-data-horizontal/tabs:h-8 group-data-vertical/tabs:h-fit group-data-vertical/tabs:flex-col data-[variant=line]:rounded-none",
          if(@variant == "line", do: "gap-1 bg-transparent", else: "bg-muted"),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(name form)
  slot :inner_block, required: true

  @doc "Renders a tab button linked to its panel through the root context."
  def tabs_trigger(assigns) do
    assigns = assign(assigns, :active, assigns.value == assigns.context.value)

    ~H"""
    <button
      type="button"
      role="tab"
      id={tab_id(@context, @value, "trigger")}
      aria-selected={to_string(@active)}
      aria-controls={tab_id(@context, @value, "content")}
      data-state={if @active, do: "active", else: "inactive"}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      tabindex="-1"
      data-orientation={@context.orientation}
      data-slot="tabs-trigger"
      data-radix-collection-item=""
      phx-value-value={@value}
      class={
        classes([
          "relative inline-flex h-[calc(100%-1px)] flex-1 items-center justify-center gap-1.5 rounded-md border border-transparent px-1.5 py-0.5 text-sm font-medium whitespace-nowrap text-foreground/60 transition-all group-data-vertical/tabs:w-full group-data-vertical/tabs:justify-start hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 focus-visible:outline-ring disabled:pointer-events-none disabled:opacity-50 has-data-[icon=inline-end]:pr-1 has-data-[icon=inline-start]:pl-1 dark:text-muted-foreground dark:hover:text-foreground group-data-[variant=default]/tabs-list:data-active:shadow-sm group-data-[variant=line]/tabs-list:data-active:shadow-none [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 group-data-[variant=line]/tabs-list:bg-transparent group-data-[variant=line]/tabs-list:data-active:bg-transparent dark:group-data-[variant=line]/tabs-list:data-active:border-transparent dark:group-data-[variant=line]/tabs-list:data-active:bg-transparent data-active:bg-background data-active:text-foreground dark:data-active:border-input dark:data-active:bg-input/30 dark:data-active:text-foreground after:absolute after:bg-foreground after:opacity-0 after:transition-opacity group-data-horizontal/tabs:after:inset-x-0 group-data-horizontal/tabs:after:bottom-[-5px] group-data-horizontal/tabs:after:h-0.5 group-data-vertical/tabs:after:inset-y-0 group-data-vertical/tabs:after:-right-1 group-data-vertical/tabs:after:w-0.5 group-data-[variant=line]/tabs-list:data-active:after:opacity-100",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :force_mount, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: false

  @doc "Renders a tabpanel; inactive children mount on selection unless force-mounted."
  def tabs_content(assigns) do
    assigns = assign(assigns, :active, assigns.value == assigns.context.value)

    ~H"""
    <div
      id={tab_id(@context, @value, "content")}
      role="tabpanel"
      aria-labelledby={tab_id(@context, @value, "trigger")}
      tabindex="0"
      data-state={if @active, do: "active", else: "inactive"}
      data-orientation={@context.orientation}
      data-slot="tabs-content"
      hidden={not (@active || @force_mount)}
      {if @active, do: %{style: "animation-duration:0s"}, else: %{}}
      class={classes(["flex-1 text-sm outline-none", @class])}
      {@rest}
    >
      <%= if @active || @force_mount do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end

  defp tab_id(context, value, suffix),
    do: context.id <> "-" <> URI.encode_www_form(value) <> "-" <> suffix
end
