// Radix portals popup content to <body>, so it escapes ancestor stacking contexts
// (`relative z-0` table rows), overflow clipping and transformed containing blocks
// (drawers). Phoenix keeps the content inline for patching, so hooks promote the
// positioned element into the browser top layer with a manual popover instead.
// `ignoreAttributes` keeps the client-owned `popover` and positioning `style`
// across server patches without moving the element out of LiveView's tree.
//
// `bare` elements are unstyled positioning wrappers: neutralize the UA popover box
// (Canvas background, border, padding, centered margin, scroll clipping of the
// content's shadow). Styled popups keep their own classes, which already override
// the UA defaults, and only lose the UA inset.
export function topLayerMethod(indent: string): string {
  return [
    "promoteToTopLayer(el, bare) {",
    "  if (!el || typeof el.showPopover !== \"function\") return;",
    "  if (!el.hasAttribute(\"popover\")) {",
    "    this.js().ignoreAttributes(el, [\"popover\", \"style\"]);",
    "    el.setAttribute(\"popover\", \"manual\");",
    "    Object.assign(el.style, {inset: \"auto\", margin: \"0\"});",
    "    if (bare) Object.assign(el.style, {border: \"0\", padding: \"0\", overflow: \"visible\", background: \"transparent\", color: \"inherit\"});",
    "  }",
    "  if (!el.matches(\":popover-open\")) el.showPopover();",
    "},",
  ].map(line => indent + line).join("\n")
}
