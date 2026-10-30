defmodule ShadcnLiveview.Components.Skeleton do
  @moduledoc ~S"""
  Placeholder shown while content is loading.

  Upstream: https://ui.shadcn.com/docs/components/radix/skeleton

  Components: `skeleton/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.skeleton class="h-4 w-[250px]" />
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
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def skeleton(assigns) do
    ~H"""
    <div
      data-slot="skeleton"
      class={classes(["animate-pulse rounded-md bg-muted", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
