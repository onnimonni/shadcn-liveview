defmodule ShadcnLiveview.Components.Checkbox do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :checked, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def checkbox(assigns) do
    ~H"""
    <button
      type="button"
      role="checkbox"
      aria-checked={to_string(@checked)}
      data-state={if @checked, do: "checked", else: "unchecked"}
      value="on"
      data-slot="checkbox"
      class={classes(["peer relative flex size-4 shrink-0 items-center justify-center rounded-[4px] border border-input transition-colors outline-none group-has-disabled/field:opacity-50 group-has-[:focus-visible]/field-label:ring-0 group-has-[:focus-visible]/field-label:not-data-checked:border-input after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 aria-invalid:aria-checked:border-primary dark:bg-input/30 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:border-primary data-checked:bg-primary data-checked:text-primary-foreground", @class])}
      {@rest}
    ><%= if @checked do %><span data-slot="checkbox-indicator" class="grid place-content-center text-current transition-none [&>svg]:size-3.5"><ShadcnLiveview.Components.Icon.icon name="check" class="size-3.5" /></span><% end %></button><input
      type="checkbox"
      aria-hidden="true"
      tabindex="-1"
      style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
      value="on"
      checked={@checked}
    />
    """
  end
end
