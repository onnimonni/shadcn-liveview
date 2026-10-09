import * as React from "react"
import type { ComponentFixture } from "../fixtures"
import { bindLiveOverlayControls } from "../../assets/js/react-fixtures/overlay-controls"
import { Button } from "../../vendor/shadcn/ui/button"
import { ContextMenu, ContextMenuContent, ContextMenuItem, ContextMenuTrigger } from "../../vendor/shadcn/ui/context-menu"
import { DropdownMenu, DropdownMenuCheckboxItem, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuSeparator, DropdownMenuTrigger } from "../../vendor/shadcn/ui/dropdown-menu"
import { HoverCard, HoverCardContent, HoverCardTrigger } from "../../vendor/shadcn/ui/hover-card"
import { Popover, PopoverContent, PopoverTrigger } from "../../vendor/shadcn/ui/popover"
import { Select, SelectContent, SelectGroup, SelectItem, SelectLabel, SelectTrigger, SelectValue } from "../../vendor/shadcn/ui/select"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "../../vendor/shadcn/ui/tooltip"

export const fixtures: ComponentFixture[] = [
  {
    name: "context-menu", title: "Context Menu", category: "overlay",
    renderReact: () => <ContextMenu><ContextMenuTrigger id="context-demo-trigger" className="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">Right click here</ContextMenuTrigger><ContextMenuContent><ContextMenuItem>Back</ContextMenuItem><ContextMenuItem>Forward</ContextMenuItem><ContextMenuItem>Reload</ContextMenuItem></ContextMenuContent></ContextMenu>,
    heex: `<.context_menu id="context-demo"><:trigger :let={popup}><.context_menu_trigger context={popup} class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">Right click here</.context_menu_trigger></:trigger><:content :let={popup}><.context_menu_content context={popup}><.context_menu_item>Back</.context_menu_item><.context_menu_item>Forward</.context_menu_item><.context_menu_item>Reload</.context_menu_item></.context_menu_content></:content></.context_menu>`
  },
  {
    name: "context-menu-disabled", family: "context-menu", title: "Disabled context surface", category: "overlay",
    renderReact: () => <ContextMenu><ContextMenuTrigger id="context-disabled-trigger" disabled>Unavailable</ContextMenuTrigger><ContextMenuContent><ContextMenuItem disabled>Unavailable action</ContextMenuItem></ContextMenuContent></ContextMenu>,
    heex: `<.context_menu id="context-disabled" disabled><:trigger :let={popup}><.context_menu_trigger context={popup}>Unavailable</.context_menu_trigger></:trigger><:content :let={popup}><.context_menu_content context={popup}><.context_menu_item disabled>Unavailable action</.context_menu_item></.context_menu_content></:content></.context_menu>`
  },
  {
    name: "context-menu-multiple", family: "context-menu", title: "Independent context surfaces", category: "overlay",
    renderReact: () => <>{["first", "second"].map(id => <ContextMenu key={id}><ContextMenuTrigger id={`context-${id}-trigger`}>{id}</ContextMenuTrigger><ContextMenuContent><ContextMenuItem>{id} action</ContextMenuItem></ContextMenuContent></ContextMenu>)}</>,
    heex: ["first", "second"].map(id => `<.context_menu id="context-${id}"><:trigger :let={popup}><.context_menu_trigger context={popup}>${id}</.context_menu_trigger></:trigger><:content :let={popup}><.context_menu_content context={popup}><.context_menu_item>${id} action</.context_menu_item></.context_menu_content></:content></.context_menu>`).join("\n")
  },
  {
    name: "dropdown-menu", title: "Dropdown Menu", category: "overlay",
    renderReact: () => <DropdownMenu open><DropdownMenuTrigger id="dropdown-demo-trigger" aria-controls="dropdown-demo-content" asChild><Button variant="outline">Open Menu</Button></DropdownMenuTrigger><DropdownMenuContent id="dropdown-demo-content" aria-labelledby="dropdown-demo-trigger"><DropdownMenuLabel>My Account</DropdownMenuLabel><DropdownMenuSeparator /><DropdownMenuItem>Profile</DropdownMenuItem><DropdownMenuItem>Billing</DropdownMenuItem></DropdownMenuContent></DropdownMenu>,
    heex: `<.dropdown_menu id="dropdown-demo" open><:trigger :let={popup}><.button variant="outline" {popup.trigger}>Open Menu</.button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_label>My Account</.dropdown_menu_label><.dropdown_menu_separator /><.dropdown_menu_item>Profile</.dropdown_menu_item><.dropdown_menu_item>Billing</.dropdown_menu_item></.dropdown_menu_content></:content></.dropdown_menu>`
  },
  {
    name: "dropdown-menu-closed-disabled", family: "dropdown-menu", title: "Disabled closed dropdown", category: "overlay",
    renderReact: () => <DropdownMenu><DropdownMenuTrigger id="dropdown-disabled-trigger" disabled>Disabled</DropdownMenuTrigger><DropdownMenuContent><DropdownMenuItem>Action</DropdownMenuItem></DropdownMenuContent></DropdownMenu>,
    heex: `<.dropdown_menu id="dropdown-disabled" disabled><:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_item>Action</.dropdown_menu_item></.dropdown_menu_content></:content></.dropdown_menu>`
  },
  {
    name: "dropdown-menu-items", family: "dropdown-menu", title: "Dropdown item states and independent instances", category: "overlay",
    renderReact: () => <>{["first", "second"].map(id => <DropdownMenu key={id} open><DropdownMenuTrigger id={`dropdown-${id}-trigger`} aria-controls={`dropdown-${id}-content`}>{id}</DropdownMenuTrigger><DropdownMenuContent id={`dropdown-${id}-content`} aria-labelledby={`dropdown-${id}-trigger`}><DropdownMenuItem disabled inset>Disabled</DropdownMenuItem><DropdownMenuItem variant="destructive">Delete</DropdownMenuItem></DropdownMenuContent></DropdownMenu>)}</>,
    heex: ["first", "second"].map(id => `<.dropdown_menu id="dropdown-${id}" open><:trigger :let={popup}><button {popup.trigger}>${id}</button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_item disabled inset>Disabled</.dropdown_menu_item><.dropdown_menu_item variant="destructive">Delete</.dropdown_menu_item></.dropdown_menu_content></:content></.dropdown_menu>`).join("\n")
  },
  {
    name: "dropdown-menu-checks", family: "dropdown-menu", title: "Checkbox and radio menu selection", category: "overlay",
    renderReact: () => <DropdownMenu open><DropdownMenuTrigger id="dropdown-checks-trigger" aria-controls="dropdown-checks-content">Preferences</DropdownMenuTrigger><DropdownMenuContent id="dropdown-checks-content" aria-labelledby="dropdown-checks-trigger"><DropdownMenuCheckboxItem checked>Show status</DropdownMenuCheckboxItem><DropdownMenuRadioGroup value="compact"><DropdownMenuRadioItem value="compact">Compact</DropdownMenuRadioItem><DropdownMenuRadioItem value="comfortable">Comfortable</DropdownMenuRadioItem></DropdownMenuRadioGroup></DropdownMenuContent></DropdownMenu>,
    heex: `<.dropdown_menu id="dropdown-checks" open><:trigger :let={popup}><button {popup.trigger}>Preferences</button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_checkbox_item checked value="status">Show status</.dropdown_menu_checkbox_item><.dropdown_menu_radio_group><.dropdown_menu_radio_item checked value="compact">Compact</.dropdown_menu_radio_item><.dropdown_menu_radio_item value="comfortable">Comfortable</.dropdown_menu_radio_item></.dropdown_menu_radio_group></.dropdown_menu_content></:content></.dropdown_menu>`,
    liveHeex: `<.dropdown_menu id="dropdown-checks" open={Map.get(@state, "dropdown-checks-open", true)}><:trigger :let={popup}><button {popup.trigger}>Preferences</button></:trigger><:content :let={popup}><.dropdown_menu_content context={popup}><.dropdown_menu_checkbox_item checked={Map.get(@state, "dropdown-checks-status-checked", true)} value="status">Show status</.dropdown_menu_checkbox_item><.dropdown_menu_radio_group><.dropdown_menu_radio_item checked={Map.get(@state, "dropdown-checks-value", "compact") == "compact"} value="compact">Compact</.dropdown_menu_radio_item><.dropdown_menu_radio_item checked={Map.get(@state, "dropdown-checks-value", "compact") == "comfortable"} value="comfortable">Comfortable</.dropdown_menu_radio_item></.dropdown_menu_radio_group></.dropdown_menu_content></:content></.dropdown_menu>`
  },
  {
    name: "hover-card", title: "Hover Card", category: "overlay",
    renderReact: () => <HoverCard open><HoverCardTrigger id="hover-demo-trigger" asChild><Button variant="link">@nextjs</Button></HoverCardTrigger><HoverCardContent id="hover-demo-content" className="w-80"><p className="text-sm">The React Framework for the Web.</p></HoverCardContent></HoverCard>,
    heex: `<.hover_card id="hover-demo" open><:trigger :let={popup}><.button variant="link" {popup.trigger}>@nextjs</.button></:trigger><:content :let={popup}><.hover_card_content context={popup} class="w-80"><p class="text-sm">The React Framework for the Web.</p></.hover_card_content></:content></.hover_card>`
  },
  {
    name: "hover-card-disabled", family: "hover-card", title: "Disabled hover card trigger", category: "overlay",
    renderReact: () => <HoverCard><HoverCardTrigger id="hover-disabled-trigger" asChild><Button variant="link" disabled>Unavailable profile</Button></HoverCardTrigger><HoverCardContent>Unavailable profile details</HoverCardContent></HoverCard>,
    heex: `<.hover_card id="hover-disabled" disabled><:trigger :let={popup}><.button variant="link" {popup.trigger}>Unavailable profile</.button></:trigger><:content :let={popup}><.hover_card_content context={popup}>Unavailable profile details</.hover_card_content></:content></.hover_card>`
  },
  {
    name: "hover-card-closed", family: "hover-card", title: "Focus and hover disclosure", category: "overlay",
    renderReact: () => <HoverCard><HoverCardTrigger id="hover-closed-trigger" href="#profile">Profile</HoverCardTrigger><HoverCardContent>Profile details</HoverCardContent></HoverCard>,
    heex: `<.hover_card id="hover-closed"><:trigger :let={popup}><a href="#profile" {popup.trigger}>Profile</a></:trigger><:content :let={popup}><.hover_card_content context={popup}>Profile details</.hover_card_content></:content></.hover_card>`
  },
  {
    name: "hover-card-multiple", family: "hover-card", title: "Multiple hover cards and alternate placement", category: "overlay",
    renderReact: () => <>{["first", "second"].map(id => <HoverCard key={id} open><HoverCardTrigger id={`hover-${id}-trigger`} href={`#${id}`}>{id}</HoverCardTrigger><HoverCardContent id={`hover-${id}-content`} side="right" align="start">{id} details</HoverCardContent></HoverCard>)}</>,
    heex: ["first", "second"].map(id => `<.hover_card id="hover-${id}" open side="right" align="start"><:trigger :let={popup}><a href="#${id}" {popup.trigger}>${id}</a></:trigger><:content :let={popup}><.hover_card_content context={popup}>${id} details</.hover_card_content></:content></.hover_card>`).join("\n")
  },
  {
    name: "popover", title: "Popover", category: "overlay",
    renderReact: () => <Popover open><PopoverTrigger id="popover-demo-trigger" aria-controls="popover-demo-content" asChild><Button variant="outline">Open popover</Button></PopoverTrigger><PopoverContent id="popover-demo-content" className="w-80"><p className="text-sm">Dimensions settings.</p></PopoverContent></Popover>,
    heex: `<.popover id="popover-demo" open><:trigger :let={popup}><.button variant="outline" {popup.trigger}>Open popover</.button></:trigger><:content :let={popup}><.popover_content context={popup} class="w-80"><p class="text-sm">Dimensions settings.</p></.popover_content></:content></.popover>`
  },
  {
    name: "popover-closed", family: "popover", title: "Closed popover with editable content", category: "overlay",
    renderReact: () => <Popover><PopoverTrigger id="popover-closed-trigger">Edit</PopoverTrigger><PopoverContent><label htmlFor="popover-name">Name</label><input id="popover-name" defaultValue="Ada" /></PopoverContent></Popover>,
    heex: `<.popover id="popover-closed"><:trigger :let={popup}><button {popup.trigger}>Edit</button></:trigger><:content :let={popup}><.popover_content context={popup}><label for="popover-name">Name</label><input id="popover-name" value="Ada" /></.popover_content></:content></.popover>`
  },
  {
    name: "popover-multiple-disabled", family: "popover", title: "Independent disabled and open popovers", category: "overlay",
    renderReact: () => <><Popover><PopoverTrigger id="popover-disabled-trigger" disabled>Disabled</PopoverTrigger><PopoverContent>Unavailable</PopoverContent></Popover><Popover open><PopoverTrigger id="popover-second-trigger" aria-controls="popover-second-content">Second</PopoverTrigger><PopoverContent id="popover-second-content" side="left" align="end">Details</PopoverContent></Popover></>,
    heex: `<.popover id="popover-disabled" disabled><:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={popup}><.popover_content context={popup}>Unavailable</.popover_content></:content></.popover><.popover id="popover-second" open side="left" align="end"><:trigger :let={popup}><button {popup.trigger}>Second</button></:trigger><:content :let={popup}><.popover_content context={popup}>Details</.popover_content></:content></.popover>`
  },
  {
    name: "select", title: "Select", category: "forms",
    renderReact: () => <Select open><SelectTrigger id="select-demo-trigger" aria-controls="select-demo-content" className="w-[180px]"><SelectValue placeholder="Select a fruit" /></SelectTrigger><SelectContent id="select-demo-content"><SelectItem id="select-demo-apple" value="apple">Apple</SelectItem><SelectItem id="select-demo-banana" value="banana">Banana</SelectItem></SelectContent></Select>,
    heex: `<.select id="select-demo" open placeholder="Select a fruit"><:trigger :let={popup}><.select_trigger context={popup} class="w-[180px]"><.select_value context={popup} placeholder="Select a fruit" /></.select_trigger></:trigger><:option id="select-demo-apple" value="apple" label="Apple">Apple</:option><:option id="select-demo-banana" value="banana" label="Banana">Banana</:option></.select>`
  },
  {
    name: "select-value-disabled", family: "select", title: "Required form select with disabled option", category: "forms",
    renderReact: () => <form><Select open name="fruit" defaultValue="banana" required><SelectTrigger id="select-value-trigger" aria-controls="select-value-content"><SelectValue>Banana</SelectValue></SelectTrigger><SelectContent id="select-value-content"><SelectItem id="select-value-apple" value="apple" disabled>Apple</SelectItem><SelectItem id="select-value-banana" value="banana">Banana</SelectItem></SelectContent></Select></form>,
    heex: `<form><.select id="select-value" open name="fruit" value="banana" required><:trigger :let={popup}><.select_trigger context={popup}><.select_value>Banana</.select_value></.select_trigger></:trigger><:option id="select-value-apple" value="apple" label="Apple" disabled>Apple</:option><:option id="select-value-banana" value="banana" label="Banana">Banana</:option></.select></form>`
  },
  {
    name: "select-closed-multiple", family: "select", title: "Closed small and disabled selects", category: "forms",
    renderReact: () => <>{[false, true].map((disabled, index) => <Select key={index} disabled={disabled} name={`fruit-${index}`}><SelectTrigger id={`select-closed-${index}-trigger`} size="sm"><SelectValue placeholder="Fruit" /></SelectTrigger><SelectContent><SelectItem value="apple">Apple</SelectItem><SelectItem value="banana">Banana</SelectItem></SelectContent></Select>)}</>,
    heex: [false, true].map((disabled, index) => `<.select id="select-closed-${index}" name="fruit-${index}" disabled={${disabled}} placeholder="Fruit"><:trigger :let={popup}><.select_trigger context={popup} size="sm"><.select_value placeholder="Fruit" /></.select_trigger></:trigger><:option id="select-closed-${index}-apple" value="apple" label="Apple">Apple</:option><:option id="select-closed-${index}-banana" value="banana" label="Banana">Banana</:option></.select>`).join("\n")
  },
  {
    name: "select-popper", family: "select", title: "Popper select placement", category: "forms",
    renderReact: () => <Select open><SelectTrigger id="select-popper-trigger" aria-controls="select-popper-content"><SelectValue placeholder="Fruit" /></SelectTrigger><SelectContent id="select-popper-content" position="popper" align="start"><SelectItem id="select-popper-apple" value="apple">Apple</SelectItem></SelectContent></Select>,
    heex: `<.select id="select-popper" open position="popper" align="start" placeholder="Fruit"><:trigger :let={popup}><.select_trigger context={popup}><.select_value placeholder="Fruit" /></.select_trigger></:trigger><:option id="select-popper-apple" value="apple" label="Apple">Apple</:option></.select>`
  },
  {
    name: "select-groups", family: "select", title: "Labeled option groups", category: "forms",
    renderReact: () => <Select open name="produce"><SelectTrigger id="select-groups-trigger" aria-controls="select-groups-content"><SelectValue placeholder="Produce" /></SelectTrigger><SelectContent id="select-groups-content"><SelectGroup><SelectLabel>Fruit</SelectLabel><SelectItem id="select-groups-apple" value="apple">Apple</SelectItem></SelectGroup><SelectGroup><SelectLabel>Vegetables</SelectLabel><SelectItem id="select-groups-carrot" value="carrot">Carrot</SelectItem></SelectGroup></SelectContent></Select>,
    heex: `<.select id="select-groups" open name="produce" placeholder="Produce"><:trigger :let={popup}><.select_trigger context={popup}><.select_value placeholder="Produce" /></.select_trigger></:trigger><:group id="fruit" label="Fruit" /><:group id="vegetables" label="Vegetables" /><:option id="select-groups-apple" value="apple" label="Apple" group="fruit">Apple</:option><:option id="select-groups-carrot" value="carrot" label="Carrot" group="vegetables">Carrot</:option></.select>`
  },
  {
    name: "tooltip", title: "Tooltip", category: "overlay",
    renderReact: () => <TooltipProvider><Tooltip open><TooltipTrigger id="tooltip-demo-trigger" asChild><Button variant="outline">Hover</Button></TooltipTrigger><TooltipContent><p>Add to library</p></TooltipContent></Tooltip></TooltipProvider>,
    heex: `<.tooltip_provider><.tooltip id="tooltip-demo" open><:trigger :let={popup}><.button variant="outline" {popup.trigger}>Hover</.button></:trigger><:content :let={popup}><.tooltip_content context={popup}><p>Add to library</p></.tooltip_content></:content></.tooltip></.tooltip_provider>`
  },
  {
    name: "tooltip-closed-disabled", family: "tooltip", title: "Closed disabled tooltip", category: "overlay",
    renderReact: () => <TooltipProvider><Tooltip><TooltipTrigger id="tooltip-disabled-trigger" disabled>Unavailable</TooltipTrigger><TooltipContent>Unavailable action</TooltipContent></Tooltip></TooltipProvider>,
    heex: `<.tooltip id="tooltip-disabled" disabled><:trigger :let={popup}><button {popup.trigger}>Unavailable</button></:trigger><:content :let={popup}><.tooltip_content context={popup}>Unavailable action</.tooltip_content></:content></.tooltip>`
  },
  {
    name: "tooltip-multiple", family: "tooltip", title: "Independent tooltip descriptions", category: "overlay",
    renderReact: () => <TooltipProvider>{["first", "second"].map(id => <Tooltip key={id} open><TooltipTrigger id={`tooltip-${id}-trigger`}>{id}</TooltipTrigger><TooltipContent side="bottom" align="end">{id} hint</TooltipContent></Tooltip>)}</TooltipProvider>,
    heex: ["first", "second"].map(id => `<.tooltip id="tooltip-${id}" open side="bottom" align="end"><:trigger :let={popup}><button {popup.trigger}>${id}</button></:trigger><:content :let={popup}><.tooltip_content context={popup}>${id} hint</.tooltip_content></:content></.tooltip>`).join("\n")
  }
]

for (const fixture of fixtures) {
  if (fixture.liveHeex) continue
  const family = fixture.family || fixture.name
  const root = family.replaceAll("-", "_")
  fixture.liveHeex = fixture.heex.replace(new RegExp(`<\\.${root} id="([^"]+)"([^>]*)>`, "g"), (_match, id: string, attributes: string) => {
    const open = /(?:^|\s)open(?:\s|$)/.test(attributes)
    attributes = attributes.replace(/(?:^|\s)open(?=\s|$)/, "")
    if (family === "select") {
      const value = attributes.match(/\svalue="([^"]*)"/)?.[1]
      attributes = attributes.replace(/\svalue="[^"]*"/, "")
      attributes += ` value={Map.get(@state, "${id}-value", ${value === undefined ? "nil" : JSON.stringify(value)})}`
    }
    return `<.${root} id="${id}" open={Map.get(@state, "${id}-open", ${open})}${attributes} on_change="shadcn:popup-change">`
  })
  if (family === "select") {
    fixture.liveHeex = fixture.liveHeex.replace(/<\.select_value(?!\scontext=)(?=\s|>)/g, "<.select_value context={popup}")
      .replace("<.select_value context={popup}>Banana</.select_value>", "<.select_value context={popup} />")
  }
}

bindLiveOverlayControls(fixtures)
