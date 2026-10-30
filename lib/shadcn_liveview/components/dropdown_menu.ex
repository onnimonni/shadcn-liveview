defmodule ShadcnLiveview.Components.DropdownMenu do
  @moduledoc """
  Accessible dropdown-menu with explicit caller identity and slot-scoped context.

  Supply an `:id` and a named `:trigger` slot receiving a context map.
  Spread `context.trigger` on exactly one native trigger.
  The root owns the trigger ID (default `id <> "-trigger"`); set `:trigger_id` to choose it so
  content aria relations and focus return follow. Never add `id` beside the spread: HEEx renders both.
  The named content slot receives the same context; pass it to the content component.
  The LiveView owns open and selection state and renders content only when open.
  The colocated hook requests transitions, positions server-rendered content,
  and handles dismissal, focus, keyboard navigation, and pointer interactions.
  Open content stays inline for LiveView patching but is shown in the browser
  top layer (a manual `popover`), so like a Radix portal it escapes ancestor
  stacking contexts (`relative z-0` rows), overflow clipping and transforms.
  As in Radix, a pointer open focuses the menu itself; a keyboard open
  (Enter, Space, ArrowDown or ArrowUp) focuses the first (ArrowUp: last) item.
  Handle `:on_change` (default `shadcn:popup-change`) with `id`, `action`,
  and `value` and update the corresponding root assigns.
  Set phx-target on this wrapperless root (or its optional `:target`) to route
  every hook event to a LiveComponent. The slot context forwards the target to
  its native trigger; the trigger also inherits its nearest containing phx-target.
  Menu selections include `role` and `checked`; checkbox changes update their own value key, while radio selections update the group value.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :dir, :string, default: "ltr", values: ~w(ltr rtl)
  attr :side, :string, default: "bottom", values: ~w(top right bottom left)
  attr :align, :string, default: "start", values: ~w(start center end)
  attr :side_offset, :integer, default: 4
  attr :open_delay, :integer, default: 0
  attr :close_delay, :integer, default: 100

  attr :on_change, :string,
    default: "shadcn:popup-change",
    doc: "LiveView event name pushed on change; the payload is described in the module docs."

  attr :trigger_id, :string, default: nil

  attr :target, :any,
    default: nil,
    doc: "Event target such as `@myself`; equivalent to `phx-target` on the root."

  attr :rest, :global

  slot :trigger, required: true
  slot :content, required: true

  @doc "Renders a dropdown-menu root without a synthetic DOM wrapper."
  def dropdown_menu(assigns) do
    context = %{
      id: assigns.id,
      target: assigns.target || Map.get(assigns.rest, :"phx-target"),
      content_id: assigns.id <> "-content",
      trigger_id: trigger_id(assigns),
      open: assigns.open,
      state: if(assigns.open, do: "open", else: "closed"),
      dir: assigns.dir,
      side: assigns.side,
      align: assigns.align
    }

    trigger = %{
      "id" => context.trigger_id,
      "data-slot" => "dropdown-menu-trigger",
      "data-state" => context.state,
      "phx-hook" => "ShadcnLiveview.Components.DropdownMenu.Popup",
      "phx-popup-id" => assigns.id,
      "phx-popup-kind" => "dropdown-menu",
      "phx-popup-content-id" => context.content_id,
      "phx-popup-trigger-id" => context.trigger_id,
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
        "data-disabled" => if(assigns.disabled, do: ""),
        "aria-haspopup" => "menu",
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
        promoteToTopLayer(el, bare) {
          if (!el || typeof el.showPopover !== "function") return;
          if (!el.hasAttribute("popover")) {
            this.js().ignoreAttributes(el, ["popover", "style"]);
            el.setAttribute("popover", "manual");
            Object.assign(el.style, {inset: "auto", margin: "0"});
            if (bare) Object.assign(el.style, {border: "0", padding: "0", overflow: "visible", background: "transparent", color: "inherit"});
          }
          if (!el.matches(":popover-open")) el.showPopover();
        },
        mounted() {
          this.abort = new AbortController();
          this.kind = this.el.getAttribute("phx-popup-kind");
          this.contentId = this.el.getAttribute("phx-popup-content-id");
          const triggerId = this.el.getAttribute("phx-popup-trigger-id");
          if (triggerId && this.el.id !== triggerId) console.error("shadcn_liveview: the element spreading the " + this.kind + " trigger context has id=\"" + this.el.id + "\" instead of the root's trigger id \"" + triggerId + "\", so aria relations and focus return break. Pass trigger_id=\"" + this.el.id + "\" on the root and drop id from the trigger element.", this.el);
          this.listen = (node, name, fn, options = {}) => node.addEventListener(name, fn, {...options, signal: this.abort.signal});
          this.listen(this.el, "click", e => {
            if (this.kind === "tooltip") return this.close(false);
            if (["context-menu", "hover-card"].includes(this.kind)) return;
            // Enter/Space activation dispatches a click with detail 0: a keyboard open.
            e.preventDefault(); this.content ? this.close(true) : this.open(true, false, false, e.detail === 0);
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
              e.preventDefault(); this.point = null; this.open(true, false, false, true);
            } else if (["ArrowDown", "ArrowUp"].includes(e.key) && ["select", "dropdown-menu"].includes(this.kind)) {
              e.preventDefault(); this.open(true, e.key === "ArrowUp", false, true);
            } else if (e.key === "Escape" && (this.content || this.pendingOpen)) { e.preventDefault(); this.close(true); }
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
            this.bindContent(); this.promoteToTopLayer(this.wrapper, true); this.position();
            if (this.kind === "tooltip" && this.delayed) this.content.dataset.state = this.el.dataset.state = "delayed-open";
            if (this.pendingFocus) this.focusContent(this.pendingLast, this.pendingKeyboard);
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
        open(focus, last = false, delayed = false, keyboard = false) {
          clearTimeout(this.timer); if (this.disabled()) return;
          if (this.content && !this.pendingClose) { if (focus) this.focusContent(last, keyboard); return; }
          this.pendingFocus = focus; this.pendingLast = last;
          // A keyboard request is not downgraded by the pointer-style event it may also dispatch.
          this.pendingKeyboard = keyboard || (!!this.pendingOpen && !!this.pendingKeyboard);
          this.delayed = this.kind === "tooltip" && delayed && Number(this.el.getAttribute("phx-popup-open-delay")) > 0;
          if (!this.pendingOpen) { this.pendingOpen = true; this.pendingClose = false; this.notify("open"); }
        },
        focusContent(last, keyboard) {
          const items = this.items();
          // Radix menus focus their content on pointer open and the first (ArrowUp: last) item only on
          // keyboard open. Select focuses its selected item, else the first valid one, either way.
          if (["dropdown-menu", "context-menu"].includes(this.kind)) return (keyboard && items[last ? items.length - 1 : 0] || this.content).focus({preventScroll: !keyboard});
          const selected = items.find(item => item.dataset.state === "checked");
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
          // Leaving a highlighted option/item returns focus to the content, clearing the highlight
          // (Radix select/menu onItemLeave).
          on("pointerout", e => {
            const item = e.target.closest('[role="option"],[role^="menuitem"]');
            if (item && document.activeElement === item && !item.contains(e.relatedTarget)) this.content.focus({preventScroll: true});
          });
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
              const up = e.key === "ArrowUp";
              e.preventDefault(); const next = e.key === "Home" ? 0 : e.key === "End" ? items.length - 1 : index < 0 ? (up ? items.length - 1 : 0) : (index + (up ? -1 : 1) + items.length) % items.length; items[next].focus();
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
          // A failed push keeps the server-rendered popup; clear pending requests so the next interaction retries.
          const event = this.el.getAttribute("phx-popup-event"); if (event) this.sendEvent(event, payload).catch(() => {
            this.pendingOpen = this.pendingClose = this.pendingFocus = this.pendingRestore = false;
            if (this.native) this.native.value = this.el.getAttribute("phx-popup-value") || "";
          });
        }
      }
    </script>
    """
  end

  defp trigger_id(%{trigger_id: nil, id: id}), do: id <> "-trigger"
  defp trigger_id(%{trigger_id: trigger_id}), do: trigger_id

  attr :context, :map, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_content(assigns) do
    ~H"""
    <div
      data-radix-popper-content-wrapper=""
      style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:"
      dir={@context.dir}
    >
      <div
        id={@context.content_id}
        data-side={@context.side}
        data-align={@context.align}
        data-state={@context.state}
        data-slot="dropdown-menu-content"
        role="menu"
        tabindex="-1"
        aria-orientation="vertical"
        aria-labelledby={@context.trigger_id}
        data-radix-menu-content=""
        data-orientation="vertical"
        dir={@context.dir}
        class={
          classes([
            "cn-menu-target cn-menu-translucent z-50 max-h-(--radix-dropdown-menu-content-available-height) w-(--radix-dropdown-menu-trigger-width) min-w-32 origin-(--radix-dropdown-menu-content-transform-origin) overflow-x-hidden overflow-y-auto rounded-lg bg-popover p-1 text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:overflow-hidden data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95",
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
    "outline:none;--radix-dropdown-menu-content-transform-origin:var(--radix-popper-transform-origin);--radix-dropdown-menu-content-available-width:var(--radix-popper-available-width);--radix-dropdown-menu-content-available-height:var(--radix-popper-available-height);--radix-dropdown-menu-trigger-width:var(--radix-popper-anchor-width);--radix-dropdown-menu-trigger-height:var(--radix-popper-anchor-height);animation:none"
  end

  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: false
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :value, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id)
  slot :inner_block, required: true

  def dropdown_menu_item(assigns) do
    ~H"""
    <div
      role="menuitem"
      aria-disabled={if @disabled, do: "true"}
      data-disabled={if @disabled, do: ""}
      data-slot="dropdown-menu-item"
      data-variant={@variant}
      data-inset={if @inset, do: "true"}
      class={
        classes([
          "group/dropdown-menu-item relative flex cursor-default items-center gap-1.5 rounded-md px-1.5 py-1 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground not-data-[variant=destructive]:focus:**:text-accent-foreground data-inset:pl-7 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 data-[variant=destructive]:*:[svg]:text-destructive",
          @class
        ])
      }
      tabindex="-1"
      data-orientation="vertical"
      phx-popup-value={@value}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: false
  attr :value, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id)
  slot :inner_block, required: true

  def dropdown_menu_checkbox_item(assigns) do
    ~H"""
    <div
      role="menuitemcheckbox"
      aria-checked={to_string(@checked)}
      aria-disabled={if @disabled, do: "true"}
      data-state={if @checked, do: "checked", else: "unchecked"}
      data-disabled={if @disabled, do: ""}
      data-inset={if @inset, do: "true"}
      data-slot="dropdown-menu-checkbox-item"
      class={
        classes([
          "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-8 pl-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      tabindex="-1"
      data-orientation="vertical"
      phx-popup-value={@value}
      {@rest}
    >
      <span
        class="pointer-events-none absolute right-2 flex items-center justify-center"
        data-slot="dropdown-menu-checkbox-item-indicator"
      ><span :if={@checked} data-state="checked"><Icon.icon name="check" /></span></span>{render_slot(
        @inner_block
      )}
    </div>
    """
  end

  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: false
  attr :value, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id)
  slot :inner_block, required: true

  def dropdown_menu_radio_item(assigns) do
    ~H"""
    <div
      role="menuitemradio"
      aria-checked={to_string(@checked)}
      aria-disabled={if @disabled, do: "true"}
      data-state={if @checked, do: "checked", else: "unchecked"}
      data-disabled={if @disabled, do: ""}
      data-inset={if @inset, do: "true"}
      data-slot="dropdown-menu-radio-item"
      class={
        classes([
          "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-8 pl-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      tabindex="-1"
      data-orientation="vertical"
      phx-popup-value={@value}
      {@rest}
    >
      <span
        class="pointer-events-none absolute right-2 flex items-center justify-center"
        data-slot="dropdown-menu-radio-item-indicator"
      ><span :if={@checked} data-state="checked"><Icon.icon name="check" /></span></span>{render_slot(
        @inner_block
      )}
    </div>
    """
  end

  attr :inset, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_label(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-label"
      data-inset={if @inset, do: "true"}
      class={
        classes(["px-1.5 py-1 text-xs font-medium text-muted-foreground data-inset:pl-7", @class])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def dropdown_menu_separator(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-separator"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      role="separator"
      aria-orientation="horizontal"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def dropdown_menu_shortcut(assigns) do
    ~H"""
    <span
      data-slot="dropdown-menu-shortcut"
      class={
        classes([
          "ml-auto text-xs tracking-widest text-muted-foreground group-focus/dropdown-menu-item:text-accent-foreground",
          @class
        ])
      }
      {@rest}
    >{render_slot(@inner_block)}</span>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def dropdown_menu_group(assigns) do
    ~H"""
    <div data-slot="dropdown-menu-group" class={classes(["", @class])} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global, include: ~w(id href tabindex)
  slot :inner_block

  def dropdown_menu_radio_group(assigns) do
    ~H"""
    <div data-slot="dropdown-menu-radio-group" class={classes(["", @class])} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
