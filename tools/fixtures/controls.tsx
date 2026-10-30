import React from "react"
import type { ComponentFixture } from "../fixtures"
import { bindLiveOverlayControls } from "../../assets/js/react-fixtures/overlay-controls"
import { Checkbox } from "../../vendor/shadcn/ui/checkbox"
import { Switch } from "../../vendor/shadcn/ui/switch"
import { Slider } from "../../vendor/shadcn/ui/slider"
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "../../vendor/shadcn/ui/collapsible"
import { NavigationMenu, NavigationMenuList, NavigationMenuItem, NavigationMenuTrigger, NavigationMenuContent, NavigationMenuLink, NavigationMenuIndicator } from "../../vendor/shadcn/ui/navigation-menu"

export const fixtures: ComponentFixture[] = [
  {
    name: "checkbox", title: "Checkbox", category: "forms",
    renderReact: () => <div className="flex items-center space-x-2"><Checkbox id="terms" /><label htmlFor="terms" className="text-sm font-medium leading-none">Accept terms</label></div>,
    heex: `<div class="flex items-center space-x-2"><.checkbox id="terms" /><label for="terms" class="text-sm font-medium leading-none">Accept terms</label></div>`,
    liveHeex: `<div class="flex items-center space-x-2"><.checkbox id="terms" checked={Map.get(@state, "terms", false)} on_change="control_change" /><label for="terms" class="text-sm font-medium leading-none">Accept terms</label></div>`
  },
  ...([false, true, "indeterminate"] as const).flatMap(checked => [false, true].map(disabled => {
    const id = `checkbox-${checked}-${disabled ? "disabled" : "enabled"}`
    return {
      name: id, family: "checkbox", title: `Checkbox ${checked} ${disabled ? "Disabled" : "Enabled"}`, category: "forms" as const,
      renderReact: () => <form id={`${id}-form`}><Checkbox id={id} checked={checked} onCheckedChange={() => {}} disabled={disabled} required name="permission" value="allow" aria-label="Permission" className="size-5" /><button type="reset">Reset</button></form>,
      heex: `<form id="${id}-form"><.checkbox id="${id}" checked={${JSON.stringify(checked)}} disabled={${disabled}} required name="permission" value="allow" aria-label="Permission" class="size-5" /><button type="reset">Reset</button></form>`,
      liveHeex: `<form id="${id}-form"><.checkbox id="${id}" checked={Map.get(@state, "${id}", ${JSON.stringify(checked)})} on_change="control_change" disabled={${disabled}} required name="permission" value="allow" aria-label="Permission" class="size-5" /><button type="reset">Reset</button></form>`
    }
  })),
  {
    name: "checkbox-multiple-external-form", family: "checkbox", title: "Checkbox Multiple External Form", category: "forms",
    renderReact: () => <div><form id="checkbox-external"><button type="reset">Reset permissions</button></form><Checkbox id="permission-read" defaultChecked name="permissions[]" value="read" form="checkbox-external" aria-label="Read" /><Checkbox id="permission-write" name="permissions[]" value="write" form="checkbox-external" aria-label="Write" /></div>,
    heex: `<div><form id="checkbox-external"><button type="reset">Reset permissions</button></form><.checkbox id="permission-read" default_checked={true} name="permissions[]" value="read" form="checkbox-external" aria-label="Read" /><.checkbox id="permission-write" name="permissions[]" value="write" form="checkbox-external" aria-label="Write" /></div>`,
    liveHeex: `<div><form id="checkbox-external"><button type="reset">Reset permissions</button></form><.checkbox id="permission-read" checked={Map.get(@state, "permission-read", true)} on_change="control_change" name="permissions[]" value="read" form="checkbox-external" aria-label="Read" /><.checkbox id="permission-write" checked={Map.get(@state, "permission-write", false)} on_change="control_change" name="permissions[]" value="write" form="checkbox-external" aria-label="Write" /></div>`
  },
  {
    name: "switch", title: "Switch", category: "forms",
    renderReact: () => <Switch id="airplane-mode" />,
    heex: `<.switch id="airplane-mode" />`,
    liveHeex: `<.switch id="airplane-mode" checked={Map.get(@state, "airplane-mode", false)} on_change="control_change" />`
  },
  ...(["default", "sm"] as const).flatMap(size => [false, true].flatMap(checked => [false, true].map(disabled => {
    const id = `switch-${size}-${checked}-${disabled ? "disabled" : "enabled"}`
    return {
      name: id, family: "switch", title: `Switch ${size} ${checked} ${disabled ? "Disabled" : "Enabled"}`, category: "forms" as const,
      renderReact: () => <form id={`${id}-form`}><Switch id={id} size={size} checked={checked} onCheckedChange={() => {}} disabled={disabled} required name="notifications" value="enabled" aria-label="Notifications" /><button type="reset">Reset</button></form>,
      heex: `<form id="${id}-form"><.switch id="${id}" size="${size}" checked={${checked}} disabled={${disabled}} required name="notifications" value="enabled" aria-label="Notifications" /><button type="reset">Reset</button></form>`,
      liveHeex: `<form id="${id}-form"><.switch id="${id}" size="${size}" checked={Map.get(@state, "${id}", ${checked})} on_change="control_change" disabled={${disabled}} required name="notifications" value="enabled" aria-label="Notifications" /><button type="reset">Reset</button></form>`
    }
  }))),
  {
    name: "switch-multiple-external-form", family: "switch", title: "Switch Multiple External Form", category: "forms",
    renderReact: () => <div><form id="switch-settings"><button type="reset">Reset settings</button></form><Switch id="switch-mail" defaultChecked name="mail" form="switch-settings" aria-label="Mail" /><Switch id="switch-sms" size="sm" name="sms" form="switch-settings" aria-label="SMS" /></div>,
    heex: `<div><form id="switch-settings"><button type="reset">Reset settings</button></form><.switch id="switch-mail" default_checked={true} name="mail" form="switch-settings" aria-label="Mail" /><.switch id="switch-sms" size="sm" name="sms" form="switch-settings" aria-label="SMS" /></div>`,
    liveHeex: `<div><form id="switch-settings"><button type="reset">Reset settings</button></form><.switch id="switch-mail" checked={Map.get(@state, "switch-mail", true)} on_change="control_change" name="mail" form="switch-settings" aria-label="Mail" /><.switch id="switch-sms" size="sm" checked={Map.get(@state, "switch-sms", false)} on_change="control_change" name="sms" form="switch-settings" aria-label="SMS" /></div>`
  },
  {
    name: "slider", title: "Slider", category: "forms",
    renderReact: () => <Slider id="slider-base" defaultValue={[50]} max={100} step={1} className="w-[60%]" />,
    heex: `<.slider id="slider-base" default_value={[50]} max={100} step={1} class="w-[60%]" />`,
    liveHeex: `<.slider id="slider-base" value={Map.get(@state, "slider-base", [50])} default_value={[50]} on_change="control_change" max={100} step={1} class="w-[60%]" />`
  },
  ...[
    {id: "slider-lower-bound", values: [-10], min: -10, max: 10, step: 0.5},
    {id: "slider-upper-bound", values: [10], min: -10, max: 10, step: 0.5},
    {id: "slider-range", values: [20, 80], min: 10, max: 90, step: 5},
    {id: "slider-three-thumbs", values: [10, 40, 80], min: 0, max: 100, step: 10},
    {id: "slider-vertical", values: [25], min: 0, max: 50, step: 5, orientation: "vertical" as const},
    {id: "slider-rtl", values: [15, 70], min: 0, max: 100, step: 5, dir: "rtl" as const},
    {id: "slider-inverted", values: [35], min: 0, max: 100, step: 5, inverted: true},
    {id: "slider-disabled", values: [30, 60], min: 0, max: 90, step: 3, disabled: true},
  ].map(config => {
    const {id, values, min, max, step} = config
    const orientation = "orientation" in config ? config.orientation : "horizontal"
    const dir = "dir" in config ? config.dir : "ltr"
    const inverted = "inverted" in config && config.inverted
    const disabled = "disabled" in config && config.disabled
    const attributes = `id="${id}" min={${min}} max={${max}} step={${step}} orientation="${orientation}" dir="${dir}" inverted={${inverted}} disabled={${disabled}} name="amount" aria-label="Amount" class="w-64"`
    return {
      name: id, family: "slider", title: id, category: "forms" as const,
      renderReact: () => <form id={`${id}-form`}><Slider id={id} value={values} onValueChange={() => {}} min={min} max={max} step={step} orientation={orientation} dir={dir} inverted={inverted} disabled={disabled} name="amount" aria-label="Amount" className="w-64" /><button type="reset">Reset</button></form>,
      heex: `<form id="${id}-form"><.slider ${attributes} value={${JSON.stringify(values)}} /><button type="reset">Reset</button></form>`,
      liveHeex: `<form id="${id}-form"><.slider ${attributes} value={Map.get(@state, "${id}", ${JSON.stringify(values)})} default_value={${JSON.stringify(values)}} on_change="control_change" /><button type="reset">Reset</button></form>`
    }
  }),
  {
    name: "slider-default-extents", family: "slider", title: "Slider Default Extents", category: "forms",
    renderReact: () => <Slider id="slider-default-extents" min={10} max={30} />,
    heex: `<.slider id="slider-default-extents" min={10} max={30} />`
  },
  {
    name: "slider-multiple-instances", family: "slider", title: "Slider Multiple Instances", category: "forms",
    renderReact: () => <form id="slider-multiple-form" className="w-64 space-y-4"><Slider id="slider-price" defaultValue={[5, 15]} min={0} max={20} step={1} name="price" /><Slider id="slider-rating" defaultValue={[3]} min={1} max={5} step={1} name="rating" /></form>,
    heex: `<form id="slider-multiple-form" class="w-64 space-y-4"><.slider id="slider-price" default_value={[5, 15]} min={0} max={20} step={1} name="price" /><.slider id="slider-rating" default_value={[3]} min={1} max={5} step={1} name="rating" /></form>`,
    liveHeex: `<form id="slider-multiple-form" class="w-64 space-y-4"><.slider id="slider-price" value={Map.get(@state, "slider-price", [5, 15])} default_value={[5, 15]} on_change="control_change" min={0} max={20} step={1} name="price" /><.slider id="slider-rating" value={Map.get(@state, "slider-rating", [3])} default_value={[3]} on_change="control_change" min={1} max={5} step={1} name="rating" /></form>`
  },
  {
    name: "slider-external-form", family: "slider", title: "Slider External Form", category: "forms",
    renderReact: () => <div><form id="slider-external-form" /><Slider id="slider-external" className="w-64" defaultValue={[2]} min={0} max={10} step={0.25} name="quantity" form="slider-external-form" /></div>,
    heex: `<div><form id="slider-external-form"></form><.slider id="slider-external" class="w-64" default_value={[2]} min={0} max={10} step={0.25} name="quantity" form="slider-external-form" /></div>`,
    liveHeex: `<div><form id="slider-external-form"></form><.slider id="slider-external" class="w-64" value={Map.get(@state, "slider-external", [2])} default_value={[2]} on_change="control_change" min={0} max={10} step={0.25} name="quantity" form="slider-external-form" /></div>`
  },
  {
    name: "slider-minimum-thumb-distance", family: "slider", title: "Slider Minimum Thumb Distance", category: "forms",
    renderReact: () => <Slider id="slider-thumb-distance" value={[20, 60]} min={0} max={100} step={5} minStepsBetweenThumbs={2} />,
    heex: `<.slider id="slider-thumb-distance" value={[20, 60]} min={0} max={100} step={5} min_steps_between_thumbs={2} />`,
    liveHeex: `<.slider id="slider-thumb-distance" value={Map.get(@state, "slider-thumb-distance", [20, 60])} on_change="control_change" min={0} max={100} step={5} min_steps_between_thumbs={2} />`
  },
  {
    name: "collapsible", title: "Collapsible", category: "layout",
    renderReact: () => <Collapsible id="collapsible-base" open><CollapsibleTrigger className="px-4 py-2 text-sm font-medium">Toggle Details</CollapsibleTrigger><CollapsibleContent className="px-4 py-2 text-sm">Here is collapsible content.</CollapsibleContent></Collapsible>,
    heex: `<.collapsible :let={context} id="collapsible-base" open={true}><.collapsible_trigger context={context} class="px-4 py-2 text-sm font-medium">Toggle Details</.collapsible_trigger><.collapsible_content context={context} class="px-4 py-2 text-sm">Here is collapsible content.</.collapsible_content></.collapsible>`,
    liveHeex: `<.collapsible :let={context} id="collapsible-base" open={Map.get(@state, "collapsible-base", true)}><.collapsible_trigger context={context} class="px-4 py-2 text-sm font-medium">Toggle Details</.collapsible_trigger><.collapsible_content context={context} class="px-4 py-2 text-sm">Here is collapsible content.</.collapsible_content></.collapsible>`
  },
  ...[false, true].flatMap(open => [false, true].map(disabled => {
    const id = `collapsible-${open ? "open" : "closed"}-${disabled ? "disabled" : "enabled"}`
    return {
      name: id, family: "collapsible", title: id, category: "layout" as const,
      renderReact: () => <Collapsible id={id} open={open} disabled={disabled}><CollapsibleTrigger>Details</CollapsibleTrigger><CollapsibleContent><p>Scoped content</p></CollapsibleContent></Collapsible>,
      heex: `<.collapsible :let={context} id="${id}" open={${open}} disabled={${disabled}}><.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={context}><p>Scoped content</p></.collapsible_content></.collapsible>`,
      liveHeex: `<.collapsible :let={context} id="${id}" open={Map.get(@state, "${id}", ${open})} disabled={${disabled}}><.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={context}><p>Scoped content</p></.collapsible_content></.collapsible>`
    }
  })),
  {
    name: "collapsible-force-mount", family: "collapsible", title: "Collapsible Force Mount", category: "layout",
    renderReact: () => <Collapsible id="collapsible-forced" open={false}><CollapsibleTrigger>More</CollapsibleTrigger><CollapsibleContent forceMount>Always mounted</CollapsibleContent></Collapsible>,
    heex: `<.collapsible :let={context} id="collapsible-forced" open={false}><.collapsible_trigger context={context}>More</.collapsible_trigger><.collapsible_content context={context} force_mount={true}>Always mounted</.collapsible_content></.collapsible>`
  },
  {
    name: "collapsible-multiple-instances", family: "collapsible", title: "Collapsible Multiple Instances", category: "layout",
    renderReact: () => <div><Collapsible id="details-one" open><CollapsibleTrigger>One</CollapsibleTrigger><CollapsibleContent>First</CollapsibleContent></Collapsible><Collapsible id="details-two" open={false}><CollapsibleTrigger>Two</CollapsibleTrigger><CollapsibleContent>Second</CollapsibleContent></Collapsible></div>,
    heex: `<div><.collapsible :let={context} id="details-one" open={true}><.collapsible_trigger context={context}>One</.collapsible_trigger><.collapsible_content context={context}>First</.collapsible_content></.collapsible><.collapsible :let={context} id="details-two" open={false}><.collapsible_trigger context={context}>Two</.collapsible_trigger><.collapsible_content context={context}>Second</.collapsible_content></.collapsible></div>`,
    liveHeex: `<div><.collapsible :let={context} id="details-one" open={Map.get(@state, "details-one", true)}><.collapsible_trigger context={context}>One</.collapsible_trigger><.collapsible_content context={context}>First</.collapsible_content></.collapsible><.collapsible :let={context} id="details-two" open={Map.get(@state, "details-two", false)}><.collapsible_trigger context={context}>Two</.collapsible_trigger><.collapsible_content context={context}>Second</.collapsible_content></.collapsible></div>`
  },
  {
    name: "navigation-menu", title: "Navigation Menu", category: "navigation",
    renderReact: () => <NavigationMenu id="navigation-base"><NavigationMenuList><NavigationMenuItem value="docs"><NavigationMenuLink href="/docs">Documentation</NavigationMenuLink></NavigationMenuItem></NavigationMenuList></NavigationMenu>,
    heex: `<.navigation_menu :let={context} id="navigation-base"><.navigation_menu_list context={context}><.navigation_menu_item context={context} value="docs"><.navigation_menu_link href="/docs">Documentation</.navigation_menu_link></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`
  },
  ...[false, true].flatMap(viewport => ["", "docs", "about"].map(value => {
    const id = `navigation-${viewport ? "viewport" : "inline"}-${value || "closed"}`
    const children = `<.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item}><.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link></.navigation_menu_content></.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about"><.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={item}><.navigation_menu_link href="/about">Company</.navigation_menu_link></.navigation_menu_content></.navigation_menu_item><.navigation_menu_item context={context} value="home"><.navigation_menu_link href="/">Home</.navigation_menu_link></.navigation_menu_item></.navigation_menu_list>`
    return {
      name: id, family: "navigation-menu", title: id, category: "navigation" as const,
      renderReact: () => <NavigationMenu id={id} value={value} onValueChange={() => {}} viewport={viewport}><NavigationMenuList><NavigationMenuItem value="docs"><NavigationMenuTrigger>Docs</NavigationMenuTrigger><NavigationMenuContent><NavigationMenuLink href="/docs" active>Guide</NavigationMenuLink></NavigationMenuContent></NavigationMenuItem><NavigationMenuItem value="about"><NavigationMenuTrigger>About</NavigationMenuTrigger><NavigationMenuContent><NavigationMenuLink href="/about">Company</NavigationMenuLink></NavigationMenuContent></NavigationMenuItem><NavigationMenuItem value="home"><NavigationMenuLink href="/">Home</NavigationMenuLink></NavigationMenuItem></NavigationMenuList></NavigationMenu>,
      heex: `<.navigation_menu :let={context} id="${id}" value="${value}" viewport={${viewport}}>${children}</.navigation_menu>`,
      liveHeex: `<.navigation_menu :let={context} id="${id}" value={Map.get(@state, "${id}", "${value}")} viewport={${viewport}}>${children}</.navigation_menu>`
    }
  })),
  {
    name: "navigation-vertical-rtl-disabled", family: "navigation-menu", title: "Navigation Vertical RTL Disabled", category: "navigation",
    renderReact: () => <NavigationMenu id="navigation-vertical" orientation="vertical" dir="rtl" viewport={false}><NavigationMenuList><NavigationMenuItem value="locked"><NavigationMenuTrigger disabled>Locked</NavigationMenuTrigger><NavigationMenuContent>Unavailable</NavigationMenuContent></NavigationMenuItem><NavigationMenuItem value="active"><NavigationMenuLink active href="/active">Active</NavigationMenuLink></NavigationMenuItem></NavigationMenuList></NavigationMenu>,
    heex: `<.navigation_menu :let={context} id="navigation-vertical" orientation="vertical" dir="rtl" viewport={false}><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="locked"><.navigation_menu_trigger context={item} disabled>Locked</.navigation_menu_trigger><.navigation_menu_content context={item}>Unavailable</.navigation_menu_content></.navigation_menu_item><.navigation_menu_item context={context} value="active"><.navigation_menu_link active href="/active">Active</.navigation_menu_link></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`
  },
  {
    name: "navigation-force-mount", family: "navigation-menu", title: "Navigation Force Mount", category: "navigation",
    renderReact: () => <NavigationMenu id="navigation-forced" viewport={false}><NavigationMenuList><NavigationMenuItem value="docs"><NavigationMenuTrigger>Docs</NavigationMenuTrigger><NavigationMenuContent forceMount>Mounted docs</NavigationMenuContent></NavigationMenuItem></NavigationMenuList></NavigationMenu>,
    heex: `<.navigation_menu :let={context} id="navigation-forced" viewport={false}><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item} force_mount={true}>Mounted docs</.navigation_menu_content></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`
  },
  {
    name: "navigation-multiple-instances", family: "navigation-menu", title: "Navigation Multiple Instances", category: "navigation",
    renderReact: () => <div>{["primary", "secondary"].map(id => <NavigationMenu key={id} id={`navigation-${id}`} viewport={false} value={id === "primary" ? "docs" : ""}><NavigationMenuList><NavigationMenuItem value="docs"><NavigationMenuTrigger>Docs</NavigationMenuTrigger><NavigationMenuContent><NavigationMenuLink href="/docs">Guide</NavigationMenuLink></NavigationMenuContent></NavigationMenuItem></NavigationMenuList></NavigationMenu>)}</div>,
    heex: `<div>${["primary", "secondary"].map(id => `<.navigation_menu :let={context} id="navigation-${id}" viewport={false} value="${id === "primary" ? "docs" : ""}"><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item}><.navigation_menu_link href="/docs">Guide</.navigation_menu_link></.navigation_menu_content></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`).join("")}</div>`,
    liveHeex: `<div>${["primary", "secondary"].map(id => `<.navigation_menu :let={context} id="navigation-${id}" viewport={false} value={Map.get(@state, "navigation-${id}", "${id === "primary" ? "docs" : ""}")}><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item}><.navigation_menu_link href="/docs">Guide</.navigation_menu_link></.navigation_menu_content></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`).join("")}</div>`
  },
  {
    name: "navigation-indicator", family: "navigation-menu", title: "Navigation Indicator", category: "navigation",
    renderReact: () => <NavigationMenu id="navigation-indicator" value="docs" viewport={false}><NavigationMenuList><NavigationMenuItem value="docs"><NavigationMenuTrigger>Docs</NavigationMenuTrigger><NavigationMenuContent>Guide</NavigationMenuContent></NavigationMenuItem><NavigationMenuIndicator /></NavigationMenuList></NavigationMenu>,
    heex: `<.navigation_menu :let={context} id="navigation-indicator" value="docs" viewport={false}><:indicator /><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item}>Guide</.navigation_menu_content></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`,
    liveHeex: `<.navigation_menu :let={context} id="navigation-indicator" value={Map.get(@state, "navigation-indicator", "docs")} viewport={false}><:indicator /><.navigation_menu_list context={context}><.navigation_menu_item :let={item} context={context} value="docs"><.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={item}>Guide</.navigation_menu_content></.navigation_menu_item></.navigation_menu_list></.navigation_menu>`
  }
]

for (const fixture of fixtures) {
  if (fixture.liveHeex) continue
  const family = fixture.family ?? fixture.name
  if (family === "slider") {
    fixture.liveHeex = fixture.heex.replace('<.slider id="slider-default-extents"', '<.slider id="slider-default-extents" value={Map.get(@state, "slider-default-extents", [10, 30])} default_value={[10, 30]} on_change="control_change"')
  } else if (family === "collapsible") {
    fixture.liveHeex = fixture.heex.replace('open={false}', 'open={Map.get(@state, "collapsible-forced", false)}')
  } else if (family === "navigation-menu") {
    fixture.liveHeex = fixture.heex.replace(/<\.navigation_menu([^>]*?)id="([^"]+)"/, (_match, attrs: string, id: string) => `<.navigation_menu${attrs}id="${id}" value={Map.get(@state, "${id}", "")}`)
  }
}

bindLiveOverlayControls(fixtures)
