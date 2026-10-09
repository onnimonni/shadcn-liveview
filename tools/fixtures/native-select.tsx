import React from "react"
import type { ComponentFixture } from "../fixtures"
import { NativeSelect, NativeSelectOptGroup, NativeSelectOption } from "../../vendor/shadcn/ui/native-select"

function LiveNativeSelect({ value: initialValue, ...props }: React.ComponentProps<typeof NativeSelect>) {
  const [value, setValue] = React.useState(initialValue)
  return (
    <NativeSelect
      {...props}
      value={value}
      onChange={event => setValue(props.multiple
        ? Array.from(event.currentTarget.selectedOptions, option => option.value)
        : event.currentTarget.value)}
    />
  )
}

export const fixtures: ComponentFixture[] = [
  {
    name: "native-select",
    title: "Native Select",
    category: "forms",
    renderReact: () => (
      <NativeSelect>
        <NativeSelectOption value="1">Option 1</NativeSelectOption>
        <NativeSelectOption value="2">Option 2</NativeSelectOption>
      </NativeSelect>
    ),
    heex: `<.native_select>
  <.native_select_option value="1">Option 1</.native_select_option>
  <.native_select_option value="2">Option 2</.native_select_option>
</.native_select>`
  },
  {
    name: "native-select-default-selection",
    family: "native-select",
    title: "Native Select Default Selection",
    category: "forms",
    renderReact: () => (
      <form id="native-default-form">
        <label htmlFor="native-default">Fruit</label>
        <NativeSelect id="native-default" name="fruit" defaultValue="pear" required aria-describedby="native-default-help" className="w-48 min-w-24 max-w-64">
          <NativeSelectOption value="">Choose fruit</NativeSelectOption>
          <NativeSelectOptGroup label="Fruit">
            <NativeSelectOption value="apple">Apple</NativeSelectOption>
            <NativeSelectOption value="pear" className="font-medium">Pear</NativeSelectOption>
          </NativeSelectOptGroup>
        </NativeSelect>
        <p id="native-default-help">Choose a fruit.</p>
        <button type="reset">Reset</button>
      </form>
    ),
    heex: `<form id="native-default-form">
  <label for="native-default">Fruit</label>
  <.native_select :let={selection} id="native-default" name="fruit" default_value="pear" required aria-describedby="native-default-help" class="w-48 min-w-24 max-w-64">
    <.native_select_option value="" selected={"" in selection}>Choose fruit</.native_select_option>
    <.native_select_opt_group label="Fruit">
      <.native_select_option value="apple" selected={"apple" in selection}>Apple</.native_select_option>
      <.native_select_option value="pear" selected={"pear" in selection} class="font-medium">Pear</.native_select_option>
    </.native_select_opt_group>
  </.native_select>
  <p id="native-default-help">Choose a fruit.</p>
  <button type="reset">Reset</button>
</form>`
  },
  {
    name: "native-select-controlled-small",
    family: "native-select",
    title: "Native Select Controlled Small",
    category: "forms",
    renderReact: () => (
      <NativeSelect id="native-controlled" name="quantity" value={2} onChange={() => {}} size="sm" aria-label="Quantity" aria-invalid="true" className="w-[180px]">
        <NativeSelectOption value={1}>One</NativeSelectOption>
        <NativeSelectOption value={2}>Two</NativeSelectOption>
        <NativeSelectOption value={3} disabled>Three</NativeSelectOption>
      </NativeSelect>
    ),
    renderLiveReact: () => (
      <LiveNativeSelect id="native-controlled" name="quantity" value={2} size="sm" aria-label="Quantity" aria-invalid="true" className="w-[180px]">
        <NativeSelectOption value={1}>One</NativeSelectOption>
        <NativeSelectOption value={2}>Two</NativeSelectOption>
        <NativeSelectOption value={3} disabled>Three</NativeSelectOption>
      </LiveNativeSelect>
    ),
    heex: `<.native_select :let={selection} id="native-controlled" name="quantity" value={2} size="sm" aria-label="Quantity" aria-invalid="true" class="w-[180px]">
  <.native_select_option value={1} selected={"1" in selection}>One</.native_select_option>
  <.native_select_option value={2} selected={"2" in selection}>Two</.native_select_option>
  <.native_select_option value={3} selected={"3" in selection} disabled>Three</.native_select_option>
</.native_select>`
  },
  {
    name: "native-select-disabled-groups",
    family: "native-select",
    title: "Native Select Disabled Groups",
    category: "forms",
    renderReact: () => (
      <form>
        <NativeSelect id="native-disabled" name="region" disabled defaultValue="west" aria-label="Region">
          <NativeSelectOptGroup label="Unavailable" disabled>
            <NativeSelectOption value="east">East</NativeSelectOption>
          </NativeSelectOptGroup>
          <NativeSelectOptGroup label="Available">
            <NativeSelectOption value="west" label="Western region">West</NativeSelectOption>
          </NativeSelectOptGroup>
        </NativeSelect>
      </form>
    ),
    heex: `<form>
  <.native_select :let={selection} id="native-disabled" name="region" disabled default_value="west" aria-label="Region">
    <.native_select_opt_group label="Unavailable" disabled>
      <.native_select_option value="east" selected={"east" in selection}>East</.native_select_option>
    </.native_select_opt_group>
    <.native_select_opt_group label="Available">
      <.native_select_option value="west" selected={"west" in selection} label="Western region">West</.native_select_option>
    </.native_select_opt_group>
  </.native_select>
</form>`
  },
  {
    name: "native-select-multiple-instances",
    family: "native-select",
    title: "Native Select Multiple Instances",
    category: "forms",
    renderReact: () => (
      <form id="native-multiple-form">
        <NativeSelect id="native-multiple" name="colors" multiple defaultValue={["red", "blue"]} aria-label="Colors">
          <NativeSelectOptGroup label="Colors">
            <NativeSelectOption value="red">Red</NativeSelectOption>
            <NativeSelectOption value="green">Green</NativeSelectOption>
            <NativeSelectOption value="blue">Blue</NativeSelectOption>
          </NativeSelectOptGroup>
        </NativeSelect>
        <NativeSelect id="native-second" name="shape" defaultValue="square" aria-label="Shape">
          <NativeSelectOption value="circle">Circle</NativeSelectOption>
          <NativeSelectOption value="square">Square</NativeSelectOption>
        </NativeSelect>
        <button type="reset">Reset</button>
      </form>
    ),
    heex: `<form id="native-multiple-form">
  <.native_select :let={selection} id="native-multiple" name="colors" multiple default_value={["red", "blue"]} aria-label="Colors">
    <.native_select_opt_group label="Colors">
      <.native_select_option value="red" selected={"red" in selection}>Red</.native_select_option>
      <.native_select_option value="green" selected={"green" in selection}>Green</.native_select_option>
      <.native_select_option value="blue" selected={"blue" in selection}>Blue</.native_select_option>
    </.native_select_opt_group>
  </.native_select>
  <.native_select :let={selection} id="native-second" name="shape" default_value="square" aria-label="Shape">
    <.native_select_option value="circle" selected={"circle" in selection}>Circle</.native_select_option>
    <.native_select_option value="square" selected={"square" in selection}>Square</.native_select_option>
  </.native_select>
  <button type="reset">Reset</button>
</form>`
  },
  {
    name: "native-select-empty-controlled",
    family: "native-select",
    title: "Native Select Empty Controlled",
    category: "forms",
    renderReact: () => (
      <NativeSelect value="" onChange={() => {}} name="empty-choice" aria-label="Empty choice">
        <NativeSelectOption value="other">Other</NativeSelectOption>
        <NativeSelectOption value="">None</NativeSelectOption>
      </NativeSelect>
    ),
    renderLiveReact: () => (
      <LiveNativeSelect value="" name="empty-choice" aria-label="Empty choice">
        <NativeSelectOption value="other">Other</NativeSelectOption>
        <NativeSelectOption value="">None</NativeSelectOption>
      </LiveNativeSelect>
    ),
    heex: `<.native_select :let={selection} value="" name="empty-choice" aria-label="Empty choice">
  <.native_select_option value="other" selected={"other" in selection}>Other</.native_select_option>
  <.native_select_option value="" selected={"" in selection}>None</.native_select_option>
</.native_select>`
  },
  {
    name: "native-select-controlled-multiple",
    family: "native-select",
    title: "Native Select Controlled Multiple",
    category: "forms",
    renderReact: () => (
      <NativeSelect multiple value={["b", "c"]} onChange={() => {}} name="letters" aria-label="Letters" size="sm">
        <NativeSelectOption value="a">A</NativeSelectOption>
        <NativeSelectOption value="b">B</NativeSelectOption>
        <NativeSelectOption value="c">C</NativeSelectOption>
      </NativeSelect>
    ),
    renderLiveReact: () => (
      <LiveNativeSelect multiple value={["b", "c"]} name="letters" aria-label="Letters" size="sm">
        <NativeSelectOption value="a">A</NativeSelectOption>
        <NativeSelectOption value="b">B</NativeSelectOption>
        <NativeSelectOption value="c">C</NativeSelectOption>
      </LiveNativeSelect>
    ),
    heex: `<.native_select :let={selection} multiple value={["b", "c"]} name="letters" aria-label="Letters" size="sm">
  <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
  <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
  <.native_select_option value="c" selected={"c" in selection}>C</.native_select_option>
</.native_select>`
  },
  {
    name: "native-select-external-form-empty-multiple",
    family: "native-select",
    title: "Native Select External Form Empty Multiple",
    category: "forms",
    renderReact: () => (
      <div>
        <form id="native-external-form"><button type="reset">Reset</button></form>
        <NativeSelect id="native-external" form="native-external-form" name="external-choices" multiple defaultValue={[]} aria-label="External choices">
          <NativeSelectOption value="a">A</NativeSelectOption>
          <NativeSelectOption value="b">B</NativeSelectOption>
        </NativeSelect>
      </div>
    ),
    heex: `<div>
  <form id="native-external-form"><button type="reset">Reset</button></form>
  <.native_select :let={selection} id="native-external" form="native-external-form" name="external-choices" multiple default_value={[]} aria-label="External choices">
    <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
    <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
  </.native_select>
</div>`
  },
]
