import React from "react"
import type { ComponentFixture } from "../fixtures"
import { Combobox, ComboboxContent, ComboboxEmpty, ComboboxInput, ComboboxItem, ComboboxList } from "../../vendor/shadcn/ui/combobox"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList, CommandSeparator, CommandShortcut } from "../../vendor/shadcn/ui/command"
import { InputOTP, InputOTPGroup, InputOTPSeparator, InputOTPSlot } from "../../vendor/shadcn/ui/input-otp"

const frameworks = [{ value: "next", label: "Next.js" }, { value: "phoenix", label: "Phoenix" }]

function comboReact(id: string, options = frameworks, value = "", disabled = false, showClear = false, name?: string) {
  return <Combobox id={id} defaultValue={value || null} disabled={disabled} name={name}>
    <ComboboxInput id={`${id}-input`} disabled={disabled} placeholder="Select framework..." showClear={showClear} />
    <ComboboxContent><ComboboxList>
      {options.map(option => <ComboboxItem key={option.value} value={option.value}>{option.label}</ComboboxItem>)}
    </ComboboxList><ComboboxEmpty>No frameworks found.</ComboboxEmpty></ComboboxContent>
  </Combobox>
}

function comboHeex(id: string, options = frameworks, value = "", disabled = false, showClear = false, name?: string, live = false) {
  const selected = live ? `{Map.get(@state, "${id}", "${value}")}` : `"${value}"`
  const inputValue = live ? options.length ? ` input_value={Map.get(%{${options.map(option => `${JSON.stringify(option.value)} => ${JSON.stringify(option.label)}`).join(", ")}}, Map.get(@state, "${id}", "${value}"), "")}` : ` input_value=""` : ""
  return `<.combobox id="${id}" value=${selected}${inputValue} disabled={${disabled}}${name ? ` name="${name}"` : ""}${live ? ` open={Map.get(@state, "${id}-open", false)} on_change="shadcn:combobox-change"` : ""}>
  <:input :let={combo}><.combobox_input context={combo} id="${id}-input" disabled={${disabled}} placeholder="Select framework..." show_clear={${showClear}} /></:input>
  <:content :let={combo}>
    <.combobox_content context={combo}>
      <.combobox_list context={combo}>
        ${options.map(option => `<.combobox_item context={combo} value="${option.value}">${option.label}</.combobox_item>`).join("\n        ")}
      </.combobox_list>
      <.combobox_empty>No frameworks found.</.combobox_empty>
    </.combobox_content>
  </:content>
</.combobox>`
}

function otpReact(id: string, length: number, value = "", disabled = false, separator = false, name?: string) {
  return <InputOTP id={id} maxLength={length} value={value} disabled={disabled} name={name}>
    <InputOTPGroup>{Array.from({length: separator ? length / 2 : length}, (_, index) => <InputOTPSlot key={index} index={index} />)}</InputOTPGroup>
    {separator && <><InputOTPSeparator /><InputOTPGroup>{Array.from({length: length / 2}, (_, index) => <InputOTPSlot key={index} index={index + length / 2} />)}</InputOTPGroup></>}
  </InputOTP>
}

function otpHeex(id: string, length: number, value = "", disabled = false, separator = false, name?: string, live = false) {
  const slots = (start: number, end: number) => `<.input_otp_group>${Array.from({length: end - start}, (_, offset) => `<.input_otp_slot context={otp} index={${start + offset}} />`).join("")}</.input_otp_group>`
  const selected = live ? `{Map.get(@state, "${id}", "${value}")}` : `"${value}"`
  return `<.input_otp id="${id}" max_length={${length}} value=${selected} disabled={${disabled}}${name ? ` name="${name}"` : ""}${live ? ` required minlength={${length}} pattern="^[0-9]+$" on_change="shadcn:otp-change" on_complete="shadcn:otp-complete" paste_transform="strip-separators"` : ""} :let={otp}>
  ${separator ? `${slots(0, length / 2)}<.input_otp_separator />${slots(length / 2, length)}` : slots(0, length)}
</.input_otp>`
}

export const fixtures: ComponentFixture[] = [
  {
    name: "combobox", title: "Combobox", category: "forms",
    renderReact: () => comboReact("framework-combo"),
    heex: comboHeex("framework-combo"),
    liveHeex: `<form id="framework-form" phx-submit="preview:form">${comboHeex("framework-combo", frameworks, "", false, false, "framework", true)}<button type="submit">Submit framework</button></form>`,
  },
  {
    name: "combobox-empty", family: "combobox", title: "Empty combobox", category: "forms",
    renderReact: () => comboReact("empty-combo", []), heex: comboHeex("empty-combo", []),
    liveHeex: comboHeex("empty-combo", [], "", false, false, undefined, true),
  },
  {
    name: "combobox-value", family: "combobox", title: "Combobox selected form value", category: "forms",
    renderReact: () => comboReact("selected-combo", frameworks, "phoenix", false, true, "framework"),
    heex: comboHeex("selected-combo", frameworks, "phoenix", false, true, "framework"),
    liveHeex: `<form id="selected-framework-form" phx-submit="preview:form">${comboHeex("selected-combo", frameworks, "phoenix", false, true, "framework", true)}<button type="submit">Submit framework</button></form>`,
  },
  {
    name: "combobox-disabled", family: "combobox", title: "Disabled combobox", category: "forms",
    renderReact: () => comboReact("disabled-combo", frameworks, "next", true, true, "framework"),
    heex: comboHeex("disabled-combo", frameworks, "next", true, true, "framework"),
    liveHeex: comboHeex("disabled-combo", frameworks, "next", true, true, "framework", true),
  },
  {
    name: "combobox-multiple-instances", family: "combobox", title: "Independent comboboxes", category: "forms",
    renderReact: () => <div>{comboReact("first-combo")}{comboReact("second-combo", frameworks, "phoenix")}</div>,
    heex: `<div>${comboHeex("first-combo")}${comboHeex("second-combo", frameworks, "phoenix")}</div>`,
    liveHeex: `<div>${comboHeex("first-combo", frameworks, "", false, false, undefined, true)}${comboHeex("second-combo", frameworks, "phoenix", false, false, undefined, true)}</div>`,
  },
  {
    name: "command", title: "Command", category: "forms",
    renderReact: () => <Command id="command-demo" className="rounded-lg border shadow-md">
      <CommandInput placeholder="Type a command or search..." />
      <CommandList><CommandEmpty>No results found.</CommandEmpty><CommandGroup heading="Suggestions">
        <CommandItem value="calendar">Calendar</CommandItem><CommandItem value="emoji">Search Emoji</CommandItem>
      </CommandGroup></CommandList>
    </Command>,
    heex: `<.command id="command-demo" class="rounded-lg border shadow-md" :let={command}>
  <.command_input context={command} placeholder="Type a command or search..." />
  <.command_list context={command}>
    <.command_empty>No results found.</.command_empty>
    <.command_group id="command-suggestions" heading="Suggestions">
      <.command_item id="radix-command-demo-calendar" value="calendar">Calendar</.command_item>
      <.command_item id="radix-command-demo-emoji" value="emoji">Search Emoji</.command_item>
    </.command_group>
  </.command_list>
</.command>`,
    liveHeex: `<.command id="command-demo" value={Map.get(@state, "command-demo", "")} on_select="shadcn:command-change" class="rounded-lg border shadow-md" :let={command}>
  <.command_input context={command} placeholder="Type a command or search..." name="query" />
  <.command_list context={command}><.command_empty>No results found.</.command_empty><.command_group id="command-suggestions" heading="Suggestions">
    <.command_item id="radix-command-demo-calendar" value="calendar">Calendar</.command_item><.command_item id="radix-command-demo-emoji" value="emoji">Search Emoji</.command_item>
  </.command_group></.command_list>
</.command>`,
  },
  {
    name: "command-empty", family: "command", title: "Empty command list", category: "forms",
    renderReact: () => <Command id="empty-command" label="Actions"><CommandInput /><CommandList label="Actions"><CommandEmpty>No actions available.</CommandEmpty></CommandList></Command>,
    heex: `<.command id="empty-command" label="Actions" :let={command}><.command_input context={command} /><.command_list context={command} label="Actions"><.command_empty>No actions available.</.command_empty></.command_list></.command>`,
  },
  {
    name: "command-values-disabled", family: "command", title: "Command values, shortcuts and disabled items", category: "forms",
    renderReact: () => <Command id="valued-command" value="save" label="Editor actions"><CommandInput name="query" value="sav" disabled /><CommandList>
      <CommandEmpty>No actions.</CommandEmpty><CommandGroup heading="Editor"><CommandItem value="save" keywords={["persist"]}>Save<CommandShortcut>⌘S</CommandShortcut></CommandItem><CommandItem value="delete" disabled>Delete</CommandItem></CommandGroup><CommandSeparator /><CommandItem value="close">Close</CommandItem>
    </CommandList></Command>,
    heex: `<.command id="valued-command" value="save" label="Editor actions" :let={command}><.command_input context={command} name="query" value="sav" disabled /><.command_list context={command}>
  <.command_empty>No actions.</.command_empty><.command_group id="editor-actions" heading="Editor"><.command_item id="radix-valued-command-save" value="save" keywords={["persist"]}>Save<.command_shortcut>⌘S</.command_shortcut></.command_item><.command_item id="radix-valued-command-delete" value="delete" disabled>Delete</.command_item></.command_group><.command_separator /><.command_item id="radix-valued-command-close" value="close">Close</.command_item>
</.command_list></.command>`,
  },
  {
    name: "command-multiple-instances", family: "command", title: "Independent commands", category: "forms",
    renderReact: () => <div>{["first-command", "second-command"].map(id => <Command key={id} id={id}><CommandInput /><CommandList><CommandItem value="open">Open</CommandItem></CommandList></Command>)}</div>,
    heex: `<div>${["first-command", "second-command"].map(id => `<.command id="${id}" :let={command}><.command_input context={command} /><.command_list context={command}><.command_item id="radix-${id}-open" value="open">Open</.command_item></.command_list></.command>`).join("")}</div>`,
  },
  {
    name: "input-otp", title: "Input OTP", category: "forms", renderReact: () => otpReact("otp-demo", 4), heex: otpHeex("otp-demo", 4),
    liveHeex: `<form id="otp-form" phx-submit="preview:form">${otpHeex("otp-demo", 4, "", false, false, "code", true)}<button type="submit">Submit code</button><button type="button" id="otp-server-value" value="9021" phx-click="shadcn:otp-change" phx-value-id="otp-demo">Set server code to 9021</button></form>`,
  },
  {
    name: "input-otp-partial-value", family: "input-otp", title: "OTP partially entered value", category: "forms",
    renderReact: () => otpReact("partial-otp", 4, "12", false, false, "code"), heex: otpHeex("partial-otp", 4, "12", false, false, "code"),
  },
  {
    name: "input-otp-separated", family: "input-otp", title: "OTP full value with separator", category: "forms",
    renderReact: () => otpReact("separated-otp", 6, "123456", false, true, "code"), heex: otpHeex("separated-otp", 6, "123456", false, true, "code"),
  },
  {
    name: "input-otp-disabled", family: "input-otp", title: "Disabled OTP", category: "forms",
    renderReact: () => otpReact("disabled-otp", 4, "9876", true, false, "code"), heex: otpHeex("disabled-otp", 4, "9876", true, false, "code"),
  },
  {
    name: "input-otp-validation", family: "input-otp", title: "OTP native form and validation attributes", category: "forms",
    renderReact: () => <InputOTP id="validated-otp" maxLength={4} name="code" form="verification" required readOnly pattern="^[0-9]+$" placeholder="----" aria-invalid="true" aria-label="Verification code">
      <InputOTPGroup>{[0, 1, 2, 3].map(index => <InputOTPSlot key={index} index={index} aria-invalid="true" />)}</InputOTPGroup>
    </InputOTP>,
    heex: `<.input_otp id="validated-otp" max_length={4} name="code" form="verification" required readonly pattern="^[0-9]+$" placeholder="----" aria-invalid="true" aria-label="Verification code" :let={otp}>
  <.input_otp_group><.input_otp_slot context={otp} index={0} aria-invalid="true" /><.input_otp_slot context={otp} index={1} aria-invalid="true" /><.input_otp_slot context={otp} index={2} aria-invalid="true" /><.input_otp_slot context={otp} index={3} aria-invalid="true" /></.input_otp_group>
</.input_otp>`,
  },
  {
    name: "input-otp-multiple-instances", family: "input-otp", title: "Independent OTP fields", category: "forms",
    renderReact: () => <div>{otpReact("first-otp", 4)}{otpReact("second-otp", 4, "23")}</div>,
    heex: `<div>${otpHeex("first-otp", 4)}${otpHeex("second-otp", 4, "23")}</div>`,
  },
]
