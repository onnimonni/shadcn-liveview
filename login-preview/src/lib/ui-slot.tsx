import * as React from "react"
import { cn } from "cn"

// Static slots share class merging and prop forwarding, not their HTML semantics.
export function createUiSlot<Tag extends "div" | "nav" | "ol" | "li" | "span">(
  tag: Tag,
  slot: string,
  classes = "",
  defaults?: React.ComponentProps<Tag>
) {
  function UiSlot({ className, ...props }: React.ComponentProps<Tag>) {
    return React.createElement(tag, {
      "data-slot": slot,
      ...defaults,
      className: cn(classes, className),
      ...props,
    })
  }

  UiSlot.displayName = slot
  return UiSlot
}
