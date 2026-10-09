const spacious = new Set(["dialog", "alert-dialog", "drawer", "sheet"])
const popups = new Set(["popover", "hover-card", "tooltip", "select", "dropdown-menu", "context-menu", "menubar", "navigation-menu", "combobox", "sonner"])

export function fixtureMinHeight(family) {
  return spacious.has(family) ? 480 : popups.has(family) ? 320 : family === "sidebar" ? 640 : 120
}
