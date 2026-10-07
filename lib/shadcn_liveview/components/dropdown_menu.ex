defmodule ShadcnLiveview.Components.DropdownMenu do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_portal(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-portal"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_trigger(assigns) do
    ~H"""
    <button
      data-slot="dropdown-menu-trigger"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_content(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-content"
      class={classes(["cn-menu-target cn-menu-translucent z-50 max-h-(--radix-dropdown-menu-content-available-height) w-(--radix-dropdown-menu-trigger-width) min-w-32 origin-(--radix-dropdown-menu-content-transform-origin) overflow-x-hidden overflow-y-auto rounded-lg bg-popover p-1 text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:overflow-hidden data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_group(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-group"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_item(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-item" data-variant={@variant}
      class={classes(["group/dropdown-menu-item relative flex cursor-default items-center gap-1.5 rounded-md px-1.5 py-1 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground not-data-[variant=destructive]:focus:**:text-accent-foreground data-inset:pl-7 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 data-[variant=destructive]:*:[svg]:text-destructive", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_checkbox_item(assigns) do
    ~H"""
    <span
      data-slot="dropdown-menu-checkbox-item-indicator"
      class={classes(["pointer-events-none absolute right-2 flex items-center justify-center", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_radio_group(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-radio-group"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_radio_item(assigns) do
    ~H"""
    <span
      data-slot="dropdown-menu-radio-item-indicator"
      class={classes(["pointer-events-none absolute right-2 flex items-center justify-center", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_label(assigns) do
    ~H"""
    <label
      data-slot="dropdown-menu-label"
      class={classes(["px-1.5 py-1 text-xs font-medium text-muted-foreground data-inset:pl-7", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_separator(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-separator"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_shortcut(assigns) do
    ~H"""
    <span
      data-slot="dropdown-menu-shortcut"
      class={classes(["ml-auto text-xs tracking-widest text-muted-foreground group-focus/dropdown-menu-item:text-accent-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_sub(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-sub"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_sub_trigger(assigns) do
    ~H"""
    <button
      data-slot="dropdown-menu-sub-trigger"
      class={classes(["cn-rtl-flip ml-auto", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def dropdown_menu_sub_content(assigns) do
    ~H"""
    <div
      data-slot="dropdown-menu-sub-content"
      class={classes(["cn-menu-target cn-menu-translucent z-50 min-w-[96px] origin-(--radix-dropdown-menu-content-transform-origin) overflow-hidden rounded-lg bg-popover p-1 text-popover-foreground shadow-lg ring-1 ring-foreground/10 duration-100 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-open:animate-in data-open:fade-in-0 data-open:zoom-in-95 data-closed:animate-out data-closed:fade-out-0 data-closed:zoom-out-95", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
