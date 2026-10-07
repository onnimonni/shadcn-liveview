defmodule ShadcnLiveview.Components.Breadcrumb do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb(assigns) do
    ~H"""
    <nav
      data-slot="breadcrumb" aria-label="breadcrumb"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_list(assigns) do
    ~H"""
    <ol
      data-slot="breadcrumb-list"
      class={classes(["flex flex-wrap items-center gap-1.5 text-sm wrap-break-word text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ol>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_item(assigns) do
    ~H"""
    <li
      data-slot="breadcrumb-item"
      class={classes(["inline-flex items-center gap-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_link(assigns) do
    ~H"""
    <a
      data-slot="breadcrumb-link"
      class={classes(["transition-colors hover:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_page(assigns) do
    ~H"""
    <span
      data-slot="breadcrumb-page" role="link" aria-disabled="true" aria-current="page"
      class={classes(["font-normal text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_separator(assigns) do
    ~H"""
    <li
      data-slot="breadcrumb-separator"
      role="presentation"
      aria-hidden="true"
      class={["[&>svg]:size-3.5", @class]}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" class="cn-rtl-flip" />
    </li>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def breadcrumb_ellipsis(assigns) do
    ~H"""
    <span
      data-slot="breadcrumb-ellipsis" role="presentation"
      class={classes(["sr-only", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
