defmodule ShadcnLiveview.Components.Drawer do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_trigger(assigns) do
    ~H"""
    <button
      data-slot="drawer-trigger"
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

  def drawer_portal(assigns) do
    ~H"""
    <div
      data-slot="drawer-portal"
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

  def drawer_close(assigns) do
    ~H"""
    <button
      data-slot="drawer-close"
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

  def drawer_overlay(assigns) do
    ~H"""
    <div
      data-slot="drawer-overlay"
      class={classes(["fixed inset-0 z-50 bg-black/10 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_content(assigns) do
    ~H"""
    <div
      data-state="open"
      data-slot="drawer-overlay"
      class="fixed inset-0 z-50 bg-black/80"
    />
    <div
      role="dialog"
      data-state="open"
      data-slot="drawer-content"
      tabindex="-1"
      class={classes(["fixed inset-x-0 bottom-0 z-50 mt-24 flex h-auto flex-col rounded-t-[10px] border bg-background", @class])}
      {@rest}
    >
      <div class="mx-auto mt-4 h-2 w-[100px] rounded-full bg-muted" />
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_header(assigns) do
    ~H"""
    <div
      data-slot="drawer-header"
      class={classes(["flex flex-col gap-0.5 p-4 group-data-[vaul-drawer-direction=bottom]/drawer-content:text-center group-data-[vaul-drawer-direction=top]/drawer-content:text-center md:gap-0.5 md:text-left", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_footer(assigns) do
    ~H"""
    <div
      data-slot="drawer-footer"
      class={classes(["mt-auto flex flex-col gap-2 p-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_title(assigns) do
    ~H"""
    <h2
      data-slot="drawer-title"
      class={classes(["cn-font-heading text-base font-medium text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def drawer_description(assigns) do
    ~H"""
    <p
      data-slot="drawer-description"
      class={classes(["text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end
end
