import fs from "node:fs/promises"
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import * as Lucide from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { defaultTreeAdapter, parseFragment, serialize } from "parse5"
import ts from "typescript"

const normalize = (name: string) => name.replace(/Icon$/, "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([a-zA-Z])([0-9])/g, "$1-$2").toLowerCase()

/** Generate geometry AND alias classes from pinned upstream components. */
export async function generateIcons(): Promise<void> {
  const names = new Set([
    "arrow-down", "arrow-left", "arrow-right", "arrow-up", "check", "chevron-down",
    "chevron-left", "chevron-right", "chevron-up", "circle", "grip-vertical",
    "loader-circle", "minus", "more-horizontal", "panel-left", "search", "x",
  ])
  for (const file of await fs.readdir("vendor/shadcn/ui")) {
    if (!file.endsWith(".tsx")) continue
    const source = ts.createSourceFile(file, await fs.readFile(`vendor/shadcn/ui/${file}`, "utf8"), ts.ScriptTarget.Latest, true)
    function visit(node: ts.Node): void {
      if (ts.isJsxAttribute(node) && node.name.getText(source) === "lucide" && node.initializer && ts.isStringLiteral(node.initializer)) {
        names.add(normalize(node.initializer.text))
      }
      ts.forEachChild(node, visit)
    }
    visit(source)
  }
  const clauses: string[] = []
  const classes: string[] = []
  for (const name of [...names].sort()) {
    const exportName = name.split("-").map(part => part[0].toUpperCase() + part.slice(1)).join("")
    const component = Reflect.get(Lucide, exportName) as LucideIcon | undefined
    if (!component) throw new Error(`Unknown vendored Lucide icon: ${exportName}`)
    const svg = parseFragment(renderToStaticMarkup(createElement(component))).childNodes[0]
    if (!defaultTreeAdapter.isElementNode(svg)) throw new Error(`Invalid Lucide SVG: ${exportName}`)
    const geometry = serialize(svg)
    const className = svg.attrs.find(attr => attr.name === "class")!.value
    classes.push(`    ${JSON.stringify(name)} => ${JSON.stringify(className)}`)
    clauses.push(`  defp icon_body(%{name: "${name}"} = assigns) do\n    ~H"""\n    ${geometry}\n    """\n  end`)
  }
  await fs.writeFile("lib/shadcn_liveview/components/icon.ex", `defmodule ShadcnLiveview.Components.Icon do
  @moduledoc """
  Lucide icons used by the vendored components, generated from pinned upstream geometry.
  Names accept Lucide PascalCase or kebab-case. Unknown names raise instead of rendering a substitute.
  """
  use Phoenix.Component

  @icon_classes %{
${classes.join(",\n")}
  }

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
    name = icon_name(assigns.name)
    assigns = assign(assigns, icon_name: name, icon_classes: Map.fetch!(@icon_classes, name))
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
      fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
      class={[@icon_classes, @class]} aria-hidden="true" {@rest}>
      <.icon_body name={@icon_name} />
    </svg>
    """
  end

  defp icon_name(name) do
    name |> Macro.underscore() |> String.replace("_", "-") |> String.replace_suffix("-icon", "")
    |> String.replace(~r/([a-z])([0-9])/, "\\\\1-\\\\2")
  end

${clauses.join("\n\n")}

  defp icon_body(%{name: name}) do
    raise ArgumentError, "Unknown Lucide icon: #{inspect(name)}"
  end
end
`, "utf8")
}
