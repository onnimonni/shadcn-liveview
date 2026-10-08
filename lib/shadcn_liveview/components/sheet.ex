defmodule ShadcnLiveview.Components.Sheet do
  @moduledoc """
  Controlled sheet components with explicit, per-instance ID context.

  Pass a stable `id`, `open` assign and optional `on_open`/`on_close`
  LiveView JS commands. The defaults push `shadcn:modal-open` and
  `shadcn:modal-close` with `%{id: id}`; the owning LiveView updates
  its open assign. Both named slots receive context with `:let`.
  Content, title, description and close controls consume that context.
  The root `id` is the content ID; default IDs append `-trigger`,
  `-title` and `-description`. Title/description IDs can be overridden
  on the root. Native action/close buttons accept `on_click` JS that
  runs before the root's close command, plus ordinary form attributes.

  Closed content is absent, as with Radix portals. Initial SSR intentionally
  omits Radix's effect-installed ARIA links; the colocated hook establishes
  those links, modal focus containment, Escape dismissal and focus restoration
  when LiveView connects.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]
  alias Phoenix.LiveView.JS
  alias ShadcnLiveview.Components.Icon

  @button_classes %{
    {"ghost", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg"
  }

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :modal, :boolean, default: true

  attr :dismissible, :boolean, default: true
  attr :title_id, :string, default: nil
  attr :description_id, :string, default: nil
  attr :trigger_id, :string, default: nil
  attr :on_open, JS, default: nil
  attr :on_close, JS, default: nil
  slot :trigger
  slot :content, required: true
  @doc "Renders trigger and open content slots, yielding the explicit modal context."
  def sheet(assigns) do
    context = %{
      id: assigns.id,
      open: assigns.open,
      modal: assigns.modal,
      dismissible: assigns.dismissible,
      title_id: assigns.title_id || assigns.id <> "-title",
      description_id: assigns.description_id || assigns.id <> "-description",
      trigger_id: assigns.trigger_id || assigns.id <> "-trigger",
      on_open: assigns.on_open || JS.push("shadcn:modal-open", value: %{id: assigns.id}),
      on_close: assigns.on_close || JS.push("shadcn:modal-close", value: %{id: assigns.id})
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    {render_slot(@trigger, @context)}
    {render_slot(@content, @context)}
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true
  @doc "A native trigger button; never wrap another button inside this component."
  def sheet_trigger(assigns) do
    ~H"""
    <button
      type="button"
      id={@context.trigger_id}
      aria-haspopup="dialog"
      aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.id}
      data-state={if @context.open, do: "open", else: "closed"}
      data-slot="sheet-trigger"
      class={@class}
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

  def sheet_overlay(assigns) do
    ~H"""
    <div
      :if={@context.open and @context.modal}
      data-state="open"
      data-slot="sheet-overlay"
      class={
        classes([
          "fixed inset-0 z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0",
          @class
        ])
      }
      style={"pointer-events:auto;" <> (@style || "")}
      phx-click={if @context.dismissible, do: @context.on_close}
      {@rest}
    >
    </div>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :show_close_button, :boolean, default: true
  attr :side, :string, default: "right", values: ~w(top right bottom left)
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true
  @doc "Renders the portaled SSR structure only while its context is open."
  def sheet_content(assigns) do
    assigns = assign(assigns, :button_classes, @button_classes)

    ~H"""
    <.sheet_overlay context={@context} />
    <div
      :if={@context.open}
      role="dialog"
      id={@context.id}
      data-state="open"
      data-slot="sheet-content"
      data-side={@side}
      class={
        classes([
          "fixed z-50 flex flex-col gap-4 bg-popover bg-clip-padding text-sm text-popover-foreground shadow-lg transition duration-200 ease-in-out data-[side=bottom]:inset-x-0 data-[side=bottom]:bottom-0 data-[side=bottom]:h-auto data-[side=bottom]:border-t data-[side=left]:inset-y-0 data-[side=left]:left-0 data-[side=left]:h-full data-[side=left]:w-3/4 data-[side=left]:border-r data-[side=right]:inset-y-0 data-[side=right]:right-0 data-[side=right]:h-full data-[side=right]:w-3/4 data-[side=right]:border-l data-[side=top]:inset-x-0 data-[side=top]:top-0 data-[side=top]:h-auto data-[side=top]:border-b data-[side=left]:sm:max-w-sm data-[side=right]:sm:max-w-sm data-open:animate-in data-open:fade-in-0 data-[side=bottom]:data-open:slide-in-from-bottom-10 data-[side=left]:data-open:slide-in-from-left-10 data-[side=right]:data-open:slide-in-from-right-10 data-[side=top]:data-open:slide-in-from-top-10 data-closed:animate-out data-closed:fade-out-0 data-[side=bottom]:data-closed:slide-out-to-bottom-10 data-[side=left]:data-closed:slide-out-to-left-10 data-[side=right]:data-closed:slide-out-to-right-10 data-[side=top]:data-closed:slide-out-to-top-10",
          @class
        ])
      }
      tabindex="-1"
      phx-hook=".Modal"
      phx-value-modal={to_string(@context.modal)}
      phx-value-dismissible={to_string(@context.dismissible)}
      phx-value-trigger-id={@context.trigger_id}
      phx-modal-close={@context.on_close}
      {@rest}
    >
      {render_slot(@inner_block)}
      <button
        :if={@show_close_button}
        type="button"
        data-slot="sheet-close"
        data-variant="ghost"
        data-size="icon-sm"
        class={classes([Map.fetch!(@button_classes, {"ghost", "icon-sm"}), "absolute top-3 right-3"])}
        phx-click={@context.on_close}
      >
        <Icon.icon name="x" /><span class="sr-only">Close</span>
      </button>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Modal">
      export default {
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
          this.liveSocket.execJS(this.el, this.el.getAttribute("phx-modal-close"));
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

  def sheet_header(assigns) do
    ~H"""
    <div data-slot="sheet-header" class={classes(["flex flex-col gap-0.5 p-4", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def sheet_footer(assigns) do
    ~H"""
    <div data-slot="sheet-footer" class={classes(["mt-auto flex flex-col gap-2 p-4", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(type name value disabled form tabindex)
  slot :inner_block, required: true

  def sheet_title(assigns) do
    ~H"""
    <h2
      id={@id || @context.title_id}
      data-slot="sheet-title"
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

  def sheet_description(assigns) do
    ~H"""
    <p
      id={@id || @context.description_id}
      data-slot="sheet-description"
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

  def sheet_close(assigns) do
    ~H"""
    <button
      type={@type}
      data-slot="sheet-close"
      class={@class}
      phx-click={JS.concat(@on_click, @context.on_close)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "An explicit portal slot, useful when composing overlay and content manually."
  slot :inner_block, required: true

  def sheet_portal(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end
end
