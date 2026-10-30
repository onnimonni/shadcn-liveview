defmodule ShadcnLiveview.Components.Resizable do
  @moduledoc """
  Resizable panels using the current react-resizable-panels sizing convention:
  numeric sizes are pixels; strings accept CSS lengths and percentages. Require
  stable IDs for the group, every panel and every handle. Bind the group with
  `:let={group}` and pass `group={group}` to its direct children. The hook
  installs separator ARIA relationships after layout, supports pointer capture,
  arrow/Home/End keyboard resizing, min/max constraints and collapsible panels.
  Arrow keys resize by five percentage points, including with Shift held.
  Double-clicking an enabled separator resets the first adjacent panel with an
  explicit default_size, respecting its constraints; panels without defaults do
  not reset. Disabled groups, separators and fixed panels cannot be resized.
  Set disable_double_click on a separator to opt out of this reset.
  Keep panel default_size values as reset baselines. Bind the group's layout to
  a map of panel IDs to percentages for caller-owned state, and persist the
  value map from shadcn:resizable-change; resizable:change exposes that same map
  as a browser event. Reset notifications use the same payload and phx-target
  routing as pointer and keyboard resizing.
  Hook events honor phx-target on the root or nearest containing element,
  including internal state changes and completion acknowledgements.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :disabled, :boolean, default: false
  attr :layout, :map, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def resizable_panel_group(assigns) do
    assigns =
      assign(assigns, :context, %{
        id: assigns.id,
        orientation: assigns.orientation,
        disabled: assigns.disabled
      })

    ~H"""
    <div
      id={@id}
      data-slot="resizable-panel-group"
      data-group="true"
      data-testid={@id}
      class={classes(["flex h-full w-full aria-[orientation=vertical]:flex-col", @class])}
      style={"height:100%;width:100%;overflow:hidden;display:flex;flex-direction:" <> if(@orientation == "horizontal", do: "row", else: "column") <> ";flex-wrap:nowrap;touch-action:" <> if(@orientation == "horizontal", do: "pan-y", else: "pan-x")}
      phx-hook=".Resizable"
      phx-value-orientation={@orientation}
      phx-value-disabled={to_string(@disabled)}
      phx-value-layout={if @layout, do: Jason.encode!(@layout)}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Resizable">
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
          on("dblclick", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (event.defaultPrevented || !this.usable(handle) || handle.getAttribute("phx-value-disable-double-click") === "true") return;
            const panels = this.panels(), index = this.pair(handle).find(index => panels[index].hasAttribute("phx-value-default-size"));
            if (index === undefined) return;
            event.preventDefault(); this.reset(index);
          });
          on("keydown", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (!this.usable(handle)) return;
            const keys = this.vertical() ? ["ArrowUp", "ArrowDown"] : ["ArrowLeft", "ArrowRight"];
            let delta = event.key === keys[0] ? -5 : event.key === keys[1] ? 5 : 0;
            if (event.key === "Home") delta = -100;
            if (event.key === "End") delta = 100;
            if (!delta) return;
            event.preventDefault(); this.resize(handle, this.sizes(), delta); this.emit();
          });
          this.observer = new ResizeObserver(() => this.aria()); this.observer.observe(this.el); this.configure();
        },
        vertical() { return this.el.getAttribute("phx-value-orientation") === "vertical"; },
        point(event) { return this.vertical() ? event.clientY : event.clientX; },
        length() { return this.panels().reduce((total,panel) => total + (this.vertical() ? panel.offsetHeight : panel.offsetWidth), 0); },
        panels() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-panel"); },
        handles() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-handle"); },
        sizes() { const sizes = this.panels().map(node => this.vertical() ? node.getBoundingClientRect().height : node.getBoundingClientRect().width); const total = sizes.reduce((a,b) => a+b, 0); return sizes.map(size => total ? size / total * 100 : 100 / sizes.length); },
        bound(panel, name, fallback) {
          const value = panel.getAttribute("phx-value-" + name);
          if (!value) return fallback;
          if (value.endsWith("%")) return parseFloat(value);
          let pixels;
          if (/^[\d.]+(?:px)?$/.test(value)) pixels = parseFloat(value);
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
          return left >= 0 && right >= 0 && ![panels[left],panels[right]].some(panel => panel.dataset.disabled === "true" || this.bound(panel, "min-size", 0) >= this.bound(panel, "max-size", 100));
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
        clamp(panel, value) {
          const min = this.bound(panel, "min-size", 0), max = this.bound(panel, "max-size", 100);
          if (value < min) {
            const collapsed = this.bound(panel, "collapsed-size", 0);
            value = panel.getAttribute("phx-value-collapsible") === "true" && value < (min + collapsed) / 2 ? collapsed : min;
          }
          return Math.min(max, value);
        },
        normalize(values) {
          const panels = this.panels(), total = values.reduce((sum,value) => sum + value, 0);
          const normalized = values.map(value => total ? value / total * 100 : 100 / panels.length);
          let remaining = 0;
          panels.forEach((panel,index) => { const next = this.clamp(panel, normalized[index]); remaining += normalized[index] - next; normalized[index] = next; });
          for (let index = 0; index < panels.length && Math.abs(remaining) > .001; index++) {
            const next = this.clamp(panels[index], normalized[index] + remaining);
            remaining -= next - normalized[index]; normalized[index] = next;
          }
          return normalized;
        },
        apply(values) {
          this.panels().forEach((panel,index) => {panel.style.flexBasis="0px";panel.style.flexGrow=values[index];panel.style.flexShrink="1";}); this.aria();
        },
        reset(index) {
          const panels = this.panels(), sizes = this.sizes(), last = index === panels.length - 1;
          const target = this.bound(panels[index], "default-size", sizes[index]);
          let delta = last ? sizes[index] - target : target - sizes[index];
          if (Math.abs(delta) < .001) return;
          const a = last ? index - 1 : index, b = last ? index : index + 1;
          const expanding = delta > 0 ? a : b, min = this.bound(panels[expanding], "min-size", 0);
          if (panels[expanding].getAttribute("phx-value-collapsible") === "true" && sizes[expanding] < min && sizes[expanding] + Math.abs(delta) < min) {
            const gap = min - this.bound(panels[expanding], "collapsed-size", 0);
            if (Math.abs(delta) < gap / 2 || (Math.abs(delta) === gap / 2 && delta > 0)) return;
            delta = delta < 0 ? -gap : gap;
          }
          const growing = [], shrinking = [];
          for (let current = delta > 0 ? a : b; current >= 0 && current < panels.length; current += delta > 0 ? -1 : 1) growing.push(current);
          for (let current = delta > 0 ? b : a; current >= 0 && current < panels.length; current += delta > 0 ? 1 : -1) shrinking.push(current);
          const clamp = (current,value) => panels[current].dataset.disabled === "true" ? sizes[current] : this.clamp(panels[current], value);
          const capacity = growing.reduce((sum,current) => sum + clamp(current,100) - sizes[current], 0);
          const requested = Math.min(Math.abs(delta), Math.max(0,capacity)), next = [...sizes];
          let freed = 0;
          for (const current of shrinking) {
            next[current] = clamp(current, sizes[current] - (requested - freed));
            freed += sizes[current] - next[current];
            if (freed >= requested - .001) break;
          }
          let remaining = freed;
          for (const current of growing) {
            next[current] = clamp(current, sizes[current] + remaining);
            remaining -= next[current] - sizes[current];
            if (Math.abs(remaining) < .001) break;
          }
          if (Math.abs(remaining) > .1 || next.every((value,current) => Math.abs(value - sizes[current]) < .001)) return;
          this.apply(next); this.emit();
        },
        configure() {
          const panels = this.panels(), values = this.sizes(), layoutValue = this.el.getAttribute("phx-value-layout");
          const signature = [this.vertical(),layoutValue,panels.map(panel => [panel.id,...["default-size","min-size","max-size","collapsible","collapsed-size"].map(name => panel.getAttribute("phx-value-"+name))].join(":")).join("|")].join(";");
          if (signature === this.layoutSignature) {this.aria();return;} this.layoutSignature = signature;
          const defaults = panels.map(panel => panel.getAttribute("phx-value-default-size") ? this.bound(panel, "default-size", 0) : null);
          const specified = defaults.reduce((sum,value) => sum + (value || 0), 0), missing = defaults.filter(value => value === null).length;
          if (defaults.some(value => value !== null)) {
            const requested = defaults.map(value => value === null ? Math.max(0,100-specified) / missing : value);
            const sum = requested.reduce((total,value) => total + value,0);
            if (sum) requested.forEach((value,index) => {values[index] = value / sum * 100;});
          }
          if (layoutValue) {
            const layout = JSON.parse(layoutValue);
            if (panels.every(panel => typeof layout[panel.id] === "number")) panels.forEach((panel,index) => {values[index] = layout[panel.id];});
          }
          this.apply(this.normalize(values));
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
          this.sendEvent("shadcn:resizable-change", {id:this.el.id,value});
        },
        updated() { this.configure(); },
        destroyed() { this.abort.abort(); this.observer.disconnect(); this.drag = null; }
      }
    </script>
    """
  end

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :group, :map, required: true
  attr :default_size, :any, default: nil
  attr :min_size, :any, default: nil
  attr :max_size, :any, default: nil
  attr :collapsed_size, :any, default: 0
  attr :collapsible, :boolean, default: false
  attr :disabled, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def resizable_panel(assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="resizable-panel"
      data-panel="true"
      data-testid={@id}
      data-disabled={if @disabled, do: "true"}
      class={@class}
      style={panel_style(@default_size)}
      phx-value-default-size={size_value(@default_size)}
      phx-value-min-size={size_value(@min_size)}
      phx-value-max-size={size_value(@max_size)}
      phx-value-collapsible={to_string(@collapsible)}
      phx-value-collapsed-size={size_value(@collapsed_size)}
      {@rest}
    >
      <div style={"max-height:100%;max-width:100%;flex-grow:1;overflow:auto;touch-action:" <> if(@group.orientation == "horizontal", do: "pan-y", else: "pan-x")}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :group, :map, required: true
  attr :with_handle, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :disable_double_click, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def resizable_handle(assigns) do
    assigns = assign(assigns, :disabled, assigns.disabled or assigns.group.disabled)

    ~H"""
    <div
      id={@id}
      data-slot="resizable-handle"
      data-testid={@id}
      data-separator={if @disabled, do: "disabled", else: "inactive"}
      role="separator"
      aria-disabled={if @disabled, do: "true"}
      aria-orientation={if @group.orientation == "horizontal", do: "vertical", else: "horizontal"}
      phx-value-disable-double-click={to_string(@disable_double_click)}
      tabindex={if !@disabled, do: "0"}
      class={
        classes([
          "relative flex w-px items-center justify-center bg-border ring-offset-background after:absolute after:inset-y-0 after:left-1/2 after:w-1 after:-translate-x-1/2 focus-visible:ring-1 focus-visible:ring-ring focus-visible:outline-hidden aria-[orientation=horizontal]:h-px aria-[orientation=horizontal]:w-full aria-[orientation=horizontal]:after:left-0 aria-[orientation=horizontal]:after:h-1 aria-[orientation=horizontal]:after:w-full aria-[orientation=horizontal]:after:translate-x-0 aria-[orientation=horizontal]:after:-translate-y-1/2 [&[aria-orientation=horizontal]>div]:rotate-90",
          @class
        ])
      }
      style={"flex-basis:auto;" <> if(@disabled, do: "cursor:not-allowed;", else: "") <> "flex-grow:0;flex-shrink:0;touch-action:none"}
      {@rest}
    >
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
      if(is_nil(size),
        do: "flex-basis:0;flex-shrink:1;overflow:visible;flex-grow:1",
        else: "flex-basis:" <> size_value(size) <> ";overflow:visible"
      )
  end
end
