defmodule ShadcnLiveview.Components.NavigationMenu do
  @moduledoc """
  Server-owned navigation selection. Pass the root's :let context to the list
  and items; each item's :let context goes to its trigger and content.
  on_value_change receives %{"id" => id, "value" => item_value}; an empty
  value closes the menu. Events respect the nearest phx-target. Links remain
  native anchors. IDs are caller-scoped.
  Optional <:indicator class="..." force_mount={false} /> is measured by the
  mounted hook, matching Radix's initially absent SSR indicator.
  Viewport relocation preserves the original DOM position and is undone before
  every LiveView patch and on destruction, leaving content server-owned.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :value, :string, default: ""
  attr :viewport, :boolean, default: true
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :dir, :string, values: ~w(ltr rtl), default: "ltr"

  attr :on_value_change, :string,
    default: "control_change",
    doc:
      "LiveView event name pushed on value change; the payload is described in the module docs."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  slot :indicator do
    attr :class, :any,
      doc:
        "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

    attr :force_mount, :boolean
  end

  def navigation_menu(assigns) do
    context = Map.take(assigns, [:id, :value, :viewport, :orientation, :dir])
    assigns = assign(assigns, :context, context)

    indicator_config =
      Enum.map(assigns.indicator, fn indicator ->
        indicator
        |> Map.take([:class, :force_mount])
        |> Map.replace_lazy(:class, fn
          class when is_binary(class) -> class
          class -> classes(class)
        end)
      end)

    assigns = assign(assigns, :indicator_config, indicator_config)

    ~H"""
    <nav
      id={@id}
      aria-label="Main"
      data-orientation={@orientation}
      dir={@dir}
      data-slot="navigation-menu"
      data-viewport={to_string(@viewport)}
      class={
        classes([
          "group/navigation-menu relative flex max-w-max flex-1 items-center justify-center",
          @class
        ])
      }
      phx-hook=".NavigationMenu"
      phx-value-change={@on_value_change}
      phx-value-indicator={Jason.encode!(@indicator_config)}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
      <.navigation_menu_viewport :if={@viewport} context={@context} />
    </nav>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".NavigationMenu">
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
          this.click = event => {
            const trigger = event.target.closest('[data-slot="navigation-menu-trigger"]');
            if (trigger && this.el.contains(trigger) && !trigger.disabled) {
              event.preventDefault();
              const value = trigger.getAttribute("phx-value-item");
              this.select(trigger.getAttribute("aria-expanded") === "true" ? "" : value);
            }
            const link = event.target.closest('[data-slot="navigation-menu-link"]');
            if (link && this.el.contains(link)) this.select("");
          };
          this.over = event => {
            const trigger = event.target.closest('[data-slot="navigation-menu-trigger"]');
            clearTimeout(this.timer);
            if (trigger && !trigger.disabled && event.pointerType !== "touch") {
              this.timer = setTimeout(() => this.select(trigger.getAttribute("phx-value-item")), 200);
            }
          };
          this.leave = () => { clearTimeout(this.timer); this.timer = setTimeout(() => this.select(""), 300); };
          this.enter = () => clearTimeout(this.timer);
          this.outside = event => { if (!this.el.contains(event.target)) this.select(""); };
          this.keydown = event => {
            const target = event.target;
            const trigger = target.closest('[data-slot="navigation-menu-trigger"]');
            if (event.key === "Escape") {
              event.preventDefault();
              const active = this.el.querySelector('[data-slot="navigation-menu-trigger"][aria-expanded="true"]');
              this.pendingFocus = false;
              this.select(""); if (active) active.focus(); return;
            }
            const content = target.closest('[data-slot="navigation-menu-content"]');
            const forward = this.el.getAttribute("data-orientation") === "vertical" ? "ArrowDown" : "ArrowRight";
            const backward = this.el.getAttribute("data-orientation") === "vertical" ? "ArrowUp" : "ArrowLeft";
            if (trigger && event.key === (forward === "ArrowDown" ? "ArrowRight" : "ArrowDown")) {
              event.preventDefault();
              this.pendingFocus = trigger.getAttribute("phx-value-item");
              this.select(this.pendingFocus);
              this.focusContent(); return;
            }
            const keys = content ? ["ArrowUp","ArrowDown","ArrowLeft","ArrowRight","Home","End"] : [forward,backward,"Home","End"];
            if (!keys.includes(event.key)) return;
            const scope = content || this.el.querySelector('[data-slot="navigation-menu-list"]');
            const items = Array.from(scope.querySelectorAll('a[href],button:not(:disabled),[tabindex="0"]')).filter(item => item.getAttribute("aria-hidden") !== "true" && (content || !item.closest('[data-slot="navigation-menu-content"]')));
            if (!items.length) return;
            event.preventDefault();
            let direction = event.key === backward || event.key === "ArrowUp" ? -1 : 1;
            if (!content && forward === "ArrowRight" && this.el.getAttribute("dir") === "rtl") direction *= -1;
            const index = event.key === "Home" ? 0 : event.key === "End" ? items.length-1 : (items.indexOf(target)+direction+items.length)%items.length;
            items[index].focus();
          };
          this.el.addEventListener("click",this.click);
          this.el.addEventListener("pointerover",this.over);
          this.el.addEventListener("pointerleave",this.leave);
          this.el.addEventListener("pointerenter",this.enter);
          this.el.addEventListener("keydown",this.keydown);
          document.addEventListener("pointerdown",this.outside);
          this.updated();
        },
        select(value) {
          const event = this.el.getAttribute("phx-value-change");
          // The server owns the open item; a failed push drops the pending content focus.
          if (event) this.sendEvent(event,{id:this.el.id,value}).catch(() => { if (this.pendingFocus === value) this.pendingFocus = false; });
        },
        focusContent() {
          const content = document.getElementById("radix-" + this.el.id + "-content-" + this.pendingFocus);
          const first = content?.querySelector('a[href],button:not(:disabled),[tabindex="0"]');
          if (first) { first.focus(); this.pendingFocus = false; }
        },
        restoreContent() {
          for (const {content, placeholder} of this.relocated || []) {
            if (placeholder.parentNode) placeholder.replaceWith(content);
          }
          this.relocated = [];
        },
        beforeUpdate() {
          this.restoreContent();
          this.el.querySelectorAll('[data-slot="navigation-menu-indicator"]').forEach(item => item.remove());
        },
        updated() {
          this.restoreContent();
          const viewport = this.el.querySelector('[data-slot="navigation-menu-viewport"]');
          const contents = Array.from(this.el.querySelectorAll('[data-slot="navigation-menu-content"]'));
          const activeContent = contents.find(content => content.getAttribute("data-state") === "open");
          if (viewport) {
            for (const content of contents) {
              if (content.parentElement === viewport) continue;
              const placeholder = document.createComment("navigation-content-origin");
              content.before(placeholder);
              this.relocated.push({content, placeholder});
              viewport.append(content);
            }
            if (activeContent) {
              viewport.style.setProperty("--radix-navigation-menu-viewport-width", activeContent.scrollWidth+"px");
              viewport.style.setProperty("--radix-navigation-menu-viewport-height", activeContent.scrollHeight+"px");
            }
          }
          if (this.pendingFocus) this.focusContent();
          const indicatorConfig = JSON.parse(this.el.getAttribute("phx-value-indicator") || "[]");
          const active = this.el.querySelector('[data-slot="navigation-menu-trigger"][aria-expanded="true"]');
          const list = this.el.querySelector('[data-slot="navigation-menu-list"]');
          this.el.querySelectorAll('[data-slot="navigation-menu-indicator"]').forEach(item => item.remove());
          indicatorConfig.forEach(config => {
            if (!active && !config.force_mount) return;
            const indicator = document.createElement("div");
            indicator.setAttribute("data-slot", "navigation-menu-indicator");
            indicator.setAttribute("data-state", active ? "visible" : "hidden");
            indicator.setAttribute("data-orientation", this.el.getAttribute("data-orientation"));
            indicator.className = "top-full z-1 flex h-1.5 items-end justify-center overflow-hidden data-[state=hidden]:animate-out data-[state=hidden]:fade-out data-[state=visible]:animate-in data-[state=visible]:fade-in " + (config.class || "");
            indicator.style.position = "absolute";
            if (active) {
              const vertical = this.el.getAttribute("data-orientation") === "vertical";
              indicator.style[vertical ? "top" : "left"] = (vertical ? active.offsetTop : active.offsetLeft) + "px";
              indicator.style[vertical ? "height" : "width"] = (vertical ? active.offsetHeight : active.offsetWidth) + "px";
            }
            const arrow = document.createElement("div");
            arrow.className = "relative top-[60%] h-2 w-2 rotate-45 rounded-tl-sm bg-border shadow-md";
            indicator.append(arrow); list.append(indicator);
          });
        },
        destroyed() {
          this.restoreContent();
          clearTimeout(this.timer);
          this.el.removeEventListener("click",this.click);
          this.el.removeEventListener("pointerover",this.over);
          this.el.removeEventListener("pointerleave",this.leave);
          this.el.removeEventListener("pointerenter",this.enter);
          this.el.removeEventListener("keydown",this.keydown);
          document.removeEventListener("pointerdown",this.outside);
        }
      }
    </script>
    """
  end

  attr :context, :map, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_list(assigns) do
    ~H"""
    <div style="position:relative">
      <ul
        data-orientation={@context.orientation}
        data-slot="navigation-menu-list"
        class={classes(["group flex flex-1 list-none items-center justify-center gap-0", @class])}
        dir={@context.dir}
        {@rest}
      >
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_item(assigns) do
    assigns =
      assign(
        assigns,
        :item,
        Map.merge(assigns.context, %{
          item: assigns.value,
          open: assigns.context.value == assigns.value
        })
      )

    ~H"""
    <li data-slot="navigation-menu-item" class={classes(["relative", @class])} {@rest}>
      {render_slot(@inner_block, @item)}
    </li>
    """
  end

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_trigger(assigns) do
    ~H"""
    <button
      id={"radix-" <> @context.id <> "-trigger-" <> @context.item}
      data-state={if @context.open, do: "open", else: "closed"}
      aria-expanded={to_string(@context.open)}
      aria-controls={if @context.open, do: "radix-" <> @context.id <> "-content-" <> @context.item}
      disabled={@disabled}
      data-disabled={if @disabled, do: ""}
      data-slot="navigation-menu-trigger"
      class={
        classes([
          "group/navigation-menu-trigger inline-flex h-9 w-max items-center justify-center rounded-lg px-2.5 py-1.5 text-sm font-medium transition-all outline-none hover:bg-muted focus:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-1 disabled:pointer-events-none disabled:opacity-50 data-popup-open:bg-muted/50 data-popup-open:hover:bg-muted data-open:bg-muted/50 data-open:hover:bg-muted data-open:focus:bg-muted group",
          @class
        ])
      }
      data-radix-collection-item=""
      phx-value-item={@context.item}
      {@rest}
    >
      {render_slot(@inner_block)}{" "}<ShadcnLiveview.Components.Icon.icon
        name="chevron-down"
        class="relative top-px ml-1 size-3 transition duration-300 group-data-popup-open/navigation-menu-trigger:rotate-180 group-data-open/navigation-menu-trigger:rotate-180"
        aria-hidden="true"
      />
    </button>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_content(assigns) do
    assigns =
      assign(
        assigns,
        :content_style,
        if(assigns.context.open, do: %{}, else: %{style: "pointer-events:none"})
      )

    ~H"""
    <%= if @context.open || @force_mount do %>
      <span
        :if={@context.open}
        aria-hidden="true"
        tabindex="0"
        style="position:absolute;border:0;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;word-wrap:normal"
      />
      <div
        id={"radix-" <> @context.id <> "-content-" <> @context.item}
        aria-labelledby={"radix-" <> @context.id <> "-trigger-" <> @context.item}
        data-orientation={@context.orientation}
        data-state={if @context.open, do: "open", else: "closed"}
        data-slot="navigation-menu-content"
        class={
          classes([
            "top-0 left-0 w-full p-1 ease-[cubic-bezier(0.22,1,0.36,1)] group-data-[viewport=false]/navigation-menu:top-full group-data-[viewport=false]/navigation-menu:mt-1.5 group-data-[viewport=false]/navigation-menu:overflow-hidden group-data-[viewport=false]/navigation-menu:rounded-lg group-data-[viewport=false]/navigation-menu:bg-popover group-data-[viewport=false]/navigation-menu:text-popover-foreground group-data-[viewport=false]/navigation-menu:shadow group-data-[viewport=false]/navigation-menu:ring-1 group-data-[viewport=false]/navigation-menu:ring-foreground/10 group-data-[viewport=false]/navigation-menu:duration-300 data-[motion=from-end]:slide-in-from-right-52 data-[motion=from-start]:slide-in-from-left-52 data-[motion=to-end]:slide-out-to-right-52 data-[motion=to-start]:slide-out-to-left-52 data-[motion^=from-]:animate-in data-[motion^=from-]:fade-in data-[motion^=to-]:animate-out data-[motion^=to-]:fade-out **:data-[slot=navigation-menu-link]:focus:ring-0 **:data-[slot=navigation-menu-link]:focus:outline-none md:absolute md:w-auto group-data-[viewport=false]/navigation-menu:data-open:animate-in group-data-[viewport=false]/navigation-menu:data-open:fade-in-0 group-data-[viewport=false]/navigation-menu:data-open:zoom-in-95 group-data-[viewport=false]/navigation-menu:data-closed:animate-out group-data-[viewport=false]/navigation-menu:data-closed:fade-out-0 group-data-[viewport=false]/navigation-menu:data-closed:zoom-out-95",
            @class
          ])
        }
        {@content_style}
        dir={@context.dir}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    <% end %>
    """
  end

  attr :active, :boolean, default: false
  attr :href, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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

  attr :rest, :global, include: ~w(target rel download)
  slot :inner_block, required: true

  def navigation_menu_link(assigns) do
    ~H"""
    <.link
      :if={@navigate || @patch}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      data-active={if @active, do: ""}
      aria-current={if @active, do: "page"}
      data-slot="navigation-menu-link"
      class={
        classes([
          "flex items-center gap-2 rounded-lg p-2 text-sm transition-all outline-none hover:bg-muted focus:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-1 in-data-[slot=navigation-menu-content]:rounded-md data-active:bg-muted/50 data-active:hover:bg-muted data-active:focus:bg-muted [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      href={@href}
      data-radix-collection-item=""
      {@rest}
    >{render_slot(@inner_block)}</.link>
    <a
      :if={!(@navigate || @patch)}
      data-active={if @active, do: ""}
      aria-current={if @active, do: "page"}
      data-slot="navigation-menu-link"
      class={
        classes([
          "flex items-center gap-2 rounded-lg p-2 text-sm transition-all outline-none hover:bg-muted focus:bg-muted focus-visible:ring-3 focus-visible:ring-ring/50 focus-visible:outline-1 in-data-[slot=navigation-menu-content]:rounded-md data-active:bg-muted/50 data-active:hover:bg-muted data-active:focus:bg-muted [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      href={@href}
      data-radix-collection-item=""
      {@rest}
    >{render_slot(@inner_block)}</a>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block

  def navigation_menu_viewport(assigns) do
    ~H"""
    <div class="absolute top-full left-0 isolate z-50 flex justify-center">
      <div
        :if={@context.value != "" || @force_mount}
        data-state={if @context.value != "", do: "open", else: "closed"}
        data-orientation={@context.orientation}
        data-slot="navigation-menu-viewport"
        class={
          classes([
            "origin-top-center relative mt-1.5 h-(--radix-navigation-menu-viewport-height) w-full overflow-hidden rounded-lg bg-popover text-popover-foreground shadow ring-1 ring-foreground/10 duration-100 md:w-(--radix-navigation-menu-viewport-width) data-open:animate-in data-open:zoom-in-90 data-closed:animate-out data-closed:zoom-out-90",
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
end
