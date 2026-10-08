import type { ComponentSpec } from "../generate"
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
const modalHook = `
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
  const buttonPairs: ButtonPair[] = alert
    ? buttonVariantNames.flatMap(variant => buttonSizeNames.map(size => [variant, size] as ButtonPair))
    : closeButton ? [["ghost", "icon-sm"], ...(spec.name === "dialog" ? [["outline", "default"] as ButtonPair] : [])] : []
  const buttonMap = buttonPairs.map(([variant, size]) =>
    `    {${literal(variant)}, ${literal(size)}} => ${literal(cn(buttonVariants({ variant, size })))}`
  ).join(",\n")
  const global = `  attr :rest, :global, include: ~w(type name value disabled form tabindex)`
  const context = `  attr :context, :map, required: true`
  const simple = (suffix: string, tag = "div", withContext = false) => `
${withContext ? context + "\n  attr :id, :string, default: nil\n" : ""}  attr :class, :string, default: nil
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
  attr :class, :string, default: nil
  attr :type, :string, default: "button"
${variant ? `  attr :variant, :string, default: ${literal(variant)}, values: ~w(${buttonVariantNames.join(" ")})\n  attr :size, :string, default: "default", values: ~w(${buttonSizeNames.join(" ")})\n` : ""}  attr :on_click, JS, default: %JS{}
${global}
  slot :inner_block, required: true
  def ${prefix}_${suffix}(assigns) do
    ~H"""
    <button type={@type} data-slot="${spec.name}-${suffix}"${variant ? " data-variant={@variant} data-size={@size}" : ""}
      class={${variant ? "classes([Map.fetch!(@button_classes, {@variant, @size}), @class])" : "@class"}}
      phx-click={JS.concat(@on_click, @context.on_close)} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end
`
  // Module attributes are compile-time class data, not renderer state.
  const variantButtons = alert ? plainButton("action", "default") + plainButton("cancel", "outline") : plainButton("close")
  const automaticClose = closeButton ? `
      <button :if={@show_close_button} type="button" data-slot="${spec.name}-close" data-variant="ghost" data-size="icon-sm"
        class={classes([Map.fetch!(@button_classes, {"ghost", "icon-sm"}), "absolute ${spec.name === "sheet" ? "top-3 right-3" : "top-2 right-2"}"])} phx-click={@context.on_close}>
        <Icon.icon name="x" /><span class="sr-only">Close</span>
      </button>` : ""
  // Use an assign for the compiled map in each function that needs it.
  const buttons = alert ? variantButtons.replaceAll('    ~H"""', '    assigns = assign(assigns, :button_classes, @button_classes)\n    ~H"""') : variantButtons
  return `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  Controlled ${spec.name} components with explicit, per-instance ID context.

  Pass a stable \`id\`, \`open\` assign and optional \`on_open\`/\`on_close\`
  LiveView JS commands. The defaults push \`shadcn:modal-open\` and
  \`shadcn:modal-close\` with \`%{id: id}\`; the owning LiveView updates
  its open assign. Both named slots receive context with \`:let\`.
  Content, title, description and close controls consume that context.
  The root \`id\` is the content ID; default IDs append \`-trigger\`,
  \`-title\` and \`-description\`. Title/description IDs can be overridden
  on the root. Native action/close buttons accept \`on_click\` JS that
  runs before the root's close command, plus ordinary form attributes.

  Closed content is absent, as with Radix portals. Initial SSR intentionally
  omits Radix's effect-installed ARIA links; the colocated hook establishes
  those links, modal focus containment, Escape dismissal and focus restoration
  when LiveView connects.${drawer ? " The basic drawer supports directional pointer dragging, a close threshold and dismissible state; it does not expose Vaul snap points or background scaling." : ""}
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
${drawer ? `  attr :direction, :string, default: "bottom", values: ~w(top right bottom left)
  attr :draggable, :boolean, default: true
  attr :close_threshold, :float, default: 0.25
` : ""}  slot :trigger
  slot :content, required: true
  @doc "Renders trigger and open content slots, yielding the explicit modal context."
  def ${prefix}(assigns) do
    context = %{
      id: assigns.id, open: assigns.open, modal: ${alert ? "true" : "assigns.modal"},
      dismissible: assigns.dismissible,
      title_id: assigns.title_id || assigns.id <> "-title",
      description_id: assigns.description_id || assigns.id <> "-description",
      trigger_id: assigns.trigger_id || assigns.id <> "-trigger",
      on_open: assigns.on_open || JS.push("shadcn:modal-open", value: %{id: assigns.id}),
      on_close: ${drawer ? 'if(assigns.dismissible, do: assigns.on_close || JS.push("shadcn:modal-close", value: %{id: assigns.id}), else: %JS{})' : 'assigns.on_close || JS.push("shadcn:modal-close", value: %{id: assigns.id})'}${drawer ? ",\n      direction: assigns.direction, draggable: assigns.draggable, close_threshold: assigns.close_threshold" : ""}
    }
    assigns = assign(assigns, :context, context)
    ~H"""
    {render_slot(@trigger, @context)}
    {render_slot(@content, @context)}
    """
  end

${context}
  attr :class, :string, default: nil
${global}
  slot :inner_block, required: true
  @doc "A native trigger button; never wrap another button inside this component."
  def ${prefix}_trigger(assigns) do
    ~H"""
    <button type="button" id={@context.trigger_id} aria-haspopup="dialog" aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.id} data-state={if @context.open, do: "open", else: "closed"}
      data-slot="${spec.name}-trigger" class={@class} phx-click={if @context.open, do: @context.on_close, else: @context.on_open} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

${context}
  attr :class, :string, default: nil
  attr :style, :string, default: nil
${global}
  def ${prefix}_overlay(assigns) do
    ~H"""
    <div :if={@context.open and @context.modal} data-state="open" data-slot="${spec.name}-overlay"
      class={classes([${cls("overlay")}, @class])} style={"pointer-events:auto;" <> (@style || "")}
      phx-click={${alert ? "nil" : "if @context.dismissible, do: @context.on_close"}}${drawer ? ' data-vaul-overlay="" data-vaul-snap-points="false" data-vaul-snap-points-overlay="true" data-vaul-animate="true"' : ""} {@rest}></div>
    """
  end

${context}
  attr :class, :string, default: nil
${closeButton ? "  attr :show_close_button, :boolean, default: true\n" : ""}${alert ? '  attr :size, :string, default: "default", values: ~w(default sm)\n' : ""}${spec.name === "sheet" ? '  attr :side, :string, default: "right", values: ~w(top right bottom left)\n' : ""}${global}
  slot :inner_block, required: true
  @doc "Renders the portaled SSR structure only while its context is open."
  def ${prefix}_content(assigns) do
${closeButton ? "    assigns = assign(assigns, :button_classes, @button_classes)\n" : ""}
    ~H"""
    <.${prefix}_overlay context={@context} />
    <div :if={@context.open} role="${alert ? "alertdialog" : "dialog"}" id={@context.id} data-state="open" data-slot="${spec.name}-content"
      ${alert ? 'data-size={@size}' : spec.name === "sheet" ? 'data-side={@side}' : drawer ? 'data-vaul-drawer-direction={@context.direction} data-vaul-drawer="" data-vaul-delayed-snap-points="false" data-vaul-snap-points="false" data-vaul-custom-container="false" data-vaul-animate="true"' : ""}
      class={classes([${cls("content")}, @class])} tabindex="-1" phx-hook=".Modal"
      phx-value-modal={to_string(@context.modal)} phx-value-dismissible={to_string(@context.dismissible)}
      phx-value-trigger-id={@context.trigger_id} phx-modal-close={@context.on_close}${drawer ? ' phx-value-draggable={to_string(@context.draggable)} phx-value-close-threshold={@context.close_threshold}' : ""} {@rest}>
${drawer ? '      <div class="mx-auto mt-4 hidden h-1 w-[100px] shrink-0 rounded-full bg-muted group-data-[vaul-drawer-direction=bottom]/drawer-content:block" />\n' : ""}      {render_slot(@inner_block)}${automaticClose}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Modal">${modalHook}    </script>
    """
  end
${simple("header")}${spec.name === "dialog" ? `
  attr :class, :string, default: nil
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
        class={Map.fetch!(@button_classes, {"outline", "default"})} phx-click={@context.on_close}>Close</button>
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
