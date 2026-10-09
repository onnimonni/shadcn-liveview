defmodule ShadcnLiveview.Components.Textarea do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  attr :value, :any, default: nil

  @doc "Native textarea content: a non-nil value overrides the slot; an explicit empty string clears it. Content is escaped and leading newlines are preserved."
  slot :inner_block, required: false

  def textarea(assigns) do
    ~H"""
    <textarea
      data-slot="textarea"
      class={
        classes([
          "flex field-sizing-content min-h-16 w-full rounded-lg border border-input bg-transparent px-2.5 py-2 text-base transition-colors outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    >{if is_nil(@value), do: render_slot(@inner_block), else: Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end
end
