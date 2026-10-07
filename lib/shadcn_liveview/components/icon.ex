defmodule ShadcnLiveview.Components.Icon do
  @moduledoc false
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def icon(assigns) do
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
      class={["lucide", "lucide-#{icon_class_name(@name)}", @class]}
      aria-hidden="true"
      {@rest}
    >
      <.icon_body name={@name} />
    </svg>
    """
  end

  defp icon_class_name(name) do
    name
    |> to_string()
    |> Macro.underscore()
    |> String.replace("_", "-")
    |> String.replace(~r/-icon$/, "")
  end

  defp icon_body(assigns) do
    key =
      assigns.name
      |> to_string()
      |> Macro.underscore()
      |> String.replace(~r/(_icon|-icon)$/, "")

    case key do
      k when k in ~w(chevron_down chevron-down) ->
        ~H"""
        <path d="m6 9 6 6 6-6" />
        """

      k when k in ~w(chevron_up chevron-up) ->
        ~H"""
        <path d="m18 15-6-6-6 6" />
        """

      k when k in ~w(chevron_left chevron-left) ->
        ~H"""
        <path d="m15 18-6-6 6-6" />
        """

      k when k in ~w(chevron_right chevron-right) ->
        ~H"""
        <path d="m9 18 6-6-6-6" />
        """

      k when k in ~w(check) ->
        ~H"""
        <path d="M20 6 9 17l-5-5" />
        """

      k when k in ~w(x cancel close) ->
        ~H"""
        <path d="M18 6 6 18" /><path d="m6 6 12 12" />
        """

      k when k in ~w(search) ->
        ~H"""
        <circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />
        """

      k when k in ~w(minus) ->
        ~H"""
        <path d="M5 12h14" />
        """

      k when k in ~w(more_horizontal more-horizontal) ->
        ~H"""
        <circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" />
        """

      k when k in ~w(arrow_down arrow-down) ->
        ~H"""
        <path d="M12 5v14" /><path d="m19 12-7 7-7-7" />
        """

      k when k in ~w(panel_left panel-left) ->
        ~H"""
        <rect width="18" height="18" x="3" y="3" rx="2" /><path d="M9 3v18" />
        """

      k when k in ~w(circle) ->
        ~H"""
        <circle cx="12" cy="12" r="10" />
        """

      _ ->
        ~H"""
        <circle cx="12" cy="12" r="10" />
        """
    end
  end
end
