defmodule ShadcnLiveview.Components.Accordion do
  @moduledoc """
  Linked, server-controlled accordion components.

  Give each root a stable unique `id`, bind its `:let` context to each item,
  and bind each item's `:let` context to its trigger and content. `value`
  controls selection; `default_value` is used when `value` is not supplied.
  Single accordions accept a string or nil; multiple accordions accept a list.

  The colocated hook pushes `on_change` (default `shadcn:accordion-change`)
  with `%{"id" => root_id, "item" => clicked_item, "value" => next_value}`.
  Handle that event in the owning LiveView or `target` LiveComponent and
  assign the result of `accordion_next_value/4` back to `value`. This renders
  previously closed slots, whose children Radix deliberately omits in SSR.
  Slots are retained as render functions, never discarded or cached HTML.
  `use ShadcnLiveview` imports components only, so call the helper through its
  module (or `import ShadcnLiveview.Components.Accordion, only: [accordion_next_value: 4]`):

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

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :type, :string, values: ~w(single multiple), default: "single"
  attr :value, :any, default: :uncontrolled

  attr :default_value, :any,
    default: nil,
    doc: "Uncontrolled initial `value`; ignored once `value` is supplied."

  attr :collapsible, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :orientation, :string, values: ~w(vertical horizontal), default: "vertical"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"

  attr :on_change, :string,
    default: "shadcn:accordion-change",
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

  @doc "Renders an accordion root and passes its selection context to its slot."
  def accordion(assigns) do
    value = if assigns.value == :uncontrolled, do: assigns.default_value, else: assigns.value
    selected = List.wrap(value)

    context =
      Map.take(assigns, [:id, :type, :collapsible, :disabled, :orientation, :dir])
      |> Map.put(:selected, selected)

    assigns = assign(assigns, :context, context)

    ~H"""
    <div
      id={@id}
      data-slot="accordion"
      data-orientation={@orientation}
      phx-hook=".Accordion"
      phx-target={@target}
      phx-value-on-change={@on_change}
      phx-value-navigation-orientation={@orientation}
      phx-value-dir={@dir}
      phx-value-selected={Jason.encode!(@context.selected)}
      phx-value-type={@type}
      phx-value-collapsible={to_string(@collapsible)}
      class={classes(["flex w-full flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Accordion">
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
            
            target.focus();
          };
          this.el.addEventListener("click", this.click);
          this.el.addEventListener("keydown", this.keydown);
          
          this.sync();
        },
        updated() { this.pending = null; this.sync(); },
        destroyed() {
          this.el.removeEventListener("click", this.click);
          this.el.removeEventListener("keydown", this.keydown);
          
        },
        trigger(target) {
          const trigger = target.closest('[data-slot="accordion-trigger"]');
          return trigger && trigger.closest('[data-slot="accordion"]') === this.el ? trigger : null;
        },
        triggers() {
          return Array.from(this.el.querySelectorAll('[data-slot="accordion-trigger"]')).filter(trigger => this.trigger(trigger) === trigger);
        },
        select(trigger) {
          if (trigger.getAttribute("aria-disabled") === "true") return;
          const event = this.el.getAttribute("phx-value-on-change");
          const payload = {id: this.el.id, value: trigger.getAttribute("phx-value-value")};
          const current = JSON.parse(this.el.getAttribute("phx-value-selected"));
          const item = payload.value;
          payload.item = item;
          if (this.el.getAttribute("phx-value-type") === "multiple") {
            payload.value = current.includes(item) ? current.filter(value => value !== item) : [...current, item];
          } else {
            payload.value = current.includes(item) && this.el.getAttribute("phx-value-collapsible") === "true" ? null : item;
          }
          // A failed push leaves the server-rendered selection untouched.
          this.sendEvent(event, payload);
        },
        sync() {
          this.el.querySelectorAll('[data-slot="accordion-content"]').forEach(panel => {
            if (panel.closest('[data-slot="accordion"]') !== this.el || panel.hidden) return;
            panel.style.setProperty("--radix-collapsible-content-height", panel.scrollHeight + "px");
            panel.style.setProperty("--radix-collapsible-content-width", panel.scrollWidth + "px");
          });
        }
      }
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

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders an item and passes its linked IDs and state to trigger/content slots."
  def accordion_item(assigns) do
    context = assigns.context

    item =
      Map.merge(context, %{
        value: assigns.value,
        open: assigns.value in context.selected,
        disabled: context.disabled || assigns.disabled,
        trigger_id:
          assigns.trigger_id ||
            context.id <> "-" <> URI.encode_www_form(assigns.value) <> "-trigger",
        content_id:
          assigns.content_id ||
            context.id <> "-" <> URI.encode_www_form(assigns.value) <> "-content"
      })

    assigns = assign(assigns, :item, item)

    ~H"""
    <div
      data-slot="accordion-item"
      data-state={state(@item.open)}
      data-orientation={@item.orientation}
      data-disabled={if @item.disabled, do: ""}
      class={classes(["not-last:border-b", @class])}
      {@rest}
    >
      {render_slot(@inner_block, @item)}
    </div>
    """
  end

  attr :context, :map, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(name value form)
  slot :inner_block, required: true

  @doc "Renders an item's accessible native button and disclosure icons."
  def accordion_trigger(assigns) do
    ~H"""
    <h3
      class="flex"
      data-state={state(@context.open)}
      data-orientation={@context.orientation}
      data-disabled={if @context.disabled, do: ""}
    >
      <button
        type="button"
        id={@context.trigger_id}
        data-slot="accordion-trigger"
        data-state={state(@context.open)}
        data-orientation={@context.orientation}
        data-disabled={if @context.disabled, do: ""}
        disabled={@context.disabled}
        aria-expanded={to_string(@context.open)}
        aria-disabled={
          if @context.open && @context.type == "single" && !@context.collapsible, do: "true"
        }
        aria-controls={if @context.open, do: @context.content_id}
        data-radix-collection-item=""
        phx-value-value={@context.value}
        class={
          classes([
            "group/accordion-trigger relative flex flex-1 items-start justify-between rounded-lg border border-transparent py-2.5 text-left text-sm font-medium transition-all outline-none hover:underline focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:after:border-ring disabled:pointer-events-none disabled:opacity-50 **:data-[slot=accordion-trigger-icon]:ml-auto **:data-[slot=accordion-trigger-icon]:size-4 **:data-[slot=accordion-trigger-icon]:text-muted-foreground",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
        <ShadcnLiveview.Components.Icon.icon
          name="chevron-down"
          data-slot="accordion-trigger-icon"
          class="pointer-events-none shrink-0 group-aria-expanded/accordion-trigger:hidden"
        />
        <ShadcnLiveview.Components.Icon.icon
          name="chevron-up"
          data-slot="accordion-trigger-icon"
          class="pointer-events-none hidden shrink-0 group-aria-expanded/accordion-trigger:inline"
        />
      </button>
    </h3>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: false

  @doc "Renders an item's region; closed content children mount after a server selection."
  def accordion_content(assigns) do
    ~H"""
    <div
      id={@context.content_id}
      role="region"
      aria-labelledby={@context.trigger_id}
      data-slot="accordion-content"
      data-state={state(@context.open)}
      data-orientation={@context.orientation}
      data-disabled={if @context.disabled, do: ""}
      hidden={not (@context.open || @force_mount)}
      class="overflow-hidden text-sm data-open:animate-accordion-down data-closed:animate-accordion-up"
      style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"
      {@rest}
    >
      <div
        :if={@context.open || @force_mount}
        class={
          classes([
            "h-(--radix-accordion-content-height) pt-0 pb-2.5 [&_a]:underline [&_a]:underline-offset-3 [&_a]:hover:text-foreground [&_p:not(:last-child)]:mb-4",
            @class
          ])
        }
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp state(true), do: "open"
  defp state(false), do: "closed"
end
