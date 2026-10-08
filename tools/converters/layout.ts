import type { ComponentSpec } from "../generate"
import { cn } from "cn"
import { buttonVariants } from "../../vendor/shadcn/ui/button"

const header = (spec: ComponentSpec, docs: string) => `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  ${docs}
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
`
const globals = `  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)
  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."`

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name === "carousel") return carousel(spec)
  if (spec.name === "resizable") return resizable(spec)
  if (spec.name === "sidebar") return sidebar(spec)
  return undefined
}

function carousel(spec: ComponentSpec): string {
  return header(spec, `Composable carousel with an explicit caller ID. Bind the root's slot context with
  \`:let={carousel}\` and pass \`carousel={carousel}\` to content, items and controls.
  Orientation, loop and start_index configure the native scrolling hook. Controls
  are disabled during SSR, like upstream Embla, and synchronize after mounting.
  Items retain their caller-specified basis classes; scrolling supports pointer,
  touch, keyboard, responsive resizing and independently scoped instances.
  Keyboard focus survives server acknowledgements and disabling an end control;
  the region remains keyboard reachable without changing upstream SSR markup.`) + `
  @control_classes %{
${["default", "outline", "secondary", "ghost", "destructive", "link"].flatMap(variant => ["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"].map(size => `    {"${variant}", "${size}"} => ${JSON.stringify(cn(buttonVariants({variant: variant as "outline", size: size as "icon-sm"}), "absolute touch-manipulation rounded-full"))}`)).join(",\n")}
  }

  attr :id, :string, required: true
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :loop, :boolean, default: false
  attr :start_index, :integer, default: 0
${globals}

  def carousel(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, orientation: assigns.orientation})
    ~H"""
    <div id={@id} data-slot="carousel" role="region" aria-roledescription="carousel"
      class={classes(["relative", @class])} phx-hook=".Carousel"
      phx-value-orientation={@orientation} phx-value-loop={to_string(@loop)} phx-value-start-index={@start_index} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Carousel">
      export default {
        mounted() {
          this.abort = new AbortController();
          const on = (target, name, callback, options = {}) => target.addEventListener(name, callback, {...options, signal: this.abort.signal});
          this.index = Number(this.el.getAttribute("phx-value-start-index") || 0); this.serverIndex = this.index;
          on(this.el, "click", event => {
            const button = event.target.closest('[data-slot="carousel-previous"], [data-slot="carousel-next"]');
            if (!button || button.closest('[data-slot="carousel"]') !== this.el) return;
            this.move(button.getAttribute("data-slot") === "carousel-next" ? 1 : -1);
          });
          on(this.el, "keydown", event => {
            if (event.target.closest('input,textarea,select,[contenteditable=true]')) return;
            const vertical = this.vertical();
            const delta = event.key === "ArrowLeft" || (vertical && event.key === "ArrowUp") ? -1 : event.key === "ArrowRight" || (vertical && event.key === "ArrowDown") ? 1 : 0;
            if (delta) { event.preventDefault(); this.move(delta); }
          });
          on(this.el, "pointerdown", event => {
            if (!this.viewport || !this.viewport.contains(event.target) || event.button !== 0 || event.target.closest('button,a,input,textarea,select')) return;
            this.drag = {id: event.pointerId, point: this.vertical() ? event.clientY : event.clientX, offset: this.position()};
            this.viewport.setPointerCapture(event.pointerId);
          });
          on(this.el, "pointermove", event => {
            if (!this.drag || this.drag.id !== event.pointerId) return;
            const distance = this.drag.point - (this.vertical() ? event.clientY : event.clientX);
            if (Math.abs(distance) > 4) { event.preventDefault(); this.scroll(this.drag.offset + distance, "instant"); }
          });
          const end = () => { if (!this.drag) return; const focused = this.el.contains(document.activeElement) ? document.activeElement : null; this.drag = null; this.index = this.nearest(); this.go("smooth"); this.pushEvent("shadcn:carousel-change", {id: this.el.id, value: this.index}, () => this.restoreFocus(focused)); };
          on(this.el, "pointerup", end); on(this.el, "pointercancel", end);
          this.observer = new ResizeObserver(() => { this.measure(); this.go("instant"); });
          this.configure();
        },
        vertical() { return this.el.getAttribute("phx-value-orientation") === "vertical"; },
        position() { return this.vertical() ? this.viewport.scrollTop : this.viewport.scrollLeft; },
        scroll(position, behavior) { this.viewport.scrollTo(this.vertical() ? {top: position, behavior} : {left: position, behavior}); },
        configure() {
          if (!this.el.hasAttribute("tabindex")) this.el.tabIndex = 0;
          this.observer.disconnect();
          this.viewport = [...this.el.querySelectorAll('[data-slot="carousel-content"]')].find(node => node.closest('[data-slot="carousel"]') === this.el);
          if (!this.viewport) return;
          this.track = this.viewport.firstElementChild;
          this.viewport.style.touchAction = this.vertical() ? "pan-x" : "pan-y";
          this.observer.observe(this.viewport); this.observer.observe(this.track);
          this.measure(); this.go("instant");
        },
        measure() {
          if (!this.viewport) return;
          const items = [...this.track.children].filter(node => node.getAttribute("data-slot") === "carousel-item");
          const max = Math.max(0, this.vertical() ? this.viewport.scrollHeight - this.viewport.clientHeight : this.viewport.scrollWidth - this.viewport.clientWidth);
          const origin = items.length ? (this.vertical() ? items[0].offsetTop : items[0].offsetLeft) : 0;
          this.positions = [...new Set(items.map(node => Math.min(max, Math.max(0, (this.vertical() ? node.offsetTop : node.offsetLeft) - origin))))];
          if (!this.positions.length) this.positions = [0];
          this.index = Math.max(0, Math.min(this.index, this.positions.length - 1));
        },
        nearest() { return this.positions.reduce((best, position, index) => Math.abs(position - this.position()) < Math.abs(this.positions[best] - this.position()) ? index : best, 0); },
        move(delta) {
          if (!this.viewport) return;
          const focused = this.el.contains(document.activeElement) ? document.activeElement : null;
          const count = this.positions.length;
          const loop = this.el.getAttribute("phx-value-loop") === "true";
          this.index = loop ? (this.index + delta + count) % count : Math.max(0, Math.min(count - 1, this.index + delta));
          this.go("smooth");
          this.pushEvent("shadcn:carousel-change", {id: this.el.id, value: this.index}, () => this.restoreFocus(focused));
        },
        go(behavior) {
          if (!this.viewport) return;
          this.scroll(this.positions[this.index] || 0, behavior);
          const loop = this.el.getAttribute("phx-value-loop") === "true" && this.positions.length > 1;
          this.el.querySelectorAll('[data-slot="carousel-previous"], [data-slot="carousel-next"]').forEach(button => {
            if (button.closest('[data-slot="carousel"]') !== this.el) return;
            const focused = document.activeElement === button;
            button.disabled = button.getAttribute("phx-value-disabled") === "true" || (!loop && (button.getAttribute("data-slot") === "carousel-previous" ? this.index === 0 : this.index === this.positions.length - 1));
            if (focused && button.disabled) this.el.focus();
          });
          this.el.dispatchEvent(new CustomEvent("carousel:select", {detail: {index: this.index}, bubbles: true}));
        },
        restoreFocus(focused) {
          if (!focused || document.activeElement !== document.body) return;
          const slot = focused.getAttribute("data-slot");
          const replacement = slot && this.el.querySelector('[data-slot="' + slot + '"]');
          const target = focused.isConnected && !focused.disabled ? focused : replacement && !replacement.disabled ? replacement : this.el;
          target.focus();
        },
        updated() { const index = Number(this.el.getAttribute("phx-value-start-index") || 0); if (index !== this.serverIndex) {this.index = index;this.serverIndex = index;} this.configure(); },
        destroyed() { this.abort.abort(); this.observer.disconnect(); }
      }
    </script>
    """
  end

  attr :carousel, :map, required: true
${globals}
  def carousel_content(assigns) do
    ~H"""
    <div class="overflow-hidden" data-slot="carousel-content">
      <div class={classes(["flex", if(@carousel.orientation == "horizontal", do: "-ml-4", else: "-mt-4 flex-col"), @class])} {@rest}>
        {render_slot(@inner_block, @carousel)}
      </div>
    </div>
    """
  end

  attr :carousel, :map, required: true
${globals}
  def carousel_item(assigns) do
    basis = if Enum.any?(String.split(assigns.class || ""), &String.starts_with?(&1, "basis-")), do: nil, else: "basis-full"
    assigns = assign(assigns, :basis, basis)
    ~H"""
    <div role="group" aria-roledescription="slide" data-slot="carousel-item"
      class={classes(["min-w-0 shrink-0 grow-0", @basis, if(@carousel.orientation == "horizontal", do: "pl-4", else: "pt-4"), @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

${["previous", "next"].map(direction => `  attr :carousel, :map, required: true
  attr :variant, :string, default: "outline", values: ~w(default outline secondary ghost destructive link)
  attr :size, :string, default: "icon-sm", values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)
  attr :disabled, :boolean, default: nil
${globals}
  def carousel_${direction}(assigns) do
    ~H"""
    <button data-slot="carousel-${direction}" data-variant={@variant} data-size={@size}
      class={classes([control_classes(@variant, @size), if(@carousel.orientation == "horizontal", do: "inset-y-0 -${direction === "previous" ? "left" : "right"}-12 my-auto", else: "-${direction === "previous" ? "top" : "bottom"}-12 left-1/2 -translate-x-1/2 rotate-90"), @class])}
      disabled={if is_nil(@disabled), do: true, else: @disabled} phx-value-disabled={to_string(@disabled)} {@rest}>
      <ShadcnLiveview.Components.Icon.icon name="chevron-${direction === "previous" ? "left" : "right"}" class="cn-rtl-flip" />
      <span class="sr-only">${direction === "previous" ? "Previous" : "Next"} slide</span>
    </button>
    """
  end`).join("\n\n")}

  defp control_classes(variant, size), do: Map.fetch!(@control_classes, {variant, size})
end
`
}

function resizable(spec: ComponentSpec): string {
  const groupClass = spec.functions.find(fn => fn.name === "resizable_panel_group")!.baseClasses
  const handleClass = spec.functions.find(fn => fn.name === "resizable_handle")!.baseClasses
  return header(spec, `Resizable panels using the current react-resizable-panels sizing convention:
  numeric sizes are pixels; strings accept CSS lengths and percentages. Require
  stable IDs for the group, every panel and every handle. Bind the group with
  \`:let={group}\` and pass \`group={group}\` to its direct children. The hook
  installs separator ARIA relationships after layout, supports pointer capture,
  arrow/Home/End keyboard resizing, min/max constraints and collapsible panels.
  Listen for \`resizable:change\` to persist the percentage layout in LiveView.`) + `
  attr :id, :string, required: true
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :disabled, :boolean, default: false
${globals}
  def resizable_panel_group(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, orientation: assigns.orientation, disabled: assigns.disabled})
    ~H"""
    <div id={@id} data-slot="resizable-panel-group" data-group="true" data-testid={@id}
      class={classes([${JSON.stringify(groupClass)}, @class])}
      style={"height:100%;width:100%;overflow:hidden;display:flex;flex-direction:" <> if(@orientation == "horizontal", do: "row", else: "column") <> ";flex-wrap:nowrap;touch-action:" <> if(@orientation == "horizontal", do: "pan-y", else: "pan-x")}
      phx-hook=".Resizable" phx-value-orientation={@orientation} phx-value-disabled={to_string(@disabled)} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Resizable">
      export default {
        mounted() {
          this.abort = new AbortController();
          const on = (name, callback) => this.el.addEventListener(name, callback, {signal: this.abort.signal});
          on("pointerdown", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (event.button !== 0 || !this.usable(handle)) return;
            event.preventDefault(); handle.setPointerCapture(event.pointerId);
            this.drag = {handle, id: event.pointerId, start: this.point(event), sizes: this.sizes()};
            handle.dataset.separator = "active";
          });
          on("pointermove", event => { if (this.drag && this.drag.id === event.pointerId) this.resize(this.drag.handle, this.drag.sizes, (this.point(event) - this.drag.start) / this.length() * 100); });
          const end = event => {
            if (!this.drag || this.drag.id !== event.pointerId) return;
            this.drag.handle.dataset.separator = "inactive"; this.drag = null; this.emit();
          };
          on("pointerup", end); on("pointercancel", end); on("lostpointercapture", end);
          on("keydown", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (!this.usable(handle)) return;
            const keys = this.vertical() ? ["ArrowUp", "ArrowDown"] : ["ArrowLeft", "ArrowRight"];
            let delta = event.key === keys[0] ? -1 : event.key === keys[1] ? 1 : 0;
            if (event.key === "Home") delta = -100;
            if (event.key === "End") delta = 100;
            if (!delta) return;
            event.preventDefault(); this.resize(handle, this.sizes(), delta * (event.shiftKey && Math.abs(delta) === 1 ? 10 : 1)); this.emit();
          });
          this.observer = new ResizeObserver(() => this.aria()); this.observer.observe(this.el); this.configure();
        },
        vertical() { return this.el.getAttribute("phx-value-orientation") === "vertical"; },
        point(event) { return this.vertical() ? event.clientY : event.clientX; },
        length() { return this.vertical() ? this.el.clientHeight : this.el.clientWidth; },
        panels() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-panel"); },
        handles() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-handle"); },
        sizes() { const sizes = this.panels().map(node => this.vertical() ? node.getBoundingClientRect().height : node.getBoundingClientRect().width); const total = sizes.reduce((a,b) => a+b, 0); return sizes.map(size => total ? size / total * 100 : 100 / sizes.length); },
        bound(panel, name, fallback) {
          const value = panel.getAttribute("phx-value-" + name);
          if (!value) return fallback;
          if (value.endsWith("%")) return parseFloat(value);
          let pixels;
          if (/^[\\d.]+(?:px)?$/.test(value)) pixels = parseFloat(value);
          else {
            const probe = document.createElement("div"); probe.style.position = "absolute"; probe.style.visibility = "hidden"; probe.style[this.vertical() ? "height" : "width"] = value;
            this.el.append(probe); pixels = this.vertical() ? probe.getBoundingClientRect().height : probe.getBoundingClientRect().width; probe.remove();
          }
          return this.length() ? pixels / this.length() * 100 : fallback;
        },
        pair(handle) {
          const panels = this.panels(); return [panels.indexOf(handle.previousElementSibling), panels.indexOf(handle.nextElementSibling)];
        },
        usable(handle) {
          if (!handle || handle.parentElement !== this.el || handle.getAttribute("aria-disabled") === "true" || this.el.getAttribute("phx-value-disabled") === "true") return false;
          const [left,right] = this.pair(handle); const panels = this.panels();
          return left >= 0 && right >= 0 && ![panels[left],panels[right]].some(panel => panel.dataset.disabled === "true");
        },
        resize(handle, sizes, delta) {
          const [a,b] = this.pair(handle); const panels = this.panels(); const total = sizes[a] + sizes[b];
          const minA = this.bound(panels[a], "min-size", 0), minB = this.bound(panels[b], "min-size", 0);
          const maxA = this.bound(panels[a], "max-size", 100), maxB = this.bound(panels[b], "max-size", 100);
          const collapsedA = panels[a].getAttribute("phx-value-collapsible") === "true" ? this.bound(panels[a], "collapsed-size", 0) : minA;
          const collapsedB = panels[b].getAttribute("phx-value-collapsible") === "true" ? this.bound(panels[b], "collapsed-size", 0) : minB;
          const low = Math.max(collapsedA, total - maxB), high = Math.min(maxA, total - collapsedB);
          if (low > high) return;
          let value = Math.max(low, Math.min(high, sizes[a] + delta));
          if (value < minA) value = value < (minA + collapsedA) / 2 ? collapsedA : minA;
          if (total - value < minB) value = total - (total - value < (minB + collapsedB) / 2 ? collapsedB : minB);
          value = Math.max(low, Math.min(high, value));
          const next = [...sizes]; next[a] = value; next[b] = total - value;
          panels.forEach((panel,index) => { panel.style.flexBasis = "0px"; panel.style.flexGrow = next[index]; panel.style.flexShrink = "1"; }); this.aria();
        },
        configure() {
          const panels = this.panels(), values = this.sizes();
          const signature = panels.map(panel => [panel.id,...["default-size","min-size","max-size","collapsible","collapsed-size"].map(name => panel.getAttribute("phx-value-"+name))].join(":")).join("|");
          if (signature === this.layoutSignature) {this.aria();return;} this.layoutSignature = signature;
          const defaults = panels.map(panel => panel.getAttribute("phx-value-default-size") ? this.bound(panel, "default-size", 0) : null);
          const specified = defaults.reduce((sum,value) => sum + (value || 0), 0), missing = defaults.filter(value => value === null).length;
          if (defaults.some(value => value !== null)) {
            const requested = defaults.map(value => value === null ? Math.max(0,100-specified) / missing : value);
            const sum = requested.reduce((total,value) => total + value,0);
            if (sum) requested.forEach((value,index) => {values[index] = value / sum * 100;});
          }
          const bounds = panels.map(panel => [this.bound(panel, "min-size", 0), this.bound(panel, "max-size", 100)]);
          panels.forEach((panel,index) => { values[index] = Math.max(bounds[index][0], Math.min(bounds[index][1], values[index])); });
          for (let pass = 0; pass < panels.length; pass++) {
            const difference = 100 - values.reduce((sum,value) => sum + value, 0);
            if (Math.abs(difference) < .001) break;
            const adjustable = values.map((value,index) => index).filter(index => difference > 0 ? values[index] < bounds[index][1] : values[index] > bounds[index][0]);
            if (!adjustable.length) break;
            adjustable.forEach(index => {values[index] = Math.max(bounds[index][0], Math.min(bounds[index][1], values[index] + difference / adjustable.length));});
          }
          panels.forEach((panel,index) => {panel.style.flexBasis="0px";panel.style.flexGrow=values[index];panel.style.flexShrink="1";}); this.aria();
        },
        aria() {
          if (!this.length()) return;
          const panels = this.panels(), sizes = this.sizes();
          this.handles().forEach(handle => {
            const [a,b] = this.pair(handle); if (a < 0 || b < 0) return;
            handle.setAttribute("aria-controls", panels[a].id);
            handle.setAttribute("aria-valuemin", String(Math.round(this.bound(panels[a], "min-size", 0))));
            handle.setAttribute("aria-valuemax", String(Math.round(this.bound(panels[a], "max-size", 100))));
            handle.setAttribute("aria-valuenow", String(Math.round(sizes[a])));
          });
        },
        emit() {
          const sizes = this.sizes(), value = Object.fromEntries(this.panels().map((panel,index) => [panel.id, sizes[index]]));
          this.el.dispatchEvent(new CustomEvent("resizable:change", {detail:value,bubbles:true}));
          this.pushEvent("shadcn:resizable-change", {id:this.el.id,value});
        },
        updated() { this.configure(); },
        destroyed() { this.abort.abort(); this.observer.disconnect(); this.drag = null; }
      }
    </script>
    """
  end

  attr :id, :string, required: true
  attr :group, :map, required: true
  attr :default_size, :any, default: nil
  attr :min_size, :any, default: nil
  attr :max_size, :any, default: nil
  attr :collapsed_size, :any, default: 0
  attr :collapsible, :boolean, default: false
  attr :disabled, :boolean, default: false
${globals}
  def resizable_panel(assigns) do
    ~H"""
    <div id={@id} data-slot="resizable-panel" data-panel="true" data-testid={@id} data-disabled={if @disabled, do: "true"}
      class={@class} style={panel_style(@default_size)} phx-value-default-size={size_value(@default_size)} phx-value-min-size={size_value(@min_size)} phx-value-max-size={size_value(@max_size)}
      phx-value-collapsible={to_string(@collapsible)} phx-value-collapsed-size={size_value(@collapsed_size)} {@rest}>
      <div style={"max-height:100%;max-width:100%;flex-grow:1;overflow:auto;touch-action:" <> if(@group.orientation == "horizontal", do: "pan-y", else: "pan-x")}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :group, :map, required: true
  attr :with_handle, :boolean, default: false
  attr :disabled, :boolean, default: false
${globals}
  def resizable_handle(assigns) do
    assigns = assign(assigns, :disabled, assigns.disabled or assigns.group.disabled)
    ~H"""
    <div id={@id} data-slot="resizable-handle" data-testid={@id} data-separator={if @disabled, do: "disabled", else: "inactive"}
      role="separator" aria-disabled={if @disabled, do: "true"} aria-orientation={if @group.orientation == "horizontal", do: "vertical", else: "horizontal"}
      tabindex={if !@disabled, do: "0"} class={classes([${JSON.stringify(handleClass)}, @class])}
      style={"flex-basis:auto;" <> if(@disabled, do: "cursor:not-allowed;", else: "") <> "flex-grow:0;flex-shrink:0;touch-action:none"} {@rest}>
      <div :if={@with_handle} class="z-10 flex h-6 w-1 shrink-0 rounded-lg bg-border"></div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp size_value(nil), do: nil
  defp size_value(value) when is_number(value), do: to_string(value) <> "px"
  defp size_value(value), do: to_string(value)
  defp panel_style(size) do
    "min-height:0;max-height:100%;height:auto;min-width:0;max-width:100%;width:auto;border:none;border-width:0;padding:0;margin:0;display:flex;" <>
      if(is_nil(size), do: "flex-basis:0;flex-shrink:1;overflow:visible;flex-grow:1", else: "flex-basis:" <> size_value(size) <> ";overflow:visible")
  end
end
`
}

function sidebar(spec: ComponentSpec): string {
  const base = (name: string) => JSON.stringify(spec.functions.find(fn => fn.name === name)!.baseClasses)
  const ordinary: Record<string, string> = {
    sidebar_header: "div", sidebar_footer: "div", sidebar_content: "div", sidebar_group: "div", sidebar_group_label: "div",
    sidebar_group_action: "button", sidebar_group_content: "div", sidebar_menu: "ul", sidebar_menu_item: "li",
    sidebar_menu_badge: "div", sidebar_menu_sub: "ul", sidebar_menu_sub_item: "li", sidebar_inset: "main",
  }
  return header(spec, `Sidebar provider exposes its state through \`:let={sidebar}\`; pass that context
  to the sidebar and its trigger/rail. Require unique IDs on providers and sidebar
  containers. \`open\` and \`mobile_open\` are caller-owned server state. The hook
  emits \`shadcn:sidebar-change\` with the provider ID for desktop and its ID plus
  \`-mobile\` for the drawer, and handles scoped Ctrl/Meta+B, cookies and focus.
  Upstream always renders desktop markup during SSR because its media-query hook
  initializes false; mobile behavior is installed only after mounting. The same
  children become the mobile dialog without hidden duplicate content or IDs.
  Nested primitives accept caller classes and global attributes. Use \`tag=\"a\"\`
  on menu/group buttons for link composition instead of a React asChild wrapper.`) + `
  attr :id, :string, required: true
  attr :open, :boolean, default: true
  attr :mobile_open, :boolean, default: false
  attr :width, :string, default: "16rem"
  attr :icon_width, :string, default: "3rem"
  attr :style, :string, default: nil
${globals}
  def sidebar_provider(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, open: assigns.open})
    ~H"""
    <div id={@id} data-slot="sidebar-wrapper" class={classes(["group/sidebar-wrapper flex min-h-svh w-full has-data-[variant=inset]:bg-sidebar", @class])}
      style={"--sidebar-width:" <> @width <> ";--sidebar-width-icon:" <> @icon_width <> if(@style, do: ";" <> @style, else: "")}
      phx-hook=".Sidebar" phx-value-open={to_string(@open)} phx-value-mobile-open={to_string(@mobile_open)} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Sidebar">
      export default {
        mounted() {
          this.abort = new AbortController(); this.open = this.el.getAttribute("phx-value-open") === "true"; this.serverOpen = this.open;
          this.serverMobileOpen = this.el.getAttribute("phx-value-mobile-open") === "true"; this.mobileOpen = this.serverMobileOpen;
          this.original = new WeakMap();
          this.media = matchMedia("(max-width: 767px)");
          this.mobileOpen = this.mobileOpen && this.media.matches;
          const on = (target,name,fn) => target.addEventListener(name,fn,{signal:this.abort.signal});
          on(this.el,"click",event => {
            const trigger = event.target.closest('[data-sidebar="trigger"],[data-sidebar="rail"]');
            if (trigger && trigger.closest('[data-slot="sidebar-wrapper"]') === this.el) this.toggle(trigger);
          });
          on(document,"sidebar:mobile-open",event => {if(event.detail.id!==this.el.id) this.closeMobile();});
          on(document,"keydown",event => {
            if (event.key.toLowerCase() === "b" && (event.ctrlKey || event.metaKey)) {
              const owner = document.activeElement?.closest('[data-slot="sidebar-wrapper"]') || document.querySelector('[data-slot="sidebar-wrapper"]');
              if (owner === this.el) { event.preventDefault(); this.toggle(document.activeElement); }
            }
            if (!this.mobileOpen) return;
            if (event.key === "Escape") { event.preventDefault(); this.closeMobile(); }
            if (event.key === "Tab") {
              const container = this.containers()[0]; if (!container) return;
              const targets = [...container.querySelectorAll('button:not(:disabled),a[href],input:not(:disabled),select:not(:disabled),textarea:not(:disabled),[tabindex="0"]')].filter(node => node.getClientRects().length);
              const first = targets[0] || container, last = targets[targets.length-1] || container;
              if (event.shiftKey && (document.activeElement === first || document.activeElement === container)) { event.preventDefault(); last.focus(); }
              else if (!event.shiftKey && (document.activeElement === last || !container.contains(document.activeElement))) { event.preventDefault(); first.focus(); }
            }
          });
          on(this.media,"change",() => { this.closeMobile(); this.paint(); });
          this.paint();
        },
        roots() { return [...this.el.querySelectorAll('[data-slot="sidebar"]')].filter(node => node.closest('[data-slot="sidebar-wrapper"]') === this.el && node.hasAttribute("data-collapsible")); },
        containers() { return this.roots().map(root => root.querySelector('[data-slot="sidebar-container"]')); },
        closeMobile() {
          if (!this.mobileOpen) return;
          this.mobileOpen = false; this.pushEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:false}); this.paint();
        },
        toggle(trigger) {
          if (this.media.matches) {
            this.returnFocus = trigger; this.mobileOpen = !this.mobileOpen;
            if(this.mobileOpen) document.dispatchEvent(new CustomEvent("sidebar:mobile-open",{detail:{id:this.el.id}}));
            this.pushEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:this.mobileOpen});
          } else {
            this.open = !this.open; document.cookie = "sidebar_state=" + this.open + "; path=/; max-age=604800";
            this.pushEvent("shadcn:sidebar-change", {id:this.el.id,open:this.open});
          }
          this.paint(); this.el.dispatchEvent(new CustomEvent("sidebar:change", {detail:{open:this.open, mobileOpen:this.mobileOpen},bubbles:true}));
        },
        paint() {
          const mobile = this.media.matches;
          this.roots().forEach(root => {
            const container = root.querySelector('[data-slot="sidebar-container"]');
            const mode = root.getAttribute("phx-value-collapsible") || "offcanvas";
            root.dataset.state = mobile || this.open ? "expanded" : "collapsed"; root.dataset.collapsible = mobile || this.open ? "" : mode;
            if (!container) return;
            if (!this.original.has(container)) this.original.set(container,Object.fromEntries(["role","aria-modal","aria-label","tabindex","data-mobile","style"].map(name => [name,container.getAttribute(name)])));
            if (mobile) {
              root.style.display = this.mobileOpen ? "block" : "none";
              root.querySelector('[data-slot="sidebar-gap"]').style.display = "none";
              container.style.cssText = (this.original.get(container).style || "") + ";display:flex;position:fixed;top:0;bottom:0;width:18rem;max-width:calc(100vw - 2rem);z-index:51;" + (root.dataset.side === "right" ? "right:0;left:auto;" : "left:0;right:auto;");
              container.setAttribute("role","dialog"); container.setAttribute("aria-modal","true"); container.setAttribute("aria-label","Sidebar"); container.setAttribute("tabindex","-1"); container.dataset.mobile = "true";
              container.style.setProperty("--sidebar-width", "18rem");
            } else {
              root.style.removeProperty("display");
              root.querySelector('[data-slot="sidebar-gap"]').style.removeProperty("display");
              Object.entries(this.original.get(container)).forEach(([name,value]) => {if(value===null) container.removeAttribute(name);else container.setAttribute(name,value);});
            }
          });
          this.el.querySelectorAll('[data-sidebar="trigger"],[data-sidebar="rail"]').forEach(trigger => {
            if (trigger.closest('[data-slot="sidebar-wrapper"]') !== this.el) return;
            const target = this.containers()[0]; if (target) trigger.setAttribute("aria-controls",target.id);
            trigger.setAttribute("aria-expanded",String(mobile ? this.mobileOpen : this.open));
          });
          if (mobile && this.mobileOpen && !this.backdrop) {
            this.backdrop = document.createElement("div"); this.backdrop.style.cssText="position:fixed;inset:0;background:rgb(0 0 0 / .5);z-index:50";
            this.backdrop.addEventListener("click",() => this.closeMobile(),{signal:this.abort.signal});
            this.el.append(this.backdrop); this.containers()[0]?.focus();
            this.locked = true; this.previousOverflow = document.body.style.overflow; document.body.style.overflow = "hidden";
          } else if (mobile && this.mobileOpen && !this.backdrop.isConnected) {
            this.el.append(this.backdrop);
          } else if ((!mobile || !this.mobileOpen) && this.backdrop) {
            this.backdrop.remove(); this.backdrop=null; this.unlock(); this.returnFocus?.focus();
          }
          if (mobile && this.mobileOpen) {
            const container = this.containers()[0];
            if (container && !container.contains(document.activeElement)) container.focus();
          }
        },
        unlock() { if (this.locked) { document.body.style.overflow=this.previousOverflow;this.locked=false; } },
        beforeUpdate() { this.backdrop?.remove(); },
        updated() {
          const state=this.el.getAttribute("phx-value-open")==="true"; if(state!==this.serverOpen){this.open=state;this.serverOpen=state;}
          const mobileState=this.el.getAttribute("phx-value-mobile-open")==="true"; if(mobileState!==this.serverMobileOpen){this.mobileOpen=mobileState&&this.media.matches;this.serverMobileOpen=mobileState;}
          this.paint();
        },
        destroyed() { this.abort.abort();this.backdrop?.remove();this.unlock(); }
      }
    </script>
    """
  end

  attr :id, :string, required: true
  attr :sidebar, :map, required: true
  attr :side, :string, default: "left", values: ~w(left right)
  attr :variant, :string, default: "sidebar", values: ~w(sidebar floating inset)
  attr :collapsible, :string, default: "offcanvas", values: ~w(offcanvas icon none)
${globals}
  def sidebar(assigns) do
    assigns = assign(assigns, :floating, assigns.variant in ["floating", "inset"])
    ~H"""
    <div :if={@collapsible == "none"} id={@id} data-slot="sidebar"
      class={classes(["flex h-full w-(--sidebar-width) flex-col bg-sidebar text-sidebar-foreground", @class])} {@rest}>
      {render_slot(@inner_block, @sidebar)}
    </div>
    <div :if={@collapsible != "none"} data-slot="sidebar" class="group peer hidden text-sidebar-foreground md:block"
      data-state={if @sidebar.open, do: "expanded", else: "collapsed"} data-collapsible={if @sidebar.open, do: "", else: @collapsible}
      data-variant={@variant} data-side={@side} phx-value-collapsible={@collapsible}>
      <div data-slot="sidebar-gap" class={classes(["relative w-(--sidebar-width) bg-transparent transition-[width] duration-200 ease-linear group-data-[collapsible=offcanvas]:w-0 group-data-[side=right]:rotate-180", if(@floating, do: "group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4)))]", else: "group-data-[collapsible=icon]:w-(--sidebar-width-icon)")])}></div>
      <div id={@id} data-slot="sidebar-container" data-side={@side}
        class={classes(["fixed inset-y-0 z-10 hidden h-svh w-(--sidebar-width) transition-[left,right,width] duration-200 ease-linear data-[side=left]:left-0 data-[side=left]:group-data-[collapsible=offcanvas]:left-[calc(var(--sidebar-width)*-1)] data-[side=right]:right-0 data-[side=right]:group-data-[collapsible=offcanvas]:right-[calc(var(--sidebar-width)*-1)] md:flex", if(@floating, do: "p-2 group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4))+2px)]", else: "group-data-[collapsible=icon]:w-(--sidebar-width-icon) group-data-[side=left]:border-r group-data-[side=right]:border-l"), @class])} {@rest}>
        <div data-sidebar="sidebar" data-slot="sidebar-inner" class="flex size-full flex-col bg-sidebar group-data-[variant=floating]:rounded-lg group-data-[variant=floating]:shadow-sm group-data-[variant=floating]:ring-1 group-data-[variant=floating]:ring-sidebar-border">
          {render_slot(@inner_block, @sidebar)}
        </div>
      </div>
    </div>
    """
  end

  attr :sidebar, :map, required: true
${globals}
  def sidebar_trigger(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Button.button data-sidebar="trigger" data-slot="sidebar-trigger" variant="ghost" size="icon-sm" class={@class} {@rest}>
      <ShadcnLiveview.Components.Icon.icon name="panel-left" class="cn-rtl-flip" />
      <span class="sr-only">Toggle Sidebar</span>
    </ShadcnLiveview.Components.Button.button>
    """
  end

  attr :sidebar, :map, required: true
${globals}
  def sidebar_rail(assigns) do
    ~H"""
    <button data-sidebar="rail" data-slot="sidebar-rail" aria-label="Toggle Sidebar" tabindex="-1" title="Toggle Sidebar"
      class={classes([${base("sidebar_rail")}, @class])} {@rest}></button>
    """
  end

${Object.entries(ordinary).map(([name, tag]) => `${globals}
${name === "sidebar_group_label" || name === "sidebar_group_action" ? `  attr :tag, :string, default: "${tag}"\n` : ""}  def ${name}(assigns) do
    ~H"""
${name === "sidebar_group_label" || name === "sidebar_group_action" ? `    <.dynamic_tag tag_name={@tag}` : `    <${tag}`} data-slot="${name.replaceAll("_", "-")}" ${name === "sidebar_inset" ? "" : `data-sidebar="${name.replace("sidebar_", "").replaceAll("_", "-")}"`} class={classes([${base(name)}, @class])} {@rest}>
      {render_slot(@inner_block)}
    ${name === "sidebar_group_label" || name === "sidebar_group_action" ? "</.dynamic_tag>" : `</${tag}>`}
    """
  end`).join("\n\n")}

  attr :tag, :string, default: "button"
  attr :variant, :string, default: "default", values: ~w(default outline)
  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :is_active, :boolean, default: false
${globals}
  def sidebar_menu_button(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} data-slot="sidebar-menu-button" data-sidebar="menu-button" data-size={@size} data-active={to_string(@is_active)}
      class={classes([${base("sidebar_menu_button")}, if(@variant == "outline", do: "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]", else: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"), menu_size(@size), @class])} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :tag, :string, default: "button"
  attr :show_on_hover, :boolean, default: false
${globals}
  def sidebar_menu_action(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} data-slot="sidebar-menu-action" data-sidebar="menu-action"
      class={classes([${base("sidebar_menu_action")}, @show_on_hover && "group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 peer-data-active/menu-button:text-sidebar-accent-foreground aria-expanded:opacity-100 md:opacity-0", @class])} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :tag, :string, default: "a"
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :is_active, :boolean, default: false
${globals}
  def sidebar_menu_sub_button(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@tag} data-slot="sidebar-menu-sub-button" data-sidebar="menu-sub-button" data-size={@size} data-active={to_string(@is_active)}
      class={classes([${base("sidebar_menu_sub_button")}, @class])} {@rest}>{render_slot(@inner_block)}</.dynamic_tag>
    """
  end

${globals}
  def sidebar_input(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Input.input data-slot="sidebar-input" data-sidebar="input" class={classes(["h-8 w-full bg-background shadow-none", @class])} {@rest} />
    """
  end

${globals}
  def sidebar_separator(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Separator.separator data-slot="sidebar-separator" data-sidebar="separator" class={classes(["mx-2 w-auto bg-sidebar-border", @class])} {@rest} />
    """
  end

  attr :show_icon, :boolean, default: false
  attr :width, :string, default: "70%"
${globals}
  def sidebar_menu_skeleton(assigns) do
    ~H"""
    <div data-slot="sidebar-menu-skeleton" data-sidebar="menu-skeleton" class={classes(["flex h-8 items-center gap-2 rounded-md px-2", @class])} {@rest}>
      <ShadcnLiveview.Components.Skeleton.skeleton :if={@show_icon} class="size-4 rounded-md" data-sidebar="menu-skeleton-icon" />
      <ShadcnLiveview.Components.Skeleton.skeleton class="h-4 max-w-(--skeleton-width) flex-1" data-sidebar="menu-skeleton-text" style={"--skeleton-width:" <> @width} />
    </div>
    """
  end

  defp menu_size("sm"), do: "h-7 text-xs"
  defp menu_size("lg"), do: "h-12 text-sm group-data-[collapsible=icon]:p-0!"
  defp menu_size(_), do: "h-8 text-sm"
end
`
}
