import React from "react"
import type { ComponentFixture } from "../fixtures"
import { MessageScroller, MessageScrollerProvider, MessageScrollerViewport, MessageScrollerContent, MessageScrollerItem, MessageScrollerButton } from "../../vendor/shadcn/ui/message-scroller"
import { Questionnaire, QuestionnaireItem, QuestionnaireProgress, QuestionnaireTitle, QuestionnaireDescription, QuestionnaireChoices, QuestionnaireChoice, QuestionnaireChoiceDescription, QuestionnaireInput, QuestionnaireError, QuestionnaireActions, QuestionnairePrevious, QuestionnaireSkip, QuestionnaireNext, QuestionnaireSubmit } from "../../vendor/shadcn/ui/questionnaire"

type Step = { name: string; required?: boolean; disabled?: boolean; choices?: { value: string; disabled?: boolean }[] }
const flowItems: Step[] = [
  { name: "rating", required: true, choices: [{ value: "good" }, { value: "great" }, { value: "unavailable", disabled: true }] },
  { name: "comment" },
  { name: "archived", disabled: true },
]

function Flow({ id, item = "rating", invalid = false, shortcuts = "letters", multiple = false }: { id: string; item?: string; invalid?: boolean; shortcuts?: "letters" | "numbers"; multiple?: boolean }) {
  return <Questionnaire id={id} items={flowItems} item={item} shortcuts={shortcuts}>
    <QuestionnaireProgress />
    <QuestionnaireItem name="rating" required multiple={multiple} invalid={invalid}>
      <QuestionnaireTitle>How was your visit?</QuestionnaireTitle>
      <QuestionnaireDescription id={`${id}-rating-description`}>Choose an answer.</QuestionnaireDescription>
      <QuestionnaireChoices>
        <QuestionnaireChoice value="good">Good<QuestionnaireChoiceDescription>A pleasant visit.</QuestionnaireChoiceDescription></QuestionnaireChoice>
        <QuestionnaireChoice value="great">Great</QuestionnaireChoice>
        <QuestionnaireChoice value="unavailable" disabled>Unavailable</QuestionnaireChoice>
      </QuestionnaireChoices>
      <QuestionnaireError id={`${id}-rating-error`} />
    </QuestionnaireItem>
    <QuestionnaireItem name="comment">
      <QuestionnaireTitle>Anything to add?</QuestionnaireTitle>
      <QuestionnaireInput id={`${id}-comment-input`} defaultValue="Thanks!" placeholder="Your feedback" />
      <QuestionnaireError id={`${id}-comment-error`} />
    </QuestionnaireItem>
    <QuestionnaireItem name="archived" disabled><QuestionnaireTitle>Archived question</QuestionnaireTitle></QuestionnaireItem>
    <QuestionnaireActions><QuestionnairePrevious /><QuestionnaireSkip /><QuestionnaireNext /><QuestionnaireSubmit /></QuestionnaireActions>
  </Questionnaire>
}

function flowHeex(id: string, item = '"rating"', invalid = false, shortcuts = "letters", multiple = false) {
  return `<.questionnaire id="${id}" :let={questionnaire} items={[%{name: "rating", required: true, choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]}, %{name: "comment"}, %{name: "archived", disabled: true}]} item={${item}} shortcuts="${shortcuts}">
  <.questionnaire_progress context={questionnaire} />
  <.questionnaire_item context={questionnaire} name="rating" required multiple={${multiple}} invalid={${invalid}} :let={question}>
    <.questionnaire_title>How was your visit?</.questionnaire_title>
    <.questionnaire_description id="${id}-rating-description">Choose an answer.</.questionnaire_description>
    <.questionnaire_choices context={question}>
      <.questionnaire_choice context={question} value="good" index={0}>Good<.questionnaire_choice_description>A pleasant visit.</.questionnaire_choice_description></.questionnaire_choice>
      <.questionnaire_choice context={question} value="great" index={1}>Great</.questionnaire_choice>
      <.questionnaire_choice context={question} value="unavailable" disabled index={2}>Unavailable</.questionnaire_choice>
    </.questionnaire_choices>
    <.questionnaire_error context={question} id="${id}-rating-error" />
  </.questionnaire_item>
  <.questionnaire_item context={questionnaire} name="comment" :let={question}>
    <.questionnaire_title>Anything to add?</.questionnaire_title>
    <.questionnaire_input context={question} id="${id}-comment-input" value="Thanks!" placeholder="Your feedback" />
    <.questionnaire_error context={question} id="${id}-comment-error" />
  </.questionnaire_item>
  <.questionnaire_item context={questionnaire} name="archived" disabled><.questionnaire_title>Archived question</.questionnaire_title></.questionnaire_item>
  <.questionnaire_actions><.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={questionnaire} /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={questionnaire} /></.questionnaire_actions>
</.questionnaire>`
}

function Stream({ id, position = "end", empty = false }: { id: string; position?: "start" | "end" | "last-anchor"; empty?: boolean }) {
  return <MessageScrollerProvider defaultScrollPosition={position} autoScroll>
    <MessageScroller id={id} className="h-40 border rounded p-4">
      <MessageScrollerViewport>
        <MessageScrollerContent spacerClassName="shrink-0">
          {!empty && <><MessageScrollerItem messageId={`${id}-first`} scrollAnchor><p>First message</p></MessageScrollerItem><MessageScrollerItem messageId={`${id}-second`}><p>Second message</p></MessageScrollerItem><MessageScrollerItem messageId={`${id}-third`} scrollAnchor><p>Latest message</p></MessageScrollerItem></>}
        </MessageScrollerContent>
      </MessageScrollerViewport>
      <MessageScrollerButton direction="start">Earlier</MessageScrollerButton><MessageScrollerButton>Latest</MessageScrollerButton>
    </MessageScroller>
  </MessageScrollerProvider>
}

function streamHeex(id: string, position = "end", empty = false) {
  return `<.message_scroller_provider default_scroll_position="${position}" auto_scroll :let={scroll}>
  <.message_scroller id="${id}" context={scroll} class="h-40 border rounded p-4">
    <.message_scroller_viewport context={scroll}>
      <.message_scroller_content spacer_class="shrink-0">
        ${empty ? "" : `<.message_scroller_item message_id="${id}-first" scroll_anchor><p>First message</p></.message_scroller_item><.message_scroller_item message_id="${id}-second"><p>Second message</p></.message_scroller_item><.message_scroller_item message_id="${id}-third" scroll_anchor><p>Latest message</p></.message_scroller_item>`}
      </.message_scroller_content>
    </.message_scroller_viewport>
    <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
  </.message_scroller>
</.message_scroller_provider>`
}

export const fixtures: ComponentFixture[] = [
  {
    name: "message-scroller", title: "Message Scroller", category: "layout",
    renderReact: () => <MessageScrollerProvider><MessageScroller id="message-scroller-demo" className="h-40 border rounded p-4"><p>Message stream content</p></MessageScroller></MessageScrollerProvider>,
    heex: `<.message_scroller_provider :let={scroll}><.message_scroller id="message-scroller-demo" context={scroll} class="h-40 border rounded p-4"><p>Message stream content</p></.message_scroller></.message_scroller_provider>`,
  },
  ...(["start", "end", "last-anchor"] as const).map(position => ({
    name: `message-scroller-${position}`, family: "message-scroller", title: `Message Scroller ${position}`, category: "layout" as const,
    renderReact: () => <Stream id={`stream-${position}`} position={position} />,
    heex: streamHeex(`stream-${position}`, position),
    ...(position === "end" ? { liveHeex: `<div>${streamHeex("stream-end").replace("</.message_scroller_content>", '<.message_scroller_item :for={n <- Enum.drop(Enum.to_list(1..String.to_integer(to_string(Map.get(@state, "stream-end", 3)))), 3)} message_id={"stream-end-#{n}"} class="h-24"><p>Added message {n}</p></.message_scroller_item></.message_scroller_content>')}<button type="button" phx-click="shadcn:message-count" phx-value-id="stream-end" value="8">Append messages</button><button type="button" phx-click="shadcn:message-count" phx-value-id="stream-end" value="12">Append more</button></div>` } : {}),
  })),
  {
    name: "message-scroller-empty", family: "message-scroller", title: "Empty Message Scroller", category: "layout",
    renderReact: () => <Stream id="stream-empty" empty />, heex: streamHeex("stream-empty", "end", true),
  },
  {
    name: "message-scroller-multiple", family: "message-scroller", title: "Independent Message Scrollers", category: "layout",
    renderReact: () => <div><Stream id="stream-a" position="start" /><Stream id="stream-b" position="last-anchor" /></div>,
    heex: `<div>${streamHeex("stream-a", "start")}${streamHeex("stream-b", "last-anchor")}</div>`,
  },
  {
    name: "questionnaire", title: "Questionnaire", category: "data-display",
    renderReact: () => <Questionnaire id="questionnaire-demo" items={[{ name: "satisfaction" }]}><QuestionnaireItem name="satisfaction">How satisfied are you with our service?</QuestionnaireItem></Questionnaire>,
    heex: `<.questionnaire id="questionnaire-demo" items={[%{name: "satisfaction"}]} :let={questionnaire}><.questionnaire_item context={questionnaire} name="satisfaction">How satisfied are you with our service?</.questionnaire_item></.questionnaire>`,
  },
  {
    name: "questionnaire-flow", family: "questionnaire", title: "Questionnaire Form Flow", category: "forms",
    renderReact: () => <Flow id="questionnaire-flow" />, heex: flowHeex("questionnaire-flow"),
    // Controlled native fields keep server patches and submitted answers in agreement.
    liveHeex: flowHeex("questionnaire-flow", 'Map.get(@state, "questionnaire-flow", "rating")')
      .replace('shortcuts="letters">', 'shortcuts="letters" on_item_change="shadcn:questionnaire-change" phx-value-id="questionnaire-flow" phx-submit="shadcn:questionnaire-submit" phx-change="shadcn:questionnaire-answer">')
      .replace('value="good" index={0}', 'value="good" checked={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "rating") == "good"} index={0}')
      .replace('value="great" index={1}', 'value="great" checked={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "rating") == "great"} index={1}')
      .replace('value="Thanks!"', 'value={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "comment", "Thanks!")}'),
  },
  {
    name: "questionnaire-current-last", family: "questionnaire", title: "Questionnaire Last Question", category: "forms",
    renderReact: () => <Flow id="questionnaire-last" item="comment" />, heex: flowHeex("questionnaire-last", '"comment"'),
  },
  {
    name: "questionnaire-invalid-multiple", family: "questionnaire", title: "Questionnaire Invalid Multiple Answers", category: "forms",
    renderReact: () => <Flow id="questionnaire-invalid" invalid multiple shortcuts="numbers" />, heex: flowHeex("questionnaire-invalid", '"rating"', true, "numbers", true),
  },
  {
    name: "questionnaire-empty", family: "questionnaire", title: "Empty Questionnaire", category: "forms",
    renderReact: () => <Questionnaire id="questionnaire-empty" items={[]}><QuestionnaireProgress /><QuestionnaireActions><QuestionnairePrevious /><QuestionnaireSkip /><QuestionnaireNext /><QuestionnaireSubmit /></QuestionnaireActions></Questionnaire>,
    heex: `<.questionnaire id="questionnaire-empty" :let={questionnaire}><.questionnaire_progress context={questionnaire} /><.questionnaire_actions><.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={questionnaire} /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={questionnaire} /></.questionnaire_actions></.questionnaire>`,
  },
  {
    name: "questionnaire-multiple", family: "questionnaire", title: "Independent Questionnaires", category: "forms",
    renderReact: () => <div><Flow id="questionnaire-a" /><Flow id="questionnaire-b" item="comment" /></div>,
    heex: `<div>${flowHeex("questionnaire-a")}${flowHeex("questionnaire-b", '"comment"')}</div>`,
  },
  {
    name: "questionnaire-selected-choice", family: "questionnaire", title: "Questionnaire Controlled Selection", category: "forms",
    renderReact: () => <Questionnaire id="questionnaire-selected" items={[{ name: "color", choices: [{ value: "red" }, { value: "blue" }] }]} shortcuts="numbers"><QuestionnaireItem name="color"><QuestionnaireTitle>Color</QuestionnaireTitle><QuestionnaireChoices><QuestionnaireChoice value="red" checked>Red</QuestionnaireChoice><QuestionnaireChoice value="blue" defaultChecked>Blue</QuestionnaireChoice></QuestionnaireChoices><QuestionnaireSubmit disabled /></QuestionnaireItem></Questionnaire>,
    heex: `<.questionnaire id="questionnaire-selected" items={[%{name: "color", choices: [%{value: "red"}, %{value: "blue"}]}]} shortcuts="numbers" :let={questionnaire}><.questionnaire_item context={questionnaire} name="color" :let={question}><.questionnaire_title>Color</.questionnaire_title><.questionnaire_choices context={question}><.questionnaire_choice context={question} value="red" checked index={0}>Red</.questionnaire_choice><.questionnaire_choice context={question} value="blue" default_checked index={1}>Blue</.questionnaire_choice></.questionnaire_choices><.questionnaire_submit context={questionnaire} disabled /></.questionnaire_item></.questionnaire>`,
  },
  {
    name: "message-scroller-default-button", family: "message-scroller", title: "Message Scroller Accessible Button", category: "layout",
    renderReact: () => <MessageScrollerProvider defaultScrollPosition="start"><MessageScroller id="stream-buttons"><MessageScrollerButton /><MessageScrollerButton direction="start" /></MessageScroller></MessageScrollerProvider>,
    heex: `<.message_scroller_provider default_scroll_position="start" :let={scroll}><.message_scroller id="stream-buttons" context={scroll}><.message_scroller_button /><.message_scroller_button direction="start" /></.message_scroller></.message_scroller_provider>`,
  },
  {
    name: "questionnaire-input-states", family: "questionnaire", title: "Questionnaire Empty and Disabled Inputs", category: "forms",
    renderReact: () => <Questionnaire id="questionnaire-inputs" items={[{ name: "email", required: true }]} noValidate={false}><QuestionnaireItem name="email" required><QuestionnaireTitle>Your email</QuestionnaireTitle><QuestionnaireInput id="questionnaire-email" type="email" placeholder="you@example.com" required /><QuestionnaireInput id="questionnaire-locked" defaultValue="locked" disabled /><QuestionnaireError id="questionnaire-email-error" /></QuestionnaireItem></Questionnaire>,
    heex: `<.questionnaire id="questionnaire-inputs" items={[%{name: "email", required: true}]} no_validate={false} :let={questionnaire}><.questionnaire_item context={questionnaire} name="email" required :let={question}><.questionnaire_title>Your email</.questionnaire_title><.questionnaire_input context={question} id="questionnaire-email" type="email" placeholder="you@example.com" required /><.questionnaire_input context={question} id="questionnaire-locked" value="locked" disabled /><.questionnaire_error context={question} id="questionnaire-email-error" /></.questionnaire_item></.questionnaire>`,
  },
]
