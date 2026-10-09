defmodule ShadcnLiveview.Components.Combobox do
  @moduledoc "A native editable combobox with caller IDs and explicit selected/open assigns. Input and content named slots receive :let context. Closed content is absent, matching Base UI SSR; LiveView renders and owns the content after the caller handles shadcn:combobox-open with id/open. Pressing the editable input or its trigger opens the options. Handle shadcn:combobox-change with id/value to update selection and the clear affordance; pass input_value for the selected display label. Event names are configurable and route to the nearest phx-target ancestor of the editable input, or the owning LiveView when absent. The colocated hook filters and navigates existing server-owned items; it never copies or reparents slot markup. Group and popup ownership is refreshed after patches to independent roots. Disabling either the root or combobox_input disables the editable input, trigger and clear affordance on every server render. Native name/form, disabled and validation semantics stay on form controls."
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

  @doc "Root is renderless; input/content named slots receive explicit state context."
  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :input_value, :string, default: nil
  attr :name, :string, default: nil
  attr :form, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :open, :boolean, default: false
  attr :on_open_change, :string, default: "shadcn:combobox-open"
  attr :required, :boolean, default: false
  attr :on_change, :string, default: "shadcn:combobox-change"
  attr :rest, :global
  slot :input, required: true
  slot :content, required: true

  def combobox(assigns) do
    context = %{
      id: assigns.id,
      value: assigns.value,
      input_value: assigns.input_value || assigns.value,
      disabled: assigns.disabled,
      open: assigns.open,
      event: assigns.on_change,
      open_event: assigns.on_open_change,
      target: Map.get(assigns.rest, :"phx-target") || Map.get(assigns.rest, "phx-target"),
      list_id: "radix-#{assigns.id}-list",
      popup_id: "radix-#{assigns.id}-popup"
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    {render_slot(@input, @context)}
    {if @open, do: render_slot(@content, @context)}
    <input
      id={is_nil(@name) && @id <> "-hidden-input"}
      disabled={@disabled}
      style={"clip-path:inset(50%);overflow:hidden;white-space:nowrap;border:0;padding:0;width:1px;height:1px;margin:-1px;position:" <> if(@name, do: "absolute", else: "fixed;top:0;left:0")}
      tabindex="-1"
      aria-hidden="true"
      name={@name}
      form={@form}
      required={@required}
      value={@value}
    />
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
  attr :disabled, :boolean, default: false
  attr :show_trigger, :boolean, default: true
  attr :show_clear, :boolean, default: false
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(type placeholder readonly required name form inputmode autocomplete aria-label aria-describedby aria-invalid)

  slot :inner_block

  def combobox_input(assigns) do
    assigns = assign(assigns, :effective_disabled, assigns.disabled || assigns.context.disabled)

    ~H"""
    <div
      data-slot="input-group"
      role="group"
      phx-target={@context.target}
      class={
        classes([
          "group/input-group relative flex h-8 min-w-0 items-center rounded-lg border border-input transition-colors outline-none in-data-[slot=combobox-content]:focus-within:border-inherit in-data-[slot=combobox-content]:focus-within:ring-0 has-disabled:bg-input/50 has-disabled:opacity-50 has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-3 has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50 has-[[data-slot][aria-invalid=true]]:border-destructive has-[[data-slot][aria-invalid=true]]:ring-3 has-[[data-slot][aria-invalid=true]]:ring-destructive/20 has-[>[data-align=block-end]]:h-auto has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-start]]:h-auto has-[>[data-align=block-start]]:flex-col has-[>textarea]:h-auto dark:bg-input/30 dark:has-disabled:bg-input/80 dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40 has-[>[data-align=block-end]]:[&>input]:pt-3 has-[>[data-align=block-start]]:[&>input]:pb-3 has-[>[data-align=inline-end]]:[&>input]:pr-1.5 has-[>[data-align=inline-start]]:[&>input]:pl-1.5 w-auto",
          @class
        ])
      }
    >
      <input
        id={@id}
        data-slot="input-group-control"
        class="h-8 w-full min-w-0 border-input px-2.5 py-1 text-base transition-colors outline-none file:inline-flex file:h-6 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 md:text-sm dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 flex-1 rounded-none border-0 bg-transparent shadow-none ring-0 focus-visible:ring-0 disabled:bg-transparent aria-invalid:ring-0 dark:bg-transparent dark:disabled:bg-transparent"
        data-disabled={@effective_disabled && ""}
        data-list-empty=""
        autocomplete="off"
        spellcheck="false"
        autocorrect="off"
        autocapitalize="none"
        role="combobox"
        aria-expanded={to_string(@context.open)}
        aria-controls={@context.open && @context.list_id}
        aria-haspopup="listbox"
        aria-autocomplete="list"
        disabled={@effective_disabled}
        value={@context.input_value}
        phx-hook=".Combobox"
        phx-value-root={@context.id}
        phx-value-popup-id={@context.popup_id}
        phx-value-selected={@context.value}
        phx-value-event={@context.event}
        phx-value-open-event={@context.open_event}
        phx-value-open={to_string(@context.open)}
        {@rest}
      />
      <div
        role="group"
        data-slot="input-group-addon"
        data-align="inline-end"
        class="flex h-auto cursor-text items-center justify-center gap-2 py-1.5 text-sm font-medium text-muted-foreground select-none group-data-[disabled=true]/input-group:opacity-50 [&>kbd]:rounded-[calc(var(--radius)-5px)] [&>svg:not([class*='size-'])]:size-4 order-last pr-2 has-[>button]:mr-[-0.3rem] has-[>kbd]:mr-[-0.15rem]"
      >
        <button
          :if={@show_trigger}
          id={@context.id}
          type="button"
          data-disabled={@effective_disabled && ""}
          data-list-empty=""
          data-placeholder={@context.value == "" && ""}
          tabindex="0"
          role="combobox"
          aria-expanded={to_string(@context.open)}
          aria-haspopup="dialog"
          disabled={@effective_disabled}
          data-slot="input-group-button"
          data-variant="ghost"
          data-size="icon-xs"
          class="group/button shrink-0 justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 flex items-center gap-2 text-sm shadow-none size-6 rounded-[calc(var(--radius)-3px)] p-0 has-[>svg]:p-0 group-has-data-[slot=combobox-clear]/input-group:hidden data-pressed:bg-transparent"
        ><Icon.icon name="chevron-down" class="pointer-events-none size-4 text-muted-foreground" /></button>
        <.combobox_clear :if={@show_clear && @context.value != ""} disabled={@effective_disabled} />
      </div>
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Combobox">
        export default {
      sendEvent(event, payload, onReply) {
      const target = this.el.closest('[phx-target]')?.getAttribute('phx-target');
      if (target) return this.pushEventTo(target, event, payload, onReply);
      return this.pushEvent(event, payload, onReply);
      },
      mounted() {
      this.group = this.el.closest("[data-slot=input-group]"); this.listeners = []; this.popup = null; this.active = null; this.popupListeners = []; this.query = "";
      this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
      this.listen(document, "click", e => {
        this.group = this.el.closest("[data-slot=input-group]");
        if (!this.group.contains(e.target)) return;
        const clear = e.target.closest("[data-slot=combobox-clear]");
        if (clear && !clear.disabled) { this.commit("", ""); return; }
        const trigger = e.target.closest("[data-slot=input-group-button]");
        if (trigger && !trigger.disabled) { this.requestOpen(this.el.getAttribute("phx-value-open") !== "true"); this.el.focus(); }
      });
      this.listen(document, "phx:update", () => {
        this.group = this.el.closest("[data-slot=input-group]");
        this.syncTrigger();
        if (document.getElementById(this.el.getAttribute("phx-value-popup-id")) !== this.popup) this.bindPopup();
      });
      this.listen(this.el, "pointerdown", () => this.requestOpen(true));
      this.listen(this.el, "input", () => { if (!this.el.readOnly) { this.query = this.el.value; this.requestOpen(true); this.filter(); } });
      this.listen(this.el, "keydown", e => {
        if (this.el.disabled || this.el.readOnly || this.el.hasAttribute("data-disabled") || e.isComposing) return;
        if (["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key)) {
          e.preventDefault();
          if (!this.popup) { this.pendingKey = e.key; this.requestOpen(true); }
          else this.navigate(e.key);
        }
        if (e.key === "Enter" && this.popup && this.active) { e.preventDefault(); this.choose(this.active); }
        if (e.key === "Escape" && this.popup) { e.preventDefault(); this.requestOpen(false); }
        if (e.key === "Tab") this.requestOpen(false);
      });
      this.listen(document, "pointerdown", e => {
        this.group = this.el.closest("[data-slot=input-group]");
        if (!this.group.contains(e.target) && !this.popup?.contains(e.target)) this.requestOpen(false);
      });
      this.listen(window, "resize", () => this.position());
      this.listen(window, "scroll", () => this.position());
      if (this.el.form) this.listen(this.el.form, "reset", () => queueMicrotask(() => {
        this.requestOpen(false); this.commit(this.formInput()?.value || "", this.el.value);
      }));
      this.bindPopup();
      this.syncTrigger();
      },
      syncTrigger() {
      // Base UI starts with popup-input trigger semantics during SSR, then the
      // editable input registers on mount and leaves its auxiliary trigger a button.
      const trigger = this.group.querySelector("[data-slot=input-group-button]");
      if (!trigger) return;
      trigger.removeAttribute("role");
      trigger.setAttribute("tabindex", "-1");
      trigger.setAttribute("aria-haspopup", "listbox");
      trigger.setAttribute("aria-expanded", this.el.getAttribute("aria-expanded"));
      const controls = this.el.getAttribute("aria-controls");
      if (controls) trigger.setAttribute("aria-controls", controls);
      else trigger.removeAttribute("aria-controls");
      },
      formInput() {
      let sibling = this.group.nextElementSibling;
      while (sibling && sibling.tagName !== "INPUT") sibling = sibling.nextElementSibling;
      return sibling;
      },
      requestOpen(open) {
      if (open && (this.el.disabled || this.el.readOnly || this.el.hasAttribute("data-disabled"))) return;
      if (this.requestedOpen === open || (this.requestedOpen === undefined && (this.el.getAttribute("phx-value-open") === "true") === open)) return;
      this.requestedOpen = open;
      const event = this.el.getAttribute("phx-value-open-event");
      if (event) this.sendEvent(event, {id: this.el.getAttribute("phx-value-root"), open});
      },
      unbindPopup() {
      if (this.popup) this.popupListeners.forEach(([type, listener]) => this.popup.removeEventListener(type, listener));
      this.popupListeners = []; this.popup = null; this.active = null;
      this.el.removeAttribute("aria-activedescendant");
      },
      bindPopup() {
      this.unbindPopup();
      this.popup = document.getElementById(this.el.getAttribute("phx-value-popup-id"));
      if (!this.popup) return;
      this.popupListeners = [
        ["pointerdown", e => e.preventDefault()],
        ["click", e => { const item = e.target.closest("[data-slot=combobox-item]"); if (item && !item.hasAttribute("data-disabled") && !item.hidden) this.choose(item); }],
        ["pointermove", e => { const item = e.target.closest("[data-slot=combobox-item]"); if (item && !item.hasAttribute("data-disabled") && !item.hidden) this.highlight(item); }]
      ];
      this.popupListeners.forEach(([type, listener]) => this.popup.addEventListener(type, listener));
      this.position(); this.filter();
      if (this.pendingKey) { this.navigate(this.pendingKey); this.pendingKey = null; }
      },
      position() {
      if (!this.popup) return;
      const rect = this.group.getBoundingClientRect(); const available = window.innerHeight - rect.bottom - 12;
      this.popup.style.position = "fixed"; this.popup.style.zIndex = "50";
      this.popup.style.left = Math.max(4, Math.min(rect.left, window.innerWidth - rect.width - 4)) + "px";
      this.popup.style.top = (rect.bottom + 6) + "px"; this.popup.style.setProperty("--anchor-width", rect.width + "px");
      this.popup.style.setProperty("--available-width", (window.innerWidth - 8) + "px");
      this.popup.style.setProperty("--available-height", Math.max(80, available) + "px");
      this.popup.style.setProperty("--transform-origin", "top left");
      },
      available() { return this.popup ? Array.from(this.popup.querySelectorAll("[data-slot=combobox-item]")).filter(item => !item.hidden && !item.hasAttribute("data-disabled")) : []; },
      navigate(key) {
      const items = this.available(); if (!items.length) return;
      const current = items.indexOf(this.active);
      const index = key === "Home" ? 0 : key === "End" ? items.length - 1 : key === "ArrowDown" ? (current + 1) % items.length : current <= 0 ? items.length - 1 : current - 1;
      this.highlight(items[index]);
      },
      filter() {
      if (!this.popup) return;
      const query = this.query.toLocaleLowerCase().trim(); let count = 0;
      this.popup.querySelectorAll("[data-slot=combobox-item]").forEach(item => {
        item.hidden = !item.textContent.toLocaleLowerCase().includes(query); if (!item.hidden) count++;
      });
      this.popup.toggleAttribute("data-empty", count === 0);
      this.popup.querySelectorAll("[data-slot=combobox-empty]").forEach(empty => { empty.style.display = count === 0 ? "flex" : "none"; });
      this.popup.querySelectorAll("[data-slot=combobox-group]").forEach(group => { group.hidden = !Array.from(group.querySelectorAll("[data-slot=combobox-item]")).some(item => !item.hidden); });
      this.highlight(null);
      },
      highlight(item) {
      this.active = item;
      this.popup?.querySelectorAll("[data-slot=combobox-item]").forEach(node => node.toggleAttribute("data-highlighted", node === item));
      if (item) { this.el.setAttribute("aria-activedescendant", item.id); item.scrollIntoView({block: "nearest"}); }
      else this.el.removeAttribute("aria-activedescendant");
      },
      choose(item) {
      const label = Array.from(item.childNodes).filter(node => !(node.nodeType === Node.ELEMENT_NODE && node.matches("span.pointer-events-none.absolute"))).map(node => node.textContent).join("").trim();
      this.commit(item.getAttribute("phx-value-value") || "", label);
      },
      commit(value, label) {
      this.query = "";
      this.el.value = label;
      const hidden = this.formInput(); if (hidden) { hidden.value = value; hidden.dispatchEvent(new Event("input", {bubbles: true})); hidden.dispatchEvent(new Event("change", {bubbles: true})); }
      const detail = {id: this.el.getAttribute("phx-value-root"), value};
      this.el.dispatchEvent(new CustomEvent("shadcn:combobox-change", {bubbles: true, detail}));
      const event = this.el.getAttribute("phx-value-event"); if (event) this.sendEvent(event, detail);
      this.requestOpen(false); this.el.focus();
      },
      updated() {
      this.requestedOpen = undefined;
      this.group = this.el.closest("[data-slot=input-group]");
      this.bindPopup();
      this.syncTrigger();
      },
      destroyed() {
      this.unbindPopup();
      this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler));
      }
      }
    </script>
    """
  end

  attr :disabled, :boolean, default: false

  defp combobox_clear(assigns) do
    ~H"""
    <button
      data-slot="combobox-clear"
      data-variant="ghost"
      data-size="icon-xs"
      class="group/button shrink-0 justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 flex items-center gap-2 text-sm shadow-none size-6 rounded-[calc(var(--radius)-3px)] p-0 has-[>svg]:p-0"
      type="button"
      data-disabled={@disabled && ""}
      data-visible=""
      tabindex="-1"
      disabled={@disabled}
    ><Icon.icon name="x" class="pointer-events-none" /></button>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_content(assigns) do
    ~H"""
    <div
      id={@context.popup_id}
      data-slot="combobox-content"
      data-chips="false"
      data-side="bottom"
      class={
        classes([
          "cn-menu-target cn-menu-translucent group/combobox-content relative max-h-(--available-height) w-(--anchor-width) max-w-(--available-width) min-w-[calc(var(--anchor-width)+--spacing(7))] origin-(--transform-origin) overflow-hidden rounded-lg bg-popover text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[chips=true]:min-w-(--anchor-width) data-[side=bottom]:slide-in-from-top-2 data-[side=inline-end]:slide-in-from-left-2 data-[side=inline-start]:slide-in-from-right-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 *:data-[slot=input-group]:m-1 *:data-[slot=input-group]:mb-0 *:data-[slot=input-group]:h-8 *:data-[slot=input-group]:border-input/30 *:data-[slot=input-group]:bg-input/30 *:data-[slot=input-group]:shadow-none data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_list(assigns) do
    ~H"""
    <div
      id={@context.list_id}
      data-slot="combobox-list"
      role="listbox"
      class={
        classes([
          "no-scrollbar max-h-[min(calc(--spacing(72)---spacing(9)),calc(var(--available-height)---spacing(9)))] scroll-py-1 overflow-y-auto overscroll-contain p-1 data-empty:p-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_item(assigns) do
    ~H"""
    <div
      id={"radix-#{@context.id}-item-#{URI.encode(@value)}"}
      data-slot="combobox-item"
      role="option"
      aria-selected={to_string(@context.value == @value)}
      data-disabled={@disabled && ""}
      aria-disabled={to_string(@disabled)}
      phx-value-value={@value}
      class={
        classes([
          "relative flex w-full cursor-default items-center gap-2 rounded-md py-1 pr-8 pl-1.5 text-sm outline-hidden select-none data-highlighted:bg-accent data-highlighted:text-accent-foreground not-data-[variant=destructive]:data-highlighted:**:text-accent-foreground data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        hidden={@context.value != @value}
        class="pointer-events-none absolute right-2 flex size-4 items-center justify-center"
      ><Icon.icon name="check" class="pointer-events-none" /></span>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_group(assigns) do
    ~H"""
    <div data-slot="combobox-group" class={classes(["", @class])} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_label(assigns) do
    ~H"""
    <div
      data-slot="combobox-label"
      class={classes(["px-2 py-1.5 text-xs text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_empty(assigns) do
    ~H"""
    <div
      data-slot="combobox-empty"
      class={
        classes([
          "hidden w-full justify-center py-2 text-center text-sm text-muted-foreground group-data-empty/combobox-content:flex",
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
  attr :rest, :global

  def combobox_separator(assigns) do
    ~H"""
    <div
      data-slot="combobox-separator"
      role="separator"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      {@rest}
    />
    """
  end
end
