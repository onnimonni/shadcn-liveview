import type { ComponentSpec } from "../generate"
import { sendEventMethod } from "./hook-events"
import { buttonVariants } from "../../vendor/shadcn/ui/button"
import { cn } from "cn"
import { readFileSync } from "node:fs"
import ts from "typescript"

const families = new Set(["dialog", "alert-dialog", "drawer", "sheet"])
const literal = (value: string) => JSON.stringify(value).replace(/#\{/g, "\\#{")
const buttonVariantNames = ["default", "outline", "secondary", "ghost", "destructive", "link"] as const
const buttonSizeNames = ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"] as const
type ButtonPair = [typeof buttonVariantNames[number], typeof buttonSizeNames[number]]

// Read classes on their own JSX opening element; nested buttons must not
// overwrite a Content's classes as a whole-function traversal would do.
function upstreamClasses(family: string): Map<string, string> {
  const source = readFileSync(new URL(`../../vendor/shadcn/ui/${family}.tsx`, import.meta.url), "utf8")
  const file = ts.createSourceFile(`${family}.tsx`, source, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX)
  const result = new Map<string, string>()
  const visit = (node: ts.Node) => {
    if (ts.isJsxOpeningElement(node) || ts.isJsxSelfClosingElement(node)) {
      const attrs = node.attributes.properties.filter(ts.isJsxAttribute)
      const slot = attrs.find(attr => attr.name.getText(file) === "data-slot")?.initializer
      const className = attrs.find(attr => attr.name.getText(file) === "className")?.initializer
      if (slot && ts.isStringLiteral(slot) && className && ts.isJsxExpression(className) && className.expression) {
        const expression = className.expression
        const value = ts.isCallExpression(expression) ? expression.arguments[0] : expression
        if (value && (ts.isStringLiteral(value) || ts.isNoSubstitutionTemplateLiteral(value))) {
          result.set(slot.text, value.text)
        }
      }
    }
    ts.forEachChild(node, visit)
  }
  visit(file)
  return result
}

// Radix registers Title/Description in layout effects: its initial server Content
// has neither relationship nor aria-modal. The hook installs them on connection.
//
// Native open/close controls push with LiveView JS, which reads only the clicked
// element's own phx-target. Controls rendered without an explicit target carry
// phx-inherit-target and take the nearest ancestor phx-target at click time, as
// hook events do. The capture listener runs before LiveView's window listener;
// every family module evaluates this once, so a global flag dedupes it.
const modalHook = `
      const inheritTarget = Symbol.for("shadcn-liveview.inherit-target");
      if (!window[inheritTarget]) {
        window[inheritTarget] = true;
        document.addEventListener("click", event => {
          const control = event.target instanceof Element ? event.target.closest("[phx-inherit-target]") : null;
          if (!control) return;
          const target = control.parentElement?.closest("[phx-target]")?.getAttribute("phx-target");
          if (target) control.setAttribute("phx-target", target);
          else control.removeAttribute("phx-target");
        }, true);
      }
      export default {
${sendEventMethod("        ")}
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
            // An open popup inside the modal (select, menu, ...) owns Escape: close only that innermost layer.
            if (event.key === "Escape" && this.dismissible() && !this.openPopups().length) {
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
        // Contents of open popups (select, menu, popover ...) whose triggers live in this modal.
        openPopups() { return [...this.el.querySelectorAll("[phx-popup-content-id]")].map(trigger => document.getElementById(trigger.getAttribute("phx-popup-content-id"))).filter(Boolean); },
        top() { return this.registry.stack[this.registry.stack.length - 1] === this; },
        close() {
          if (this.closing) return;
          this.closing = true;
          const event = this.el.getAttribute("phx-modal-close-event");
          // The server owns open state; a failed close push keeps the modal open and closable.
          if (event) return this.sendEvent(event, {id: this.el.id}).catch(() => { this.closing = false; });
          return this.liveSocket.execJS(this.el, this.el.getAttribute("phx-modal-close"));
        },
        focusable() {
          return [...this.el.querySelectorAll('button, [href], input, select, textarea, [tabindex]')]
            .filter(el => !el.disabled && el.tabIndex >= 0 && !el.closest('[hidden], [inert]') && el.getClientRects().length);
        },
        focus() {
          // Vaul opens with autoFocus=false: no control is focused. Keep focus in the dialog by
          // focusing the drawer itself, so Tab still reaches its first control.
          if (this.el.hasAttribute("data-vaul-drawer")) return this.el.focus({preventScroll: true});
          const cancel = this.el.querySelector('[data-slot="alert-dialog-cancel"]:not(:disabled)');
          (cancel || this.focusable()[0] || this.el).focus();
        },
        connectAria() {
          if (this.modal()) this.el.setAttribute("aria-modal", "true");
          const title = this.el.querySelector('[data-slot$="-title"]');
          const description = this.el.querySelector('[data-slot$="-description"]');
          if (title && !this.el.hasAttribute("aria-labelledby")) this.el.setAttribute("aria-labelledby", title.id);
          if (description) {
            const ids = new Set((this.el.getAttribute("aria-describedby") || "").split(/\\s+/).filter(Boolean));
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
          // Pointer capture retargets the click to the drawer, so never start a drag on controls,
          // ARIA widgets (div-based options and menu items) or content of popups opened inside it.
          const interactive = 'button, a, input, select, textarea, label, summary, [contenteditable], [data-vaul-no-drag], [tabindex]:not([tabindex="-1"]), [role="button"], [role="link"], [role="checkbox"], [role="radio"], [role="switch"], [role="slider"], [role="tab"], [role="combobox"], [role="option"], [role^="menuitem"], [role="listbox"], [role="menu"]';
          this.onDown = event => {
            const control = event.target.closest(interactive);
            if (!this.top() || !this.dismissible() || event.button !== 0 || (control && this.el.contains(control)) || this.openPopups().some(content => content.contains(event.target))) return;
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
`

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (!families.has(spec.name)) return undefined
  const prefix = spec.name.replaceAll("-", "_")
  const alert = spec.name === "alert-dialog"
  const drawer = spec.name === "drawer"
  const closeButton = spec.name === "dialog" || spec.name === "sheet"
  const sourceClasses = upstreamClasses(spec.name)
  const cls = (suffix: string) => {
    const value = sourceClasses.get(`${spec.name}-${suffix}`)
    if (value === undefined) throw new Error(`Missing upstream classes for ${spec.name}-${suffix}`)
    return literal(value)
  }
  // Every family's close control (and alert-dialog's action/cancel) takes any button variant/size.
  const buttonPairs: ButtonPair[] = buttonVariantNames.flatMap(variant => buttonSizeNames.map(size => [variant, size] as ButtonPair))
  const buttonMap = buttonPairs.map(([variant, size]) =>
    `    {${literal(variant)}, ${literal(size)}} => ${literal(cn(buttonVariants({ variant, size })))}`
  ).join(",\n")
  const global = `  attr :rest, :global, include: ~w(type name value disabled form tabindex)`
  const context = `  attr :context, :map, required: true`
  const simple = (suffix: string, tag = "div", withContext = false) => `
${withContext ? context + "\n  attr :id, :string, default: nil\n" : ""}  attr :class, :any, default: nil
${global}
  slot :inner_block, required: true
  def ${prefix}_${suffix}(assigns) do
    ~H"""
    <${tag}${withContext ? ` id={@id || @context.${suffix}_id}` : ""} data-slot="${spec.name}-${suffix}" class={classes([${cls(suffix)}, @class])} {@rest}>
      {render_slot(@inner_block)}
    </${tag}>
    """
  end
`
  const plainButton = (suffix: string, variant?: string) => `
${context}
  attr :class, :any, default: nil
  attr :type, :string, default: "button"
${variant ? `  attr :variant, :string, default: ${literal(variant)}, values: ~w(${buttonVariantNames.join(" ")})\n  attr :size, :string, default: "default", values: ~w(${buttonSizeNames.join(" ")})\n` : `  attr :variant, :string, default: nil, values: [nil, ${buttonVariantNames.map(literal).join(", ")}],
    doc: "Renders the button with the matching \`button\` variant classes; unstyled when neither variant nor size is set (like Radix Close)."
  attr :size, :string, default: nil, values: [nil, ${buttonSizeNames.map(literal).join(", ")}],
    doc: "Button size; with only a size the variant is \\"default\\"."
`}  attr :on_click, JS, default: %JS{}
${global}
  slot :inner_block, required: true
  def ${prefix}_${suffix}(assigns) do
${variant ? "" : "    assigns = assign(assigns, styled: assigns.variant || assigns.size, variant: assigns.variant || (assigns.size && \"default\"), size: assigns.size || (assigns.variant && \"default\"))\n"}    assigns = assign(assigns, :button_classes, @button_classes)
    ~H"""
    <button type={@type} data-slot="${spec.name}-${suffix}" data-variant={@variant} data-size={@size}
      class={${variant ? "classes([Map.fetch!(@button_classes, {@variant, @size}), @class])" : "if @styled, do: classes([Map.fetch!(@button_classes, {@variant, @size}), @class]), else: @class"}}
      phx-target={@context.target} phx-inherit-target={@context.target in [nil, ""]} phx-click={JS.concat(@on_click, @context.on_close)} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
`
  // Module attributes are compile-time class data, not renderer state.
  const buttons = alert ? plainButton("action", "default") + plainButton("cancel", "outline") : plainButton("close")
  const automaticClose = closeButton ? `
      <button :if={@show_close_button} type="button" data-slot="${spec.name}-close" data-variant="ghost" data-size="icon-sm"
        class={classes([Map.fetch!(@button_classes, {"ghost", "icon-sm"}), "absolute ${spec.name === "sheet" ? "top-3 right-3" : "top-2 right-2"}"])} phx-target={@context.target} phx-inherit-target={@context.target in [nil, ""]} phx-click={@context.on_close}>
        <Icon.icon name="x" /><span class="sr-only">Close</span>
      </button>` : ""
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Controlled ${spec.name} components with explicit, per-instance ID context.

  Pass a stable \`id\`, \`open\` assign and optional \`on_open\`/\`on_close\`
  LiveView JS commands. The defaults push \`shadcn:modal-open\` and
  \`shadcn:modal-close\` with \`%{id: id}\`; the owning LiveView updates
  its open assign. Both named slots receive context with \`:let\`.
  Content, title, description and close controls consume that context.
  The root \`id\` is the content ID; default IDs append \`-trigger\`,
  \`-title\` and \`-description\`. Trigger/title/description IDs can be
  overridden on the root (\`trigger_id\`, ...); \`${prefix}_trigger\` renders the
  root's trigger ID and raises on a different caller \`id\`, so focus return
  follows it. Native action/close buttons accept \`on_click\` JS that
  runs before the root's close command, plus ordinary form attributes.${alert ? "" : `
  \`${prefix}_close\` is unstyled like Radix Close unless given a \`button\`
  \`variant\` and/or \`size\` (e.g. \`variant="outline"\`).`}
  Set phx-target on the wrapperless root (or optional \`target\`) to route
  default open/close commands and hook dismissal to a LiveComponent. Context
  forwards this target to native triggers, overlays, content and close controls.
  Without one, hook dismissal and the native trigger, overlay and close
  controls all use the nearest containing phx-target at event time (for
  example a LiveComponent wrapper with \`phx-target={@myself}\`), else the
  LiveView; caller-supplied JS commands keep their operation order and
  explicitly supplied push targets.

  Closed content is absent, as with Radix portals. Initial SSR intentionally
  omits Radix's effect-installed ARIA links; the colocated hook establishes
  those links, modal focus containment, Escape dismissal and focus restoration
  when LiveView connects.${drawer ? " Like Vaul (autoFocus=false), opening focuses the drawer itself, not its first control. The basic drawer supports directional pointer dragging, a close threshold and dismissible state; it does not expose Vaul snap points or background scaling." : ""}
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]
  alias Phoenix.LiveView.JS
${closeButton ? "  alias ShadcnLiveview.Components.Icon\n" : ""}

${buttonPairs.length ? `  @button_classes %{\n${buttonMap}\n  }\n` : ""}

  attr :id, :string, required: true
  attr :open, :boolean, default: false
${alert ? "" : "  attr :modal, :boolean, default: true\n"}
  attr :dismissible, :boolean, default: true
  attr :title_id, :string, default: nil
  attr :description_id, :string, default: nil
  attr :trigger_id, :string, default: nil
  attr :on_open, JS, default: nil
  attr :on_close, JS, default: nil
  attr :target, :any, default: nil
  attr :rest, :global
${drawer ? `  attr :direction, :string, default: "bottom", values: ~w(top right bottom left)
  attr :draggable, :boolean, default: true
  attr :close_threshold, :float, default: 0.25
` : ""}  slot :trigger
  slot :content, required: true
  @doc "Renders trigger and open content slots, yielding the explicit modal context."
  def ${prefix}(assigns) do
    target = assigns.target || Map.get(assigns.rest, :"phx-target")
    context = %{
      id: assigns.id, open: assigns.open, modal: ${alert ? "true" : "assigns.modal"}, target: target,
      dismissible: assigns.dismissible,
      title_id: assigns.title_id || assigns.id <> "-title",
      description_id: assigns.description_id || assigns.id <> "-description",
      trigger_id: assigns.trigger_id || assigns.id <> "-trigger",
      close_event: if(is_nil(assigns.on_close), do: "shadcn:modal-close"),
      on_open: assigns.on_open || push("shadcn:modal-open", assigns.id, target),
      on_close: assigns.on_close || push("shadcn:modal-close", assigns.id, target)${drawer ? ",\n      direction: assigns.direction, draggable: assigns.draggable, close_threshold: assigns.close_threshold" : ""}
    }
    assigns = assign(assigns, :context, context)
    ~H"""
    {render_slot(@trigger, @context)}
    {render_slot(@content, @context)}
    """
  end

  defp push(event, id, target) when target in [nil, ""], do: JS.push(event, value: %{id: id})
  defp push(event, id, target), do: JS.push(event, value: %{id: id}, target: target)

${context}
  attr :class, :any, default: nil
${global}
  slot :inner_block, required: true
  @doc "A native trigger button; never wrap another button inside this component."
  def ${prefix}_trigger(assigns) do
    assigns = assign(assigns, :rest, ShadcnLiveview.Helpers.trigger_rest!(assigns.rest, assigns.context.trigger_id, "${prefix}_trigger"))
    ~H"""
    <button type="button" id={@context.trigger_id} aria-haspopup="dialog" aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.id} data-state={if @context.open, do: "open", else: "closed"}
      data-slot="${spec.name}-trigger" class={@class} phx-target={@context.target} phx-inherit-target={@context.target in [nil, ""]} phx-click={if @context.open, do: @context.on_close, else: @context.on_open} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

${context}
  attr :class, :any, default: nil
  attr :style, :string, default: nil
${global}
  def ${prefix}_overlay(assigns) do
    ~H"""
    <div :if={@context.open and @context.modal} data-state="open" data-slot="${spec.name}-overlay"
      class={classes([${cls("overlay")}, @class])} style={"pointer-events:auto;" <> (@style || "")}
      phx-target={@context.target} phx-inherit-target={@context.target in [nil, ""]} phx-click={${alert ? "nil" : "if @context.dismissible, do: @context.on_close"}}${drawer ? ' data-vaul-overlay="" data-vaul-snap-points="false" data-vaul-snap-points-overlay="true" data-vaul-animate="true"' : ""} {@rest}></div>
    """
  end

${context}
  attr :class, :any, default: nil
${closeButton ? "  attr :show_close_button, :boolean, default: true\n" : ""}${alert ? '  attr :size, :string, default: "default", values: ~w(default sm)\n' : ""}${spec.name === "sheet" ? '  attr :side, :string, default: "right", values: ~w(top right bottom left)\n' : ""}${global}
  slot :inner_block, required: true
  @doc "Renders the portaled SSR structure only while its context is open."
  def ${prefix}_content(assigns) do
${closeButton ? "    assigns = assign(assigns, :button_classes, @button_classes)\n" : ""}
    ~H"""
    <.${prefix}_overlay context={@context} />
    <div :if={@context.open} role="${alert ? "alertdialog" : "dialog"}" id={@context.id} data-state="open" data-slot="${spec.name}-content"
      ${alert ? 'data-size={@size}' : spec.name === "sheet" ? 'data-side={@side}' : drawer ? 'data-vaul-drawer-direction={@context.direction} data-vaul-drawer="" data-vaul-delayed-snap-points="false" data-vaul-snap-points="false" data-vaul-custom-container="false" data-vaul-animate="true"' : ""}
      class={classes([${cls("content")}, @class])} tabindex="-1" phx-hook=".Modal" phx-target={@context.target}
      phx-value-modal={to_string(@context.modal)} phx-value-dismissible={to_string(@context.dismissible)}
      phx-value-trigger-id={@context.trigger_id} phx-modal-close={@context.on_close} phx-modal-close-event={@context.close_event}${drawer ? ' phx-value-draggable={to_string(@context.draggable)} phx-value-close-threshold={@context.close_threshold}' : ""} {@rest}>
${drawer ? '      <div class="mx-auto mt-4 hidden h-1 w-[100px] shrink-0 rounded-full bg-muted group-data-[vaul-drawer-direction=bottom]/drawer-content:block" />\n' : ""}      {render_slot(@inner_block)}${automaticClose}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Modal">${modalHook}    </script>
    """
  end
${simple("header")}${spec.name === "dialog" ? `
  attr :class, :any, default: nil
  attr :show_close_button, :boolean, default: false
  attr :context, :map, default: nil
${global}
  slot :inner_block, required: true
  def dialog_footer(assigns) do
    assigns = assign(assigns, :button_classes, @button_classes)
    ~H"""
    <div data-slot="dialog-footer" class={classes([${cls("footer")}, @class])} {@rest}>
      {render_slot(@inner_block)}
      <button :if={@show_close_button} type="button" data-slot="button" data-variant="outline" data-size="default"
        class={Map.fetch!(@button_classes, {"outline", "default"})} phx-target={@context.target} phx-inherit-target={@context.target in [nil, ""]} phx-click={@context.on_close}>Close</button>
    </div>
    """
  end
` : simple("footer")}${alert ? simple("media") : ""}${simple("title", "h2", true)}${simple("description", "p", true)}${buttons}
  @doc "An explicit portal slot, useful when composing overlay and content manually."
  slot :inner_block, required: true
  def ${prefix}_portal(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end
end
`
}
