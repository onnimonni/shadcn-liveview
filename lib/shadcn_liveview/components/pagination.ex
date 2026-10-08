defmodule ShadcnLiveview.Components.Pagination do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination(assigns) do
    ~H"""
    <nav
      data-slot="pagination" role="navigation"
      class={classes(["mx-auto flex w-full justify-center", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_content(assigns) do
    ~H"""
    <ul
      data-slot="pagination-content"
      class={classes(["flex items-center gap-0.5", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_item(assigns) do
    ~H"""
    <li
      data-slot="pagination-item"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_link(assigns) do
    ~H"""
    <a
      data-slot="pagination-link"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_previous(assigns) do
    ~H"""
    <div
      data-slot="pagination-previous"
      class={classes(["hidden sm:block", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_next(assigns) do
    ~H"""
    <div
      data-slot="pagination-next"
      class={classes(["cn-rtl-flip", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_ellipsis(assigns) do
    ~H"""
    <span
      data-slot="pagination-ellipsis"
      class={classes(["sr-only", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
