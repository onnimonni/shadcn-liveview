defmodule ShadcnLiveview.Components.Command do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command(assigns) do
    ~H"""
    <div
      data-slot="command"
      class={classes(["flex size-full flex-col overflow-hidden rounded-xl! bg-popover p-1 text-popover-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_dialog(assigns) do
    ~H"""
    <div
      data-slot="command-dialog"
      class={classes(["top-1/3 translate-y-0 overflow-hidden rounded-xl! p-0", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  def command_input(assigns) do
    ~H"""
    <input
      data-slot="command-input"
      class={classes(["size-4 shrink-0 opacity-50", @class])}
      {@rest}
    />
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_list(assigns) do
    ~H"""
    <div
      data-slot="command-list"
      class={classes(["no-scrollbar max-h-72 scroll-py-1 overflow-x-hidden overflow-y-auto outline-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_empty(assigns) do
    ~H"""
    <div
      data-slot="command-empty"
      class={classes(["py-6 text-center text-sm", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_group(assigns) do
    ~H"""
    <div
      data-slot="command-group"
      class={classes(["overflow-hidden p-1 text-foreground **:[[cmdk-group-heading]]:px-2 **:[[cmdk-group-heading]]:py-1.5 **:[[cmdk-group-heading]]:text-xs **:[[cmdk-group-heading]]:font-medium **:[[cmdk-group-heading]]:text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_separator(assigns) do
    ~H"""
    <div
      data-slot="command-separator"
      class={classes(["-mx-1 h-px bg-border", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_item(assigns) do
    ~H"""
    <div
      data-slot="command-item"
      class={classes(["ml-auto opacity-0 group-has-data-[slot=command-shortcut]/command-item:hidden group-data-[checked=true]/command-item:opacity-100", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def command_shortcut(assigns) do
    ~H"""
    <span
      data-slot="command-shortcut"
      class={classes(["ml-auto text-xs tracking-widest text-muted-foreground group-data-selected/command-item:text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
