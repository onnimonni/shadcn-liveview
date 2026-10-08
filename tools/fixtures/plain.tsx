import React from "react"
import { Button } from "../../vendor/shadcn/ui/button"
import { Badge } from "../../vendor/shadcn/ui/badge"
import { Toggle } from "../../vendor/shadcn/ui/toggle"
import { Card, CardContent } from "../../vendor/shadcn/ui/card"
import { Input } from "../../vendor/shadcn/ui/input"
import { Textarea } from "../../vendor/shadcn/ui/textarea"
import type { ComponentFixture } from "../fixtures"

export const fixtures: ComponentFixture[] = [
  ...(["default", "outline", "secondary", "ghost", "destructive", "link"] as const).flatMap(variant =>
    (["default", "xs", "sm", "lg", "icon", "icon-xs", "icon-sm", "icon-lg"] as const).map(size => ({
      name: `button-${variant}-${size}`, family: "button", title: `Button ${variant} ${size}`, category: "actions" as const,
      renderReact: () => <Button variant={variant} size={size} disabled={variant === "destructive"}>Save</Button>,
      heex: `<.button variant="${variant}" size="${size}" disabled={${variant === "destructive"}}>Save</.button>`,
    }))),
  ...(["default", "secondary", "destructive", "outline", "ghost", "link"] as const).map(variant => ({
    name: `badge-${variant}`, family: "badge", title: `Badge ${variant}`, category: "data-display" as const,
    renderReact: () => <Badge variant={variant}>Status</Badge>,
    heex: `<.badge variant="${variant}">Status</.badge>`,
  })),
  ...(["default", "outline"] as const).flatMap(variant => (["default", "sm", "lg"] as const).flatMap(size =>
    [false, true].map(pressed => ({
      name: `toggle-${variant}-${size}-${pressed ? "on" : "off"}`, family: "toggle", title: `Toggle ${variant} ${size} ${pressed ? "on" : "off"}`, category: "actions" as const,
      renderReact: () => <Toggle id={`toggle-${variant}-${size}-${pressed}`} variant={variant} size={size} pressed={pressed}>Bold</Toggle>,
      heex: `<.toggle id="toggle-${variant}-${size}-${pressed}" variant="${variant}" size="${size}" pressed={${pressed}}>Bold</.toggle>`,
    })))),
  {
    name: "card-small", family: "card", title: "Small card", category: "data-display",
    renderReact: () => <Card size="sm"><CardContent>Compact content</CardContent></Card>,
    heex: `<.card size="sm"><.card_content>Compact content</.card_content></.card>`,
  },
  {
    name: "input-invalid-disabled", family: "input", title: "Invalid disabled native input", category: "forms",
    renderReact: () => <Input id="disabled-input" name="email" type="email" defaultValue="onni@example.test" disabled aria-invalid className="w-72" />,
    heex: `<.input id="disabled-input" name="email" type="email" value="onni@example.test" disabled aria-invalid="true" class="w-72" />`,
  },
  {
    name: "textarea-native-form", family: "textarea", title: "Named readonly textarea", category: "forms",
    renderReact: () => <Textarea id="notes" name="notes" readOnly rows={3} defaultValue="Saved notes" />,
    heex: `<.textarea id="notes" name="notes" readonly rows="3">Saved notes</.textarea>`,
  },
]
