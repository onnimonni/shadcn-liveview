defmodule ShadcnLiveview.Components.Input do
  @moduledoc ~S"""
  Displays a native form input, optionally bound to a `Phoenix.HTML.FormField`.

  Upstream: https://ui.shadcn.com/docs/components/radix/input

  Components: `input/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.input type="email" placeholder="Email" />
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc:
      "Form field such as `@form[:email]`; supplies id, name and value. Explicit attributes win."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  @doc "Accepts a Phoenix.HTML.FormField via field to infer id, name and value. Explicit HTML attributes win; use form_field for labels, help text and used-field errors."

  def input(assigns) do
    assigns = ShadcnLiveview.Form.bind(assigns, :input)

    ~H"""
    <input
      data-slot="input"
      class={
        classes([
          "h-8 w-full min-w-0 rounded-lg border border-input bg-transparent px-2.5 py-1 text-base transition-colors outline-none file:inline-flex file:h-6 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    />
    """
  end
end
