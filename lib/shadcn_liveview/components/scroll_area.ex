defmodule ShadcnLiveview.Components.ScrollArea do
  @moduledoc ~S"""
  Scrollable region styled like Radix ScrollArea.

  Upstream: https://ui.shadcn.com/docs/components/radix/scroll-area

  Components: `scroll_area/1`, `scroll_bar/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.scroll_area id="scroll-area-demo" class="h-32 w-48 rounded-md border p-4">
    <div :for={n <- 1..20} class="py-2">Item {n}</div>
  </.scroll_area>
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

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
      <style>
        <%= Phoenix.HTML.raw("[data-radix-scroll-area-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-scroll-area-viewport]::-webkit-scrollbar{display:none}") %>
      </style>
      <div
        data-radix-scroll-area-viewport=""
        data-slot="scroll-area-viewport"
        class="size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1"
        style="overflow-x:hidden;overflow-y:hidden"
        phx-mounted={
          Phoenix.LiveView.JS.set_attribute({"tabindex", "0"})
          |> Phoenix.LiveView.JS.set_attribute({"style", "overflow-x:auto;overflow-y:auto"})
        }
      >
        <div style="min-width:100%;display:table">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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
