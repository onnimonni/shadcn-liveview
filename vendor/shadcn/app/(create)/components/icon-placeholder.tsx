import * as React from "react"
import * as LucideIcons from "lucide-react"

type IconComponentType = React.ComponentType<{ className?: string }>

export function IconPlaceholder({
  lucide,
  className,
  ...props
}: {
  lucide?: string
  className?: string
  [key: string]: unknown
}) {
  if (!lucide) return null
  const icons = LucideIcons as unknown as Record<string, IconComponentType | undefined>
  const IconComponent =
    icons[lucide] ||
    icons[lucide.replace(/Icon$/, "")] ||
    icons[lucide + "Icon"]
  if (!IconComponent) return null
  return <IconComponent className={className} {...(props as Record<string, unknown>)} />
}
