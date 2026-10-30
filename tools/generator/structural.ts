import type { ComponentFunctionSpec } from "../generate"

function slotOnly(fn: ComponentFunctionSpec): string {
    return `  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def ${fn.name}(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end`
}

function table(): string {
    return `  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def table(assigns) do
    ~H"""
    <div data-slot="table-container" class="relative w-full overflow-x-auto">
      <table
        data-slot="table"
        class={["w-full caption-bottom text-sm", @class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end`
}

function aspectRatio(): string {
    return `  attr :ratio, :float, default: 1.7777777777777777
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def aspect_ratio(assigns) do
    padding = (1.0 / (assigns.ratio || (16.0 / 9.0))) * 100.0
    assigns = assign(assigns, :padding, padding)
    ~H"""
    <div style={"position:relative;width:100%;padding-bottom:#{@padding}%"} data-radix-aspect-ratio-wrapper="">
      <div
        data-slot="aspect-ratio"
        style="position:absolute;top:0;right:0;bottom:0;left:0"
        class={[@class]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end`
}

function scrollArea(): string {
    return `  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  @doc "Preserves initial Radix SSR; LiveView mounting enables native two-axis scrolling and keyboard focus, retained across patches."
  def scroll_area(assigns) do
    ~H"""
    <div
      data-slot="scroll-area"
      dir="ltr"
      class={classes(["relative", @class])}
      style="position:relative;--radix-scroll-area-corner-width:0px;--radix-scroll-area-corner-height:0px"
      {@rest}
    >
      <style><%= Phoenix.HTML.raw("[data-radix-scroll-area-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-scroll-area-viewport]::-webkit-scrollbar{display:none}") %></style>
      <div
        data-radix-scroll-area-viewport=""
        data-slot="scroll-area-viewport"
        class="size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1"
        style="overflow-x:hidden;overflow-y:hidden"
        phx-mounted={Phoenix.LiveView.JS.set_attribute({"tabindex", "0"}) |> Phoenix.LiveView.JS.set_attribute({"style", "overflow-x:auto;overflow-y:auto"})}
      >
        <div style="min-width:100%;display:table">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end`
}

const templates: Record<string, () => string> = { table, aspect_ratio: aspectRatio, scroll_area: scrollArea }

export function generateStructuralFunction(fn: ComponentFunctionSpec): string | undefined {
  if (fn.tag === "slot_only") return slotOnly(fn)
  return Object.hasOwn(templates, fn.name) ? templates[fn.name]() : undefined
}
