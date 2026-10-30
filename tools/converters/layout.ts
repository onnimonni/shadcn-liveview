import type { ComponentSpec } from "../generate"
import { cn } from "cn"
import { buttonVariants } from "../../vendor/shadcn/ui/button"
import { carouselHook, resizableHook, sidebarHook } from "./layout-hooks"
import { linkAttrs, linkOrElement } from "../generator/links"

const header = (spec: ComponentSpec, docs: string) => `defmodule ShadcnLiveview.Components.${spec.moduleName} do
  @moduledoc """
  ${docs}
  Hook events honor phx-target on the root or nearest containing element,
  including internal state changes and completion acknowledgements.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
`
const globals = `  attr :class, :any, default: nil
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
  Orientation, loop and start_index configure the vanilla Embla hook. Controls
  are disabled during SSR, like upstream Embla, and synchronize after mounting.
  Items retain their caller-specified basis classes; scrolling supports pointer,
  touch, responsive resizing and independently scoped instances. ArrowLeft and
  ArrowRight select the previous and next slide in both orientations, like the
  upstream carousel; ArrowUp and ArrowDown do not navigate a vertical carousel.
  Enabled controls retain keyboard focus across server acknowledgements. End
  controls become disabled without moving focus to an extra region tab stop.`) + `
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
${carouselHook}
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
    basis = if Enum.any?(String.split(classes(assigns.class)), &String.starts_with?(&1, "basis-")), do: nil, else: "basis-full"
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
  Arrow keys resize by five percentage points, including with Shift held.
  Double-clicking an enabled separator resets the first adjacent panel with an
  explicit default_size, respecting its constraints; panels without defaults do
  not reset. Disabled groups, separators and fixed panels cannot be resized.
  Set disable_double_click on a separator to opt out of this reset.
  Keep panel default_size values as reset baselines. Bind the group's layout to
  a map of panel IDs to percentages for caller-owned state, and persist the
  value map from shadcn:resizable-change; resizable:change exposes that same map
  as a browser event. Reset notifications use the same payload and phx-target
  routing as pointer and keyboard resizing.`) + `
  attr :id, :string, required: true
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :disabled, :boolean, default: false
  attr :layout, :map, default: nil
${globals}
  def resizable_panel_group(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, orientation: assigns.orientation, disabled: assigns.disabled})
    ~H"""
    <div id={@id} data-slot="resizable-panel-group" data-group="true" data-testid={@id}
      class={classes([${JSON.stringify(groupClass)}, @class])}
      style={"height:100%;width:100%;overflow:hidden;display:flex;flex-direction:" <> if(@orientation == "horizontal", do: "row", else: "column") <> ";flex-wrap:nowrap;touch-action:" <> if(@orientation == "horizontal", do: "pan-y", else: "pan-x")}
      phx-hook=".Resizable" phx-value-orientation={@orientation} phx-value-disabled={to_string(@disabled)}
      phx-value-layout={if @layout, do: Jason.encode!(@layout)} {@rest}>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Resizable">
${resizableHook}
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
  attr :disable_double_click, :boolean, default: false
${globals}
  def resizable_handle(assigns) do
    assigns = assign(assigns, :disabled, assigns.disabled or assigns.group.disabled)
    ~H"""
    <div id={@id} data-slot="resizable-handle" data-testid={@id} data-separator={if @disabled, do: "disabled", else: "inactive"}
      role="separator" aria-disabled={if @disabled, do: "true"} aria-orientation={if @group.orientation == "horizontal", do: "vertical", else: "horizontal"}
      phx-value-disable-double-click={to_string(@disable_double_click)}
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
  Nested primitives accept caller classes and global attributes. Use \`tag="a"\`
  on menu/group buttons for link composition instead of a React asChild wrapper;
  \`navigate\` or \`patch\` on menu and sub buttons renders \`Phoenix.Component.link/1\`.`) + `
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
${sidebarHook}
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
${linkAttrs.join("\n")}
${globals}
  def sidebar_menu_button(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-button")
    ~H"""
${linkOrElement({ open: ".dynamic_tag tag_name={@tag}", close: ".dynamic_tag", attrs: ` data-slot={@data_slot} data-sidebar="menu-button" data-size={@size} data-active={to_string(@is_active)}
      class={classes([${base("sidebar_menu_button")}, if(@variant == "outline", do: "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]", else: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"), menu_size(@size), @class])} {@rest}`, body: `
      {render_slot(@inner_block)}
    ` })}
    """
  end

  attr :tag, :string, default: "button"
  attr :show_on_hover, :boolean, default: false
${globals}
  def sidebar_menu_action(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-action")
    ~H"""
    <.dynamic_tag tag_name={@tag} data-slot={@data_slot} data-sidebar="menu-action"
      class={classes([${base("sidebar_menu_action")}, @show_on_hover && "group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 peer-data-active/menu-button:text-sidebar-accent-foreground aria-expanded:opacity-100 md:opacity-0", @class])} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :tag, :string, default: "a"
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :is_active, :boolean, default: false
${linkAttrs.join("\n")}
${globals}
  def sidebar_menu_sub_button(assigns) do
    assigns = slot_override(assigns, "sidebar-menu-sub-button")
    ~H"""
${linkOrElement({ open: ".dynamic_tag tag_name={@tag}", close: ".dynamic_tag", attrs: ` data-slot={@data_slot} data-sidebar="menu-sub-button" data-size={@size} data-active={to_string(@is_active)}
      class={classes([${base("sidebar_menu_sub_button")}, @class])} {@rest}`, body: "{render_slot(@inner_block)}" })}
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

  # Like Radix asChild, a spread trigger context (e.g. a dropdown's popup.trigger) renders its
  # own data-slot instead of duplicating the attribute.
  defp slot_override(assigns, default) do
    rest = assigns.rest
    slot = Map.get(rest, :"data-slot", Map.get(rest, "data-slot", default))
    assign(assigns, data_slot: slot, rest: Map.drop(rest, [:"data-slot", "data-slot"]))
  end
end
`
}
