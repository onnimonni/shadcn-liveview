defmodule ShadcnLiveview.Components.Sidebar do
  @moduledoc """
  Sidebar provider exposes its state through `:let={sidebar}`; pass that context
  to the sidebar and its trigger/rail. Require unique IDs on providers and sidebar
  containers. `open` and `mobile_open` are caller-owned server state. The hook
  emits `shadcn:sidebar-change` with the provider ID for desktop and its ID plus
  `-mobile` for the drawer, and handles scoped Ctrl/Meta+B, cookies and focus.
  Upstream always renders desktop markup during SSR because its media-query hook
  initializes false; mobile behavior is installed only after mounting. The same
  children become the mobile dialog without hidden duplicate content or IDs.
  Nested primitives accept caller classes and global attributes. Use `tag="a"`
  on menu/group buttons for link composition instead of a React asChild wrapper;
  `navigate` or `patch` on menu and sub buttons renders `Phoenix.Component.link/1`.
  Hook events honor phx-target on the root or nearest containing element,
  including internal state changes and completion acknowledgements.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :open, :boolean, default: true
  attr :mobile_open, :boolean, default: false
  attr :width, :string, default: "16rem"
  attr :icon_width, :string, default: "3rem"
  attr :style, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_provider(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, open: assigns.open})

    ~H"""
    <div
      id={@id}
      data-slot="sidebar-wrapper"
      class={
        classes([
          "group/sidebar-wrapper flex min-h-svh w-full has-data-[variant=inset]:bg-sidebar",
          @class
        ])
      }
      style={"--sidebar-width:" <> @width <> ";--sidebar-width-icon:" <> @icon_width <> if(@style, do: ";" <> @style, else: "")}
      phx-hook=".Sidebar"
      phx-value-open={to_string(@open)}
      phx-value-mobile-open={to_string(@mobile_open)}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Sidebar">
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
            const container = this.containers()[0]; if (!container) return;
            // Escape belongs to the innermost layer: a popup opened from the sheet closes first (it marks
            // the event handled when focused; otherwise its own document listener closes it).
            if (event.key === "Escape" && !event.defaultPrevented && !this.popups(container).length) { event.preventDefault(); this.closeMobile(); }
            if (event.key === "Tab") {
              const targets = [...container.querySelectorAll('button:not(:disabled),a[href],input:not(:disabled),select:not(:disabled),textarea:not(:disabled),[tabindex="0"]')].filter(node => node.getClientRects().length);
              const first = targets[0] || container, last = targets[targets.length-1] || container;
              if (event.shiftKey && (document.activeElement === first || document.activeElement === container)) { event.preventDefault(); last.focus(); }
              else if (!event.shiftKey && (document.activeElement === last || !this.owns(container, document.activeElement))) { event.preventDefault(); first.focus(); }
            }
          });
          on(this.media,"change",() => { this.closeMobile(); this.paint(); });
          this.paint();
        },
        roots() { return [...this.el.querySelectorAll('[data-slot="sidebar"]')].filter(node => node.closest('[data-slot="sidebar-wrapper"]') === this.el && node.hasAttribute("data-collapsible")); },
        containers() { return this.roots().map(root => root.querySelector('[data-slot="sidebar-container"]')); },
        // Open popup contents whose triggers live in the sheet; their focus counts as inside the sheet.
        popups(container) { return [...container.querySelectorAll("[phx-popup-content-id]")].map(trigger => document.getElementById(trigger.getAttribute("phx-popup-content-id"))).filter(Boolean); },
        owns(container, node) { return Boolean(node) && node !== document.body && (container.contains(node) || this.popups(container).some(content => content.contains(node))); },
        closeMobile() {
          if (!this.mobileOpen) return;
          this.mobileOpen = false; this.sendEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:false}); this.paint();
        },
        toggle(trigger) {
          if (this.media.matches) {
            this.returnFocus = trigger; this.mobileOpen = !this.mobileOpen;
            if(this.mobileOpen) document.dispatchEvent(new CustomEvent("sidebar:mobile-open",{detail:{id:this.el.id}}));
            this.sendEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:this.mobileOpen});
          } else {
            this.open = !this.open; document.cookie = "sidebar_state=" + this.open + "; path=/; max-age=604800";
            this.sendEvent("shadcn:sidebar-change", {id:this.el.id,open:this.open});
          }
          this.paint(); this.el.dispatchEvent(new CustomEvent("sidebar:change", {detail:{open:this.open, mobileOpen:this.mobileOpen},bubbles:true}));
        },
        paint() {
          const mobile = this.media.matches;
          (this.inertNodes || []).forEach(node => node.removeAttribute("inert")); this.inertNodes = [];
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
              if (!this.open && mode === "offcanvas") this.hideOffcanvas(container);
            }
          });
          this.el.querySelectorAll('[data-sidebar="trigger"],[data-sidebar="rail"]').forEach(trigger => {
            if (trigger.closest('[data-slot="sidebar-wrapper"]') !== this.el) return;
            const target = this.containers()[0]; if (target) trigger.setAttribute("aria-controls",target.id);
            trigger.setAttribute("aria-expanded",String(mobile ? this.mobileOpen : this.open));
            // Upstream's trigger has no expanded state, so its ghost button never paints aria-expanded:* styles.
            if (trigger.dataset.sidebar === "trigger") trigger.classList.remove(...[...trigger.classList].filter(name => name.startsWith("aria-expanded:")));
          });
          const opening = mobile && this.mobileOpen && !this.backdrop;
          if (opening) {
            // Upstream renders the mobile sidebar inside a Sheet; reuse its overlay styles.
            this.backdrop = document.createElement("div"); this.backdrop.dataset.state = "open";
            this.backdrop.className = "fixed inset-0 z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0";
            this.backdrop.addEventListener("click",() => this.closeMobile(),{signal:this.abort.signal});
            this.el.append(this.backdrop);
            this.locked = true; this.previousOverflow = document.body.style.overflow; document.body.style.overflow = "hidden";
          } else if (mobile && this.mobileOpen && !this.backdrop.isConnected) {
            this.el.append(this.backdrop);
          } else if ((!mobile || !this.mobileOpen) && this.backdrop) {
            this.backdrop.remove(); this.backdrop=null; this.unlock(); this.returnFocus?.focus();
          }
          if (mobile && this.mobileOpen) {
            // Focus the sheet when it opens or when a patch dropped focus to the body; never take
            // focus from the sheet's own popups or from other layers opened on top of it.
            const container = this.containers()[0], active = document.activeElement;
            if (container && (opening || !active || active === document.body) && !this.owns(container, active)) container.focus();
          }
        },
        hideOffcanvas(container) {
          // A collapsed offcanvas sidebar sits off-screen: keep its contents out of the tab order and
          // accessibility tree. The rail stays live because it peeks in from the edge to expand it.
          const rails = [...container.querySelectorAll('[data-sidebar="rail"]')];
          if (container.contains(document.activeElement) && !rails.includes(document.activeElement)) {
            const trigger = [...this.el.querySelectorAll('[data-sidebar="trigger"]')].find(node => node.closest('[data-slot="sidebar-wrapper"]') === this.el && !container.contains(node) && node.getClientRects().length);
            trigger ? trigger.focus() : document.activeElement.blur();
          }
          const hide = node => [...node.children].forEach(child => {
            if (rails.includes(child)) return;
            if (rails.some(rail => child.contains(rail))) hide(child);
            else if (!child.hasAttribute("inert")) { child.setAttribute("inert",""); this.inertNodes.push(child); }
          });
          hide(container);
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

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :sidebar, :map, required: true
  attr :side, :string, default: "left", values: ~w(left right)
  attr :variant, :string, default: "sidebar", values: ~w(sidebar floating inset)
  attr :collapsible, :string, default: "offcanvas", values: ~w(offcanvas icon none)

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar(assigns) do
    assigns = assign(assigns, :floating, assigns.variant in ["floating", "inset"])

    ~H"""
    <div
      :if={@collapsible == "none"}
      id={@id}
      data-slot="sidebar"
      class={
        classes([
          "flex h-full w-(--sidebar-width) flex-col bg-sidebar text-sidebar-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block, @sidebar)}
    </div>
    <div
      :if={@collapsible != "none"}
      data-slot="sidebar"
      class="group peer hidden text-sidebar-foreground md:block"
      data-state={if @sidebar.open, do: "expanded", else: "collapsed"}
      data-collapsible={if @sidebar.open, do: "", else: @collapsible}
      data-variant={@variant}
      data-side={@side}
      phx-value-collapsible={@collapsible}
    >
      <div
        data-slot="sidebar-gap"
        class={
          classes([
            "relative w-(--sidebar-width) bg-transparent transition-[width] duration-200 ease-linear group-data-[collapsible=offcanvas]:w-0 group-data-[side=right]:rotate-180",
            if(@floating,
              do: "group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4)))]",
              else: "group-data-[collapsible=icon]:w-(--sidebar-width-icon)"
            )
          ])
        }
      >
      </div>
      <div
        id={@id}
        data-slot="sidebar-container"
        data-side={@side}
        class={
          classes([
            "fixed inset-y-0 z-10 hidden h-svh w-(--sidebar-width) transition-[left,right,width] duration-200 ease-linear data-[side=left]:left-0 data-[side=left]:group-data-[collapsible=offcanvas]:left-[calc(var(--sidebar-width)*-1)] data-[side=right]:right-0 data-[side=right]:group-data-[collapsible=offcanvas]:right-[calc(var(--sidebar-width)*-1)] md:flex",
            if(@floating,
              do:
                "p-2 group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4))+2px)]",
              else:
                "group-data-[collapsible=icon]:w-(--sidebar-width-icon) group-data-[side=left]:border-r group-data-[side=right]:border-l"
            ),
            @class
          ])
        }
        {@rest}
      >
        <div
          data-sidebar="sidebar"
          data-slot="sidebar-inner"
          class="flex size-full flex-col bg-sidebar group-data-[variant=floating]:rounded-lg group-data-[variant=floating]:shadow-sm group-data-[variant=floating]:ring-1 group-data-[variant=floating]:ring-sidebar-border"
        >
          {render_slot(@inner_block, @sidebar)}
        </div>
      </div>
    </div>
    """
  end

  attr :sidebar, :map, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_trigger(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Button.button
      data-sidebar="trigger"
      data-slot="sidebar-trigger"
      variant="ghost"
      size="icon-sm"
      class={@class}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="panel-left" class="cn-rtl-flip" />
      <span class="sr-only">Toggle Sidebar</span>
    </ShadcnLiveview.Components.Button.button>
    """
  end

  attr :sidebar, :map, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_rail(assigns) do
    ~H"""
    <button
      data-sidebar="rail"
      data-slot="sidebar-rail"
      aria-label="Toggle Sidebar"
      tabindex="-1"
      title="Toggle Sidebar"
      class={
        classes([
          "absolute inset-y-0 z-20 hidden w-4 transition-all ease-linear group-data-[side=left]:-right-4 group-data-[side=right]:left-0 after:absolute after:inset-y-0 after:start-1/2 after:w-[2px] hover:after:bg-sidebar-border sm:flex ltr:-translate-x-1/2 rtl:-translate-x-1/2 in-data-[side=left]:cursor-w-resize in-data-[side=right]:cursor-e-resize [[data-side=left][data-state=collapsed]_&]:cursor-e-resize [[data-side=right][data-state=collapsed]_&]:cursor-w-resize group-data-[collapsible=offcanvas]:translate-x-0 group-data-[collapsible=offcanvas]:after:left-full hover:group-data-[collapsible=offcanvas]:bg-sidebar [[data-side=left][data-collapsible=offcanvas]_&]:-right-2 [[data-side=right][data-collapsible=offcanvas]_&]:-left-2",
          @class
        ])
      }
      {@rest}
    ></button>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_header(assigns) do
    ~H"""
    <div
      data-slot="sidebar-header"
      data-sidebar="header"
      class={classes(["flex flex-col gap-2 p-2", @class])}
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_footer(assigns) do
    ~H"""
    <div
      data-slot="sidebar-footer"
      data-sidebar="footer"
      class={classes(["flex flex-col gap-2 p-2", @class])}
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_content(assigns) do
    ~H"""
    <div
      data-slot="sidebar-content"
      data-sidebar="content"
      class={
        classes([
          "no-scrollbar flex min-h-0 flex-1 flex-col gap-0 overflow-auto group-data-[collapsible=icon]:overflow-hidden",
          @class
        ])
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_group(assigns) do
    ~H"""
    <div
      data-slot="sidebar-group"
      data-sidebar="group"
      class={classes(["relative flex w-full min-w-0 flex-col p-2", @class])}
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  attr :tag, :string, default: "div"

  def sidebar_group_label(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={@tag}
      data-slot="sidebar-group-label"
      data-sidebar="group-label"
      class={
        classes([
          "flex h-8 shrink-0 items-center rounded-md px-2 text-xs font-medium text-sidebar-foreground/70 ring-sidebar-ring outline-hidden transition-[margin,opacity] duration-200 ease-linear group-data-[collapsible=icon]:-mt-8 group-data-[collapsible=icon]:opacity-0 focus-visible:ring-2 [&>svg]:size-4 [&>svg]:shrink-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  attr :tag, :string, default: "button"

  def sidebar_group_action(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={@tag}
      data-slot="sidebar-group-action"
      data-sidebar="group-action"
      class={
        classes([
          "absolute top-3.5 right-3 flex aspect-square w-5 items-center justify-center rounded-md p-0 text-sidebar-foreground ring-sidebar-ring outline-hidden transition-transform group-data-[collapsible=icon]:hidden after:absolute after:-inset-2 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 md:after:hidden [&>svg]:size-4 [&>svg]:shrink-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_group_content(assigns) do
    ~H"""
    <div
      data-slot="sidebar-group-content"
      data-sidebar="group-content"
      class={classes(["w-full text-sm", @class])}
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu(assigns) do
    ~H"""
    <ul
      data-slot="sidebar-menu"
      data-sidebar="menu"
      class={classes(["flex w-full min-w-0 flex-col gap-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_item(assigns) do
    ~H"""
    <li
      data-slot="sidebar-menu-item"
      data-sidebar="menu-item"
      class={classes(["group/menu-item relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_badge(assigns) do
    ~H"""
    <div
      data-slot="sidebar-menu-badge"
      data-sidebar="menu-badge"
      class={
        classes([
          "pointer-events-none absolute right-1 flex h-5 min-w-5 items-center justify-center rounded-md px-1 text-xs font-medium text-sidebar-foreground tabular-nums select-none group-data-[collapsible=icon]:hidden peer-hover/menu-button:text-sidebar-accent-foreground peer-data-[size=default]/menu-button:top-1.5 peer-data-[size=lg]/menu-button:top-2.5 peer-data-[size=sm]/menu-button:top-1 peer-data-active/menu-button:text-sidebar-accent-foreground",
          @class
        ])
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

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_sub(assigns) do
    ~H"""
    <ul
      data-slot="sidebar-menu-sub"
      data-sidebar="menu-sub"
      class={
        classes([
          "mx-3.5 flex min-w-0 translate-x-px flex-col gap-1 border-l border-sidebar-border px-2.5 py-0.5 group-data-[collapsible=icon]:hidden",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_sub_item(assigns) do
    ~H"""
    <li
      data-slot="sidebar-menu-sub-item"
      data-sidebar="menu-sub-item"
      class={classes(["group/menu-sub-item relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_inset(assigns) do
    ~H"""
    <main
      data-slot="sidebar-inset"
      class={
        classes([
          "relative flex w-full flex-1 flex-col bg-background md:peer-data-[variant=inset]:m-2 md:peer-data-[variant=inset]:ml-0 md:peer-data-[variant=inset]:rounded-xl md:peer-data-[variant=inset]:shadow-sm md:peer-data-[variant=inset]:peer-data-[state=collapsed]:ml-2",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </main>
    """
  end

  attr :tag, :string, default: "button"
  attr :variant, :string, default: "default", values: ~w(default outline)
  attr :size, :string, default: "default", values: ~w(default sm lg)
  attr :is_active, :boolean, default: false

  attr :navigate, :string,
    default: nil,
    doc:
      "LiveView `navigate` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :patch, :string,
    default: nil,
    doc:
      "LiveView `patch` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :replace, :boolean,
    default: false,
    doc: "Replaces the browser history entry for `navigate` and `patch` links."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_button(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-button")

    ~H"""
    <.link
      :if={@navigate || @patch}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      data-slot={@data_slot}
      data-sidebar="menu-button"
      data-size={@size}
      data-active={to_string(@is_active)}
      class={
        classes([
          "peer/menu-button group/menu-button flex w-full items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm ring-sidebar-ring outline-hidden transition-[width,height,padding] group-has-data-[sidebar=menu-action]/menu-item:pr-8 group-data-[collapsible=icon]:size-8! group-data-[collapsible=icon]:p-2! hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-open:hover:bg-sidebar-accent data-open:hover:text-sidebar-accent-foreground data-active:bg-sidebar-accent data-active:font-medium data-active:text-sidebar-accent-foreground [&_svg]:size-4 [&_svg]:shrink-0 [&>span:last-child]:truncate",
          if(@variant == "outline",
            do:
              "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]",
            else: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
          ),
          menu_size(@size),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <.dynamic_tag
      :if={!(@navigate || @patch)}
      tag_name={@tag}
      data-slot={@data_slot}
      data-sidebar="menu-button"
      data-size={@size}
      data-active={to_string(@is_active)}
      class={
        classes([
          "peer/menu-button group/menu-button flex w-full items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm ring-sidebar-ring outline-hidden transition-[width,height,padding] group-has-data-[sidebar=menu-action]/menu-item:pr-8 group-data-[collapsible=icon]:size-8! group-data-[collapsible=icon]:p-2! hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-open:hover:bg-sidebar-accent data-open:hover:text-sidebar-accent-foreground data-active:bg-sidebar-accent data-active:font-medium data-active:text-sidebar-accent-foreground [&_svg]:size-4 [&_svg]:shrink-0 [&>span:last-child]:truncate",
          if(@variant == "outline",
            do:
              "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]",
            else: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
          ),
          menu_size(@size),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :tag, :string, default: "button"
  attr :show_on_hover, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_action(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-action")

    ~H"""
    <.dynamic_tag
      tag_name={@tag}
      data-slot={@data_slot}
      data-sidebar="menu-action"
      class={
        classes([
          "absolute top-1.5 right-1 flex aspect-square w-5 items-center justify-center rounded-md p-0 text-sidebar-foreground ring-sidebar-ring outline-hidden transition-transform group-data-[collapsible=icon]:hidden peer-hover/menu-button:text-sidebar-accent-foreground peer-data-[size=default]/menu-button:top-1.5 peer-data-[size=lg]/menu-button:top-2.5 peer-data-[size=sm]/menu-button:top-1 after:absolute after:-inset-2 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 md:after:hidden [&>svg]:size-4 [&>svg]:shrink-0",
          @show_on_hover &&
            "group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 peer-data-active/menu-button:text-sidebar-accent-foreground aria-expanded:opacity-100 md:opacity-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :tag, :string, default: "a"
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :is_active, :boolean, default: false

  attr :navigate, :string,
    default: nil,
    doc:
      "LiveView `navigate` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :patch, :string,
    default: nil,
    doc:
      "LiveView `patch` destination; renders `Phoenix.Component.link/1` with the same attributes."

  attr :replace, :boolean,
    default: false,
    doc: "Replaces the browser history entry for `navigate` and `patch` links."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_sub_button(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-sub-button")

    ~H"""
    <.link
      :if={@navigate || @patch}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      data-slot={@data_slot}
      data-sidebar="menu-sub-button"
      data-size={@size}
      data-active={to_string(@is_active)}
      class={
        classes([
          "flex h-7 min-w-0 -translate-x-px items-center gap-2 overflow-hidden rounded-md px-2 text-sidebar-foreground ring-sidebar-ring outline-hidden group-data-[collapsible=icon]:hidden hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[size=md]:text-sm data-[size=sm]:text-xs data-active:bg-sidebar-accent data-active:text-sidebar-accent-foreground [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0 [&>svg]:text-sidebar-accent-foreground",
          @class
        ])
      }
      {@rest}
    >{render_slot(@inner_block)}</.link>
    <.dynamic_tag
      :if={!(@navigate || @patch)}
      tag_name={@tag}
      data-slot={@data_slot}
      data-sidebar="menu-sub-button"
      data-size={@size}
      data-active={to_string(@is_active)}
      class={
        classes([
          "flex h-7 min-w-0 -translate-x-px items-center gap-2 overflow-hidden rounded-md px-2 text-sidebar-foreground ring-sidebar-ring outline-hidden group-data-[collapsible=icon]:hidden hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[size=md]:text-sm data-[size=sm]:text-xs data-active:bg-sidebar-accent data-active:text-sidebar-accent-foreground [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0 [&>svg]:text-sidebar-accent-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_input(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Input.input
      data-slot="sidebar-input"
      data-sidebar="input"
      class={classes(["h-8 w-full bg-background shadow-none", @class])}
      {@rest}
    />
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_separator(assigns) do
    ~H"""
    <ShadcnLiveview.Components.Separator.separator
      data-slot="sidebar-separator"
      data-sidebar="separator"
      class={classes(["mx-2 w-auto bg-sidebar-border", @class])}
      {@rest}
    />
    """
  end

  attr :show_icon, :boolean, default: false
  attr :width, :string, default: "70%"

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def sidebar_menu_skeleton(assigns) do
    ~H"""
    <div
      data-slot="sidebar-menu-skeleton"
      data-sidebar="menu-skeleton"
      class={classes(["flex h-8 items-center gap-2 rounded-md px-2", @class])}
      {@rest}
    >
      <ShadcnLiveview.Components.Skeleton.skeleton
        :if={@show_icon}
        class="size-4 rounded-md"
        data-sidebar="menu-skeleton-icon"
      />
      <ShadcnLiveview.Components.Skeleton.skeleton
        class="h-4 max-w-(--skeleton-width) flex-1"
        data-sidebar="menu-skeleton-text"
        style={"--skeleton-width:" <> @width}
      />
    </div>
    """
  end

  defp menu_size("sm"), do: "h-7 text-xs"
  defp menu_size("lg"), do: "h-12 text-sm group-data-[collapsible=icon]:p-0!"
  defp menu_size(_), do: "h-8 text-sm"

  # Like Radix asChild, a spread trigger context (e.g. a dropdown's popup.trigger) renders its
  # own data-slot instead of duplicating the attribute.
  defp slot_override(assigns, default) do
    rest = assigns.rest
    slot = Map.get(rest, :"data-slot", Map.get(rest, "data-slot", default))
    assign(assigns, data_slot: slot, rest: Map.drop(rest, [:"data-slot", "data-slot"]))
  end
end
