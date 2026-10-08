defmodule ShadcnLiveview.Components.Label do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def label(assigns) do
    ~H"""
    <label
      data-slot="label"
      class={
        classes([
          "flex items-center gap-2 text-sm leading-none font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end
end
