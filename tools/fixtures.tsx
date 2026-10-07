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
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "../vendor/shadcn/ui/accordion"
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "../vendor/shadcn/ui/alert-dialog"
import { Alert, AlertDescription, AlertTitle } from "../vendor/shadcn/ui/alert"
import { AspectRatio } from "../vendor/shadcn/ui/aspect-ratio"
import { Attachment, AttachmentDescription, AttachmentTitle } from "../vendor/shadcn/ui/attachment"
import { Avatar, AvatarFallback, AvatarImage } from "../vendor/shadcn/ui/avatar"
import { Badge } from "../vendor/shadcn/ui/badge"
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbPage, BreadcrumbSeparator } from "../vendor/shadcn/ui/breadcrumb"
import { Bubble, BubbleContent } from "../vendor/shadcn/ui/bubble"
import { ButtonGroup } from "../vendor/shadcn/ui/button-group"
import { Button } from "../vendor/shadcn/ui/button"
import { Calendar } from "../vendor/shadcn/ui/calendar"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../vendor/shadcn/ui/card"
import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from "../vendor/shadcn/ui/carousel"
import { ChartContainer } from "../vendor/shadcn/ui/chart"
import { Checkbox } from "../vendor/shadcn/ui/checkbox"
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "../vendor/shadcn/ui/collapsible"
import { Combobox, ComboboxContent, ComboboxInput, ComboboxItem, ComboboxList } from "../vendor/shadcn/ui/combobox"
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "../vendor/shadcn/ui/command"
import { ContextMenu, ContextMenuContent, ContextMenuItem, ContextMenuTrigger } from "../vendor/shadcn/ui/context-menu"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "../vendor/shadcn/ui/dialog"
import { DirectionProvider } from "../vendor/shadcn/ui/direction"
import { Drawer, DrawerContent, DrawerDescription, DrawerHeader, DrawerTitle } from "../vendor/shadcn/ui/drawer"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "../vendor/shadcn/ui/dropdown-menu"
import { Empty, EmptyDescription, EmptyHeader, EmptyTitle } from "../vendor/shadcn/ui/empty"
import { Field, FieldDescription, FieldGroup, FieldLabel, FieldSet } from "../vendor/shadcn/ui/field"
import { HoverCard, HoverCardContent, HoverCardTrigger } from "../vendor/shadcn/ui/hover-card"
import { InputGroup, InputGroupAddon, InputGroupInput } from "../vendor/shadcn/ui/input-group"
import { InputOTP, InputOTPGroup, InputOTPSlot } from "../vendor/shadcn/ui/input-otp"
import { Input } from "../vendor/shadcn/ui/input"
import { Item, ItemContent, ItemDescription, ItemTitle } from "../vendor/shadcn/ui/item"
import { Kbd } from "../vendor/shadcn/ui/kbd"
import { Label } from "../vendor/shadcn/ui/label"
import { Marker } from "../vendor/shadcn/ui/marker"
import { Menubar, MenubarContent, MenubarItem, MenubarMenu, MenubarTrigger } from "../vendor/shadcn/ui/menubar"
import { MessageScroller, MessageScrollerProvider } from "../vendor/shadcn/ui/message-scroller"
import { Message, MessageContent } from "../vendor/shadcn/ui/message"
import { NativeSelect, NativeSelectOption } from "../vendor/shadcn/ui/native-select"
import { NavigationMenu, NavigationMenuItem, NavigationMenuLink, NavigationMenuList } from "../vendor/shadcn/ui/navigation-menu"
import { Pagination, PaginationContent, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "../vendor/shadcn/ui/pagination"
import { Popover, PopoverContent, PopoverTrigger } from "../vendor/shadcn/ui/popover"
import { Progress } from "../vendor/shadcn/ui/progress"
import { Questionnaire, QuestionnaireItem } from "../vendor/shadcn/ui/questionnaire"
import { RadioGroup, RadioGroupItem } from "../vendor/shadcn/ui/radio-group"
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "../vendor/shadcn/ui/resizable"
import { ScrollArea } from "../vendor/shadcn/ui/scroll-area"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../vendor/shadcn/ui/select"
import { Separator } from "../vendor/shadcn/ui/separator"
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "../vendor/shadcn/ui/sheet"
import { Sidebar, SidebarContent, SidebarHeader, SidebarProvider } from "../vendor/shadcn/ui/sidebar"
import { Skeleton } from "../vendor/shadcn/ui/skeleton"
import { Slider } from "../vendor/shadcn/ui/slider"
import { Toaster } from "../vendor/shadcn/ui/sonner"
import { Spinner } from "../vendor/shadcn/ui/spinner"
import { Switch } from "../vendor/shadcn/ui/switch"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../vendor/shadcn/ui/table"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../vendor/shadcn/ui/tabs"
import { Textarea } from "../vendor/shadcn/ui/textarea"
import { ToggleGroup, ToggleGroupItem } from "../vendor/shadcn/ui/toggle-group"
import { Toggle } from "../vendor/shadcn/ui/toggle"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "../vendor/shadcn/ui/tooltip"

export interface ComponentFixture {
  name: string
  title: string
  category: "actions" | "data-display" | "feedback" | "forms" | "layout" | "navigation" | "overlay"
  renderReact: () => React.ReactElement
  heex: string
}

export const fixtures: ComponentFixture[] = [
  {
    name: "accordion",
    title: "Accordion",
    category: "data-display",
    renderReact: () => (
      <Accordion type="single" defaultValue="item-1">
        <AccordionItem value="item-1">
          <AccordionTrigger>Is it accessible?</AccordionTrigger>
          <AccordionContent>Yes. It adheres to the WAI-ARIA design pattern.</AccordionContent>
        </AccordionItem>
      </Accordion>
    ),
    heex: `<.accordion type="single" default_value="item-1">
  <.accordion_item value="item-1">
    <.accordion_trigger>Is it accessible?</.accordion_trigger>
    <.accordion_content>Yes. It adheres to the WAI-ARIA design pattern.</.accordion_content>
  </.accordion_item>
</.accordion>`
  },
  {
    name: "alert-dialog",
    title: "Alert Dialog",
    category: "overlay",
    renderReact: () => (
      <AlertDialog open>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete your account.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction>Continue</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    ),
    heex: `<.alert_dialog open={true}>
  <.alert_dialog_content>
    <.alert_dialog_header>
      <.alert_dialog_title>Are you absolutely sure?</.alert_dialog_title>
      <.alert_dialog_description>
        This action cannot be undone. This will permanently delete your account.
      </.alert_dialog_description>
    </.alert_dialog_header>
    <.alert_dialog_footer>
      <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
      <.alert_dialog_action>Continue</.alert_dialog_action>
    </.alert_dialog_footer>
  </.alert_dialog_content>
</.alert_dialog>`
  },
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
    name: "calendar",
    title: "Calendar",
    category: "forms",
    renderReact: () => <Calendar />,
    heex: `<.calendar />`
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
    name: "carousel",
    title: "Carousel",
    category: "data-display",
    renderReact: () => (
      <Carousel className="w-full max-w-xs">
        <CarouselContent>
          <CarouselItem>
            <div className="p-1">
              <Card>
                <CardContent className="flex aspect-square items-center justify-center p-6">
                  <span className="text-4xl font-semibold">1</span>
                </CardContent>
              </Card>
            </div>
          </CarouselItem>
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    ),
    heex: `<.carousel class="w-full max-w-xs">
  <.carousel_content>
    <.carousel_item>
      <div class="p-1">
        <.card>
          <.card_content class="flex aspect-square items-center justify-center p-6">
            <span class="text-4xl font-semibold">1</span>
          </.card_content>
        </.card>
      </div>
    </.carousel_item>
  </.carousel_content>
  <.carousel_previous />
  <.carousel_next />
</.carousel>`
  },
  {
    name: "chart",
    title: "Chart",
    category: "data-display",
    renderReact: () => (
      <ChartContainer config={{ desktop: { label: "Desktop", color: "#2563eb" } }} className="min-h-[200px] w-full">
        <div className="p-4 text-center text-muted-foreground">Chart Viewport</div>
      </ChartContainer>
    ),
    heex: `<.chart_container config={%{desktop: %{label: "Desktop", color: "#2563eb"}}} class="min-h-[200px] w-full">
  <div class="p-4 text-center text-muted-foreground">Chart Viewport</div>
</.chart_container>`
  },
  {
    name: "checkbox",
    title: "Checkbox",
    category: "forms",
    renderReact: () => (
      <div className="flex items-center space-x-2">
        <Checkbox id="terms" />
        <label htmlFor="terms" className="text-sm font-medium leading-none">Accept terms</label>
      </div>
    ),
    heex: `<div class="flex items-center space-x-2">
  <.checkbox id="terms" />
  <label for="terms" class="text-sm font-medium leading-none">Accept terms</label>
</div>`
  },
  {
    name: "collapsible",
    title: "Collapsible",
    category: "layout",
    renderReact: () => (
      <Collapsible open>
        <CollapsibleTrigger className="px-4 py-2 text-sm font-medium">Toggle Details</CollapsibleTrigger>
        <CollapsibleContent className="px-4 py-2 text-sm">
          Here is collapsible content.
        </CollapsibleContent>
      </Collapsible>
    ),
    heex: `<.collapsible open={true}>
  <.collapsible_trigger class="px-4 py-2 text-sm font-medium">Toggle Details</.collapsible_trigger>
  <.collapsible_content class="px-4 py-2 text-sm">
    Here is collapsible content.
  </.collapsible_content>
</.collapsible>`
  },
  {
    name: "combobox",
    title: "Combobox",
    category: "forms",
    renderReact: () => (
      <Combobox>
        <ComboboxInput placeholder="Select framework..." />
        <ComboboxContent>
          <ComboboxList>
            <ComboboxItem value="next">Next.js</ComboboxItem>
            <ComboboxItem value="phoenix">Phoenix</ComboboxItem>
          </ComboboxList>
        </ComboboxContent>
      </Combobox>
    ),
    heex: `<.combobox>
  <.combobox_input placeholder="Select framework..." />
  <.combobox_content>
    <.combobox_list>
      <.combobox_item value="next">Next.js</.combobox_item>
      <.combobox_item value="phoenix">Phoenix</.combobox_item>
    </.combobox_list>
  </.combobox_content>
</.combobox>`
  },
  {
    name: "command",
    title: "Command",
    category: "forms",
    renderReact: () => (
      <Command className="rounded-lg border shadow-md">
        <CommandInput placeholder="Type a command or search..." />
        <CommandList>
          <CommandEmpty>No results found.</CommandEmpty>
          <CommandGroup heading="Suggestions">
            <CommandItem>Calendar</CommandItem>
            <CommandItem>Search Emoji</CommandItem>
          </CommandGroup>
        </CommandList>
      </Command>
    ),
    heex: `<.command class="rounded-lg border shadow-md">
  <.command_input placeholder="Type a command or search..." />
  <.command_list>
    <.command_empty>No results found.</.command_empty>
    <.command_group heading="Suggestions">
      <.command_item>Calendar</.command_item>
      <.command_item>Search Emoji</.command_item>
    </.command_group>
  </.command_list>
</.command>`
  },
  {
    name: "context-menu",
    title: "Context Menu",
    category: "overlay",
    renderReact: () => (
      <ContextMenu>
        <ContextMenuTrigger className="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">
          Right click here
        </ContextMenuTrigger>
        <ContextMenuContent>
          <ContextMenuItem>Back</ContextMenuItem>
          <ContextMenuItem>Forward</ContextMenuItem>
          <ContextMenuItem>Reload</ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>
    ),
    heex: `<.context_menu>
  <.context_menu_trigger class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">
    Right click here
  </.context_menu_trigger>
  <.context_menu_content>
    <.context_menu_item>Back</.context_menu_item>
    <.context_menu_item>Forward</.context_menu_item>
    <.context_menu_item>Reload</.context_menu_item>
  </.context_menu_content>
</.context_menu>`
  },
  {
    name: "dialog",
    title: "Dialog",
    category: "overlay",
    renderReact: () => (
      <Dialog open>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit profile</DialogTitle>
            <DialogDescription>
              Make changes to your profile here. Click save when you are done.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button type="submit">Save changes</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    ),
    heex: `<.dialog open={true}>
  <.dialog_content>
    <.dialog_header>
      <.dialog_title>Edit profile</.dialog_title>
      <.dialog_description>
        Make changes to your profile here. Click save when you are done.
      </.dialog_description>
    </.dialog_header>
    <.dialog_footer>
      <.button type="submit">Save changes</.button>
    </.dialog_footer>
  </.dialog_content>
</.dialog>`
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
    name: "drawer",
    title: "Drawer",
    category: "overlay",
    renderReact: () => (
      <Drawer open>
        <DrawerContent>
          <DrawerHeader>
            <DrawerTitle>Drawer Title</DrawerTitle>
            <DrawerDescription>Drawer Description goes here.</DrawerDescription>
          </DrawerHeader>
        </DrawerContent>
      </Drawer>
    ),
    heex: `<.drawer open={true}>
  <.drawer_content>
    <.drawer_header>
      <.drawer_title>Drawer Title</.drawer_title>
      <.drawer_description>Drawer Description goes here.</.drawer_description>
    </.drawer_header>
  </.drawer_content>
</.drawer>`
  },
  {
    name: "dropdown-menu",
    title: "Dropdown Menu",
    category: "overlay",
    renderReact: () => (
      <DropdownMenu open>
        <DropdownMenuTrigger asChild>
          <Button variant="outline">Open Menu</Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent>
          <DropdownMenuLabel>My Account</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem>Profile</DropdownMenuItem>
          <DropdownMenuItem>Billing</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
    heex: `<.dropdown_menu open={true}>
  <.dropdown_menu_trigger>
    <.button variant="outline">Open Menu</.button>
  </.dropdown_menu_trigger>
  <.dropdown_menu_content>
    <.dropdown_menu_label>My Account</.dropdown_menu_label>
    <.dropdown_menu_separator />
    <.dropdown_menu_item>Profile</.dropdown_menu_item>
    <.dropdown_menu_item>Billing</.dropdown_menu_item>
  </.dropdown_menu_content>
</.dropdown_menu>`
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
    name: "hover-card",
    title: "Hover Card",
    category: "overlay",
    renderReact: () => (
      <HoverCard open>
        <HoverCardTrigger asChild>
          <Button variant="link">@nextjs</Button>
        </HoverCardTrigger>
        <HoverCardContent className="w-80">
          <p className="text-sm">The React Framework for the Web.</p>
        </HoverCardContent>
      </HoverCard>
    ),
    heex: `<.hover_card open={true}>
  <.hover_card_trigger>
    <.button variant="link">@nextjs</.button>
  </.hover_card_trigger>
  <.hover_card_content class="w-80">
    <p class="text-sm">The React Framework for the Web.</p>
  </.hover_card_content>
</.hover_card>`
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
    name: "input-otp",
    title: "Input OTP",
    category: "forms",
    renderReact: () => (
      <InputOTP maxLength={4}>
        <InputOTPGroup>
          <InputOTPSlot index={0} />
          <InputOTPSlot index={1} />
          <InputOTPSlot index={2} />
          <InputOTPSlot index={3} />
        </InputOTPGroup>
      </InputOTP>
    ),
    heex: `<.input_otp max_length={4}>
  <.input_otp_group>
    <.input_otp_slot index={0} />
    <.input_otp_slot index={1} />
    <.input_otp_slot index={2} />
    <.input_otp_slot index={3} />
  </.input_otp_group>
</.input_otp>`
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
    name: "menubar",
    title: "Menubar",
    category: "navigation",
    renderReact: () => (
      <Menubar>
        <MenubarMenu>
          <MenubarTrigger>File</MenubarTrigger>
          <MenubarContent>
            <MenubarItem>New Tab</MenubarItem>
            <MenubarItem>New Window</MenubarItem>
          </MenubarContent>
        </MenubarMenu>
      </Menubar>
    ),
    heex: `<.menubar>
  <.menubar_menu>
    <.menubar_trigger>File</.menubar_trigger>
    <.menubar_content>
      <.menubar_item>New Tab</.menubar_item>
      <.menubar_item>New Window</.menubar_item>
    </.menubar_content>
  </.menubar_menu>
</.menubar>`
  },
  {
    name: "message-scroller",
    title: "Message Scroller",
    category: "layout",
    renderReact: () => (
      <MessageScrollerProvider>
        <MessageScroller className="h-40 border rounded p-4">
          <p>Message stream content</p>
        </MessageScroller>
      </MessageScrollerProvider>
    ),
    heex: `<.message_scroller_provider>
  <.message_scroller class="h-40 border rounded p-4">
    <p>Message stream content</p>
  </.message_scroller>
</.message_scroller_provider>`
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
    name: "navigation-menu",
    title: "Navigation Menu",
    category: "navigation",
    renderReact: () => (
      <NavigationMenu>
        <NavigationMenuList>
          <NavigationMenuItem>
            <NavigationMenuLink href="/docs">Documentation</NavigationMenuLink>
          </NavigationMenuItem>
        </NavigationMenuList>
      </NavigationMenu>
    ),
    heex: `<.navigation_menu>
  <.navigation_menu_list>
    <.navigation_menu_item>
      <.navigation_menu_link href="/docs">Documentation</.navigation_menu_link>
    </.navigation_menu_item>
  </.navigation_menu_list>
</.navigation_menu>`
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
    name: "popover",
    title: "Popover",
    category: "overlay",
    renderReact: () => (
      <Popover open>
        <PopoverTrigger asChild>
          <Button variant="outline">Open popover</Button>
        </PopoverTrigger>
        <PopoverContent className="w-80">
          <p className="text-sm">Dimensions settings.</p>
        </PopoverContent>
      </Popover>
    ),
    heex: `<.popover open={true}>
  <.popover_trigger>
    <.button variant="outline">Open popover</.button>
  </.popover_trigger>
  <.popover_content class="w-80">
    <p class="text-sm">Dimensions settings.</p>
  </.popover_content>
</.popover>`
  },
  {
    name: "progress",
    title: "Progress",
    category: "feedback",
    renderReact: () => <Progress value={60} className="w-[60%]" />,
    heex: `<.progress value={60} class="w-[60%]" />`
  },
  {
    name: "questionnaire",
    title: "Questionnaire",
    category: "data-display",
    renderReact: () => (
      <Questionnaire>
        <QuestionnaireItem>How satisfied are you with our service?</QuestionnaireItem>
      </Questionnaire>
    ),
    heex: `<.questionnaire>
  <.questionnaire_item>How satisfied are you with our service?</.questionnaire_item>
</.questionnaire>`
  },
  {
    name: "radio-group",
    title: "Radio Group",
    category: "forms",
    renderReact: () => (
      <RadioGroup defaultValue="comfortable">
        <div className="flex items-center space-x-2">
          <RadioGroupItem value="default" id="r1" />
          <Label htmlFor="r1">Default</Label>
        </div>
        <div className="flex items-center space-x-2">
          <RadioGroupItem value="comfortable" id="r2" />
          <Label htmlFor="r2">Comfortable</Label>
        </div>
      </RadioGroup>
    ),
    heex: `<.radio_group default_value="comfortable">
  <div class="flex items-center space-x-2">
    <.radio_group_item value="default" id="r1" />
    <.label for="r1">Default</.label>
  </div>
  <div class="flex items-center space-x-2">
    <.radio_group_item value="comfortable" id="r2" />
    <.label for="r2">Comfortable</.label>
  </div>
</.radio_group>`
  },
  {
    name: "resizable",
    title: "Resizable",
    category: "layout",
    renderReact: () => (
      <ResizablePanelGroup direction="horizontal" className="max-w-md rounded-lg border">
        <ResizablePanel defaultSize={50}>
          <div className="flex h-[100px] items-center justify-center p-6">One</div>
        </ResizablePanel>
        <ResizableHandle />
        <ResizablePanel defaultSize={50}>
          <div className="flex h-[100px] items-center justify-center p-6">Two</div>
        </ResizablePanel>
      </ResizablePanelGroup>
    ),
    heex: `<.resizable_panel_group direction="horizontal" class="max-w-md rounded-lg border">
  <.resizable_panel default_size={50}>
    <div class="flex h-[100px] items-center justify-center p-6">One</div>
  </.resizable_panel>
  <.resizable_handle />
  <.resizable_panel default_size={50}>
    <div class="flex h-[100px] items-center justify-center p-6">Two</div>
  </.resizable_panel>
</.resizable_panel_group>`
  },
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
    name: "select",
    title: "Select",
    category: "forms",
    renderReact: () => (
      <Select open>
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Select a fruit" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="apple">Apple</SelectItem>
          <SelectItem value="banana">Banana</SelectItem>
        </SelectContent>
      </Select>
    ),
    heex: `<.select open={true}>
  <.select_trigger class="w-[180px]">
    <.select_value placeholder="Select a fruit" />
  </.select_trigger>
  <.select_content>
    <.select_item value="apple">Apple</.select_item>
    <.select_item value="banana">Banana</.select_item>
  </.select_content>
</.select>`
  },
  {
    name: "separator",
    title: "Separator",
    category: "layout",
    renderReact: () => <Separator className="my-4" />,
    heex: `<.separator class="my-4" />`
  },
  {
    name: "sheet",
    title: "Sheet",
    category: "overlay",
    renderReact: () => (
      <Sheet open>
        <SheetContent>
          <SheetHeader>
            <SheetTitle>Edit profile</SheetTitle>
            <SheetDescription>Make changes to your profile here.</SheetDescription>
          </SheetHeader>
        </SheetContent>
      </Sheet>
    ),
    heex: `<.sheet open={true}>
  <.sheet_content>
    <.sheet_header>
      <.sheet_title>Edit profile</.sheet_title>
      <.sheet_description>Make changes to your profile here.</.sheet_description>
    </.sheet_header>
  </.sheet_content>
</.sheet>`
  },
  {
    name: "sidebar",
    title: "Sidebar",
    category: "navigation",
    renderReact: () => (
      <SidebarProvider>
        <Sidebar>
          <SidebarHeader>
            <h4 className="font-semibold text-sm">Application</h4>
          </SidebarHeader>
          <SidebarContent>
            <div className="p-2 text-sm text-muted-foreground">Nav items</div>
          </SidebarContent>
        </Sidebar>
      </SidebarProvider>
    ),
    heex: `<.sidebar_provider>
  <.sidebar>
    <.sidebar_header>
      <h4 class="font-semibold text-sm">Application</h4>
    </.sidebar_header>
    <.sidebar_content>
      <div class="p-2 text-sm text-muted-foreground">Nav items</div>
    </.sidebar_content>
  </.sidebar>
</.sidebar_provider>`
  },
  {
    name: "skeleton",
    title: "Skeleton",
    category: "feedback",
    renderReact: () => <Skeleton className="h-4 w-[250px]" />,
    heex: `<.skeleton class="h-4 w-[250px]" />`
  },
  {
    name: "slider",
    title: "Slider",
    category: "forms",
    renderReact: () => <Slider defaultValue={[50]} max={100} step={1} className="w-[60%]" />,
    heex: `<.slider default_value={[50]} max={100} step={1} class="w-[60%]" />`
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
    name: "switch",
    title: "Switch",
    category: "forms",
    renderReact: () => <Switch id="airplane-mode" />,
    heex: `<.switch id="airplane-mode" />`
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
    name: "tabs",
    title: "Tabs",
    category: "navigation",
    renderReact: () => (
      <Tabs defaultValue="account" className="w-[400px]">
        <TabsList>
          <TabsTrigger value="account">Account</TabsTrigger>
          <TabsTrigger value="password">Password</TabsTrigger>
        </TabsList>
        <TabsContent value="account">Make changes to your account here.</TabsContent>
        <TabsContent value="password">Change your password here.</TabsContent>
      </Tabs>
    ),
    heex: `<.tabs default_value="account" class="w-[400px]">
  <.tabs_list>
    <.tabs_trigger value="account">Account</.tabs_trigger>
    <.tabs_trigger value="password">Password</.tabs_trigger>
  </.tabs_list>
  <.tabs_content value="account">Make changes to your account here.</.tabs_content>
  <.tabs_content value="password">Change your password here.</.tabs_content>
</.tabs>`
  },
  {
    name: "textarea",
    title: "Textarea",
    category: "forms",
    renderReact: () => <Textarea placeholder="Type your message here." />,
    heex: `<.textarea placeholder="Type your message here." />`
  },
  {
    name: "toggle-group",
    title: "Toggle Group",
    category: "actions",
    renderReact: () => (
      <ToggleGroup type="multiple">
        <ToggleGroupItem value="bold" aria-label="Toggle bold">B</ToggleGroupItem>
        <ToggleGroupItem value="italic" aria-label="Toggle italic">I</ToggleGroupItem>
        <ToggleGroupItem value="underline" aria-label="Toggle underline">U</ToggleGroupItem>
      </ToggleGroup>
    ),
    heex: `<.toggle_group type="multiple">
  <.toggle_group_item value="bold" aria-label="Toggle bold">B</.toggle_group_item>
  <.toggle_group_item value="italic" aria-label="Toggle italic">I</.toggle_group_item>
  <.toggle_group_item value="underline" aria-label="Toggle underline">U</.toggle_group_item>
</.toggle_group>`
  },
  {
    name: "toggle",
    title: "Toggle",
    category: "actions",
    renderReact: () => <Toggle aria-label="Toggle italic">B</Toggle>,
    heex: `<.toggle aria-label="Toggle italic">B</.toggle>`
  },
  {
    name: "tooltip",
    title: "Tooltip",
    category: "overlay",
    renderReact: () => (
      <TooltipProvider>
        <Tooltip open>
          <TooltipTrigger asChild>
            <Button variant="outline">Hover</Button>
          </TooltipTrigger>
          <TooltipContent>
            <p>Add to library</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    ),
    heex: `<.tooltip_provider>
  <.tooltip open={true}>
    <.tooltip_trigger>
      <.button variant="outline">Hover</.button>
    </.tooltip_trigger>
    <.tooltip_content>
      <p>Add to library</p>
    </.tooltip_content>
  </.tooltip>
</.tooltip_provider>`
  }
]
