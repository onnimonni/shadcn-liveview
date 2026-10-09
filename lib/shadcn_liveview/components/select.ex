defmodule ShadcnLiveview.Components.Select do
  @moduledoc """
  Accessible select with explicit caller identity and slot-scoped context.

  Supply an `:id` and a named `:trigger` slot receiving a context map.
  Spread `context.trigger` on exactly one native trigger, or pass the context map to the family trigger component.
  Declare options with stable IDs, values, labels, and rendered option slots; optional group slots label option groups.
  The LiveView owns open and selection state and renders content only when open.
  The colocated hook requests transitions, positions server-rendered content,
  and handles dismissal, focus, keyboard navigation, and native form synchronization.
  Handle `:on_change` (default `shadcn:popup-change`) with `id`, `action`,
  and `value` and update the corresponding root assigns.
  Set phx-target on this wrapperless root (or its optional `:target`) to route
  every hook event to a LiveComponent. The slot context forwards the target to
  its native trigger; the trigger also inherits its nearest containing phx-target.
  Escape dismisses the owning popup and restores focus to its trigger.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

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
  attr :value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :required, :boolean, default: false
  attr :placeholder, :string, default: ""
  attr :position, :string, default: "item-aligned", values: ~w(item-aligned popper)

  slot :option, required: true do
    attr :id, :string, required: true
    attr :value, :string, required: true
    attr :label, :string, required: true
    attr :disabled, :boolean
    attr :class, :string
    attr :group, :string
  end

  slot :group do
    attr :id, :string, required: true
    attr :label, :string, required: true
  end

  slot :trigger, required: true

  @doc "Renders a select root without a synthetic DOM wrapper."
  def select(assigns) do
    context = %{
      id: assigns.id,
      target: assigns.target || Map.get(assigns.rest, :"phx-target"),
      content_id: assigns.id <> "-content",
      trigger_id: assigns.id <> "-trigger",
      open: assigns.open,
      state: if(assigns.open, do: "open", else: "closed"),
      dir: assigns.dir,
      side: assigns.side,
      align: assigns.align,
      value: assigns.value,
      position: assigns.position,
      label:
        Enum.find_value(assigns.option, fn option ->
          if option.value == assigns.value, do: option.label
        end)
    }

    markup = if assigns.open, do: select_content(assign(assigns, :context, context))

    trigger = %{
      "id" => context.trigger_id,
      "data-slot" => "select-trigger",
      "data-state" => context.state,
      "phx-hook" => "ShadcnLiveview.Components.Select.Popup",
      "phx-popup-id" => assigns.id,
      "phx-popup-kind" => "select",
      "phx-popup-content-id" => context.content_id,
      "phx-popup-disabled" => to_string(assigns.disabled),
      "phx-target" => context.target,
      "phx-popup-offset" => assigns.side_offset,
      "phx-popup-open-delay" => assigns.open_delay,
      "phx-popup-close-delay" => assigns.close_delay,
      "phx-popup-event" => assigns.on_change,
      "phx-popup-value" => assigns.value,
      "phx-popup-placeholder" => assigns.placeholder,
      "phx-popup-options" =>
        Jason.encode!(
          Enum.map(assigns.option, fn option ->
            %{
              value: option.value,
              label: option.label,
              disabled: Map.get(option, :disabled, false)
            }
          end)
        )
    }

    trigger =
      Map.merge(trigger, %{
        "type" => "button",
        "disabled" => assigns.disabled,
        "data-disabled" => nil,
        "aria-haspopup" => "listbox",
        "aria-expanded" => to_string(assigns.open),
        "aria-controls" => if(assigns.open, do: context.content_id)
      })

    trigger =
      trigger
      |> Map.delete("aria-haspopup")
      |> Map.merge(%{
        "role" => "combobox",
        "aria-autocomplete" => "none",
        "aria-required" => if(assigns.required, do: "true"),
        "dir" => assigns.dir,
        "data-disabled" => if(assigns.disabled, do: ""),
        "data-placeholder" => if(assigns.value in [nil, ""], do: "")
      })

    assigns = assign(assigns, context: Map.put(context, :trigger, trigger), markup: markup)

    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @open do %>
      {@markup}
    <% end %>
    <select
      name={@name}
      form={@form}
      disabled={@disabled}
      required={@required}
      aria-hidden="true"
      tabindex="-1"
      style="position:absolute;border:0;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;word-wrap:normal"
    ><option :if={is_nil(@value)} value="" selected=""></option></select>
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
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :rest, :global
  slot :inner_block, required: true

  def select_trigger(assigns) do
    ~H"""
    <button
      data-size={@size}
      class={
        classes([
          "flex w-fit items-center justify-between gap-1.5 rounded-lg border border-input bg-transparent py-2 pr-2 pl-2.5 text-sm whitespace-nowrap transition-colors outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 data-placeholder:text-muted-foreground data-[size=default]:h-8 data-[size=sm]:h-7 data-[size=sm]:rounded-[min(var(--radius-md),10px)] *:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center *:data-[slot=select-value]:gap-1.5 dark:bg-input/30 dark:hover:bg-input/50 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@context.trigger}
      {@rest}
    >{render_slot(@inner_block)}<Icon.icon
      name="chevron-down"
      class="pointer-events-none size-4 text-muted-foreground"
    /></button>
    """
  end

  attr :context, :map, default: nil
  attr :placeholder, :string, default: ""
  slot :inner_block

  def select_value(assigns) do
    ~H"""
    <span data-slot="select-value" style="pointer-events:none"><%= if @inner_block == [] do %>
      {(@context && @context.label) || @placeholder}
    <% else %>
      {render_slot(@inner_block)}
    <% end %></span>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true
  attr :group, :list, default: []

  def select_content(assigns) do
    ~H"""
    <div
      :if={@context.position == "item-aligned"}
      style="display:flex;flex-direction:column;position:fixed"
    >
      <.select_listbox context={@context} option={@option} group={@group} />
    </div>
    <div
      :if={@context.position == "popper"}
      data-radix-popper-content-wrapper=""
      style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:"
      dir={@context.dir}
    >
      <.select_listbox context={@context} option={@option} group={@group} />
    </div>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true
  attr :group, :list, default: []

  defp select_listbox(assigns) do
    assigns =
      assign(assigns, :options_by_group, Enum.group_by(assigns.option, &Map.get(&1, :group)))

    ~H"""
    <div
      role="listbox"
      id={@context.content_id}
      data-state="open"
      dir={@context.dir}
      data-side={if @context.position == "popper", do: @context.side}
      data-align={if @context.position == "popper", do: @context.align}
      data-slot="select-content"
      data-align-trigger={to_string(@context.position == "item-aligned")}
      class={
        classes([
          "cn-menu-target cn-menu-translucent relative z-50 max-h-(--radix-select-content-available-height) min-w-36 origin-(--radix-select-content-transform-origin) overflow-x-hidden overflow-y-auto rounded-lg bg-popover text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[align-trigger=true]:animate-none data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95",
          if(@context.position == "popper",
            do:
              "data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1"
          )
        ])
      }
      style={
        if @context.position == "item-aligned",
          do: "box-sizing:border-box;max-height:100%;display:flex;flex-direction:column;outline:none",
          else:
            "box-sizing:border-box;display:flex;flex-direction:column;outline:none;--radix-select-content-transform-origin:var(--radix-popper-transform-origin);--radix-select-content-available-width:var(--radix-popper-available-width);--radix-select-content-available-height:var(--radix-popper-available-height);--radix-select-trigger-width:var(--radix-popper-anchor-width);--radix-select-trigger-height:var(--radix-popper-anchor-height);animation:none"
      }
      tabindex="-1"
    >
      <style>
        [data-radix-select-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-select-viewport]::-webkit-scrollbar{display:none}
      </style>
      <div
        data-radix-select-viewport=""
        role="presentation"
        data-position={@context.position}
        class="data-[position=popper]:h-(--radix-select-trigger-height) data-[position=popper]:w-full data-[position=popper]:min-w-(--radix-select-trigger-width)"
        style="position:relative;flex:1;overflow:hidden auto"
      >
        <.select_options context={@context} option={Map.get(@options_by_group, nil, [])} />
        <div
          :for={group <- @group}
          role="group"
          aria-labelledby={"radix-" <> @context.id <> "-" <> group.id <> "-label"}
          data-slot="select-group"
          class="scroll-my-1 p-1"
        >
          <div
            id={"radix-" <> @context.id <> "-" <> group.id <> "-label"}
            data-slot="select-label"
            class="px-1.5 py-1 text-xs text-muted-foreground"
          >
            {group.label}
          </div>
          <.select_options context={@context} option={Map.get(@options_by_group, group.id, [])} />
        </div>
      </div>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :option, :list, required: true

  defp select_options(assigns) do
    ~H"""
    <div
      :for={option <- @option}
      id={option.id}
      role="option"
      aria-labelledby={"radix-" <> option.id <> "-text"}
      aria-selected="false"
      data-state={if @context.value == option.value, do: "checked", else: "unchecked"}
      aria-disabled={if Map.get(option, :disabled, false), do: "true"}
      data-disabled={if Map.get(option, :disabled, false), do: ""}
      tabindex={if !Map.get(option, :disabled, false), do: "-1"}
      data-slot="select-item"
      class={
        classes([
          "relative flex w-full cursor-default items-center gap-1.5 rounded-md py-1 pr-8 pl-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground not-data-[variant=destructive]:focus:**:text-accent-foreground data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 *:[span]:last:flex *:[span]:last:items-center *:[span]:last:gap-2",
          Map.get(option, :class)
        ])
      }
      phx-popup-value={option.value}
    >
      <span class="pointer-events-none absolute right-2 flex size-4 items-center justify-center"><span
        :if={@context.value == option.value}
        aria-hidden="true"
      ><Icon.icon name="check" class="pointer-events-none" /></span></span>
      <span id={"radix-" <> option.id <> "-text"}>{render_slot(option)}</span>
    </div>
    """
  end
end
