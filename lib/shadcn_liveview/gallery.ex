defmodule ShadcnLiveview.Gallery do
  @moduledoc false
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  def names,
    do: [
      "accordion",
      "accordion-closed",
      "accordion-selected-details",
      "accordion-multiple",
      "accordion-disabled",
      "accordion-force-mount",
      "accordion-instances",
      "tabs",
      "tabs-history",
      "tabs-unselected",
      "tabs-disabled",
      "tabs-line-rtl",
      "tabs-force-mount",
      "tabs-instances",
      "dialog",
      "dialog-closed",
      "dialog-open-custom-ids",
      "dialog-no-close-icon-footer-close",
      "dialog-nonmodal",
      "dialog-multiple-instances",
      "alert-dialog",
      "alert-dialog-closed",
      "alert-dialog-open-custom-ids",
      "alert-dialog-small-media",
      "alert-dialog-multiple-instances",
      "drawer",
      "drawer-closed",
      "drawer-open-custom-ids",
      "drawer-top",
      "drawer-left",
      "drawer-right",
      "drawer-nondismissible",
      "drawer-select",
      "drawer-multiple-instances",
      "sheet",
      "sheet-closed",
      "sheet-open-custom-ids",
      "sheet-top",
      "sheet-bottom",
      "sheet-left",
      "sheet-multiple-instances",
      "context-menu",
      "context-menu-disabled",
      "context-menu-multiple",
      "dropdown-menu",
      "dropdown-menu-closed-disabled",
      "dropdown-menu-items",
      "dropdown-menu-checks",
      "hover-card",
      "hover-card-disabled",
      "hover-card-closed",
      "hover-card-multiple",
      "popover",
      "popover-closed",
      "popover-multiple-disabled",
      "select",
      "select-value-disabled",
      "select-closed-multiple",
      "select-popper",
      "select-groups",
      "tooltip",
      "tooltip-closed-disabled",
      "tooltip-multiple",
      "combobox",
      "combobox-empty",
      "combobox-value",
      "combobox-disabled",
      "combobox-multiple-instances",
      "command",
      "command-empty",
      "command-values-disabled",
      "command-multiple-instances",
      "input-otp",
      "input-otp-partial-value",
      "input-otp-separated",
      "input-otp-disabled",
      "input-otp-validation",
      "input-otp-multiple-instances",
      "calendar",
      "calendar-leap-selection",
      "calendar-common-february",
      "calendar-bounded-range",
      "calendar-british-week",
      "calendar-fixed-multiple",
      "calendar-year-boundary",
      "calendar-independent-instances",
      "carousel",
      "carousel-vertical",
      "carousel-multiple",
      "resizable",
      "resizable-vertical",
      "resizable-multiple",
      "sidebar",
      "sidebar-collapsed-icon",
      "sidebar-collapsed-offcanvas",
      "sidebar-multiple",
      "sidebar-menu-popup",
      "chart",
      "chart-config-theme",
      "chart-label-only",
      "chart-empty-config",
      "chart-bar-series",
      "chart-line-custom-dimensions",
      "chart-area-gaps",
      "chart-empty-data",
      "chart-tooltip",
      "chart-tooltip-line",
      "chart-tooltip-hidden",
      "chart-tooltip-inactive",
      "chart-tooltip-dashed",
      "chart-empty-payload",
      "chart-legend",
      "chart-multiple-instances",
      "chart-area-interactive",
      "message-scroller",
      "message-scroller-start",
      "message-scroller-end",
      "message-scroller-last-anchor",
      "message-scroller-empty",
      "message-scroller-multiple",
      "questionnaire",
      "questionnaire-flow",
      "questionnaire-current-last",
      "questionnaire-invalid-multiple",
      "questionnaire-empty",
      "questionnaire-multiple",
      "questionnaire-selected-choice",
      "message-scroller-default-button",
      "questionnaire-input-states",
      "radio-group",
      "radio-group-required-vertical",
      "radio-group-controlled",
      "radio-group-disabled-external-form",
      "radio-group-multiple-instances",
      "toggle-group",
      "toggle-group-single-vertical",
      "toggle-group-multiple-default",
      "toggle-group-controlled",
      "toggle-group-disabled",
      "toggle-group-multiple-instances",
      "menubar",
      "menubar-default-open",
      "menubar-controlled",
      "menubar-check-radio-submenu",
      "menubar-multiple-disabled",
      "menubar-submenu-open",
      "menubar-explicit-relations",
      "checkbox",
      "checkbox-false-enabled",
      "checkbox-false-disabled",
      "checkbox-true-enabled",
      "checkbox-true-disabled",
      "checkbox-indeterminate-enabled",
      "checkbox-indeterminate-disabled",
      "checkbox-multiple-external-form",
      "switch",
      "switch-default-false-enabled",
      "switch-default-false-disabled",
      "switch-default-true-enabled",
      "switch-default-true-disabled",
      "switch-sm-false-enabled",
      "switch-sm-false-disabled",
      "switch-sm-true-enabled",
      "switch-sm-true-disabled",
      "switch-multiple-external-form",
      "slider",
      "slider-lower-bound",
      "slider-upper-bound",
      "slider-range",
      "slider-three-thumbs",
      "slider-vertical",
      "slider-rtl",
      "slider-inverted",
      "slider-disabled",
      "slider-default-extents",
      "slider-multiple-instances",
      "slider-external-form",
      "slider-minimum-thumb-distance",
      "collapsible",
      "collapsible-closed-enabled",
      "collapsible-closed-disabled",
      "collapsible-open-enabled",
      "collapsible-open-disabled",
      "collapsible-force-mount",
      "collapsible-multiple-instances",
      "navigation-menu",
      "navigation-inline-closed",
      "navigation-inline-docs",
      "navigation-inline-about",
      "navigation-viewport-closed",
      "navigation-viewport-docs",
      "navigation-viewport-about",
      "navigation-vertical-rtl-disabled",
      "navigation-force-mount",
      "navigation-multiple-instances",
      "navigation-indicator",
      "button-default-default",
      "button-default-xs",
      "button-default-sm",
      "button-default-lg",
      "button-default-icon",
      "button-default-icon-xs",
      "button-default-icon-sm",
      "button-default-icon-lg",
      "button-outline-default",
      "button-outline-xs",
      "button-outline-sm",
      "button-outline-lg",
      "button-outline-icon",
      "button-outline-icon-xs",
      "button-outline-icon-sm",
      "button-outline-icon-lg",
      "button-secondary-default",
      "button-secondary-xs",
      "button-secondary-sm",
      "button-secondary-lg",
      "button-secondary-icon",
      "button-secondary-icon-xs",
      "button-secondary-icon-sm",
      "button-secondary-icon-lg",
      "button-ghost-default",
      "button-ghost-xs",
      "button-ghost-sm",
      "button-ghost-lg",
      "button-ghost-icon",
      "button-ghost-icon-xs",
      "button-ghost-icon-sm",
      "button-ghost-icon-lg",
      "button-destructive-default",
      "button-destructive-xs",
      "button-destructive-sm",
      "button-destructive-lg",
      "button-destructive-icon",
      "button-destructive-icon-xs",
      "button-destructive-icon-sm",
      "button-destructive-icon-lg",
      "button-link-default",
      "button-link-xs",
      "button-link-sm",
      "button-link-lg",
      "button-link-icon",
      "button-link-icon-xs",
      "button-link-icon-sm",
      "button-link-icon-lg",
      "badge-default",
      "badge-secondary",
      "badge-destructive",
      "badge-outline",
      "badge-ghost",
      "badge-link",
      "toggle-default-default-off",
      "toggle-default-default-on",
      "toggle-default-sm-off",
      "toggle-default-sm-on",
      "toggle-default-lg-off",
      "toggle-default-lg-on",
      "toggle-outline-default-off",
      "toggle-outline-default-on",
      "toggle-outline-sm-off",
      "toggle-outline-sm-on",
      "toggle-outline-lg-off",
      "toggle-outline-lg-on",
      "card-small",
      "input-invalid-disabled",
      "textarea-native-form",
      "alert",
      "aspect-ratio",
      "attachment",
      "avatar",
      "badge",
      "breadcrumb",
      "bubble",
      "button-group",
      "button",
      "card",
      "direction",
      "empty",
      "field",
      "field-separator",
      "input-group",
      "input",
      "item",
      "kbd",
      "label",
      "marker",
      "message",
      "native-select",
      "native-select-default-selection",
      "native-select-controlled-small",
      "native-select-disabled-groups",
      "native-select-multiple-instances",
      "native-select-empty-controlled",
      "native-select-controlled-multiple",
      "native-select-external-form-empty-multiple",
      "pagination",
      "progress",
      "progress-absent",
      "progress-null",
      "progress-zero",
      "progress-fractional",
      "progress-complete",
      "progress-custom-max",
      "progress-null-max",
      "progress-outside-visual-range",
      "progress-custom-class-aria",
      "scroll-area",
      "separator",
      "skeleton",
      "sonner",
      "spinner",
      "table",
      "textarea",
      "toggle"
    ]

  def entries,
    do: [
      %{name: "accordion", title: "Accordion", category: "data-display", family: "accordion"},
      %{
        name: "accordion-closed",
        title: "Accordion — initially closed",
        category: "data-display",
        family: "accordion"
      },
      %{
        name: "accordion-selected-details",
        title: "Accordion — controlled different selection",
        category: "data-display",
        family: "accordion"
      },
      %{
        name: "accordion-multiple",
        title: "Accordion — multiple open",
        category: "data-display",
        family: "accordion"
      },
      %{
        name: "accordion-disabled",
        title: "Accordion — disabled items",
        category: "data-display",
        family: "accordion"
      },
      %{
        name: "accordion-force-mount",
        title: "Accordion — retained closed content",
        category: "data-display",
        family: "accordion"
      },
      %{
        name: "accordion-instances",
        title: "Accordion — independent instances",
        category: "data-display",
        family: "accordion"
      },
      %{name: "tabs", title: "Tabs", category: "navigation", family: "tabs"},
      %{
        name: "tabs-history",
        title: "Tabs — controlled non-account selection",
        category: "navigation",
        family: "tabs"
      },
      %{
        name: "tabs-unselected",
        title: "Tabs — initially unselected",
        category: "navigation",
        family: "tabs"
      },
      %{
        name: "tabs-disabled",
        title: "Tabs — disabled and manual activation",
        category: "navigation",
        family: "tabs"
      },
      %{
        name: "tabs-line-rtl",
        title: "Tabs — line variant, visual vertical and RTL",
        category: "navigation",
        family: "tabs"
      },
      %{
        name: "tabs-force-mount",
        title: "Tabs — retained inactive content",
        category: "navigation",
        family: "tabs"
      },
      %{
        name: "tabs-instances",
        title: "Tabs — independent instances",
        category: "navigation",
        family: "tabs"
      },
      %{name: "dialog", title: "Dialog", category: "overlay", family: "dialog"},
      %{name: "dialog-closed", title: "Dialog closed", category: "overlay", family: "dialog"},
      %{
        name: "dialog-open-custom-ids",
        title: "Dialog open-custom-ids",
        category: "overlay",
        family: "dialog"
      },
      %{
        name: "dialog-no-close-icon-footer-close",
        title: "Dialog no-close-icon-footer-close",
        category: "overlay",
        family: "dialog"
      },
      %{name: "dialog-nonmodal", title: "Dialog nonmodal", category: "overlay", family: "dialog"},
      %{
        name: "dialog-multiple-instances",
        title: "dialog Multiple Instances",
        category: "overlay",
        family: "dialog"
      },
      %{name: "alert-dialog", title: "Alert Dialog", category: "overlay", family: "alert-dialog"},
      %{
        name: "alert-dialog-closed",
        title: "Alert Dialog closed",
        category: "overlay",
        family: "alert-dialog"
      },
      %{
        name: "alert-dialog-open-custom-ids",
        title: "Alert Dialog open-custom-ids",
        category: "overlay",
        family: "alert-dialog"
      },
      %{
        name: "alert-dialog-small-media",
        title: "Alert Dialog small-media",
        category: "overlay",
        family: "alert-dialog"
      },
      %{
        name: "alert-dialog-multiple-instances",
        title: "alert-dialog Multiple Instances",
        category: "overlay",
        family: "alert-dialog"
      },
      %{name: "drawer", title: "Drawer", category: "overlay", family: "drawer"},
      %{name: "drawer-closed", title: "Drawer closed", category: "overlay", family: "drawer"},
      %{
        name: "drawer-open-custom-ids",
        title: "Drawer open-custom-ids",
        category: "overlay",
        family: "drawer"
      },
      %{name: "drawer-top", title: "Drawer top", category: "overlay", family: "drawer"},
      %{name: "drawer-left", title: "Drawer left", category: "overlay", family: "drawer"},
      %{name: "drawer-right", title: "Drawer right", category: "overlay", family: "drawer"},
      %{
        name: "drawer-nondismissible",
        title: "Drawer nondismissible",
        category: "overlay",
        family: "drawer"
      },
      %{name: "drawer-select", title: "Drawer select", category: "overlay", family: "drawer"},
      %{
        name: "drawer-multiple-instances",
        title: "drawer Multiple Instances",
        category: "overlay",
        family: "drawer"
      },
      %{name: "sheet", title: "Sheet", category: "overlay", family: "sheet"},
      %{name: "sheet-closed", title: "Sheet closed", category: "overlay", family: "sheet"},
      %{
        name: "sheet-open-custom-ids",
        title: "Sheet open-custom-ids",
        category: "overlay",
        family: "sheet"
      },
      %{name: "sheet-top", title: "Sheet top", category: "overlay", family: "sheet"},
      %{name: "sheet-bottom", title: "Sheet bottom", category: "overlay", family: "sheet"},
      %{name: "sheet-left", title: "Sheet left", category: "overlay", family: "sheet"},
      %{
        name: "sheet-multiple-instances",
        title: "sheet Multiple Instances",
        category: "overlay",
        family: "sheet"
      },
      %{name: "context-menu", title: "Context Menu", category: "overlay", family: "context-menu"},
      %{
        name: "context-menu-disabled",
        title: "Disabled context surface",
        category: "overlay",
        family: "context-menu"
      },
      %{
        name: "context-menu-multiple",
        title: "Independent context surfaces",
        category: "overlay",
        family: "context-menu"
      },
      %{
        name: "dropdown-menu",
        title: "Dropdown Menu",
        category: "overlay",
        family: "dropdown-menu"
      },
      %{
        name: "dropdown-menu-closed-disabled",
        title: "Disabled closed dropdown",
        category: "overlay",
        family: "dropdown-menu"
      },
      %{
        name: "dropdown-menu-items",
        title: "Dropdown item states and independent instances",
        category: "overlay",
        family: "dropdown-menu"
      },
      %{
        name: "dropdown-menu-checks",
        title: "Checkbox and radio menu selection",
        category: "overlay",
        family: "dropdown-menu"
      },
      %{name: "hover-card", title: "Hover Card", category: "overlay", family: "hover-card"},
      %{
        name: "hover-card-disabled",
        title: "Disabled hover card trigger",
        category: "overlay",
        family: "hover-card"
      },
      %{
        name: "hover-card-closed",
        title: "Focus and hover disclosure",
        category: "overlay",
        family: "hover-card"
      },
      %{
        name: "hover-card-multiple",
        title: "Multiple hover cards and alternate placement",
        category: "overlay",
        family: "hover-card"
      },
      %{name: "popover", title: "Popover", category: "overlay", family: "popover"},
      %{
        name: "popover-closed",
        title: "Closed popover with editable content",
        category: "overlay",
        family: "popover"
      },
      %{
        name: "popover-multiple-disabled",
        title: "Independent disabled and open popovers",
        category: "overlay",
        family: "popover"
      },
      %{name: "select", title: "Select", category: "forms", family: "select"},
      %{
        name: "select-value-disabled",
        title: "Required form select with disabled option",
        category: "forms",
        family: "select"
      },
      %{
        name: "select-closed-multiple",
        title: "Closed small and disabled selects",
        category: "forms",
        family: "select"
      },
      %{
        name: "select-popper",
        title: "Popper select placement",
        category: "forms",
        family: "select"
      },
      %{
        name: "select-groups",
        title: "Labeled option groups",
        category: "forms",
        family: "select"
      },
      %{name: "tooltip", title: "Tooltip", category: "overlay", family: "tooltip"},
      %{
        name: "tooltip-closed-disabled",
        title: "Closed disabled tooltip",
        category: "overlay",
        family: "tooltip"
      },
      %{
        name: "tooltip-multiple",
        title: "Independent tooltip descriptions",
        category: "overlay",
        family: "tooltip"
      },
      %{name: "combobox", title: "Combobox", category: "forms", family: "combobox"},
      %{name: "combobox-empty", title: "Empty combobox", category: "forms", family: "combobox"},
      %{
        name: "combobox-value",
        title: "Combobox selected form value",
        category: "forms",
        family: "combobox"
      },
      %{
        name: "combobox-disabled",
        title: "Disabled combobox",
        category: "forms",
        family: "combobox"
      },
      %{
        name: "combobox-multiple-instances",
        title: "Independent comboboxes",
        category: "forms",
        family: "combobox"
      },
      %{name: "command", title: "Command", category: "forms", family: "command"},
      %{name: "command-empty", title: "Empty command list", category: "forms", family: "command"},
      %{
        name: "command-values-disabled",
        title: "Command values, shortcuts and disabled items",
        category: "forms",
        family: "command"
      },
      %{
        name: "command-multiple-instances",
        title: "Independent commands",
        category: "forms",
        family: "command"
      },
      %{name: "input-otp", title: "Input OTP", category: "forms", family: "input-otp"},
      %{
        name: "input-otp-partial-value",
        title: "OTP partially entered value",
        category: "forms",
        family: "input-otp"
      },
      %{
        name: "input-otp-separated",
        title: "OTP full value with separator",
        category: "forms",
        family: "input-otp"
      },
      %{
        name: "input-otp-disabled",
        title: "Disabled OTP",
        category: "forms",
        family: "input-otp"
      },
      %{
        name: "input-otp-validation",
        title: "OTP native form and validation attributes",
        category: "forms",
        family: "input-otp"
      },
      %{
        name: "input-otp-multiple-instances",
        title: "Independent OTP fields",
        category: "forms",
        family: "input-otp"
      },
      %{name: "calendar", title: "Calendar", category: "forms", family: "calendar"},
      %{
        name: "calendar-leap-selection",
        title: "Leap day selection",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-common-february",
        title: "Non-leap February",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-bounded-range",
        title: "Bounded selected range",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-british-week",
        title: "British locale and Monday weeks",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-fixed-multiple",
        title: "Fixed six weeks with disabled multiple dates",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-year-boundary",
        title: "Two months crossing a year boundary",
        category: "forms",
        family: "calendar"
      },
      %{
        name: "calendar-independent-instances",
        title: "Independent calendars",
        category: "forms",
        family: "calendar"
      },
      %{name: "carousel", title: "Carousel", category: "data-display", family: "carousel"},
      %{
        name: "carousel-vertical",
        title: "Vertical carousel",
        category: "data-display",
        family: "carousel"
      },
      %{
        name: "carousel-multiple",
        title: "Independent looping carousels",
        category: "data-display",
        family: "carousel"
      },
      %{name: "resizable", title: "Resizable", category: "layout", family: "resizable"},
      %{
        name: "resizable-vertical",
        title: "Vertical constrained panels",
        category: "layout",
        family: "resizable"
      },
      %{
        name: "resizable-multiple",
        title: "Default sizing and disabled separator",
        category: "layout",
        family: "resizable"
      },
      %{name: "sidebar", title: "Sidebar", category: "navigation", family: "sidebar"},
      %{
        name: "sidebar-collapsed-icon",
        title: "Collapsed icon sidebar",
        category: "navigation",
        family: "sidebar"
      },
      %{
        name: "sidebar-collapsed-offcanvas",
        title: "Collapsed offcanvas sidebar",
        category: "navigation",
        family: "sidebar"
      },
      %{
        name: "sidebar-multiple",
        title: "Independent expanded and static sidebars",
        category: "navigation",
        family: "sidebar"
      },
      %{
        name: "sidebar-menu-popup",
        title: "Sidebar with a menu popup",
        category: "navigation",
        family: "sidebar"
      },
      %{name: "chart", title: "Chart", category: "data-display", family: "chart"},
      %{
        name: "chart-config-theme",
        title: "Chart light/dark configuration",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-label-only",
        title: "Chart without color stylesheet",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-empty-config",
        title: "Chart empty configuration",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-bar-series",
        title: "Responsive signed multi-series bars",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-line-custom-dimensions",
        title: "Line chart custom initial dimensions",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-area-gaps",
        title: "Area chart missing samples",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-empty-data",
        title: "Chart empty dataset",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-tooltip",
        title: "Chart active multi-series tooltip",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-tooltip-line",
        title: "Chart nested line-indicator tooltip",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-tooltip-hidden",
        title: "Chart tooltip hidden label and indicator",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-tooltip-inactive",
        title: "Chart inactive tooltip",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-tooltip-dashed",
        title: "Chart dashed indicator with zero value",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-empty-payload",
        title: "Chart empty tooltip and legend payloads",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-legend",
        title: "Chart top legend and filtered payload",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-multiple-instances",
        title: "Independent chart styles and canvases",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "chart-area-interactive",
        title: "Stacked natural gradient area chart (dashboard-01)",
        category: "data-display",
        family: "chart"
      },
      %{
        name: "message-scroller",
        title: "Message Scroller",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "message-scroller-start",
        title: "Message Scroller start",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "message-scroller-end",
        title: "Message Scroller end",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "message-scroller-last-anchor",
        title: "Message Scroller last-anchor",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "message-scroller-empty",
        title: "Empty Message Scroller",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "message-scroller-multiple",
        title: "Independent Message Scrollers",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "questionnaire",
        title: "Questionnaire",
        category: "data-display",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-flow",
        title: "Questionnaire Form Flow",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-current-last",
        title: "Questionnaire Last Question",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-invalid-multiple",
        title: "Questionnaire Invalid Multiple Answers",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-empty",
        title: "Empty Questionnaire",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-multiple",
        title: "Independent Questionnaires",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "questionnaire-selected-choice",
        title: "Questionnaire Controlled Selection",
        category: "forms",
        family: "questionnaire"
      },
      %{
        name: "message-scroller-default-button",
        title: "Message Scroller Accessible Button",
        category: "layout",
        family: "message-scroller"
      },
      %{
        name: "questionnaire-input-states",
        title: "Questionnaire Empty and Disabled Inputs",
        category: "forms",
        family: "questionnaire"
      },
      %{name: "radio-group", title: "Radio Group", category: "forms", family: "radio-group"},
      %{
        name: "radio-group-required-vertical",
        title: "Required vertical radios",
        category: "forms",
        family: "radio-group"
      },
      %{
        name: "radio-group-controlled",
        title: "Controlled radios",
        category: "forms",
        family: "radio-group"
      },
      %{
        name: "radio-group-disabled-external-form",
        title: "Disabled external-form radios",
        category: "forms",
        family: "radio-group"
      },
      %{
        name: "radio-group-multiple-instances",
        title: "Independent radio instances",
        category: "forms",
        family: "radio-group"
      },
      %{name: "toggle-group", title: "Toggle Group", category: "actions", family: "toggle-group"},
      %{
        name: "toggle-group-single-vertical",
        title: "Vertical single toggle",
        category: "actions",
        family: "toggle-group"
      },
      %{
        name: "toggle-group-multiple-default",
        title: "Multiple default values",
        category: "actions",
        family: "toggle-group"
      },
      %{
        name: "toggle-group-controlled",
        title: "Controlled toggle selection",
        category: "actions",
        family: "toggle-group"
      },
      %{
        name: "toggle-group-disabled",
        title: "Disabled toggle group",
        category: "actions",
        family: "toggle-group"
      },
      %{
        name: "toggle-group-multiple-instances",
        title: "Independent toggle groups",
        category: "actions",
        family: "toggle-group"
      },
      %{name: "menubar", title: "Menubar", category: "navigation", family: "menubar"},
      %{
        name: "menubar-default-open",
        title: "Default-open menubar",
        category: "navigation",
        family: "menubar"
      },
      %{
        name: "menubar-controlled",
        title: "Controlled menubar",
        category: "navigation",
        family: "menubar"
      },
      %{
        name: "menubar-check-radio-submenu",
        title: "Menu selection and submenu",
        category: "navigation",
        family: "menubar"
      },
      %{
        name: "menubar-multiple-disabled",
        title: "Independent menubars and disabled menus",
        category: "navigation",
        family: "menubar"
      },
      %{
        name: "menubar-submenu-open",
        title: "Open nested menu",
        category: "navigation",
        family: "menubar"
      },
      %{
        name: "menubar-explicit-relations",
        title: "Caller-owned menu relations",
        category: "navigation",
        family: "menubar"
      },
      %{name: "checkbox", title: "Checkbox", category: "forms", family: "checkbox"},
      %{
        name: "checkbox-false-enabled",
        title: "Checkbox false Enabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-false-disabled",
        title: "Checkbox false Disabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-true-enabled",
        title: "Checkbox true Enabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-true-disabled",
        title: "Checkbox true Disabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-indeterminate-enabled",
        title: "Checkbox indeterminate Enabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-indeterminate-disabled",
        title: "Checkbox indeterminate Disabled",
        category: "forms",
        family: "checkbox"
      },
      %{
        name: "checkbox-multiple-external-form",
        title: "Checkbox Multiple External Form",
        category: "forms",
        family: "checkbox"
      },
      %{name: "switch", title: "Switch", category: "forms", family: "switch"},
      %{
        name: "switch-default-false-enabled",
        title: "Switch default false Enabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-default-false-disabled",
        title: "Switch default false Disabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-default-true-enabled",
        title: "Switch default true Enabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-default-true-disabled",
        title: "Switch default true Disabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-sm-false-enabled",
        title: "Switch sm false Enabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-sm-false-disabled",
        title: "Switch sm false Disabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-sm-true-enabled",
        title: "Switch sm true Enabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-sm-true-disabled",
        title: "Switch sm true Disabled",
        category: "forms",
        family: "switch"
      },
      %{
        name: "switch-multiple-external-form",
        title: "Switch Multiple External Form",
        category: "forms",
        family: "switch"
      },
      %{name: "slider", title: "Slider", category: "forms", family: "slider"},
      %{
        name: "slider-lower-bound",
        title: "slider-lower-bound",
        category: "forms",
        family: "slider"
      },
      %{
        name: "slider-upper-bound",
        title: "slider-upper-bound",
        category: "forms",
        family: "slider"
      },
      %{name: "slider-range", title: "slider-range", category: "forms", family: "slider"},
      %{
        name: "slider-three-thumbs",
        title: "slider-three-thumbs",
        category: "forms",
        family: "slider"
      },
      %{name: "slider-vertical", title: "slider-vertical", category: "forms", family: "slider"},
      %{name: "slider-rtl", title: "slider-rtl", category: "forms", family: "slider"},
      %{name: "slider-inverted", title: "slider-inverted", category: "forms", family: "slider"},
      %{name: "slider-disabled", title: "slider-disabled", category: "forms", family: "slider"},
      %{
        name: "slider-default-extents",
        title: "Slider Default Extents",
        category: "forms",
        family: "slider"
      },
      %{
        name: "slider-multiple-instances",
        title: "Slider Multiple Instances",
        category: "forms",
        family: "slider"
      },
      %{
        name: "slider-external-form",
        title: "Slider External Form",
        category: "forms",
        family: "slider"
      },
      %{
        name: "slider-minimum-thumb-distance",
        title: "Slider Minimum Thumb Distance",
        category: "forms",
        family: "slider"
      },
      %{name: "collapsible", title: "Collapsible", category: "layout", family: "collapsible"},
      %{
        name: "collapsible-closed-enabled",
        title: "collapsible-closed-enabled",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "collapsible-closed-disabled",
        title: "collapsible-closed-disabled",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "collapsible-open-enabled",
        title: "collapsible-open-enabled",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "collapsible-open-disabled",
        title: "collapsible-open-disabled",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "collapsible-force-mount",
        title: "Collapsible Force Mount",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "collapsible-multiple-instances",
        title: "Collapsible Multiple Instances",
        category: "layout",
        family: "collapsible"
      },
      %{
        name: "navigation-menu",
        title: "Navigation Menu",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-inline-closed",
        title: "navigation-inline-closed",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-inline-docs",
        title: "navigation-inline-docs",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-inline-about",
        title: "navigation-inline-about",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-viewport-closed",
        title: "navigation-viewport-closed",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-viewport-docs",
        title: "navigation-viewport-docs",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-viewport-about",
        title: "navigation-viewport-about",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-vertical-rtl-disabled",
        title: "Navigation Vertical RTL Disabled",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-force-mount",
        title: "Navigation Force Mount",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-multiple-instances",
        title: "Navigation Multiple Instances",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "navigation-indicator",
        title: "Navigation Indicator",
        category: "navigation",
        family: "navigation-menu"
      },
      %{
        name: "button-default-default",
        title: "Button default default",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-xs",
        title: "Button default xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-sm",
        title: "Button default sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-lg",
        title: "Button default lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-icon",
        title: "Button default icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-icon-xs",
        title: "Button default icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-icon-sm",
        title: "Button default icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-default-icon-lg",
        title: "Button default icon-lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-default",
        title: "Button outline default",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-xs",
        title: "Button outline xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-sm",
        title: "Button outline sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-lg",
        title: "Button outline lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-icon",
        title: "Button outline icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-icon-xs",
        title: "Button outline icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-icon-sm",
        title: "Button outline icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-outline-icon-lg",
        title: "Button outline icon-lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-default",
        title: "Button secondary default",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-xs",
        title: "Button secondary xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-sm",
        title: "Button secondary sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-lg",
        title: "Button secondary lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-icon",
        title: "Button secondary icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-icon-xs",
        title: "Button secondary icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-icon-sm",
        title: "Button secondary icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-secondary-icon-lg",
        title: "Button secondary icon-lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-ghost-default",
        title: "Button ghost default",
        category: "actions",
        family: "button"
      },
      %{name: "button-ghost-xs", title: "Button ghost xs", category: "actions", family: "button"},
      %{name: "button-ghost-sm", title: "Button ghost sm", category: "actions", family: "button"},
      %{name: "button-ghost-lg", title: "Button ghost lg", category: "actions", family: "button"},
      %{
        name: "button-ghost-icon",
        title: "Button ghost icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-ghost-icon-xs",
        title: "Button ghost icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-ghost-icon-sm",
        title: "Button ghost icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-ghost-icon-lg",
        title: "Button ghost icon-lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-default",
        title: "Button destructive default",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-xs",
        title: "Button destructive xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-sm",
        title: "Button destructive sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-lg",
        title: "Button destructive lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-icon",
        title: "Button destructive icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-icon-xs",
        title: "Button destructive icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-icon-sm",
        title: "Button destructive icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-destructive-icon-lg",
        title: "Button destructive icon-lg",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-link-default",
        title: "Button link default",
        category: "actions",
        family: "button"
      },
      %{name: "button-link-xs", title: "Button link xs", category: "actions", family: "button"},
      %{name: "button-link-sm", title: "Button link sm", category: "actions", family: "button"},
      %{name: "button-link-lg", title: "Button link lg", category: "actions", family: "button"},
      %{
        name: "button-link-icon",
        title: "Button link icon",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-link-icon-xs",
        title: "Button link icon-xs",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-link-icon-sm",
        title: "Button link icon-sm",
        category: "actions",
        family: "button"
      },
      %{
        name: "button-link-icon-lg",
        title: "Button link icon-lg",
        category: "actions",
        family: "button"
      },
      %{name: "badge-default", title: "Badge default", category: "data-display", family: "badge"},
      %{
        name: "badge-secondary",
        title: "Badge secondary",
        category: "data-display",
        family: "badge"
      },
      %{
        name: "badge-destructive",
        title: "Badge destructive",
        category: "data-display",
        family: "badge"
      },
      %{name: "badge-outline", title: "Badge outline", category: "data-display", family: "badge"},
      %{name: "badge-ghost", title: "Badge ghost", category: "data-display", family: "badge"},
      %{name: "badge-link", title: "Badge link", category: "data-display", family: "badge"},
      %{
        name: "toggle-default-default-off",
        title: "Toggle default default off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-default-default-on",
        title: "Toggle default default on",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-default-sm-off",
        title: "Toggle default sm off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-default-sm-on",
        title: "Toggle default sm on",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-default-lg-off",
        title: "Toggle default lg off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-default-lg-on",
        title: "Toggle default lg on",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-default-off",
        title: "Toggle outline default off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-default-on",
        title: "Toggle outline default on",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-sm-off",
        title: "Toggle outline sm off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-sm-on",
        title: "Toggle outline sm on",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-lg-off",
        title: "Toggle outline lg off",
        category: "actions",
        family: "toggle"
      },
      %{
        name: "toggle-outline-lg-on",
        title: "Toggle outline lg on",
        category: "actions",
        family: "toggle"
      },
      %{name: "card-small", title: "Small card", category: "data-display", family: "card"},
      %{
        name: "input-invalid-disabled",
        title: "Invalid disabled native input",
        category: "forms",
        family: "input"
      },
      %{
        name: "textarea-native-form",
        title: "Named readonly textarea",
        category: "forms",
        family: "textarea"
      },
      %{name: "alert", title: "Alert", category: "feedback", family: "alert"},
      %{name: "aspect-ratio", title: "Aspect Ratio", category: "layout", family: "aspect-ratio"},
      %{name: "attachment", title: "Attachment", category: "data-display", family: "attachment"},
      %{name: "avatar", title: "Avatar", category: "data-display", family: "avatar"},
      %{name: "badge", title: "Badge", category: "data-display", family: "badge"},
      %{name: "breadcrumb", title: "Breadcrumb", category: "navigation", family: "breadcrumb"},
      %{name: "bubble", title: "Bubble", category: "feedback", family: "bubble"},
      %{name: "button-group", title: "Button Group", category: "actions", family: "button-group"},
      %{name: "button", title: "Button", category: "actions", family: "button"},
      %{name: "card", title: "Card", category: "data-display", family: "card"},
      %{name: "direction", title: "Direction", category: "layout", family: "direction"},
      %{name: "empty", title: "Empty", category: "feedback", family: "empty"},
      %{name: "field", title: "Field", category: "forms", family: "field"},
      %{name: "field-separator", title: "Field separator", category: "forms", family: "field"},
      %{name: "input-group", title: "Input Group", category: "forms", family: "input-group"},
      %{name: "input", title: "Input", category: "forms", family: "input"},
      %{name: "item", title: "Item", category: "data-display", family: "item"},
      %{name: "kbd", title: "Kbd", category: "data-display", family: "kbd"},
      %{name: "label", title: "Label", category: "forms", family: "label"},
      %{name: "marker", title: "Marker", category: "data-display", family: "marker"},
      %{name: "message", title: "Message", category: "data-display", family: "message"},
      %{
        name: "native-select",
        title: "Native Select",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-default-selection",
        title: "Native Select Default Selection",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-controlled-small",
        title: "Native Select Controlled Small",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-disabled-groups",
        title: "Native Select Disabled Groups",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-multiple-instances",
        title: "Native Select Multiple Instances",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-empty-controlled",
        title: "Native Select Empty Controlled",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-controlled-multiple",
        title: "Native Select Controlled Multiple",
        category: "forms",
        family: "native-select"
      },
      %{
        name: "native-select-external-form-empty-multiple",
        title: "Native Select External Form Empty Multiple",
        category: "forms",
        family: "native-select"
      },
      %{name: "pagination", title: "Pagination", category: "navigation", family: "pagination"},
      %{name: "progress", title: "Progress", category: "feedback", family: "progress"},
      %{
        name: "progress-absent",
        title: "Progress absent",
        category: "feedback",
        family: "progress"
      },
      %{name: "progress-null", title: "Progress null", category: "feedback", family: "progress"},
      %{name: "progress-zero", title: "Progress zero", category: "feedback", family: "progress"},
      %{
        name: "progress-fractional",
        title: "Progress fractional",
        category: "feedback",
        family: "progress"
      },
      %{
        name: "progress-complete",
        title: "Progress complete",
        category: "feedback",
        family: "progress"
      },
      %{
        name: "progress-custom-max",
        title: "Progress custom-max",
        category: "feedback",
        family: "progress"
      },
      %{
        name: "progress-null-max",
        title: "Progress null-max",
        category: "feedback",
        family: "progress"
      },
      %{
        name: "progress-outside-visual-range",
        title: "Progress outside-visual-range",
        category: "feedback",
        family: "progress"
      },
      %{
        name: "progress-custom-class-aria",
        title: "Progress custom-class-aria",
        category: "feedback",
        family: "progress"
      },
      %{name: "scroll-area", title: "Scroll Area", category: "layout", family: "scroll-area"},
      %{name: "separator", title: "Separator", category: "layout", family: "separator"},
      %{name: "skeleton", title: "Skeleton", category: "feedback", family: "skeleton"},
      %{name: "sonner", title: "Sonner", category: "feedback", family: "sonner"},
      %{name: "spinner", title: "Spinner", category: "feedback", family: "spinner"},
      %{name: "table", title: "Table", category: "data-display", family: "table"},
      %{name: "textarea", title: "Textarea", category: "forms", family: "textarea"},
      %{name: "toggle", title: "Toggle", category: "actions", family: "toggle"}
    ]

  def render_html(name) do
    case render_fixture(name) do
      nil -> nil
      rendered -> Safe.to_iodata(rendered) |> IO.iodata_to_binary()
    end
  end

  def dump_all do
    names()
    |> Enum.map(fn name -> {name, render_html(name)} end)
    |> Map.new()
    |> Jason.encode!()
  end

  def render_fixture("accordion") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-demo"
      type="single"
      default_value="item-1"
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="item-1" disabled={false}>
        <.accordion_trigger context={item}>Is it accessible?</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Yes. It adheres to the WAI-ARIA design pattern.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-closed") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-closed-demo"
      type="single"
      default_value={nil}
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-selected-details") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-details-demo"
      type="single"
      value="details"
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-multiple") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-multiple-demo"
      type="multiple"
      value={["intro", "advanced"]}
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-disabled") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-disabled-demo"
      type="single"
      default_value="intro"
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={true}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    <.accordion
      :let={accordion}
      id="accordion-disabled-root"
      type="single"
      default_value="details"
      collapsible={false}
      disabled={true}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-force-mount") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-force-demo"
      type="single"
      default_value={nil}
      collapsible={true}
      disabled={false}
      orientation="horizontal"
      dir="rtl"
      class="max-w-lg"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Read the details.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("accordion-instances") do
    assigns = %{}

    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-first"
      type="single"
      default_value="intro"
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    <.accordion
      :let={accordion}
      id="accordion-second"
      type="single"
      default_value="details"
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("tabs") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-demo"
      default_value="account"
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
      class="w-[400px]"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="account" disabled={false}>Account</.tabs_trigger>
        <.tabs_trigger context={tabs} value="password" disabled={false}>Password</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="account" force_mount={false}>
        Make changes to your account here.
      </.tabs_content>
      <.tabs_content context={tabs} value="password" force_mount={false}>
        Change your password here.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-history") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-history-demo"
      value="history"
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-unselected") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-unselected-demo"
      default_value=""
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-disabled") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-disabled-demo"
      default_value="overview"
      orientation="horizontal"
      dir="ltr"
      activation_mode="manual"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={true}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-line-rtl") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-line-demo"
      default_value="settings"
      orientation="vertical"
      dir="rtl"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="line">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-force-mount") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-force-demo"
      default_value="history"
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={true} class="p-2">
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={true} class="p-2">
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={true} class="p-2">
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("tabs-instances") do
    assigns = %{}

    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-first"
      default_value="overview"
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    <.tabs
      :let={tabs}
      id="tabs-second"
      default_value="settings"
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("dialog") do
    assigns = %{}

    ~H"""
    <.dialog id="dialog-demo" open={true}>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-demo-title"
          aria-describedby="dialog-demo-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("dialog-closed") do
    assigns = %{}

    ~H"""
    <.dialog id="dialog-closed-root" open={false}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-closed-root-title"
          aria-describedby="dialog-closed-root-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("dialog-open-custom-ids") do
    assigns = %{}

    ~H"""
    <.dialog
      id="profile-editor"
      open={true}
      title_id="profile-editor-heading"
      description_id="profile-editor-help"
    >
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="profile-editor-heading"
          aria-describedby="profile-editor-help"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("dialog-no-close-icon-footer-close") do
    assigns = %{}

    ~H"""
    <.dialog id="dialog-footer" open={true}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-footer-title"
          aria-describedby="dialog-footer-description"
          show_close_button={false}
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer context={modal} show_close_button={true}>
            <.button type="submit">Save changes</.button>
            <.dialog_close context={modal}>Dismiss</.dialog_close>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("dialog-nonmodal") do
    assigns = %{}

    ~H"""
    <.dialog id="dialog-nonmodal-root" open={true} modal={false}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-nonmodal-root-title"
          aria-describedby="dialog-nonmodal-root-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("dialog-multiple-instances") do
    assigns = %{}

    ~H"""
    <.dialog
      id="dialog-instance-a"
      open={true}
      title_id="dialog-instance-a-heading"
      description_id="dialog-instance-a-help"
    >
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-instance-a-heading"
          aria-describedby="dialog-instance-a-help"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    <.dialog id="dialog-instance-b" open={false}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-instance-b-title"
          aria-describedby="dialog-instance-b-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def render_fixture("alert-dialog") do
    assigns = %{}

    ~H"""
    <.alert_dialog id="alert-dialog-demo" open={true}>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-demo-title"
          aria-describedby="alert-dialog-demo-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def render_fixture("alert-dialog-closed") do
    assigns = %{}

    ~H"""
    <.alert_dialog id="alert-dialog-closed-root" open={false}>
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-closed-root-title"
          aria-describedby="alert-dialog-closed-root-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def render_fixture("alert-dialog-open-custom-ids") do
    assigns = %{}

    ~H"""
    <.alert_dialog
      id="delete-confirmation"
      open={true}
      title_id="delete-confirmation-heading"
      description_id="delete-confirmation-help"
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="delete-confirmation-heading"
          aria-describedby="delete-confirmation-help"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def render_fixture("alert-dialog-small-media") do
    assigns = %{}

    ~H"""
    <.alert_dialog id="alert-dialog-small" open={true}>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-small-title"
          aria-describedby="alert-dialog-small-description"
          size="sm"
        >
          <.alert_dialog_header>
            <.alert_dialog_media><span aria-hidden="true">!</span></.alert_dialog_media>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal} disabled variant="destructive" size="sm">
              Continue
            </.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def render_fixture("alert-dialog-multiple-instances") do
    assigns = %{}

    ~H"""
    <.alert_dialog
      id="alert-dialog-instance-a"
      open={true}
      title_id="alert-dialog-instance-a-heading"
      description_id="alert-dialog-instance-a-help"
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-instance-a-heading"
          aria-describedby="alert-dialog-instance-a-help"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    <.alert_dialog id="alert-dialog-instance-b" open={false}>
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-instance-b-title"
          aria-describedby="alert-dialog-instance-b-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def render_fixture("drawer") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-demo" open={true} direction="bottom">
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-demo-title"
          aria-describedby="drawer-demo-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-closed") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-closed-root" open={false} direction="bottom">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-closed-root-title"
          aria-describedby="drawer-closed-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-open-custom-ids") do
    assigns = %{}

    ~H"""
    <.drawer
      id="drawer-custom"
      open={true}
      title_id="drawer-custom-heading"
      description_id="drawer-custom-help"
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-custom-heading"
          aria-describedby="drawer-custom-help"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-top") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-top-panel" open={true} direction="top">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-top-panel-title"
          aria-describedby="drawer-top-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-left") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-left-panel" open={true} direction="left">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-left-panel-title"
          aria-describedby="drawer-left-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-right") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-right-panel" open={true} direction="right">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-right-panel-title"
          aria-describedby="drawer-right-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-nondismissible") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-nondismissible-root" open={true} dismissible={false} direction="bottom">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-nondismissible-root-title"
          aria-describedby="drawer-nondismissible-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-select") do
    assigns = %{}

    ~H"""
    <.drawer id="drawer-select-root" open={true} direction="bottom">
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-select-root-title"
          aria-describedby="drawer-select-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <div class="p-4">
            <.select id="drawer-select-fruit" name="drawer-fruit" placeholder="Fruit">
              <:trigger :let={popup}>
                <.select_trigger context={popup}>
                  <.select_value placeholder="Fruit" />
                </.select_trigger>
              </:trigger><:option id="drawer-select-fruit-apple" value="apple" label="Apple">
                Apple
              </:option><:option id="drawer-select-fruit-banana" value="banana" label="Banana">
                Banana
              </:option>
            </.select>
          </div>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("drawer-multiple-instances") do
    assigns = %{}

    ~H"""
    <.drawer
      id="drawer-instance-a"
      open={true}
      title_id="drawer-instance-a-heading"
      description_id="drawer-instance-a-help"
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-instance-a-heading"
          aria-describedby="drawer-instance-a-help"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    <.drawer id="drawer-instance-b" open={false} direction="bottom">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-instance-b-title"
          aria-describedby="drawer-instance-b-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def render_fixture("sheet") do
    assigns = %{}

    ~H"""
    <.sheet id="sheet-demo" open={true}>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-demo-title"
          aria-describedby="sheet-demo-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-closed") do
    assigns = %{}

    ~H"""
    <.sheet id="sheet-closed-root" open={false}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-closed-root-title"
          aria-describedby="sheet-closed-root-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-open-custom-ids") do
    assigns = %{}

    ~H"""
    <.sheet
      id="sheet-custom"
      open={true}
      title_id="sheet-custom-heading"
      description_id="sheet-custom-help"
    >
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-custom-heading"
          aria-describedby="sheet-custom-help"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-top") do
    assigns = %{}

    ~H"""
    <.sheet id="sheet-top-panel" open={true}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-top-panel-title"
          aria-describedby="sheet-top-panel-description"
          side="top"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-bottom") do
    assigns = %{}

    ~H"""
    <.sheet id="sheet-bottom-panel" open={true}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-bottom-panel-title"
          aria-describedby="sheet-bottom-panel-description"
          side="bottom"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-left") do
    assigns = %{}

    ~H"""
    <.sheet id="sheet-left-panel" open={true}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-left-panel-title"
          aria-describedby="sheet-left-panel-description"
          side="left"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("sheet-multiple-instances") do
    assigns = %{}

    ~H"""
    <.sheet
      id="sheet-instance-a"
      open={true}
      title_id="sheet-instance-a-heading"
      description_id="sheet-instance-a-help"
    >
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-instance-a-heading"
          aria-describedby="sheet-instance-a-help"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    <.sheet id="sheet-instance-b" open={false}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-instance-b-title"
          aria-describedby="sheet-instance-b-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def render_fixture("context-menu") do
    assigns = %{}

    ~H"""
    <.context_menu id="context-demo">
      <:trigger :let={popup}>
        <.context_menu_trigger
          context={popup}
          class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm"
        >
          Right click here
        </.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>Back</.context_menu_item><.context_menu_item>
            Forward
          </.context_menu_item><.context_menu_item>Reload</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def render_fixture("context-menu-disabled") do
    assigns = %{}

    ~H"""
    <.context_menu id="context-disabled" disabled>
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>Unavailable</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item disabled>Unavailable action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def render_fixture("context-menu-multiple") do
    assigns = %{}

    ~H"""
    <.context_menu id="context-first">
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>first</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>first action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    <.context_menu id="context-second">
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>second</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>second action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def render_fixture("dropdown-menu") do
    assigns = %{}

    ~H"""
    <.dropdown_menu id="dropdown-demo" open>
      <:trigger :let={popup}><.button variant="outline" {popup.trigger}>Open Menu</.button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_label>My Account</.dropdown_menu_label><.dropdown_menu_separator /><.dropdown_menu_item>
            Profile
          </.dropdown_menu_item><.dropdown_menu_item>Billing</.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def render_fixture("dropdown-menu-closed-disabled") do
    assigns = %{}

    ~H"""
    <.dropdown_menu id="dropdown-disabled" disabled>
      <:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item>Action</.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def render_fixture("dropdown-menu-items") do
    assigns = %{}

    ~H"""
    <.dropdown_menu id="dropdown-first" open>
      <:trigger :let={popup}><button {popup.trigger}>first</button></:trigger><:content :let={popup}>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item disabled inset>Disabled</.dropdown_menu_item><.dropdown_menu_item variant="destructive">
            Delete
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    <.dropdown_menu id="dropdown-second" open>
      <:trigger :let={popup}><button {popup.trigger}>second</button></:trigger><:content :let={popup}>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item disabled inset>Disabled</.dropdown_menu_item><.dropdown_menu_item variant="destructive">
            Delete
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def render_fixture("dropdown-menu-checks") do
    assigns = %{}

    ~H"""
    <.dropdown_menu id="dropdown-checks" open>
      <:trigger :let={popup}><button {popup.trigger}>Preferences</button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_checkbox_item checked value="status">
            Show status
          </.dropdown_menu_checkbox_item><.dropdown_menu_radio_group>
            <.dropdown_menu_radio_item checked value="compact">Compact</.dropdown_menu_radio_item><.dropdown_menu_radio_item value="comfortable">
              Comfortable
            </.dropdown_menu_radio_item>
          </.dropdown_menu_radio_group>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def render_fixture("hover-card") do
    assigns = %{}

    ~H"""
    <.hover_card id="hover-demo" open>
      <:trigger :let={popup}><.button variant="link" {popup.trigger}>@nextjs</.button></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup} class="w-80">
          <p class="text-sm">The React Framework for the Web.</p>
        </.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def render_fixture("hover-card-disabled") do
    assigns = %{}

    ~H"""
    <.hover_card id="hover-disabled" disabled>
      <:trigger :let={popup}>
        <.button variant="link" {popup.trigger}>Unavailable profile</.button>
      </:trigger><:content :let={popup}>
        <.hover_card_content context={popup}>Unavailable profile details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def render_fixture("hover-card-closed") do
    assigns = %{}

    ~H"""
    <.hover_card id="hover-closed">
      <:trigger :let={popup}><a href="#profile" {popup.trigger}>Profile</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>Profile details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def render_fixture("hover-card-multiple") do
    assigns = %{}

    ~H"""
    <.hover_card id="hover-first" open side="right" align="start">
      <:trigger :let={popup}><a href="#first" {popup.trigger}>first</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>first details</.hover_card_content>
      </:content>
    </.hover_card>
    <.hover_card id="hover-second" open side="right" align="start">
      <:trigger :let={popup}><a href="#second" {popup.trigger}>second</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>second details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def render_fixture("popover") do
    assigns = %{}

    ~H"""
    <.popover id="popover-demo" open>
      <:trigger :let={popup}>
        <.button variant="outline" {popup.trigger}>Open popover</.button>
      </:trigger><:content :let={popup}>
        <.popover_content context={popup} class="w-80">
          <p class="text-sm">Dimensions settings.</p>
        </.popover_content>
      </:content>
    </.popover>
    """
  end

  def render_fixture("popover-closed") do
    assigns = %{}

    ~H"""
    <.popover id="popover-closed">
      <:trigger :let={popup}><button {popup.trigger}>Edit</button></:trigger><:content :let={popup}>
        <.popover_content context={popup}>
          <label for="popover-name">Name</label><input id="popover-name" value="Ada" />
        </.popover_content>
      </:content>
    </.popover>
    """
  end

  def render_fixture("popover-multiple-disabled") do
    assigns = %{}

    ~H"""
    <.popover id="popover-disabled" disabled>
      <:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={
        popup
      }>
        <.popover_content context={popup}>Unavailable</.popover_content>
      </:content>
    </.popover><.popover id="popover-second" open side="left" align="end">
      <:trigger :let={popup}><button {popup.trigger}>Second</button></:trigger><:content :let={popup}>
        <.popover_content context={popup}>Details</.popover_content>
      </:content>
    </.popover>
    """
  end

  def render_fixture("select") do
    assigns = %{}

    ~H"""
    <.select id="select-demo" open placeholder="Select a fruit">
      <:trigger :let={popup}>
        <.select_trigger context={popup} class="w-[180px]">
          <.select_value context={popup} placeholder="Select a fruit" />
        </.select_trigger>
      </:trigger><:option id="select-demo-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-demo-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    """
  end

  def render_fixture("select-value-disabled") do
    assigns = %{}

    ~H"""
    <form>
      <.select id="select-value" open name="fruit" value="banana" required>
        <:trigger :let={popup}>
          <.select_trigger context={popup}>
            <.select_value>Banana</.select_value>
          </.select_trigger>
        </:trigger><:option id="select-value-apple" value="apple" label="Apple" disabled>
          Apple
        </:option><:option id="select-value-banana" value="banana" label="Banana">Banana</:option>
      </.select>
    </form>
    """
  end

  def render_fixture("select-closed-multiple") do
    assigns = %{}

    ~H"""
    <.select id="select-closed-0" name="fruit-0" disabled={false} placeholder="Fruit">
      <:trigger :let={popup}>
        <.select_trigger context={popup} size="sm">
          <.select_value placeholder="Fruit" />
        </.select_trigger>
      </:trigger><:option id="select-closed-0-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-closed-0-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    <.select id="select-closed-1" name="fruit-1" disabled={true} placeholder="Fruit">
      <:trigger :let={popup}>
        <.select_trigger context={popup} size="sm">
          <.select_value placeholder="Fruit" />
        </.select_trigger>
      </:trigger><:option id="select-closed-1-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-closed-1-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    """
  end

  def render_fixture("select-popper") do
    assigns = %{}

    ~H"""
    <.select id="select-popper" open position="popper" align="start" placeholder="Fruit">
      <:trigger :let={popup}>
        <.select_trigger context={popup}><.select_value placeholder="Fruit" /></.select_trigger>
      </:trigger><:option id="select-popper-apple" value="apple" label="Apple">Apple</:option>
    </.select>
    """
  end

  def render_fixture("select-groups") do
    assigns = %{}

    ~H"""
    <.select id="select-groups" open name="produce" placeholder="Produce">
      <:trigger :let={popup}>
        <.select_trigger context={popup}><.select_value placeholder="Produce" /></.select_trigger>
      </:trigger><:group id="fruit" label="Fruit" /><:group id="vegetables" label="Vegetables" /><:option
        id="select-groups-apple"
        value="apple"
        label="Apple"
        group="fruit"
      >
        Apple
      </:option><:option id="select-groups-carrot" value="carrot" label="Carrot" group="vegetables">
        Carrot
      </:option>
    </.select>
    """
  end

  def render_fixture("tooltip") do
    assigns = %{}

    ~H"""
    <.tooltip_provider>
      <.tooltip id="tooltip-demo" open>
        <:trigger :let={popup}><.button variant="outline" {popup.trigger}>Hover</.button></:trigger><:content :let={
          popup
        }>
          <.tooltip_content context={popup}>
            <p>Add to library</p>
          </.tooltip_content>
        </:content>
      </.tooltip>
    </.tooltip_provider>
    """
  end

  def render_fixture("tooltip-closed-disabled") do
    assigns = %{}

    ~H"""
    <.tooltip id="tooltip-disabled" disabled>
      <:trigger :let={popup}><button {popup.trigger}>Unavailable</button></:trigger><:content :let={
        popup
      }>
        <.tooltip_content context={popup}>Unavailable action</.tooltip_content>
      </:content>
    </.tooltip>
    """
  end

  def render_fixture("tooltip-multiple") do
    assigns = %{}

    ~H"""
    <.tooltip id="tooltip-first" open side="bottom" align="end">
      <:trigger :let={popup}><button {popup.trigger}>first</button></:trigger><:content :let={popup}>
        <.tooltip_content context={popup}>first hint</.tooltip_content>
      </:content>
    </.tooltip>
    <.tooltip id="tooltip-second" open side="bottom" align="end">
      <:trigger :let={popup}><button {popup.trigger}>second</button></:trigger><:content :let={popup}>
        <.tooltip_content context={popup}>second hint</.tooltip_content>
      </:content>
    </.tooltip>
    """
  end

  def render_fixture("combobox") do
    assigns = %{}

    ~H"""
    <.combobox id="framework-combo" value="" disabled={false}>
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="framework-combo-input"
          disabled={false}
          placeholder="Select framework..."
          show_clear={false}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}>
            <.combobox_item context={combo} value="next">Next.js</.combobox_item>
            <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
          </.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def render_fixture("combobox-empty") do
    assigns = %{}

    ~H"""
    <.combobox id="empty-combo" value="" disabled={false}>
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="empty-combo-input"
          disabled={false}
          placeholder="Select framework..."
          show_clear={false}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}></.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def render_fixture("combobox-value") do
    assigns = %{}

    ~H"""
    <.combobox id="selected-combo" value="phoenix" disabled={false} name="framework">
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="selected-combo-input"
          disabled={false}
          placeholder="Select framework..."
          show_clear={true}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}>
            <.combobox_item context={combo} value="next">Next.js</.combobox_item>
            <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
          </.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def render_fixture("combobox-disabled") do
    assigns = %{}

    ~H"""
    <.combobox id="disabled-combo" value="next" disabled={true} name="framework">
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="disabled-combo-input"
          disabled={true}
          placeholder="Select framework..."
          show_clear={true}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}>
            <.combobox_item context={combo} value="next">Next.js</.combobox_item>
            <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
          </.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def render_fixture("combobox-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.combobox id="first-combo" value="" disabled={false}>
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="first-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={false}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox><.combobox id="second-combo" value="phoenix" disabled={false}>
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="second-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={false}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox>
    </div>
    """
  end

  def render_fixture("command") do
    assigns = %{}

    ~H"""
    <.command :let={command} id="command-demo" class="rounded-lg border shadow-md">
      <.command_input context={command} placeholder="Type a command or search..." />
      <.command_list context={command}>
        <.command_empty>No results found.</.command_empty>
        <.command_group id="command-suggestions" heading="Suggestions">
          <.command_item id="radix-command-demo-calendar" value="calendar">Calendar</.command_item>
          <.command_item id="radix-command-demo-emoji" value="emoji">Search Emoji</.command_item>
        </.command_group>
      </.command_list>
    </.command>
    """
  end

  def render_fixture("command-empty") do
    assigns = %{}

    ~H"""
    <.command :let={command} id="empty-command" label="Actions">
      <.command_input context={command} /><.command_list context={command} label="Actions">
        <.command_empty>No actions available.</.command_empty>
      </.command_list>
    </.command>
    """
  end

  def render_fixture("command-values-disabled") do
    assigns = %{}

    ~H"""
    <.command :let={command} id="valued-command" value="save" label="Editor actions">
      <.command_input context={command} name="query" value="sav" disabled /><.command_list context={
        command
      }>
        <.command_empty>No actions.</.command_empty><.command_group
          id="editor-actions"
          heading="Editor"
        >
          <.command_item id="radix-valued-command-save" value="save" keywords={["persist"]}>
            Save<.command_shortcut>⌘S</.command_shortcut>
          </.command_item><.command_item id="radix-valued-command-delete" value="delete" disabled>
            Delete
          </.command_item>
        </.command_group><.command_separator /><.command_item
          id="radix-valued-command-close"
          value="close"
        >
          Close
        </.command_item>
      </.command_list>
    </.command>
    """
  end

  def render_fixture("command-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.command :let={command} id="first-command">
        <.command_input context={command} /><.command_list context={command}>
          <.command_item id="radix-first-command-open" value="open">Open</.command_item>
        </.command_list>
      </.command><.command :let={command} id="second-command">
        <.command_input context={command} /><.command_list context={command}>
          <.command_item id="radix-second-command-open" value="open">Open</.command_item>
        </.command_list>
      </.command>
    </div>
    """
  end

  def render_fixture("input-otp") do
    assigns = %{}

    ~H"""
    <.input_otp :let={otp} id="otp-demo" max_length={4} value="" disabled={false}>
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        /><.input_otp_slot context={otp} index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input-otp-partial-value") do
    assigns = %{}

    ~H"""
    <.input_otp :let={otp} id="partial-otp" max_length={4} value="12" disabled={false} name="code">
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        /><.input_otp_slot context={otp} index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input-otp-separated") do
    assigns = %{}

    ~H"""
    <.input_otp
      :let={otp}
      id="separated-otp"
      max_length={6}
      value="123456"
      disabled={false}
      name="code"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        />
      </.input_otp_group><.input_otp_separator /><.input_otp_group>
        <.input_otp_slot context={otp} index={3} /><.input_otp_slot context={otp} index={4} /><.input_otp_slot
          context={otp}
          index={5}
        />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input-otp-disabled") do
    assigns = %{}

    ~H"""
    <.input_otp :let={otp} id="disabled-otp" max_length={4} value="9876" disabled={true} name="code">
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        /><.input_otp_slot context={otp} index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input-otp-validation") do
    assigns = %{}

    ~H"""
    <.input_otp
      :let={otp}
      id="validated-otp"
      max_length={4}
      name="code"
      form="verification"
      required
      readonly
      pattern="^[0-9]+$"
      placeholder="----"
      aria-invalid="true"
      aria-label="Verification code"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} aria-invalid="true" /><.input_otp_slot
          context={otp}
          index={1}
          aria-invalid="true"
        /><.input_otp_slot context={otp} index={2} aria-invalid="true" /><.input_otp_slot
          context={otp}
          index={3}
          aria-invalid="true"
        />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input-otp-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.input_otp :let={otp} id="first-otp" max_length={4} value="" disabled={false}>
        <.input_otp_group>
          <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
            context={otp}
            index={2}
          /><.input_otp_slot context={otp} index={3} />
        </.input_otp_group>
      </.input_otp><.input_otp :let={otp} id="second-otp" max_length={4} value="23" disabled={false}>
        <.input_otp_group>
          <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
            context={otp}
            index={2}
          /><.input_otp_slot context={otp} index={3} />
        </.input_otp_group>
      </.input_otp>
    </div>
    """
  end

  def render_fixture("calendar") do
    assigns = %{}

    ~H"""
    <.calendar id="calendar-default" month={~D[2024-10-01]} today={~D[2024-02-15]} />
    """
  end

  def render_fixture("calendar-leap-selection") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-leap"
      month={~D[2024-02-01]}
      today={~D[2024-02-15]}
      mode="single"
      selected={~D[2024-02-29]}
    />
    """
  end

  def render_fixture("calendar-common-february") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-common"
      month={~D[2023-02-01]}
      today={~D[2024-02-15]}
      show_outside_days={false}
    />
    """
  end

  def render_fixture("calendar-bounded-range") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-range"
      month={~D[2024-02-01]}
      today={~D[2024-02-15]}
      mode="range"
      selected={%{from: ~D[2024-02-10], to: ~D[2024-02-12]}}
      disabled_before={~D[2024-02-05]}
      disabled_after={~D[2024-02-25]}
      start_month={~D[2024-02-01]}
      end_month={~D[2024-02-01]}
      show_outside_days={false}
    />
    """
  end

  def render_fixture("calendar-british-week") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-british"
      month={~D[2024-02-01]}
      today={~D[2024-02-15]}
      locale="en-GB"
      mode="single"
    />
    """
  end

  def render_fixture("calendar-fixed-multiple") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-multiple"
      month={~D[2024-02-01]}
      today={~D[2024-02-15]}
      mode="multiple"
      selected={[~D[2024-02-05], ~D[2024-02-21]]}
      disabled={[~D[2024-02-08], ~D[2024-02-09]]}
      week_starts_on={1}
      fixed_weeks
    />
    """
  end

  def render_fixture("calendar-year-boundary") do
    assigns = %{}

    ~H"""
    <.calendar id="calendar-year" month={~D[2024-12-01]} today={~D[2024-02-15]} number_of_months={2} />
    """
  end

  def render_fixture("calendar-independent-instances") do
    assigns = %{}

    ~H"""
    <.calendar
      id="calendar-first"
      month={~D[2024-01-01]}
      today={~D[2024-02-15]}
      mode="single"
      selected={~D[2024-01-10]}
    /><.calendar
      id="calendar-second"
      month={~D[2024-03-01]}
      today={~D[2024-02-15]}
      mode="single"
      selected={~D[2024-03-20]}
    />
    """
  end

  def render_fixture("carousel") do
    assigns = %{}

    ~H"""
    <.carousel :let={carousel} id="carousel-demo" class="w-full max-w-xs">
      <.carousel_content carousel={carousel}>
        <.carousel_item carousel={carousel}>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">1</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
    </.carousel>
    """
  end

  def render_fixture("carousel-vertical") do
    assigns = %{}

    ~H"""
    <.carousel
      :let={carousel}
      id="carousel-vertical-demo"
      orientation="vertical"
      class="my-12 h-48 w-full max-w-xs"
    >
      <.carousel_content carousel={carousel} class="h-48">
        <.carousel_item carousel={carousel}>First</.carousel_item><.carousel_item carousel={carousel}>
          Second
        </.carousel_item><.carousel_item carousel={carousel}>Third</.carousel_item>
      </.carousel_content>
      <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
    </.carousel>
    """
  end

  def render_fixture("carousel-multiple") do
    assigns = %{}

    ~H"""
    <div class="flex w-full flex-col items-center gap-12 px-12">
      <.carousel
        :let={carousel}
        :for={side <- ~w(left right)}
        id={"carousel-" <> side}
        loop={true}
        start_index={1}
        class="w-full max-w-48"
      >
        <.carousel_content carousel={carousel}>
          <.carousel_item :for={label <- ~w(A B C D)} carousel={carousel} class="basis-1/2">
            {label}
          </.carousel_item>
        </.carousel_content><.carousel_previous carousel={carousel} /><.carousel_next carousel={
          carousel
        } />
      </.carousel>
    </div>
    """
  end

  def render_fixture("resizable") do
    assigns = %{}

    ~H"""
    <.resizable_panel_group
      :let={group}
      id="resizable-demo"
      orientation="horizontal"
      class="max-w-md rounded-lg border"
    >
      <.resizable_panel group={group} id="resizable-demo-one" default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">One</div>
      </.resizable_panel>
      <.resizable_handle group={group} id="resizable-demo-handle" />
      <.resizable_panel group={group} id="resizable-demo-two" default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">Two</div>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  def render_fixture("resizable-vertical") do
    assigns = %{}

    ~H"""
    <.resizable_panel_group
      :let={group}
      id="resizable-vertical-demo"
      orientation="vertical"
      class="min-h-64 max-w-md border"
    >
      <.resizable_panel
        group={group}
        id="resizable-vertical-one"
        default_size="30%"
        min_size="10%"
        max_size="80%"
      >
        Top
      </.resizable_panel><.resizable_handle
        group={group}
        id="resizable-vertical-handle"
        with_handle={true}
      /><.resizable_panel
        group={group}
        id="resizable-vertical-two"
        default_size="70%"
        min_size="20%"
        max_size="90%"
      >
        Bottom
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  def render_fixture("resizable-multiple") do
    assigns = %{}

    ~H"""
    <div class="flex gap-4">
      <.resizable_panel_group :let={group} id="resize-auto" class="min-h-32">
        <.resizable_panel id="resize-auto-a" group={group}>Automatic</.resizable_panel><.resizable_handle
          id="resize-auto-h"
          group={group}
          with_handle={true}
        /><.resizable_panel
          id="resize-auto-b"
          group={group}
          collapsible={true}
          collapsed_size="5%"
          min_size="15%"
          max_size="70%"
        >
          Collapsible
        </.resizable_panel>
      </.resizable_panel_group><.resizable_panel_group :let={group} id="resize-fixed" class="min-h-32">
        <.resizable_panel id="resize-fixed-a" group={group} default_size="40%">
          Fixed
        </.resizable_panel><.resizable_handle id="resize-fixed-h" group={group} disabled={true} /><.resizable_panel
          id="resize-fixed-b"
          group={group}
          default_size="60%"
          disabled={true}
        >
          Disabled
        </.resizable_panel>
      </.resizable_panel_group>
    </div>
    """
  end

  def render_fixture("sidebar") do
    assigns = %{}

    ~H"""
    <.sidebar_provider :let={sidebar} id="sidebar-demo">
      <.sidebar id="sidebar-demo-panel" sidebar={sidebar}>
        <.sidebar_header>
          <h4 class="font-semibold text-sm">Application</h4>
        </.sidebar_header><.sidebar_content>
          <div class="p-2 text-sm text-muted-foreground">Nav items</div>
        </.sidebar_content>
      </.sidebar>
    </.sidebar_provider>
    """
  end

  def render_fixture("sidebar-collapsed-icon") do
    assigns = %{}

    ~H"""
    <.sidebar_provider :let={sidebar} id="sidebar-icon" open={false}>
      <.sidebar
        id="sidebar-icon-panel"
        sidebar={sidebar}
        collapsible="icon"
        side="right"
        variant="floating"
      >
        <.sidebar_header>Workspace</.sidebar_header><.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub>
                    <.sidebar_menu_sub_item>
                      <.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button>
                    </.sidebar_menu_sub_item>
                  </.sidebar_menu_sub>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} />
      </.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def render_fixture("sidebar-collapsed-offcanvas") do
    assigns = %{}

    ~H"""
    <.sidebar_provider :let={sidebar} id="sidebar-offcanvas" open={false}>
      <.sidebar
        id="sidebar-offcanvas-panel"
        sidebar={sidebar}
        collapsible="offcanvas"
        side="right"
        variant="floating"
      >
        <.sidebar_header>Workspace</.sidebar_header><.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub>
                    <.sidebar_menu_sub_item>
                      <.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button>
                    </.sidebar_menu_sub_item>
                  </.sidebar_menu_sub>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} />
      </.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def render_fixture("sidebar-multiple") do
    assigns = %{}

    ~H"""
    <div class="flex w-full min-w-0 flex-col gap-4 md:flex-row">
      <.sidebar_provider
        :let={sidebar}
        id="sidebar-inset"
        class="relative h-64 min-h-0! min-w-0 overflow-hidden"
      >
        <.sidebar
          id="sidebar-inset-panel"
          sidebar={sidebar}
          variant="inset"
          class="md:absolute md:h-full"
        >
          <.sidebar_header>Inset</.sidebar_header><.sidebar_content>Navigation</.sidebar_content>
        </.sidebar><.sidebar_inset class="min-w-0">
          <.sidebar_trigger sidebar={sidebar} />Main
        </.sidebar_inset>
      </.sidebar_provider><.sidebar_provider
        :let={sidebar}
        id="sidebar-static"
        class="h-48 min-h-0! min-w-0 md:h-64 md:w-48 md:shrink-0"
      >
        <.sidebar id="sidebar-static-panel" sidebar={sidebar} collapsible="none" class="w-48">
          <.sidebar_content>Always visible</.sidebar_content>
        </.sidebar>
      </.sidebar_provider>
    </div>
    """
  end

  def render_fixture("sidebar-menu-popup") do
    assigns = %{}

    ~H"""
    <.sidebar_provider :let={sidebar} id="sidebar-popup">
      <.sidebar id="sidebar-popup-panel" sidebar={sidebar}>
        <.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.dropdown_menu id="sidebar-popup-menu">
                    <:trigger :let={popup}>
                      <.sidebar_menu_button {popup.trigger}>Team</.sidebar_menu_button>
                    </:trigger><:content :let={popup}>
                      <.dropdown_menu_content context={popup}>
                        <.dropdown_menu_item>Acme</.dropdown_menu_item><.dropdown_menu_item>
                          Globex
                        </.dropdown_menu_item>
                      </.dropdown_menu_content>
                    </:content>
                  </.dropdown_menu>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content>
      </.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Main</.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def render_fixture("chart") do
    assigns = %{}

    ~H"""
    <.chart_container
      id="viewport"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="min-h-[200px] w-full"
    >
      <div class="p-4 text-center text-muted-foreground">Chart Viewport</div>
    </.chart_container>
    """
  end

  def render_fixture("chart-config-theme") do
    assigns = %{}

    ~H"""
    <.chart_container
      id="theme-sales"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <div>Theme-aware sales</div>
    </.chart_container>
    """
  end

  def render_fixture("chart-label-only") do
    assigns = %{}

    ~H"""
    <.chart_container id="label-only" config={%{sales: %{label: "Sales"}}} aria-label="Sales report">
      <div>Sales</div>
    </.chart_container>
    """
  end

  def render_fixture("chart-empty-config") do
    assigns = %{}

    ~H"""
    <.chart_container id="no-config" config={%{}}>
      <div>No configured series</div>
    </.chart_container>
    """
  end

  def render_fixture("chart-bar-series") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="sales-bars"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
      class="h-[240px] w-full"
    >
      <.chart_canvas
        id="sales-bars-canvas"
        context={chart}
        data={[
          %{month: "January", desktop: 186, mobile: 80},
          %{month: "February", desktop: 305, mobile: 200},
          %{month: "March", desktop: -45, mobile: 120},
          %{month: "April", desktop: 0, mobile: 0}
        ]}
        series={[:desktop, :mobile]}
        x_key="month"
        legend
        label="Monthly desktop and mobile sales"
      />
    </.chart_container>
    """
  end

  def render_fixture("chart-line-custom-dimensions") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="trend"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
      initial_dimension={%{width: 480, height: 260}}
      class="h-[260px] w-full"
    >
      <.chart_canvas
        id="trend-canvas"
        context={chart}
        kind="line"
        data={[
          %{month: "January", desktop: 186, mobile: 80},
          %{month: "February", desktop: 305, mobile: 200},
          %{month: "March", desktop: -45, mobile: 120},
          %{month: "April", desktop: 0, mobile: 0}
        ]}
        series={[:desktop, :mobile]}
        x_key="month"
        label="Monthly trends"
      />
    </.chart_container>
    """
  end

  def render_fixture("chart-area-gaps") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="area"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="h-[200px] w-full"
    >
      <.chart_canvas
        id="area-canvas"
        context={chart}
        kind="area"
        data={[
          %{month: "January", desktop: 20},
          %{month: "February", desktop: nil},
          %{month: "March", desktop: 40}
        ]}
        series={[:desktop]}
        x_key="month"
      />
    </.chart_container>
    """
  end

  def render_fixture("chart-empty-data") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="empty-data"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="h-[200px] w-full"
    >
      <.chart_canvas
        id="empty-data-canvas"
        context={chart}
        data={[]}
        series={[:desktop]}
        axes={false}
        tooltip={false}
      />
    </.chart_container>
    """
  end

  def render_fixture("chart-tooltip") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
          label="January"
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-tooltip-line") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-line"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[%{dataKey: "desktop", name: "desktop", value: 1234, color: "#2563eb"}]}
          label="January"
          indicator="line"
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-tooltip-hidden") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-hidden"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
          label="January"
          hide_label
          hide_indicator
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-tooltip-inactive") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-inactive"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-tooltip-dashed") do
    assigns = %{}

    ~H"""
    <.chart_container :let={chart} id="tooltip-dashed" config={%{desktop: %{label: "Desktop"}}}>
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[%{name: "desktop", value: 0, color: "#123"}]}
          label="January"
          indicator="dashed"
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-empty-payload") do
    assigns = %{}

    ~H"""
    <.chart_container :let={chart} id="empty-payload" config={%{}}>
      <section>
        <.chart_tooltip_content context={chart} active payload={[]} /><.chart_legend_content
          context={chart}
          payload={[]}
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-legend") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="legend"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_legend_content
          context={chart}
          vertical_align="top"
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"},
            %{type: "none", dataKey: "ignored", color: "red"}
          ]}
        />
      </section>
    </.chart_container>
    """
  end

  def render_fixture("chart-multiple-instances") do
    assigns = %{}

    ~H"""
    <section>
      <.chart_container
        :let={chart}
        id="first"
        config={%{sales: %{label: "First sales", color: "#9333ea"}}}
        class="h-[200px] w-full"
      >
        <.chart_canvas
          id="first-canvas"
          context={chart}
          data={[%{name: "A", sales: 12}]}
          series={[:sales]}
        />
      </.chart_container><.chart_container
        :let={chart}
        id="second"
        config={%{sales: %{label: "Second sales", theme: %{light: "#dc2626", dark: "#f87171"}}}}
        class="h-[200px] w-full"
      >
        <.chart_canvas
          id="second-canvas"
          context={chart}
          kind="line"
          data={[%{name: "B", sales: 18}]}
          series={[:sales]}
        />
      </.chart_container>
    </section>
    """
  end

  def render_fixture("chart-area-interactive") do
    assigns = %{}

    ~H"""
    <.chart_container
      :let={chart}
      id="visitors"
      config={[
        visitors: %{label: "Visitors"},
        desktop: %{label: "Desktop", color: "var(--primary)"},
        mobile: %{label: "Mobile", color: "var(--primary)"}
      ]}
      class="aspect-auto h-[250px] w-full"
    >
      <.chart_canvas
        id="visitors-chart"
        context={chart}
        kind="area"
        data={[
          %{date: "2024-06-01", desktop: 178, mobile: 200},
          %{date: "2024-06-02", desktop: 470, mobile: 410},
          %{date: "2024-06-03", desktop: 103, mobile: 160},
          %{date: "2024-06-04", desktop: 439, mobile: 380},
          %{date: "2024-06-05", desktop: 88, mobile: 140},
          %{date: "2024-06-06", desktop: 294, mobile: 250},
          %{date: "2024-06-07", desktop: 323, mobile: 370},
          %{date: "2024-06-08", desktop: 385, mobile: 320},
          %{date: "2024-06-09", desktop: 438, mobile: 480},
          %{date: "2024-06-10", desktop: 155, mobile: 200},
          %{date: "2024-06-11", desktop: 92, mobile: 150},
          %{date: "2024-06-12", desktop: 492, mobile: 420},
          %{date: "2024-06-13", desktop: 81, mobile: 130},
          %{date: "2024-06-14", desktop: 426, mobile: 380},
          %{date: "2024-06-15", desktop: 307, mobile: 350},
          %{date: "2024-06-16", desktop: 371, mobile: 310},
          %{date: "2024-06-17", desktop: 475, mobile: 520},
          %{date: "2024-06-18", desktop: 107, mobile: 170},
          %{date: "2024-06-19", desktop: 341, mobile: 290},
          %{date: "2024-06-20", desktop: 408, mobile: 450},
          %{date: "2024-06-21", desktop: 169, mobile: 210},
          %{date: "2024-06-22", desktop: 317, mobile: 270},
          %{date: "2024-06-23", desktop: 480, mobile: 530},
          %{date: "2024-06-24", desktop: 132, mobile: 180},
          %{date: "2024-06-25", desktop: 141, mobile: 190},
          %{date: "2024-06-26", desktop: 434, mobile: 380},
          %{date: "2024-06-27", desktop: 448, mobile: 490},
          %{date: "2024-06-28", desktop: 149, mobile: 200},
          %{date: "2024-06-29", desktop: 103, mobile: 160},
          %{date: "2024-06-30", desktop: 446, mobile: 400}
        ]}
        x_key="date"
        series={[
          %{key: "mobile", gradient_opacity: [0.8, 0.1]},
          %{key: "desktop", gradient_opacity: [1.0, 0.1]}
        ]}
        stack
        curve="natural"
        fill="gradient"
        grid="horizontal"
        axis_line={false}
        tick_line={false}
        tick_margin={8}
        min_tick_gap={32}
        tick_format="date_short"
        tooltip_label_format="date_short"
        cursor={false}
        label="Total visitors"
      />
    </.chart_container>
    """
  end

  def render_fixture("message-scroller") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll}>
      <.message_scroller id="message-scroller-demo" context={scroll} class="h-40 border rounded p-4">
        <p>Message stream content</p>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message-scroller-start") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="start" auto_scroll>
      <.message_scroller id="stream-start" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0">
            <.message_scroller_item message_id="stream-start-first" scroll_anchor>
              <p>First message</p>
            </.message_scroller_item><.message_scroller_item message_id="stream-start-second">
              <p>Second message</p>
            </.message_scroller_item><.message_scroller_item
              message_id="stream-start-third"
              scroll_anchor
            >
              <p>Latest message</p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message-scroller-end") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="end" auto_scroll>
      <.message_scroller id="stream-end" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0">
            <.message_scroller_item message_id="stream-end-first" scroll_anchor>
              <p>First message</p>
            </.message_scroller_item><.message_scroller_item message_id="stream-end-second">
              <p>Second message</p>
            </.message_scroller_item><.message_scroller_item
              message_id="stream-end-third"
              scroll_anchor
            >
              <p>Latest message</p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message-scroller-last-anchor") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="last-anchor" auto_scroll>
      <.message_scroller id="stream-last-anchor" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0">
            <.message_scroller_item message_id="stream-last-anchor-first" scroll_anchor>
              <p>First message</p>
            </.message_scroller_item><.message_scroller_item message_id="stream-last-anchor-second">
              <p>Second message</p>
            </.message_scroller_item><.message_scroller_item
              message_id="stream-last-anchor-third"
              scroll_anchor
            >
              <p>Latest message</p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message-scroller-empty") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="end" auto_scroll>
      <.message_scroller id="stream-empty" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0"></.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message-scroller-multiple") do
    assigns = %{}

    ~H"""
    <div>
      <.message_scroller_provider :let={scroll} default_scroll_position="start" auto_scroll>
        <.message_scroller id="stream-a" context={scroll} class="h-40 border rounded p-4">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content spacer_class="shrink-0">
              <.message_scroller_item message_id="stream-a-first" scroll_anchor>
                <p>First message</p>
              </.message_scroller_item><.message_scroller_item message_id="stream-a-second">
                <p>Second message</p>
              </.message_scroller_item><.message_scroller_item
                message_id="stream-a-third"
                scroll_anchor
              >
                <p>Latest message</p>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
        </.message_scroller>
      </.message_scroller_provider><.message_scroller_provider
        :let={scroll}
        default_scroll_position="last-anchor"
        auto_scroll
      >
        <.message_scroller id="stream-b" context={scroll} class="h-40 border rounded p-4">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content spacer_class="shrink-0">
              <.message_scroller_item message_id="stream-b-first" scroll_anchor>
                <p>First message</p>
              </.message_scroller_item><.message_scroller_item message_id="stream-b-second">
                <p>Second message</p>
              </.message_scroller_item><.message_scroller_item
                message_id="stream-b-third"
                scroll_anchor
              >
                <p>Latest message</p>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
        </.message_scroller>
      </.message_scroller_provider>
    </div>
    """
  end

  def render_fixture("questionnaire") do
    assigns = %{}

    ~H"""
    <.questionnaire :let={questionnaire} id="questionnaire-demo" items={[%{name: "satisfaction"}]}>
      <.questionnaire_item context={questionnaire} name="satisfaction">
        How satisfied are you with our service?
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  def render_fixture("questionnaire-flow") do
    assigns = %{}

    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-flow"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item="rating"
      shortcuts="letters"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={false}
        invalid={false}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-flow-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice context={question} value="good" index={0}>
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="great" index={1}>
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-flow-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-flow-comment-input"
          value="Thanks!"
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-flow-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  def render_fixture("questionnaire-current-last") do
    assigns = %{}

    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-last"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item="comment"
      shortcuts="letters"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={false}
        invalid={false}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-last-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice context={question} value="good" index={0}>
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="great" index={1}>
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-last-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-last-comment-input"
          value="Thanks!"
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-last-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  def render_fixture("questionnaire-invalid-multiple") do
    assigns = %{}

    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-invalid"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item="rating"
      shortcuts="numbers"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={true}
        invalid={true}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-invalid-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice context={question} value="good" index={0}>
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="great" index={1}>
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-invalid-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-invalid-comment-input"
          value="Thanks!"
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-invalid-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  def render_fixture("questionnaire-empty") do
    assigns = %{}

    ~H"""
    <.questionnaire :let={questionnaire} id="questionnaire-empty">
      <.questionnaire_progress context={questionnaire} /><.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  def render_fixture("questionnaire-multiple") do
    assigns = %{}

    ~H"""
    <div>
      <.questionnaire
        :let={questionnaire}
        id="questionnaire-a"
        items={[
          %{
            name: "rating",
            required: true,
            choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
          },
          %{name: "comment"},
          %{name: "archived", disabled: true}
        ]}
        item="rating"
        shortcuts="letters"
      >
        <.questionnaire_progress context={questionnaire} />
        <.questionnaire_item
          :let={question}
          context={questionnaire}
          name="rating"
          required
          multiple={false}
          invalid={false}
        >
          <.questionnaire_title>How was your visit?</.questionnaire_title>
          <.questionnaire_description id="questionnaire-a-rating-description">
            Choose an answer.
          </.questionnaire_description>
          <.questionnaire_choices context={question}>
            <.questionnaire_choice context={question} value="good" index={0}>
              Good<.questionnaire_choice_description>
                A pleasant visit.
              </.questionnaire_choice_description>
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="great" index={1}>
              Great
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
              Unavailable
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error context={question} id="questionnaire-a-rating-error" />
        </.questionnaire_item>
        <.questionnaire_item :let={question} context={questionnaire} name="comment">
          <.questionnaire_title>Anything to add?</.questionnaire_title>
          <.questionnaire_input
            context={question}
            id="questionnaire-a-comment-input"
            value="Thanks!"
            placeholder="Your feedback"
          />
          <.questionnaire_error context={question} id="questionnaire-a-comment-error" />
        </.questionnaire_item>
        <.questionnaire_item context={questionnaire} name="archived" disabled>
          <.questionnaire_title>Archived question</.questionnaire_title>
        </.questionnaire_item>
        <.questionnaire_actions>
          <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
            questionnaire
          } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
            questionnaire
          } />
        </.questionnaire_actions>
      </.questionnaire><.questionnaire
        :let={questionnaire}
        id="questionnaire-b"
        items={[
          %{
            name: "rating",
            required: true,
            choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
          },
          %{name: "comment"},
          %{name: "archived", disabled: true}
        ]}
        item="comment"
        shortcuts="letters"
      >
        <.questionnaire_progress context={questionnaire} />
        <.questionnaire_item
          :let={question}
          context={questionnaire}
          name="rating"
          required
          multiple={false}
          invalid={false}
        >
          <.questionnaire_title>How was your visit?</.questionnaire_title>
          <.questionnaire_description id="questionnaire-b-rating-description">
            Choose an answer.
          </.questionnaire_description>
          <.questionnaire_choices context={question}>
            <.questionnaire_choice context={question} value="good" index={0}>
              Good<.questionnaire_choice_description>
                A pleasant visit.
              </.questionnaire_choice_description>
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="great" index={1}>
              Great
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
              Unavailable
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error context={question} id="questionnaire-b-rating-error" />
        </.questionnaire_item>
        <.questionnaire_item :let={question} context={questionnaire} name="comment">
          <.questionnaire_title>Anything to add?</.questionnaire_title>
          <.questionnaire_input
            context={question}
            id="questionnaire-b-comment-input"
            value="Thanks!"
            placeholder="Your feedback"
          />
          <.questionnaire_error context={question} id="questionnaire-b-comment-error" />
        </.questionnaire_item>
        <.questionnaire_item context={questionnaire} name="archived" disabled>
          <.questionnaire_title>Archived question</.questionnaire_title>
        </.questionnaire_item>
        <.questionnaire_actions>
          <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
            questionnaire
          } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
            questionnaire
          } />
        </.questionnaire_actions>
      </.questionnaire>
    </div>
    """
  end

  def render_fixture("questionnaire-selected-choice") do
    assigns = %{}

    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-selected"
      items={[%{name: "color", choices: [%{value: "red"}, %{value: "blue"}]}]}
      shortcuts="numbers"
    >
      <.questionnaire_item :let={question} context={questionnaire} name="color">
        <.questionnaire_title>Color</.questionnaire_title><.questionnaire_choices context={question}>
          <.questionnaire_choice context={question} value="red" checked index={0}>
            Red
          </.questionnaire_choice><.questionnaire_choice
            context={question}
            value="blue"
            default_checked
            index={1}
          >
            Blue
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_submit context={questionnaire} disabled />
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  def render_fixture("message-scroller-default-button") do
    assigns = %{}

    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="start">
      <.message_scroller id="stream-buttons" context={scroll}>
        <.message_scroller_button /><.message_scroller_button direction="start" />
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("questionnaire-input-states") do
    assigns = %{}

    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-inputs"
      items={[%{name: "email", required: true}]}
      no_validate={false}
    >
      <.questionnaire_item :let={question} context={questionnaire} name="email" required>
        <.questionnaire_title>Your email</.questionnaire_title><.questionnaire_input
          context={question}
          id="questionnaire-email"
          type="email"
          placeholder="you@example.com"
          required
        /><.questionnaire_input context={question} id="questionnaire-locked" value="locked" disabled /><.questionnaire_error
          context={question}
          id="questionnaire-email-error"
        />
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  def render_fixture("radio-group") do
    assigns = %{}

    ~H"""
    <.radio_group :let={group} id="density" default_value="comfortable">
      <div class="flex items-center space-x-2">
        <.radio_group_item context={group} value="default" id="r1" /><.label for="r1">Default</.label>
      </div>
      <div class="flex items-center space-x-2">
        <.radio_group_item context={group} value="comfortable" id="r2" /><.label for="r2">
          Comfortable
        </.label>
      </div>
    </.radio_group>
    """
  end

  def render_fixture("radio-group-required-vertical") do
    assigns = %{}

    ~H"""
    <form id="shipping-form" class="grid gap-4">
      <.radio_group
        :let={group}
        id="shipping"
        name="shipping"
        required
        orientation="vertical"
        default_value="standard"
      >
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="standard" value="standard" class="peer" /><.label for="standard">
            Standard
          </.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="express" value="express" disabled class="peer" /><.label for="express">
            Express
          </.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="overnight" value="overnight" class="peer" /><.label for="overnight">
            Overnight
          </.label>
        </div>
      </.radio_group><.button type="submit" class="justify-self-start">Submit shipping</.button><output
        aria-live="polite"
        class="text-sm text-muted-foreground"
      >Submitted shipping: none</output>
    </form>
    """
  end

  def render_fixture("radio-group-controlled") do
    assigns = %{}

    ~H"""
    <.radio_group
      :let={group}
      id="plan"
      name="plan"
      value="pro"
      orientation="horizontal"
      loop={false}
      dir="rtl"
      on_value_change="shadcn:selection-change"
    >
      <.radio_group_item context={group} id="basic-plan" value="basic" aria-label="Basic" /><.radio_group_item
        context={group}
        id="pro-plan"
        value="pro"
        aria-label="Pro"
      />
    </.radio_group>
    """
  end

  def render_fixture("radio-group-disabled-external-form") do
    assigns = %{}

    ~H"""
    <div>
      <form id="external-radio-form"></form><.radio_group
        :let={group}
        id="disabled-radios"
        name="choice"
        form="external-radio-form"
        disabled
        default_value="yes"
      >
        <.radio_group_item context={group} id="disabled-yes" value="yes" /><.radio_group_item
          context={group}
          id="disabled-no"
          value="no"
        />
      </.radio_group>
    </div>
    """
  end

  def render_fixture("radio-group-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.radio_group :let={group} id="first-radio" default_value="b">
        <.radio_group_item context={group} id="first-radio-a" value="a" /><.radio_group_item
          context={group}
          id="first-radio-b"
          value="b"
        />
      </.radio_group><.radio_group :let={group} id="second-radio">
        <.radio_group_item context={group} id="second-radio-a" value="a" /><.radio_group_item
          context={group}
          id="second-radio-b"
          value="b"
        />
      </.radio_group>
    </div>
    """
  end

  def render_fixture("toggle-group") do
    assigns = %{}

    ~H"""
    <.toggle_group :let={group} id="formatting" type="multiple">
      <.toggle_group_item context={group} id="format-bold" value="bold" aria-label="Toggle bold">
        B
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="format-italic"
        value="italic"
        aria-label="Toggle italic"
      >
        I
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="format-underline"
        value="underline"
        aria-label="Toggle underline"
      >
        U
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle-group-single-vertical") do
    assigns = %{}

    ~H"""
    <.toggle_group
      :let={group}
      id="alignment"
      type="single"
      default_value="center"
      orientation="vertical"
      spacing={0}
      variant="outline"
      size="sm"
    >
      <.toggle_group_item context={group} id="align-left" value="left" aria-label="Left">
        L
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="align-center"
        value="center"
        aria-label="Center"
      >
        C
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="align-right"
        value="right"
        aria-label="Right"
        disabled
      >
        R
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle-group-multiple-default") do
    assigns = %{}

    ~H"""
    <.toggle_group
      :let={group}
      id="styles"
      type="multiple"
      default_value={["bold", "italic"]}
      spacing={3}
      size="lg"
    >
      <.toggle_group_item context={group} id="styles-bold" value="bold">B</.toggle_group_item><.toggle_group_item
        context={group}
        id="styles-italic"
        value="italic"
      >
        I
      </.toggle_group_item><.toggle_group_item context={group} id="styles-underline" value="underline">
        U
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle-group-controlled") do
    assigns = %{}

    ~H"""
    <.toggle_group
      :let={group}
      id="controlled-format"
      type="multiple"
      value={["bold"]}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="controlled-bold" value="bold">B</.toggle_group_item><.toggle_group_item
        context={group}
        id="controlled-italic"
        value="italic"
      >
        I
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle-group-disabled") do
    assigns = %{}

    ~H"""
    <.toggle_group
      :let={group}
      id="disabled-toggles"
      type="single"
      disabled
      default_value="one"
      roving_focus={false}
    >
      <.toggle_group_item context={group} id="disabled-toggle-one" value="one">
        One
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="disabled-toggle-two"
        value="two"
        variant="outline"
        size="sm"
      >
        Two
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle-group-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.toggle_group :let={group} id="first-toggle" type="single" default_value="x">
        <.toggle_group_item context={group} id="first-toggle-x" value="x">X</.toggle_group_item><.toggle_group_item
          context={group}
          id="first-toggle-y"
          value="y"
        >
          Y
        </.toggle_group_item>
      </.toggle_group><.toggle_group
        :let={group}
        id="second-toggle"
        type="multiple"
        default_value={["y"]}
        dir="rtl"
        loop={false}
      >
        <.toggle_group_item context={group} id="second-toggle-x" value="x">X</.toggle_group_item><.toggle_group_item
          context={group}
          id="second-toggle-y"
          value="y"
        >
          Y
        </.toggle_group_item>
      </.toggle_group>
    </div>
    """
  end

  def render_fixture("menubar") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="app-menu">
      <.menubar_menu id="app-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>New Tab</.menubar_item><.menubar_item>New Window</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("menubar-default-open") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="open-menu" default_value="file">
      <.menubar_menu id="open-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_label>Workspace</.menubar_label><.menubar_item>
              New Tab<.menubar_shortcut>⌘T</.menubar_shortcut>
            </.menubar_item><.menubar_item disabled>Unavailable</.menubar_item><.menubar_separator /><.menubar_item
              inset
              variant="destructive"
            >
              Delete
            </.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu><.menubar_menu id="open-edit" context={bar} value="edit">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>Edit</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>Undo</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("menubar-controlled") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="controlled-menu" value="edit" on_value_change="shadcn:menubar-change">
      <.menubar_menu id="controlled-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>New</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu><.menubar_menu id="controlled-edit" context={bar} value="edit">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>Edit</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>Undo</.menubar_item><.menubar_item>Redo</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("menubar-check-radio-submenu") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="view-menu" default_value="view">
      <.menubar_menu id="view-options" context={bar} value="view">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>View</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_checkbox_item id="show-status" checked>Show status</.menubar_checkbox_item><.menubar_checkbox_item
              id="show-panel"
              checked={false}
              disabled
            >
              Show panel
            </.menubar_checkbox_item><.menubar_checkbox_item id="mixed-panel" checked="indeterminate">
              Mixed panel
            </.menubar_checkbox_item><.menubar_radio_group :let={radio} id="theme-menu" value="light">
              <.menubar_radio_item context={radio} id="theme-light" value="light">
                Light
              </.menubar_radio_item><.menubar_radio_item context={radio} id="theme-dark" value="dark">
                Dark
              </.menubar_radio_item>
            </.menubar_radio_group><.menubar_sub id="more-options">
              <:trigger :let={sub}>
                <.menubar_sub_trigger context={sub}>More</.menubar_sub_trigger>
              </:trigger><:content :let={sub}>
                <.menubar_sub_content context={sub}>
                  <.menubar_item>Details</.menubar_item>
                </.menubar_sub_content>
              </:content>
            </.menubar_sub>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("menubar-multiple-disabled") do
    assigns = %{}

    ~H"""
    <div>
      <.menubar :let={bar} id="first-menu" loop={false}>
        <.menubar_menu id="first-file" context={bar} value="file">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>File</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>New</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu><.menubar_menu id="first-locked" context={bar} value="locked">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu} disabled>Locked</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>Locked action</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
      </.menubar><.menubar :let={bar} id="second-menu" dir="rtl" default_value="help">
        <.menubar_menu id="second-help" context={bar} value="help">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>Help</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>About</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
      </.menubar>
    </div>
    """
  end

  def render_fixture("menubar-submenu-open") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="submenu-open" default_value="file">
      <.menubar_menu id="submenu-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_sub id="submenu-more" open>
              <:trigger :let={sub}>
                <.menubar_sub_trigger context={sub}>More</.menubar_sub_trigger>
              </:trigger><:content :let={sub}>
                <.menubar_sub_content context={sub}>
                  <.menubar_item>Details</.menubar_item>
                </.menubar_sub_content>
              </:content>
            </.menubar_sub>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("menubar-explicit-relations") do
    assigns = %{}

    ~H"""
    <.menubar :let={bar} id="explicit-menu" default_value="file">
      <.menubar_menu
        id="explicit-file"
        trigger_id="explicit-file-trigger"
        content_id="explicit-file-content"
        context={bar}
        value="file"
      >
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu} align="end" side_offset={12} align_offset={0}>
            <.menubar_item>New</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("checkbox") do
    assigns = %{}

    ~H"""
    <div class="flex items-center space-x-2">
      <.checkbox id="terms" /><label for="terms" class="text-sm font-medium leading-none">Accept terms</label>
    </div>
    """
  end

  def render_fixture("checkbox-false-enabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-false-enabled-form">
      <.checkbox
        id="checkbox-false-enabled"
        checked={false}
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-false-disabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-false-disabled-form">
      <.checkbox
        id="checkbox-false-disabled"
        checked={false}
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-true-enabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-true-enabled-form">
      <.checkbox
        id="checkbox-true-enabled"
        checked={true}
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-true-disabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-true-disabled-form">
      <.checkbox
        id="checkbox-true-disabled"
        checked={true}
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-indeterminate-enabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-indeterminate-enabled-form">
      <.checkbox
        id="checkbox-indeterminate-enabled"
        checked="indeterminate"
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-indeterminate-disabled") do
    assigns = %{}

    ~H"""
    <form id="checkbox-indeterminate-disabled-form">
      <.checkbox
        id="checkbox-indeterminate-disabled"
        checked="indeterminate"
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("checkbox-multiple-external-form") do
    assigns = %{}

    ~H"""
    <div>
      <form id="checkbox-external"><button type="reset">Reset permissions</button></form><.checkbox
        id="permission-read"
        default_checked={true}
        name="permissions[]"
        value="read"
        form="checkbox-external"
        aria-label="Read"
      /><.checkbox
        id="permission-write"
        name="permissions[]"
        value="write"
        form="checkbox-external"
        aria-label="Write"
      />
    </div>
    """
  end

  def render_fixture("switch") do
    assigns = %{}

    ~H"""
    <.switch id="airplane-mode" />
    """
  end

  def render_fixture("switch-default-false-enabled") do
    assigns = %{}

    ~H"""
    <form id="switch-default-false-enabled-form">
      <.switch
        id="switch-default-false-enabled"
        size="default"
        checked={false}
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-default-false-disabled") do
    assigns = %{}

    ~H"""
    <form id="switch-default-false-disabled-form">
      <.switch
        id="switch-default-false-disabled"
        size="default"
        checked={false}
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-default-true-enabled") do
    assigns = %{}

    ~H"""
    <form id="switch-default-true-enabled-form">
      <.switch
        id="switch-default-true-enabled"
        size="default"
        checked={true}
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-default-true-disabled") do
    assigns = %{}

    ~H"""
    <form id="switch-default-true-disabled-form">
      <.switch
        id="switch-default-true-disabled"
        size="default"
        checked={true}
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-sm-false-enabled") do
    assigns = %{}

    ~H"""
    <form id="switch-sm-false-enabled-form">
      <.switch
        id="switch-sm-false-enabled"
        size="sm"
        checked={false}
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-sm-false-disabled") do
    assigns = %{}

    ~H"""
    <form id="switch-sm-false-disabled-form">
      <.switch
        id="switch-sm-false-disabled"
        size="sm"
        checked={false}
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-sm-true-enabled") do
    assigns = %{}

    ~H"""
    <form id="switch-sm-true-enabled-form">
      <.switch
        id="switch-sm-true-enabled"
        size="sm"
        checked={true}
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-sm-true-disabled") do
    assigns = %{}

    ~H"""
    <form id="switch-sm-true-disabled-form">
      <.switch
        id="switch-sm-true-disabled"
        size="sm"
        checked={true}
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("switch-multiple-external-form") do
    assigns = %{}

    ~H"""
    <div>
      <form id="switch-settings"><button type="reset">Reset settings</button></form><.switch
        id="switch-mail"
        default_checked={true}
        name="mail"
        form="switch-settings"
        aria-label="Mail"
      /><.switch id="switch-sms" size="sm" name="sms" form="switch-settings" aria-label="SMS" />
    </div>
    """
  end

  def render_fixture("slider") do
    assigns = %{}

    ~H"""
    <.slider id="slider-base" default_value={[50]} max={100} step={1} class="w-[60%]" />
    """
  end

  def render_fixture("slider-lower-bound") do
    assigns = %{}

    ~H"""
    <form id="slider-lower-bound-form">
      <.slider
        id="slider-lower-bound"
        min={-10}
        max={10}
        step={0.5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[-10]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-upper-bound") do
    assigns = %{}

    ~H"""
    <form id="slider-upper-bound-form">
      <.slider
        id="slider-upper-bound"
        min={-10}
        max={10}
        step={0.5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[10]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-range") do
    assigns = %{}

    ~H"""
    <form id="slider-range-form">
      <.slider
        id="slider-range"
        min={10}
        max={90}
        step={5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[20, 80]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-three-thumbs") do
    assigns = %{}

    ~H"""
    <form id="slider-three-thumbs-form">
      <.slider
        id="slider-three-thumbs"
        min={0}
        max={100}
        step={10}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[10, 40, 80]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-vertical") do
    assigns = %{}

    ~H"""
    <form id="slider-vertical-form">
      <.slider
        id="slider-vertical"
        min={0}
        max={50}
        step={5}
        orientation="vertical"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[25]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-rtl") do
    assigns = %{}

    ~H"""
    <form id="slider-rtl-form">
      <.slider
        id="slider-rtl"
        min={0}
        max={100}
        step={5}
        orientation="horizontal"
        dir="rtl"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[15, 70]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-inverted") do
    assigns = %{}

    ~H"""
    <form id="slider-inverted-form">
      <.slider
        id="slider-inverted"
        min={0}
        max={100}
        step={5}
        orientation="horizontal"
        dir="ltr"
        inverted={true}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[35]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-disabled") do
    assigns = %{}

    ~H"""
    <form id="slider-disabled-form">
      <.slider
        id="slider-disabled"
        min={0}
        max={90}
        step={3}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={true}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={[30, 60]}
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("slider-default-extents") do
    assigns = %{}

    ~H"""
    <.slider id="slider-default-extents" min={10} max={30} />
    """
  end

  def render_fixture("slider-multiple-instances") do
    assigns = %{}

    ~H"""
    <form id="slider-multiple-form" class="w-64 space-y-4">
      <.slider id="slider-price" default_value={[5, 15]} min={0} max={20} step={1} name="price" /><.slider
        id="slider-rating"
        default_value={[3]}
        min={1}
        max={5}
        step={1}
        name="rating"
      />
    </form>
    """
  end

  def render_fixture("slider-external-form") do
    assigns = %{}

    ~H"""
    <div>
      <form id="slider-external-form"></form><.slider
        id="slider-external"
        class="w-64"
        default_value={[2]}
        min={0}
        max={10}
        step={0.25}
        name="quantity"
        form="slider-external-form"
      />
    </div>
    """
  end

  def render_fixture("slider-minimum-thumb-distance") do
    assigns = %{}

    ~H"""
    <.slider
      id="slider-thumb-distance"
      value={[20, 60]}
      min={0}
      max={100}
      step={5}
      min_steps_between_thumbs={2}
    />
    """
  end

  def render_fixture("collapsible") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-base" open={true}>
      <.collapsible_trigger context={context} class="px-4 py-2 text-sm font-medium">
        Toggle Details
      </.collapsible_trigger><.collapsible_content context={context} class="px-4 py-2 text-sm">
        Here is collapsible content.
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-closed-enabled") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-closed-enabled" open={false} disabled={false}>
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-closed-disabled") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-closed-disabled" open={false} disabled={true}>
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-open-enabled") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-open-enabled" open={true} disabled={false}>
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-open-disabled") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-open-disabled" open={true} disabled={true}>
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-force-mount") do
    assigns = %{}

    ~H"""
    <.collapsible :let={context} id="collapsible-forced" open={false}>
      <.collapsible_trigger context={context}>More</.collapsible_trigger><.collapsible_content
        context={context}
        force_mount={true}
      >
        Always mounted
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("collapsible-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.collapsible :let={context} id="details-one" open={true}>
        <.collapsible_trigger context={context}>One</.collapsible_trigger><.collapsible_content context={
          context
        }>
          First
        </.collapsible_content>
      </.collapsible><.collapsible :let={context} id="details-two" open={false}>
        <.collapsible_trigger context={context}>Two</.collapsible_trigger><.collapsible_content context={
          context
        }>
          Second
        </.collapsible_content>
      </.collapsible>
    </div>
    """
  end

  def render_fixture("navigation-menu") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-base">
      <.navigation_menu_list context={context}>
        <.navigation_menu_item context={context} value="docs">
          <.navigation_menu_link href="/docs">Documentation</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-inline-closed") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-inline-closed" value="" viewport={false}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-inline-docs") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-inline-docs" value="docs" viewport={false}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-inline-about") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-inline-about" value="about" viewport={false}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-viewport-closed") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-viewport-closed" value="" viewport={true}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-viewport-docs") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-viewport-docs" value="docs" viewport={true}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-viewport-about") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-viewport-about" value="about" viewport={true}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-vertical-rtl-disabled") do
    assigns = %{}

    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-vertical"
      orientation="vertical"
      dir="rtl"
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="locked">
          <.navigation_menu_trigger context={item} disabled>Locked</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            Unavailable
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="active">
          <.navigation_menu_link active href="/active">Active</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-force-mount") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-forced" viewport={false}>
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content
            context={item}
            force_mount={true}
          >
            Mounted docs
          </.navigation_menu_content>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("navigation-multiple-instances") do
    assigns = %{}

    ~H"""
    <div>
      <.navigation_menu :let={context} id="navigation-primary" viewport={false} value="docs">
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
              item
            }>
              <.navigation_menu_link href="/docs">Guide</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu><.navigation_menu
        :let={context}
        id="navigation-secondary"
        viewport={false}
        value=""
      >
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
              item
            }>
              <.navigation_menu_link href="/docs">Guide</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu>
    </div>
    """
  end

  def render_fixture("navigation-indicator") do
    assigns = %{}

    ~H"""
    <.navigation_menu :let={context} id="navigation-indicator" value="docs" viewport={false}>
      <:indicator /><.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            Guide
          </.navigation_menu_content>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("button-default-default") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="default" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-xs") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-sm") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-lg") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-icon") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="icon" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-default-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="default" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-default") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="default" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-xs") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-sm") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-lg") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-icon") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="icon" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-outline-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="outline" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-default") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="default" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-xs") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-sm") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-lg") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-icon") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="icon" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-secondary-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="secondary" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-default") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="default" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-xs") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-sm") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-lg") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-icon") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="icon" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-ghost-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="ghost" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-destructive-default") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="default" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-xs") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="xs" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-sm") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="sm" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-lg") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="lg" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-icon") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="icon" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="icon-xs" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="icon-sm" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-destructive-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="destructive" size="icon-lg" disabled={true}>Save</.button>
    """
  end

  def render_fixture("button-link-default") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="default" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-xs") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-sm") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-lg") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-icon") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="icon" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-icon-xs") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-icon-sm") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def render_fixture("button-link-icon-lg") do
    assigns = %{}

    ~H"""
    <.button variant="link" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def render_fixture("badge-default") do
    assigns = %{}

    ~H"""
    <.badge variant="default">Status</.badge>
    """
  end

  def render_fixture("badge-secondary") do
    assigns = %{}

    ~H"""
    <.badge variant="secondary">Status</.badge>
    """
  end

  def render_fixture("badge-destructive") do
    assigns = %{}

    ~H"""
    <.badge variant="destructive">Status</.badge>
    """
  end

  def render_fixture("badge-outline") do
    assigns = %{}

    ~H"""
    <.badge variant="outline">Status</.badge>
    """
  end

  def render_fixture("badge-ghost") do
    assigns = %{}

    ~H"""
    <.badge variant="ghost">Status</.badge>
    """
  end

  def render_fixture("badge-link") do
    assigns = %{}

    ~H"""
    <.badge variant="link">Status</.badge>
    """
  end

  def render_fixture("toggle-default-default-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-default-false" variant="default" size="default" pressed={false}>
      Bold
    </.toggle>
    """
  end

  def render_fixture("toggle-default-default-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-default-true" variant="default" size="default" pressed={true}>
      Bold
    </.toggle>
    """
  end

  def render_fixture("toggle-default-sm-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-sm-false" variant="default" size="sm" pressed={false}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-default-sm-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-sm-true" variant="default" size="sm" pressed={true}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-default-lg-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-lg-false" variant="default" size="lg" pressed={false}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-default-lg-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-default-lg-true" variant="default" size="lg" pressed={true}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-outline-default-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-default-false" variant="outline" size="default" pressed={false}>
      Bold
    </.toggle>
    """
  end

  def render_fixture("toggle-outline-default-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-default-true" variant="outline" size="default" pressed={true}>
      Bold
    </.toggle>
    """
  end

  def render_fixture("toggle-outline-sm-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-sm-false" variant="outline" size="sm" pressed={false}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-outline-sm-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-sm-true" variant="outline" size="sm" pressed={true}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-outline-lg-off") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-lg-false" variant="outline" size="lg" pressed={false}>Bold</.toggle>
    """
  end

  def render_fixture("toggle-outline-lg-on") do
    assigns = %{}

    ~H"""
    <.toggle id="toggle-outline-lg-true" variant="outline" size="lg" pressed={true}>Bold</.toggle>
    """
  end

  def render_fixture("card-small") do
    assigns = %{}

    ~H"""
    <.card size="sm">
      <.card_content>Compact content</.card_content>
    </.card>
    """
  end

  def render_fixture("input-invalid-disabled") do
    assigns = %{}

    ~H"""
    <.input
      id="disabled-input"
      name="email"
      type="email"
      value="onni@example.test"
      disabled
      aria-invalid="true"
      class="w-72"
    />
    """
  end

  def render_fixture("textarea-native-form") do
    assigns = %{}

    ~H"""
    <.textarea id="notes" name="notes" readonly rows="3">Saved notes</.textarea>
    """
  end

  def render_fixture("alert") do
    assigns = %{}

    ~H"""
    <.alert>
      <.alert_title>Heads up!</.alert_title>
      <.alert_description>You can add components to your app using the cli.</.alert_description>
    </.alert>
    """
  end

  def render_fixture("aspect-ratio") do
    assigns = %{}

    ~H"""
    <.aspect_ratio ratio={16 / 9} class="bg-muted flex items-center justify-center">
      <span>16:9 Aspect Ratio</span>
    </.aspect_ratio>
    """
  end

  def render_fixture("attachment") do
    assigns = %{}

    ~H"""
    <.attachment>
      <.attachment_title>document.pdf</.attachment_title>
      <.attachment_description>2.4 MB</.attachment_description>
    </.attachment>
    """
  end

  def render_fixture("avatar") do
    assigns = %{}

    ~H"""
    <.avatar>
      <.avatar_fallback>CN</.avatar_fallback>
    </.avatar>
    """
  end

  def render_fixture("badge") do
    assigns = %{}

    ~H"""
    <.badge variant="secondary">New Feature</.badge>
    """
  end

  def render_fixture("breadcrumb") do
    assigns = %{}

    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="/">Home</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Components</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  def render_fixture("bubble") do
    assigns = %{}

    ~H"""
    <.bubble>
      <.bubble_content>Hello from bubble chat!</.bubble_content>
    </.bubble>
    """
  end

  def render_fixture("button-group") do
    assigns = %{}

    ~H"""
    <.button_group>
      <.button variant="outline">Left</.button>
      <.button variant="outline">Middle</.button>
      <.button variant="outline">Right</.button>
    </.button_group>
    """
  end

  def render_fixture("button") do
    assigns = %{}

    ~H"""
    <.button variant="default">Click me</.button>
    """
  end

  def render_fixture("card") do
    assigns = %{}

    ~H"""
    <.card>
      <.card_header>
        <.card_title>Notifications</.card_title>
        <.card_description>You have 3 unread messages.</.card_description>
      </.card_header>
      <.card_content>
        <p>Everything looks good today.</p>
      </.card_content>
      <.card_footer>
        <.button class="w-full">Mark all as read</.button>
      </.card_footer>
    </.card>
    """
  end

  def render_fixture("direction") do
    assigns = %{}

    ~H"""
    <.direction_provider dir="ltr">
      <div class="p-2 text-sm">Left to right layout</div>
    </.direction_provider>
    """
  end

  def render_fixture("empty") do
    assigns = %{}

    ~H"""
    <.empty>
      <.empty_header>
        <.empty_title>No data available</.empty_title>
        <.empty_description>Get started by creating your first project.</.empty_description>
      </.empty_header>
    </.empty>
    """
  end

  def render_fixture("field") do
    assigns = %{}

    ~H"""
    <.field_set class="w-full max-w-md">
      <.field_group>
        <.field>
          <.field_label for="field-email">Email address</.field_label>
          <.input
            id="field-email"
            type="email"
            placeholder="m@example.com"
            aria-describedby="field-help"
          />
          <.field_description id="field-help">We will never share your email.</.field_description>
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  def render_fixture("field-separator") do
    assigns = %{}

    ~H"""
    <.field_group class="w-full max-w-md">
      <.field_separator />
      <.field_separator class="*:data-[slot=field-separator-content]:bg-card">
        Or continue with
      </.field_separator>
    </.field_group>
    """
  end

  def render_fixture("input-group") do
    assigns = %{}

    ~H"""
    <.input_group>
      <.input_group_addon>https://</.input_group_addon>
      <.input_group_input placeholder="example.com" />
    </.input_group>
    """
  end

  def render_fixture("input") do
    assigns = %{}

    ~H"""
    <.input type="email" placeholder="Email" />
    """
  end

  def render_fixture("item") do
    assigns = %{}

    ~H"""
    <.item>
      <.item_content>
        <.item_title>Basic Item</.item_title>
        <.item_description>Item description text</.item_description>
      </.item_content>
    </.item>
    """
  end

  def render_fixture("kbd") do
    assigns = %{}

    ~H"""
    <.kbd>Ctrl + K</.kbd>
    """
  end

  def render_fixture("label") do
    assigns = %{}

    ~H"""
    <div>
      <.label for="test-input">Your email address</.label><.input id="test-input" type="email" />
    </div>
    """
  end

  def render_fixture("marker") do
    assigns = %{}

    ~H"""
    <.marker class="size-2 bg-emerald-500 rounded-full" />
    """
  end

  def render_fixture("message") do
    assigns = %{}

    ~H"""
    <.message>
      <.message_content>Hi, how can I help you today?</.message_content>
    </.message>
    """
  end

  def render_fixture("native-select") do
    assigns = %{}

    ~H"""
    <.native_select>
      <.native_select_option value="1">Option 1</.native_select_option>
      <.native_select_option value="2">Option 2</.native_select_option>
    </.native_select>
    """
  end

  def render_fixture("native-select-default-selection") do
    assigns = %{}

    ~H"""
    <form id="native-default-form">
      <label for="native-default">Fruit</label>
      <.native_select
        :let={selection}
        id="native-default"
        name="fruit"
        default_value="pear"
        required
        aria-describedby="native-default-help"
        class="w-48 min-w-24 max-w-64"
      >
        <.native_select_option value="" selected={"" in selection}>
          Choose fruit
        </.native_select_option>
        <.native_select_opt_group label="Fruit">
          <.native_select_option value="apple" selected={"apple" in selection}>
            Apple
          </.native_select_option>
          <.native_select_option value="pear" selected={"pear" in selection} class="font-medium">
            Pear
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
      <p id="native-default-help">Choose a fruit.</p>
      <button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("native-select-controlled-small") do
    assigns = %{}

    ~H"""
    <.native_select
      :let={selection}
      id="native-controlled"
      name="quantity"
      value={2}
      size="sm"
      aria-label="Quantity"
      aria-invalid="true"
      class="w-[180px]"
    >
      <.native_select_option value={1} selected={"1" in selection}>One</.native_select_option>
      <.native_select_option value={2} selected={"2" in selection}>Two</.native_select_option>
      <.native_select_option value={3} selected={"3" in selection} disabled>
        Three
      </.native_select_option>
    </.native_select>
    """
  end

  def render_fixture("native-select-disabled-groups") do
    assigns = %{}

    ~H"""
    <form>
      <.native_select
        :let={selection}
        id="native-disabled"
        name="region"
        disabled
        default_value="west"
        aria-label="Region"
      >
        <.native_select_opt_group label="Unavailable" disabled>
          <.native_select_option value="east" selected={"east" in selection}>
            East
          </.native_select_option>
        </.native_select_opt_group>
        <.native_select_opt_group label="Available">
          <.native_select_option value="west" selected={"west" in selection} label="Western region">
            West
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
    </form>
    """
  end

  def render_fixture("native-select-multiple-instances") do
    assigns = %{}

    ~H"""
    <form id="native-multiple-form">
      <.native_select
        :let={selection}
        id="native-multiple"
        name="colors"
        multiple
        default_value={["red", "blue"]}
        aria-label="Colors"
      >
        <.native_select_opt_group label="Colors">
          <.native_select_option value="red" selected={"red" in selection}>Red</.native_select_option>
          <.native_select_option value="green" selected={"green" in selection}>
            Green
          </.native_select_option>
          <.native_select_option value="blue" selected={"blue" in selection}>
            Blue
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
      <.native_select
        :let={selection}
        id="native-second"
        name="shape"
        default_value="square"
        aria-label="Shape"
      >
        <.native_select_option value="circle" selected={"circle" in selection}>
          Circle
        </.native_select_option>
        <.native_select_option value="square" selected={"square" in selection}>
          Square
        </.native_select_option>
      </.native_select>
      <button type="reset">Reset</button>
    </form>
    """
  end

  def render_fixture("native-select-empty-controlled") do
    assigns = %{}

    ~H"""
    <.native_select :let={selection} value="" name="empty-choice" aria-label="Empty choice">
      <.native_select_option value="other" selected={"other" in selection}>
        Other
      </.native_select_option>
      <.native_select_option value="" selected={"" in selection}>None</.native_select_option>
    </.native_select>
    """
  end

  def render_fixture("native-select-controlled-multiple") do
    assigns = %{}

    ~H"""
    <.native_select
      :let={selection}
      multiple
      value={["b", "c"]}
      name="letters"
      aria-label="Letters"
      size="sm"
    >
      <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
      <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
      <.native_select_option value="c" selected={"c" in selection}>C</.native_select_option>
    </.native_select>
    """
  end

  def render_fixture("native-select-external-form-empty-multiple") do
    assigns = %{}

    ~H"""
    <div>
      <form id="native-external-form"><button type="reset">Reset</button></form>
      <.native_select
        :let={selection}
        id="native-external"
        form="native-external-form"
        name="external-choices"
        multiple
        default_value={[]}
        aria-label="External choices"
      >
        <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
        <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
      </.native_select>
    </div>
    """
  end

  def render_fixture("pagination") do
    assigns = %{}

    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous href="#" />
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#" is_active={true}>1</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_next href="#" />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  def render_fixture("progress") do
    assigns = %{}

    ~H"""
    <.progress value={60} class="w-[60%]" />
    """
  end

  def render_fixture("progress-absent") do
    assigns = %{}

    ~H"""
    <.progress />
    """
  end

  def render_fixture("progress-null") do
    assigns = %{}

    ~H"""
    <.progress value={nil} />
    """
  end

  def render_fixture("progress-zero") do
    assigns = %{}

    ~H"""
    <.progress value={0} />
    """
  end

  def render_fixture("progress-fractional") do
    assigns = %{}

    ~H"""
    <.progress value={25.5} />
    """
  end

  def render_fixture("progress-complete") do
    assigns = %{}

    ~H"""
    <.progress value={100} />
    """
  end

  def render_fixture("progress-custom-max") do
    assigns = %{}

    ~H"""
    <.progress value={50} max={200} />
    """
  end

  def render_fixture("progress-null-max") do
    assigns = %{}

    ~H"""
    <.progress value={40} max={nil} />
    """
  end

  def render_fixture("progress-outside-visual-range") do
    assigns = %{}

    ~H"""
    <.progress value={125} max={80} />
    """
  end

  def render_fixture("progress-custom-class-aria") do
    assigns = %{}

    ~H"""
    <.progress
      value={75}
      class="w-[180px] min-w-24 max-w-64 h-2 bg-primary"
      id="upload-progress"
      aria-label="Upload"
      aria-valuetext="Uploading"
    />
    """
  end

  def render_fixture("scroll-area") do
    assigns = %{}

    ~H"""
    <.scroll_area id="scroll-area-demo" class="h-32 w-48 rounded-md border p-4">
      <div :for={n <- 1..20} class="py-2">Item {n}</div>
    </.scroll_area>
    """
  end

  def render_fixture("separator") do
    assigns = %{}

    ~H"""
    <.separator class="my-4" />
    """
  end

  def render_fixture("skeleton") do
    assigns = %{}

    ~H"""
    <.skeleton class="h-4 w-[250px]" />
    """
  end

  def render_fixture("sonner") do
    assigns = %{}

    ~H"""
    <.toaster />
    """
  end

  def render_fixture("spinner") do
    assigns = %{}

    ~H"""
    <.spinner class="size-6 text-primary" />
    """
  end

  def render_fixture("table") do
    assigns = %{}

    ~H"""
    <.table>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">Invoice</.table_head>
          <.table_head>Status</.table_head>
          <.table_head class="text-right">Amount</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row>
          <.table_cell class="font-medium">INV001</.table_cell>
          <.table_cell>Paid</.table_cell>
          <.table_cell class="text-right">$250.00</.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  def render_fixture("textarea") do
    assigns = %{}

    ~H"""
    <.textarea placeholder="Type your message here." />
    """
  end

  def render_fixture("toggle") do
    assigns = %{}

    ~H"""
    <.toggle id="italic-toggle" aria-label="Toggle italic">B</.toggle>
    """
  end

  def render_fixture(_), do: nil

  attr :fixture, :string, required: true
  attr :state, :map, required: true
  attr :form_data, :map, required: true
  @doc "Renders a connected fixture using the caller's tracked state and submitted form data."

  def live_fixture(%{fixture: "accordion"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-demo"
      type="single"
      value={Map.get(@state, "accordion-demo", "item-1")}
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="item-1" disabled={false}>
        <.accordion_trigger context={item}>Is it accessible?</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Yes. It adheres to the WAI-ARIA design pattern.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-closed"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-closed-demo"
      type="single"
      value={Map.get(@state, "accordion-closed-demo", nil)}
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-selected-details"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-details-demo"
      type="single"
      value={Map.get(@state, "accordion-details-demo", "details")}
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-multiple"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-multiple-demo"
      type="multiple"
      value={Map.get(@state, "accordion-multiple-demo", ["intro", "advanced"])}
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-disabled"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-disabled-demo"
      type="single"
      value={Map.get(@state, "accordion-disabled-demo", "intro")}
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={true}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    <.accordion
      :let={accordion}
      id="accordion-disabled-root"
      type="single"
      value={Map.get(@state, "accordion-disabled-root", "details")}
      collapsible={false}
      disabled={true}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-force-mount"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-force-demo"
      type="single"
      value={Map.get(@state, "accordion-force-demo", nil)}
      collapsible={true}
      disabled={false}
      orientation="horizontal"
      dir="rtl"
      class="max-w-lg"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Read the details.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={true} class="text-muted-foreground">
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "accordion-instances"} = assigns) do
    ~H"""
    <.accordion
      :let={accordion}
      id="accordion-first"
      type="single"
      value={Map.get(@state, "accordion-first", "intro")}
      collapsible={false}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    <.accordion
      :let={accordion}
      id="accordion-second"
      type="single"
      value={Map.get(@state, "accordion-second", "details")}
      collapsible={true}
      disabled={false}
      orientation="vertical"
      dir="ltr"
    >
      <.accordion_item :let={item} context={accordion} value="intro" disabled={false}>
        <.accordion_trigger context={item}>Introduction</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Start with an introduction.
        </.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="details" disabled={false}>
        <.accordion_trigger context={item}>Details</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>Read the details.</.accordion_content>
      </.accordion_item>
      <.accordion_item :let={item} context={accordion} value="advanced" disabled={false}>
        <.accordion_trigger context={item}>Advanced</.accordion_trigger>
        <.accordion_content context={item} force_mount={false}>
          Explore advanced settings.
        </.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def live_fixture(%{fixture: "tabs"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-demo"
      value={Map.get(@state, "tabs-demo", "account")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
      class="w-[400px]"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="account" disabled={false}>Account</.tabs_trigger>
        <.tabs_trigger context={tabs} value="password" disabled={false}>Password</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="account" force_mount={false}>
        Make changes to your account here.
      </.tabs_content>
      <.tabs_content context={tabs} value="password" force_mount={false}>
        Change your password here.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-history"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-history-demo"
      value={Map.get(@state, "tabs-history-demo", "history")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-unselected"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-unselected-demo"
      value={Map.get(@state, "tabs-unselected-demo", nil)}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-disabled"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-disabled-demo"
      value={Map.get(@state, "tabs-disabled-demo", "overview")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="manual"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={true}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-line-rtl"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-line-demo"
      value={Map.get(@state, "tabs-line-demo", "settings")}
      orientation="vertical"
      dir="rtl"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="line">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-force-mount"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-force-demo"
      value={Map.get(@state, "tabs-force-demo", "history")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={true} class="p-2">
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={true} class="p-2">
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={true} class="p-2">
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "tabs-instances"} = assigns) do
    ~H"""
    <.tabs
      :let={tabs}
      id="tabs-first"
      value={Map.get(@state, "tabs-first", "overview")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    <.tabs
      :let={tabs}
      id="tabs-second"
      value={Map.get(@state, "tabs-second", "settings")}
      orientation="horizontal"
      dir="ltr"
      activation_mode="automatic"
    >
      <.tabs_list context={tabs} variant="default">
        <.tabs_trigger context={tabs} value="overview" disabled={false}>Overview</.tabs_trigger>
        <.tabs_trigger context={tabs} value="history" disabled={false}>History</.tabs_trigger>
        <.tabs_trigger context={tabs} value="settings" disabled={false}>Settings</.tabs_trigger>
      </.tabs_list>
      <.tabs_content context={tabs} value="overview" force_mount={false}>
        View the overview.
      </.tabs_content>
      <.tabs_content context={tabs} value="history" force_mount={false}>
        View the history.
      </.tabs_content>
      <.tabs_content context={tabs} value="settings" force_mount={false}>
        Adjust settings.
      </.tabs_content>
    </.tabs>
    """
  end

  def live_fixture(%{fixture: "dialog"} = assigns) do
    ~H"""
    <.dialog id="dialog-demo" open={Map.get(@state, "dialog-demo", true)}>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-demo-title"
          aria-describedby="dialog-demo-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "dialog-closed"} = assigns) do
    ~H"""
    <.dialog id="dialog-closed-root" open={Map.get(@state, "dialog-closed-root", false)}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-closed-root-title"
          aria-describedby="dialog-closed-root-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "dialog-open-custom-ids"} = assigns) do
    ~H"""
    <.dialog
      id="profile-editor"
      open={Map.get(@state, "profile-editor", true)}
      title_id="profile-editor-heading"
      description_id="profile-editor-help"
    >
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="profile-editor-heading"
          aria-describedby="profile-editor-help"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "dialog-no-close-icon-footer-close"} = assigns) do
    ~H"""
    <.dialog id="dialog-footer" open={Map.get(@state, "dialog-footer", true)}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-footer-title"
          aria-describedby="dialog-footer-description"
          show_close_button={false}
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer context={modal} show_close_button={true}>
            <.button type="submit">Save changes</.button>
            <.dialog_close context={modal}>Dismiss</.dialog_close>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "dialog-nonmodal"} = assigns) do
    ~H"""
    <.dialog
      id="dialog-nonmodal-root"
      open={Map.get(@state, "dialog-nonmodal-root", true)}
      modal={false}
    >
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-nonmodal-root-title"
          aria-describedby="dialog-nonmodal-root-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "dialog-multiple-instances"} = assigns) do
    ~H"""
    <.dialog
      id="dialog-instance-a"
      open={Map.get(@state, "dialog-instance-a", true)}
      title_id="dialog-instance-a-heading"
      description_id="dialog-instance-a-help"
    >
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-instance-a-heading"
          aria-describedby="dialog-instance-a-help"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    <.dialog id="dialog-instance-b" open={Map.get(@state, "dialog-instance-b", false)}>
      <:trigger :let={modal}>
        <.dialog_trigger context={modal}>Edit profile</.dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.dialog_content
          context={modal}
          aria-labelledby="dialog-instance-b-title"
          aria-describedby="dialog-instance-b-description"
        >
          <.dialog_header>
            <.dialog_title context={modal}>Edit profile</.dialog_title>
            <.dialog_description context={modal}>
              Make changes to your profile here. Click save when you are done.
            </.dialog_description>
          </.dialog_header>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </:content>
    </.dialog>
    """
  end

  def live_fixture(%{fixture: "alert-dialog"} = assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-demo" open={Map.get(@state, "alert-dialog-demo", true)}>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-demo-title"
          aria-describedby="alert-dialog-demo-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def live_fixture(%{fixture: "alert-dialog-closed"} = assigns) do
    ~H"""
    <.alert_dialog
      id="alert-dialog-closed-root"
      open={Map.get(@state, "alert-dialog-closed-root", false)}
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-closed-root-title"
          aria-describedby="alert-dialog-closed-root-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def live_fixture(%{fixture: "alert-dialog-open-custom-ids"} = assigns) do
    ~H"""
    <.alert_dialog
      id="delete-confirmation"
      open={Map.get(@state, "delete-confirmation", true)}
      title_id="delete-confirmation-heading"
      description_id="delete-confirmation-help"
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="delete-confirmation-heading"
          aria-describedby="delete-confirmation-help"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def live_fixture(%{fixture: "alert-dialog-small-media"} = assigns) do
    ~H"""
    <.alert_dialog id="alert-dialog-small" open={Map.get(@state, "alert-dialog-small", true)}>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-small-title"
          aria-describedby="alert-dialog-small-description"
          size="sm"
        >
          <.alert_dialog_header>
            <.alert_dialog_media><span aria-hidden="true">!</span></.alert_dialog_media>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal} disabled variant="destructive" size="sm">
              Continue
            </.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def live_fixture(%{fixture: "alert-dialog-multiple-instances"} = assigns) do
    ~H"""
    <.alert_dialog
      id="alert-dialog-instance-a"
      open={Map.get(@state, "alert-dialog-instance-a", true)}
      title_id="alert-dialog-instance-a-heading"
      description_id="alert-dialog-instance-a-help"
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-instance-a-heading"
          aria-describedby="alert-dialog-instance-a-help"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    <.alert_dialog
      id="alert-dialog-instance-b"
      open={Map.get(@state, "alert-dialog-instance-b", false)}
    >
      <:trigger :let={modal}>
        <.alert_dialog_trigger context={modal}>Delete account</.alert_dialog_trigger>
      </:trigger>
      <:content :let={modal}>
        <.alert_dialog_content
          context={modal}
          aria-labelledby="alert-dialog-instance-b-title"
          aria-describedby="alert-dialog-instance-b-description"
          size="default"
        >
          <.alert_dialog_header>
            <.alert_dialog_title context={modal}>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description context={modal}>
              This action cannot be undone. This will permanently delete your account.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel context={modal}>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action context={modal}>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </:content>
    </.alert_dialog>
    """
  end

  def live_fixture(%{fixture: "drawer"} = assigns) do
    ~H"""
    <.drawer id="drawer-demo" open={Map.get(@state, "drawer-demo", true)} direction="bottom">
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-demo-title"
          aria-describedby="drawer-demo-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-closed"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-closed-root"
      open={Map.get(@state, "drawer-closed-root", false)}
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-closed-root-title"
          aria-describedby="drawer-closed-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-open-custom-ids"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-custom"
      open={Map.get(@state, "drawer-custom", true)}
      title_id="drawer-custom-heading"
      description_id="drawer-custom-help"
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-custom-heading"
          aria-describedby="drawer-custom-help"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-top"} = assigns) do
    ~H"""
    <.drawer id="drawer-top-panel" open={Map.get(@state, "drawer-top-panel", true)} direction="top">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-top-panel-title"
          aria-describedby="drawer-top-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-left"} = assigns) do
    ~H"""
    <.drawer id="drawer-left-panel" open={Map.get(@state, "drawer-left-panel", true)} direction="left">
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-left-panel-title"
          aria-describedby="drawer-left-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-right"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-right-panel"
      open={Map.get(@state, "drawer-right-panel", true)}
      direction="right"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-right-panel-title"
          aria-describedby="drawer-right-panel-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-nondismissible"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-nondismissible-root"
      open={Map.get(@state, "drawer-nondismissible-root", true)}
      dismissible={false}
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-nondismissible-root-title"
          aria-describedby="drawer-nondismissible-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-select"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-select-root"
      open={Map.get(@state, "drawer-select-root", true)}
      direction="bottom"
    >
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-select-root-title"
          aria-describedby="drawer-select-root-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <div class="p-4">
            <.select
              id="drawer-select-fruit"
              name="drawer-fruit"
              placeholder="Fruit"
              open={Map.get(@state, "drawer-select-fruit-open", false)}
              value={Map.get(@state, "drawer-select-fruit-value", nil)}
              on_change="shadcn:popup-change"
            >
              <:trigger :let={popup}>
                <.select_trigger context={popup}>
                  <.select_value context={popup} placeholder="Fruit" />
                </.select_trigger>
              </:trigger><:option id="drawer-select-fruit-apple" value="apple" label="Apple">
                Apple
              </:option><:option id="drawer-select-fruit-banana" value="banana" label="Banana">
                Banana
              </:option>
            </.select>
          </div>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "drawer-multiple-instances"} = assigns) do
    ~H"""
    <.drawer
      id="drawer-instance-a"
      open={Map.get(@state, "drawer-instance-a", true)}
      title_id="drawer-instance-a-heading"
      description_id="drawer-instance-a-help"
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-instance-a-heading"
          aria-describedby="drawer-instance-a-help"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    <.drawer
      id="drawer-instance-b"
      open={Map.get(@state, "drawer-instance-b", false)}
      direction="bottom"
    >
      <:trigger :let={modal}>
        <.drawer_trigger context={modal}>Open drawer</.drawer_trigger>
      </:trigger>
      <:content :let={modal}>
        <.drawer_content
          context={modal}
          aria-labelledby="drawer-instance-b-title"
          aria-describedby="drawer-instance-b-description"
        >
          <.drawer_header>
            <.drawer_title context={modal}>Drawer Title</.drawer_title>
            <.drawer_description context={modal}>Drawer Description goes here.</.drawer_description>
          </.drawer_header>
          <.drawer_footer>
            <.drawer_close context={modal}>Close drawer</.drawer_close>
          </.drawer_footer>
        </.drawer_content>
      </:content>
    </.drawer>
    """
  end

  def live_fixture(%{fixture: "sheet"} = assigns) do
    ~H"""
    <.sheet id="sheet-demo" open={Map.get(@state, "sheet-demo", true)}>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-demo-title"
          aria-describedby="sheet-demo-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-closed"} = assigns) do
    ~H"""
    <.sheet id="sheet-closed-root" open={Map.get(@state, "sheet-closed-root", false)}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-closed-root-title"
          aria-describedby="sheet-closed-root-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-open-custom-ids"} = assigns) do
    ~H"""
    <.sheet
      id="sheet-custom"
      open={Map.get(@state, "sheet-custom", true)}
      title_id="sheet-custom-heading"
      description_id="sheet-custom-help"
    >
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-custom-heading"
          aria-describedby="sheet-custom-help"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-top"} = assigns) do
    ~H"""
    <.sheet id="sheet-top-panel" open={Map.get(@state, "sheet-top-panel", true)}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-top-panel-title"
          aria-describedby="sheet-top-panel-description"
          side="top"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-bottom"} = assigns) do
    ~H"""
    <.sheet id="sheet-bottom-panel" open={Map.get(@state, "sheet-bottom-panel", true)}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-bottom-panel-title"
          aria-describedby="sheet-bottom-panel-description"
          side="bottom"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-left"} = assigns) do
    ~H"""
    <.sheet id="sheet-left-panel" open={Map.get(@state, "sheet-left-panel", true)}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-left-panel-title"
          aria-describedby="sheet-left-panel-description"
          side="left"
          show_close_button={false}
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
          <.sheet_footer>
            <.sheet_close context={modal}>Done</.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "sheet-multiple-instances"} = assigns) do
    ~H"""
    <.sheet
      id="sheet-instance-a"
      open={Map.get(@state, "sheet-instance-a", true)}
      title_id="sheet-instance-a-heading"
      description_id="sheet-instance-a-help"
    >
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-instance-a-heading"
          aria-describedby="sheet-instance-a-help"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    <.sheet id="sheet-instance-b" open={Map.get(@state, "sheet-instance-b", false)}>
      <:trigger :let={modal}>
        <.sheet_trigger context={modal}>Edit profile</.sheet_trigger>
      </:trigger>
      <:content :let={modal}>
        <.sheet_content
          context={modal}
          aria-labelledby="sheet-instance-b-title"
          aria-describedby="sheet-instance-b-description"
          side="right"
        >
          <.sheet_header>
            <.sheet_title context={modal}>Edit profile</.sheet_title>
            <.sheet_description context={modal}>
              Make changes to your profile here.
            </.sheet_description>
          </.sheet_header>
        </.sheet_content>
      </:content>
    </.sheet>
    """
  end

  def live_fixture(%{fixture: "context-menu"} = assigns) do
    ~H"""
    <.context_menu
      id="context-demo"
      open={Map.get(@state, "context-demo-open", false)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.context_menu_trigger
          context={popup}
          class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm"
        >
          Right click here
        </.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>Back</.context_menu_item><.context_menu_item>
            Forward
          </.context_menu_item><.context_menu_item>Reload</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def live_fixture(%{fixture: "context-menu-disabled"} = assigns) do
    ~H"""
    <.context_menu
      id="context-disabled"
      open={Map.get(@state, "context-disabled-open", false)}
      disabled
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>Unavailable</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item disabled>Unavailable action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def live_fixture(%{fixture: "context-menu-multiple"} = assigns) do
    ~H"""
    <.context_menu
      id="context-first"
      open={Map.get(@state, "context-first-open", false)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>first</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>first action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    <.context_menu
      id="context-second"
      open={Map.get(@state, "context-second-open", false)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.context_menu_trigger context={popup}>second</.context_menu_trigger>
      </:trigger><:content :let={popup}>
        <.context_menu_content context={popup}>
          <.context_menu_item>second action</.context_menu_item>
        </.context_menu_content>
      </:content>
    </.context_menu>
    """
  end

  def live_fixture(%{fixture: "dropdown-menu"} = assigns) do
    ~H"""
    <.dropdown_menu
      id="dropdown-demo"
      open={Map.get(@state, "dropdown-demo-open", true)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><.button variant="outline" {popup.trigger}>Open Menu</.button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_label>My Account</.dropdown_menu_label><.dropdown_menu_separator /><.dropdown_menu_item>
            Profile
          </.dropdown_menu_item><.dropdown_menu_item>Billing</.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def live_fixture(%{fixture: "dropdown-menu-closed-disabled"} = assigns) do
    ~H"""
    <.dropdown_menu
      id="dropdown-disabled"
      open={Map.get(@state, "dropdown-disabled-open", false)}
      disabled
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item>Action</.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def live_fixture(%{fixture: "dropdown-menu-items"} = assigns) do
    ~H"""
    <.dropdown_menu
      id="dropdown-first"
      open={Map.get(@state, "dropdown-first-open", true)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>first</button></:trigger><:content :let={popup}>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item disabled inset>Disabled</.dropdown_menu_item><.dropdown_menu_item variant="destructive">
            Delete
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    <.dropdown_menu
      id="dropdown-second"
      open={Map.get(@state, "dropdown-second-open", true)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>second</button></:trigger><:content :let={popup}>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_item disabled inset>Disabled</.dropdown_menu_item><.dropdown_menu_item variant="destructive">
            Delete
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def live_fixture(%{fixture: "dropdown-menu-checks"} = assigns) do
    ~H"""
    <.dropdown_menu id="dropdown-checks" open={Map.get(@state, "dropdown-checks-open", true)}>
      <:trigger :let={popup}><button {popup.trigger}>Preferences</button></:trigger><:content :let={
        popup
      }>
        <.dropdown_menu_content context={popup}>
          <.dropdown_menu_checkbox_item
            checked={Map.get(@state, "dropdown-checks-status-checked", true)}
            value="status"
          >
            Show status
          </.dropdown_menu_checkbox_item><.dropdown_menu_radio_group>
            <.dropdown_menu_radio_item
              checked={Map.get(@state, "dropdown-checks-value", "compact") == "compact"}
              value="compact"
            >
              Compact
            </.dropdown_menu_radio_item><.dropdown_menu_radio_item
              checked={Map.get(@state, "dropdown-checks-value", "compact") == "comfortable"}
              value="comfortable"
            >
              Comfortable
            </.dropdown_menu_radio_item>
          </.dropdown_menu_radio_group>
        </.dropdown_menu_content>
      </:content>
    </.dropdown_menu>
    """
  end

  def live_fixture(%{fixture: "hover-card"} = assigns) do
    ~H"""
    <.hover_card
      id="hover-demo"
      open={Map.get(@state, "hover-demo-open", true)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><.button variant="link" {popup.trigger}>@nextjs</.button></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup} class="w-80">
          <p class="text-sm">The React Framework for the Web.</p>
        </.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def live_fixture(%{fixture: "hover-card-disabled"} = assigns) do
    ~H"""
    <.hover_card
      id="hover-disabled"
      open={Map.get(@state, "hover-disabled-open", false)}
      disabled
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.button variant="link" {popup.trigger}>Unavailable profile</.button>
      </:trigger><:content :let={popup}>
        <.hover_card_content context={popup}>Unavailable profile details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def live_fixture(%{fixture: "hover-card-closed"} = assigns) do
    ~H"""
    <.hover_card
      id="hover-closed"
      open={Map.get(@state, "hover-closed-open", false)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><a href="#profile" {popup.trigger}>Profile</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>Profile details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def live_fixture(%{fixture: "hover-card-multiple"} = assigns) do
    ~H"""
    <.hover_card
      id="hover-first"
      open={Map.get(@state, "hover-first-open", true)}
      side="right"
      align="start"
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><a href="#first" {popup.trigger}>first</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>first details</.hover_card_content>
      </:content>
    </.hover_card>
    <.hover_card
      id="hover-second"
      open={Map.get(@state, "hover-second-open", true)}
      side="right"
      align="start"
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><a href="#second" {popup.trigger}>second</a></:trigger><:content :let={
        popup
      }>
        <.hover_card_content context={popup}>second details</.hover_card_content>
      </:content>
    </.hover_card>
    """
  end

  def live_fixture(%{fixture: "popover"} = assigns) do
    ~H"""
    <.popover
      id="popover-demo"
      open={Map.get(@state, "popover-demo-open", true)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.button variant="outline" {popup.trigger}>Open popover</.button>
      </:trigger><:content :let={popup}>
        <.popover_content context={popup} class="w-80">
          <p class="text-sm">Dimensions settings.</p>
        </.popover_content>
      </:content>
    </.popover>
    """
  end

  def live_fixture(%{fixture: "popover-closed"} = assigns) do
    ~H"""
    <.popover
      id="popover-closed"
      open={Map.get(@state, "popover-closed-open", false)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>Edit</button></:trigger><:content :let={popup}>
        <.popover_content context={popup}>
          <label for="popover-name">Name</label><input id="popover-name" value="Ada" />
        </.popover_content>
      </:content>
    </.popover>
    """
  end

  def live_fixture(%{fixture: "popover-multiple-disabled"} = assigns) do
    ~H"""
    <.popover
      id="popover-disabled"
      open={Map.get(@state, "popover-disabled-open", false)}
      disabled
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>Disabled</button></:trigger><:content :let={
        popup
      }>
        <.popover_content context={popup}>Unavailable</.popover_content>
      </:content>
    </.popover><.popover
      id="popover-second"
      open={Map.get(@state, "popover-second-open", true)}
      side="left"
      align="end"
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>Second</button></:trigger><:content :let={popup}>
        <.popover_content context={popup}>Details</.popover_content>
      </:content>
    </.popover>
    """
  end

  def live_fixture(%{fixture: "select"} = assigns) do
    ~H"""
    <.select
      id="select-demo"
      open={Map.get(@state, "select-demo-open", true)}
      placeholder="Select a fruit"
      value={Map.get(@state, "select-demo-value", nil)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.select_trigger context={popup} class="w-[180px]">
          <.select_value context={popup} placeholder="Select a fruit" />
        </.select_trigger>
      </:trigger><:option id="select-demo-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-demo-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    """
  end

  def live_fixture(%{fixture: "select-value-disabled"} = assigns) do
    ~H"""
    <form>
      <.select
        id="select-value"
        open={Map.get(@state, "select-value-open", true)}
        name="fruit"
        required
        value={Map.get(@state, "select-value-value", "banana")}
        on_change="shadcn:popup-change"
      >
        <:trigger :let={popup}>
          <.select_trigger context={popup}><.select_value context={popup} /></.select_trigger>
        </:trigger><:option id="select-value-apple" value="apple" label="Apple" disabled>
          Apple
        </:option><:option id="select-value-banana" value="banana" label="Banana">Banana</:option>
      </.select>
    </form>
    """
  end

  def live_fixture(%{fixture: "select-closed-multiple"} = assigns) do
    ~H"""
    <.select
      id="select-closed-0"
      open={Map.get(@state, "select-closed-0-open", false)}
      name="fruit-0"
      disabled={false}
      placeholder="Fruit"
      value={Map.get(@state, "select-closed-0-value", nil)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.select_trigger context={popup} size="sm">
          <.select_value context={popup} placeholder="Fruit" />
        </.select_trigger>
      </:trigger><:option id="select-closed-0-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-closed-0-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    <.select
      id="select-closed-1"
      open={Map.get(@state, "select-closed-1-open", false)}
      name="fruit-1"
      disabled={true}
      placeholder="Fruit"
      value={Map.get(@state, "select-closed-1-value", nil)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.select_trigger context={popup} size="sm">
          <.select_value context={popup} placeholder="Fruit" />
        </.select_trigger>
      </:trigger><:option id="select-closed-1-apple" value="apple" label="Apple">Apple</:option><:option
        id="select-closed-1-banana"
        value="banana"
        label="Banana"
      >
        Banana
      </:option>
    </.select>
    """
  end

  def live_fixture(%{fixture: "select-popper"} = assigns) do
    ~H"""
    <.select
      id="select-popper"
      open={Map.get(@state, "select-popper-open", true)}
      position="popper"
      align="start"
      placeholder="Fruit"
      value={Map.get(@state, "select-popper-value", nil)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.select_trigger context={popup}>
          <.select_value context={popup} placeholder="Fruit" />
        </.select_trigger>
      </:trigger><:option id="select-popper-apple" value="apple" label="Apple">Apple</:option>
    </.select>
    """
  end

  def live_fixture(%{fixture: "select-groups"} = assigns) do
    ~H"""
    <.select
      id="select-groups"
      open={Map.get(@state, "select-groups-open", true)}
      name="produce"
      placeholder="Produce"
      value={Map.get(@state, "select-groups-value", nil)}
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}>
        <.select_trigger context={popup}>
          <.select_value context={popup} placeholder="Produce" />
        </.select_trigger>
      </:trigger><:group id="fruit" label="Fruit" /><:group id="vegetables" label="Vegetables" /><:option
        id="select-groups-apple"
        value="apple"
        label="Apple"
        group="fruit"
      >
        Apple
      </:option><:option id="select-groups-carrot" value="carrot" label="Carrot" group="vegetables">
        Carrot
      </:option>
    </.select>
    """
  end

  def live_fixture(%{fixture: "tooltip"} = assigns) do
    ~H"""
    <.tooltip_provider>
      <.tooltip
        id="tooltip-demo"
        open={Map.get(@state, "tooltip-demo-open", true)}
        on_change="shadcn:popup-change"
      >
        <:trigger :let={popup}><.button variant="outline" {popup.trigger}>Hover</.button></:trigger><:content :let={
          popup
        }>
          <.tooltip_content context={popup}>
            <p>Add to library</p>
          </.tooltip_content>
        </:content>
      </.tooltip>
    </.tooltip_provider>
    """
  end

  def live_fixture(%{fixture: "tooltip-closed-disabled"} = assigns) do
    ~H"""
    <.tooltip
      id="tooltip-disabled"
      open={Map.get(@state, "tooltip-disabled-open", false)}
      disabled
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>Unavailable</button></:trigger><:content :let={
        popup
      }>
        <.tooltip_content context={popup}>Unavailable action</.tooltip_content>
      </:content>
    </.tooltip>
    """
  end

  def live_fixture(%{fixture: "tooltip-multiple"} = assigns) do
    ~H"""
    <.tooltip
      id="tooltip-first"
      open={Map.get(@state, "tooltip-first-open", true)}
      side="bottom"
      align="end"
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>first</button></:trigger><:content :let={popup}>
        <.tooltip_content context={popup}>first hint</.tooltip_content>
      </:content>
    </.tooltip>
    <.tooltip
      id="tooltip-second"
      open={Map.get(@state, "tooltip-second-open", true)}
      side="bottom"
      align="end"
      on_change="shadcn:popup-change"
    >
      <:trigger :let={popup}><button {popup.trigger}>second</button></:trigger><:content :let={popup}>
        <.tooltip_content context={popup}>second hint</.tooltip_content>
      </:content>
    </.tooltip>
    """
  end

  def live_fixture(%{fixture: "combobox"} = assigns) do
    ~H"""
    <form id="framework-form" phx-submit="preview:form">
      <.combobox
        id="framework-combo"
        value={Map.get(@state, "framework-combo", "")}
        input_value={
          Map.get(
            %{"next" => "Next.js", "phoenix" => "Phoenix"},
            Map.get(@state, "framework-combo", ""),
            ""
          )
        }
        disabled={false}
        name="framework"
        open={Map.get(@state, "framework-combo-open", false)}
        on_change="shadcn:combobox-change"
      >
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="framework-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={false}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox><button type="submit">Submit framework</button><output
        :if={Map.has_key?(@form_data, "framework")}
        aria-live="polite"
      >Submitted framework: {if Map.get(@form_data, "framework") == "",
        do: "None",
        else: Map.get(@form_data, "framework")}</output>
    </form>
    """
  end

  def live_fixture(%{fixture: "combobox-empty"} = assigns) do
    ~H"""
    <.combobox
      id="empty-combo"
      value={Map.get(@state, "empty-combo", "")}
      input_value=""
      disabled={false}
      open={Map.get(@state, "empty-combo-open", false)}
      on_change="shadcn:combobox-change"
    >
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="empty-combo-input"
          disabled={false}
          placeholder="Select framework..."
          show_clear={false}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}></.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def live_fixture(%{fixture: "combobox-value"} = assigns) do
    ~H"""
    <form id="selected-framework-form" phx-submit="preview:form">
      <.combobox
        id="selected-combo"
        value={Map.get(@state, "selected-combo", "phoenix")}
        input_value={
          Map.get(
            %{"next" => "Next.js", "phoenix" => "Phoenix"},
            Map.get(@state, "selected-combo", "phoenix"),
            ""
          )
        }
        disabled={false}
        name="framework"
        open={Map.get(@state, "selected-combo-open", false)}
        on_change="shadcn:combobox-change"
      >
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="selected-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={true}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox><button type="submit">Submit framework</button><output
        :if={Map.has_key?(@form_data, "framework")}
        aria-live="polite"
      >Submitted framework: {if Map.get(@form_data, "framework") == "",
        do: "None",
        else: Map.get(@form_data, "framework")}</output>
    </form>
    """
  end

  def live_fixture(%{fixture: "combobox-disabled"} = assigns) do
    ~H"""
    <.combobox
      id="disabled-combo"
      value={Map.get(@state, "disabled-combo", "next")}
      input_value={
        Map.get(
          %{"next" => "Next.js", "phoenix" => "Phoenix"},
          Map.get(@state, "disabled-combo", "next"),
          ""
        )
      }
      disabled={true}
      name="framework"
      open={Map.get(@state, "disabled-combo-open", false)}
      on_change="shadcn:combobox-change"
    >
      <:input :let={combo}>
        <.combobox_input
          context={combo}
          id="disabled-combo-input"
          disabled={true}
          placeholder="Select framework..."
          show_clear={true}
        />
      </:input>
      <:content :let={combo}>
        <.combobox_content context={combo}>
          <.combobox_list context={combo}>
            <.combobox_item context={combo} value="next">Next.js</.combobox_item>
            <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
          </.combobox_list>
          <.combobox_empty>No frameworks found.</.combobox_empty>
        </.combobox_content>
      </:content>
    </.combobox>
    """
  end

  def live_fixture(%{fixture: "combobox-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.combobox
        id="first-combo"
        value={Map.get(@state, "first-combo", "")}
        input_value={
          Map.get(
            %{"next" => "Next.js", "phoenix" => "Phoenix"},
            Map.get(@state, "first-combo", ""),
            ""
          )
        }
        disabled={false}
        open={Map.get(@state, "first-combo-open", false)}
        on_change="shadcn:combobox-change"
      >
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="first-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={false}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox><.combobox
        id="second-combo"
        value={Map.get(@state, "second-combo", "phoenix")}
        input_value={
          Map.get(
            %{"next" => "Next.js", "phoenix" => "Phoenix"},
            Map.get(@state, "second-combo", "phoenix"),
            ""
          )
        }
        disabled={false}
        open={Map.get(@state, "second-combo-open", false)}
        on_change="shadcn:combobox-change"
      >
        <:input :let={combo}>
          <.combobox_input
            context={combo}
            id="second-combo-input"
            disabled={false}
            placeholder="Select framework..."
            show_clear={false}
          />
        </:input>
        <:content :let={combo}>
          <.combobox_content context={combo}>
            <.combobox_list context={combo}>
              <.combobox_item context={combo} value="next">Next.js</.combobox_item>
              <.combobox_item context={combo} value="phoenix">Phoenix</.combobox_item>
            </.combobox_list>
            <.combobox_empty>No frameworks found.</.combobox_empty>
          </.combobox_content>
        </:content>
      </.combobox>
    </div>
    """
  end

  def live_fixture(%{fixture: "command"} = assigns) do
    ~H"""
    <.command
      :let={command}
      id="command-demo"
      value={Map.get(@state, "command-demo", "")}
      on_select="shadcn:command-change"
      class="rounded-lg border shadow-md"
    >
      <.command_input context={command} placeholder="Type a command or search..." name="query" />
      <.command_list context={command}>
        <.command_empty>No results found.</.command_empty><.command_group
          id="command-suggestions"
          heading="Suggestions"
        >
          <.command_item id="radix-command-demo-calendar" value="calendar">Calendar</.command_item><.command_item
            id="radix-command-demo-emoji"
            value="emoji"
          >
            Search Emoji
          </.command_item>
        </.command_group>
      </.command_list>
    </.command>
    <output :if={Map.get(@state, "command-demo", "") != ""} aria-live="polite">Selected command: {Map.get(
      @state,
      "command-demo"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "command-empty"} = assigns) do
    ~H"""
    <.command
      :let={command}
      id="empty-command"
      label="Actions"
      value={Map.get(@state, "empty-command", "")}
      on_select="shadcn:command-change"
    >
      <.command_input context={command} /><.command_list context={command} label="Actions">
        <.command_empty>No actions available.</.command_empty>
      </.command_list>
    </.command><output :if={Map.get(@state, "empty-command", "") != ""} aria-live="polite">Selected command: {Map.get(
      @state,
      "empty-command"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "command-values-disabled"} = assigns) do
    ~H"""
    <.command
      :let={command}
      id="valued-command"
      value={Map.get(@state, "valued-command", "save")}
      on_select="shadcn:command-change"
      label="Editor actions"
    >
      <.command_input context={command} name="query" value="sav" disabled /><.command_list context={
        command
      }>
        <.command_empty>No actions.</.command_empty><.command_group
          id="editor-actions"
          heading="Editor"
        >
          <.command_item id="radix-valued-command-save" value="save" keywords={["persist"]}>
            Save<.command_shortcut>⌘S</.command_shortcut>
          </.command_item><.command_item id="radix-valued-command-delete" value="delete" disabled>
            Delete
          </.command_item>
        </.command_group><.command_separator /><.command_item
          id="radix-valued-command-close"
          value="close"
        >
          Close
        </.command_item>
      </.command_list>
    </.command><output :if={Map.get(@state, "valued-command", "") != ""} aria-live="polite">Selected command: {Map.get(
      @state,
      "valued-command"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "command-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.command
        :let={command}
        id="first-command"
        value={Map.get(@state, "first-command", "")}
        on_select="shadcn:command-change"
      >
        <.command_input context={command} /><.command_list context={command}>
          <.command_item id="radix-first-command-open" value="open">Open</.command_item>
        </.command_list>
      </.command><output :if={Map.get(@state, "first-command", "") != ""} aria-live="polite">Selected command: {Map.get(
        @state,
        "first-command"
      )}</output><.command
        :let={command}
        id="second-command"
        value={Map.get(@state, "second-command", "")}
        on_select="shadcn:command-change"
      >
        <.command_input context={command} /><.command_list context={command}>
          <.command_item id="radix-second-command-open" value="open">Open</.command_item>
        </.command_list>
      </.command><output :if={Map.get(@state, "second-command", "") != ""} aria-live="polite">Selected command: {Map.get(
        @state,
        "second-command"
      )}</output>
    </div>
    """
  end

  def live_fixture(%{fixture: "input-otp"} = assigns) do
    ~H"""
    <form id="otp-form" phx-submit="preview:form">
      <.input_otp
        :let={otp}
        id="otp-demo"
        max_length={4}
        value={Map.get(@state, "otp-demo", "")}
        disabled={false}
        name="code"
        required
        minlength={4}
        pattern="^[0-9]+$"
        paste_transform="strip-separators"
        on_change="shadcn:otp-change"
        on_complete="shadcn:otp-complete"
      >
        <.input_otp_group>
          <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
            context={otp}
            index={2}
          /><.input_otp_slot context={otp} index={3} />
        </.input_otp_group>
      </.input_otp><button type="submit">Submit code</button><button
        type="button"
        id="otp-server-value"
        value="9021"
        phx-click="shadcn:otp-change"
        phx-value-id="otp-demo"
      >Set server code to 9021</button><output
        :if={Map.has_key?(@form_data, "code")}
        aria-live="polite"
      >Submitted code: {Map.get(@form_data, "code")}</output>
    </form>
    """
  end

  def live_fixture(%{fixture: "input-otp-partial-value"} = assigns) do
    ~H"""
    <.input_otp
      :let={otp}
      id="partial-otp"
      max_length={4}
      value={Map.get(@state, "partial-otp", "12")}
      disabled={false}
      name="code"
      on_change="shadcn:otp-change"
      on_complete="shadcn:otp-complete"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        /><.input_otp_slot context={otp} index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def live_fixture(%{fixture: "input-otp-separated"} = assigns) do
    ~H"""
    <.input_otp
      :let={otp}
      id="separated-otp"
      max_length={6}
      value={Map.get(@state, "separated-otp", "123456")}
      disabled={false}
      name="code"
      on_change="shadcn:otp-change"
      on_complete="shadcn:otp-complete"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        />
      </.input_otp_group><.input_otp_separator /><.input_otp_group>
        <.input_otp_slot context={otp} index={3} /><.input_otp_slot context={otp} index={4} /><.input_otp_slot
          context={otp}
          index={5}
        />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def live_fixture(%{fixture: "input-otp-disabled"} = assigns) do
    ~H"""
    <.input_otp
      :let={otp}
      id="disabled-otp"
      max_length={4}
      value={Map.get(@state, "disabled-otp", "9876")}
      disabled={true}
      name="code"
      on_change="shadcn:otp-change"
      on_complete="shadcn:otp-complete"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
          context={otp}
          index={2}
        /><.input_otp_slot context={otp} index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def live_fixture(%{fixture: "input-otp-validation"} = assigns) do
    ~H"""
    <.input_otp
      :let={otp}
      id="validated-otp"
      max_length={4}
      name="code"
      form="verification"
      required
      readonly
      pattern="^[0-9]+$"
      placeholder="----"
      aria-invalid="true"
      aria-label="Verification code"
    >
      <.input_otp_group>
        <.input_otp_slot context={otp} index={0} aria-invalid="true" /><.input_otp_slot
          context={otp}
          index={1}
          aria-invalid="true"
        /><.input_otp_slot context={otp} index={2} aria-invalid="true" /><.input_otp_slot
          context={otp}
          index={3}
          aria-invalid="true"
        />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def live_fixture(%{fixture: "input-otp-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.input_otp
        :let={otp}
        id="first-otp"
        max_length={4}
        value={Map.get(@state, "first-otp", "")}
        disabled={false}
        on_change="shadcn:otp-change"
        on_complete="shadcn:otp-complete"
      >
        <.input_otp_group>
          <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
            context={otp}
            index={2}
          /><.input_otp_slot context={otp} index={3} />
        </.input_otp_group>
      </.input_otp><.input_otp
        :let={otp}
        id="second-otp"
        max_length={4}
        value={Map.get(@state, "second-otp", "23")}
        disabled={false}
        on_change="shadcn:otp-change"
        on_complete="shadcn:otp-complete"
      >
        <.input_otp_group>
          <.input_otp_slot context={otp} index={0} /><.input_otp_slot context={otp} index={1} /><.input_otp_slot
            context={otp}
            index={2}
          /><.input_otp_slot context={otp} index={3} />
        </.input_otp_group>
      </.input_otp>
    </div>
    """
  end

  def live_fixture(%{fixture: "calendar"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-default"
      month={Map.get(@state, "calendar-default", %{month: ~D[2024-10-01]}).month}
      today={~D[2024-02-15]}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-leap-selection"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-leap"
      month={Map.get(@state, "calendar-leap", %{month: ~D[2024-02-01]}).month}
      today={~D[2024-02-15]}
      mode="single"
      selected={Map.get(Map.get(@state, "calendar-leap", %{}), :selected, ~D[2024-02-29])}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-common-february"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-common"
      month={Map.get(@state, "calendar-common", %{month: ~D[2023-02-01]}).month}
      today={~D[2024-02-15]}
      show_outside_days={false}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-bounded-range"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-range"
      month={Map.get(@state, "calendar-range", %{month: ~D[2024-02-01]}).month}
      today={~D[2024-02-15]}
      mode="range"
      selected={
        Map.get(Map.get(@state, "calendar-range", %{}), :selected, %{
          from: ~D[2024-02-10],
          to: ~D[2024-02-12]
        })
      }
      disabled_before={~D[2024-02-05]}
      disabled_after={~D[2024-02-25]}
      start_month={~D[2024-02-01]}
      end_month={~D[2024-02-01]}
      show_outside_days={false}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-british-week"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-british"
      month={Map.get(@state, "calendar-british", %{month: ~D[2024-02-01]}).month}
      today={~D[2024-02-15]}
      locale="en-GB"
      mode="single"
      selected={Map.get(Map.get(@state, "calendar-british", %{}), :selected)}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-fixed-multiple"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-multiple"
      month={Map.get(@state, "calendar-multiple", %{month: ~D[2024-02-01]}).month}
      today={~D[2024-02-15]}
      mode="multiple"
      selected={
        Map.get(Map.get(@state, "calendar-multiple", %{}), :selected, [~D[2024-02-05], ~D[2024-02-21]])
      }
      disabled={[~D[2024-02-08], ~D[2024-02-09]]}
      week_starts_on={1}
      fixed_weeks
    />
    """
  end

  def live_fixture(%{fixture: "calendar-year-boundary"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-year"
      month={Map.get(@state, "calendar-year", %{month: ~D[2024-12-01]}).month}
      today={~D[2024-02-15]}
      number_of_months={2}
    />
    """
  end

  def live_fixture(%{fixture: "calendar-independent-instances"} = assigns) do
    ~H"""
    <.calendar
      id="calendar-first"
      month={Map.get(@state, "calendar-first", %{month: ~D[2024-01-01]}).month}
      today={~D[2024-02-15]}
      mode="single"
      selected={Map.get(Map.get(@state, "calendar-first", %{}), :selected, ~D[2024-01-10])}
    /><.calendar
      id="calendar-second"
      month={Map.get(@state, "calendar-second", %{month: ~D[2024-03-01]}).month}
      today={~D[2024-02-15]}
      mode="single"
      selected={Map.get(Map.get(@state, "calendar-second", %{}), :selected, ~D[2024-03-20])}
    />
    """
  end

  def live_fixture(%{fixture: "carousel"} = assigns) do
    ~H"""
    <.carousel
      :let={carousel}
      id="carousel-demo"
      start_index={Map.get(@state, "carousel-demo", 0)}
      class="w-full max-w-xs"
    >
      <.carousel_content carousel={carousel}>
        <.carousel_item carousel={carousel}>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">1</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
    </.carousel>
    """
  end

  def live_fixture(%{fixture: "carousel-vertical"} = assigns) do
    ~H"""
    <.carousel
      :let={carousel}
      id="carousel-vertical-demo"
      orientation="vertical"
      start_index={Map.get(@state, "carousel-vertical-demo", 0)}
      class="my-12 h-48 w-full max-w-xs"
    >
      <.carousel_content carousel={carousel} class="h-48">
        <.carousel_item carousel={carousel}>First</.carousel_item><.carousel_item carousel={carousel}>
          Second
        </.carousel_item><.carousel_item carousel={carousel}>Third</.carousel_item>
      </.carousel_content>
      <.carousel_previous carousel={carousel} /><.carousel_next carousel={carousel} />
    </.carousel>
    """
  end

  def live_fixture(%{fixture: "carousel-multiple"} = assigns) do
    ~H"""
    <div class="flex w-full flex-col items-center gap-12 px-12">
      <.carousel
        :let={carousel}
        :for={side <- ~w(left right)}
        id={"carousel-" <> side}
        loop={true}
        start_index={Map.get(@state, "carousel-" <> side, 1)}
        class="w-full max-w-48"
      >
        <.carousel_content carousel={carousel}>
          <.carousel_item :for={label <- ~w(A B C D)} carousel={carousel} class="basis-1/2">
            {label}
          </.carousel_item>
        </.carousel_content><.carousel_previous carousel={carousel} /><.carousel_next carousel={
          carousel
        } />
      </.carousel>
    </div>
    """
  end

  def live_fixture(%{fixture: "resizable"} = assigns) do
    ~H"""
    <.resizable_panel_group
      :let={group}
      id="resizable-demo"
      layout={Map.get(@state, "resizable-demo")}
      orientation="horizontal"
      class="max-w-md rounded-lg border"
    >
      <.resizable_panel group={group} id="resizable-demo-one" default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">One</div>
      </.resizable_panel>
      <.resizable_handle group={group} id="resizable-demo-handle" />
      <.resizable_panel group={group} id="resizable-demo-two" default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">Two</div>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  def live_fixture(%{fixture: "resizable-vertical"} = assigns) do
    ~H"""
    <.resizable_panel_group
      :let={group}
      id="resizable-vertical-demo"
      layout={Map.get(@state, "resizable-vertical-demo")}
      orientation="vertical"
      class="min-h-64 max-w-md border"
    >
      <.resizable_panel
        group={group}
        id="resizable-vertical-one"
        default_size="30%"
        min_size="10%"
        max_size="80%"
      >
        Top
      </.resizable_panel><.resizable_handle
        group={group}
        id="resizable-vertical-handle"
        with_handle={true}
      /><.resizable_panel
        group={group}
        id="resizable-vertical-two"
        default_size="70%"
        min_size="20%"
        max_size="90%"
      >
        Bottom
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  def live_fixture(%{fixture: "resizable-multiple"} = assigns) do
    ~H"""
    <div class="flex gap-4">
      <.resizable_panel_group
        :let={group}
        id="resize-auto"
        layout={Map.get(@state, "resize-auto")}
        class="min-h-32"
      >
        <.resizable_panel id="resize-auto-a" group={group}>Automatic</.resizable_panel><.resizable_handle
          id="resize-auto-h"
          group={group}
          with_handle={true}
        /><.resizable_panel
          id="resize-auto-b"
          group={group}
          collapsible={true}
          collapsed_size="5%"
          min_size="15%"
          max_size="70%"
        >
          Collapsible
        </.resizable_panel>
      </.resizable_panel_group><.resizable_panel_group :let={group} id="resize-fixed" class="min-h-32">
        <.resizable_panel id="resize-fixed-a" group={group} default_size="40%">
          Fixed
        </.resizable_panel><.resizable_handle id="resize-fixed-h" group={group} disabled={true} /><.resizable_panel
          id="resize-fixed-b"
          group={group}
          default_size="60%"
          disabled={true}
        >
          Disabled
        </.resizable_panel>
      </.resizable_panel_group>
    </div>
    """
  end

  def live_fixture(%{fixture: "sidebar"} = assigns) do
    ~H"""
    <.sidebar_provider
      :let={sidebar}
      id="sidebar-demo"
      open={Map.get(@state, "sidebar-demo", true)}
      mobile_open={Map.get(@state, "sidebar-demo-mobile", false)}
    >
      <.sidebar id="sidebar-demo-panel" sidebar={sidebar}>
        <.sidebar_header>
          <h4 class="font-semibold text-sm">Application</h4>
        </.sidebar_header><.sidebar_content>
          <div class="p-2 text-sm text-muted-foreground">Nav items</div>
        </.sidebar_content>
      </.sidebar>
    </.sidebar_provider>
    """
  end

  def live_fixture(%{fixture: "sidebar-collapsed-icon"} = assigns) do
    ~H"""
    <.sidebar_provider
      :let={sidebar}
      id="sidebar-icon"
      open={Map.get(@state, "sidebar-icon", false)}
      mobile_open={Map.get(@state, "sidebar-icon-mobile", false)}
    >
      <.sidebar
        id="sidebar-icon-panel"
        sidebar={sidebar}
        collapsible="icon"
        side="right"
        variant="floating"
      >
        <.sidebar_header>Workspace</.sidebar_header><.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub>
                    <.sidebar_menu_sub_item>
                      <.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button>
                    </.sidebar_menu_sub_item>
                  </.sidebar_menu_sub>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} />
      </.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def live_fixture(%{fixture: "sidebar-collapsed-offcanvas"} = assigns) do
    ~H"""
    <.sidebar_provider
      :let={sidebar}
      id="sidebar-offcanvas"
      open={Map.get(@state, "sidebar-offcanvas", false)}
      mobile_open={Map.get(@state, "sidebar-offcanvas-mobile", false)}
    >
      <.sidebar
        id="sidebar-offcanvas-panel"
        sidebar={sidebar}
        collapsible="offcanvas"
        side="right"
        variant="floating"
      >
        <.sidebar_header>Workspace</.sidebar_header><.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_label>Projects</.sidebar_group_label><.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.sidebar_menu_button is_active={true} size="sm">Overview</.sidebar_menu_button><.sidebar_menu_sub>
                    <.sidebar_menu_sub_item>
                      <.sidebar_menu_sub_button href="#details" is_active={true}>Details</.sidebar_menu_sub_button>
                    </.sidebar_menu_sub_item>
                  </.sidebar_menu_sub>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content><.sidebar_footer>Account</.sidebar_footer><.sidebar_rail sidebar={sidebar} />
      </.sidebar><.sidebar_inset><.sidebar_trigger sidebar={sidebar} />Content</.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def live_fixture(%{fixture: "sidebar-multiple"} = assigns) do
    ~H"""
    <div class="flex w-full min-w-0 flex-col gap-4 md:flex-row">
      <.sidebar_provider
        :let={sidebar}
        id="sidebar-inset"
        class="relative h-64 min-h-0! min-w-0 overflow-hidden"
        open={Map.get(@state, "sidebar-inset", true)}
        mobile_open={Map.get(@state, "sidebar-inset-mobile", false)}
      >
        <.sidebar
          id="sidebar-inset-panel"
          sidebar={sidebar}
          variant="inset"
          class="md:absolute md:h-full"
        >
          <.sidebar_header>Inset</.sidebar_header><.sidebar_content>Navigation</.sidebar_content>
        </.sidebar><.sidebar_inset class="min-w-0">
          <.sidebar_trigger sidebar={sidebar} />Main
        </.sidebar_inset>
      </.sidebar_provider><.sidebar_provider
        :let={sidebar}
        id="sidebar-static"
        class="h-48 min-h-0! min-w-0 md:h-64 md:w-48 md:shrink-0"
        open={Map.get(@state, "sidebar-static", true)}
        mobile_open={Map.get(@state, "sidebar-static-mobile", false)}
      >
        <.sidebar id="sidebar-static-panel" sidebar={sidebar} collapsible="none" class="w-48">
          <.sidebar_content>Always visible</.sidebar_content>
        </.sidebar>
      </.sidebar_provider>
    </div>
    """
  end

  def live_fixture(%{fixture: "sidebar-menu-popup"} = assigns) do
    ~H"""
    <.sidebar_provider
      :let={sidebar}
      id="sidebar-popup"
      open={Map.get(@state, "sidebar-popup", true)}
      mobile_open={Map.get(@state, "sidebar-popup-mobile", false)}
    >
      <.sidebar id="sidebar-popup-panel" sidebar={sidebar}>
        <.sidebar_content>
          <.sidebar_group>
            <.sidebar_group_content>
              <.sidebar_menu>
                <.sidebar_menu_item>
                  <.dropdown_menu
                    id="sidebar-popup-menu"
                    open={Map.get(@state, "sidebar-popup-menu-open", false)}
                    on_change="shadcn:popup-change"
                  >
                    <:trigger :let={popup}>
                      <.sidebar_menu_button {popup.trigger}>Team</.sidebar_menu_button>
                    </:trigger><:content :let={popup}>
                      <.dropdown_menu_content context={popup}>
                        <.dropdown_menu_item>Acme</.dropdown_menu_item><.dropdown_menu_item>
                          Globex
                        </.dropdown_menu_item>
                      </.dropdown_menu_content>
                    </:content>
                  </.dropdown_menu>
                </.sidebar_menu_item>
              </.sidebar_menu>
            </.sidebar_group_content>
          </.sidebar_group>
        </.sidebar_content>
      </.sidebar><.sidebar_inset>
        <.sidebar_trigger sidebar={sidebar} />Main<span id="sidebar-popup-ticks">{Map.get(
          @state,
          "sidebar-popup-ticks",
          0
        )}</span>
      </.sidebar_inset>
    </.sidebar_provider>
    """
  end

  def live_fixture(%{fixture: "chart"} = assigns) do
    ~H"""
    <.chart_container
      id="viewport"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="min-h-[200px] w-full"
    >
      <div class="p-4 text-center text-muted-foreground">Chart Viewport</div>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-config-theme"} = assigns) do
    ~H"""
    <.chart_container
      id="theme-sales"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <div>Theme-aware sales</div>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-label-only"} = assigns) do
    ~H"""
    <.chart_container id="label-only" config={%{sales: %{label: "Sales"}}} aria-label="Sales report">
      <div>Sales</div>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-empty-config"} = assigns) do
    ~H"""
    <.chart_container id="no-config" config={%{}}>
      <div>No configured series</div>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-bar-series"} = assigns) do
    ~H"""
    <section class="w-full min-w-0">
      <button type="button" phx-click="shadcn:chart-data" phx-value-id="sales-bars" value="alternate">Change chart data</button><.chart_container
        :let={chart}
        id="sales-bars"
        config={[
          desktop: %{label: "Desktop", color: "#2563eb"},
          mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
        ]}
        class="h-[240px] w-full"
      >
        <.chart_canvas
          id="sales-bars-canvas"
          context={chart}
          data={
            if Map.get(@state, "sales-bars") == "alternate",
              do: [
                %{month: "May", desktop: 45, mobile: 300},
                %{month: "June", desktop: 240, mobile: -30}
              ],
              else: [
                %{month: "January", desktop: 186, mobile: 80},
                %{month: "February", desktop: 305, mobile: 200},
                %{month: "March", desktop: -45, mobile: 120},
                %{month: "April", desktop: 0, mobile: 0}
              ]
          }
          series={[:desktop, :mobile]}
          x_key="month"
          legend
          label="Monthly desktop and mobile sales"
        />
      </.chart_container>
    </section>
    """
  end

  def live_fixture(%{fixture: "chart-line-custom-dimensions"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="trend"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
      initial_dimension={%{width: 480, height: 260}}
      class="h-[260px] w-full"
    >
      <.chart_canvas
        id="trend-canvas"
        context={chart}
        kind="line"
        data={[
          %{month: "January", desktop: 186, mobile: 80},
          %{month: "February", desktop: 305, mobile: 200},
          %{month: "March", desktop: -45, mobile: 120},
          %{month: "April", desktop: 0, mobile: 0}
        ]}
        series={[:desktop, :mobile]}
        x_key="month"
        label="Monthly trends"
      />
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-area-gaps"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="area"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="h-[200px] w-full"
    >
      <.chart_canvas
        id="area-canvas"
        context={chart}
        kind="area"
        data={[
          %{month: "January", desktop: 20},
          %{month: "February", desktop: nil},
          %{month: "March", desktop: 40}
        ]}
        series={[:desktop]}
        x_key="month"
      />
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-empty-data"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="empty-data"
      config={%{desktop: %{label: "Desktop", color: "#2563eb"}}}
      class="h-[200px] w-full"
    >
      <.chart_canvas
        id="empty-data-canvas"
        context={chart}
        data={[]}
        series={[:desktop]}
        axes={false}
        tooltip={false}
      />
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-tooltip"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
          label="January"
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-tooltip-line"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-line"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[%{dataKey: "desktop", name: "desktop", value: 1234, color: "#2563eb"}]}
          label="January"
          indicator="line"
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-tooltip-hidden"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-hidden"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
          label="January"
          hide_label
          hide_indicator
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-tooltip-inactive"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="tooltip-inactive"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_tooltip_content
          context={chart}
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"}
          ]}
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-tooltip-dashed"} = assigns) do
    ~H"""
    <.chart_container :let={chart} id="tooltip-dashed" config={%{desktop: %{label: "Desktop"}}}>
      <section>
        <.chart_tooltip_content
          context={chart}
          active
          payload={[%{name: "desktop", value: 0, color: "#123"}]}
          label="January"
          indicator="dashed"
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-empty-payload"} = assigns) do
    ~H"""
    <.chart_container :let={chart} id="empty-payload" config={%{}}>
      <section>
        <.chart_tooltip_content context={chart} active payload={[]} /><.chart_legend_content
          context={chart}
          payload={[]}
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-legend"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="legend"
      config={[
        desktop: %{label: "Desktop", color: "#2563eb"},
        mobile: %{label: "Mobile", theme: %{light: "#16a34a", dark: "#4ade80"}}
      ]}
    >
      <section>
        <.chart_legend_content
          context={chart}
          vertical_align="top"
          payload={[
            %{
              dataKey: "desktop",
              name: "desktop",
              value: 1234,
              color: "#2563eb",
              payload: %{month: "January"}
            },
            %{dataKey: "mobile", name: "mobile", value: 56, color: "#16a34a"},
            %{type: "none", dataKey: "ignored", color: "red"}
          ]}
        />
      </section>
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "chart-multiple-instances"} = assigns) do
    ~H"""
    <section>
      <.chart_container
        :let={chart}
        id="first"
        config={%{sales: %{label: "First sales", color: "#9333ea"}}}
        class="h-[200px] w-full"
      >
        <.chart_canvas
          id="first-canvas"
          context={chart}
          data={[%{name: "A", sales: 12}]}
          series={[:sales]}
        />
      </.chart_container><.chart_container
        :let={chart}
        id="second"
        config={%{sales: %{label: "Second sales", theme: %{light: "#dc2626", dark: "#f87171"}}}}
        class="h-[200px] w-full"
      >
        <.chart_canvas
          id="second-canvas"
          context={chart}
          kind="line"
          data={[%{name: "B", sales: 18}]}
          series={[:sales]}
        />
      </.chart_container>
    </section>
    """
  end

  def live_fixture(%{fixture: "chart-area-interactive"} = assigns) do
    ~H"""
    <.chart_container
      :let={chart}
      id="visitors"
      config={[
        visitors: %{label: "Visitors"},
        desktop: %{label: "Desktop", color: "var(--primary)"},
        mobile: %{label: "Mobile", color: "var(--primary)"}
      ]}
      class="aspect-auto h-[250px] w-full"
    >
      <.chart_canvas
        id="visitors-chart"
        context={chart}
        kind="area"
        data={[
          %{date: "2024-06-01", desktop: 178, mobile: 200},
          %{date: "2024-06-02", desktop: 470, mobile: 410},
          %{date: "2024-06-03", desktop: 103, mobile: 160},
          %{date: "2024-06-04", desktop: 439, mobile: 380},
          %{date: "2024-06-05", desktop: 88, mobile: 140},
          %{date: "2024-06-06", desktop: 294, mobile: 250},
          %{date: "2024-06-07", desktop: 323, mobile: 370},
          %{date: "2024-06-08", desktop: 385, mobile: 320},
          %{date: "2024-06-09", desktop: 438, mobile: 480},
          %{date: "2024-06-10", desktop: 155, mobile: 200},
          %{date: "2024-06-11", desktop: 92, mobile: 150},
          %{date: "2024-06-12", desktop: 492, mobile: 420},
          %{date: "2024-06-13", desktop: 81, mobile: 130},
          %{date: "2024-06-14", desktop: 426, mobile: 380},
          %{date: "2024-06-15", desktop: 307, mobile: 350},
          %{date: "2024-06-16", desktop: 371, mobile: 310},
          %{date: "2024-06-17", desktop: 475, mobile: 520},
          %{date: "2024-06-18", desktop: 107, mobile: 170},
          %{date: "2024-06-19", desktop: 341, mobile: 290},
          %{date: "2024-06-20", desktop: 408, mobile: 450},
          %{date: "2024-06-21", desktop: 169, mobile: 210},
          %{date: "2024-06-22", desktop: 317, mobile: 270},
          %{date: "2024-06-23", desktop: 480, mobile: 530},
          %{date: "2024-06-24", desktop: 132, mobile: 180},
          %{date: "2024-06-25", desktop: 141, mobile: 190},
          %{date: "2024-06-26", desktop: 434, mobile: 380},
          %{date: "2024-06-27", desktop: 448, mobile: 490},
          %{date: "2024-06-28", desktop: 149, mobile: 200},
          %{date: "2024-06-29", desktop: 103, mobile: 160},
          %{date: "2024-06-30", desktop: 446, mobile: 400}
        ]}
        x_key="date"
        series={[
          %{key: "mobile", gradient_opacity: [0.8, 0.1]},
          %{key: "desktop", gradient_opacity: [1.0, 0.1]}
        ]}
        stack
        curve="natural"
        fill="gradient"
        grid="horizontal"
        axis_line={false}
        tick_line={false}
        tick_margin={8}
        min_tick_gap={32}
        tick_format="date_short"
        tooltip_label_format="date_short"
        cursor={false}
        label="Total visitors"
      />
    </.chart_container>
    """
  end

  def live_fixture(%{fixture: "message-scroller"} = assigns) do
    ~H"""
    <.message_scroller_provider :let={scroll}>
      <.message_scroller id="message-scroller-demo" context={scroll} class="h-40 border rounded p-4">
        <p>Message stream content</p>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def live_fixture(%{fixture: "message-scroller-start"} = assigns) do
    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="start" auto_scroll>
      <.message_scroller id="stream-start" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0">
            <.message_scroller_item message_id="stream-start-first" scroll_anchor>
              <p>First message</p>
            </.message_scroller_item><.message_scroller_item message_id="stream-start-second">
              <p>Second message</p>
            </.message_scroller_item><.message_scroller_item
              message_id="stream-start-third"
              scroll_anchor
            >
              <p>Latest message</p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def live_fixture(%{fixture: "message-scroller-end"} = assigns) do
    ~H"""
    <div>
      <.message_scroller_provider :let={scroll} default_scroll_position="end" auto_scroll>
        <.message_scroller id="stream-end" context={scroll} class="h-40 border rounded p-4">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content spacer_class="shrink-0">
              <.message_scroller_item message_id="stream-end-first" scroll_anchor>
                <p>First message</p>
              </.message_scroller_item><.message_scroller_item message_id="stream-end-second">
                <p>Second message</p>
              </.message_scroller_item><.message_scroller_item
                message_id="stream-end-third"
                scroll_anchor
              >
                <p>Latest message</p>
              </.message_scroller_item>
              <.message_scroller_item
                :for={
                  n <-
                    Enum.drop(
                      Enum.to_list(1..String.to_integer(to_string(Map.get(@state, "stream-end", 3)))),
                      3
                    )
                }
                message_id={"stream-end-#{n}"}
                class="h-24"
              >
                <p>Added message {n}</p>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
        </.message_scroller>
      </.message_scroller_provider><button
        type="button"
        phx-click="shadcn:message-count"
        phx-value-id="stream-end"
        value="8"
      >Append messages</button><button
        type="button"
        phx-click="shadcn:message-count"
        phx-value-id="stream-end"
        value="12"
      >Append more</button>
    </div>
    """
  end

  def live_fixture(%{fixture: "message-scroller-last-anchor"} = assigns) do
    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="last-anchor" auto_scroll>
      <.message_scroller id="stream-last-anchor" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0">
            <.message_scroller_item message_id="stream-last-anchor-first" scroll_anchor>
              <p>First message</p>
            </.message_scroller_item><.message_scroller_item message_id="stream-last-anchor-second">
              <p>Second message</p>
            </.message_scroller_item><.message_scroller_item
              message_id="stream-last-anchor-third"
              scroll_anchor
            >
              <p>Latest message</p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def live_fixture(%{fixture: "message-scroller-empty"} = assigns) do
    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="end" auto_scroll>
      <.message_scroller id="stream-empty" context={scroll} class="h-40 border rounded p-4">
        <.message_scroller_viewport context={scroll}>
          <.message_scroller_content spacer_class="shrink-0"></.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def live_fixture(%{fixture: "message-scroller-multiple"} = assigns) do
    ~H"""
    <div>
      <.message_scroller_provider :let={scroll} default_scroll_position="start" auto_scroll>
        <.message_scroller id="stream-a" context={scroll} class="h-40 border rounded p-4">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content spacer_class="shrink-0">
              <.message_scroller_item message_id="stream-a-first" scroll_anchor>
                <p>First message</p>
              </.message_scroller_item><.message_scroller_item message_id="stream-a-second">
                <p>Second message</p>
              </.message_scroller_item><.message_scroller_item
                message_id="stream-a-third"
                scroll_anchor
              >
                <p>Latest message</p>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
        </.message_scroller>
      </.message_scroller_provider><.message_scroller_provider
        :let={scroll}
        default_scroll_position="last-anchor"
        auto_scroll
      >
        <.message_scroller id="stream-b" context={scroll} class="h-40 border rounded p-4">
          <.message_scroller_viewport context={scroll}>
            <.message_scroller_content spacer_class="shrink-0">
              <.message_scroller_item message_id="stream-b-first" scroll_anchor>
                <p>First message</p>
              </.message_scroller_item><.message_scroller_item message_id="stream-b-second">
                <p>Second message</p>
              </.message_scroller_item><.message_scroller_item
                message_id="stream-b-third"
                scroll_anchor
              >
                <p>Latest message</p>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button direction="start">Earlier</.message_scroller_button><.message_scroller_button>Latest</.message_scroller_button>
        </.message_scroller>
      </.message_scroller_provider>
    </div>
    """
  end

  def live_fixture(%{fixture: "questionnaire"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-demo"
      items={[%{name: "satisfaction"}]}
      item={Map.get(@state, "questionnaire-demo", "satisfaction")}
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-demo"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_item context={questionnaire} name="satisfaction">
        How satisfied are you with our service?
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  def live_fixture(%{fixture: "questionnaire-flow"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-flow"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item={Map.get(@state, "questionnaire-flow", "rating")}
      shortcuts="letters"
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-flow"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={false}
        invalid={false}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-flow-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice
            context={question}
            value="good"
            checked={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "rating") == "good"}
            index={0}
          >
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice
            context={question}
            value="great"
            checked={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "rating") == "great"}
            index={1}
          >
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-flow-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-flow-comment-input"
          value={Map.get(Map.get(@state, "questionnaire-flow-answers", %{}), "comment", "Thanks!")}
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-flow-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    <output :if={!is_nil(Map.get(@state, "questionnaire-flow-submitted"))} aria-live="polite">Submitted answers: {Map.get(
      @state,
      "questionnaire-flow-submitted"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "questionnaire-current-last"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-last"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item={Map.get(@state, "questionnaire-last", "comment")}
      shortcuts="letters"
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-last"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={false}
        invalid={false}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-last-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice
            context={question}
            value="good"
            checked={Map.get(Map.get(@state, "questionnaire-last-answers", %{}), "rating") == "good"}
            index={0}
          >
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice
            context={question}
            value="great"
            checked={Map.get(Map.get(@state, "questionnaire-last-answers", %{}), "rating") == "great"}
            index={1}
          >
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-last-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-last-comment-input"
          value={Map.get(Map.get(@state, "questionnaire-last-answers", %{}), "comment", "Thanks!")}
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-last-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    <output :if={!is_nil(Map.get(@state, "questionnaire-last-submitted"))} aria-live="polite">Submitted answers: {Map.get(
      @state,
      "questionnaire-last-submitted"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "questionnaire-invalid-multiple"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-invalid"
      items={[
        %{
          name: "rating",
          required: true,
          choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
        },
        %{name: "comment"},
        %{name: "archived", disabled: true}
      ]}
      item={Map.get(@state, "questionnaire-invalid", "rating")}
      shortcuts="numbers"
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-invalid"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_progress context={questionnaire} />
      <.questionnaire_item
        :let={question}
        context={questionnaire}
        name="rating"
        required
        multiple={true}
        invalid={not Map.has_key?(Map.get(@state, "questionnaire-invalid-answers", %{}), "rating")}
      >
        <.questionnaire_title>How was your visit?</.questionnaire_title>
        <.questionnaire_description id="questionnaire-invalid-rating-description">
          Choose an answer.
        </.questionnaire_description>
        <.questionnaire_choices context={question}>
          <.questionnaire_choice
            context={question}
            value="good"
            checked={
              "good" in Map.get(Map.get(@state, "questionnaire-invalid-answers", %{}), "rating", [])
            }
            index={0}
          >
            Good<.questionnaire_choice_description>
              A pleasant visit.
            </.questionnaire_choice_description>
          </.questionnaire_choice>
          <.questionnaire_choice
            context={question}
            value="great"
            checked={
              "great" in Map.get(Map.get(@state, "questionnaire-invalid-answers", %{}), "rating", [])
            }
            index={1}
          >
            Great
          </.questionnaire_choice>
          <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
            Unavailable
          </.questionnaire_choice>
        </.questionnaire_choices>
        <.questionnaire_error context={question} id="questionnaire-invalid-rating-error" />
      </.questionnaire_item>
      <.questionnaire_item :let={question} context={questionnaire} name="comment">
        <.questionnaire_title>Anything to add?</.questionnaire_title>
        <.questionnaire_input
          context={question}
          id="questionnaire-invalid-comment-input"
          value={Map.get(Map.get(@state, "questionnaire-invalid-answers", %{}), "comment", "Thanks!")}
          placeholder="Your feedback"
        />
        <.questionnaire_error context={question} id="questionnaire-invalid-comment-error" />
      </.questionnaire_item>
      <.questionnaire_item context={questionnaire} name="archived" disabled>
        <.questionnaire_title>Archived question</.questionnaire_title>
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    <output :if={!is_nil(Map.get(@state, "questionnaire-invalid-submitted"))} aria-live="polite">Submitted answers: {Map.get(
      @state,
      "questionnaire-invalid-submitted"
    )}</output>
    """
  end

  def live_fixture(%{fixture: "questionnaire-empty"} = assigns) do
    ~H"""
    <.questionnaire :let={questionnaire} id="questionnaire-empty">
      <.questionnaire_progress context={questionnaire} /><.questionnaire_actions>
        <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
          questionnaire
        } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
          questionnaire
        } />
      </.questionnaire_actions>
    </.questionnaire>
    """
  end

  def live_fixture(%{fixture: "questionnaire-multiple"} = assigns) do
    ~H"""
    <div>
      <.questionnaire
        :let={questionnaire}
        id="questionnaire-a"
        items={[
          %{
            name: "rating",
            required: true,
            choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
          },
          %{name: "comment"},
          %{name: "archived", disabled: true}
        ]}
        item={Map.get(@state, "questionnaire-a", "rating")}
        shortcuts="letters"
        on_item_change="shadcn:questionnaire-change"
        phx-value-id="questionnaire-a"
        phx-submit="shadcn:questionnaire-submit"
        phx-change="shadcn:questionnaire-answer"
      >
        <.questionnaire_progress context={questionnaire} />
        <.questionnaire_item
          :let={question}
          context={questionnaire}
          name="rating"
          required
          multiple={false}
          invalid={false}
        >
          <.questionnaire_title>How was your visit?</.questionnaire_title>
          <.questionnaire_description id="questionnaire-a-rating-description">
            Choose an answer.
          </.questionnaire_description>
          <.questionnaire_choices context={question}>
            <.questionnaire_choice
              context={question}
              value="good"
              checked={Map.get(Map.get(@state, "questionnaire-a-answers", %{}), "rating") == "good"}
              index={0}
            >
              Good<.questionnaire_choice_description>
                A pleasant visit.
              </.questionnaire_choice_description>
            </.questionnaire_choice>
            <.questionnaire_choice
              context={question}
              value="great"
              checked={Map.get(Map.get(@state, "questionnaire-a-answers", %{}), "rating") == "great"}
              index={1}
            >
              Great
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
              Unavailable
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error context={question} id="questionnaire-a-rating-error" />
        </.questionnaire_item>
        <.questionnaire_item :let={question} context={questionnaire} name="comment">
          <.questionnaire_title>Anything to add?</.questionnaire_title>
          <.questionnaire_input
            context={question}
            id="questionnaire-a-comment-input"
            value={Map.get(Map.get(@state, "questionnaire-a-answers", %{}), "comment", "Thanks!")}
            placeholder="Your feedback"
          />
          <.questionnaire_error context={question} id="questionnaire-a-comment-error" />
        </.questionnaire_item>
        <.questionnaire_item context={questionnaire} name="archived" disabled>
          <.questionnaire_title>Archived question</.questionnaire_title>
        </.questionnaire_item>
        <.questionnaire_actions>
          <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
            questionnaire
          } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
            questionnaire
          } />
        </.questionnaire_actions>
      </.questionnaire>
      <output :if={!is_nil(Map.get(@state, "questionnaire-a-submitted"))} aria-live="polite">Submitted answers: {Map.get(
        @state,
        "questionnaire-a-submitted"
      )}</output><.questionnaire
        :let={questionnaire}
        id="questionnaire-b"
        items={[
          %{
            name: "rating",
            required: true,
            choices: [%{value: "good"}, %{value: "great"}, %{value: "unavailable", disabled: true}]
          },
          %{name: "comment"},
          %{name: "archived", disabled: true}
        ]}
        item={Map.get(@state, "questionnaire-b", "comment")}
        shortcuts="letters"
        on_item_change="shadcn:questionnaire-change"
        phx-value-id="questionnaire-b"
        phx-submit="shadcn:questionnaire-submit"
        phx-change="shadcn:questionnaire-answer"
      >
        <.questionnaire_progress context={questionnaire} />
        <.questionnaire_item
          :let={question}
          context={questionnaire}
          name="rating"
          required
          multiple={false}
          invalid={false}
        >
          <.questionnaire_title>How was your visit?</.questionnaire_title>
          <.questionnaire_description id="questionnaire-b-rating-description">
            Choose an answer.
          </.questionnaire_description>
          <.questionnaire_choices context={question}>
            <.questionnaire_choice
              context={question}
              value="good"
              checked={Map.get(Map.get(@state, "questionnaire-b-answers", %{}), "rating") == "good"}
              index={0}
            >
              Good<.questionnaire_choice_description>
                A pleasant visit.
              </.questionnaire_choice_description>
            </.questionnaire_choice>
            <.questionnaire_choice
              context={question}
              value="great"
              checked={Map.get(Map.get(@state, "questionnaire-b-answers", %{}), "rating") == "great"}
              index={1}
            >
              Great
            </.questionnaire_choice>
            <.questionnaire_choice context={question} value="unavailable" disabled index={2}>
              Unavailable
            </.questionnaire_choice>
          </.questionnaire_choices>
          <.questionnaire_error context={question} id="questionnaire-b-rating-error" />
        </.questionnaire_item>
        <.questionnaire_item :let={question} context={questionnaire} name="comment">
          <.questionnaire_title>Anything to add?</.questionnaire_title>
          <.questionnaire_input
            context={question}
            id="questionnaire-b-comment-input"
            value={Map.get(Map.get(@state, "questionnaire-b-answers", %{}), "comment", "Thanks!")}
            placeholder="Your feedback"
          />
          <.questionnaire_error context={question} id="questionnaire-b-comment-error" />
        </.questionnaire_item>
        <.questionnaire_item context={questionnaire} name="archived" disabled>
          <.questionnaire_title>Archived question</.questionnaire_title>
        </.questionnaire_item>
        <.questionnaire_actions>
          <.questionnaire_previous context={questionnaire} /><.questionnaire_skip context={
            questionnaire
          } /><.questionnaire_next context={questionnaire} /><.questionnaire_submit context={
            questionnaire
          } />
        </.questionnaire_actions>
      </.questionnaire>
      <output :if={!is_nil(Map.get(@state, "questionnaire-b-submitted"))} aria-live="polite">Submitted answers: {Map.get(
        @state,
        "questionnaire-b-submitted"
      )}</output>
    </div>
    """
  end

  def live_fixture(%{fixture: "questionnaire-selected-choice"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-selected"
      items={[%{name: "color", choices: [%{value: "red"}, %{value: "blue"}]}]}
      item={Map.get(@state, "questionnaire-selected", "color")}
      shortcuts="numbers"
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-selected"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_item :let={question} context={questionnaire} name="color">
        <.questionnaire_title>Color</.questionnaire_title><.questionnaire_choices context={question}>
          <.questionnaire_choice
            context={question}
            value="red"
            checked={
              not Map.has_key?(Map.get(@state, "questionnaire-selected-answers", %{}), "color") or
                Map.get(Map.get(@state, "questionnaire-selected-answers", %{}), "color") == "red"
            }
            index={0}
          >
            Red
          </.questionnaire_choice><.questionnaire_choice
            context={question}
            value="blue"
            checked={
              not Map.has_key?(Map.get(@state, "questionnaire-selected-answers", %{}), "color") or
                Map.get(Map.get(@state, "questionnaire-selected-answers", %{}), "color") == "blue"
            }
            index={1}
          >
            Blue
          </.questionnaire_choice>
        </.questionnaire_choices><.questionnaire_submit context={questionnaire} disabled />
      </.questionnaire_item>
    </.questionnaire>
    """
  end

  def live_fixture(%{fixture: "message-scroller-default-button"} = assigns) do
    ~H"""
    <.message_scroller_provider :let={scroll} default_scroll_position="start">
      <.message_scroller id="stream-buttons" context={scroll}>
        <.message_scroller_button /><.message_scroller_button direction="start" />
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def live_fixture(%{fixture: "questionnaire-input-states"} = assigns) do
    ~H"""
    <.questionnaire
      :let={questionnaire}
      id="questionnaire-inputs"
      items={[%{name: "email", required: true}]}
      item={Map.get(@state, "questionnaire-inputs", "email")}
      no_validate={false}
      on_item_change="shadcn:questionnaire-change"
      phx-value-id="questionnaire-inputs"
      phx-submit="shadcn:questionnaire-submit"
      phx-change="shadcn:questionnaire-answer"
    >
      <.questionnaire_item :let={question} context={questionnaire} name="email" required>
        <.questionnaire_title>Your email</.questionnaire_title><.questionnaire_input
          context={question}
          id="questionnaire-email"
          type="email"
          value={Map.get(Map.get(@state, "questionnaire-inputs-answers", %{}), "email", "")}
          placeholder="you@example.com"
          required
        /><.questionnaire_input context={question} id="questionnaire-locked" value="locked" disabled /><.questionnaire_error
          context={question}
          id="questionnaire-email-error"
        />
      </.questionnaire_item>
    </.questionnaire><output
      :if={!is_nil(Map.get(@state, "questionnaire-inputs-submitted"))}
      aria-live="polite"
    >Submitted email: {Map.get(@state, "questionnaire-inputs-submitted")}</output>
    """
  end

  def live_fixture(%{fixture: "radio-group"} = assigns) do
    ~H"""
    <.radio_group
      :let={group}
      id="density"
      value={Map.get(@state, "density", "comfortable")}
      on_value_change="shadcn:selection-change"
    >
      <div class="flex items-center space-x-2">
        <.radio_group_item context={group} value="default" id="r1" /><.label for="r1">Default</.label>
      </div>
      <div class="flex items-center space-x-2">
        <.radio_group_item context={group} value="comfortable" id="r2" /><.label for="r2">
          Comfortable
        </.label>
      </div>
    </.radio_group>
    """
  end

  def live_fixture(%{fixture: "radio-group-required-vertical"} = assigns) do
    ~H"""
    <form id="shipping-form" class="grid gap-4" phx-submit="preview:form">
      <.radio_group
        :let={group}
        id="shipping"
        name="shipping"
        required
        orientation="vertical"
        value={Map.get(@state, "shipping", "standard")}
        on_value_change="shadcn:selection-change"
      >
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="standard" value="standard" class="peer" /><.label for="standard">
            Standard
          </.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="express" value="express" disabled class="peer" /><.label for="express">
            Express
          </.label>
        </div>
        <div class="flex items-center space-x-2">
          <.radio_group_item context={group} id="overnight" value="overnight" class="peer" /><.label for="overnight">
            Overnight
          </.label>
        </div>
      </.radio_group><.button type="submit" class="justify-self-start">Submit shipping</.button><output
        aria-live="polite"
        class="text-sm text-muted-foreground"
      >Submitted shipping: {Map.get(@form_data, "shipping", "none")}</output>
    </form>
    """
  end

  def live_fixture(%{fixture: "radio-group-controlled"} = assigns) do
    ~H"""
    <.radio_group
      :let={group}
      id="plan"
      name="plan"
      value={Map.get(@state, "plan", "pro")}
      orientation="horizontal"
      loop={false}
      dir="rtl"
      on_value_change="shadcn:selection-change"
    >
      <.radio_group_item context={group} id="basic-plan" value="basic" aria-label="Basic" /><.radio_group_item
        context={group}
        id="pro-plan"
        value="pro"
        aria-label="Pro"
      />
    </.radio_group>
    """
  end

  def live_fixture(%{fixture: "radio-group-disabled-external-form"} = assigns) do
    ~H"""
    <div>
      <form id="external-radio-form"></form><.radio_group
        :let={group}
        id="disabled-radios"
        name="choice"
        form="external-radio-form"
        disabled
        value={Map.get(@state, "disabled-radios", "yes")}
        on_value_change="shadcn:selection-change"
      >
        <.radio_group_item context={group} id="disabled-yes" value="yes" /><.radio_group_item
          context={group}
          id="disabled-no"
          value="no"
        />
      </.radio_group>
    </div>
    """
  end

  def live_fixture(%{fixture: "radio-group-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.radio_group
        :let={group}
        id="first-radio"
        value={Map.get(@state, "first-radio", "b")}
        on_value_change="shadcn:selection-change"
      >
        <.radio_group_item context={group} id="first-radio-a" value="a" /><.radio_group_item
          context={group}
          id="first-radio-b"
          value="b"
        />
      </.radio_group><.radio_group
        :let={group}
        id="second-radio"
        value={Map.get(@state, "second-radio", "")}
        on_value_change="shadcn:selection-change"
      >
        <.radio_group_item context={group} id="second-radio-a" value="a" /><.radio_group_item
          context={group}
          id="second-radio-b"
          value="b"
        />
      </.radio_group>
    </div>
    """
  end

  def live_fixture(%{fixture: "toggle-group"} = assigns) do
    ~H"""
    <.toggle_group
      :let={group}
      id="formatting"
      type="multiple"
      value={Map.get(@state, "formatting", [])}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="format-bold" value="bold" aria-label="Toggle bold">
        B
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="format-italic"
        value="italic"
        aria-label="Toggle italic"
      >
        I
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="format-underline"
        value="underline"
        aria-label="Toggle underline"
      >
        U
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def live_fixture(%{fixture: "toggle-group-single-vertical"} = assigns) do
    ~H"""
    <.toggle_group
      :let={group}
      id="alignment"
      type="single"
      orientation="vertical"
      spacing={0}
      variant="outline"
      size="sm"
      value={Map.get(@state, "alignment", "center")}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="align-left" value="left" aria-label="Left">
        L
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="align-center"
        value="center"
        aria-label="Center"
      >
        C
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="align-right"
        value="right"
        aria-label="Right"
        disabled
      >
        R
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def live_fixture(%{fixture: "toggle-group-multiple-default"} = assigns) do
    ~H"""
    <.toggle_group
      :let={group}
      id="styles"
      type="multiple"
      spacing={3}
      size="lg"
      value={Map.get(@state, "styles", ["bold", "italic"])}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="styles-bold" value="bold">B</.toggle_group_item><.toggle_group_item
        context={group}
        id="styles-italic"
        value="italic"
      >
        I
      </.toggle_group_item><.toggle_group_item context={group} id="styles-underline" value="underline">
        U
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def live_fixture(%{fixture: "toggle-group-controlled"} = assigns) do
    ~H"""
    <.toggle_group
      :let={group}
      id="controlled-format"
      type="multiple"
      value={Map.get(@state, "controlled-format", ["bold"])}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="controlled-bold" value="bold">B</.toggle_group_item><.toggle_group_item
        context={group}
        id="controlled-italic"
        value="italic"
      >
        I
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def live_fixture(%{fixture: "toggle-group-disabled"} = assigns) do
    ~H"""
    <.toggle_group
      :let={group}
      id="disabled-toggles"
      type="single"
      disabled
      roving_focus={false}
      value={Map.get(@state, "disabled-toggles", "one")}
      on_value_change="shadcn:selection-change"
    >
      <.toggle_group_item context={group} id="disabled-toggle-one" value="one">
        One
      </.toggle_group_item><.toggle_group_item
        context={group}
        id="disabled-toggle-two"
        value="two"
        variant="outline"
        size="sm"
      >
        Two
      </.toggle_group_item>
    </.toggle_group>
    """
  end

  def live_fixture(%{fixture: "toggle-group-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.toggle_group
        :let={group}
        id="first-toggle"
        type="single"
        value={Map.get(@state, "first-toggle", "x")}
        on_value_change="shadcn:selection-change"
      >
        <.toggle_group_item context={group} id="first-toggle-x" value="x">X</.toggle_group_item><.toggle_group_item
          context={group}
          id="first-toggle-y"
          value="y"
        >
          Y
        </.toggle_group_item>
      </.toggle_group><.toggle_group
        :let={group}
        id="second-toggle"
        type="multiple"
        value={Map.get(@state, "second-toggle", ["y"])}
        on_value_change="shadcn:selection-change"
        dir="rtl"
        loop={false}
      >
        <.toggle_group_item context={group} id="second-toggle-x" value="x">X</.toggle_group_item><.toggle_group_item
          context={group}
          id="second-toggle-y"
          value="y"
        >
          Y
        </.toggle_group_item>
      </.toggle_group>
    </div>
    """
  end

  def live_fixture(%{fixture: "menubar"} = assigns) do
    ~H"""
    <.menubar :let={bar} id="app-menu" value={Map.get(@state, "app-menu", "")}>
      <.menubar_menu id="app-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>New Tab</.menubar_item><.menubar_item>New Window</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "menubar-default-open"} = assigns) do
    ~H"""
    <.menubar :let={bar} id="open-menu" value={Map.get(@state, "open-menu", "file")}>
      <.menubar_menu id="open-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_label>Workspace</.menubar_label><.menubar_item>
              New Tab<.menubar_shortcut>⌘T</.menubar_shortcut>
            </.menubar_item><.menubar_item disabled>Unavailable</.menubar_item><.menubar_separator /><.menubar_item
              inset
              variant="destructive"
            >
              Delete
            </.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu><.menubar_menu id="open-edit" context={bar} value="edit">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>Edit</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>Undo</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "menubar-controlled"} = assigns) do
    ~H"""
    <.menubar
      :let={bar}
      id="controlled-menu"
      value={Map.get(@state, "controlled-menu", "edit")}
      on_value_change="shadcn:menubar-change"
    >
      <.menubar_menu id="controlled-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>New</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu><.menubar_menu id="controlled-edit" context={bar} value="edit">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>Edit</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_item>Undo</.menubar_item><.menubar_item>Redo</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "menubar-check-radio-submenu"} = assigns) do
    ~H"""
    <.menubar :let={bar} id="view-menu" value={Map.get(@state, "view-menu", "view")}>
      <.menubar_menu id="view-options" context={bar} value="view">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>View</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_checkbox_item id="show-status" checked={Map.get(@state, "show-status", true)}>
              Show status
            </.menubar_checkbox_item><.menubar_checkbox_item id="show-panel" checked={false} disabled>
              Show panel
            </.menubar_checkbox_item><.menubar_checkbox_item
              id="mixed-panel"
              checked={Map.get(@state, "mixed-panel", "indeterminate")}
            >
              Mixed panel
            </.menubar_checkbox_item><.menubar_radio_group
              :let={radio}
              id="theme-menu"
              value={Map.get(@state, "theme-menu", "light")}
            >
              <.menubar_radio_item context={radio} id="theme-light" value="light">
                Light
              </.menubar_radio_item><.menubar_radio_item context={radio} id="theme-dark" value="dark">
                Dark
              </.menubar_radio_item>
            </.menubar_radio_group><.menubar_sub
              id="more-options"
              open={Map.get(@state, "more-options", false)}
            >
              <:trigger :let={sub}>
                <.menubar_sub_trigger context={sub}>More</.menubar_sub_trigger>
              </:trigger><:content :let={sub}>
                <.menubar_sub_content context={sub}>
                  <.menubar_item>Details</.menubar_item>
                </.menubar_sub_content>
              </:content>
            </.menubar_sub>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "menubar-multiple-disabled"} = assigns) do
    ~H"""
    <div>
      <.menubar :let={bar} id="first-menu" value={Map.get(@state, "first-menu", "")} loop={false}>
        <.menubar_menu id="first-file" context={bar} value="file">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>File</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>New</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu><.menubar_menu id="first-locked" context={bar} value="locked">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu} disabled>Locked</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>Locked action</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
      </.menubar><.menubar
        :let={bar}
        id="second-menu"
        dir="rtl"
        value={Map.get(@state, "second-menu", "help")}
      >
        <.menubar_menu id="second-help" context={bar} value="help">
          <:trigger :let={menu}>
            <.menubar_trigger context={menu}>Help</.menubar_trigger>
          </:trigger><:content :let={menu}>
            <.menubar_content context={menu}>
              <.menubar_item>About</.menubar_item>
            </.menubar_content>
          </:content>
        </.menubar_menu>
      </.menubar>
    </div>
    """
  end

  def live_fixture(%{fixture: "menubar-submenu-open"} = assigns) do
    ~H"""
    <.menubar :let={bar} id="submenu-open" value={Map.get(@state, "submenu-open", "file")}>
      <.menubar_menu id="submenu-file" context={bar} value="file">
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu}>
            <.menubar_sub id="submenu-more" open={Map.get(@state, "submenu-more", true)}>
              <:trigger :let={sub}>
                <.menubar_sub_trigger context={sub}>More</.menubar_sub_trigger>
              </:trigger><:content :let={sub}>
                <.menubar_sub_content context={sub}>
                  <.menubar_item>Details</.menubar_item>
                </.menubar_sub_content>
              </:content>
            </.menubar_sub>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "menubar-explicit-relations"} = assigns) do
    ~H"""
    <.menubar :let={bar} id="explicit-menu" value={Map.get(@state, "explicit-menu", "file")}>
      <.menubar_menu
        id="explicit-file"
        trigger_id="explicit-file-trigger"
        content_id="explicit-file-content"
        context={bar}
        value="file"
      >
        <:trigger :let={menu}>
          <.menubar_trigger context={menu}>File</.menubar_trigger>
        </:trigger><:content :let={menu}>
          <.menubar_content context={menu} align="end" side_offset={12} align_offset={0}>
            <.menubar_item>New</.menubar_item>
          </.menubar_content>
        </:content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def live_fixture(%{fixture: "checkbox"} = assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <.checkbox id="terms" checked={Map.get(@state, "terms", false)} on_change="control_change" /><label
        for="terms"
        class="text-sm font-medium leading-none"
      >Accept terms</label>
    </div>
    """
  end

  def live_fixture(%{fixture: "checkbox-false-enabled"} = assigns) do
    ~H"""
    <form id="checkbox-false-enabled-form">
      <.checkbox
        id="checkbox-false-enabled"
        checked={Map.get(@state, "checkbox-false-enabled", false)}
        on_change="control_change"
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-false-disabled"} = assigns) do
    ~H"""
    <form id="checkbox-false-disabled-form">
      <.checkbox
        id="checkbox-false-disabled"
        checked={Map.get(@state, "checkbox-false-disabled", false)}
        on_change="control_change"
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-true-enabled"} = assigns) do
    ~H"""
    <form id="checkbox-true-enabled-form">
      <.checkbox
        id="checkbox-true-enabled"
        checked={Map.get(@state, "checkbox-true-enabled", true)}
        on_change="control_change"
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-true-disabled"} = assigns) do
    ~H"""
    <form id="checkbox-true-disabled-form">
      <.checkbox
        id="checkbox-true-disabled"
        checked={Map.get(@state, "checkbox-true-disabled", true)}
        on_change="control_change"
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-indeterminate-enabled"} = assigns) do
    ~H"""
    <form id="checkbox-indeterminate-enabled-form">
      <.checkbox
        id="checkbox-indeterminate-enabled"
        checked={Map.get(@state, "checkbox-indeterminate-enabled", "indeterminate")}
        on_change="control_change"
        disabled={false}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-indeterminate-disabled"} = assigns) do
    ~H"""
    <form id="checkbox-indeterminate-disabled-form">
      <.checkbox
        id="checkbox-indeterminate-disabled"
        checked={Map.get(@state, "checkbox-indeterminate-disabled", "indeterminate")}
        on_change="control_change"
        disabled={true}
        required
        name="permission"
        value="allow"
        aria-label="Permission"
        class="size-5"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "checkbox-multiple-external-form"} = assigns) do
    ~H"""
    <div>
      <form id="checkbox-external"><button type="reset">Reset permissions</button></form><.checkbox
        id="permission-read"
        checked={Map.get(@state, "permission-read", true)}
        on_change="control_change"
        name="permissions[]"
        value="read"
        form="checkbox-external"
        aria-label="Read"
      /><.checkbox
        id="permission-write"
        checked={Map.get(@state, "permission-write", false)}
        on_change="control_change"
        name="permissions[]"
        value="write"
        form="checkbox-external"
        aria-label="Write"
      />
    </div>
    """
  end

  def live_fixture(%{fixture: "switch"} = assigns) do
    ~H"""
    <.switch
      id="airplane-mode"
      checked={Map.get(@state, "airplane-mode", false)}
      on_change="control_change"
    />
    """
  end

  def live_fixture(%{fixture: "switch-default-false-enabled"} = assigns) do
    ~H"""
    <form id="switch-default-false-enabled-form">
      <.switch
        id="switch-default-false-enabled"
        size="default"
        checked={Map.get(@state, "switch-default-false-enabled", false)}
        on_change="control_change"
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-default-false-disabled"} = assigns) do
    ~H"""
    <form id="switch-default-false-disabled-form">
      <.switch
        id="switch-default-false-disabled"
        size="default"
        checked={Map.get(@state, "switch-default-false-disabled", false)}
        on_change="control_change"
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-default-true-enabled"} = assigns) do
    ~H"""
    <form id="switch-default-true-enabled-form">
      <.switch
        id="switch-default-true-enabled"
        size="default"
        checked={Map.get(@state, "switch-default-true-enabled", true)}
        on_change="control_change"
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-default-true-disabled"} = assigns) do
    ~H"""
    <form id="switch-default-true-disabled-form">
      <.switch
        id="switch-default-true-disabled"
        size="default"
        checked={Map.get(@state, "switch-default-true-disabled", true)}
        on_change="control_change"
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-sm-false-enabled"} = assigns) do
    ~H"""
    <form id="switch-sm-false-enabled-form">
      <.switch
        id="switch-sm-false-enabled"
        size="sm"
        checked={Map.get(@state, "switch-sm-false-enabled", false)}
        on_change="control_change"
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-sm-false-disabled"} = assigns) do
    ~H"""
    <form id="switch-sm-false-disabled-form">
      <.switch
        id="switch-sm-false-disabled"
        size="sm"
        checked={Map.get(@state, "switch-sm-false-disabled", false)}
        on_change="control_change"
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-sm-true-enabled"} = assigns) do
    ~H"""
    <form id="switch-sm-true-enabled-form">
      <.switch
        id="switch-sm-true-enabled"
        size="sm"
        checked={Map.get(@state, "switch-sm-true-enabled", true)}
        on_change="control_change"
        disabled={false}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-sm-true-disabled"} = assigns) do
    ~H"""
    <form id="switch-sm-true-disabled-form">
      <.switch
        id="switch-sm-true-disabled"
        size="sm"
        checked={Map.get(@state, "switch-sm-true-disabled", true)}
        on_change="control_change"
        disabled={true}
        required
        name="notifications"
        value="enabled"
        aria-label="Notifications"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "switch-multiple-external-form"} = assigns) do
    ~H"""
    <div>
      <form id="switch-settings"><button type="reset">Reset settings</button></form><.switch
        id="switch-mail"
        checked={Map.get(@state, "switch-mail", true)}
        on_change="control_change"
        name="mail"
        form="switch-settings"
        aria-label="Mail"
      /><.switch
        id="switch-sms"
        size="sm"
        checked={Map.get(@state, "switch-sms", false)}
        on_change="control_change"
        name="sms"
        form="switch-settings"
        aria-label="SMS"
      />
    </div>
    """
  end

  def live_fixture(%{fixture: "slider"} = assigns) do
    ~H"""
    <.slider
      id="slider-base"
      value={Map.get(@state, "slider-base", [50])}
      default_value={[50]}
      on_change="control_change"
      max={100}
      step={1}
      class="w-[60%]"
    />
    """
  end

  def live_fixture(%{fixture: "slider-lower-bound"} = assigns) do
    ~H"""
    <form id="slider-lower-bound-form">
      <.slider
        id="slider-lower-bound"
        min={-10}
        max={10}
        step={0.5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-lower-bound", [-10])}
        default_value={[-10]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-upper-bound"} = assigns) do
    ~H"""
    <form id="slider-upper-bound-form">
      <.slider
        id="slider-upper-bound"
        min={-10}
        max={10}
        step={0.5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-upper-bound", [10])}
        default_value={[10]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-range"} = assigns) do
    ~H"""
    <form id="slider-range-form">
      <.slider
        id="slider-range"
        min={10}
        max={90}
        step={5}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-range", [20, 80])}
        default_value={[20, 80]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-three-thumbs"} = assigns) do
    ~H"""
    <form id="slider-three-thumbs-form">
      <.slider
        id="slider-three-thumbs"
        min={0}
        max={100}
        step={10}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-three-thumbs", [10, 40, 80])}
        default_value={[10, 40, 80]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-vertical"} = assigns) do
    ~H"""
    <form id="slider-vertical-form">
      <.slider
        id="slider-vertical"
        min={0}
        max={50}
        step={5}
        orientation="vertical"
        dir="ltr"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-vertical", [25])}
        default_value={[25]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-rtl"} = assigns) do
    ~H"""
    <form id="slider-rtl-form">
      <.slider
        id="slider-rtl"
        min={0}
        max={100}
        step={5}
        orientation="horizontal"
        dir="rtl"
        inverted={false}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-rtl", [15, 70])}
        default_value={[15, 70]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-inverted"} = assigns) do
    ~H"""
    <form id="slider-inverted-form">
      <.slider
        id="slider-inverted"
        min={0}
        max={100}
        step={5}
        orientation="horizontal"
        dir="ltr"
        inverted={true}
        disabled={false}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-inverted", [35])}
        default_value={[35]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-disabled"} = assigns) do
    ~H"""
    <form id="slider-disabled-form">
      <.slider
        id="slider-disabled"
        min={0}
        max={90}
        step={3}
        orientation="horizontal"
        dir="ltr"
        inverted={false}
        disabled={true}
        name="amount"
        aria-label="Amount"
        class="w-64"
        value={Map.get(@state, "slider-disabled", [30, 60])}
        default_value={[30, 60]}
        on_change="control_change"
      /><button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-default-extents"} = assigns) do
    ~H"""
    <.slider
      id="slider-default-extents"
      value={Map.get(@state, "slider-default-extents", [10, 30])}
      default_value={[10, 30]}
      on_change="control_change"
      min={10}
      max={30}
    />
    """
  end

  def live_fixture(%{fixture: "slider-multiple-instances"} = assigns) do
    ~H"""
    <form id="slider-multiple-form" class="w-64 space-y-4">
      <.slider
        id="slider-price"
        value={Map.get(@state, "slider-price", [5, 15])}
        default_value={[5, 15]}
        on_change="control_change"
        min={0}
        max={20}
        step={1}
        name="price"
      /><.slider
        id="slider-rating"
        value={Map.get(@state, "slider-rating", [3])}
        default_value={[3]}
        on_change="control_change"
        min={1}
        max={5}
        step={1}
        name="rating"
      />
    </form>
    """
  end

  def live_fixture(%{fixture: "slider-external-form"} = assigns) do
    ~H"""
    <div>
      <form id="slider-external-form"></form><.slider
        id="slider-external"
        class="w-64"
        value={Map.get(@state, "slider-external", [2])}
        default_value={[2]}
        on_change="control_change"
        min={0}
        max={10}
        step={0.25}
        name="quantity"
        form="slider-external-form"
      />
    </div>
    """
  end

  def live_fixture(%{fixture: "slider-minimum-thumb-distance"} = assigns) do
    ~H"""
    <.slider
      id="slider-thumb-distance"
      value={Map.get(@state, "slider-thumb-distance", [20, 60])}
      on_change="control_change"
      min={0}
      max={100}
      step={5}
      min_steps_between_thumbs={2}
    />
    """
  end

  def live_fixture(%{fixture: "collapsible"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-base"
      open={Map.get(@state, "collapsible-base", true)}
    >
      <.collapsible_trigger context={context} class="px-4 py-2 text-sm font-medium">
        Toggle Details
      </.collapsible_trigger><.collapsible_content context={context} class="px-4 py-2 text-sm">
        Here is collapsible content.
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-closed-enabled"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-closed-enabled"
      open={Map.get(@state, "collapsible-closed-enabled", false)}
      disabled={false}
    >
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-closed-disabled"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-closed-disabled"
      open={Map.get(@state, "collapsible-closed-disabled", false)}
      disabled={true}
    >
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-open-enabled"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-open-enabled"
      open={Map.get(@state, "collapsible-open-enabled", true)}
      disabled={false}
    >
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-open-disabled"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-open-disabled"
      open={Map.get(@state, "collapsible-open-disabled", true)}
      disabled={true}
    >
      <.collapsible_trigger context={context}>Details</.collapsible_trigger><.collapsible_content context={
        context
      }>
        <p>Scoped content</p>
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-force-mount"} = assigns) do
    ~H"""
    <.collapsible
      :let={context}
      id="collapsible-forced"
      open={Map.get(@state, "collapsible-forced", false)}
    >
      <.collapsible_trigger context={context}>More</.collapsible_trigger><.collapsible_content
        context={context}
        force_mount={true}
      >
        Always mounted
      </.collapsible_content>
    </.collapsible>
    """
  end

  def live_fixture(%{fixture: "collapsible-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.collapsible :let={context} id="details-one" open={Map.get(@state, "details-one", true)}>
        <.collapsible_trigger context={context}>One</.collapsible_trigger><.collapsible_content context={
          context
        }>
          First
        </.collapsible_content>
      </.collapsible><.collapsible
        :let={context}
        id="details-two"
        open={Map.get(@state, "details-two", false)}
      >
        <.collapsible_trigger context={context}>Two</.collapsible_trigger><.collapsible_content context={
          context
        }>
          Second
        </.collapsible_content>
      </.collapsible>
    </div>
    """
  end

  def live_fixture(%{fixture: "navigation-menu"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-base"
      value={Map.get(@state, "navigation-base", "")}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item context={context} value="docs">
          <.navigation_menu_link href="/docs">Documentation</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-inline-closed"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-inline-closed"
      value={Map.get(@state, "navigation-inline-closed", "")}
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-inline-docs"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-inline-docs"
      value={Map.get(@state, "navigation-inline-docs", "docs")}
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-inline-about"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-inline-about"
      value={Map.get(@state, "navigation-inline-about", "about")}
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-viewport-closed"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-viewport-closed"
      value={Map.get(@state, "navigation-viewport-closed", "")}
      viewport={true}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-viewport-docs"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-viewport-docs"
      value={Map.get(@state, "navigation-viewport-docs", "docs")}
      viewport={true}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-viewport-about"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-viewport-about"
      value={Map.get(@state, "navigation-viewport-about", "about")}
      viewport={true}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/docs" active={true}>Guide</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item :let={item} context={context} value="about">
          <.navigation_menu_trigger context={item}>About</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            <.navigation_menu_link href="/about">Company</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="home">
          <.navigation_menu_link href="/">Home</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-vertical-rtl-disabled"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-vertical"
      value={Map.get(@state, "navigation-vertical", "")}
      orientation="vertical"
      dir="rtl"
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="locked">
          <.navigation_menu_trigger context={item} disabled>Locked</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            Unavailable
          </.navigation_menu_content>
        </.navigation_menu_item><.navigation_menu_item context={context} value="active">
          <.navigation_menu_link active href="/active">Active</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-force-mount"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-forced"
      value={Map.get(@state, "navigation-forced", "")}
      viewport={false}
    >
      <.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content
            context={item}
            force_mount={true}
          >
            Mounted docs
          </.navigation_menu_content>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "navigation-multiple-instances"} = assigns) do
    ~H"""
    <div>
      <.navigation_menu
        :let={context}
        id="navigation-primary"
        viewport={false}
        value={Map.get(@state, "navigation-primary", "docs")}
      >
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
              item
            }>
              <.navigation_menu_link href="/docs">Guide</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu><.navigation_menu
        :let={context}
        id="navigation-secondary"
        viewport={false}
        value={Map.get(@state, "navigation-secondary", "")}
      >
        <.navigation_menu_list context={context}>
          <.navigation_menu_item :let={item} context={context} value="docs">
            <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
              item
            }>
              <.navigation_menu_link href="/docs">Guide</.navigation_menu_link>
            </.navigation_menu_content>
          </.navigation_menu_item>
        </.navigation_menu_list>
      </.navigation_menu>
    </div>
    """
  end

  def live_fixture(%{fixture: "navigation-indicator"} = assigns) do
    ~H"""
    <.navigation_menu
      :let={context}
      id="navigation-indicator"
      value={Map.get(@state, "navigation-indicator", "docs")}
      viewport={false}
    >
      <:indicator /><.navigation_menu_list context={context}>
        <.navigation_menu_item :let={item} context={context} value="docs">
          <.navigation_menu_trigger context={item}>Docs</.navigation_menu_trigger><.navigation_menu_content context={
            item
          }>
            Guide
          </.navigation_menu_content>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def live_fixture(%{fixture: "button-default-default"} = assigns) do
    ~H"""
    <.button variant="default" size="default" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-xs"} = assigns) do
    ~H"""
    <.button variant="default" size="xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-sm"} = assigns) do
    ~H"""
    <.button variant="default" size="sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-lg"} = assigns) do
    ~H"""
    <.button variant="default" size="lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-icon"} = assigns) do
    ~H"""
    <.button variant="default" size="icon" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-icon-xs"} = assigns) do
    ~H"""
    <.button variant="default" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-icon-sm"} = assigns) do
    ~H"""
    <.button variant="default" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-default-icon-lg"} = assigns) do
    ~H"""
    <.button variant="default" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-default"} = assigns) do
    ~H"""
    <.button variant="outline" size="default" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-xs"} = assigns) do
    ~H"""
    <.button variant="outline" size="xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-sm"} = assigns) do
    ~H"""
    <.button variant="outline" size="sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-lg"} = assigns) do
    ~H"""
    <.button variant="outline" size="lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-icon"} = assigns) do
    ~H"""
    <.button variant="outline" size="icon" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-icon-xs"} = assigns) do
    ~H"""
    <.button variant="outline" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-icon-sm"} = assigns) do
    ~H"""
    <.button variant="outline" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-outline-icon-lg"} = assigns) do
    ~H"""
    <.button variant="outline" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-default"} = assigns) do
    ~H"""
    <.button variant="secondary" size="default" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-xs"} = assigns) do
    ~H"""
    <.button variant="secondary" size="xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-sm"} = assigns) do
    ~H"""
    <.button variant="secondary" size="sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-lg"} = assigns) do
    ~H"""
    <.button variant="secondary" size="lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-icon"} = assigns) do
    ~H"""
    <.button variant="secondary" size="icon" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-icon-xs"} = assigns) do
    ~H"""
    <.button variant="secondary" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-icon-sm"} = assigns) do
    ~H"""
    <.button variant="secondary" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-secondary-icon-lg"} = assigns) do
    ~H"""
    <.button variant="secondary" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-default"} = assigns) do
    ~H"""
    <.button variant="ghost" size="default" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-xs"} = assigns) do
    ~H"""
    <.button variant="ghost" size="xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-sm"} = assigns) do
    ~H"""
    <.button variant="ghost" size="sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-lg"} = assigns) do
    ~H"""
    <.button variant="ghost" size="lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-icon"} = assigns) do
    ~H"""
    <.button variant="ghost" size="icon" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-icon-xs"} = assigns) do
    ~H"""
    <.button variant="ghost" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-icon-sm"} = assigns) do
    ~H"""
    <.button variant="ghost" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-ghost-icon-lg"} = assigns) do
    ~H"""
    <.button variant="ghost" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-default"} = assigns) do
    ~H"""
    <.button variant="destructive" size="default" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-xs"} = assigns) do
    ~H"""
    <.button variant="destructive" size="xs" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-sm"} = assigns) do
    ~H"""
    <.button variant="destructive" size="sm" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-lg"} = assigns) do
    ~H"""
    <.button variant="destructive" size="lg" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-icon"} = assigns) do
    ~H"""
    <.button variant="destructive" size="icon" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-icon-xs"} = assigns) do
    ~H"""
    <.button variant="destructive" size="icon-xs" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-icon-sm"} = assigns) do
    ~H"""
    <.button variant="destructive" size="icon-sm" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-destructive-icon-lg"} = assigns) do
    ~H"""
    <.button variant="destructive" size="icon-lg" disabled={true}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-default"} = assigns) do
    ~H"""
    <.button variant="link" size="default" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-xs"} = assigns) do
    ~H"""
    <.button variant="link" size="xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-sm"} = assigns) do
    ~H"""
    <.button variant="link" size="sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-lg"} = assigns) do
    ~H"""
    <.button variant="link" size="lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-icon"} = assigns) do
    ~H"""
    <.button variant="link" size="icon" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-icon-xs"} = assigns) do
    ~H"""
    <.button variant="link" size="icon-xs" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-icon-sm"} = assigns) do
    ~H"""
    <.button variant="link" size="icon-sm" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "button-link-icon-lg"} = assigns) do
    ~H"""
    <.button variant="link" size="icon-lg" disabled={false}>Save</.button>
    """
  end

  def live_fixture(%{fixture: "badge-default"} = assigns) do
    ~H"""
    <.badge variant="default">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "badge-secondary"} = assigns) do
    ~H"""
    <.badge variant="secondary">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "badge-destructive"} = assigns) do
    ~H"""
    <.badge variant="destructive">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "badge-outline"} = assigns) do
    ~H"""
    <.badge variant="outline">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "badge-ghost"} = assigns) do
    ~H"""
    <.badge variant="ghost">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "badge-link"} = assigns) do
    ~H"""
    <.badge variant="link">Status</.badge>
    """
  end

  def live_fixture(%{fixture: "toggle-default-default-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-default-false" variant="default" size="default" pressed={false}>
      Bold
    </.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-default-default-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-default-true" variant="default" size="default" pressed={true}>
      Bold
    </.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-default-sm-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-sm-false" variant="default" size="sm" pressed={false}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-default-sm-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-sm-true" variant="default" size="sm" pressed={true}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-default-lg-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-lg-false" variant="default" size="lg" pressed={false}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-default-lg-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-default-lg-true" variant="default" size="lg" pressed={true}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-default-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-default-false" variant="outline" size="default" pressed={false}>
      Bold
    </.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-default-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-default-true" variant="outline" size="default" pressed={true}>
      Bold
    </.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-sm-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-sm-false" variant="outline" size="sm" pressed={false}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-sm-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-sm-true" variant="outline" size="sm" pressed={true}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-lg-off"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-lg-false" variant="outline" size="lg" pressed={false}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "toggle-outline-lg-on"} = assigns) do
    ~H"""
    <.toggle id="toggle-outline-lg-true" variant="outline" size="lg" pressed={true}>Bold</.toggle>
    """
  end

  def live_fixture(%{fixture: "card-small"} = assigns) do
    ~H"""
    <.card size="sm">
      <.card_content>Compact content</.card_content>
    </.card>
    """
  end

  def live_fixture(%{fixture: "input-invalid-disabled"} = assigns) do
    ~H"""
    <.input
      id="disabled-input"
      name="email"
      type="email"
      value="onni@example.test"
      disabled
      aria-invalid="true"
      class="w-72"
    />
    """
  end

  def live_fixture(%{fixture: "textarea-native-form"} = assigns) do
    ~H"""
    <.textarea id="notes" name="notes" readonly rows="3">Saved notes</.textarea>
    """
  end

  def live_fixture(%{fixture: "alert"} = assigns) do
    ~H"""
    <.alert>
      <.alert_title>Heads up!</.alert_title>
      <.alert_description>You can add components to your app using the cli.</.alert_description>
    </.alert>
    """
  end

  def live_fixture(%{fixture: "aspect-ratio"} = assigns) do
    ~H"""
    <.aspect_ratio ratio={16 / 9} class="bg-muted flex items-center justify-center">
      <span>16:9 Aspect Ratio</span>
    </.aspect_ratio>
    """
  end

  def live_fixture(%{fixture: "attachment"} = assigns) do
    ~H"""
    <.attachment>
      <.attachment_title>document.pdf</.attachment_title>
      <.attachment_description>2.4 MB</.attachment_description>
    </.attachment>
    """
  end

  def live_fixture(%{fixture: "avatar"} = assigns) do
    ~H"""
    <.avatar>
      <.avatar_fallback>CN</.avatar_fallback>
    </.avatar>
    """
  end

  def live_fixture(%{fixture: "badge"} = assigns) do
    ~H"""
    <.badge variant="secondary">New Feature</.badge>
    """
  end

  def live_fixture(%{fixture: "breadcrumb"} = assigns) do
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="/">Home</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Components</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  def live_fixture(%{fixture: "bubble"} = assigns) do
    ~H"""
    <.bubble>
      <.bubble_content>Hello from bubble chat!</.bubble_content>
    </.bubble>
    """
  end

  def live_fixture(%{fixture: "button-group"} = assigns) do
    ~H"""
    <.button_group>
      <.button variant="outline">Left</.button>
      <.button variant="outline">Middle</.button>
      <.button variant="outline">Right</.button>
    </.button_group>
    """
  end

  def live_fixture(%{fixture: "button"} = assigns) do
    ~H"""
    <.button phx-click="preview:increment" phx-value-id="button-clicks">{if Map.get(
                                                                              @state,
                                                                              "button-clicks",
                                                                              0
                                                                            ) == 0,
                                                                            do: "Click me",
                                                                            else:
                                                                              "Clicked #{Map.get(@state, "button-clicks")} times"}</.button>
    """
  end

  def live_fixture(%{fixture: "card"} = assigns) do
    ~H"""
    <.card>
      <.card_header>
        <.card_title>Notifications</.card_title>
        <.card_description>You have 3 unread messages.</.card_description>
      </.card_header>
      <.card_content>
        <p>Everything looks good today.</p>
      </.card_content>
      <.card_footer>
        <.button class="w-full">Mark all as read</.button>
      </.card_footer>
    </.card>
    """
  end

  def live_fixture(%{fixture: "direction"} = assigns) do
    ~H"""
    <.direction_provider dir="ltr">
      <div class="p-2 text-sm">Left to right layout</div>
    </.direction_provider>
    """
  end

  def live_fixture(%{fixture: "empty"} = assigns) do
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_title>No data available</.empty_title>
        <.empty_description>Get started by creating your first project.</.empty_description>
      </.empty_header>
    </.empty>
    """
  end

  def live_fixture(%{fixture: "field"} = assigns) do
    ~H"""
    <.field_set class="w-full max-w-md">
      <.field_group>
        <.field>
          <.field_label for="field-email">Email address</.field_label>
          <.input
            id="field-email"
            type="email"
            placeholder="m@example.com"
            aria-describedby="field-help"
          />
          <.field_description id="field-help">We will never share your email.</.field_description>
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  def live_fixture(%{fixture: "field-separator"} = assigns) do
    ~H"""
    <.field_group class="w-full max-w-md">
      <.field_separator />
      <.field_separator class="*:data-[slot=field-separator-content]:bg-card">
        Or continue with
      </.field_separator>
    </.field_group>
    """
  end

  def live_fixture(%{fixture: "input-group"} = assigns) do
    ~H"""
    <.input_group>
      <.input_group_addon>https://</.input_group_addon>
      <.input_group_input placeholder="example.com" />
    </.input_group>
    """
  end

  def live_fixture(%{fixture: "input"} = assigns) do
    ~H"""
    <.input type="email" placeholder="Email" />
    """
  end

  def live_fixture(%{fixture: "item"} = assigns) do
    ~H"""
    <.item>
      <.item_content>
        <.item_title>Basic Item</.item_title>
        <.item_description>Item description text</.item_description>
      </.item_content>
    </.item>
    """
  end

  def live_fixture(%{fixture: "kbd"} = assigns) do
    ~H"""
    <.kbd>Ctrl + K</.kbd>
    """
  end

  def live_fixture(%{fixture: "label"} = assigns) do
    ~H"""
    <div>
      <.label for="test-input">Your email address</.label><.input id="test-input" type="email" />
    </div>
    """
  end

  def live_fixture(%{fixture: "marker"} = assigns) do
    ~H"""
    <.marker class="size-2 bg-emerald-500 rounded-full" />
    """
  end

  def live_fixture(%{fixture: "message"} = assigns) do
    ~H"""
    <.message>
      <.message_content>Hi, how can I help you today?</.message_content>
    </.message>
    """
  end

  def live_fixture(%{fixture: "native-select"} = assigns) do
    ~H"""
    <.native_select>
      <.native_select_option value="1">Option 1</.native_select_option>
      <.native_select_option value="2">Option 2</.native_select_option>
    </.native_select>
    """
  end

  def live_fixture(%{fixture: "native-select-default-selection"} = assigns) do
    ~H"""
    <form id="native-default-form">
      <label for="native-default">Fruit</label>
      <.native_select
        :let={selection}
        id="native-default"
        name="fruit"
        default_value="pear"
        required
        aria-describedby="native-default-help"
        class="w-48 min-w-24 max-w-64"
      >
        <.native_select_option value="" selected={"" in selection}>
          Choose fruit
        </.native_select_option>
        <.native_select_opt_group label="Fruit">
          <.native_select_option value="apple" selected={"apple" in selection}>
            Apple
          </.native_select_option>
          <.native_select_option value="pear" selected={"pear" in selection} class="font-medium">
            Pear
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
      <p id="native-default-help">Choose a fruit.</p>
      <button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "native-select-controlled-small"} = assigns) do
    ~H"""
    <.native_select
      :let={selection}
      id="native-controlled"
      name="quantity"
      value={2}
      size="sm"
      aria-label="Quantity"
      aria-invalid="true"
      class="w-[180px]"
    >
      <.native_select_option value={1} selected={"1" in selection}>One</.native_select_option>
      <.native_select_option value={2} selected={"2" in selection}>Two</.native_select_option>
      <.native_select_option value={3} selected={"3" in selection} disabled>
        Three
      </.native_select_option>
    </.native_select>
    """
  end

  def live_fixture(%{fixture: "native-select-disabled-groups"} = assigns) do
    ~H"""
    <form>
      <.native_select
        :let={selection}
        id="native-disabled"
        name="region"
        disabled
        default_value="west"
        aria-label="Region"
      >
        <.native_select_opt_group label="Unavailable" disabled>
          <.native_select_option value="east" selected={"east" in selection}>
            East
          </.native_select_option>
        </.native_select_opt_group>
        <.native_select_opt_group label="Available">
          <.native_select_option value="west" selected={"west" in selection} label="Western region">
            West
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
    </form>
    """
  end

  def live_fixture(%{fixture: "native-select-multiple-instances"} = assigns) do
    ~H"""
    <form id="native-multiple-form">
      <.native_select
        :let={selection}
        id="native-multiple"
        name="colors"
        multiple
        default_value={["red", "blue"]}
        aria-label="Colors"
      >
        <.native_select_opt_group label="Colors">
          <.native_select_option value="red" selected={"red" in selection}>Red</.native_select_option>
          <.native_select_option value="green" selected={"green" in selection}>
            Green
          </.native_select_option>
          <.native_select_option value="blue" selected={"blue" in selection}>
            Blue
          </.native_select_option>
        </.native_select_opt_group>
      </.native_select>
      <.native_select
        :let={selection}
        id="native-second"
        name="shape"
        default_value="square"
        aria-label="Shape"
      >
        <.native_select_option value="circle" selected={"circle" in selection}>
          Circle
        </.native_select_option>
        <.native_select_option value="square" selected={"square" in selection}>
          Square
        </.native_select_option>
      </.native_select>
      <button type="reset">Reset</button>
    </form>
    """
  end

  def live_fixture(%{fixture: "native-select-empty-controlled"} = assigns) do
    ~H"""
    <.native_select :let={selection} value="" name="empty-choice" aria-label="Empty choice">
      <.native_select_option value="other" selected={"other" in selection}>
        Other
      </.native_select_option>
      <.native_select_option value="" selected={"" in selection}>None</.native_select_option>
    </.native_select>
    """
  end

  def live_fixture(%{fixture: "native-select-controlled-multiple"} = assigns) do
    ~H"""
    <.native_select
      :let={selection}
      multiple
      value={["b", "c"]}
      name="letters"
      aria-label="Letters"
      size="sm"
    >
      <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
      <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
      <.native_select_option value="c" selected={"c" in selection}>C</.native_select_option>
    </.native_select>
    """
  end

  def live_fixture(%{fixture: "native-select-external-form-empty-multiple"} = assigns) do
    ~H"""
    <div>
      <form id="native-external-form"><button type="reset">Reset</button></form>
      <.native_select
        :let={selection}
        id="native-external"
        form="native-external-form"
        name="external-choices"
        multiple
        default_value={[]}
        aria-label="External choices"
      >
        <.native_select_option value="a" selected={"a" in selection}>A</.native_select_option>
        <.native_select_option value="b" selected={"b" in selection}>B</.native_select_option>
      </.native_select>
    </div>
    """
  end

  def live_fixture(%{fixture: "pagination"} = assigns) do
    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous
            href="#page-1"
            phx-click="preview:page"
            phx-value-page={max(1, Map.get(@state, "page", 1) - 1)}
          />
        </.pagination_item>
        <.pagination_item :for={page <- 1..3}>
          <.pagination_link
            href={"#page-#{page}"}
            is_active={Map.get(@state, "page", 1) == page}
            phx-click="preview:page"
            phx-value-page={page}
          >{page}</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_next
            href="#page-3"
            phx-click="preview:page"
            phx-value-page={min(3, Map.get(@state, "page", 1) + 1)}
          />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  def live_fixture(%{fixture: "progress"} = assigns) do
    ~H"""
    <.progress value={60} class="w-[60%]" />
    """
  end

  def live_fixture(%{fixture: "progress-absent"} = assigns) do
    ~H"""
    <.progress />
    """
  end

  def live_fixture(%{fixture: "progress-null"} = assigns) do
    ~H"""
    <.progress value={nil} />
    """
  end

  def live_fixture(%{fixture: "progress-zero"} = assigns) do
    ~H"""
    <.progress value={0} />
    """
  end

  def live_fixture(%{fixture: "progress-fractional"} = assigns) do
    ~H"""
    <.progress value={25.5} />
    """
  end

  def live_fixture(%{fixture: "progress-complete"} = assigns) do
    ~H"""
    <.progress value={100} />
    """
  end

  def live_fixture(%{fixture: "progress-custom-max"} = assigns) do
    ~H"""
    <.progress value={50} max={200} />
    """
  end

  def live_fixture(%{fixture: "progress-null-max"} = assigns) do
    ~H"""
    <.progress value={40} max={nil} />
    """
  end

  def live_fixture(%{fixture: "progress-outside-visual-range"} = assigns) do
    ~H"""
    <.progress value={125} max={80} />
    """
  end

  def live_fixture(%{fixture: "progress-custom-class-aria"} = assigns) do
    ~H"""
    <.progress
      value={75}
      class="w-[180px] min-w-24 max-w-64 h-2 bg-primary"
      id="upload-progress"
      aria-label="Upload"
      aria-valuetext="Uploading"
    />
    """
  end

  def live_fixture(%{fixture: "scroll-area"} = assigns) do
    ~H"""
    <.scroll_area id="scroll-area-demo" class="h-32 w-48 rounded-md border p-4">
      <div :for={n <- 1..20} class="py-2">Item {n}</div>
    </.scroll_area>
    """
  end

  def live_fixture(%{fixture: "separator"} = assigns) do
    ~H"""
    <.separator class="my-4" />
    """
  end

  def live_fixture(%{fixture: "skeleton"} = assigns) do
    ~H"""
    <.skeleton class="h-4 w-[250px]" />
    """
  end

  def live_fixture(%{fixture: "sonner"} = assigns) do
    ~H"""
    <form phx-submit="preview:toast" class="grid gap-2">
      <.input name="message" aria-label="Notification message" value="Event has been created" />
      <.button type="submit" name="duration" value="0">Show notification</.button>
      <.button type="submit" name="duration" value="1000">Show brief notification</.button>
    </form><.toaster id="preview-toaster" />
    """
  end

  def live_fixture(%{fixture: "spinner"} = assigns) do
    ~H"""
    <.spinner class="size-6 text-primary" />
    """
  end

  def live_fixture(%{fixture: "table"} = assigns) do
    ~H"""
    <.table>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">Invoice</.table_head>
          <.table_head>Status</.table_head>
          <.table_head class="text-right">Amount</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row>
          <.table_cell class="font-medium">INV001</.table_cell>
          <.table_cell>Paid</.table_cell>
          <.table_cell class="text-right">$250.00</.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  def live_fixture(%{fixture: "textarea"} = assigns) do
    ~H"""
    <.textarea placeholder="Type your message here." />
    """
  end

  def live_fixture(%{fixture: "toggle"} = assigns) do
    ~H"""
    <.toggle
      id="italic-toggle"
      pressed={Map.get(@state, "italic-toggle", false)}
      on_change="control_change"
      aria-label="Toggle italic"
    >
      B
    </.toggle>
    """
  end

  def live_fixture(%{fixture: fixture}),
    do: raise(ArgumentError, "Unknown component fixture: #{inspect(fixture)}")
end
