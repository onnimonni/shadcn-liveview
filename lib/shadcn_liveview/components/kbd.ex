defmodule ShadcnLiveview.Components.Kbd do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def kbd(assigns) do
    ~H"""
    <kbd
      data-slot="kbd"
      class={classes(["pointer-events-none inline-flex h-5 w-fit min-w-5 items-center justify-center gap-1 rounded-sm bg-muted px-1 font-sans text-xs font-medium text-muted-foreground select-none in-data-[slot=tooltip-content]:bg-background/20 in-data-[slot=tooltip-content]:text-background dark:in-data-[slot=tooltip-content]:bg-background/10 [&_svg:not([class*='size-'])]:size-3", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def kbd_group(assigns) do
    ~H"""
    <div
      data-slot="kbd-group"
      class={classes(["inline-flex items-center gap-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
