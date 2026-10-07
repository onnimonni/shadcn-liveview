defmodule ShadcnLiveview.Components.MessageScroller do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller(assigns) do
    ~H"""
    <div
      data-slot="message-scroller"
      class={classes(["group/message-scroller relative flex size-full min-h-0 flex-col overflow-hidden", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller_viewport(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-viewport"
      class={classes(["size-full min-h-0 min-w-0 scroll-fade-b scrollbar-thin scrollbar-gutter-stable overflow-y-auto overscroll-contain contain-content data-autoscrolling:scrollbar-thumb-transparent data-autoscrolling:scrollbar-track-transparent data-pending-scroll:invisible", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller_content(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-content"
      class={classes(["flex h-max min-h-full flex-col gap-6", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller_item(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-item"
      class={classes(["min-w-0 shrink-0 [contain-intrinsic-size:auto_10rem] [content-visibility:auto]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def message_scroller_button(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-button" data-variant={@variant} data-size={@size}
      class={classes(["sr-only", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
