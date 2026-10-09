import * as React from "react"
import type { ComponentFixture } from "../../../tools/fixtures"
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from "../../../vendor/shadcn/ui/accordion"
import { Tabs } from "../../../vendor/shadcn/ui/tabs"
import { Dialog, DialogTrigger, DialogContent } from "../../../vendor/shadcn/ui/dialog"
import { AlertDialog, AlertDialogTrigger, AlertDialogContent } from "../../../vendor/shadcn/ui/alert-dialog"
import { Drawer, DrawerTrigger, DrawerContent } from "../../../vendor/shadcn/ui/drawer"
import { Sheet, SheetTrigger, SheetContent } from "../../../vendor/shadcn/ui/sheet"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuCheckboxItem, DropdownMenuRadioGroup } from "../../../vendor/shadcn/ui/dropdown-menu"
import { HoverCard, HoverCardTrigger } from "../../../vendor/shadcn/ui/hover-card"
import { Popover, PopoverTrigger, PopoverContent } from "../../../vendor/shadcn/ui/popover"
import { Select, SelectTrigger, SelectContent, SelectValue } from "../../../vendor/shadcn/ui/select"
import { Tooltip, TooltipTrigger } from "../../../vendor/shadcn/ui/tooltip"
import { Checkbox } from "../../../vendor/shadcn/ui/checkbox"
import { Switch } from "../../../vendor/shadcn/ui/switch"
import { Slider } from "../../../vendor/shadcn/ui/slider"
import { Collapsible } from "../../../vendor/shadcn/ui/collapsible"
import { NavigationMenu } from "../../../vendor/shadcn/ui/navigation-menu"
import { RadioGroup } from "../../../vendor/shadcn/ui/radio-group"
import { ToggleGroup } from "../../../vendor/shadcn/ui/toggle-group"
import { Menubar, MenubarSub, MenubarCheckboxItem, MenubarRadioGroup } from "../../../vendor/shadcn/ui/menubar"

type Props = Record<string, unknown> & { children?: React.ReactNode }
type Element = React.ReactElement<Props>
type StateValue = boolean | string | string[] | number[]
type Binding = {
  prop: "value" | "open" | "checked"
  callback: "onValueChange" | "onOpenChange" | "onCheckedChange"
  initial?: (props: Props) => StateValue
}
const value: Binding = { prop: "value", callback: "onValueChange" }
const open: Binding = { prop: "open", callback: "onOpenChange" }
const checked: Binding = { prop: "checked", callback: "onCheckedChange" }

// These contracts are limited to the vendor controls used by these fixture families.
// Uncontrolled roots retain their vendor-owned state; controlled props get real callbacks.
const bindings = new Map<React.ElementType, Binding[]>([
  [Accordion, [{ ...value, initial: props => (props.defaultValue as StateValue) ?? (props.type === "multiple" ? [] : "") }]],
  [Tabs, [value]],
  [Dialog, [open]], [AlertDialog, [open]], [Drawer, [open]], [Sheet, [open]],
  [DropdownMenu, [open]], [DropdownMenuCheckboxItem, [checked]], [DropdownMenuRadioGroup, [value]],
  [HoverCard, [{ ...open, initial: props => Boolean(props.defaultOpen) }]], [Popover, [open]],
  [Tooltip, [{ ...open, initial: props => Boolean(props.defaultOpen) }]], [Select, [open, value]],
  [Checkbox, [checked]], [Switch, [checked]],
  [Slider, [{ ...value, initial: props => (props.defaultValue as number[]) ?? [Number(props.min ?? 0), Number(props.max ?? 100)] }]],
  [Collapsible, [open]], [NavigationMenu, [value]], [RadioGroup, [value]], [ToggleGroup, [value]],
  [Menubar, [value]], [MenubarSub, [open]], [MenubarCheckboxItem, [checked]], [MenubarRadioGroup, [value]],
])

const disclosures = new Map<React.ElementType, [React.ElementType, React.ElementType]>([
  [Dialog, [DialogTrigger, DialogContent]], [AlertDialog, [AlertDialogTrigger, AlertDialogContent]],
  [Drawer, [DrawerTrigger, DrawerContent]], [Sheet, [SheetTrigger, SheetContent]],
  [DropdownMenu, [DropdownMenuTrigger, DropdownMenuContent]], [Popover, [PopoverTrigger, PopoverContent]],
  [Select, [SelectTrigger, SelectContent]],
])

function mapElements(children: React.ReactNode, map: (element: Element, index: number) => React.ReactNode): React.ReactNode {
  if (React.isValidElement<Props>(children)) return map(children, 0)
  return React.Children.map(children, (child, index) => React.isValidElement<Props>(child) ? map(child, index) : child)
}

function liveRelationships(element: Element, props: Props): React.ReactNode {
  if (element.type === Accordion) {
    const selected = Array.isArray(props.value) ? props.value : [props.value]
    return mapElements(props.children, item => {
      if (item.type !== AccordionItem) return item
      const content = React.Children.toArray(item.props.children).find(child => React.isValidElement(child) && child.type === AccordionContent) as Element | undefined
      return React.cloneElement(item, {}, mapElements(item.props.children, child => child.type === AccordionTrigger
        ? React.cloneElement(child, { "aria-controls": selected.includes(item.props.value) ? content?.props.id : undefined })
        : child))
    })
  }
  const disclosure = disclosures.get(element.type as React.ElementType)
  if (disclosure) {
    const [triggerType, contentType] = disclosure
    const content = React.Children.toArray(props.children).find(child => React.isValidElement(child) && child.type === contentType) as Element | undefined
    return mapElements(props.children, child => child.type === triggerType && content?.props.id
      ? React.cloneElement(child, { "aria-controls": props.open ? content.props.id : undefined })
      : child)
  }
  return props.children
}

function LiveOverlayControls({ render }: { render: ComponentFixture["renderReact"] }) {
  const tree = React.useMemo(render, [render])
  // State lives above portals/content, so menu selections survive closing and reopening.
  const [state, setState] = React.useState<Record<string, StateValue>>({})

  function visit(children: React.ReactNode, parent: string): React.ReactNode {
    return mapElements(children, (child, index) => {
      const path = `${parent}/${index}`
      const props: Props = { ...child.props }
      // Radix's hover/focus roots do not themselves check their button's disabled flag.
      const hoverTrigger = child.type === HoverCard ? HoverCardTrigger : child.type === Tooltip ? TooltipTrigger : undefined
      const disabledHover = hoverTrigger !== undefined && React.Children.toArray(props.children).some(trigger => {
        if (!React.isValidElement<Props>(trigger) || trigger.type !== hoverTrigger) return false
        return Boolean(trigger.props.disabled) || (Boolean(trigger.props.asChild) && React.Children.toArray(trigger.props.children).some(button => React.isValidElement<Props>(button) && Boolean(button.props.disabled)))
      })
      for (const binding of bindings.get(child.type as React.ElementType) ?? []) {
        if (props[binding.prop] === undefined && !binding.initial) continue
        const key = `${path}:${binding.prop}`
        props[binding.prop] = disabledHover && binding.prop === "open" ? false : state[key] ?? props[binding.prop] ?? binding.initial?.(props)
        props[binding.callback] = (next: StateValue) => {
          if (!disabledHover) setState(current => ({ ...current, [key]: next }))
        }
      }
      // A caller-provided SelectValue label would otherwise remain frozen after selection.
      if (child.type === SelectValue && props.children !== undefined) props.children = undefined
      if (child.type === "form") {
        const onReset = props.onReset as React.FormEventHandler<HTMLFormElement> | undefined
        props.onReset = (event: React.FormEvent<HTMLFormElement>) => {
          onReset?.(event)
          if (!event.defaultPrevented) setState(current => Object.fromEntries(Object.entries(current).filter(([key]) => !key.startsWith(`${path}/`))))
        }
      }
      const liveChildren = visit(liveRelationships(child, props), path)
      return props.children === undefined
        ? React.cloneElement(child, props)
        : React.cloneElement(child, props, liveChildren)
    })
  }

  return <>{visit(tree, "fixture")}</>
}

export function bindLiveOverlayControls(fixtures: ComponentFixture[]) {
  for (const fixture of fixtures) fixture.renderLiveReact = () => <LiveOverlayControls render={fixture.renderReact} />
}
