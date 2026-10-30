import React from "react"
import type { ComponentFixture } from "../fixtures"
import { bindLiveOverlayControls } from "../../assets/js/react-fixtures/overlay-controls"
import { Button } from "../../vendor/shadcn/ui/button"
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "../../vendor/shadcn/ui/dialog"
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogMedia, AlertDialogTitle, AlertDialogTrigger } from "../../vendor/shadcn/ui/alert-dialog"
import { Drawer, DrawerClose, DrawerContent, DrawerDescription, DrawerFooter, DrawerHeader, DrawerTitle, DrawerTrigger } from "../../vendor/shadcn/ui/drawer"
import { Sheet, SheetClose, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle, SheetTrigger } from "../../vendor/shadcn/ui/sheet"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../../vendor/shadcn/ui/select"

type LiveFixture = ComponentFixture & { liveHeex?: string }
type Side = "top" | "right" | "bottom" | "left"
type Options = {
  id: string
  open?: boolean
  trigger?: boolean
  showCloseButton?: boolean
  footerClose?: boolean
  side?: Side
  direction?: Side
  size?: "default" | "sm"
  modal?: boolean
  dismissible?: boolean
  customIds?: boolean
  media?: boolean
  disabledAction?: boolean
  actionVariant?: "default" | "destructive"
  select?: boolean
}

function ids(options: Options) {
  return {
    content: options.id,
    trigger: `${options.id}-trigger`,
    title: options.customIds ? `${options.id}-heading` : `${options.id}-title`,
    description: options.customIds ? `${options.id}-help` : `${options.id}-description`,
  }
}

function rootAttrs(options: Options, live = false): string {
  const value = ids(options)
  return `id="${value.content}" open={${live ? `Map.get(@state, "${options.id}", ${options.open ?? true})` : options.open ?? true}}${options.modal === false ? " modal={false}" : ""}${options.dismissible === false ? " dismissible={false}" : ""}${options.customIds ? ` title_id="${value.title}" description_id="${value.description}"` : ""}`
}

function relationships(options: Options) {
  const value = ids(options)
  return { id: value.content, "aria-labelledby": value.title, "aria-describedby": value.description }
}

function triggerProps(options: Options) {
  const value = ids(options)
  return { id: value.trigger, "aria-controls": (options.open ?? true) ? value.content : undefined }
}

function contentAttrs(options: Options): string {
  const value = ids(options)
  return `context={modal} aria-labelledby="${value.title}" aria-describedby="${value.description}"`
}

function dialogFixture(name: string, options: Options): LiveFixture {
  const value = ids(options)
  const heex = (live: boolean) => `<.dialog ${rootAttrs(options, live)}>
${options.trigger ? '  <:trigger :let={modal}><.dialog_trigger context={modal}>Edit profile</.dialog_trigger></:trigger>\n' : ""}  <:content :let={modal}>
    <.dialog_content ${contentAttrs(options)}${options.showCloseButton === false ? " show_close_button={false}" : ""}>
      <.dialog_header>
        <.dialog_title context={modal}>Edit profile</.dialog_title>
        <.dialog_description context={modal}>Make changes to your profile here. Click save when you are done.</.dialog_description>
      </.dialog_header>
      <.dialog_footer${options.footerClose ? " context={modal} show_close_button={true}" : ""}>
        <.button type="submit">Save changes</.button>
${options.showCloseButton === false ? '        <.dialog_close context={modal}>Dismiss</.dialog_close>\n' : ""}      </.dialog_footer>
    </.dialog_content>
  </:content>
</.dialog>`
  return {
    name, family: "dialog", title: name === "dialog" ? "Dialog" : `Dialog ${name.slice(7)}`, category: "overlay",
    renderReact: () => <Dialog open={options.open ?? true} modal={options.modal ?? true}>
      {options.trigger && <DialogTrigger {...triggerProps(options)}>Edit profile</DialogTrigger>}
      <DialogContent {...relationships(options)} showCloseButton={options.showCloseButton ?? true}>
        <DialogHeader>
          <DialogTitle id={value.title}>Edit profile</DialogTitle>
          <DialogDescription id={value.description}>Make changes to your profile here. Click save when you are done.</DialogDescription>
        </DialogHeader>
        <DialogFooter showCloseButton={options.footerClose ?? false}>
          <Button type="submit">Save changes</Button>
          {options.showCloseButton === false && <DialogClose>Dismiss</DialogClose>}
        </DialogFooter>
      </DialogContent>
    </Dialog>,
    heex: heex(false), liveHeex: heex(true),
  }
}

function alertFixture(name: string, options: Options): LiveFixture {
  const value = ids(options)
  const heex = (live: boolean) => `<.alert_dialog ${rootAttrs(options, live)}>
${options.trigger ? '  <:trigger :let={modal}><.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger></:trigger>\n' : ""}  <:content :let={modal}>
    <.alert_dialog_content ${contentAttrs(options)} size="${options.size ?? "default"}">
      <.alert_dialog_header>
${options.media ? '        <.alert_dialog_media><span aria-hidden="true">!</span></.alert_dialog_media>\n' : ""}        <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
        <.alert_dialog_description context={modal}>This action cannot be undone. This will permanently delete your account.</.alert_dialog_description>
      </.alert_dialog_header>
      <.alert_dialog_footer>
        <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
        <.alert_dialog_action context={modal}${options.disabledAction ? " disabled" : ""}${options.actionVariant ? ` variant="${options.actionVariant}" size="sm"` : ""}>Continue</.alert_dialog_action>
      </.alert_dialog_footer>
    </.alert_dialog_content>
  </:content>
</.alert_dialog>`
  return {
    name, family: "alert-dialog", title: name === "alert-dialog" ? "Alert Dialog" : `Alert Dialog ${name.slice(13)}`, category: "overlay",
    renderReact: () => <AlertDialog open={options.open ?? true}>
      {options.trigger && <AlertDialogTrigger {...triggerProps(options)}>Delete account</AlertDialogTrigger>}
      <AlertDialogContent {...relationships(options)} size={options.size ?? "default"}>
        <AlertDialogHeader>
          {options.media && <AlertDialogMedia><span aria-hidden="true">!</span></AlertDialogMedia>}
          <AlertDialogTitle id={value.title}>Are you absolutely sure?</AlertDialogTitle>
          <AlertDialogDescription id={value.description}>This action cannot be undone. This will permanently delete your account.</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction disabled={options.disabledAction || undefined} variant={options.actionVariant} size={options.actionVariant ? "sm" : "default"}>Continue</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>,
    heex: heex(false), liveHeex: heex(true),
  }
}

function drawerSelect(live: boolean): string {
  const state = live ? ` open={Map.get(@state, "drawer-select-fruit-open", false)} value={Map.get(@state, "drawer-select-fruit-value", nil)} on_change="shadcn:popup-change"` : ""
  return `      <div class="p-4"><.select id="drawer-select-fruit" name="drawer-fruit" placeholder="Fruit"${state}><:trigger :let={popup}><.select_trigger context={popup}><.select_value${live ? " context={popup}" : ""} placeholder="Fruit" /></.select_trigger></:trigger><:option id="drawer-select-fruit-apple" value="apple" label="Apple">Apple</:option><:option id="drawer-select-fruit-banana" value="banana" label="Banana">Banana</:option></.select></div>\n`
}

function drawerFixture(name: string, options: Options): LiveFixture {
  const value = ids(options)
  const heex = (live: boolean) => `<.drawer ${rootAttrs(options, live)} direction="${options.direction ?? "bottom"}">
${options.trigger ? '  <:trigger :let={modal}><.drawer_trigger context={modal}>Open drawer</.drawer_trigger></:trigger>\n' : ""}  <:content :let={modal}>
    <.drawer_content ${contentAttrs(options)}>
      <.drawer_header>
        <.drawer_title context={modal}>Drawer Title</.drawer_title>
        <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
      </.drawer_header>
${options.select ? drawerSelect(live) : ""}${options.trigger ? '      <.drawer_footer><.drawer_close context={modal}>Close drawer</.drawer_close></.drawer_footer>\n' : ""}    </.drawer_content>
  </:content>
</.drawer>`
  return {
    name, family: "drawer", title: name === "drawer" ? "Drawer" : `Drawer ${name.slice(7)}`, category: "overlay",
    renderReact: () => <Drawer open={options.open ?? true} direction={options.direction ?? "bottom"} dismissible={options.dismissible ?? true} modal={options.modal ?? true}>
      {options.trigger && <DrawerTrigger {...triggerProps(options)}>Open drawer</DrawerTrigger>}
      <DrawerContent {...relationships(options)}>
        <DrawerHeader>
          <DrawerTitle id={value.title}>Drawer Title</DrawerTitle>
          <DrawerDescription id={value.description}>Drawer Description goes here.</DrawerDescription>
        </DrawerHeader>
        {options.select && <div className="p-4"><Select name="drawer-fruit"><SelectTrigger id="drawer-select-fruit-trigger"><SelectValue placeholder="Fruit" /></SelectTrigger><SelectContent><SelectItem value="apple">Apple</SelectItem><SelectItem value="banana">Banana</SelectItem></SelectContent></Select></div>}
        {options.trigger && <DrawerFooter><DrawerClose>Close drawer</DrawerClose></DrawerFooter>}
      </DrawerContent>
    </Drawer>,
    heex: heex(false), liveHeex: heex(true),
  }
}

function sheetFixture(name: string, options: Options): LiveFixture {
  const value = ids(options)
  const heex = (live: boolean) => `<.sheet ${rootAttrs(options, live)}>
${options.trigger ? '  <:trigger :let={modal}><.sheet_trigger context={modal}>Edit profile</.sheet_trigger></:trigger>\n' : ""}  <:content :let={modal}>
    <.sheet_content ${contentAttrs(options)} side="${options.side ?? "right"}"${options.showCloseButton === false ? " show_close_button={false}" : ""}>
      <.sheet_header>
        <.sheet_title context={modal}>Edit profile</.sheet_title>
        <.sheet_description context={modal}>Make changes to your profile here.</.sheet_description>
      </.sheet_header>
${options.showCloseButton === false ? '      <.sheet_footer><.sheet_close context={modal}>Done</.sheet_close></.sheet_footer>\n' : ""}    </.sheet_content>
  </:content>
</.sheet>`
  return {
    name, family: "sheet", title: name === "sheet" ? "Sheet" : `Sheet ${name.slice(6)}`, category: "overlay",
    renderReact: () => <Sheet open={options.open ?? true} modal={options.modal ?? true}>
      {options.trigger && <SheetTrigger {...triggerProps(options)}>Edit profile</SheetTrigger>}
      <SheetContent {...relationships(options)} side={options.side ?? "right"} showCloseButton={options.showCloseButton ?? true}>
        <SheetHeader>
          <SheetTitle id={value.title}>Edit profile</SheetTitle>
          <SheetDescription id={value.description}>Make changes to your profile here.</SheetDescription>
        </SheetHeader>
        {options.showCloseButton === false && <SheetFooter><SheetClose>Done</SheetClose></SheetFooter>}
      </SheetContent>
    </Sheet>,
    heex: heex(false), liveHeex: heex(true),
  }
}

function twoInstances(family: string, create: (name: string, options: Options) => LiveFixture): LiveFixture {
  const first = create(`${family}-instance-a`, { id: `${family}-instance-a`, open: true, trigger: true, customIds: true })
  const second = create(`${family}-instance-b`, { id: `${family}-instance-b`, open: false, trigger: true })
  return {
    name: `${family}-multiple-instances`, family, title: `${family} Multiple Instances`, category: "overlay",
    renderReact: () => <>{first.renderReact()}{second.renderReact()}</>,
    heex: `${first.heex}\n${second.heex}`,
    liveHeex: `${first.liveHeex}\n${second.liveHeex}`,
  }
}

export const fixtures: LiveFixture[] = [
  dialogFixture("dialog", { id: "dialog-demo" }),
  dialogFixture("dialog-closed", { id: "dialog-closed-root", open: false, trigger: true }),
  dialogFixture("dialog-open-custom-ids", { id: "profile-editor", trigger: true, customIds: true }),
  dialogFixture("dialog-no-close-icon-footer-close", { id: "dialog-footer", trigger: true, showCloseButton: false, footerClose: true }),
  dialogFixture("dialog-nonmodal", { id: "dialog-nonmodal-root", trigger: true, modal: false }),
  twoInstances("dialog", dialogFixture),
  alertFixture("alert-dialog", { id: "alert-dialog-demo" }),
  alertFixture("alert-dialog-closed", { id: "alert-dialog-closed-root", open: false, trigger: true }),
  alertFixture("alert-dialog-open-custom-ids", { id: "delete-confirmation", trigger: true, customIds: true }),
  alertFixture("alert-dialog-small-media", { id: "alert-dialog-small", size: "sm", media: true, actionVariant: "destructive", disabledAction: true }),
  twoInstances("alert-dialog", alertFixture),
  drawerFixture("drawer", { id: "drawer-demo" }),
  drawerFixture("drawer-closed", { id: "drawer-closed-root", open: false, trigger: true }),
  drawerFixture("drawer-open-custom-ids", { id: "drawer-custom", trigger: true, customIds: true }),
  ...(["top", "left", "right"] as const).map(direction => drawerFixture(`drawer-${direction}`, { id: `drawer-${direction}-panel`, trigger: true, direction })),
  drawerFixture("drawer-nondismissible", { id: "drawer-nondismissible-root", trigger: true, dismissible: false }),
  drawerFixture("drawer-select", { id: "drawer-select-root", select: true }),
  twoInstances("drawer", drawerFixture),
  sheetFixture("sheet", { id: "sheet-demo" }),
  sheetFixture("sheet-closed", { id: "sheet-closed-root", open: false, trigger: true }),
  sheetFixture("sheet-open-custom-ids", { id: "sheet-custom", trigger: true, customIds: true }),
  ...(["top", "bottom", "left"] as const).map(side => sheetFixture(`sheet-${side}`, { id: `sheet-${side}-panel`, side, trigger: true, showCloseButton: false })),
  twoInstances("sheet", sheetFixture),
]

bindLiveOverlayControls(fixtures)
