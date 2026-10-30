defmodule ShadcnLiveview.Components.Direction do
  @moduledoc ~S"""
  Sets the text direction (`ltr`/`rtl`) for a subtree.

  Upstream: https://ui.shadcn.com/docs/components/radix/direction

  Components: `direction_provider/1`, `use_direction/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.direction_provider dir="ltr">
    <div class="p-2 text-sm">Left to right layout</div>
  </.direction_provider>
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :rest, :global,
    include:
      ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  slot :inner_block, required: false

  def direction_provider(assigns) do
    ~H"""
    {render_slot(@inner_block)}
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

  def use_direction(assigns) do
    ~H"""
    <div
      data-slot="use-direction"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
