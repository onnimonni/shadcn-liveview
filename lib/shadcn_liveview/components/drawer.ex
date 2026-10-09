defmodule ShadcnLiveview.Components.Drawer do
  @moduledoc """
  Controlled drawer components with explicit, per-instance ID context.

  Pass a stable `id`, `open` assign and optional `on_open`/`on_close`
  LiveView JS commands. The defaults push `shadcn:modal-open` and
  `shadcn:modal-close` with `%{id: id}`; the owning LiveView updates
  its open assign. Both named slots receive context with `:let`.
  Content, title, description and close controls consume that context.
  The root `id` is the content ID; default IDs append `-trigger`,
  `-title` and `-description`. Title/description IDs can be overridden
  on the root. Native action/close buttons accept `on_click` JS that
  runs before the root's close command, plus ordinary form attributes.
  Set phx-target on the wrapperless root (or optional `target`) to route
  default open/close commands and hook dismissal to a LiveComponent. Context
  forwards this target to native triggers, overlays, content and close controls.
  Hook dismissal also inherits the nearest containing phx-target; caller-supplied
  JS commands keep their operation order and explicitly supplied push targets.

  Closed content is absent, as with Radix portals. Initial SSR intentionally
  omits Radix's effect-installed ARIA links; the colocated hook establishes
  those links, modal focus containment, Escape dismissal and focus restoration
  when LiveView connects. The basic drawer supports directional pointer dragging, a close threshold and dismissible state; it does not expose Vaul snap points or background scaling.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]
  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :modal, :boolean, default: true

  attr :dismissible, :boolean, default: true
  attr :title_id, :string, default: nil
  attr :description_id, :string, default: nil
  attr :trigger_id, :string, default: nil
  attr :on_open, JS, default: nil
  attr :on_close, JS, default: nil
  attr :target, :any, default: nil
  attr :rest, :global
  attr :direction, :string, default: "bottom", values: ~w(top right bottom left)
  attr :draggable, :boolean, default: true
  attr :close_threshold, :float, default: 0.25
  slot :trigger
  slot :content, required: true
  @doc "Renders trigger and open content slots, yielding the explicit modal context."
  def drawer(assigns) do
    target = assigns.target || Map.get(assigns.rest, :"phx-target")

    context = %{
      id: assigns.id,
      open: assigns.open,
      modal: assigns.modal,
      target: target,
      dismissible: assigns.dismissible,
      title_id: assigns.title_id || assigns.id <> "-title",
      description_id: assigns.description_id || assigns.id <> "-description",
      trigger_id: assigns.trigger_id || assigns.id <> "-trigger",
      close_event: if(is_nil(assigns.on_close), do: "shadcn:modal-close"),
      on_open: assigns.on_open || push("shadcn:modal-open", assigns.id, target),
      on_close: assigns.on_close || push("shadcn:modal-close", assigns.id, target),
      direction: assigns.direction,
      draggable: assigns.draggable,
      close_threshold: assigns.close_threshold
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    {render_slot(@trigger, @context)}
    {render_slot(@content, @context)}
    """
  end

  defp push(event, id, target) when target in [nil, ""], do: JS.push(event, value: %{id: id})
  defp push(event, id, target), do: JS.push(event, value: %{id: id}, target: target)

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true
  @doc "A native trigger button; never wrap another button inside this component."
  def drawer_trigger(assigns) do
    ~H"""
    <button
      type="button"
      id={@context.trigger_id}
      aria-haspopup="dialog"
      aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.id}
      data-state={if @context.open, do: "open", else: "closed"}
      data-slot="drawer-trigger"
      class={@class}
      phx-target={@context.target}
      phx-click={if @context.open, do: @context.on_close, else: @context.on_open}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :style, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)

  def drawer_overlay(assigns) do
    ~H"""
    <div
      :if={@context.open and @context.modal}
      data-state="open"
      data-slot="drawer-overlay"
      class={
        classes([
          "fixed inset-0 z-50 bg-black/10 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0",
          @class
        ])
      }
      style={"pointer-events:auto;" <> (@style || "")}
      phx-target={@context.target}
      phx-click={if @context.dismissible, do: @context.on_close}
      data-vaul-overlay=""
      data-vaul-snap-points="false"
      data-vaul-snap-points-overlay="true"
      data-vaul-animate="true"
      {@rest}
    >
    </div>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true
  @doc "Renders the portaled SSR structure only while its context is open."
  def drawer_content(assigns) do
    ~H"""
    <.drawer_overlay context={@context} />
    <div
      :if={@context.open}
      role="dialog"
      id={@context.id}
      data-state="open"
      data-slot="drawer-content"
      data-vaul-drawer-direction={@context.direction}
      data-vaul-drawer=""
      data-vaul-delayed-snap-points="false"
      data-vaul-snap-points="false"
      data-vaul-custom-container="false"
      data-vaul-animate="true"
      class={
        classes([
          "group/drawer-content fixed z-50 flex h-auto flex-col bg-popover text-sm text-popover-foreground data-[vaul-drawer-direction=bottom]:inset-x-0 data-[vaul-drawer-direction=bottom]:bottom-0 data-[vaul-drawer-direction=bottom]:mt-24 data-[vaul-drawer-direction=bottom]:max-h-[80vh] data-[vaul-drawer-direction=bottom]:rounded-t-xl data-[vaul-drawer-direction=bottom]:border-t data-[vaul-drawer-direction=left]:inset-y-0 data-[vaul-drawer-direction=left]:left-0 data-[vaul-drawer-direction=left]:w-3/4 data-[vaul-drawer-direction=left]:rounded-r-xl data-[vaul-drawer-direction=left]:border-r data-[vaul-drawer-direction=right]:inset-y-0 data-[vaul-drawer-direction=right]:right-0 data-[vaul-drawer-direction=right]:w-3/4 data-[vaul-drawer-direction=right]:rounded-l-xl data-[vaul-drawer-direction=right]:border-l data-[vaul-drawer-direction=top]:inset-x-0 data-[vaul-drawer-direction=top]:top-0 data-[vaul-drawer-direction=top]:mb-24 data-[vaul-drawer-direction=top]:max-h-[80vh] data-[vaul-drawer-direction=top]:rounded-b-xl data-[vaul-drawer-direction=top]:border-b data-[vaul-drawer-direction=left]:sm:max-w-sm data-[vaul-drawer-direction=right]:sm:max-w-sm",
          @class
        ])
      }
      tabindex="-1"
      phx-hook=".Modal"
      phx-target={@context.target}
      phx-value-modal={to_string(@context.modal)}
      phx-value-dismissible={to_string(@context.dismissible)}
      phx-value-trigger-id={@context.trigger_id}
      phx-modal-close={@context.on_close}
      phx-modal-close-event={@context.close_event}
      phx-value-draggable={to_string(@context.draggable)}
      phx-value-close-threshold={@context.close_threshold}
      {@rest}
    >
      <div class="mx-auto mt-4 hidden h-1 w-[100px] shrink-0 rounded-full bg-muted group-data-[vaul-drawer-direction=bottom]/drawer-content:block" />
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Modal">
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          const key = Symbol.for("shadcn-liveview.modal-stack");
          this.registry = window[key] ||= { stack: [], overflow: null };
          this.previousFocus = document.activeElement;
          if (this.modal() && !this.registry.stack.some(hook => hook.modal())) {
            this.registry.overflow = document.body.style.overflow;
            document.body.style.overflow = "hidden";
          }
          this.registry.stack.push(this);
          this.onKey = event => {
            if (!this.top()) return;
            if (event.key === "Escape" && this.dismissible()) {
              event.preventDefault();
              event.stopPropagation();
              this.close();
            } else if (event.key === "Tab" && this.modal()) {
              const items = this.focusable();
              const first = items[0] || this.el;
              const last = items[items.length - 1] || this.el;
              if (event.shiftKey && (document.activeElement === first || document.activeElement === this.el)) {
                event.preventDefault(); last.focus();
              } else if (!event.shiftKey && (document.activeElement === last || !items.length)) {
                event.preventDefault(); first.focus();
              }
            }
          };
          this.onFocus = event => {
            if (!this.top() || this.el.contains(event.target)) return;
            if (this.modal()) this.focus();
            else if (this.dismissible() && event.target.id !== this.el.getAttribute("phx-value-trigger-id")) this.close();
          };
          this.onOutside = event => {
            if (this.top() && !this.modal() && this.dismissible() && !this.el.contains(event.target) && event.target.id !== this.el.getAttribute("phx-value-trigger-id")) this.close();
          };
          document.addEventListener("keydown", this.onKey, true);
          document.addEventListener("focusin", this.onFocus, true);
          document.addEventListener("pointerdown", this.onOutside, true);
          this.connectAria();
          this.focus();
          if (this.el.getAttribute("phx-value-draggable") === "true") this.connectDrag();
        },
        updated() {
          this.closing = false;
          this.connectAria();
          const draggable = this.el.getAttribute("phx-value-draggable") === "true";
          const direction = this.el.getAttribute("data-vaul-drawer-direction");
          if (this.onDown && (!draggable || direction !== this.dragDirection)) this.disconnectDrag();
          if (draggable && !this.onDown) this.connectDrag();
        },
        destroyed() {
          document.removeEventListener("keydown", this.onKey, true);
          document.removeEventListener("focusin", this.onFocus, true);
          document.removeEventListener("pointerdown", this.onOutside, true);
          this.disconnectDrag();
          const wasTop = this.top();
          this.registry.stack = this.registry.stack.filter(hook => hook !== this);
          if (!this.registry.stack.some(hook => hook.modal()) && this.registry.overflow !== null) {
            document.body.style.overflow = this.registry.overflow;
            this.registry.overflow = null;
          }
          if (wasTop) {
            const trigger = document.getElementById(this.el.getAttribute("phx-value-trigger-id"));
            const target = trigger || this.previousFocus;
            if (target?.isConnected) target.focus();
          }
        },
        modal() { return this.el.getAttribute("phx-value-modal") === "true"; },
        dismissible() { return this.el.getAttribute("phx-value-dismissible") === "true"; },
        top() { return this.registry.stack[this.registry.stack.length - 1] === this; },
        close() {
          if (this.closing) return;
          this.closing = true;
          const event = this.el.getAttribute("phx-modal-close-event");
          if (event) return this.sendEvent(event, {id: this.el.id});
          return this.liveSocket.execJS(this.el, this.el.getAttribute("phx-modal-close"));
        },
        focusable() {
          return [...this.el.querySelectorAll('button, [href], input, select, textarea, [tabindex]')]
            .filter(el => !el.disabled && el.tabIndex >= 0 && !el.closest('[hidden], [inert]') && el.getClientRects().length);
        },
        focus() {
          const cancel = this.el.querySelector('[data-slot="alert-dialog-cancel"]:not(:disabled)');
          (cancel || this.focusable()[0] || this.el).focus();
        },
        connectAria() {
          if (this.modal()) this.el.setAttribute("aria-modal", "true");
          const title = this.el.querySelector('[data-slot$="-title"]');
          const description = this.el.querySelector('[data-slot$="-description"]');
          if (title && !this.el.hasAttribute("aria-labelledby")) this.el.setAttribute("aria-labelledby", title.id);
          if (description) {
            const ids = new Set((this.el.getAttribute("aria-describedby") || "").split(/\s+/).filter(Boolean));
            ids.add(description.id);
            this.el.setAttribute("aria-describedby", [...ids].join(" "));
          }
        },
        disconnectDrag() {
          if (!this.onDown) return;
          this.el.removeEventListener("pointerdown", this.onDown);
          this.el.removeEventListener("pointermove", this.onMove);
          this.el.removeEventListener("pointerup", this.onUp);
          this.el.removeEventListener("pointercancel", this.onCancel);
          Object.assign(this.el.style, this.dragStyles);
          this.drag = null;
          this.onDown = null;
        },
        connectDrag() {
          const direction = this.el.getAttribute("data-vaul-drawer-direction");
          this.dragDirection = direction;
          this.dragStyles = { touchAction: this.el.style.touchAction, transition: this.el.style.transition, transform: this.el.style.transform };
          const vertical = direction === "top" || direction === "bottom";
          const sign = direction === "bottom" || direction === "right" ? 1 : -1;
          this.el.style.touchAction = vertical ? "pan-x" : "pan-y";
          this.onDown = event => {
            if (!this.top() || !this.dismissible() || event.button !== 0 || event.target.closest('button, a, input, select, textarea, [contenteditable], [data-vaul-no-drag]')) return;
            for (let node = event.target; node && node !== this.el; node = node.parentElement) {
              if (vertical && node.scrollHeight > node.clientHeight && node.scrollTop > 0) return;
              if (!vertical && node.scrollWidth > node.clientWidth && node.scrollLeft > 0) return;
            }
            this.drag = { id: event.pointerId, start: vertical ? event.clientY : event.clientX, time: performance.now(), distance: 0 };
            this.el.setPointerCapture(event.pointerId);
          };
          this.onMove = event => {
            if (!this.drag || event.pointerId !== this.drag.id) return;
            this.drag.distance = Math.max(0, sign * ((vertical ? event.clientY : event.clientX) - this.drag.start));
            this.el.style.transition = "none";
            this.el.style.transform = vertical ? "translateY(" + sign * this.drag.distance + "px)" : "translateX(" + sign * this.drag.distance + "px)";
          };
          this.resetDrag = () => {
            this.drag = null;
            this.el.style.transition = this.dragStyles.transition;
            this.el.style.transform = this.dragStyles.transform;
          };
          this.onUp = event => {
            if (!this.drag || event.pointerId !== this.drag.id) return;
            const size = vertical ? this.el.getBoundingClientRect().height : this.el.getBoundingClientRect().width;
            const velocity = this.drag.distance / Math.max(1, performance.now() - this.drag.time);
            const threshold = Number(this.el.getAttribute("phx-value-close-threshold"));
            const dismiss = this.drag.distance > size * threshold || (this.drag.distance > 10 && velocity > 0.4);
            this.resetDrag();
            if (dismiss) this.close();
          };
          this.onCancel = () => this.resetDrag();
          this.el.addEventListener("pointerdown", this.onDown);
          this.el.addEventListener("pointermove", this.onMove);
          this.el.addEventListener("pointerup", this.onUp);
          this.el.addEventListener("pointercancel", this.onCancel);
        }
      }
    </script>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def drawer_header(assigns) do
    ~H"""
    <div
      data-slot="drawer-header"
      class={
        classes([
          "flex flex-col gap-0.5 p-4 group-data-[vaul-drawer-direction=bottom]/drawer-content:text-center group-data-[vaul-drawer-direction=top]/drawer-content:text-center md:gap-0.5 md:text-left",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def drawer_footer(assigns) do
    ~H"""
    <div
      data-slot="drawer-footer"
      class={classes(["mt-auto flex flex-col gap-2 p-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def drawer_title(assigns) do
    ~H"""
    <h2
      id={@id || @context.title_id}
      data-slot="drawer-title"
      class={classes(["cn-font-heading text-base font-medium text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def drawer_description(assigns) do
    ~H"""
    <p
      id={@id || @context.description_id}
      data-slot="drawer-description"
      class={classes(["text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :type, :string, default: "button"
  attr :on_click, JS, default: %JS{}
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def drawer_close(assigns) do
    ~H"""
    <button
      type={@type}
      data-slot="drawer-close"
      class={@class}
      phx-target={@context.target}
      phx-click={JS.concat(@on_click, @context.on_close)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "An explicit portal slot, useful when composing overlay and content manually."
  slot :inner_block, required: true

  def drawer_portal(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end
end
