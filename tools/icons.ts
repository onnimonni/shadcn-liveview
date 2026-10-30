import fs from "node:fs/promises"
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import * as Lucide from "lucide-react"
import type { LucideIcon } from "lucide-react"
import { defaultTreeAdapter, parseFragment, serialize } from "parse5"
import ts from "typescript"

const normalize = (name: string) => name.replace(/Icon$/, "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([a-zA-Z])([0-9])/g, "$1-$2").toLowerCase()

/** Icons rendered by the generated components outside of vendored `lucide="..."` attributes. */
const COMPONENT_ICONS = [
  "arrow-down", "arrow-left", "arrow-right", "arrow-up", "check", "chevron-down",
  "chevron-left", "chevron-right", "chevron-up", "circle", "grip-vertical",
  "loader-circle", "minus", "more-horizontal", "panel-left", "search", "x",
]

/** Curated Lucide icons commonly needed by app screens (navigation, CRUD, auth, status, media). */
const APP_ICONS = [
  "archive", "arrow-up-down", "arrow-up-right", "at-sign", "bell", "bookmark", "briefcase",
  "building", "calendar", "chart-bar", "chart-column", "chart-line", "chart-pie",
  "chevrons-left", "chevrons-right", "chevrons-up-down", "circle-alert", "circle-check",
  "circle-dot", "circle-help", "circle-plus", "circle-user", "circle-x", "clock", "columns-3", "copy",
  "credit-card", "dollar-sign", "download", "ellipsis", "ellipsis-vertical", "external-link",
  "eye", "eye-off", "file-text", "filter", "flag", "folder", "globe", "hash", "heart",
  "history", "house", "image", "inbox", "info", "key", "layout-dashboard", "link", "list",
  "list-todo", "loader", "lock", "log-in", "log-out", "mail", "map-pin", "menu",
  "message-square", "monitor", "moon", "paperclip", "pause", "pencil", "phone", "pin", "play",
  "plus", "printer", "refresh-cw", "rotate-ccw", "save", "send", "settings", "share-2",
  "shield", "shopping-bag", "shopping-cart", "sliders-horizontal", "smartphone", "sparkles",
  "square-pen", "star", "sun", "tag", "thumbs-down", "thumbs-up", "trash-2",
  "trending-down", "trending-up", "triangle-alert", "upload", "user", "user-plus", "users", "zap",
]

/** `icon_name/1` in the generated module inserts a hyphen between a letter and a digit. */
const reachable = (name: string) => !/[a-z][0-9]/.test(name)

type IconEntry = { canonical: string, className: string, geometry: string, aliases: Set<string> }

/** Generate geometry AND alias classes from pinned upstream components. */
export async function generateIcons(): Promise<void> {
  const names = new Set([...COMPONENT_ICONS, ...APP_ICONS])
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
  const { version } = JSON.parse(await fs.readFile("node_modules/lucide-react/package.json", "utf8")) as { version: string }

  // Lucide aliases (Home/House, Trash2/Trash, ...) are the same component: emit one clause per
  // component under its canonical name and resolve every Lucide alias to it.
  const entries = new Map<LucideIcon, IconEntry>()
  for (const name of [...names].sort()) {
    if (!reachable(name)) throw new Error(`Lucide icon name ${name} cannot be reached through icon_name/1 normalization`)
    const exportName = name.split("-").map(part => part[0].toUpperCase() + part.slice(1)).join("")
    const component = Reflect.get(Lucide, exportName) as LucideIcon | undefined
    if (!component) throw new Error(`Unknown vendored Lucide icon: ${exportName}`)
    const existing = entries.get(component)
    if (existing) {
      existing.aliases.add(name)
      continue
    }
    const svg = parseFragment(renderToStaticMarkup(createElement(component))).childNodes[0]
    if (!defaultTreeAdapter.isElementNode(svg)) throw new Error(`Invalid Lucide SVG: ${exportName}`)
    const className = svg.attrs.find(attr => attr.name === "class")!.value
    const [canonical, ...lucideAliases] = className.split(" ").filter(token => token !== "lucide").map(token => token.replace(/^lucide-/, ""))
    if (!reachable(canonical)) throw new Error(`Canonical Lucide icon name ${canonical} cannot be reached through icon_name/1 normalization`)
    entries.set(component, {
      canonical,
      className,
      geometry: serialize(svg),
      aliases: new Set([name, ...lucideAliases.filter(reachable)]),
    })
  }

  const icons = [...entries.values()].sort((a, b) => a.canonical.localeCompare(b.canonical))
  const owners = new Map<string, string>()
  for (const icon of icons) {
    icon.aliases.delete(icon.canonical)
    for (const name of [icon.canonical, ...icon.aliases]) {
      const owner = owners.get(name)
      if (owner && owner !== icon.canonical) throw new Error(`Lucide icon name ${name} resolves to both ${owner} and ${icon.canonical}`)
      owners.set(name, icon.canonical)
    }
  }

  const classes = icons.map(icon => `    ${JSON.stringify(icon.canonical)} => ${JSON.stringify(icon.className)}`)
  const aliases = icons.flatMap(icon => [...icon.aliases].sort().map(alias => `    ${JSON.stringify(alias)} => ${JSON.stringify(icon.canonical)}`))
  const docList = icons.map(icon => {
    const also = [...icon.aliases].sort().map(alias => `\`${alias}\``).join(", ")
    return `  * \`${icon.canonical}\`${also ? ` (also ${also})` : ""}`
  })
  const clauses = icons.map(icon => `  defp icon_body(%{name: "${icon.canonical}"} = assigns) do\n    ~H"""\n    ${icon.geometry}\n    """\n  end`)

  await fs.writeFile("lib/shadcn_liveview/components/icon.ex", `defmodule ShadcnLiveview.Components.Icon do
  @moduledoc """
  A curated subset of Lucide icons: the ones the vendored components render plus common
  app icons (navigation, CRUD actions, auth, status, media). Geometry and classes are
  generated from the pinned \`lucide-react\` ${version} package, so markup matches React.

  See \`icon/1\` for every supported name. Names starting with \`hero-\` render like Phoenix
  1.8 \`CoreComponents.icon/1\`, so this module can replace that function. Other unknown
  names raise \`ArgumentError\` instead of rendering a substitute.
  """
  use Phoenix.Component

  @issues_url "https://github.com/onnimonni/shadcn-liveview/issues"

  @icon_classes %{
${classes.join(",\n")}
  }

  @icon_aliases %{
${aliases.join(",\n")}
  }

  @icon_names @icon_classes |> Map.keys() |> Enum.sort()

  @doc """
  Renders a Lucide icon as an inline \`<svg>\` with \`aria-hidden="true"\`, or a Heroicon
  when \`name\` starts with \`hero-\`.

  \`name\` accepts Lucide kebab-case (\`"trash-2"\`) or PascalCase (\`"Trash2"\`, \`"Trash2Icon"\`)
  and any Lucide alias listed below. \`class\` is appended to the Lucide classes; other
  attributes are passed to the \`<svg>\`.

      <.icon name="plus" class="size-4" />

  ## Heroicons

  \`hero-*\` names render exactly like Phoenix 1.8 \`CoreComponents.icon/1\`:
  \`<span class={[@name, @class]} />\`, with \`class\` defaulting to \`"size-4"\`. The CSS comes
  from the Heroicons Tailwind plugin that \`mix phx.new\` installs
  (\`assets/vendor/heroicons.js\`), so \`phx.new\` templates keep working after
  \`import MyAppWeb.CoreComponents, except: [icon: 1]\`.

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />

  ## Supported names

${docList.join("\n")}

  Any other name raises \`ArgumentError\`. To request another Lucide icon, open an issue at
  https://github.com/onnimonni/shadcn-liveview/issues (contributors: add the name to
  \`APP_ICONS\` in \`tools/icons.ts\` and run \`bun run generate\`). For a one-off icon,
  render your own inline \`<svg>\`.
  """
  attr :name, :string,
    required: true,
    doc: "Lucide icon name (see the supported list above) or a \`hero-*\` Heroicon name."

  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class || "size-4"]} {@rest} />
    """
  end

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
    normalized =
      name |> Macro.underscore() |> String.replace("_", "-") |> String.replace_suffix("-icon", "")
      |> String.replace(~r/([a-z])([0-9])/, "\\\\1-\\\\2")

    canonical = Map.get(@icon_aliases, normalized, normalized)

    if Map.has_key?(@icon_classes, canonical) do
      canonical
    else
      raise ArgumentError, """
      unknown Lucide icon #{inspect(name)} (normalized to #{inspect(normalized)}).

      ShadcnLiveview.Components.Icon bundles a curated Lucide subset; see the icon/1 docs for
      aliases. Supported names: #{Enum.join(@icon_names, ", ")}

      To request another icon, open an issue at #{@issues_url}
      (contributors: add it to APP_ICONS in tools/icons.ts and run \`bun run generate\`).
      For a one-off icon, render your own inline <svg>.
      """
    end
  end

${clauses.join("\n\n")}
end
`, "utf8")
}
