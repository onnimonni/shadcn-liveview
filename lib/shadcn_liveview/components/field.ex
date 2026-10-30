defmodule ShadcnLiveview.Components.Field do
  @moduledoc ~S"""
  Composes labels, controls, descriptions and errors into accessible form fields.

  Upstream: https://ui.shadcn.com/docs/components/radix/field

  Components: `field_set/1`, `field_legend/1`, `field_group/1`, `field/1`, `field_content/1`, `field_label/1`, `field_title/1`, `field_description/1`, `field_separator/1`, `field_error/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.field_set class="w-full max-w-md">
    <.field_group>
      <.field>
        <.field_label for="field-email">Email address</.field_label>
        <.input id="field-email" type="email" placeholder="m@example.com" aria-describedby="field-help" />
        <.field_description id="field-help">We will never share your email.</.field_description>
      </.field>
    </.field_group>
  </.field_set>
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

  def field_set(assigns) do
    ~H"""
    <fieldset
      data-slot="field-set"
      class={
        classes([
          "flex flex-col gap-4 has-[>[data-slot=checkbox-group]]:gap-3 has-[>[data-slot=radio-group]]:gap-3",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :variant, :string, default: "legend", values: ~w(legend label)

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def field_legend(assigns) do
    ~H"""
    <div
      data-slot="field-legend"
      data-variant={@variant}
      class={
        classes([
          "mb-1.5 font-medium data-[variant=label]:text-sm data-[variant=legend]:text-base",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
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

  def field_group(assigns) do
    ~H"""
    <div
      data-slot="field-group"
      class={
        classes([
          "group/field-group @container/field-group flex w-full flex-col gap-5 data-[slot=checkbox-group]:gap-3 *:data-[slot=field-group]:gap-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :orientation, :string, default: "vertical", values: ~w(vertical horizontal responsive)

  attr :invalid, :boolean,
    default: false,
    doc:
      "Renders `data-invalid=\"true\"` (the `data-[invalid=true]` styles); `data-invalid` passed through attrs still works."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def field(assigns) do
    ~H"""
    <div
      data-slot="field"
      role="group"
      data-orientation={@orientation}
      data-invalid={if @invalid, do: "true"}
      class={classes([field_classes(@orientation), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @field_styles %{
    "vertical" =>
      "group/field flex w-full gap-2 data-[invalid=true]:text-destructive flex-col *:w-full [&>.sr-only]:w-auto",
    "horizontal" =>
      "group/field flex w-full gap-2 data-[invalid=true]:text-destructive flex-row items-center has-[>[data-slot=field-content]]:items-start *:data-[slot=field-label]:flex-auto has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px",
    "responsive" =>
      "group/field flex w-full gap-2 data-[invalid=true]:text-destructive flex-col *:w-full @md/field-group:flex-row @md/field-group:items-center @md/field-group:*:w-auto @md/field-group:has-[>[data-slot=field-content]]:items-start @md/field-group:*:data-[slot=field-label]:flex-auto [&>.sr-only]:w-auto @md/field-group:has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px"
  }

  defp field_classes(orientation) do
    Map.get(
      @field_styles,
      orientation || "vertical",
      "group/field flex w-full gap-2 data-[invalid=true]:text-destructive flex-col *:w-full [&>.sr-only]:w-auto"
    )
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def field_content(assigns) do
    ~H"""
    <div
      data-slot="field-content"
      class={classes(["group/field-content flex flex-1 flex-col gap-0.5 leading-snug", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
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

  def field_label(assigns) do
    ~H"""
    <label
      data-slot="field-label"
      class={
        classes([
          "items-center text-sm font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50 group/field-label peer/field-label flex w-fit gap-2 leading-snug group-data-[disabled=true]/field:opacity-50 has-data-checked:border-primary/30 has-data-checked:bg-primary/5 has-[>[data-slot=field]]:rounded-lg has-[>[data-slot=field]]:border has-[>[data-slot=field]]:not-has-[:disabled,[data-disabled]]:hover:bg-muted/50 has-[>[data-slot=field]]:has-[:focus-visible]:border-ring has-[>[data-slot=field]]:has-[:focus-visible]:ring-3 has-[>[data-slot=field]]:has-[:focus-visible]:ring-ring/50 *:data-[slot=field]:p-2.5 dark:has-data-checked:border-primary/20 dark:has-data-checked:bg-primary/10 has-[>[data-slot=field]]:w-full has-[>[data-slot=field]]:flex-col",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
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

  def field_title(assigns) do
    ~H"""
    <h2
      data-slot="field-label"
      class={
        classes([
          "flex w-fit items-center gap-2 text-sm font-medium group-data-[disabled=true]/field:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
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

  def field_description(assigns) do
    ~H"""
    <p
      data-slot="field-description"
      class={
        classes([
          "text-left text-sm leading-normal font-normal text-muted-foreground group-has-data-horizontal/field:text-balance [[data-variant=legend]+&]:-mt-1.5 last:mt-0 nth-last-2:-mt-1 [&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
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

  def field_separator(assigns) do
    ~H"""
    <div
      data-slot="field-separator"
      data-content={to_string(@inner_block != [])}
      class={
        classes(["relative -my-2 h-5 text-sm group-data-[variant=outline]/field-group:-mb-2", @class])
      }
      {@rest}
    >
      <ShadcnLiveview.Components.Separator.separator class="absolute inset-0 top-1/2" />
      <span
        :if={@inner_block != []}
        class="relative mx-auto block w-fit bg-background px-2 text-muted-foreground"
        data-slot="field-separator-content"
      >{render_slot(@inner_block)}</span>
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

  def field_error(assigns) do
    ~H"""
    <div
      data-slot="field-error"
      role="alert"
      class={classes(["text-sm font-normal text-destructive", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
