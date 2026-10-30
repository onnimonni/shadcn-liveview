defmodule ShadcnLiveview.FormTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "field bindings preserve explicit empty values and escape textarea content" do
    assigns = %{
      form:
        to_form(%{"email" => "saved@example.com", "bio" => "<script>bad</script>"},
          as: "settings"
        )
    }

    document =
      parse(~H"""
      <.input field={@form[:email]} id="override" name="custom" value="" />
      <.textarea field={@form[:bio]} />
      """)

    assert Floki.attribute(document, "#override", "value") == [""]
    assert Floki.attribute(document, "#override", "name") == ["custom"]
    assert Floki.find(document, "script") == []
  end

  test "unused errors are hidden then associated with the control after field use" do
    errors = [email: {"must have at least %{count} characters", [count: 3, validation: :length]}]

    assigns = %{
      form: to_form(%{"email" => "x", "_unused_email" => ""}, as: "settings", errors: errors)
    }

    unused = parse(field_example(assigns))
    assert Floki.find(unused, "[role=alert]") == []
    assert Floki.attribute(unused, "#settings_email", "aria-invalid") == []

    assert Floki.attribute(unused, "#settings_email", "aria-describedby") == [
             "settings_email-description"
           ]

    assigns = %{form: to_form(%{"email" => "x"}, as: "settings", errors: errors)}
    used = parse(field_example(assigns))
    assert Floki.attribute(used, "label", "for") == ["settings_email"]
    assert Floki.attribute(used, "#settings_email", "aria-invalid") == ["true"]

    assert Floki.attribute(used, "#settings_email", "aria-describedby") == [
             "settings_email-description settings_email-errors"
           ]

    assert Floki.text(Floki.find(used, "#settings_email-errors")) ==
             "must have at least 3 characters"
  end

  test "error translation is caller owned and HTML is escaped" do
    assigns = %{
      form: to_form(%{"email" => "x"}, as: "settings", errors: [email: {"invalid", []}])
    }

    document =
      parse(~H"""
      <.form_field
        :let={attrs}
        field={@form[:email]}
        label="Email"
        translate_error={fn _ -> "<b>Translated</b>" end}
      >
        <.input {attrs} />
      </.form_field>
      """)

    assert Floki.text(Floki.find(document, "[role=alert]")) == "<b>Translated</b>"
    assert Floki.find(document, "b") == []
  end

  test "field checkboxes submit false when unchecked and infer checked from string parameters" do
    assigns = %{form: to_form(%{"notify" => "false", "active" => "true"}, as: "settings")}

    document =
      parse(~H"""
      <.checkbox field={@form[:notify]} />
      <.checkbox field={@form[:active]} />
      <.checkbox field={@form[:active]} id="explicit-off" checked={false} disabled />
      """)

    assert Floki.attribute(document, "#settings_notify", "aria-checked") == ["false"]

    assert Floki.attribute(document, "input[type=hidden][name='settings[notify]']", "value") == [
             "false"
           ]

    assert Floki.attribute(document, "input[type=checkbox][checked]", "value") == ["true"]
    assert Floki.attribute(document, "#explicit-off", "aria-checked") == ["false"]
    assert length(Floki.find(document, "input[type=hidden][disabled]")) == 1
  end

  test "native select uses field selection and explicit empty selection wins" do
    assigns = %{form: to_form(%{"zone" => "Europe/Helsinki"}, as: "settings")}

    document =
      parse(~H"""
      <.native_select :let={selection} field={@form[:zone]}>
        <.native_select_option value="UTC" selected={"UTC" in selection}>UTC</.native_select_option>
        <.native_select_option value="Europe/Helsinki" selected={"Europe/Helsinki" in selection}>
          Helsinki
        </.native_select_option>
      </.native_select>
      <.native_select :let={selection} field={@form[:zone]} id="empty" value="">
        <.native_select_option value="" selected={"" in selection}>Choose</.native_select_option>
        <.native_select_option value="Europe/Helsinki" selected={"Europe/Helsinki" in selection}>
          Helsinki
        </.native_select_option>
      </.native_select>
      """)

    assert Floki.attribute(document, "#settings_zone option[selected]", "value") == [
             "Europe/Helsinki"
           ]

    assert Floki.attribute(document, "#empty option[selected]", "value") == [""]
  end

  test "field radio groups infer identity and stay controlled when nothing is selected" do
    assigns = %{form: to_form(%{"plan" => "pro", "tier" => nil}, as: "settings")}

    document =
      parse(~H"""
      <.radio_group :let={plan} field={@form[:plan]}>
        <.radio_group_item context={plan} id="plan-basic" value="basic" />
        <.radio_group_item context={plan} id="plan-pro" value="pro" />
      </.radio_group>
      <.radio_group :let={tier} field={@form[:tier]} aria-invalid="true">
        <.radio_group_item context={tier} id="tier-free" value="free" />
      </.radio_group>
      """)

    assert Floki.attribute(document, "[role=radiogroup]", "id") == [
             "settings_plan",
             "settings_tier"
           ]

    assert Floki.attribute(document, "[role=radiogroup]", "phx-controlled") == ["true", "true"]
    assert Floki.attribute(document, "input[type=radio][checked]", "value") == ["pro"]

    assert Floki.attribute(document, "input[type=radio]", "name") ==
             ["settings[plan]", "settings[plan]", "settings[tier]"]

    assert Floki.attribute(document, "[role=radio][aria-invalid]", "id") == ["tier-free"]
  end

  test "form fields label radio groups through aria-labelledby" do
    assigns = %{form: to_form(%{"plan" => "basic"}, as: "settings")}

    document =
      parse(~H"""
      <.form_field :let={attrs} field={@form[:plan]} label="Plan">
        <.radio_group :let={plan} {attrs}>
          <.radio_group_item context={plan} id="plan-basic" value="basic" />
        </.radio_group>
      </.form_field>
      """)

    assert Floki.attribute(document, "[role=radiogroup]", "aria-labelledby") == [
             "settings_plan-label"
           ]

    assert Floki.text(Floki.find(document, "#settings_plan-label")) =~ "Plan"
  end

  test "label_content slot renders rich label markup with ids and required marker" do
    assigns = %{form: to_form(%{"terms" => "false"}, as: "signup")}

    document =
      parse(~H"""
      <.form_field :let={attrs} field={@form[:terms]} orientation="horizontal" required>
        <.checkbox {attrs} />
        <:label_content>I accept the <a href="/terms">terms</a></:label_content>
      </.form_field>
      """)

    assert Floki.attribute(document, "#signup_terms", "aria-labelledby") == ["signup_terms-label"]

    assert Floki.attribute(document, "#signup_terms-label", "for") == ["signup_terms"]
    assert Floki.attribute(document, "#signup_terms-label a", "href") == ["/terms"]

    assert Floki.text(Floki.find(document, "#signup_terms-label")) =~
             ~r/I accept the\s*terms\s*\*/
  end

  test "form_field requires exactly one of label or label_content" do
    assigns = %{form: to_form(%{"email" => ""}, as: "settings")}

    assert_raise ArgumentError,
                 ~r/requires a `label` attribute or a `<:label_content>` slot/,
                 fn ->
                   parse(~H"""
                   <.form_field :let={attrs} field={@form[:email]}>
                     <.input {attrs} />
                   </.form_field>
                   """)
                 end

    assert_raise ArgumentError, ~r/not both/, fn ->
      parse(~H"""
      <.form_field :let={attrs} field={@form[:email]} label="Email">
        <.input {attrs} />
        <:label_content>Email</:label_content>
      </.form_field>
      """)
    end
  end

  test "multiple field select retains all selected values and uses array form names" do
    assigns = %{form: to_form(%{"zones" => ["UTC", "Europe/Helsinki"]}, as: "settings")}

    document =
      parse(~H"""
      <.native_select :let={selection} field={@form[:zones]} multiple>
        <.native_select_option
          :for={zone <- ["UTC", "Europe/Helsinki", "Asia/Tokyo"]}
          value={zone}
          selected={zone in selection}
        >
          {zone}
        </.native_select_option>
      </.native_select>
      """)

    assert Floki.attribute(document, "select", "name") == ["settings[zones][]"]
    assert Floki.attribute(document, "option[selected]", "value") == ["UTC", "Europe/Helsinki"]
  end

  defp field_example(assigns) do
    ~H"""
    <.form_field :let={attrs} field={@form[:email]} label="Email" description="Receipts" required>
      <.input {attrs} type="email" />
    </.form_field>
    """
  end

  defp parse(rendered) do
    rendered |> Safe.to_iodata() |> IO.iodata_to_binary() |> Floki.parse_document!()
  end
end
