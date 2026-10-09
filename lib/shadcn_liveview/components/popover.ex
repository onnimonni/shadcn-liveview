defmodule ShadcnLiveview.Components.Popover do
  @moduledoc """
  Accessible popover with explicit caller identity and slot-scoped context.

  Supply an `:id` and a named `:trigger` slot receiving a context map.
  Spread `context.trigger` on exactly one native trigger.
  The named content slot receives the same context; pass it to the content component.
  The LiveView owns open and selection state and renders content only when open.
  The colocated hook requests transitions, positions server-rendered content,
  and handles dismissal, focus, keyboard navigation, and pointer interactions.
  Handle `:on_change` (default `shadcn:popup-change`) with `id`, `action`,
  and `value` and update the corresponding root assigns.
  Set phx-target on this wrapperless root (or its optional `:target`) to route
  every hook event to a LiveComponent. The slot context forwards the target to
  its native trigger; the trigger also inherits its nearest containing phx-target.
  Escape dismisses the owning popup and restores focus to its trigger.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :dir, :string, default: "ltr", values: ~w(ltr rtl)
  attr :side, :string, default: "bottom", values: ~w(top right bottom left)
  attr :align, :string, default: "center", values: ~w(start center end)
  attr :side_offset, :integer, default: 4
  attr :open_delay, :integer, default: 0
  attr :close_delay, :integer, default: 100
  attr :on_change, :string, default: "shadcn:popup-change"
  attr :target, :any, default: nil
  attr :rest, :global

  slot :trigger, required: true
  slot :content, required: true

  @doc "Renders a popover root without a synthetic DOM wrapper."
  def popover(assigns) do
    context = %{
      id: assigns.id,
      target: assigns.target || Map.get(assigns.rest, :"phx-target"),
      content_id: assigns.id <> "-content",
      trigger_id: assigns.id <> "-trigger",
      open: assigns.open,
      state: if(assigns.open, do: "open", else: "closed"),
      dir: assigns.dir,
      side: assigns.side,
      align: assigns.align
    }

    trigger = %{
      "id" => context.trigger_id,
      "data-slot" => "popover-trigger",
      "data-state" => context.state,
      "phx-hook" => "ShadcnLiveview.Components.Popover.Popup",
      "phx-popup-id" => assigns.id,
      "phx-popup-kind" => "popover",
      "phx-popup-content-id" => context.content_id,
      "phx-popup-disabled" => to_string(assigns.disabled),
      "phx-target" => context.target,
      "phx-popup-offset" => assigns.side_offset,
      "phx-popup-open-delay" => assigns.open_delay,
      "phx-popup-close-delay" => assigns.close_delay,
      "phx-popup-event" => assigns.on_change
    }

    trigger =
      Map.merge(trigger, %{
        "type" => "button",
        "disabled" => assigns.disabled,
        "data-disabled" => nil,
        "aria-haspopup" => "dialog",
        "aria-expanded" => to_string(assigns.open),
        "aria-controls" => if(assigns.open, do: context.content_id)
      })

    assigns = assign(assigns, context: Map.put(context, :trigger, trigger))

    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @open do %>
      {render_slot(@content, @context)}
    <% end %>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Popup">
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          this.abort = new AbortController();
          this.kind = this.el.getAttribute("phx-popup-kind");
          this.contentId = this.el.getAttribute("phx-popup-content-id");
          this.listen = (node, name, fn, options = {}) => node.addEventListener(name, fn, {...options, signal: this.abort.signal});
          this.listen(this.el, "click", e => {
            if (this.kind === "tooltip") return this.close(false);
            if (["context-menu", "hover-card"].includes(this.kind)) return;
            e.preventDefault(); this.content ? this.close(true) : this.open(true);
          });
          this.listen(this.el, "contextmenu", e => {
            if (this.kind !== "context-menu" || this.disabled()) return;
            e.preventDefault(); this.point = {x: e.clientX, y: e.clientY}; this.open(true);
          });
          this.listen(this.el, "pointerdown", e => {
            if (this.kind === "context-menu" && e.pointerType !== "mouse") {
              this.point = {x: e.clientX, y: e.clientY};
              this.longPress = setTimeout(() => this.open(true), 700);
            }
          });
          ["pointerup", "pointercancel", "pointermove"].forEach(name => this.listen(this.el, name, () => clearTimeout(this.longPress)));
          if (["tooltip", "hover-card"].includes(this.kind)) {
            this.listen(this.el, "pointerenter", e => { if (e.pointerType !== "touch") this.scheduleOpen(); });
            this.listen(this.el, "pointerleave", () => this.scheduleClose());
            this.listen(this.el, "focus", () => { if (this.skipFocusOpen) return; if (this.kind === "tooltip") this.open(false); else this.scheduleOpen(); });
            this.listen(this.el, "blur", e => { if (!this.content?.contains(e.relatedTarget)) this.scheduleClose(); });
          }
          this.listen(this.el, "keydown", e => {
            if ((e.key === "ContextMenu" || (e.shiftKey && e.key === "F10")) && this.kind === "context-menu") {
              e.preventDefault(); this.point = null; this.open(true);
            } else if (["ArrowDown", "ArrowUp"].includes(e.key) && ["select", "dropdown-menu"].includes(this.kind)) {
              e.preventDefault(); this.open(true, e.key === "ArrowUp");
            } else if (e.key === "Escape") { e.preventDefault(); this.close(true); }
          });
          this.listen(document, "pointerdown", e => {
            if (this.content && !this.content.contains(e.target) && !this.el.contains(e.target)) this.close(false);
          });
          this.listen(document, "focusin", e => {
            if (this.content && !this.content.contains(e.target) && !this.el.contains(e.target) && this.kind !== "tooltip") this.close(false);
          });
          this.listen(document, "keydown", e => { if (e.key === "Escape" && !e.defaultPrevented && this.content) { e.preventDefault(); this.close(true); } });
          this.listen(window, "resize", () => this.position());
          this.listen(window, "scroll", () => this.position(), {capture: true});
          this.adopt(); this.populateSelect();
        },
        disabled() { return this.el.disabled || this.el.getAttribute("phx-popup-disabled") === "true"; },
        adopt() {
          if (this.kind === "context-menu" && !this.el.hasAttribute("tabindex")) this.el.tabIndex = this.disabled() ? -1 : 0;
          this.contentAbort?.abort();
          this.content = document.getElementById(this.contentId);
          this.wrapper = this.content?.parentElement;
          if (this.content) {
            this.pendingOpen = false; this.pendingClose = false;
            this.bindContent(); this.position();
            if (this.kind === "tooltip" && this.delayed) this.content.dataset.state = this.el.dataset.state = "delayed-open";
            if (this.pendingFocus) this.focusContent(this.pendingLast);
            this.pendingFocus = false;
          } else if (this.pendingRestore) {
            this.pendingRestore = false; this.skipFocusOpen = true; this.el.focus(); this.skipFocusOpen = false;
          }
        },
        updated() { this.adopt(); this.populateSelect(); },
        destroyed() {
          this.abort.abort(); this.contentAbort?.abort(); this.nativeAbort?.abort();
          clearTimeout(this.timer); clearTimeout(this.longPress); clearTimeout(this.resetTimer);
        },
        scheduleOpen() { clearTimeout(this.timer); this.timer = setTimeout(() => this.open(false, false, true), Number(this.el.getAttribute("phx-popup-open-delay") || 0)); },
        scheduleClose() { clearTimeout(this.timer); this.timer = setTimeout(() => this.close(false), Number(this.el.getAttribute("phx-popup-close-delay") || 100)); },
        open(focus, last = false, delayed = false) {
          clearTimeout(this.timer); if (this.disabled()) return;
          if (this.content && !this.pendingClose) { if (focus) this.focusContent(last); return; }
          this.pendingFocus = focus; this.pendingLast = last;
          this.delayed = this.kind === "tooltip" && delayed && Number(this.el.getAttribute("phx-popup-open-delay")) > 0;
          if (!this.pendingOpen) { this.pendingOpen = true; this.pendingClose = false; this.notify("open"); }
        },
        focusContent(last) {
          const items = this.items(); const selected = items.find(item => item.dataset.state === "checked");
          (selected || items[last ? items.length - 1 : 0] || this.content.querySelector("input,button,a[href],textarea,[tabindex='0']") || this.content).focus();
        },
        close(restore) {
          clearTimeout(this.timer);
          if ((!this.content && !this.pendingOpen) || this.pendingClose) return;
          this.pendingRestore = restore; this.pendingFocus = false;
          this.pendingOpen = false; this.pendingClose = true; this.notify("close");
        },
        items() { return this.content ? [...this.content.querySelectorAll('[role="option"],[role^="menuitem"]')].filter(item => item.getAttribute("aria-disabled") !== "true") : []; },
        bindContent() {
          this.contentAbort?.abort(); this.contentAbort = new AbortController();
          const on = (name, fn) => this.content.addEventListener(name, fn, {signal: this.contentAbort.signal});
          on("pointerenter", () => clearTimeout(this.timer));
          on("pointerleave", () => { if (["tooltip", "hover-card"].includes(this.kind)) this.scheduleClose(); });
          on("focusout", e => { if (!this.content?.contains(e.relatedTarget) && e.relatedTarget !== this.el) this.close(false); });
          on("pointermove", e => { const item = e.target.closest('[role="option"],[role^="menuitem"]'); if (item && item.getAttribute("aria-disabled") !== "true") item.focus(); });
          on("focusin", e => {
            this.items().forEach(item => { item.toggleAttribute("data-highlighted", item === e.target); if (item.getAttribute("role") === "option") item.setAttribute("aria-selected", String(item === e.target && item.dataset.state === "checked")); });
          });
          on("click", e => {
            if (e.target.closest("[phx-popup-close]")) return this.close(true);
            const item = e.target.closest('[role="option"],[role^="menuitem"]');
            if (!item || item.getAttribute("aria-disabled") === "true") return;
            if (item.getAttribute("role") === "option") this.select(item);
            else {
              const role = item.getAttribute("role");
              const checked = role === "menuitemcheckbox" ? item.getAttribute("aria-checked") !== "true" : role === "menuitemradio" ? true : undefined;
              this.notify("select", item.getAttribute("phx-popup-value") || item.textContent.trim(), {role, checked}); this.close(true);
            }
          });
          on("keydown", e => {
            const items = this.items(); const index = items.indexOf(document.activeElement);
            if (["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key) && items.length) {
              e.preventDefault(); const next = e.key === "Home" ? 0 : e.key === "End" ? items.length - 1 : (index + (e.key === "ArrowUp" ? -1 : 1) + items.length) % items.length; items[next].focus();
            } else if (["Enter", " "].includes(e.key) && index >= 0) { e.preventDefault(); items[index].click(); }
            else if (e.key === "Escape") { e.preventDefault(); this.close(true); }
            else if (e.key === "Tab" && ["select", "dropdown-menu", "context-menu"].includes(this.kind)) this.close(false);
            else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey) {
              this.search = (Date.now() - (this.searchTime || 0) < 700 ? this.search || "" : "") + e.key.toLowerCase(); this.searchTime = Date.now();
              const found = [...items.slice(index + 1), ...items.slice(0, index + 1)].find(item => item.textContent.trim().toLowerCase().startsWith(this.search)); if (found) found.focus();
            }
          });
        },
        position() {
          if (!this.content || !this.wrapper) return;
          const rect = this.el.getBoundingClientRect(); const box = this.content.getBoundingClientRect();
          const side = this.content.dataset.side || "bottom"; const align = this.content.dataset.align || "center";
          const gap = Number(this.el.getAttribute("phx-popup-offset") || 4);
          let x = align === "start" ? rect.left : align === "end" ? rect.right - box.width : rect.left + (rect.width - box.width) / 2;
          let y = side === "top" ? rect.top - box.height - gap : rect.bottom + gap;
          if (side === "left" || side === "right") { x = side === "left" ? rect.left - box.width - gap : rect.right + gap; y = align === "start" ? rect.top : align === "end" ? rect.bottom - box.height : rect.top + (rect.height - box.height) / 2; }
          if (this.kind === "context-menu" && this.point) { x = this.point.x; y = this.point.y; }
          x = Math.max(4, Math.min(x, window.innerWidth - box.width - 4)); y = Math.max(4, Math.min(y, window.innerHeight - box.height - 4));
          Object.assign(this.wrapper.style, {position: "fixed", left: x + "px", top: y + "px", transform: "none", zIndex: "50"});
          this.wrapper.style.setProperty("--radix-popper-anchor-width", rect.width + "px");
          this.wrapper.style.setProperty("--radix-popper-anchor-height", rect.height + "px");
          this.wrapper.style.setProperty("--radix-popper-available-height", Math.max(0, window.innerHeight - y - 4) + "px");
          this.wrapper.style.setProperty("--radix-popper-available-width", (window.innerWidth - 8) + "px");
          this.wrapper.style.setProperty("--radix-popper-transform-origin", align + " " + (side === "top" ? "bottom" : "top"));
          const arrow = this.content.querySelector("[phx-popup-arrow]"); if (arrow) arrow.style.visibility = "visible";
        },
        populateSelect() {
          if (this.kind !== "select") return;
          this.native = this.el.nextElementSibling;
          while (this.native && this.native.tagName !== "SELECT") this.native = this.native.nextElementSibling;
          if (!this.native) return;
          const options = JSON.parse(this.el.getAttribute("phx-popup-options") || "[]");
          const value = this.el.getAttribute("phx-popup-value") || "";
          this.native.replaceChildren(); if (!value) this.native.add(new Option("", ""));
          options.forEach(item => { const option = new Option(item.label, item.value); option.disabled = item.disabled; this.native.add(option); });
          this.native.value = value;
          this.nativeAbort?.abort(); this.nativeAbort = new AbortController();
          this.resetValue ??= value;
          this.native.addEventListener("change", () => { if (!this.nativeUpdating) this.notify("select", this.native.value); }, {signal: this.nativeAbort.signal});
          if (this.native.form) this.native.form.addEventListener("reset", () => {
            clearTimeout(this.resetTimer);
            this.resetTimer = setTimeout(() => { this.native.value = this.resetValue; this.notify("select", this.resetValue); }, 0);
          }, {signal: this.nativeAbort.signal});
        },
        select(item) {
          const value = item.getAttribute("phx-popup-value");
          if (this.native) {
            this.nativeUpdating = true; this.native.value = value;
            this.native.dispatchEvent(new Event("input", {bubbles: true}));
            this.native.dispatchEvent(new Event("change", {bubbles: true}));
            this.nativeUpdating = false;
          }
          this.notify("select", value); this.close(true);
        },
        notify(action, value, extra = {}) {
          const id = this.el.getAttribute("phx-popup-id");
          const payload = {action, value, id, ...extra};
          this.el.dispatchEvent(new CustomEvent("shadcn:popup", {bubbles: true, detail: payload}));
          const event = this.el.getAttribute("phx-popup-event"); if (event) this.sendEvent(event, payload);
        }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def popover_content(assigns) do
    ~H"""
    <div
      data-radix-popper-content-wrapper=""
      style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:"
      dir={nil}
    >
      <div
        id={@context.content_id}
        data-side={@context.side}
        data-align={@context.align}
        data-state={@context.state}
        data-slot="popover-content"
        role="dialog"
        tabindex="-1"
        aria-orientation={nil}
        aria-labelledby={nil}
        data-radix-menu-content={nil}
        data-orientation={nil}
        dir={nil}
        class={
          classes([
            "z-50 flex w-72 origin-(--radix-popover-content-transform-origin) flex-col gap-2.5 rounded-lg bg-popover p-2.5 text-sm text-popover-foreground shadow-md ring-1 ring-foreground/10 outline-hidden duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95",
            @class
          ])
        }
        style={content_style()}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp content_style do
    "--radix-popover-content-transform-origin:var(--radix-popper-transform-origin);--radix-popover-content-available-width:var(--radix-popper-available-width);--radix-popover-content-available-height:var(--radix-popper-available-height);--radix-popover-trigger-width:var(--radix-popper-anchor-width);--radix-popover-trigger-height:var(--radix-popper-anchor-height);animation:none"
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def popover_anchor(assigns) do
    ~H"""
    <div data-slot="popover-anchor" class={classes(["", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def popover_header(assigns) do
    ~H"""
    <div data-slot="popover-header" class={classes(["flex flex-col gap-0.5 text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def popover_title(assigns) do
    ~H"""
    <h2 data-slot="popover-title" class={classes(["font-medium", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def popover_description(assigns) do
    ~H"""
    <p data-slot="popover-description" class={classes(["text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end
end
