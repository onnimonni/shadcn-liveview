defmodule ShadcnLiveview.Components.Questionnaire do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire(assigns) do
    ~H"""
    <form
      data-slot="questionnaire"
      data-current="0"
      data-total="0"
      novalidate=""
      class={classes(["flex w-full min-w-0 flex-col gap-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </form>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_progress(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-progress"
      class={classes(["min-h-[1lh] w-fit min-w-[14ch] text-xs font-medium text-muted-foreground tabular-nums", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_item(assigns) do
    ~H"""
    <fieldset
      data-slot="questionnaire-item"
      class={classes(["flex min-w-0 flex-col gap-4 border-0 p-0 outline-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_title(assigns) do
    ~H"""
    <h2
      data-slot="questionnaire-title"
      class={classes(["cn-font-heading text-base leading-snug font-medium text-pretty [&:not(:has(~[data-slot=questionnaire-description]))]:mb-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_description(assigns) do
    ~H"""
    <p
      data-slot="questionnaire-description"
      class={classes(["text-sm text-pretty text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_choices(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-choices"
      class={classes(["group/questionnaire-choices grid min-w-0 gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_choice(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-choice-shortcut"
      class={classes(["pointer-events-none ms-auto hidden size-5 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-md border border-input bg-background font-mono text-[0.625rem] leading-none font-medium text-muted-foreground group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[shortcut]/questionnaire-choice:inline-flex", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_choice_description(assigns) do
    ~H"""
    <p
      data-slot="questionnaire-choice-description"
      class={classes(["text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)

  def questionnaire_input(assigns) do
    ~H"""
    <input
      data-slot="questionnaire-input"
      class={classes(["h-8 min-h-11 w-full min-w-0 rounded-lg border border-input bg-transparent px-2.5 py-1 text-base transition-[color,box-shadow,background-color] outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 sm:min-h-0 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40", @class])}
      {@rest}
    />
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_error(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-error"
      class={classes(["mt-2 text-sm text-destructive", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_actions(assigns) do
    ~H"""
    <button
      data-slot="questionnaire-actions"
      class={classes(["grid min-h-11 w-full grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-2 sm:min-h-8", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_previous(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-previous" data-variant={@variant} data-size={@size}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_skip(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-skip" data-variant={@variant} data-size={@size}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_next(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-next" data-variant={@variant} data-size={@size}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "default"
  attr :variant, :string, default: "default"
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def questionnaire_submit(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-submit" data-variant={@variant} data-size={@size}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
