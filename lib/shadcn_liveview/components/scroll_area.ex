defmodule ShadcnLiveview.Components.ScrollArea do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def scroll_area(assigns) do
    ~H"""
    <div
      data-slot="scroll-area"
      dir="ltr"
      class={classes(["relative", @class])}
      style="position:relative;--radix-scroll-area-corner-width:0px;--radix-scroll-area-corner-height:0px"
      {@rest}
    >
      <div
        data-slot="scroll-area-viewport"
        class="size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1"
        style="overflow-x:hidden;overflow-y:scroll"
        tabindex="0"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def scroll_bar(assigns) do
    ~H"""
    <div
      data-slot="scroll-area-thumb"
      class={classes(["relative flex-1 rounded-full bg-border", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
