import type { ComponentFunctionSpec } from "../generate"

function breadcrumbSeparator(): string {
    return `  attr :class, :string, default: nil
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
  end`
}

function pagination(): string {
    return `  attr :class, :string, default: nil
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
  end`
}

function paginationLink(): string {
    return `  attr :is_active, :boolean, default: false
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
  end`
}

function paginationAdjacent(previous: boolean): string {
  const direction = previous ? "previous" : "next"
  const label = previous ? "Previous" : "Next"
  const padding = previous ? "pl" : "pr"
  const icon = previous
    ? '      <ShadcnLiveview.Components.Icon.icon name="chevron-left" data-icon="inline-start" class="cn-rtl-flip" />'
    : '      <ShadcnLiveview.Components.Icon.icon name="chevron-right" data-icon="inline-end" class="cn-rtl-flip" />'
  const text = '      <span class="hidden sm:block">{@text}</span>'
  const content = previous ? icon + "\n" + text : text + "\n" + icon
  return `  attr :text, :string, default: "${label}"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def pagination_${direction}(assigns) do
    ~H"""
    <a
      aria-label="Go to ${direction} page"
      data-slot="pagination-link"
      data-variant="ghost"
      data-size="default"
      class={classes([
        "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 ${padding}-1.5! has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
        @class
      ])}
      {@rest}
    >
${content}
    </a>
    """
  end`
}

const templates: Record<string, () => string> = {
  breadcrumb_separator: breadcrumbSeparator, pagination, pagination_link: paginationLink,
}

export function generateNavigationFunction(fn: ComponentFunctionSpec): string | undefined {
  if (fn.name === "pagination_previous") return paginationAdjacent(true)
  if (fn.name === "pagination_next") return paginationAdjacent(false)
  return Object.hasOwn(templates, fn.name) ? templates[fn.name]() : undefined
}
