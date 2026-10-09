export function resolveHtmlTag(origName: string, rawTag: string): string {
  const lowerName = origName.toLowerCase()
  const lowerTag = rawTag.toLowerCase()

  const passthrough: Record<string, true> = {
    dialog: true,
    alertdialog: true,
    sheet: true,
    drawer: true,
    popover: true,
    tooltip: true,
    tooltipprovider: true,
    hovercard: true,
    contextmenu: true,
    dropdownmenu: true,
    directionprovider: true,
    messagescrollerprovider: true,
  }
  if (passthrough[lowerName]) return "slot_only"
  if (lowerName === "inputgroupinput") return "input"
  if (lowerName === "inputgrouptextarea") return "textarea"

  if (lowerName.includes("group") || lowerName.includes("button_group") || lowerName.includes("buttongroup")) {
    return "div"
  }

  if (lowerName === "avatar") return "span"
  if (lowerName === "avatarimage") return "img"
  if (lowerName === "avatarfallback") return "span"
  if (lowerName === "spinner") return "svg"

  if (lowerName.includes("input") && !lowerName.includes("group") && !lowerName.includes("otp")) return "input"
  if (lowerName.includes("textarea")) return "textarea"
  if (lowerName.includes("label")) return "label"
  if (lowerName.includes("tableheader")) return "thead"
  if (lowerName.includes("tablebody")) return "tbody"
  if (lowerName.includes("tablerow")) return "tr"
  if (lowerName.includes("tablehead")) return "th"
  if (lowerName.includes("tablecell")) return "td"
  if (lowerName.includes("tablefooter")) return "tfoot"
  if (lowerName.includes("tablecaption")) return "caption"
  if (lowerName === "table") return "table"
  if (lowerName === "kbd") return "kbd"
  if (lowerName === "breadcrumb") return "nav"
  if (lowerName === "breadcrumblist") return "ol"
  if (lowerName.includes("breadcrumbitem") || lowerName.includes("breadcrumbseparator")) return "li"
  if (lowerName.includes("link") && !lowerName.includes("input")) return "a"
  if (lowerName.includes("breadcrumbpage") || lowerName.includes("badge")) return "span"
  if (lowerName.includes("navigationmenulist") || lowerName.includes("navigation_menu_list")) return "ul"
  if (lowerName.includes("navigationmenuitem") || lowerName.includes("navigation_menu_item")) return "li"
  if (lowerName.includes("paginationcontent") || lowerName.includes("pagination_content")) return "ul"
  if (lowerName.includes("paginationitem") || lowerName.includes("pagination_item")) return "li"
  if (lowerName === "questionnaireitem" || lowerName === "questionnaire_item") return "fieldset"
  if (lowerName.includes("card") || lowerName === "alert" || lowerName === "alerttitle" || lowerName === "alertdescription" || lowerName.includes("itemtitle") || lowerName.includes("item_title")) return "div"
  if (lowerName === "emptytitle" || lowerName === "emptydescription") return "div"
  if (lowerName === "attachmenttitle" || lowerName === "attachmentdescription") return "span"
  if (lowerName.endsWith("title")) return "h2"
  if (lowerName.endsWith("description")) return "p"
  if (
    lowerName.includes("trigger") ||
    lowerName === "button" ||
    lowerName.endsWith("_button") ||
    lowerName.includes("action") ||
    lowerName.includes("cancel") ||
    lowerName.includes("close") ||
    lowerName === "toggle"
  ) {
    return "button"
  }
  if (lowerTag === "span" || lowerTag === "a" || lowerTag === "nav" || lowerTag === "ol" || lowerTag === "li") {
    return lowerTag
  }
  return "div"
}
