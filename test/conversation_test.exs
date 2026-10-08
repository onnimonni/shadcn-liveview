defmodule ShadcnLiveview.ConversationTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  alias Phoenix.HTML.Safe

  import ShadcnLiveview.Components.MessageScroller
  import ShadcnLiveview.Components.Questionnaire

  test "questionnaire state excludes disabled steps and keeps inactive fieldsets successful" do
    assigns = %{}

    document =
      parse(~H"""
      <.questionnaire
        :let={survey}
        id="survey"
        items={[%{name: "first", required: true}, %{name: "disabled", disabled: true}, %{name: "last"}]}
        item="last"
        statuses={%{"first" => "answered"}}
      >
        <.questionnaire_progress context={survey} />
        <.questionnaire_item :let={question} context={survey} name="first" required>
          <.questionnaire_choice context={question} value="yes" checked>Yes</.questionnaire_choice>
        </.questionnaire_item>
        <.questionnaire_item context={survey} name="disabled" disabled>Unavailable</.questionnaire_item>
        <.questionnaire_item context={survey} name="last">Last question</.questionnaire_item>
        <.questionnaire_previous context={survey} />
        <.questionnaire_next context={survey} />
        <.questionnaire_submit context={survey} />
      </.questionnaire>
      """)

    assert Floki.find(document, "#survey[data-current='2'][data-total='2'][data-last]") != []

    assert Floki.find(document, "fieldset[data-status=answered][hidden][inert]:not([disabled])") !=
             []

    assert Floki.find(document, "input[name=first][checked]") != []
    assert Floki.find(document, "[data-slot=questionnaire-next][hidden][inert]") != []

    assert Floki.find(document, "[data-slot=questionnaire-submit][data-visible]:not([hidden])") !=
             []

    assert Floki.attribute(document, "[role=progressbar]", "aria-valuenow") == ["2"]
  end

  test "invalid and skipped caller states render distinct accessible semantics" do
    assigns = %{}

    document =
      parse(~H"""
      <.questionnaire
        :let={survey}
        id="invalid-survey"
        items={[%{name: "required", required: true}, %{name: "optional"}]}
        invalid={["required"]}
        statuses={%{"optional" => "skipped"}}
      >
        <.questionnaire_item :let={question} context={survey} name="required" required>
          <.questionnaire_error context={question} id="required-error" />
        </.questionnaire_item>
        <.questionnaire_item :let={question} context={survey} name="optional">
          <.questionnaire_choice context={question} value="yes">Yes</.questionnaire_choice>
        </.questionnaire_item>
      </.questionnaire>
      """)

    assert Floki.find(document, "fieldset[data-invalid][aria-invalid=true]") != []
    assert Floki.find(document, "#required-error[role=alert]:not([hidden])") != []
    assert Floki.find(document, "fieldset[data-status=skipped] input[name]") == []
  end

  test "message scroller pending initialization and instance configuration are explicit" do
    assigns = %{}

    document =
      parse(~H"""
      <.message_scroller_provider :let={scroll} default_scroll_position="start">
        <.message_scroller id="start-stream" context={scroll}>
          <.message_scroller_viewport context={scroll} />
        </.message_scroller>
      </.message_scroller_provider>
      <.message_scroller_provider :let={scroll} default_scroll_position="last-anchor" auto_scroll>
        <.message_scroller id="anchor-stream" context={scroll}>
          <.message_scroller_viewport context={scroll} preserve_scroll_on_prepend={false}>
            <.message_scroller_content>
              <.message_scroller_item message_id="latest" scroll_anchor>Latest</.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start" />
        </.message_scroller>
      </.message_scroller_provider>
      """)

    assert Floki.find(document, "#start-stream[data-pending-scroll]") == []
    assert Floki.find(document, "#anchor-stream[data-pending-scroll]") != []
    assert Floki.attribute(document, "#anchor-stream", "phx-value-position") == ["last-anchor"]
    assert Floki.attribute(document, "#anchor-stream", "phx-value-auto-scroll") == ["true"]
    assert Floki.find(document, "[data-message-id=latest][data-scroll-anchor=true]") != []
    assert Floki.find(document, "[data-message-scroller-spacer][hidden][aria-hidden=true]") != []
    assert Floki.find(document, "[data-slot=message-scroller-button][inert][tabindex='-1']") != []
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
