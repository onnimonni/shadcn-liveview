defmodule ShadcnLiveview.Components.InputOtp do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def input_otp(assigns) do
    ~H"""
    <div
      data-slot="input-otp"
      class={classes(["disabled:cursor-not-allowed", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def input_otp_group(assigns) do
    ~H"""
    <div
      data-slot="input-otp-group"
      class={classes(["flex items-center rounded-lg has-aria-invalid:border-destructive has-aria-invalid:ring-3 has-aria-invalid:ring-destructive/20 dark:has-aria-invalid:ring-destructive/40", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def input_otp_slot(assigns) do
    ~H"""
    <div
      data-slot="input-otp-slot"
      class={classes(["h-4 w-px animate-caret-blink bg-foreground duration-1000", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def input_otp_separator(assigns) do
    ~H"""
    <div
      data-slot="input-otp-separator" role="separator"
      class={classes(["flex items-center [&_svg:not([class*='size-'])]:size-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
