defmodule ShadcnLiveview.Components.Menubar do
  @moduledoc """
  An accessible menubar with explicit, instance-local slot contexts.

  Pass the root's :let context to each menu, then the menu's trigger/content
  slot context to its primitives. LiveView owns portal mounting: handle
  on_value_change by assigning value from the %{id, value} event payload.
  default_value only supplies initial selection. The hook positions mounted
  content, implements keyboard focus and requests state changes without HTML
  serialization. Submenus similarly use open and on_open_change.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  import ShadcnLiveview.Components.Icon, only: [icon: 1]

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :default_value, :string, default: ""
  attr :dir, :string, default: "ltr", values: ["ltr", "rtl"]
  attr :loop, :boolean, default: true
  attr :on_value_change, :string, default: "shadcn:menubar-change"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders a horizontal menu bar and yields its selection context."
  def menubar(assigns) do
    value = if is_nil(assigns.value), do: assigns.default_value, else: assigns.value
    assigns = assign(assigns, selected: value, context: %{value: value, dir: assigns.dir})

    ~H"""
    <div
      id={@id}
      role="menubar"
      data-slot="menubar"
      tabindex="-1"
      data-orientation="horizontal"
      style="outline:none"
      class={classes(["flex h-8 items-center gap-0.5 rounded-lg border p-[3px]", @class])}
      phx-hook=".Menubar"
      phx-value={@selected}
      phx-dir={@dir}
      phx-change-event={@on_value_change}
      phx-loop={to_string(@loop)}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Menubar">
      export default {
        mounted() {
          this.pendingFocus = null;
          this.click = e => {
            const trigger = e.target.closest('[data-slot="menubar-trigger"]');
            if (trigger && this.el.contains(trigger)) {
              if (!trigger.disabled) this.change(trigger.dataset.state === "open" ? "" : trigger.getAttribute("phx-menu-value"), false);
              return;
            }
            if (!this.owns(e.target)) return;
            const item = e.target.closest('[role^="menuitem"]');
            if (!item || item.hasAttribute("data-disabled")) return;
            if (item.dataset.slot === "menubar-sub-trigger") { this.submenu(item, true, false); return; }
            if (item.getAttribute("role") === "menuitemcheckbox") this.pushEvent(item.getAttribute("phx-change-event"), {id: item.id, value: item.getAttribute("aria-checked") !== "true"});
            if (item.getAttribute("role") === "menuitemradio") {
              const group = item.closest('[data-slot="menubar-radio-group"]');
              this.pushEvent(group.getAttribute("phx-change-event"), {id: group.id, value: item.getAttribute("phx-value")});
            }
            this.change("", false);
            this.activeTrigger?.focus();
          };
          this.pointer = e => {
            const trigger = e.target.closest('[data-slot="menubar-trigger"]');
            if (trigger && this.el.contains(trigger) && !trigger.disabled && this.value && this.value !== trigger.getAttribute("phx-menu-value")) this.change(trigger.getAttribute("phx-menu-value"), false);
            if (!this.owns(e.target)) return;
            const item = e.target.closest('[role^="menuitem"]');
            if (!item || item.hasAttribute("data-disabled")) return;
            item.focus();
            const menu = item.closest('[role="menu"]');
            for (const sibling of menu.querySelectorAll('[data-slot="menubar-sub-trigger"][aria-expanded="true"]')) {
              if (sibling !== item && sibling.closest('[role="menu"]') === menu) this.submenu(sibling, false, false);
            }
            if (item.dataset.slot === "menubar-sub-trigger" && item.getAttribute("aria-expanded") === "false") this.submenu(item, true, false);
          };
          this.outside = e => { if (!this.el.contains(e.target) && this.value) this.change("", false); };
          this.focus = e => {
            for (const trigger of this.triggers()) {
              if (trigger === e.target) { trigger.setAttribute("data-highlighted", ""); this.tabstop(trigger); }
              else trigger.removeAttribute("data-highlighted");
            }
          };
          this.key = e => this.keydown(e);
          this.layout = () => this.positionMenus();
          document.addEventListener("click", this.click);
          document.addEventListener("pointerover", this.pointer);
          document.addEventListener("pointerdown", this.outside);
          document.addEventListener("keydown", this.key);
          document.addEventListener("focusin", this.focus);
          window.addEventListener("resize", this.layout);
          document.addEventListener("scroll", this.layout, true);
          this.sync();
        },
        triggers() { return [...this.el.querySelectorAll('[data-slot="menubar-trigger"]')]; },
        owns(target) { return this.el.contains(target) && !!target.closest('[role="menu"]'); },
        tabstop(trigger) { this.triggers().forEach(t => t.tabIndex = t === trigger && !t.disabled ? 0 : -1); },
        change(value, keyboard) {
          if (value !== this.value) {
            for (const sub of this.el.querySelectorAll('[data-slot="menubar-sub-trigger"][aria-expanded="true"]')) this.submenu(sub, false, false);
          }
          this.pendingFocus = keyboard ? this.triggers().find(t => t.getAttribute("phx-menu-value") === value)?.getAttribute("phx-content-id") : null;
          this.pushEvent(this.el.getAttribute("phx-change-event"), {id: this.el.id, value});
        },
        sync() {
          this.value = this.el.getAttribute("phx-value") || "";
          const triggers = this.triggers();
          this.activeTrigger = triggers.find(t => t.getAttribute("phx-menu-value") === this.value) || this.activeTrigger;
          this.tabstop(triggers.find(t => t === document.activeElement && !t.disabled) || this.activeTrigger || triggers.find(t => !t.disabled));
          this.positionMenus();
          if (this.pendingFocus) {
            const menu = document.getElementById(this.pendingFocus);
            if (menu && this.el.contains(menu)) { this.menuItems(menu)[0]?.focus(); this.pendingFocus = null; }
          }
        },
        positionMenus() {
          for (const menu of this.el.querySelectorAll('[role="menu"]')) {
            const anchor = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (anchor) this.position(menu, anchor);
          }
        },
        position(menu, anchor) {
          const overlay = menu.parentElement;
          const box = anchor.getBoundingClientRect();
          const sub = anchor.dataset.slot === "menubar-sub-trigger";
          const sideOffset = Number(menu.getAttribute("phx-side-offset") || (sub ? 0 : 8));
          const alignOffset = Number(menu.getAttribute("phx-align-offset") || (sub ? 0 : -4));
          const rtl = this.el.getAttribute("phx-dir") === "rtl";
          overlay.style.position = "fixed";
          overlay.style.transform = "none";
          let left = sub ? (rtl ? box.left - overlay.offsetWidth - sideOffset : box.right + sideOffset) : box.left + alignOffset;
          let top = sub ? box.top : box.bottom + sideOffset;
          let side = sub ? (rtl ? "left" : "right") : (menu.getAttribute("phx-side") || "bottom");
          if (!sub && side === "top") top = box.top - overlay.offsetHeight - sideOffset;
          if (!sub && side === "left") { left = box.left - overlay.offsetWidth - sideOffset; top = box.top; }
          if (!sub && side === "right") { left = box.right + sideOffset; top = box.top; }
          if (!sub && (side === "top" || side === "bottom")) {
            const offset = rtl ? -alignOffset : alignOffset;
            const end = (menu.dataset.align === "end") !== rtl;
            left = end ? box.right - overlay.offsetWidth + offset : box.left + offset;
            if (menu.dataset.align === "center") left = box.left + (box.width - overlay.offsetWidth) / 2 + offset;
          } else if (!sub) {
            top = box.top + alignOffset;
            if (menu.dataset.align === "end") top = box.bottom - overlay.offsetHeight + alignOffset;
            if (menu.dataset.align === "center") top = box.top + (box.height - overlay.offsetHeight) / 2 + alignOffset;
          }
          if (side === "bottom" && top + overlay.offsetHeight > window.innerHeight && box.top > overlay.offsetHeight) { top = box.top - overlay.offsetHeight - sideOffset; side = "top"; }
          if (side === "right" && left + overlay.offsetWidth > window.innerWidth && box.left > overlay.offsetWidth) { left = box.left - overlay.offsetWidth - sideOffset; side = "left"; }
          if (side === "left" && left < 0 && window.innerWidth - box.right > overlay.offsetWidth) { left = box.right + sideOffset; side = "right"; }
          left = Math.max(4, Math.min(left, window.innerWidth - overlay.offsetWidth - 4));
          top = Math.max(4, Math.min(top, window.innerHeight - overlay.offsetHeight - 4));
          overlay.style.left = left + "px";
          overlay.style.top = top + "px";
          menu.dataset.side = side;
          menu.style.setProperty("--radix-popper-transform-origin", side === "top" ? "bottom left" : "top left");
          menu.style.setProperty("--radix-popper-available-width", window.innerWidth + "px");
          menu.style.setProperty("--radix-popper-available-height", Math.max(0, window.innerHeight - top) + "px");
          menu.style.setProperty("--radix-popper-anchor-width", box.width + "px");
          menu.style.setProperty("--radix-popper-anchor-height", box.height + "px");
        },
        menuItems(menu) { return [...menu.querySelectorAll('[role^="menuitem"]')].filter(i => !i.hasAttribute("data-disabled") && i.closest('[role="menu"]') === menu); },
        submenu(trigger, open, keyboard) {
          this.pendingFocus = open && keyboard ? trigger.getAttribute("phx-content-id") : null;
          this.pushEvent(trigger.getAttribute("phx-change-event"), {id: trigger.getAttribute("phx-sub-id"), value: open});
        },
        keydown(e) {
          const trigger = e.target.closest('[data-slot="menubar-trigger"]');
          if (trigger && this.el.contains(trigger) && !trigger.disabled) {
            if (["Enter", " ", "ArrowDown"].includes(e.key)) {
              e.preventDefault();
              const close = e.key !== "ArrowDown" && trigger.getAttribute("aria-expanded") === "true";
              this.change(close ? "" : trigger.getAttribute("phx-menu-value"), !close);
              return;
            }
            if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) { e.preventDefault(); this.moveTrigger(trigger, e.key, false); }
            return;
          }
          if (!this.owns(e.target)) return;
          const menu = e.target.closest('[role="menu"]');
          const items = this.menuItems(menu);
          if (e.key === "Tab") { this.change("", false); return; }
          if (e.key === "Escape") {
            e.preventDefault();
            const parent = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (parent?.dataset.slot === "menubar-sub-trigger") { this.submenu(parent, false, false); parent.focus(); }
            else { this.change("", false); this.activeTrigger?.focus(); }
            return;
          }
          if (["ArrowLeft", "ArrowRight"].includes(e.key)) {
            e.preventDefault();
            const forward = (e.key === "ArrowRight") !== (this.el.getAttribute("phx-dir") === "rtl");
            if (forward && e.target.dataset.slot === "menubar-sub-trigger") { this.submenu(e.target, true, true); return; }
            const parent = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (!forward && parent?.dataset.slot === "menubar-sub-trigger") { this.submenu(parent, false, false); parent.focus(); return; }
            this.moveTrigger(this.activeTrigger, e.key, true); return;
          }
          if (["Enter", " "].includes(e.key)) { e.preventDefault(); e.target.click(); return; }
          let target;
          if (e.key === "Home") target = items[0];
          else if (e.key === "End") target = items.at(-1);
          else if (e.key === "ArrowDown" || e.key === "ArrowUp") target = items[(items.indexOf(e.target) + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length];
          else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
            clearTimeout(this.typeTimer);
            this.search = (this.search || "") + e.key.toLowerCase();
            if ([...this.search].every(character => character === this.search[0])) this.search = this.search[0];
            this.typeTimer = setTimeout(() => this.search = "", 700);
            target = [...items.slice(items.indexOf(e.target) + 1), ...items].find(i => i.textContent.trim().toLowerCase().startsWith(this.search));
          } else return;
          e.preventDefault(); target?.focus();
        },
        moveTrigger(trigger, key, open) {
          const items = this.triggers().filter(t => !t.disabled);
          let index = key === "Home" ? 0 : key === "End" ? items.length - 1 : items.indexOf(trigger) + (((key === "ArrowRight") !== (this.el.getAttribute("phx-dir") === "rtl")) ? 1 : -1);
          if (this.el.getAttribute("phx-loop") === "true") index = (index + items.length) % items.length;
          const next = items[index];
          if (next) { this.tabstop(next); next.focus(); if (open) this.change(next.getAttribute("phx-menu-value"), true); }
        },
        updated() { this.sync(); },
        destroyed() {
          clearTimeout(this.typeTimer);
          document.removeEventListener("click", this.click);
          document.removeEventListener("pointerover", this.pointer);
          document.removeEventListener("pointerdown", this.outside);
          document.removeEventListener("keydown", this.key);
          document.removeEventListener("focusin", this.focus);
          window.removeEventListener("resize", this.layout);
          document.removeEventListener("scroll", this.layout, true);
        }
      }
    </script>
    """
  end

  attr :id, :string, required: true
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :trigger_id, :string, default: nil
  attr :content_id, :string, default: nil
  slot :trigger, required: true
  slot :content, required: true

  @doc "Connects trigger and portal content through a stable caller-owned menu ID."
  def menubar_menu(assigns) do
    context = %{
      value: assigns.value,
      open: assigns.context.value == assigns.value,
      dir: assigns.context.dir,
      trigger_id: assigns.trigger_id || "radix-#{assigns.id}-trigger",
      content_id: assigns.content_id || "radix-#{assigns.id}-content"
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @context.open do %>
      {render_slot(@content, @context)}
    <% end %>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_trigger(assigns) do
    ~H"""
    <button
      id={@id || @context.trigger_id}
      type="button"
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.content_id}
      data-state={if @context.open, do: "open", else: "closed"}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      data-slot="menubar-trigger"
      tabindex="-1"
      data-orientation="horizontal"
      class={
        classes([
          "flex items-center rounded-sm px-1.5 py-[2px] text-sm font-medium outline-hidden select-none hover:bg-muted aria-expanded:bg-muted",
          @class
        ])
      }
      phx-menu-value={@context.value}
      phx-content-id={@context.content_id}
      {@rest}
    >{render_slot(@inner_block)}</button>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :align, :string, default: "start"
  attr :side, :string, default: "bottom"
  attr :side_offset, :integer, default: 8
  attr :align_offset, :integer, default: -4
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_content(assigns) do
    ~H"""
    <div
      data-radix-popper-content-wrapper=""
      style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:"
      dir={@context.dir}
    >
      <div
        id={@id || @context.content_id}
        data-side={@side}
        data-align={@align}
        role="menu"
        aria-orientation="vertical"
        data-state="open"
        data-radix-menu-content=""
        dir={@context.dir}
        aria-labelledby={@context.trigger_id}
        data-radix-menubar-content=""
        data-slot="menubar-content"
        class={
          classes([
            "cn-menu-target cn-menu-translucent z-50 min-w-36 origin-(--radix-menubar-content-transform-origin) overflow-hidden rounded-lg bg-popover p-1 text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95",
            @class
          ])
        }
        style="outline:none;--radix-menubar-content-transform-origin:var(--radix-popper-transform-origin);--radix-menubar-content-available-width:var(--radix-popper-available-width);--radix-menubar-content-available-height:var(--radix-popper-available-height);--radix-menubar-trigger-width:var(--radix-popper-anchor-width);--radix-menubar-trigger-height:var(--radix-popper-anchor-height);animation:none"
        tabindex="-1"
        data-orientation="vertical"
        phx-side={@side}
        phx-side-offset={@side_offset}
        phx-align-offset={@align_offset}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :variant, :string, default: "default", values: ["default", "destructive"]
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_item(assigns) do
    ~H"""
    <div
      role="menuitem"
      data-slot="menubar-item"
      data-inset={inset_value(@inset)}
      data-variant={@variant}
      aria-disabled={if @disabled, do: "true"}
      data-disabled={if @disabled, do: ""}
      tabindex="-1"
      data-orientation="vertical"
      class={
        classes([
          "group/menubar-item relative flex cursor-default items-center gap-1.5 rounded-md px-1.5 py-1 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground not-data-[variant=destructive]:focus:**:text-accent-foreground data-inset:pl-7 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 data-[variant=destructive]:*:[svg]:text-destructive!",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp inset_value(nil), do: nil
  defp inset_value(value), do: to_string(value)

  attr :id, :string, required: true
  attr :checked, :any, default: false
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :on_checked_change, :string, default: "shadcn:menu-check-change"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_checkbox_item(assigns) do
    assigns =
      assign(assigns,
        state:
          if(assigns.checked == "indeterminate",
            do: "indeterminate",
            else: if(assigns.checked, do: "checked", else: "unchecked")
          )
      )

    ~H"""
    <div
      id={@id}
      role="menuitemcheckbox"
      aria-checked={if @checked == "indeterminate", do: "mixed", else: to_string(@checked)}
      data-state={@state}
      aria-disabled={if @disabled, do: "true"}
      data-disabled={if @disabled, do: ""}
      data-slot="menubar-checkbox-item"
      data-inset={inset_value(@inset)}
      tabindex="-1"
      data-orientation="vertical"
      class={
        classes([
          "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-1.5 pl-7 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none [&_svg]:pointer-events-none [&_svg]:shrink-0",
          @class
        ])
      }
      phx-change-event={@on_checked_change}
      {@rest}
    >
      <span class="pointer-events-none absolute left-1.5 flex size-4 items-center justify-center [&_svg:not([class*='size-'])]:size-4"><span
        :if={@checked}
        data-state={@state}
      ><.icon name="check" /></span></span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :on_value_change, :string, default: "shadcn:menu-radio-change"
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_radio_group(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      data-slot="menubar-radio-group"
      phx-change-event={@on_value_change}
      {@rest}
    >
      {render_slot(@inner_block, %{value: @value})}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_radio_item(assigns) do
    assigns = assign(assigns, checked: assigns.context.value == assigns.value)

    ~H"""
    <div
      id={@id}
      role="menuitemradio"
      aria-checked={to_string(@checked)}
      data-state={if @checked, do: "checked", else: "unchecked"}
      aria-disabled={if @disabled, do: "true"}
      data-disabled={if @disabled, do: ""}
      data-slot="menubar-radio-item"
      data-inset={inset_value(@inset)}
      tabindex="-1"
      data-orientation="vertical"
      class={
        classes([
          "relative flex cursor-default items-center gap-1.5 rounded-md py-1 pr-1.5 pl-7 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground focus:**:text-accent-foreground data-inset:pl-7 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      phx-value={@value}
      {@rest}
    >
      <span class="pointer-events-none absolute left-1.5 flex size-4 items-center justify-center [&_svg:not([class*='size-'])]:size-4"><span
        :if={@checked}
        data-state="checked"
      ><.icon name="check" /></span></span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :dir, :string, default: "ltr"
  attr :open, :boolean, default: false
  attr :on_open_change, :string, default: "shadcn:menubar-sub-change"
  slot :trigger, required: true
  slot :content, required: true

  def menubar_sub(assigns) do
    assigns =
      assign(assigns, :context, %{
        id: assigns.id,
        open: assigns.open,
        on_open_change: assigns.on_open_change,
        trigger_id: "radix-#{assigns.id}-trigger",
        content_id: "radix-#{assigns.id}-content",
        dir: assigns.dir
      })

    ~H"""
    {render_slot(@trigger, @context)}
    <%= if @open do %>
      {render_slot(@content, @context)}
    <% end %>
    """
  end

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :inset, :boolean, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_sub_trigger(assigns) do
    ~H"""
    <div
      id={@context.trigger_id}
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: @context.content_id}
      data-state={if @context.open, do: "open", else: "closed"}
      aria-disabled={if @disabled, do: "true"}
      data-disabled={if @disabled, do: ""}
      data-radix-menubar-subtrigger=""
      data-slot="menubar-sub-trigger"
      data-inset={inset_value(@inset)}
      tabindex="-1"
      data-orientation="vertical"
      class={
        classes([
          "flex cursor-default items-center gap-1.5 rounded-md px-1.5 py-1 text-sm outline-none select-none focus:bg-accent focus:text-accent-foreground data-inset:pl-7 data-open:bg-accent data-open:text-accent-foreground [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      phx-content-id={@context.content_id}
      phx-sub-id={@context.id}
      phx-change-event={@context.on_open_change}
      {@rest}
    >
      {render_slot(@inner_block)}<.icon name="chevron-right" class="cn-rtl-flip ml-auto size-4" />
    </div>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_sub_content(assigns) do
    ~H"""
    <div
      data-radix-popper-content-wrapper=""
      style="position:fixed;left:0;top:0;transform:translate(0, -200%);min-width:max-content;--radix-popper-transform-origin:"
      dir={@context.dir}
    >
      <div
        id={@context.content_id}
        role="menu"
        aria-orientation="vertical"
        aria-labelledby={@context.trigger_id}
        data-side={if @context.dir == "rtl", do: "left", else: "right"}
        data-align="start"
        data-state="open"
        data-radix-menu-content=""
        data-radix-menubar-content=""
        dir={@context.dir}
        data-slot="menubar-sub-content"
        tabindex="-1"
        data-orientation="vertical"
        style="outline:none;--radix-menubar-content-transform-origin:var(--radix-popper-transform-origin);--radix-menubar-content-available-width:var(--radix-popper-available-width);--radix-menubar-content-available-height:var(--radix-popper-available-height);--radix-menubar-trigger-width:var(--radix-popper-anchor-width);--radix-menubar-trigger-height:var(--radix-popper-anchor-height);animation:none"
        class={
          classes([
            "cn-menu-target cn-menu-translucent z-50 min-w-32 origin-(--radix-menubar-content-transform-origin) overflow-hidden rounded-lg bg-popover p-1 text-popover-foreground shadow-lg ring-1 ring-foreground/10 duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  slot :inner_block

  def menubar_portal(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global
  slot :inner_block

  def menubar_group(assigns) do
    ~H"""
    <div data-slot="menubar-group" role="group" class={classes(["", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :inset, :boolean, default: nil
  attr :rest, :global
  slot :inner_block

  def menubar_label(assigns) do
    ~H"""
    <div
      data-slot="menubar-label"
      data-inset={@inset}
      class={classes(["px-1.5 py-1 text-sm font-medium data-inset:pl-7", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global
  slot :inner_block

  def menubar_separator(assigns) do
    ~H"""
    <div
      data-slot="menubar-separator"
      role="separator"
      aria-orientation="horizontal"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global
  slot :inner_block

  def menubar_shortcut(assigns) do
    ~H"""
    <span
      data-slot="menubar-shortcut"
      class={
        classes([
          "ml-auto text-xs tracking-widest text-muted-foreground group-focus/menubar-item:text-accent-foreground",
          @class
        ])
      }
      {@rest}
    >{render_slot(@inner_block)}</span>
    """
  end
end
