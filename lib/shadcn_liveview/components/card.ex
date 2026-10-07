defmodule ShadcnLiveview.Components.Card do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card(assigns) do
    ~H"""
    <div
      data-slot="card" data-size={@size}
      class={classes(["group/card flex flex-col gap-(--card-spacing) overflow-hidden rounded-xl bg-card py-(--card-spacing) text-sm text-card-foreground ring-1 ring-foreground/10 [--card-spacing:--spacing(4)] has-data-[slot=card-footer]:pb-0 has-[>img:first-child]:pt-0 data-[size=sm]:[--card-spacing:--spacing(3)] data-[size=sm]:has-data-[slot=card-footer]:pb-0 *:[img:first-child]:rounded-t-xl *:[img:last-child]:rounded-b-xl", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_header(assigns) do
    ~H"""
    <div
      data-slot="card-header"
      class={classes(["group/card-header @container/card-header grid auto-rows-min items-start gap-1 rounded-t-xl px-(--card-spacing) has-data-[slot=card-action]:grid-cols-[1fr_auto] has-data-[slot=card-description]:grid-rows-[auto_auto] [.border-b]:pb-(--card-spacing)", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_title(assigns) do
    ~H"""
    <div
      data-slot="card-title"
      class={classes(["cn-font-heading text-base leading-snug font-medium group-data-[size=sm]/card:text-sm", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_description(assigns) do
    ~H"""
    <div
      data-slot="card-description"
      class={classes(["text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_action(assigns) do
    ~H"""
    <div
      data-slot="card-action"
      class={classes(["col-start-2 row-span-2 row-start-1 self-start justify-self-end", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_content(assigns) do
    ~H"""
    <div
      data-slot="card-content"
      class={classes(["px-(--card-spacing)", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def card_footer(assigns) do
    ~H"""
    <div
      data-slot="card-footer"
      class={classes(["flex items-center rounded-b-xl border-t bg-muted/50 p-(--card-spacing)", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
