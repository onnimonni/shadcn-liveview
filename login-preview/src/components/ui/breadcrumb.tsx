import * as React from "react"
import { cn } from "cn"
import { Slot } from "radix-ui"
import { ChevronRightIcon, MoreHorizontalIcon } from "lucide-react"
import { createUiSlot } from "../../lib/ui-slot"

const Breadcrumb = createUiSlot("nav", "breadcrumb", "", {
  "aria-label": "breadcrumb",
})

const BreadcrumbList = createUiSlot(
  "ol",
  "breadcrumb-list",
  "flex flex-wrap items-center gap-1.5 text-sm wrap-break-word text-muted-foreground"
)

const BreadcrumbItem = createUiSlot(
  "li",
  "breadcrumb-item",
  "inline-flex items-center gap-1"
)

function BreadcrumbLink({
  asChild,
  className,
  ...props
}: React.ComponentProps<"a"> & {
  asChild?: boolean
}) {
  const Comp = asChild ? Slot.Root : "a"

  return (
    <Comp
      data-slot="breadcrumb-link"
      className={cn("transition-colors hover:text-foreground", className)}
      {...props}
    />
  )
}

const BreadcrumbPage = createUiSlot(
  "span",
  "breadcrumb-page",
  "font-normal text-foreground",
  { "aria-current": "page" }
)

function BreadcrumbSeparator({
  children,
  className,
  ...props
}: React.ComponentProps<"li">) {
  return (
    <li
      data-slot="breadcrumb-separator"
      role="presentation"
      aria-hidden="true"
      className={cn("[&>svg]:size-3.5", className)}
      {...props}
    >
      {children ?? (
        <ChevronRightIcon />
      )}
    </li>
  )
}

function BreadcrumbEllipsis({
  className,
  ...props
}: React.ComponentProps<"span">) {
  return (
    <span
      data-slot="breadcrumb-ellipsis"
      role="presentation"
      aria-hidden="true"
      className={cn(
        "flex size-5 items-center justify-center [&>svg]:size-4",
        className
      )}
      {...props}
    >
      <MoreHorizontalIcon
      />
      <span className="sr-only">More</span>
    </span>
  )
}

export {
  Breadcrumb,
  BreadcrumbList,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbPage,
  BreadcrumbSeparator,
  BreadcrumbEllipsis,
}
