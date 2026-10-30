defmodule ShadcnLiveview.Form do
  @moduledoc """
  Phoenix form bindings and accessible field composition.

      <.form_field field={@form[:email]} label="Email" description="Used for receipts" :let={attrs}>
        <.input {attrs} type="email" />
      </.form_field>

  The slot yields `field`, `id`, `required` and ARIA attributes; use it with input,
  textarea, native_select, checkbox, switch or radio_group. The label is referenced
  by `aria-labelledby`, which also names radio groups. Primitive controls also accept
  `field` directly. Explicit control attributes override inferred field values.
  Errors follow `Phoenix.Component.used_input?/1`. Pass `translate_error` for
  application Gettext translation; the default interpolates validation options.
  Horizontal fields place the control first, then group the label, description
  and errors together. Use this layout for checkbox and switch fields.

  Pass either the `label` string or a `<:label_content>` slot for rich label
  markup such as links; exactly one is required. (Phoenix forbids an attribute
  and a slot sharing the `label` name.) The required marker and label id apply
  to both forms:

      <.form_field field={@form[:terms]} orientation="horizontal" required :let={attrs}>
        <.checkbox {attrs} />
        <:label_content>I accept the <.link navigate={~p"/terms"}>terms</.link></:label_content>
      </.form_field>
  """
  use Phoenix.Component
  import ShadcnLiveview.Components.Field
  alias Phoenix.HTML.Form, as: HTMLForm

  attr :field, Phoenix.HTML.FormField, required: true
  attr :id, :string, default: nil

  attr :label, :string,
    default: nil,
    doc: "plain label text; use `<:label_content>` for rich markup"

  attr :description, :string, default: nil
  attr :required, :boolean, default: false
  attr :orientation, :string, default: "vertical", values: ~w(vertical horizontal responsive)
  attr :class, :any, default: nil
  attr :translate_error, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :label_content, doc: "rich label markup, alternative to `label`"

  def form_field(assigns) do
    validate_label!(assigns)
    id = assigns.id || assigns.field.id
    translate = assigns.translate_error || (&translate_error/1)
    errors = Enum.map(errors(assigns.field), translate)
    label_id = id <> "-label"
    help_id = if assigns.description, do: id <> "-description"
    error_id = if errors != [], do: id <> "-errors"

    control = %{
      field: assigns.field,
      id: id,
      required: assigns.required,
      "aria-labelledby": label_id,
      "aria-invalid": if(errors != [], do: "true"),
      "aria-describedby": described_by([help_id, error_id])
    }

    assigns =
      assign(assigns,
        id: id,
        errors: errors,
        label_id: label_id,
        help_id: help_id,
        error_id: error_id,
        control: control
      )

    ~H"""
    <.field
      orientation={@orientation}
      class={@class}
      data-invalid={if @errors != [], do: "true"}
      {@rest}
    >
      <.field_label :if={@orientation != "horizontal"} id={@label_id} for={@id}>
        <span>{@label || render_slot(@label_content)}<span :if={@required} aria-hidden="true"> *</span></span>
      </.field_label>
      {render_slot(@inner_block, @control)}
      <.field_content :if={@orientation == "horizontal"}>
        <.field_label id={@label_id} for={@id}>
          <span>{@label || render_slot(@label_content)}<span :if={@required} aria-hidden="true"> *</span></span>
        </.field_label>
        <.field_description :if={@description} id={@help_id}>{@description}</.field_description>
        <.field_error :if={@errors != []} id={@error_id}>
          <ul>
            <li :for={error <- @errors}>{error}</li>
          </ul>
        </.field_error>
      </.field_content>
      <.field_description :if={@orientation != "horizontal" && @description} id={@help_id}>
        {@description}
      </.field_description>
      <.field_error :if={@orientation != "horizontal" && @errors != []} id={@error_id}>
        <ul>
          <li :for={error <- @errors}>{error}</li>
        </ul>
      </.field_error>
    </.field>
    """
  end

  defp validate_label!(%{label: label, label_content: content}) do
    case {label, content} do
      {nil, []} ->
        raise ArgumentError,
              "form_field/1 requires a `label` attribute or a `<:label_content>` slot"

      {label, [_ | _]} when not is_nil(label) ->
        raise ArgumentError,
              "form_field/1 accepts either a `label` attribute or a `<:label_content>` slot, not both"

      _ ->
        :ok
    end
  end

  @doc "Interpolates Ecto-style validation errors without requiring Ecto or Gettext."
  def translate_error({message, options}) do
    Enum.reduce(options, message, fn {key, value}, text ->
      String.replace(text, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  def translate_error(message) when is_binary(message), do: message

  @doc false
  def bind(%{field: %Phoenix.HTML.FormField{} = field} = assigns, kind) do
    rest = assigns.rest
    rest = put_inferred(rest, :id, field.id)
    multiple = Map.get(rest, :multiple, Map.get(rest, "multiple", false))
    name = if kind == :select and multiple, do: field.name <> "[]", else: field.name
    rest = put_inferred(rest, :name, name)
    rest = put_inferred(rest, :"aria-invalid", if(errors(field) != [], do: "true"))
    assigns = assign(assigns, :rest, rest)
    bind_value(assigns, field, kind)
  end

  def bind(assigns, _kind), do: assigns

  defp bind_value(assigns, field, :input) do
    assign(assigns, :rest, put_inferred(assigns.rest, :value, field.value))
  end

  defp bind_value(assigns, field, kind) when kind in [:textarea, :select] do
    assign(assigns, :value, if(is_nil(assigns.value), do: field.value, else: assigns.value))
  end

  defp bind_value(assigns, field, :checkbox) do
    assigns
    |> bind_identity(field)
    |> assign(
      :checked,
      if(is_nil(assigns.checked),
        do: HTMLForm.normalize_value("checkbox", field.value),
        else: assigns.checked
      )
    )
  end

  # Bound radio groups stay controlled; a nil field value selects nothing.
  defp bind_value(assigns, field, :radio_group) do
    assigns
    |> bind_identity(field)
    |> assign(:value, if(is_nil(assigns.value), do: to_string(field.value), else: assigns.value))
  end

  defp bind_identity(assigns, field) do
    assigns
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:rest, Map.drop(assigns.rest, [:id, "id", :name, "name"]))
  end

  defp put_inferred(rest, key, value) do
    if Map.has_key?(rest, key) or Map.has_key?(rest, Atom.to_string(key)),
      do: rest,
      else: Map.put(rest, key, value)
  end

  defp errors(field) do
    if used_input?(field), do: field.errors, else: []
  end

  defp described_by(ids) do
    case Enum.reject(ids, &is_nil/1) do
      [] -> nil
      ids -> Enum.join(ids, " ")
    end
  end
end
