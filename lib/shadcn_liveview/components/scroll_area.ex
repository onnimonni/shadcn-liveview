defmodule ShadcnLiveview.Components.ScrollArea do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  slot :inner_block, required: false

  @doc "Renders the initial Radix scroll-area viewport and scrollbar-hiding CSS. Scrollbars are absent in SSR."
  def scroll_area(assigns) do
    ~H"""
    <div
      data-slot="scroll-area"
      dir="ltr"
      class={classes(["relative", @class])}
      style="position:relative;--radix-scroll-area-corner-width:0px;--radix-scroll-area-corner-height:0px"
      {@rest}
    >
      <style>
        <%= Phoenix.HTML.raw("[data-radix-scroll-area-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-scroll-area-viewport]::-webkit-scrollbar{display:none}") %>
      </style>
      <div
        data-radix-scroll-area-viewport=""
        data-slot="scroll-area-viewport"
        class="size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1"
        style="overflow-x:hidden;overflow-y:hidden"
      >
        <div style="min-width:100%;display:table">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def scroll_bar(assigns) do
    ~H"""
    <div
      data-slot="scroll-area-scrollbar"
      class={
        classes([
          "flex touch-none p-px transition-colors select-none data-horizontal:h-2.5 data-horizontal:flex-col data-horizontal:border-t data-horizontal:border-t-transparent data-vertical:h-full data-vertical:w-2.5 data-vertical:border-l data-vertical:border-l-transparent",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
