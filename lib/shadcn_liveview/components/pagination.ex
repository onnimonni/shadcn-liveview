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
      role="navigation"
      aria-label="pagination"
      data-slot="pagination"
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

  attr :is_active, :boolean, default: false
  attr :size, :string, default: "icon"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_link(assigns) do
    ~H"""
    <a
      data-slot="pagination-link"
      data-variant={if @is_active, do: "outline", else: "ghost"}
      data-size={@size}
      aria-current={if @is_active, do: "page"}
      data-active={if @is_active, do: "true"}
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
        if(@is_active, do: "border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50", else: "border-transparent hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50"),
        if(@size == "default", do: "h-8 gap-1.5 px-2.5", else: "size-8"),
        @class
      ])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :text, :string, default: "Previous"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_previous(assigns) do
    ~H"""
    <a
      aria-label="Go to previous page"
      data-slot="pagination-link"
      data-variant="ghost"
      data-size="default"
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 pl-1.5! has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        @class
      ])}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-left" data-icon="inline-start" class="cn-rtl-flip" />
      <span class="hidden sm:block">{@text}</span>
    </a>
    """
  end

  attr :text, :string, default: "Next"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_next(assigns) do
    ~H"""
    <a
      aria-label="Go to next page"
      data-slot="pagination-link"
      data-variant="ghost"
      data-size="default"
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 pr-1.5! has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        @class
      ])}
      {@rest}
    >
      <span class="hidden sm:block">{@text}</span>
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" data-icon="inline-end" class="cn-rtl-flip" />
    </a>
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
