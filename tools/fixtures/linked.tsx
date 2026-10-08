import React from "react"
import type { ComponentFixture } from "../fixtures"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "../../vendor/shadcn/ui/accordion"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../../vendor/shadcn/ui/tabs"

type Item = { value: string; title: string; content: string; disabled?: boolean; forceMount?: boolean; className?: string; contentClass?: string }
type AccordionExample = { id: string; type?: "single" | "multiple"; selected?: string | string[]; controlled?: boolean; collapsible?: boolean; disabled?: boolean; orientation?: "horizontal" | "vertical"; dir?: "ltr" | "rtl"; items: Item[]; className?: string }
type TabsExample = { id: string; selected?: string; controlled?: boolean; orientation?: "horizontal" | "vertical"; dir?: "ltr" | "rtl"; activationMode?: "automatic" | "manual"; variant?: "default" | "line"; items: Item[]; className?: string }

function accordionFixture(name: string, title: string, examples: AccordionExample[]): ComponentFixture {
  const heex = examples.map(example => {
    const multiple = example.type === "multiple"
    const selected = multiple ? `{${JSON.stringify(example.selected ?? [])}}` : typeof example.selected === "string" ? JSON.stringify(example.selected) : "{nil}"
    return `<.accordion id="${example.id}" type="${example.type ?? "single"}" ${example.controlled ? "value" : "default_value"}=${selected} collapsible={${!!example.collapsible}} disabled={${!!example.disabled}} orientation="${example.orientation ?? "vertical"}" dir="${example.dir ?? "ltr"}" ${example.className ? `class=${JSON.stringify(example.className)}` : ""} :let={accordion}>
${example.items.map(item => `  <.accordion_item context={accordion} value="${item.value}" disabled={${!!item.disabled}} ${item.className ? `class=${JSON.stringify(item.className)}` : ""} :let={item}>
    <.accordion_trigger context={item}>${item.title}</.accordion_trigger>
    <.accordion_content context={item} force_mount={${!!item.forceMount}} ${item.contentClass ? `class=${JSON.stringify(item.contentClass)}` : ""}>${item.content}</.accordion_content>
  </.accordion_item>`).join("\n")}
</.accordion>`
  }).join("\n")
  const liveHeex = examples.reduce((source, example) => {
    const selected = example.type === "multiple" ? `{${JSON.stringify(example.selected ?? [])}}` : typeof example.selected === "string" ? JSON.stringify(example.selected) : "{nil}"
    const initial = example.type === "multiple" ? JSON.stringify(example.selected ?? []) : typeof example.selected === "string" ? JSON.stringify(example.selected) : "nil"
    return source.replace(`${example.controlled ? "value" : "default_value"}=${selected}`, `value={Map.get(@state, "${example.id}", ${initial})}`)
  }, heex)
  return {
    name, family: "accordion", title, category: "data-display", heex, liveHeex,
    renderReact: () => <>{examples.map(example => {
      const multipleProps = { type: "multiple" as const, ...(example.controlled ? { value: Array.isArray(example.selected) ? example.selected : [] } : { defaultValue: Array.isArray(example.selected) ? example.selected : [] }) }
      const singleProps = { type: "single" as const, collapsible: !!example.collapsible, ...(example.controlled ? { value: typeof example.selected === "string" ? example.selected : "" } : { defaultValue: typeof example.selected === "string" ? example.selected : undefined }) }
      const selected = Array.isArray(example.selected) ? example.selected : example.selected ? [example.selected] : []
      return <Accordion key={example.id} id={example.id} {...(example.type === "multiple" ? multipleProps : singleProps)} disabled={example.disabled} orientation={example.orientation} dir={example.dir} className={example.className}>
        {example.items.map(item => {
          const triggerId = `${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-trigger`
          const contentId = `${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-content`
          return <AccordionItem key={item.value} value={item.value} disabled={item.disabled} className={item.className}>
            <AccordionTrigger id={triggerId} aria-controls={selected.includes(item.value) ? contentId : undefined}>{item.title}</AccordionTrigger>
            <AccordionContent id={contentId} aria-labelledby={triggerId} forceMount={item.forceMount ? true : undefined} className={item.contentClass}>{item.content}</AccordionContent>
          </AccordionItem>
        })}
      </Accordion>
    })}</>
  }
}

function tabsFixture(name: string, title: string, examples: TabsExample[]): ComponentFixture {
  const heex = examples.map(example => `<.tabs id="${example.id}" ${example.controlled ? "value" : "default_value"}=${JSON.stringify(example.selected ?? "")} orientation="${example.orientation ?? "horizontal"}" dir="${example.dir ?? "ltr"}" activation_mode="${example.activationMode ?? "automatic"}" ${example.className ? `class=${JSON.stringify(example.className)}` : ""} :let={tabs}>
  <.tabs_list context={tabs} variant="${example.variant ?? "default"}">
${example.items.map(item => `    <.tabs_trigger context={tabs} value="${item.value}" disabled={${!!item.disabled}} ${item.className ? `class=${JSON.stringify(item.className)}` : ""}>${item.title}</.tabs_trigger>`).join("\n")}
  </.tabs_list>
${example.items.map(item => `  <.tabs_content context={tabs} value="${item.value}" force_mount={${!!item.forceMount}} ${item.contentClass ? `class=${JSON.stringify(item.contentClass)}` : ""}>${item.content}</.tabs_content>`).join("\n")}
</.tabs>`).join("\n")
  const liveHeex = examples.reduce((source, example) => source.replace(`${example.controlled ? "value" : "default_value"}=${JSON.stringify(example.selected ?? "")}`, `value={Map.get(@state, "${example.id}", ${example.selected === undefined ? "nil" : JSON.stringify(example.selected)})}`), heex)
  return {
    name, family: "tabs", title, category: "navigation", heex, liveHeex,
    renderReact: () => <>{examples.map(example => <Tabs key={example.id} id={example.id} {...(example.controlled ? { value: example.selected ?? "" } : { defaultValue: example.selected })} orientation={example.orientation} dir={example.dir} activationMode={example.activationMode} className={example.className}>
      <TabsList variant={example.variant}>
        {example.items.map(item => <TabsTrigger key={item.value} value={item.value} id={`${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-trigger`} aria-controls={`${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-content`} disabled={item.disabled} className={item.className}>{item.title}</TabsTrigger>)}
      </TabsList>
      {example.items.map(item => <TabsContent key={item.value} value={item.value} id={`${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-content`} aria-labelledby={`${example.id}-${encodeURIComponent(item.value).replaceAll("%20", "+")}-trigger`} forceMount={item.forceMount ? true : undefined} className={item.contentClass}>{item.content}</TabsContent>)}
    </Tabs>)}</>
  }
}

const accordionItems: Item[] = [
  { value: "intro", title: "Introduction", content: "Start with an introduction." },
  { value: "details", title: "Details", content: "Read the details." },
  { value: "advanced", title: "Advanced", content: "Explore advanced settings." }
]
const tabItems: Item[] = [
  { value: "overview", title: "Overview", content: "View the overview." },
  { value: "history", title: "History", content: "View the history." },
  { value: "settings", title: "Settings", content: "Adjust settings." }
]

export const fixtures: ComponentFixture[] = [
  accordionFixture("accordion", "Accordion", [{ id: "accordion-demo", selected: "item-1", items: [{ value: "item-1", title: "Is it accessible?", content: "Yes. It adheres to the WAI-ARIA design pattern." }] }]),
  accordionFixture("accordion-closed", "Accordion — initially closed", [{ id: "accordion-closed-demo", collapsible: true, items: accordionItems }]),
  accordionFixture("accordion-selected-details", "Accordion — controlled different selection", [{ id: "accordion-details-demo", selected: "details", controlled: true, collapsible: true, items: accordionItems }]),
  accordionFixture("accordion-multiple", "Accordion — multiple open", [{ id: "accordion-multiple-demo", type: "multiple", selected: ["intro", "advanced"], controlled: true, items: accordionItems }]),
  accordionFixture("accordion-disabled", "Accordion — disabled items", [{ id: "accordion-disabled-demo", selected: "intro", collapsible: true, items: accordionItems.map(item => ({ ...item, disabled: item.value === "details" })) }, { id: "accordion-disabled-root", selected: "details", disabled: true, items: accordionItems }]),
  accordionFixture("accordion-force-mount", "Accordion — retained closed content", [{ id: "accordion-force-demo", collapsible: true, orientation: "horizontal", dir: "rtl", className: "max-w-lg", items: accordionItems.map(item => ({ ...item, forceMount: true, contentClass: "text-muted-foreground" })) }]),
  accordionFixture("accordion-instances", "Accordion — independent instances", [{ id: "accordion-first", selected: "intro", items: accordionItems }, { id: "accordion-second", selected: "details", collapsible: true, items: accordionItems }]),
  tabsFixture("tabs", "Tabs", [{ id: "tabs-demo", selected: "account", className: "w-[400px]", items: [{ value: "account", title: "Account", content: "Make changes to your account here." }, { value: "password", title: "Password", content: "Change your password here." }] }]),
  tabsFixture("tabs-history", "Tabs — controlled non-account selection", [{ id: "tabs-history-demo", selected: "history", controlled: true, items: tabItems }]),
  tabsFixture("tabs-unselected", "Tabs — initially unselected", [{ id: "tabs-unselected-demo", items: tabItems }]),
  tabsFixture("tabs-disabled", "Tabs — disabled and manual activation", [{ id: "tabs-disabled-demo", selected: "overview", activationMode: "manual", items: tabItems.map(item => ({ ...item, disabled: item.value === "history" })) }]),
  tabsFixture("tabs-line-rtl", "Tabs — line variant, visual vertical and RTL", [{ id: "tabs-line-demo", selected: "settings", variant: "line", orientation: "vertical", dir: "rtl", items: tabItems }]),
  tabsFixture("tabs-force-mount", "Tabs — retained inactive content", [{ id: "tabs-force-demo", selected: "history", items: tabItems.map(item => ({ ...item, forceMount: true, contentClass: "p-2" })) }]),
  tabsFixture("tabs-instances", "Tabs — independent instances", [{ id: "tabs-first", selected: "overview", items: tabItems }, { id: "tabs-second", selected: "settings", items: tabItems }])
]
