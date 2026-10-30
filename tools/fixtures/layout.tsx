import React from "react"
import type { ComponentFixture } from "../fixtures"
import { Card, CardContent } from "../../vendor/shadcn/ui/card"
import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from "../../vendor/shadcn/ui/carousel"
import { ResizablePanelGroup, ResizablePanel, ResizableHandle } from "../../vendor/shadcn/ui/resizable"
import { Sidebar, SidebarContent, SidebarHeader, SidebarFooter, SidebarProvider, SidebarTrigger, SidebarRail, SidebarInset, SidebarGroup, SidebarGroupLabel, SidebarGroupContent, SidebarMenu, SidebarMenuItem, SidebarMenuButton, SidebarMenuSub, SidebarMenuSubItem, SidebarMenuSubButton } from "../../vendor/shadcn/ui/sidebar"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "../../vendor/shadcn/ui/dropdown-menu"

export const fixtures: ComponentFixture[] = [
  {
    name: "carousel", title: "Carousel", category: "data-display",
    renderReact: () => <Carousel id="carousel-demo" className="w-full max-w-xs"><CarouselContent><CarouselItem><div className="p-1"><Card><CardContent className="flex aspect-square items-center justify-center p-6"><span className="text-4xl font-semibold">1</span></CardContent></Card></div></CarouselItem></CarouselContent><CarouselPrevious /><CarouselNext /></Carousel>,
    heex: `<.carousel id="carousel-demo" class="w-full max-w-xs" :let={carousel}>
  <.carousel_content carousel={carousel}>
    <.carousel_item carousel={carousel}><div class="p-1"><.card><.card_content class="flex aspect-square items-center justify-center p-6"><span class="text-4xl font-semibold">1</span></.card_content></.card></div></.carousel_item>
  </.carousel_content>
  <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
</.carousel>`,
    liveHeex: `<.carousel id="carousel-demo" start_index={Map.get(@state, "carousel-demo", 0)} class="w-full max-w-xs" :let={carousel}>
  <.carousel_content carousel={carousel}>
    <.carousel_item carousel={carousel}><div class="p-1"><.card><.card_content class="flex aspect-square items-center justify-center p-6"><span class="text-4xl font-semibold">1</span></.card_content></.card></div></.carousel_item>
  </.carousel_content>
  <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
</.carousel>`,
  },
  {
    name: "carousel-vertical", family: "carousel", title: "Vertical carousel", category: "data-display",
    renderReact: () => <Carousel id="carousel-vertical-demo" orientation="vertical" className="my-12 h-48 w-full max-w-xs"><CarouselContent className="h-48"><CarouselItem>First</CarouselItem><CarouselItem>Second</CarouselItem><CarouselItem>Third</CarouselItem></CarouselContent><CarouselPrevious /><CarouselNext /></Carousel>,
    heex: `<.carousel id="carousel-vertical-demo" orientation="vertical" class="my-12 h-48 w-full max-w-xs" :let={carousel}>
  <.carousel_content carousel={carousel} class="h-48"><.carousel_item carousel={carousel}>First</.carousel_item><.carousel_item carousel={carousel}>Second</.carousel_item><.carousel_item carousel={carousel}>Third</.carousel_item></.carousel_content>
  <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
</.carousel>`,
    liveHeex: `<.carousel id="carousel-vertical-demo" orientation="vertical" start_index={Map.get(@state, "carousel-vertical-demo", 0)} class="my-12 h-48 w-full max-w-xs" :let={carousel}>
  <.carousel_content carousel={carousel} class="h-48"><.carousel_item carousel={carousel}>First</.carousel_item><.carousel_item carousel={carousel}>Second</.carousel_item><.carousel_item carousel={carousel}>Third</.carousel_item></.carousel_content>
  <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
</.carousel>`,
  },
  {
    name: "carousel-multiple", family: "carousel", title: "Independent looping carousels", category: "data-display",
    renderReact: () => <div className="flex w-full flex-col items-center gap-12 px-12">{["left", "right"].map(side => <Carousel key={side} id={`carousel-${side}`} opts={{ loop: true, startIndex: 1 }} className="w-full max-w-48"><CarouselContent><CarouselItem className="basis-1/2">A</CarouselItem><CarouselItem className="basis-1/2">B</CarouselItem><CarouselItem className="basis-1/2">C</CarouselItem><CarouselItem className="basis-1/2">D</CarouselItem></CarouselContent><CarouselPrevious /><CarouselNext /></Carousel>)}</div>,
    heex: `<div class="flex w-full flex-col items-center gap-12 px-12"><.carousel :for={side <- ~w(left right)} id={"carousel-" <> side} loop={true} start_index={1} class="w-full max-w-48" :let={carousel}><.carousel_content carousel={carousel}><.carousel_item :for={label <- ~w(A B C D)} carousel={carousel} class="basis-1/2">{label}</.carousel_item></.carousel_content><.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} /></.carousel></div>`,
    liveHeex: `<div class="flex w-full flex-col items-center gap-12 px-12"><.carousel :for={side <- ~w(left right)} id={"carousel-" <> side} loop={true} start_index={Map.get(@state, "carousel-" <> side, 1)} class="w-full max-w-48" :let={carousel}><.carousel_content carousel={carousel}><.carousel_item :for={label <- ~w(A B C D)} carousel={carousel} class="basis-1/2">{label}</.carousel_item></.carousel_content><.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} /></.carousel></div>`,
  },
  {
    name: "resizable", title: "Resizable", category: "layout",
    renderReact: () => <ResizablePanelGroup id="resizable-demo" orientation="horizontal" className="max-w-md rounded-lg border"><ResizablePanel id="resizable-demo-one" defaultSize={50}><div className="flex h-[100px] items-center justify-center p-6">One</div></ResizablePanel><ResizableHandle id="resizable-demo-handle" /><ResizablePanel id="resizable-demo-two" defaultSize={50}><div className="flex h-[100px] items-center justify-center p-6">Two</div></ResizablePanel></ResizablePanelGroup>,
    heex: `<.resizable_panel_group id="resizable-demo" orientation="horizontal" class="max-w-md rounded-lg border" :let={group}>
  <.resizable_panel group={group} id="resizable-demo-one" default_size={50}><div class="flex h-[100px] items-center justify-center p-6">One</div></.resizable_panel>
  <.resizable_handle group={group} id="resizable-demo-handle" />
  <.resizable_panel group={group} id="resizable-demo-two" default_size={50}><div class="flex h-[100px] items-center justify-center p-6">Two</div></.resizable_panel>
</.resizable_panel_group>`,
    liveHeex: `<.resizable_panel_group id="resizable-demo" layout={Map.get(@state, "resizable-demo")} orientation="horizontal" class="max-w-md rounded-lg border" :let={group}>
  <.resizable_panel group={group} id="resizable-demo-one" default_size={50}><div class="flex h-[100px] items-center justify-center p-6">One</div></.resizable_panel>
  <.resizable_handle group={group} id="resizable-demo-handle" />
  <.resizable_panel group={group} id="resizable-demo-two" default_size={50}><div class="flex h-[100px] items-center justify-center p-6">Two</div></.resizable_panel>
</.resizable_panel_group>`,
  },
  {
    name: "resizable-vertical", family: "resizable", title: "Vertical constrained panels", category: "layout",
    renderReact: () => <ResizablePanelGroup id="resizable-vertical-demo" orientation="vertical" className="min-h-64 max-w-md border"><ResizablePanel id="resizable-vertical-one" defaultSize="30%" minSize="10%" maxSize="80%">Top</ResizablePanel><ResizableHandle id="resizable-vertical-handle" withHandle /><ResizablePanel id="resizable-vertical-two" defaultSize="70%" minSize="20%" maxSize="90%">Bottom</ResizablePanel></ResizablePanelGroup>,
    heex: `<.resizable_panel_group id="resizable-vertical-demo" orientation="vertical" class="min-h-64 max-w-md border" :let={group}><.resizable_panel group={group} id="resizable-vertical-one" default_size="30%" min_size="10%" max_size="80%">Top</.resizable_panel><.resizable_handle group={group} id="resizable-vertical-handle" with_handle={true} /><.resizable_panel group={group} id="resizable-vertical-two" default_size="70%" min_size="20%" max_size="90%">Bottom</.resizable_panel></.resizable_panel_group>`,
    liveHeex: `<.resizable_panel_group id="resizable-vertical-demo" layout={Map.get(@state, "resizable-vertical-demo")} orientation="vertical" class="min-h-64 max-w-md border" :let={group}><.resizable_panel group={group} id="resizable-vertical-one" default_size="30%" min_size="10%" max_size="80%">Top</.resizable_panel><.resizable_handle group={group} id="resizable-vertical-handle" with_handle={true} /><.resizable_panel group={group} id="resizable-vertical-two" default_size="70%" min_size="20%" max_size="90%">Bottom</.resizable_panel></.resizable_panel_group>`,
  },
  {
    name: "resizable-multiple", family: "resizable", title: "Default sizing and disabled separator", category: "layout",
    renderReact: () => <div className="flex gap-4"><ResizablePanelGroup id="resize-auto" className="min-h-32"><ResizablePanel id="resize-auto-a">Automatic</ResizablePanel><ResizableHandle id="resize-auto-h" withHandle /><ResizablePanel id="resize-auto-b" collapsible collapsedSize="5%" minSize="15%" maxSize="70%">Collapsible</ResizablePanel></ResizablePanelGroup><ResizablePanelGroup id="resize-fixed" className="min-h-32"><ResizablePanel id="resize-fixed-a" defaultSize="40%">Fixed</ResizablePanel><ResizableHandle id="resize-fixed-h" disabled /><ResizablePanel id="resize-fixed-b" defaultSize="60%" disabled>Disabled</ResizablePanel></ResizablePanelGroup></div>,
    heex: `<div class="flex gap-4"><.resizable_panel_group id="resize-auto" class="min-h-32" :let={group}><.resizable_panel id="resize-auto-a" group={group}>Automatic</.resizable_panel><.resizable_handle id="resize-auto-h" group={group} with_handle={true} /><.resizable_panel id="resize-auto-b" group={group} collapsible={true} collapsed_size="5%" min_size="15%" max_size="70%">Collapsible</.resizable_panel></.resizable_panel_group><.resizable_panel_group id="resize-fixed" class="min-h-32" :let={group}><.resizable_panel id="resize-fixed-a" group={group} default_size="40%">Fixed</.resizable_panel><.resizable_handle id="resize-fixed-h" group={group} disabled={true} /><.resizable_panel id="resize-fixed-b" group={group} default_size="60%" disabled={true}>Disabled</.resizable_panel></.resizable_panel_group></div>`,
    liveHeex: `<div class="flex gap-4"><.resizable_panel_group id="resize-auto" layout={Map.get(@state, "resize-auto")} class="min-h-32" :let={group}><.resizable_panel id="resize-auto-a" group={group}>Automatic</.resizable_panel><.resizable_handle id="resize-auto-h" group={group} with_handle={true} /><.resizable_panel id="resize-auto-b" group={group} collapsible={true} collapsed_size="5%" min_size="15%" max_size="70%">Collapsible</.resizable_panel></.resizable_panel_group><.resizable_panel_group id="resize-fixed" class="min-h-32" :let={group}><.resizable_panel id="resize-fixed-a" group={group} default_size="40%">Fixed</.resizable_panel><.resizable_handle id="resize-fixed-h" group={group} disabled={true} /><.resizable_panel id="resize-fixed-b" group={group} default_size="60%" disabled={true}>Disabled</.resizable_panel></.resizable_panel_group></div>`,
  },
  {
    name: "sidebar", title: "Sidebar", category: "navigation",
    renderReact: () => <SidebarProvider id="sidebar-demo"><Sidebar id="sidebar-demo-panel"><SidebarHeader><h4 className="font-semibold text-sm">Application</h4></SidebarHeader><SidebarContent><div className="p-2 text-sm text-muted-foreground">Nav items</div></SidebarContent></Sidebar></SidebarProvider>,
    heex: `<.sidebar_provider id="sidebar-demo" :let={sidebar}><.sidebar id="sidebar-demo-panel" sidebar={sidebar}><.sidebar_header><h4 class="font-semibold text-sm">Application</h4></.sidebar_header><.sidebar_content><div class="p-2 text-sm text-muted-foreground">Nav items</div></.sidebar_content></.sidebar></.sidebar_provider>`,
    liveHeex: `<.sidebar_provider id="sidebar-demo" open={Map.get(@state, "sidebar-demo", true)} mobile_open={Map.get(@state, "sidebar-demo-mobile", false)} :let={sidebar}><.sidebar id="sidebar-demo-panel" sidebar={sidebar}><.sidebar_header><h4 class="font-semibold text-sm">Application</h4></.sidebar_header><.sidebar_content><div class="p-2 text-sm text-muted-foreground">Nav items</div></.sidebar_content></.sidebar></.sidebar_provider>`,
  },
  ...(["icon", "offcanvas"] as const).map(collapsible => ({
    name: `sidebar-collapsed-${collapsible}`, family: "sidebar", title: `Collapsed ${collapsible} sidebar`, category: "navigation" as const,
    renderReact: () => <SidebarProvider id={`sidebar-${collapsible}`} defaultOpen={false}><Sidebar id={`sidebar-${collapsible}-panel`} collapsible={collapsible} side="right" variant="floating"><SidebarHeader>Workspace</SidebarHeader><SidebarContent><SidebarGroup><SidebarGroupLabel>Projects</SidebarGroupLabel><SidebarGroupContent><SidebarMenu><SidebarMenuItem><SidebarMenuButton isActive size="sm">Overview</SidebarMenuButton><SidebarMenuSub><SidebarMenuSubItem><SidebarMenuSubButton href="#details" isActive>Details</SidebarMenuSubButton></SidebarMenuSubItem></SidebarMenuSub></SidebarMenuItem></SidebarMenu></SidebarGroupContent></SidebarGroup></SidebarContent><SidebarFooter>Account</SidebarFooter><SidebarRail /></Sidebar><SidebarInset><SidebarTrigger />Content</SidebarInset></SidebarProvider>,
    heex: `<.sidebar_provider id="sidebar-${collapsible}" open={false} :let={sidebar}><.sidebar id="sidebar-${collapsible}-panel" sidebar={sidebar} collapsible="${collapsible}" side="right" variant="floating"><.sidebar_header>Workspace</.sidebar_header><.sidebar_content><.sidebar_group><.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content><.sidebar_menu><.sidebar_menu_item><.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub><.sidebar_menu_sub_item><.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button></.sidebar_menu_sub_item></.sidebar_menu_sub></.sidebar_menu_item></.sidebar_menu></.sidebar_group_content></.sidebar_group></.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} /></.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset></.sidebar_provider>`,
    liveHeex: `<.sidebar_provider id="sidebar-${collapsible}" open={Map.get(@state, "sidebar-${collapsible}", false)} mobile_open={Map.get(@state, "sidebar-${collapsible}-mobile", false)} :let={sidebar}><.sidebar id="sidebar-${collapsible}-panel" sidebar={sidebar} collapsible="${collapsible}" side="right" variant="floating"><.sidebar_header>Workspace</.sidebar_header><.sidebar_content><.sidebar_group><.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content><.sidebar_menu><.sidebar_menu_item><.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub><.sidebar_menu_sub_item><.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button></.sidebar_menu_sub_item></.sidebar_menu_sub></.sidebar_menu_item></.sidebar_menu></.sidebar_group_content></.sidebar_group></.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} /></.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset></.sidebar_provider>`,
  })),
  {
    name: "sidebar-multiple", family: "sidebar", title: "Independent expanded and static sidebars", category: "navigation",
    renderReact: () => <div className="flex w-full min-w-0 flex-col gap-4 md:flex-row"><SidebarProvider id="sidebar-inset" className="relative h-64 min-h-0! min-w-0 overflow-hidden"><Sidebar id="sidebar-inset-panel" variant="inset" className="md:absolute md:h-full"><SidebarHeader>Inset</SidebarHeader><SidebarContent>Navigation</SidebarContent></Sidebar><SidebarInset className="min-w-0"><SidebarTrigger />Main</SidebarInset></SidebarProvider><SidebarProvider id="sidebar-static" className="h-48 min-h-0! min-w-0 md:h-64 md:w-48 md:shrink-0"><Sidebar id="sidebar-static-panel" collapsible="none" className="w-48"><SidebarContent>Always visible</SidebarContent></Sidebar></SidebarProvider></div>,
    heex: `<div class="flex w-full min-w-0 flex-col gap-4 md:flex-row"><.sidebar_provider id="sidebar-inset" class="relative h-64 min-h-0! min-w-0 overflow-hidden" :let={sidebar}><.sidebar id="sidebar-inset-panel" sidebar={sidebar} variant="inset" class="md:absolute md:h-full"><.sidebar_header>Inset</.sidebar_header><.sidebar_content>Navigation</.sidebar_content></.sidebar><.sidebar_inset class="min-w-0"><.sidebar_trigger sidebar={sidebar} />Main</.sidebar_inset></.sidebar_provider><.sidebar_provider id="sidebar-static" class="h-48 min-h-0! min-w-0 md:h-64 md:w-48 md:shrink-0" :let={sidebar}><.sidebar id="sidebar-static-panel" sidebar={sidebar} collapsible="none" class="w-48"><.sidebar_content>Always visible</.sidebar_content></.sidebar></.sidebar_provider></div>`,
    liveHeex: `<div class="flex w-full min-w-0 flex-col gap-4 md:flex-row"><.sidebar_provider id="sidebar-inset" class="relative h-64 min-h-0! min-w-0 overflow-hidden" open={Map.get(@state, "sidebar-inset", true)} mobile_open={Map.get(@state, "sidebar-inset-mobile", false)} :let={sidebar}><.sidebar id="sidebar-inset-panel" sidebar={sidebar} variant="inset" class="md:absolute md:h-full"><.sidebar_header>Inset</.sidebar_header><.sidebar_content>Navigation</.sidebar_content></.sidebar><.sidebar_inset class="min-w-0"><.sidebar_trigger sidebar={sidebar} />Main</.sidebar_inset></.sidebar_provider><.sidebar_provider id="sidebar-static" class="h-48 min-h-0! min-w-0 md:h-64 md:w-48 md:shrink-0" open={Map.get(@state, "sidebar-static", true)} mobile_open={Map.get(@state, "sidebar-static-mobile", false)} :let={sidebar}><.sidebar id="sidebar-static-panel" sidebar={sidebar} collapsible="none" class="w-48"><.sidebar_content>Always visible</.sidebar_content></.sidebar></.sidebar_provider></div>`,
  },
  {
    // Mobile sheet with a popup inside: patches and Escape must leave the popup owning focus.
    name: "sidebar-menu-popup", family: "sidebar", title: "Sidebar with a menu popup", category: "navigation",
    renderReact: () => <SidebarProvider id="sidebar-popup"><Sidebar id="sidebar-popup-panel"><SidebarContent><SidebarGroup><SidebarGroupContent><SidebarMenu><SidebarMenuItem><DropdownMenu><DropdownMenuTrigger id="sidebar-popup-menu-trigger" asChild><SidebarMenuButton>Team</SidebarMenuButton></DropdownMenuTrigger><DropdownMenuContent><DropdownMenuItem>Acme</DropdownMenuItem><DropdownMenuItem>Globex</DropdownMenuItem></DropdownMenuContent></DropdownMenu></SidebarMenuItem></SidebarMenu></SidebarGroupContent></SidebarGroup></SidebarContent></Sidebar><SidebarInset><SidebarTrigger />Main</SidebarInset></SidebarProvider>,
    heex: sidebarPopup(false),
    liveHeex: sidebarPopup(true),
  },
]

function sidebarPopup(live: boolean): string {
  const provider = live ? ` open={Map.get(@state, "sidebar-popup", true)} mobile_open={Map.get(@state, "sidebar-popup-mobile", false)}` : ""
  const menu = live ? ` open={Map.get(@state, "sidebar-popup-menu-open", false)} on_change="shadcn:popup-change"` : ""
  const ticks = live ? `<span id="sidebar-popup-ticks">{Map.get(@state, "sidebar-popup-ticks", 0)}</span>` : ""
  return `<.sidebar_provider id="sidebar-popup"${provider} :let={sidebar}><.sidebar id="sidebar-popup-panel" sidebar={sidebar}><.sidebar_content><.sidebar_group><.sidebar_group_content><.sidebar_menu><.sidebar_menu_item><.dropdown_menu id="sidebar-popup-menu"${menu}><:trigger :let={popup}><.sidebar_menu_button {popup.trigger}>Team</.sidebar_menu_button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_item>Acme</.dropdown_menu_item><.dropdown_menu_item>Globex</.dropdown_menu_item></.dropdown_menu_content></:content></.dropdown_menu></.sidebar_menu_item></.sidebar_menu></.sidebar_group_content></.sidebar_group></.sidebar_content></.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Main${ticks}</.sidebar_inset></.sidebar_provider>`
}
