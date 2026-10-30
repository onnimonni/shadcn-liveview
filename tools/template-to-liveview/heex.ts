// Minimal HEEx tree with a whitespace-faithful printer.

export type HAttr = { name: string; value?: string } // value: `"text"` or `{code}`; undefined = bare/spread

export type HNode =
  | { k: "el"; tag: string; attrs: HAttr[]; children: HNode[] }
  | { k: "text"; v: string }
  | { k: "expr"; code: string }
  | { k: "comment"; v: string }
  | { k: "if"; cond: string; then: HNode[]; else: HNode[] }
  | { k: "for"; gen: string; body: HNode[] }

export type HElement = Extract<HNode, { k: "el" }>

const voidTags: Record<string, true> = {
  area: true, base: true, br: true, col: true, embed: true, hr: true, img: true, input: true, link: true, meta: true,
  source: true, track: true, wbr: true,
}
const svgTags: Record<string, true> = {
  path: true, circle: true, rect: true, line: true, polyline: true, polygon: true, ellipse: true, use: true, stop: true,
}
// Elements whose surrounding whitespace is visible: siblings of these keep JSX's exact spacing.
const inlineTags: Record<string, true> = {
  a: true, abbr: true, b: true, bdi: true, br: true, button: true, cite: true, code: true, em: true, i: true, img: true,
  input: true, kbd: true, label: true, mark: true, q: true, s: true, samp: true, small: true, span: true, strong: true,
  sub: true, sup: true, svg: true, time: true, u: true, var: true, ".icon": true, ".template_icon": true, ".kbd": true,
  ".badge": true, "Input.input": true, ".link": true,
}

export function el(tag: string, attrs: HAttr[] = [], children: HNode[] = []): HElement {
  return { k: "el", tag, attrs, children }
}

export function quoteAttr(text: string): string {
  return text.includes('"') ? `{${JSON.stringify(text)}}` : `"${text}"`
}

export function escapeText(text: string): string {
  return text.replace(/\{/g, "&#123;").replace(/\}/g, "&#125;")
}

function attrsText(attrs: HAttr[]): string {
  return attrs.map(attr => (attr.value === undefined ? ` ${attr.name}` : ` ${attr.name}=${attr.value}`)).join("")
}

function isInlineContext(children: HNode[]): boolean {
  return children.some(child => child.k === "text" || child.k === "expr" || (child.k === "el" && inlineTags[child.tag]) ||
    ((child.k === "if" || child.k === "for") && isInlineContext(child.k === "if" ? [...child.then, ...child.else] : child.body)))
}

function printInline(nodes: HNode[]): string {
  return nodes.map(node => {
    switch (node.k) {
      case "text": return escapeText(node.v)
      case "expr": return `{${node.code}}`
      case "comment": return `<%!-- ${node.v} --%>`
      case "if": return `<%= if ${node.cond} do %>${printInline(node.then)}${node.else.length ? `<% else %>${printInline(node.else)}` : ""}<% end %>`
      case "for": return `<%= for ${node.gen} do %>${printInline(node.body)}<% end %>`
      case "el": {
        const open = `<${node.tag}${attrsText(node.attrs)}`
        if (!node.children.length) return selfClosing(node.tag) ? `${open} />` : `${open}></${node.tag}>`
        return `${open}>${printInline(node.children)}</${node.tag}>`
      }
    }
  }).join("")
}

function selfClosing(tag: string): boolean {
  return !!voidTags[tag] || !!svgTags[tag] || tag.startsWith(".") || /^[A-Z]/.test(tag) || tag.startsWith(":")
}

export function printNodes(nodes: HNode[], indent: number): string {
  if (isInlineContext(nodes)) return " ".repeat(indent) + printInline(nodes)
  return nodes.map(node => printBlock(node, indent)).join("\n")
}

function printBlock(node: HNode, indent: number): string {
  const pad = " ".repeat(indent)
  switch (node.k) {
    case "text":
    case "expr":
      return pad + printInline([node])
    case "comment":
      return `${pad}<%!-- ${node.v} --%>`
    case "if": {
      const lines = [`${pad}<%= if ${node.cond} do %>`, printNodes(node.then, indent + 2)]
      if (node.else.length) lines.push(`${pad}<% else %>`, printNodes(node.else, indent + 2))
      lines.push(`${pad}<% end %>`)
      return lines.join("\n")
    }
    case "for":
      return [`${pad}<%= for ${node.gen} do %>`, printNodes(node.body, indent + 2), `${pad}<% end %>`].join("\n")
    case "el": {
      const open = `${pad}<${node.tag}${attrsText(node.attrs)}`
      if (!node.children.length) return selfClosing(node.tag) ? `${open} />` : `${open}></${node.tag}>`
      if (isInlineContext(node.children)) return `${open}>${printInline(node.children)}</${node.tag}>`
      return `${open}>\n${printNodes(node.children, indent + 2)}\n${pad}</${node.tag}>`
    }
  }
}
