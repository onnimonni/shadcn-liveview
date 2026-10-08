defmodule ShadcnLiveview.Components.Icon do
  @moduledoc """
  Lucide icons used by the vendored components, generated from pinned upstream geometry.
  Names accept Lucide PascalCase or kebab-case. Unknown names raise instead of rendering a substitute.
  """
  use Phoenix.Component

  @icon_classes %{
    "arrow-down" => "lucide lucide-arrow-down",
    "arrow-left" => "lucide lucide-arrow-left",
    "arrow-right" => "lucide lucide-arrow-right",
    "arrow-up" => "lucide lucide-arrow-up",
    "check" => "lucide lucide-check",
    "chevron-down" => "lucide lucide-chevron-down",
    "chevron-left" => "lucide lucide-chevron-left",
    "chevron-right" => "lucide lucide-chevron-right",
    "chevron-up" => "lucide lucide-chevron-up",
    "circle" => "lucide lucide-circle",
    "circle-check" => "lucide lucide-circle-check lucide-check-circle-2",
    "grip-vertical" => "lucide lucide-grip-vertical",
    "info" => "lucide lucide-info",
    "loader-2" => "lucide lucide-loader-circle lucide-loader-2",
    "loader-circle" => "lucide lucide-loader-circle lucide-loader-2",
    "minus" => "lucide lucide-minus",
    "more-horizontal" => "lucide lucide-ellipsis lucide-more-horizontal",
    "octagon-x" => "lucide lucide-octagon-x lucide-x-octagon",
    "panel-left" => "lucide lucide-panel-left lucide-sidebar",
    "search" => "lucide lucide-search",
    "triangle-alert" => "lucide lucide-triangle-alert lucide-alert-triangle",
    "x" => "lucide lucide-x"
  }

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

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
    name
    |> Macro.underscore()
    |> String.replace("_", "-")
    |> String.replace_suffix("-icon", "")
    |> String.replace(~r/([a-z])([0-9])/, "\\1-\\2")
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

  defp icon_body(%{name: "circle"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle>
    """
  end

  defp icon_body(%{name: "circle-check"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="m16 9-5.5 5.5L8 12"></path>
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

  defp icon_body(%{name: "info"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path>
    """
  end

  defp icon_body(%{name: "loader-2"} = assigns) do
    ~H"""
    <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
    """
  end

  defp icon_body(%{name: "loader-circle"} = assigns) do
    ~H"""
    <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
    """
  end

  defp icon_body(%{name: "minus"} = assigns) do
    ~H"""
    <path d="M5 12h14"></path>
    """
  end

  defp icon_body(%{name: "more-horizontal"} = assigns) do
    ~H"""
    <circle cx="12" cy="12" r="1"></circle><circle cx="19" cy="12" r="1"></circle><circle
      cx="5"
      cy="12"
      r="1"
    >
    </circle>
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

  defp icon_body(%{name: "search"} = assigns) do
    ~H"""
    <path d="m21 21-4.34-4.34"></path><circle cx="11" cy="11" r="8"></circle>
    """
  end

  defp icon_body(%{name: "triangle-alert"} = assigns) do
    ~H"""
    <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"></path><path d="M12 9v4">
    </path><path d="M12 17h.01"></path>
    """
  end

  defp icon_body(%{name: "x"} = assigns) do
    ~H"""
    <path d="M18 6 6 18"></path><path d="m6 6 12 12"></path>
    """
  end

  defp icon_body(%{name: name}) do
    raise ArgumentError, "Unknown Lucide icon: #{inspect(name)}"
  end
end
