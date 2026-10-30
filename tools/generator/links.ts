// LiveView navigation for anchor-like components: `navigate`/`patch` render
// Phoenix.Component.link/1 with the same attributes; otherwise the native element is unchanged.

export const linkAttrs = [
  `  attr :navigate, :string, default: nil, doc: "LiveView \`navigate\` destination; renders \`Phoenix.Component.link/1\` with the same attributes."`,
  `  attr :patch, :string, default: nil, doc: "LiveView \`patch\` destination; renders \`Phoenix.Component.link/1\` with the same attributes."`,
  `  attr :replace, :boolean, default: false, doc: "Replaces the browser history entry for \`navigate\` and \`patch\` links."`,
]

export interface LinkModeElement {
  // Native opening tag name and closing tag, e.g. "a" or ".dynamic_tag tag_name={@tag}".
  open: string
  close: string
  // Everything between the tag name and `>`, starting with whitespace.
  attrs: string
  // Inner markup between the opening and closing tags.
  body: string
  // Extra Phoenix.Component.link/1 attrs and the matching condition; defaults to navigate/patch.
  linkAttrs?: string
  condition?: string
  indent?: string
}

export function linkOrElement({ open, close, attrs, body, linkAttrs: extra = "", condition = "@navigate || @patch", indent = "    " }: LinkModeElement): string {
  return `${indent}<.link :if={${condition}} navigate={@navigate} patch={@patch}${extra} replace={@replace}${attrs}>${body}</.link>
${indent}<${open} :if={!(${condition})}${attrs}>${body}</${close}>`
}
