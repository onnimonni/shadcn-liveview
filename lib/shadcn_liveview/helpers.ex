defmodule ShadcnLiveview.Helpers do
  @moduledoc false

  @doc """
  Combines and resolves conflicting Tailwind CSS classes, matching `cn()` behavior.
  """
  def classes(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&String.split(&1, ~r/\s+/, trim: true))
    |> Enum.reverse()
    |> Enum.uniq_by(&conflict_group/1)
    |> Enum.reverse()
    |> Enum.join(" ")
  end

  def classes(single) when is_binary(single), do: String.trim(single)
  def classes(nil), do: ""

  defp conflict_group(token) do
    cond do
      token in ~w(text-left text-right text-center text-justify text-start text-end) ->
        :text_align

      token in ~w(flex-row flex-col flex-row-reverse flex-col-reverse) ->
        :flex_direction

      token =~ ~r/^text-(xs|sm|base|lg|xl|[2-9]xl)$/ ->
        :font_size

      token =~ ~r/^border-(border|transparent|destructive|primary|input|ring|muted|card|background|foreground)$/ ->
        :border_color

      token =~ ~r/^bg-(background|foreground|primary|secondary|muted|card|popover|destructive|accent|transparent|input)$/ ->
        :bg_color

      token =~ ~r/^rounded(-[a-z0-9]+)?$/ ->
        :rounded

      token =~ ~r/^(size|w)-[0-9a-z\/.-]+$/ ->
        :width_size

      true ->
        token
    end
  end
end
