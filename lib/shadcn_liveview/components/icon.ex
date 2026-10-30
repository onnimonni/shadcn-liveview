defmodule ShadcnLiveview.Components.Icon do
  @moduledoc """
  A curated subset of Lucide icons: the ones the vendored components render plus common
  app icons (navigation, CRUD actions, auth, status, media). Geometry and classes are
  generated from the pinned `lucide-react` 1.52.0 package, so markup matches React.

  See `icon/1` for every supported name. Names starting with `hero-` render like Phoenix
  1.8 `CoreComponents.icon/1`, so this module can replace that function. Other unknown
  names raise `ArgumentError` instead of rendering a substitute.
  """
  use Phoenix.Component

  @issues_url "https://github.com/onnimonni/shadcn-liveview/issues"

  @icon_classes %{
    "archive" => "lucide lucide-archive",
    "arrow-down" => "lucide lucide-arrow-down",
    "arrow-left" => "lucide lucide-arrow-left",
    "arrow-right" => "lucide lucide-arrow-right",
    "arrow-up" => "lucide lucide-arrow-up",
    "arrow-up-down" => "lucide lucide-arrow-up-down",
    "arrow-up-right" => "lucide lucide-arrow-up-right",
    "at-sign" => "lucide lucide-at-sign",
    "bell" => "lucide lucide-bell",
    "bookmark" => "lucide lucide-bookmark",
    "briefcase" => "lucide lucide-briefcase",
    "building" => "lucide lucide-building",
    "calendar" => "lucide lucide-calendar",
    "chart-bar" => "lucide lucide-chart-bar lucide-bar-chart-horizontal",
    "chart-column" => "lucide lucide-chart-column lucide-bar-chart-3",
    "chart-line" => "lucide lucide-chart-line lucide-line-chart",
    "chart-pie" => "lucide lucide-chart-pie lucide-pie-chart",
    "check" => "lucide lucide-check",
    "chevron-down" => "lucide lucide-chevron-down",
    "chevron-left" => "lucide lucide-chevron-left",
    "chevron-right" => "lucide lucide-chevron-right",
    "chevron-up" => "lucide lucide-chevron-up",
    "chevrons-left" => "lucide lucide-chevrons-left",
    "chevrons-right" => "lucide lucide-chevrons-right",
    "chevrons-up-down" => "lucide lucide-chevrons-up-down",
    "circle" => "lucide lucide-circle",
    "circle-alert" => "lucide lucide-circle-alert lucide-alert-circle",
    "circle-check" => "lucide lucide-circle-check lucide-check-circle-2",
    "circle-dot" => "lucide lucide-circle-dot",
    "circle-plus" => "lucide lucide-circle-plus lucide-plus-circle",
    "circle-question-mark" =>
      "lucide lucide-circle-question-mark lucide-help-circle lucide-circle-help",
    "circle-user" => "lucide lucide-circle-user lucide-user-circle",
    "circle-x" => "lucide lucide-circle-x lucide-x-circle",
    "clock" => "lucide lucide-clock",
    "columns-3" => "lucide lucide-columns-3 lucide-panels-left-right",
    "copy" => "lucide lucide-copy",
    "credit-card" => "lucide lucide-credit-card",
    "dollar-sign" => "lucide lucide-dollar-sign",
    "download" => "lucide lucide-download",
    "ellipsis" => "lucide lucide-ellipsis lucide-more-horizontal",
    "ellipsis-vertical" => "lucide lucide-ellipsis-vertical lucide-more-vertical",
    "external-link" => "lucide lucide-external-link",
    "eye" => "lucide lucide-eye",
    "eye-off" => "lucide lucide-eye-off",
    "file-text" => "lucide lucide-file-text",
    "flag" => "lucide lucide-flag",
    "folder" => "lucide lucide-folder",
    "funnel" => "lucide lucide-funnel lucide-filter",
    "globe" => "lucide lucide-globe",
    "grip-vertical" => "lucide lucide-grip-vertical",
    "hash" => "lucide lucide-hash",
    "heart" => "lucide lucide-heart",
    "house" => "lucide lucide-house lucide-home",
    "image" => "lucide lucide-image",
    "inbox" => "lucide lucide-inbox",
    "info" => "lucide lucide-info",
    "key" => "lucide lucide-key",
    "layout-dashboard" => "lucide lucide-layout-dashboard",
    "link" => "lucide lucide-link",
    "list" => "lucide lucide-list",
    "list-todo" => "lucide lucide-list-todo",
    "loader" => "lucide lucide-loader",
    "loader-circle" => "lucide lucide-loader-circle lucide-loader-2",
    "lock" => "lucide lucide-lock",
    "log-in" => "lucide lucide-log-in",
    "log-out" => "lucide lucide-log-out",
    "mail" => "lucide lucide-mail",
    "map-pin" => "lucide lucide-map-pin",
    "menu" => "lucide lucide-menu",
    "message-square" => "lucide lucide-message-square",
    "minus" => "lucide lucide-minus",
    "monitor" => "lucide lucide-monitor",
    "moon" => "lucide lucide-moon",
    "octagon-x" => "lucide lucide-octagon-x lucide-x-octagon",
    "panel-left" => "lucide lucide-panel-left lucide-sidebar",
    "paperclip" => "lucide lucide-paperclip",
    "pause" => "lucide lucide-pause",
    "pencil" => "lucide lucide-pencil",
    "phone" => "lucide lucide-phone",
    "pin" => "lucide lucide-pin",
    "play" => "lucide lucide-play",
    "plus" => "lucide lucide-plus",
    "printer" => "lucide lucide-printer",
    "refresh-cw" => "lucide lucide-refresh-cw",
    "rotate-ccw" => "lucide lucide-rotate-ccw",
    "rotate-ccw-clock" => "lucide lucide-rotate-ccw-clock lucide-history",
    "save" => "lucide lucide-save",
    "search" => "lucide lucide-search",
    "send" => "lucide lucide-send",
    "settings" => "lucide lucide-settings",
    "share-2" => "lucide lucide-share-2",
    "shield" => "lucide lucide-shield",
    "shopping-bag" => "lucide lucide-shopping-bag",
    "shopping-cart" => "lucide lucide-shopping-cart",
    "sliders-horizontal" => "lucide lucide-sliders-horizontal",
    "smartphone" => "lucide lucide-smartphone",
    "sparkles" => "lucide lucide-sparkles lucide-stars",
    "square-pen" => "lucide lucide-square-pen lucide-pen-box lucide-edit lucide-pen-square",
    "star" => "lucide lucide-star",
    "sun" => "lucide lucide-sun",
    "tag" => "lucide lucide-tag",
    "thumbs-down" => "lucide lucide-thumbs-down",
    "thumbs-up" => "lucide lucide-thumbs-up",
    "trash" => "lucide lucide-trash lucide-trash-2",
    "trending-down" => "lucide lucide-trending-down",
    "trending-up" => "lucide lucide-trending-up",
    "triangle-alert" => "lucide lucide-triangle-alert lucide-alert-triangle",
    "upload" => "lucide lucide-upload",
    "user" => "lucide lucide-user",
    "user-plus" => "lucide lucide-user-plus",
    "users" => "lucide lucide-users",
    "x" => "lucide lucide-x",
    "zap" => "lucide lucide-zap"
  }

  @icon_aliases %{
    "bar-chart-horizontal" => "chart-bar",
    "bar-chart-3" => "chart-column",
    "line-chart" => "chart-line",
    "pie-chart" => "chart-pie",
    "alert-circle" => "circle-alert",
    "check-circle-2" => "circle-check",
    "plus-circle" => "circle-plus",
    "circle-help" => "circle-question-mark",
    "help-circle" => "circle-question-mark",
    "user-circle" => "circle-user",
    "x-circle" => "circle-x",
    "panels-left-right" => "columns-3",
    "more-horizontal" => "ellipsis",
    "more-vertical" => "ellipsis-vertical",
    "filter" => "funnel",
    "home" => "house",
    "loader-2" => "loader-circle",
    "x-octagon" => "octagon-x",
    "sidebar" => "panel-left",
    "history" => "rotate-ccw-clock",
    "stars" => "sparkles",
    "edit" => "square-pen",
    "pen-box" => "square-pen",
    "pen-square" => "square-pen",
    "trash-2" => "trash",
    "alert-triangle" => "triangle-alert"
  }

  @icon_names @icon_classes |> Map.keys() |> Enum.sort()

  @doc """
  Renders a Lucide icon as an inline `<svg>` with `aria-hidden="true"`, or a Heroicon
  when `name` starts with `hero-`.

  `name` accepts Lucide kebab-case (`"trash-2"`) or PascalCase (`"Trash2"`, `"Trash2Icon"`)
  and any Lucide alias listed below. `class` is appended to the Lucide classes; other
  attributes are passed to the `<svg>`.

      <.icon name="plus" class="size-4" />

  ## Heroicons

  `hero-*` names render exactly like Phoenix 1.8 `CoreComponents.icon/1`:
  `<span class={[@name, @class]} />`, with `class` defaulting to `"size-4"`. The CSS comes
  from the Heroicons Tailwind plugin that `mix phx.new` installs
  (`assets/vendor/heroicons.js`), so `phx.new` templates keep working after
  `import MyAppWeb.CoreComponents, except: [icon: 1]`.

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />

  ## Supported names

  * `archive`
  * `arrow-down`
  * `arrow-left`
  * `arrow-right`
  * `arrow-up`
  * `arrow-up-down`
  * `arrow-up-right`
  * `at-sign`
  * `bell`
  * `bookmark`
  * `briefcase`
  * `building`
  * `calendar`
  * `chart-bar` (also `bar-chart-horizontal`)
  * `chart-column` (also `bar-chart-3`)
  * `chart-line` (also `line-chart`)
  * `chart-pie` (also `pie-chart`)
  * `check`
  * `chevron-down`
  * `chevron-left`
  * `chevron-right`
  * `chevron-up`
  * `chevrons-left`
  * `chevrons-right`
  * `chevrons-up-down`
  * `circle`
  * `circle-alert` (also `alert-circle`)
  * `circle-check` (also `check-circle-2`)
  * `circle-dot`
  * `circle-plus` (also `plus-circle`)
  * `circle-question-mark` (also `circle-help`, `help-circle`)
  * `circle-user` (also `user-circle`)
  * `circle-x` (also `x-circle`)
  * `clock`
  * `columns-3` (also `panels-left-right`)
  * `copy`
  * `credit-card`
  * `dollar-sign`
  * `download`
  * `ellipsis` (also `more-horizontal`)
  * `ellipsis-vertical` (also `more-vertical`)
  * `external-link`
  * `eye`
  * `eye-off`
  * `file-text`
  * `flag`
  * `folder`
  * `funnel` (also `filter`)
  * `globe`
  * `grip-vertical`
  * `hash`
  * `heart`
  * `house` (also `home`)
  * `image`
  * `inbox`
  * `info`
  * `key`
  * `layout-dashboard`
  * `link`
  * `list`
  * `list-todo`
  * `loader`
  * `loader-circle` (also `loader-2`)
  * `lock`
  * `log-in`
  * `log-out`
  * `mail`
  * `map-pin`
  * `menu`
  * `message-square`
  * `minus`
  * `monitor`
  * `moon`
  * `octagon-x` (also `x-octagon`)
  * `panel-left` (also `sidebar`)
  * `paperclip`
  * `pause`
  * `pencil`
  * `phone`
  * `pin`
  * `play`
  * `plus`
  * `printer`
  * `refresh-cw`
  * `rotate-ccw`
  * `rotate-ccw-clock` (also `history`)
  * `save`
  * `search`
  * `send`
  * `settings`
  * `share-2`
  * `shield`
  * `shopping-bag`
  * `shopping-cart`
  * `sliders-horizontal`
  * `smartphone`
  * `sparkles` (also `stars`)
  * `square-pen` (also `edit`, `pen-box`, `pen-square`)
  * `star`
  * `sun`
  * `tag`
  * `thumbs-down`
  * `thumbs-up`
  * `trash` (also `trash-2`)
  * `trending-down`
  * `trending-up`
  * `triangle-alert` (also `alert-triangle`)
  * `upload`
  * `user`
  * `user-plus`
  * `users`
  * `x`
  * `zap`

  Any other name raises `ArgumentError`. To request another Lucide icon, open an issue at
  https://github.com/onnimonni/shadcn-liveview/issues (contributors: add the name to
  `APP_ICONS` in `tools/icons.ts` and run `bun run generate`). For a one-off icon,
  render your own inline `<svg>`.
  """
  attr :name, :string,
    required: true,
    doc: "Lucide icon name (see the supported list above) or a `hero-*` Heroicon name."

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
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={[@icon_classes, @class]}
      aria-hidden="true"
      {@rest}
    >
      <.icon_body name={@icon_name} />
    </svg>
    """
  end

  defp icon_name(name) do
    normalized =
      name
      |> Macro.underscore()
      |> String.replace("_", "-")
      |> String.replace_suffix("-icon", "")
      |> String.replace(~r/([a-z])([0-9])/, "\\1-\\2")

    canonical = Map.get(@icon_aliases, normalized, normalized)

    if Map.has_key?(@icon_classes, canonical) do
      canonical
    else
      raise ArgumentError, """
      unknown Lucide icon #{inspect(name)} (normalized to #{inspect(normalized)}).

      ShadcnLiveview.Components.Icon bundles a curated Lucide subset; see the icon/1 docs for
      aliases. Supported names: #{Enum.join(@icon_names, ", ")}

      To request another icon, open an issue at #{@issues_url}
      (contributors: add it to APP_ICONS in tools/icons.ts and run `bun run generate`).
      For a one-off icon, render your own inline <svg>.
      """
    end
  end

  defp icon_body(%{name: "archive"} = assigns) do
    ~H"""
    <rect width="20" height="5" x="2" y="3" rx="1"></rect><path d="M4 8v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8">
    </path><path d="M10 12h4"></path>
    """
  end

  defp icon_body(%{name: "arrow-down"} = assigns) do
    ~H"""
    <path d="M12 5v14"></path><path d="m19 12-7 7-7-7"></path>
    """
  end

  defp icon_body(%{name: "arrow-left"} = assigns) do
    ~H"""
    <path d="m12 19-7-7 7-7"></path><path d="M19 12H5"></path>
    """
  end

  defp icon_body(%{name: "arrow-right"} = assigns) do
    ~H"""
    <path d="M5 12h14"></path><path d="m12 5 7 7-7 7"></path>
    """
  end

  defp icon_body(%{name: "arrow-up"} = assigns) do
    ~H"""
    <path d="m5 12 7-7 7 7"></path><path d="M12 19V5"></path>
    """
  end

  defp icon_body(%{name: "arrow-up-down"} = assigns) do
    ~H"""
    <path d="m21 16-4 4-4-4"></path><path d="M17 20V4"></path><path d="m3 8 4-4 4 4"></path><path d="M7 4v16">
    </path>
    """
  end

  defp icon_body(%{name: "arrow-up-right"} = assigns) do
    ~H"""
    <path d="M7 7h10v10"></path><path d="M7 17 17 7"></path>
    """
  end

  defp icon_body(%{name: "at-sign"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="4"></circle><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8"></path>
    """
  end

  defp icon_body(%{name: "bell"} = assigns) do
    ~H"""
    <path d="M10.268 21a2 2 0 0 0 3.464 0"></path><path d="M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326">
    </path>
    """
  end

  defp icon_body(%{name: "bookmark"} = assigns) do
    ~H"""
    <path d="M17 3a2 2 0 0 1 2 2v15a1 1 0 0 1-1.496.868l-4.512-2.578a2 2 0 0 0-1.984 0l-4.512 2.578A1 1 0 0 1 5 20V5a2 2 0 0 1 2-2z">
    </path>
    """
  end

  defp icon_body(%{name: "briefcase"} = assigns) do
    ~H"""
    <path d="M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path><rect
      width="20"
      height="14"
      x="2"
      y="6"
      rx="2"
    >
    </rect>
    """
  end

  defp icon_body(%{name: "building"} = assigns) do
    ~H"""
    <path d="M12 10h.01"></path><path d="M12 14h.01"></path><path d="M12 6h.01"></path><path d="M16 10h.01">
    </path><path d="M16 14h.01"></path><path d="M16 6h.01"></path><path d="M8 10h.01"></path><path d="M8 14h.01">
    </path><path d="M8 6h.01"></path><path d="M9 22v-3a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v3"></path><rect
      x="4"
      y="2"
      width="16"
      height="20"
      rx="2"
    >
    </rect>
    """
  end

  defp icon_body(%{name: "calendar"} = assigns) do
    ~H"""
    <path d="M8 2v3"></path><path d="M16 2v3"></path><rect x="3" y="3" width="18" height="18" rx="2">
    </rect><path d="M3 9h18"></path>
    """
  end

  defp icon_body(%{name: "chart-bar"} = assigns) do
    ~H"""
    <path d="M3 3v16a2 2 0 0 0 2 2h16"></path><path d="M7 16h8"></path><path d="M7 11h12"></path><path d="M7 6h3">
    </path>
    """
  end

  defp icon_body(%{name: "chart-column"} = assigns) do
    ~H"""
    <path d="M3 3v16a2 2 0 0 0 2 2h16"></path><path d="M18 17V9"></path><path d="M13 17V5"></path><path d="M8 17v-3">
    </path>
    """
  end

  defp icon_body(%{name: "chart-line"} = assigns) do
    ~H"""
    <path d="M3 3v16a2 2 0 0 0 2 2h16"></path><path d="m19 9-5 5-4-4-3 3"></path>
    """
  end

  defp icon_body(%{name: "chart-pie"} = assigns) do
    ~H"""
    <path d="M21 12c.552 0 1.005-.449.95-.998a10 10 0 0 0-8.953-8.951c-.55-.055-.998.398-.998.95v8a1 1 0 0 0 1 1z">
    </path><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path>
    """
  end

  defp icon_body(%{name: "check"} = assigns) do
    ~H"""
    <path d="M20 6 9 17l-5-5"></path>
    """
  end

  defp icon_body(%{name: "chevron-down"} = assigns) do
    ~H"""
    <path d="m6 9 6 6 6-6"></path>
    """
  end

  defp icon_body(%{name: "chevron-left"} = assigns) do
    ~H"""
    <path d="m15 18-6-6 6-6"></path>
    """
  end

  defp icon_body(%{name: "chevron-right"} = assigns) do
    ~H"""
    <path d="m9 18 6-6-6-6"></path>
    """
  end

  defp icon_body(%{name: "chevron-up"} = assigns) do
    ~H"""
    <path d="m18 15-6-6-6 6"></path>
    """
  end

  defp icon_body(%{name: "chevrons-left"} = assigns) do
    ~H"""
    <path d="m11 17-5-5 5-5"></path><path d="m18 17-5-5 5-5"></path>
    """
  end

  defp icon_body(%{name: "chevrons-right"} = assigns) do
    ~H"""
    <path d="m6 17 5-5-5-5"></path><path d="m13 17 5-5-5-5"></path>
    """
  end

  defp icon_body(%{name: "chevrons-up-down"} = assigns) do
    ~H"""
    <path d="m7 15 5 5 5-5"></path><path d="m7 9 5-5 5 5"></path>
    """
  end

  defp icon_body(%{name: "circle"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle>
    """
  end

  defp icon_body(%{name: "circle-alert"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><line x1="12" x2="12" y1="8" y2="12"></line><line
      x1="12"
      x2="12.01"
      y1="16"
      y2="16"
    >
    </line>
    """
  end

  defp icon_body(%{name: "circle-check"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="m16 9-5.5 5.5L8 12"></path>
    """
  end

  defp icon_body(%{name: "circle-dot"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="12" r="10"></circle>
    """
  end

  defp icon_body(%{name: "circle-plus"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M8 12h8"></path><path d="M12 8v8"></path>
    """
  end

  defp icon_body(%{name: "circle-question-mark"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><path d="M12 17h.01">
    </path>
    """
  end

  defp icon_body(%{name: "circle-user"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><circle cx="12" cy="10" r="3"></circle><path d="M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662">
    </path>
    """
  end

  defp icon_body(%{name: "circle-x"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="m15 9-6 6"></path><path d="m9 9 6 6"></path>
    """
  end

  defp icon_body(%{name: "clock"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M12 6v6l4 2"></path>
    """
  end

  defp icon_body(%{name: "columns-3"} = assigns) do
    ~H"""
    <rect width="18" height="18" x="3" y="3" rx="2"></rect><path d="M9 3v18"></path><path d="M15 3v18">
    </path>
    """
  end

  defp icon_body(%{name: "copy"} = assigns) do
    ~H"""
    <rect width="14" height="14" x="8" y="8" rx="2" ry="2"></rect><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2">
    </path>
    """
  end

  defp icon_body(%{name: "credit-card"} = assigns) do
    ~H"""
    <rect width="20" height="14" x="2" y="5" rx="2"></rect><line x1="2" x2="22" y1="10" y2="10">
    </line><path d="M6 14h2"></path>
    """
  end

  defp icon_body(%{name: "dollar-sign"} = assigns) do
    ~H"""
    <line x1="12" x2="12" y1="2" y2="22"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6">
    </path>
    """
  end

  defp icon_body(%{name: "download"} = assigns) do
    ~H"""
    <path d="M12 15V3"></path><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><path d="m7 10 5 5 5-5">
    </path>
    """
  end

  defp icon_body(%{name: "ellipsis"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="1"></circle><circle cx="19" cy="12" r="1"></circle><circle
      cx="5"
      cy="12"
      r="1"
    >
    </circle>
    """
  end

  defp icon_body(%{name: "ellipsis-vertical"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle
      cx="12"
      cy="19"
      r="1"
    >
    </circle>
    """
  end

  defp icon_body(%{name: "external-link"} = assigns) do
    ~H"""
    <path d="M15 3h6v6"></path><path d="M10 14 21 3"></path><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6">
    </path>
    """
  end

  defp icon_body(%{name: "eye"} = assigns) do
    ~H"""
    <path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0">
    </path><circle cx="12" cy="12" r="3"></circle>
    """
  end

  defp icon_body(%{name: "eye-off"} = assigns) do
    ~H"""
    <path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49">
    </path><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"></path><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143">
    </path><path d="m2 2 20 20"></path>
    """
  end

  defp icon_body(%{name: "file-text"} = assigns) do
    ~H"""
    <path d="M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z">
    </path><path d="M14 2v5a1 1 0 0 0 1 1h5"></path><path d="M10 9H8"></path><path d="M16 13H8">
    </path><path d="M16 17H8"></path>
    """
  end

  defp icon_body(%{name: "flag"} = assigns) do
    ~H"""
    <path d="M4 22V4a1 1 0 0 1 .4-.8A6 6 0 0 1 8 2c3 0 5 2 7.333 2q2 0 3.067-.8A1 1 0 0 1 20 4v10a1 1 0 0 1-.4.8A6 6 0 0 1 16 16c-3 0-5-2-8-2a6 6 0 0 0-4 1.528">
    </path>
    """
  end

  defp icon_body(%{name: "folder"} = assigns) do
    ~H"""
    <path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z">
    </path>
    """
  end

  defp icon_body(%{name: "funnel"} = assigns) do
    ~H"""
    <path d="M10 20a1 1 0 0 0 .553.895l2 1A1 1 0 0 0 14 21v-7a2 2 0 0 1 .517-1.341L21.74 4.67A1 1 0 0 0 21 3H3a1 1 0 0 0-.742 1.67l7.225 7.989A2 2 0 0 1 10 14z">
    </path>
    """
  end

  defp icon_body(%{name: "globe"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20">
    </path><path d="M2 12h20"></path>
    """
  end

  defp icon_body(%{name: "grip-vertical"} = assigns) do
    ~H"""
    <circle cx="9" cy="12" r="1"></circle><circle cx="9" cy="5" r="1"></circle><circle
      cx="9"
      cy="19"
      r="1"
    >
    </circle><circle cx="15" cy="12" r="1"></circle><circle cx="15" cy="5" r="1"></circle><circle
      cx="15"
      cy="19"
      r="1"
    >
    </circle>
    """
  end

  defp icon_body(%{name: "hash"} = assigns) do
    ~H"""
    <line x1="4" x2="20" y1="9" y2="9"></line><line x1="4" x2="20" y1="15" y2="15"></line><line
      x1="10"
      x2="8"
      y1="3"
      y2="21"
    >
    </line><line x1="16" x2="14" y1="3" y2="21"></line>
    """
  end

  defp icon_body(%{name: "heart"} = assigns) do
    ~H"""
    <path d="M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5">
    </path>
    """
  end

  defp icon_body(%{name: "house"} = assigns) do
    ~H"""
    <path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"></path><path d="M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z">
    </path>
    """
  end

  defp icon_body(%{name: "image"} = assigns) do
    ~H"""
    <rect width="18" height="18" x="3" y="3" rx="2" ry="2"></rect><circle cx="9" cy="9" r="2">
    </circle><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"></path>
    """
  end

  defp icon_body(%{name: "inbox"} = assigns) do
    ~H"""
    <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"></polyline><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z">
    </path>
    """
  end

  defp icon_body(%{name: "info"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path>
    """
  end

  defp icon_body(%{name: "key"} = assigns) do
    ~H"""
    <path d="m2 21 9.6-9.6"></path><path d="m7.5 15.5 2.3 2.3a1 1 0 0 1 0 1.4l-2.1 2.1a1 1 0 0 1-1.4 0L4 19">
    </path><circle cx="15.5" cy="7.5" r="5.5"></circle>
    """
  end

  defp icon_body(%{name: "layout-dashboard"} = assigns) do
    ~H"""
    <rect width="7" height="9" x="3" y="3" rx="1"></rect><rect
      width="7"
      height="5"
      x="14"
      y="3"
      rx="1"
    >
    </rect><rect width="7" height="9" x="14" y="12" rx="1"></rect><rect
      width="7"
      height="5"
      x="3"
      y="16"
      rx="1"
    >
    </rect>
    """
  end

  defp icon_body(%{name: "link"} = assigns) do
    ~H"""
    <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71">
    </path>
    """
  end

  defp icon_body(%{name: "list"} = assigns) do
    ~H"""
    <path d="M3 5h.01"></path><path d="M3 12h.01"></path><path d="M3 19h.01"></path><path d="M8 5h13">
    </path><path d="M8 12h13"></path><path d="M8 19h13"></path>
    """
  end

  defp icon_body(%{name: "list-todo"} = assigns) do
    ~H"""
    <path d="M13 5h8"></path><path d="M13 12h8"></path><path d="M13 19h8"></path><path d="m3 17 2 2 4-4">
    </path><rect x="3" y="4" width="6" height="6" rx="1"></rect>
    """
  end

  defp icon_body(%{name: "loader"} = assigns) do
    ~H"""
    <path d="M12 2v4"></path><path d="m16.2 7.8 2.9-2.9"></path><path d="M18 12h4"></path><path d="m16.2 16.2 2.9 2.9">
    </path><path d="M12 18v4"></path><path d="m4.9 19.1 2.9-2.9"></path><path d="M2 12h4"></path><path d="m4.9 4.9 2.9 2.9">
    </path>
    """
  end

  defp icon_body(%{name: "loader-circle"} = assigns) do
    ~H"""
    <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
    """
  end

  defp icon_body(%{name: "lock"} = assigns) do
    ~H"""
    <rect width="18" height="11" x="3" y="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4">
    </path>
    """
  end

  defp icon_body(%{name: "log-in"} = assigns) do
    ~H"""
    <path d="m10 17 5-5-5-5"></path><path d="M15 12H3"></path><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4">
    </path>
    """
  end

  defp icon_body(%{name: "log-out"} = assigns) do
    ~H"""
    <path d="m16 17 5-5-5-5"></path><path d="M21 12H9"></path><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4">
    </path>
    """
  end

  defp icon_body(%{name: "mail"} = assigns) do
    ~H"""
    <path d="m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7"></path><rect
      x="2"
      y="4"
      width="20"
      height="16"
      rx="2"
    >
    </rect>
    """
  end

  defp icon_body(%{name: "map-pin"} = assigns) do
    ~H"""
    <path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0">
    </path><circle cx="12" cy="10" r="3"></circle>
    """
  end

  defp icon_body(%{name: "menu"} = assigns) do
    ~H"""
    <path d="M4 5h16"></path><path d="M4 12h16"></path><path d="M4 19h16"></path>
    """
  end

  defp icon_body(%{name: "message-square"} = assigns) do
    ~H"""
    <path d="M22 17a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 2.202A.71.71 0 0 1 2 21.286V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2z">
    </path>
    """
  end

  defp icon_body(%{name: "minus"} = assigns) do
    ~H"""
    <path d="M5 12h14"></path>
    """
  end

  defp icon_body(%{name: "monitor"} = assigns) do
    ~H"""
    <rect width="20" height="14" x="2" y="3" rx="2"></rect><line x1="8" x2="16" y1="21" y2="21">
    </line><line x1="12" x2="12" y1="17" y2="21"></line>
    """
  end

  defp icon_body(%{name: "moon"} = assigns) do
    ~H"""
    <path d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401">
    </path>
    """
  end

  defp icon_body(%{name: "octagon-x"} = assigns) do
    ~H"""
    <path d="m15 9-6 6"></path><path d="M2.586 16.726A2 2 0 0 1 2 15.312V8.688a2 2 0 0 1 .586-1.414l4.688-4.688A2 2 0 0 1 8.688 2h6.624a2 2 0 0 1 1.414.586l4.688 4.688A2 2 0 0 1 22 8.688v6.624a2 2 0 0 1-.586 1.414l-4.688 4.688a2 2 0 0 1-1.414.586H8.688a2 2 0 0 1-1.414-.586z">
    </path><path d="m9 9 6 6"></path>
    """
  end

  defp icon_body(%{name: "panel-left"} = assigns) do
    ~H"""
    <rect width="18" height="18" x="3" y="3" rx="2"></rect><path d="M9 3v18"></path>
    """
  end

  defp icon_body(%{name: "paperclip"} = assigns) do
    ~H"""
    <path d="m16 6-8.414 8.586a2 2 0 0 0 2.829 2.829l8.414-8.586a4 4 0 1 0-5.657-5.657l-8.379 8.551a6 6 0 1 0 8.485 8.485l8.379-8.551">
    </path>
    """
  end

  defp icon_body(%{name: "pause"} = assigns) do
    ~H"""
    <rect x="14" y="3" width="5" height="18" rx="1"></rect><rect
      x="5"
      y="3"
      width="5"
      height="18"
      rx="1"
    >
    </rect>
    """
  end

  defp icon_body(%{name: "pencil"} = assigns) do
    ~H"""
    <path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z">
    </path><path d="m15 5 4 4"></path>
    """
  end

  defp icon_body(%{name: "phone"} = assigns) do
    ~H"""
    <path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384">
    </path>
    """
  end

  defp icon_body(%{name: "pin"} = assigns) do
    ~H"""
    <path d="M12 17v5"></path><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H8a2 2 0 0 0 0 4 1 1 0 0 1 1 1z">
    </path>
    """
  end

  defp icon_body(%{name: "play"} = assigns) do
    ~H"""
    <path d="M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z">
    </path>
    """
  end

  defp icon_body(%{name: "plus"} = assigns) do
    ~H"""
    <path d="M5 12h14"></path><path d="M12 5v14"></path>
    """
  end

  defp icon_body(%{name: "printer"} = assigns) do
    ~H"""
    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><path d="M6 9V3a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v6">
    </path><rect x="6" y="14" width="12" height="8" rx="1"></rect>
    """
  end

  defp icon_body(%{name: "refresh-cw"} = assigns) do
    ~H"""
    <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"></path><path d="M21 3v5h-5"></path><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16">
    </path><path d="M8 16H3v5"></path>
    """
  end

  defp icon_body(%{name: "rotate-ccw"} = assigns) do
    ~H"""
    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><path d="M3 3v5h5"></path>
    """
  end

  defp icon_body(%{name: "rotate-ccw-clock"} = assigns) do
    ~H"""
    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path><path d="M3 3v5h5"></path><path d="M12 7v5l4 2">
    </path>
    """
  end

  defp icon_body(%{name: "save"} = assigns) do
    ~H"""
    <path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z">
    </path><path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7"></path><path d="M7 3v4a1 1 0 0 0 1 1h7">
    </path>
    """
  end

  defp icon_body(%{name: "search"} = assigns) do
    ~H"""
    <path d="m21 21-4.34-4.34"></path><circle cx="11" cy="11" r="8"></circle>
    """
  end

  defp icon_body(%{name: "send"} = assigns) do
    ~H"""
    <path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z">
    </path><path d="m21.854 2.147-10.94 10.939"></path>
    """
  end

  defp icon_body(%{name: "settings"} = assigns) do
    ~H"""
    <path d="M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915">
    </path><circle cx="12" cy="12" r="3"></circle>
    """
  end

  defp icon_body(%{name: "share-2"} = assigns) do
    ~H"""
    <circle cx="18" cy="5" r="3"></circle><circle cx="6" cy="12" r="3"></circle><circle
      cx="18"
      cy="19"
      r="3"
    >
    </circle><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"></line><line
      x1="15.41"
      x2="8.59"
      y1="6.51"
      y2="10.49"
    >
    </line>
    """
  end

  defp icon_body(%{name: "shield"} = assigns) do
    ~H"""
    <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z">
    </path>
    """
  end

  defp icon_body(%{name: "shopping-bag"} = assigns) do
    ~H"""
    <path d="M16 10a4 4 0 0 1-8 0"></path><path d="M3.103 6.034h17.794"></path><path d="M3.4 5.467a2 2 0 0 0-.4 1.2V20a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6.667a2 2 0 0 0-.4-1.2l-2-2.667A2 2 0 0 0 17 2H7a2 2 0 0 0-1.6.8z">
    </path>
    """
  end

  defp icon_body(%{name: "shopping-cart"} = assigns) do
    ~H"""
    <path d="m2.05 2.05 1.099-.028a1 1 0 0 1 1.008.815l2.69 14.347A1 1 0 0 0 7.83 18H18"></path><path d="M4.563 5h16.435a1 1 0 0 1 .981 1.204l-1.026 6.226A2 2 0 0 1 18.962 14H6.25">
    </path><circle cx="18" cy="20" r="2"></circle><circle cx="8" cy="20" r="2"></circle>
    """
  end

  defp icon_body(%{name: "sliders-horizontal"} = assigns) do
    ~H"""
    <path d="M10 5H3"></path><path d="M12 19H3"></path><path d="M14 3v4"></path><path d="M16 17v4">
    </path><path d="M21 12h-9"></path><path d="M21 19h-5"></path><path d="M21 5h-7"></path><path d="M8 10v4">
    </path><path d="M8 12H3"></path>
    """
  end

  defp icon_body(%{name: "smartphone"} = assigns) do
    ~H"""
    <rect width="14" height="20" x="5" y="2" rx="2" ry="2"></rect><path d="M12 18h.01"></path>
    """
  end

  defp icon_body(%{name: "sparkles"} = assigns) do
    ~H"""
    <path d="M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z">
    </path><path d="M20 2v4"></path><path d="M22 4h-4"></path><circle cx="4" cy="20" r="2"></circle>
    """
  end

  defp icon_body(%{name: "square-pen"} = assigns) do
    ~H"""
    <path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z">
    </path>
    """
  end

  defp icon_body(%{name: "star"} = assigns) do
    ~H"""
    <path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z">
    </path>
    """
  end

  defp icon_body(%{name: "sun"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="4"></circle><path d="M12 2v2"></path><path d="M12 20v2"></path><path d="m4.93 4.93 1.41 1.41">
    </path><path d="m17.66 17.66 1.41 1.41"></path><path d="M2 12h2"></path><path d="M20 12h2"></path><path d="m6.34 17.66-1.41 1.41">
    </path><path d="m19.07 4.93-1.41 1.41"></path>
    """
  end

  defp icon_body(%{name: "tag"} = assigns) do
    ~H"""
    <path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z">
    </path><circle cx="7.5" cy="7.5" r=".5" fill="currentColor"></circle>
    """
  end

  defp icon_body(%{name: "thumbs-down"} = assigns) do
    ~H"""
    <path d="M9 18.12 10 14H4.17a2 2 0 0 1-1.92-2.56l2.33-8A2 2 0 0 1 6.5 2H20a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-2.76a2 2 0 0 0-1.79 1.11L12 22a3.13 3.13 0 0 1-3-3.88Z">
    </path><path d="M17 14V2"></path>
    """
  end

  defp icon_body(%{name: "thumbs-up"} = assigns) do
    ~H"""
    <path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2a3.13 3.13 0 0 1 3 3.88Z">
    </path><path d="M7 10v12"></path>
    """
  end

  defp icon_body(%{name: "trash"} = assigns) do
    ~H"""
    <path d="M10 11v6"></path><path d="M14 11v6"></path><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6">
    </path><path d="M3 6h18"></path><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
    """
  end

  defp icon_body(%{name: "trending-down"} = assigns) do
    ~H"""
    <path d="M16 17h6v-6"></path><path d="m22 17-8.5-8.5-5 5L2 7"></path>
    """
  end

  defp icon_body(%{name: "trending-up"} = assigns) do
    ~H"""
    <path d="M16 7h6v6"></path><path d="m22 7-8.5 8.5-5-5L2 17"></path>
    """
  end

  defp icon_body(%{name: "triangle-alert"} = assigns) do
    ~H"""
    <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"></path><path d="M12 9v4">
    </path><path d="M12 17h.01"></path>
    """
  end

  defp icon_body(%{name: "upload"} = assigns) do
    ~H"""
    <path d="M12 3v12"></path><path d="m17 8-5-5-5 5"></path><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4">
    </path>
    """
  end

  defp icon_body(%{name: "user"} = assigns) do
    ~H"""
    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle>
    """
  end

  defp icon_body(%{name: "user-plus"} = assigns) do
    ~H"""
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><line
      x1="19"
      x2="19"
      y1="8"
      y2="14"
    >
    </line><line x1="22" x2="16" y1="11" y2="11"></line>
    """
  end

  defp icon_body(%{name: "users"} = assigns) do
    ~H"""
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><path d="M16 3.128a4 4 0 0 1 0 7.744">
    </path><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><circle cx="9" cy="7" r="4"></circle>
    """
  end

  defp icon_body(%{name: "x"} = assigns) do
    ~H"""
    <path d="M18 6 6 18"></path><path d="m6 6 12 12"></path>
    """
  end

  defp icon_body(%{name: "zap"} = assigns) do
    ~H"""
    <path d="M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z">
    </path>
    """
  end
end
