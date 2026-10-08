defmodule ShadcnLiveview.Helpers do
  @moduledoc false

  @doc """
  Combines classes and resolves the unprefixed conflicts used by this library.
  Width/height overrides retain the other axis of size utilities; min/max bounds
  and padding axes remain independent. This is not a complete Tailwind merge implementation.
  """
  def classes(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&String.split(&1, ~r/\s+/, trim: true))
    |> Enum.reverse()
    |> Enum.reduce({[], MapSet.new()}, &keep_class/2)
    |> elem(0)
    |> Enum.join(" ")
  end

  def classes(single) when is_binary(single), do: String.trim(single)
  def classes(nil), do: ""

  defp keep_class(token, {kept, blocked} = state) do
    group = conflict_group(token)

    if MapSet.member?(blocked, group) do
      state
    else
      {[token | kept], block_group(blocked, group)}
    end
  end

  defp block_group(blocked, :size) do
    blocked |> MapSet.put(:size) |> MapSet.put(:width) |> MapSet.put(:height)
  end

  defp block_group(blocked, :padding) do
    Enum.reduce(
      [
        :padding,
        :padding_x,
        :padding_y,
        :padding_start,
        :padding_end,
        :padding_top,
        :padding_right,
        :padding_bottom,
        :padding_left
      ],
      blocked,
      &MapSet.put(&2, &1)
    )
  end

  defp block_group(blocked, :padding_x) do
    blocked |> MapSet.put(:padding_x) |> MapSet.put(:padding_right) |> MapSet.put(:padding_left)
  end

  defp block_group(blocked, :padding_y) do
    blocked |> MapSet.put(:padding_y) |> MapSet.put(:padding_top) |> MapSet.put(:padding_bottom)
  end

  defp block_group(blocked, group), do: MapSet.put(blocked, group)

  defp conflict_group(token)
       when token in ~w(text-left text-right text-center text-justify text-start text-end),
       do: :text_align

  defp conflict_group(token)
       when token in ~w(flex-row flex-col flex-row-reverse flex-col-reverse),
       do: :flex_direction

  defp conflict_group("size-" <> _), do: :size
  defp conflict_group("w-" <> _), do: :width
  defp conflict_group("h-" <> _), do: :height
  defp conflict_group("p-" <> _), do: :padding
  defp conflict_group("px-" <> _), do: :padding_x
  defp conflict_group("py-" <> _), do: :padding_y
  defp conflict_group("ps-" <> _), do: :padding_start
  defp conflict_group("pe-" <> _), do: :padding_end
  defp conflict_group("pt-" <> _), do: :padding_top
  defp conflict_group("pr-" <> _), do: :padding_right
  defp conflict_group("pb-" <> _), do: :padding_bottom
  defp conflict_group("pl-" <> _), do: :padding_left

  defp conflict_group(token) do
    cond do
      token =~ ~r/^text-(xs|sm|base|lg|xl|[2-9]xl)$/ ->
        :font_size

      token =~
          ~r/^border-(border|transparent|destructive|primary|input|ring|muted|card|background|foreground)$/ ->
        :border_color

      token =~
          ~r/^bg-(background|foreground|primary|secondary|muted|card|popover|destructive|accent|transparent|input)$/ ->
        :bg_color

      token =~ ~r/^rounded(-[a-z0-9]+)?$/ ->
        :rounded

      true ->
        token
    end
  end
end
