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
import { fixtures as nativeSelectFixtures } from "./fixtures/native-select"
import { fixtures as progressFixtures } from "./fixtures/progress"
import { ensureSSRDocument } from "./fixtures/ssr-environment"
import { ButtonPreview, NotificationPreview, PaginationPreview } from "./fixtures/basic-live"
import { Alert, AlertDescription, AlertTitle } from "../vendor/shadcn/ui/alert"
import { AspectRatio } from "../vendor/shadcn/ui/aspect-ratio"
import { Attachment, AttachmentDescription, AttachmentTitle } from "../vendor/shadcn/ui/attachment"
import { Avatar, AvatarFallback } from "../vendor/shadcn/ui/avatar"
import { Badge } from "../vendor/shadcn/ui/badge"
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "../vendor/shadcn/ui/breadcrumb"
import { Bubble, BubbleContent } from "../vendor/shadcn/ui/bubble"
import { ButtonGroup } from "../vendor/shadcn/ui/button-group"
import { Button } from "../vendor/shadcn/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../vendor/shadcn/ui/card"
import { DirectionProvider } from "../vendor/shadcn/ui/direction"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "../vendor/shadcn/ui/empty"
import { Field, FieldDescription, FieldGroup, FieldLabel, FieldSeparator, FieldSet } from "../vendor/shadcn/ui/field"
import { InputGroup, InputGroupAddon, InputGroupInput } from "../vendor/shadcn/ui/input-group"
import { Input } from "../vendor/shadcn/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "../vendor/shadcn/ui/item"
import { Kbd } from "../vendor/shadcn/ui/kbd"
import { Label } from "../vendor/shadcn/ui/label"
import { Marker } from "../vendor/shadcn/ui/marker"
import { Message, MessageContent } from "../vendor/shadcn/ui/message"
import { Pagination, PaginationContent, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "../vendor/shadcn/ui/pagination"
import { ScrollArea } from "../vendor/shadcn/ui/scroll-area"
import { Separator } from "../vendor/shadcn/ui/separator"
import { Skeleton } from "../vendor/shadcn/ui/skeleton"
import { Toaster } from "../vendor/shadcn/ui/sonner"
import { Spinner } from "../vendor/shadcn/ui/spinner"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../vendor/shadcn/ui/table"
import { Textarea } from "../vendor/shadcn/ui/textarea"
import { Toggle } from "../vendor/shadcn/ui/toggle"

ensureSSRDocument()

export interface ComponentFixture {
  name: string
  family?: string
  title: string
  category: "actions" | "data-display" | "feedback" | "forms" | "layout" | "navigation" | "overlay"
  renderReact: () => React.ReactElement
  // Browser state owners are separate so the strict SSR reference stays deterministic.
  renderLiveReact?: () => React.ReactElement
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
    heex: `<.button variant="default">Click me</.button>`,
    renderLiveReact: () => <ButtonPreview />,
    liveHeex: `<.button phx-click="preview:increment" phx-value-id="button-clicks">{if Map.get(@state, "button-clicks", 0) == 0, do: "Click me", else: "Clicked #{Map.get(@state, "button-clicks")} times"}</.button>`
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
      <FieldSet className="w-full max-w-md">
        <FieldGroup>
          <Field>
            <FieldLabel htmlFor="field-email">Email address</FieldLabel>
            <Input id="field-email" type="email" placeholder="m@example.com" aria-describedby="field-help" />
            <FieldDescription id="field-help">We will never share your email.</FieldDescription>
          </Field>
        </FieldGroup>
      </FieldSet>
    ),
    heex: `<.field_set class="w-full max-w-md">
  <.field_group>
    <.field>
      <.field_label for="field-email">Email address</.field_label>
      <.input id="field-email" type="email" placeholder="m@example.com" aria-describedby="field-help" />
      <.field_description id="field-help">We will never share your email.</.field_description>
    </.field>
  </.field_group>
</.field_set>`
  },
  {
    name: "field-separator",
    family: "field",
    title: "Field separator",
    category: "forms",
    renderReact: () => (
      <FieldGroup className="w-full max-w-md">
        <FieldSeparator />
        <FieldSeparator className="*:data-[slot=field-separator-content]:bg-card">Or continue with</FieldSeparator>
      </FieldGroup>
    ),
    heex: `<.field_group class="w-full max-w-md">
  <.field_separator />
  <.field_separator class="*:data-[slot=field-separator-content]:bg-card">Or continue with</.field_separator>
</.field_group>`
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
    renderReact: () => <div><Label htmlFor="test-input">Your email address</Label><Input id="test-input" type="email" /></div>,
    heex: `<div><.label for="test-input">Your email address</.label><.input id="test-input" type="email" /></div>`
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
  ...nativeSelectFixtures,
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
</.pagination>`,
    renderLiveReact: () => <PaginationPreview />,
    liveHeex: `<.pagination><.pagination_content>
  <.pagination_item><.pagination_previous href="#page-1" phx-click="preview:page" phx-value-page={max(1, Map.get(@state, "page", 1) - 1)} /></.pagination_item>
  <.pagination_item :for={page <- 1..3}><.pagination_link href={"#page-#{page}"} is_active={Map.get(@state, "page", 1) == page} phx-click="preview:page" phx-value-page={page}>{page}</.pagination_link></.pagination_item>
  <.pagination_item><.pagination_next href="#page-3" phx-click="preview:page" phx-value-page={min(3, Map.get(@state, "page", 1) + 1)} /></.pagination_item>
</.pagination_content></.pagination>`
  },
  ...progressFixtures,
  {
    name: "scroll-area",
    title: "Scroll Area",
    category: "layout",
    renderReact: () => (
      <ScrollArea id="scroll-area-demo" className="h-32 w-48 rounded-md border p-4">
        {Array.from({ length: 20 }, (_, index) => <div key={index} className="py-2">Item {index + 1}</div>)}
      </ScrollArea>
    ),
    heex: `<.scroll_area id="scroll-area-demo" class="h-32 w-48 rounded-md border p-4">
  <div :for={n <- 1..20} class="py-2">Item {n}</div>
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
    heex: `<.toaster />`,
    renderLiveReact: () => <NotificationPreview />,
    liveHeex: `<form phx-submit="preview:toast" class="grid gap-2">
  <.input name="message" aria-label="Notification message" value="Event has been created" />
  <.button type="submit" name="duration" value="0">Show notification</.button>
  <.button type="submit" name="duration" value="1000">Show brief notification</.button>
</form><.toaster id="preview-toaster" />`
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
