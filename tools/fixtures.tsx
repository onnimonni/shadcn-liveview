if (typeof globalThis.document === "undefined") {
  globalThis.document = {
    querySelector: () => null,
    querySelectorAll: () => [],
    createElement: () => ({ style: {} }),
    body: { style: {} },
    documentElement: { style: {} },
  } as unknown as Document
}

import React from "react"
import { fixtures as linkedFixtures } from "./fixtures/linked"
import { fixtures as modalFixtures } from "./fixtures/modals"
import { fixtures as popupFixtures } from "./fixtures/popups"
import { fixtures as commandFixtures } from "./fixtures/command"
import { fixtures as calendarFixtures } from "./fixtures/calendar"
import { fixtures as layoutFixtures } from "./fixtures/layout"
import { fixtures as chartFixtures } from "./fixtures/chart"
import { fixtures as conversationFixtures } from "./fixtures/conversation"
import { fixtures as selectionFixtures } from "./fixtures/selections"
import { fixtures as controlFixtures } from "./fixtures/controls"
import { fixtures as plainFixtures } from "./fixtures/plain"
import { Alert, AlertDescription, AlertTitle } from "../vendor/shadcn/ui/alert"
import { AspectRatio } from "../vendor/shadcn/ui/aspect-ratio"
import { Attachment, AttachmentDescription, AttachmentTitle } from "../vendor/shadcn/ui/attachment"
import { Avatar, AvatarFallback, AvatarImage } from "../vendor/shadcn/ui/avatar"
import { Badge } from "../vendor/shadcn/ui/badge"
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "../vendor/shadcn/ui/breadcrumb"
import { Bubble, BubbleContent } from "../vendor/shadcn/ui/bubble"
import { ButtonGroup } from "../vendor/shadcn/ui/button-group"
import { Button } from "../vendor/shadcn/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../vendor/shadcn/ui/card"
import { DirectionProvider } from "../vendor/shadcn/ui/direction"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "../vendor/shadcn/ui/empty"
import { Field, FieldDescription, FieldGroup, FieldLabel, FieldSet } from "../vendor/shadcn/ui/field"
import { InputGroup, InputGroupAddon, InputGroupInput } from "../vendor/shadcn/ui/input-group"
import { Input } from "../vendor/shadcn/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "../vendor/shadcn/ui/item"
import { Kbd } from "../vendor/shadcn/ui/kbd"
import { Label } from "../vendor/shadcn/ui/label"
import { Marker } from "../vendor/shadcn/ui/marker"
import { Message, MessageContent } from "../vendor/shadcn/ui/message"
import { NativeSelect, NativeSelectOptGroup, NativeSelectOption } from "../vendor/shadcn/ui/native-select"
import { Pagination, PaginationContent, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "../vendor/shadcn/ui/pagination"
import { Progress } from "../vendor/shadcn/ui/progress"
import { ScrollArea } from "../vendor/shadcn/ui/scroll-area"
import { Separator } from "../vendor/shadcn/ui/separator"
import { Skeleton } from "../vendor/shadcn/ui/skeleton"
import { Toaster } from "../vendor/shadcn/ui/sonner"
import { Spinner } from "../vendor/shadcn/ui/spinner"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../vendor/shadcn/ui/table"
import { Textarea } from "../vendor/shadcn/ui/textarea"
import { Toggle } from "../vendor/shadcn/ui/toggle"

export interface ComponentFixture {
  name: string
  family?: string
  title: string
  category: "actions" | "data-display" | "feedback" | "forms" | "layout" | "navigation" | "overlay"
  renderReact: () => React.ReactElement
  heex: string
  liveHeex?: string
}

export const fixtures: ComponentFixture[] = [
  ...linkedFixtures,
  ...modalFixtures,
  ...popupFixtures,
  ...commandFixtures,
  ...calendarFixtures,
  ...layoutFixtures,
  ...chartFixtures,
  ...conversationFixtures,
  ...selectionFixtures,
  ...controlFixtures,
  ...plainFixtures,
  {
    name: "alert",
    title: "Alert",
    category: "feedback",
    renderReact: () => (
      <Alert>
        <AlertTitle>Heads up!</AlertTitle>
        <AlertDescription>You can add components to your app using the cli.</AlertDescription>
      </Alert>
    ),
    heex: `<.alert>
  <.alert_title>Heads up!</.alert_title>
  <.alert_description>You can add components to your app using the cli.</.alert_description>
</.alert>`
  },
  {
    name: "aspect-ratio",
    title: "Aspect Ratio",
    category: "layout",
    renderReact: () => (
      <AspectRatio ratio={16 / 9} className="bg-muted flex items-center justify-center">
        <span>16:9 Aspect Ratio</span>
      </AspectRatio>
    ),
    heex: `<.aspect_ratio ratio={16 / 9} class="bg-muted flex items-center justify-center">
  <span>16:9 Aspect Ratio</span>
</.aspect_ratio>`
  },
  {
    name: "attachment",
    title: "Attachment",
    category: "data-display",
    renderReact: () => (
      <Attachment>
        <AttachmentTitle>document.pdf</AttachmentTitle>
        <AttachmentDescription>2.4 MB</AttachmentDescription>
      </Attachment>
    ),
    heex: `<.attachment>
  <.attachment_title>document.pdf</.attachment_title>
  <.attachment_description>2.4 MB</.attachment_description>
</.attachment>`
  },
  {
    name: "avatar",
    title: "Avatar",
    category: "data-display",
    renderReact: () => (
      <Avatar>
        <AvatarFallback>CN</AvatarFallback>
      </Avatar>
    ),
    heex: `<.avatar>
  <.avatar_fallback>CN</.avatar_fallback>
</.avatar>`
  },
  {
    name: "badge",
    title: "Badge",
    category: "data-display",
    renderReact: () => <Badge variant="secondary">New Feature</Badge>,
    heex: `<.badge variant="secondary">New Feature</.badge>`
  },
  {
    name: "breadcrumb",
    title: "Breadcrumb",
    category: "navigation",
    renderReact: () => (
      <Breadcrumb>
        <BreadcrumbList>
          <BreadcrumbItem>
            <BreadcrumbLink href="/">Home</BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator />
          <BreadcrumbItem>
            <BreadcrumbPage>Components</BreadcrumbPage>
          </BreadcrumbItem>
        </BreadcrumbList>
      </Breadcrumb>
    ),
    heex: `<.breadcrumb>
  <.breadcrumb_list>
    <.breadcrumb_item>
      <.breadcrumb_link href="/">Home</.breadcrumb_link>
    </.breadcrumb_item>
    <.breadcrumb_separator />
    <.breadcrumb_item>
      <.breadcrumb_page>Components</.breadcrumb_page>
    </.breadcrumb_item>
  </.breadcrumb_list>
</.breadcrumb>`
  },
  {
    name: "bubble",
    title: "Bubble",
    category: "feedback",
    renderReact: () => (
      <Bubble>
        <BubbleContent>Hello from bubble chat!</BubbleContent>
      </Bubble>
    ),
    heex: `<.bubble>
  <.bubble_content>Hello from bubble chat!</.bubble_content>
</.bubble>`
  },
  {
    name: "button-group",
    title: "Button Group",
    category: "actions",
    renderReact: () => (
      <ButtonGroup>
        <Button variant="outline">Left</Button>
        <Button variant="outline">Middle</Button>
        <Button variant="outline">Right</Button>
      </ButtonGroup>
    ),
    heex: `<.button_group>
  <.button variant="outline">Left</.button>
  <.button variant="outline">Middle</.button>
  <.button variant="outline">Right</.button>
</.button_group>`
  },
  {
    name: "button",
    title: "Button",
    category: "actions",
    renderReact: () => <Button variant="default">Click me</Button>,
    heex: `<.button variant="default">Click me</.button>`
  },
  {
    name: "card",
    title: "Card",
    category: "data-display",
    renderReact: () => (
      <Card>
        <CardHeader>
          <CardTitle>Notifications</CardTitle>
          <CardDescription>You have 3 unread messages.</CardDescription>
        </CardHeader>
        <CardContent>
          <p>Everything looks good today.</p>
        </CardContent>
        <CardFooter>
          <Button className="w-full">Mark all as read</Button>
        </CardFooter>
      </Card>
    ),
    heex: `<.card>
  <.card_header>
    <.card_title>Notifications</.card_title>
    <.card_description>You have 3 unread messages.</.card_description>
  </.card_header>
  <.card_content>
    <p>Everything looks good today.</p>
  </.card_content>
  <.card_footer>
    <.button class="w-full">Mark all as read</.button>
  </.card_footer>
</.card>`
  },
  {
    name: "direction",
    title: "Direction",
    category: "layout",
    renderReact: () => (
      <DirectionProvider dir="ltr">
        <div className="p-2 text-sm">Left to right layout</div>
      </DirectionProvider>
    ),
    heex: `<.direction_provider dir="ltr">
  <div class="p-2 text-sm">Left to right layout</div>
</.direction_provider>`
  },
  {
    name: "empty",
    title: "Empty",
    category: "feedback",
    renderReact: () => (
      <Empty>
        <EmptyHeader>
          <EmptyTitle>No data available</EmptyTitle>
          <EmptyDescription>Get started by creating your first project.</EmptyDescription>
        </EmptyHeader>
      </Empty>
    ),
    heex: `<.empty>
  <.empty_header>
    <.empty_title>No data available</.empty_title>
    <.empty_description>Get started by creating your first project.</.empty_description>
  </.empty_header>
</.empty>`
  },
  {
    name: "field",
    title: "Field",
    category: "forms",
    renderReact: () => (
      <FieldSet>
        <FieldGroup>
          <Field>
            <FieldLabel>Email address</FieldLabel>
            <Input type="email" placeholder="m@example.com" />
            <FieldDescription>We will never share your email.</FieldDescription>
          </Field>
        </FieldGroup>
      </FieldSet>
    ),
    heex: `<.field_set>
  <.field_group>
    <.field>
      <.field_label>Email address</.field_label>
      <.input type="email" placeholder="m@example.com" />
      <.field_description>We will never share your email.</.field_description>
    </.field>
  </.field_group>
</.field_set>`
  },
  {
    name: "input-group",
    title: "Input Group",
    category: "forms",
    renderReact: () => (
      <InputGroup>
        <InputGroupAddon>https://</InputGroupAddon>
        <InputGroupInput placeholder="example.com" />
      </InputGroup>
    ),
    heex: `<.input_group>
  <.input_group_addon>https://</.input_group_addon>
  <.input_group_input placeholder="example.com" />
</.input_group>`
  },
  {
    name: "input",
    title: "Input",
    category: "forms",
    renderReact: () => <Input type="email" placeholder="Email" />,
    heex: `<.input type="email" placeholder="Email" />`
  },
  {
    name: "item",
    title: "Item",
    category: "data-display",
    renderReact: () => (
      <Item>
        <ItemContent>
          <ItemTitle>Basic Item</ItemTitle>
          <ItemDescription>Item description text</ItemDescription>
        </ItemContent>
      </Item>
    ),
    heex: `<.item>
  <.item_content>
    <.item_title>Basic Item</.item_title>
    <.item_description>Item description text</.item_description>
  </.item_content>
</.item>`
  },
  {
    name: "kbd",
    title: "Kbd",
    category: "data-display",
    renderReact: () => <Kbd>Ctrl + K</Kbd>,
    heex: `<.kbd>Ctrl + K</.kbd>`
  },
  {
    name: "label",
    title: "Label",
    category: "forms",
    renderReact: () => <Label htmlFor="test-input">Your email address</Label>,
    heex: `<.label for="test-input">Your email address</.label>`
  },
  {
    name: "marker",
    title: "Marker",
    category: "data-display",
    renderReact: () => <Marker className="size-2 bg-emerald-500 rounded-full" />,
    heex: `<.marker class="size-2 bg-emerald-500 rounded-full" />`
  },
  {
    name: "message",
    title: "Message",
    category: "data-display",
    renderReact: () => (
      <Message>
        <MessageContent>Hi, how can I help you today?</MessageContent>
      </Message>
    ),
    heex: `<.message>
  <.message_content>Hi, how can I help you today?</.message_content>
</.message>`
  },
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
  {
    name: "pagination",
    title: "Pagination",
    category: "navigation",
    renderReact: () => (
      <Pagination>
        <PaginationContent>
          <PaginationItem>
            <PaginationPrevious href="#" />
          </PaginationItem>
          <PaginationItem>
            <PaginationLink href="#" isActive>1</PaginationLink>
          </PaginationItem>
          <PaginationItem>
            <PaginationNext href="#" />
          </PaginationItem>
        </PaginationContent>
      </Pagination>
    ),
    heex: `<.pagination>
  <.pagination_content>
    <.pagination_item>
      <.pagination_previous href="#" />
    </.pagination_item>
    <.pagination_item>
      <.pagination_link href="#" is_active={true}>1</.pagination_link>
    </.pagination_item>
    <.pagination_item>
      <.pagination_next href="#" />
    </.pagination_item>
  </.pagination_content>
</.pagination>`
  },
  {
    name: "progress",
    title: "Progress",
    category: "feedback",
    renderReact: () => <Progress value={60} className="w-[60%]" />,
    heex: `<.progress value={60} class="w-[60%]" />`
  },
  ...[
    { name: "absent", props: {}, heexAttrs: "" },
    { name: "null", props: { value: null }, heexAttrs: "value={nil}" },
    { name: "zero", props: { value: 0 }, heexAttrs: "value={0}" },
    { name: "fractional", props: { value: 25.5 }, heexAttrs: "value={25.5}" },
    { name: "complete", props: { value: 100 }, heexAttrs: "value={100}" },
    { name: "custom-max", props: { value: 50, max: 200 }, heexAttrs: "value={50} max={200}" },
    { name: "null-max", props: { value: 40, max: null as unknown as number }, heexAttrs: "value={40} max={nil}" },
    { name: "outside-visual-range", props: { value: 125, max: 80 }, heexAttrs: "value={125} max={80}" },
    {
      name: "custom-class-aria",
      props: { value: 75, className: "w-[180px] min-w-24 max-w-64 h-2 bg-primary", id: "upload-progress", "aria-label": "Upload", "aria-valuetext": "Uploading" },
      heexAttrs: 'value={75} class="w-[180px] min-w-24 max-w-64 h-2 bg-primary" id="upload-progress" aria-label="Upload" aria-valuetext="Uploading"'
    },
  ].map(({ name, props, heexAttrs }): ComponentFixture => ({
    name: `progress-${name}`,
    family: "progress",
    title: `Progress ${name}`,
    category: "feedback",
    renderReact: () => <Progress {...props} />,
    heex: `<.progress ${heexAttrs} />`
  })),
  {
    name: "scroll-area",
    title: "Scroll Area",
    category: "layout",
    renderReact: () => (
      <ScrollArea className="h-32 w-48 rounded-md border p-4">
        Long scrolling text item list inside scroll area.
      </ScrollArea>
    ),
    heex: `<.scroll_area class="h-32 w-48 rounded-md border p-4">
  Long scrolling text item list inside scroll area.
</.scroll_area>`
  },
  {
    name: "separator",
    title: "Separator",
    category: "layout",
    renderReact: () => <Separator className="my-4" />,
    heex: `<.separator class="my-4" />`
  },
  {
    name: "skeleton",
    title: "Skeleton",
    category: "feedback",
    renderReact: () => <Skeleton className="h-4 w-[250px]" />,
    heex: `<.skeleton class="h-4 w-[250px]" />`
  },
  {
    name: "sonner",
    title: "Sonner",
    category: "feedback",
    renderReact: () => <Toaster />,
    heex: `<.toaster />`
  },
  {
    name: "spinner",
    title: "Spinner",
    category: "feedback",
    renderReact: () => <Spinner className="size-6 text-primary" />,
    heex: `<.spinner class="size-6 text-primary" />`
  },
  {
    name: "table",
    title: "Table",
    category: "data-display",
    renderReact: () => (
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-[100px]">Invoice</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="text-right">Amount</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow>
            <TableCell className="font-medium">INV001</TableCell>
            <TableCell>Paid</TableCell>
            <TableCell className="text-right">$250.00</TableCell>
          </TableRow>
        </TableBody>
      </Table>
    ),
    heex: `<.table>
  <.table_header>
    <.table_row>
      <.table_head class="w-[100px]">Invoice</.table_head>
      <.table_head>Status</.table_head>
      <.table_head class="text-right">Amount</.table_head>
    </.table_row>
  </.table_header>
  <.table_body>
    <.table_row>
      <.table_cell class="font-medium">INV001</.table_cell>
      <.table_cell>Paid</.table_cell>
      <.table_cell class="text-right">$250.00</.table_cell>
    </.table_row>
  </.table_body>
</.table>`
  },
  {
    name: "textarea",
    title: "Textarea",
    category: "forms",
    renderReact: () => <Textarea placeholder="Type your message here." />,
    heex: `<.textarea placeholder="Type your message here." />`
  },
  {
    name: "toggle",
    title: "Toggle",
    category: "actions",
    renderReact: () => <Toggle id="italic-toggle" aria-label="Toggle italic">B</Toggle>,
    heex: `<.toggle id="italic-toggle" aria-label="Toggle italic">B</.toggle>`,
    liveHeex: `<.toggle id="italic-toggle" pressed={Map.get(@state, "italic-toggle", false)} on_change="control_change" aria-label="Toggle italic">B</.toggle>`
  },
  
]
