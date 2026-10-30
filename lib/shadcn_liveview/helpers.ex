defmodule ShadcnLiveview.Helpers do
  @moduledoc false

  @doc """
  Combines classes and resolves Tailwind conflicts like `tailwind-merge`: a later
  class replaces an earlier one of the same group under the same variants
  (`hover:`, `dark:`, `data-[state=open]:` ...) and important modifier.
  Accepts a string or a (nested) list like HEEx `class`; `nil` and `false` entries are dropped.

  Groups cover the utilities components set and callers override: size, width,
  height, padding, text alignment and size, line height, flex direction, rounding,
  and the background, text, border and ring colours. Width/height overrides retain
  the other axis of size utilities; min/max bounds and padding axes remain
  independent. A font size replaces an earlier line height under the same variants
  (Tailwind font sizes set one). This is not a complete Tailwind merge implementation.
  """
  def classes(list) when is_list(list) do
    list
    |> List.flatten()
    |> Enum.reject(&(is_nil(&1) or &1 == false))
    |> Enum.map(&to_string/1)
    |> Enum.flat_map(&String.split(&1, ~r/\s+/, trim: true))
    |> Enum.reverse()
    |> Enum.reduce({[], MapSet.new()}, &keep_class/2)
    |> elem(0)
    |> Enum.join(" ")
  end

  def classes(single) when is_binary(single), do: String.trim(single)
  def classes(empty) when empty in [nil, false], do: ""

  @doc """
  Guards the trigger ID owned by a compound root (dialog, sheet, popover, menu, select ...).

  The root's `trigger_id` is the single source for content `aria-*` relations, hooks and
  focus return, so a caller `id` on the trigger element may repeat it but never replace
  it: HEEx would render both attributes and browsers keep only one. A matching caller
  ID is dropped; a different one raises with the root-level fix. A `nil` trigger ID (no
  spread trigger context) leaves `rest` untouched.
  """
  def trigger_rest!(rest, nil, _component), do: rest

  def trigger_rest!(rest, trigger_id, component) do
    case Map.get(rest, :id) do
      nil ->
        rest

      ^trigger_id ->
        Map.delete(rest, :id)

      id ->
        raise ArgumentError,
              "<.#{component}> received id=#{inspect(id)}, but its compound root owns the trigger " <>
                "id #{inspect(trigger_id)} that content aria relations, hooks and focus return " <>
                "reference. Pass trigger_id=#{inspect(id)} on the root (e.g. <.dialog>, " <>
                "<.dropdown_menu>, <.select>) and drop id from the trigger element."
    end
  end

  defp keep_class(token, {kept, blocked} = state) do
    {modifiers, utility} = split_modifiers(token)
    {important?, utility} = strip_important(utility)

    case conflict_group(utility) do
      nil ->
        if MapSet.member?(blocked, token),
          do: state,
          else: {[token | kept], MapSet.put(blocked, token)}

      group ->
        scope = {sort_modifiers(modifiers), important?}

        if MapSet.member?(blocked, {scope, group}) do
          state
        else
          blocked =
            Enum.reduce(
              [group | conflicting_groups(group)],
              blocked,
              &MapSet.put(&2, {scope, &1})
            )

          {[token | kept], blocked}
        end
    end
  end

  # Variants are separated by `:` outside of `[...]` and `(...)`.
  defp split_modifiers(token), do: split_modifiers(token, 0, "", [])

  defp split_modifiers(<<>>, _depth, current, modifiers),
    do: {Enum.reverse(modifiers), current}

  defp split_modifiers(<<":", rest::binary>>, 0, current, modifiers),
    do: split_modifiers(rest, 0, "", [current | modifiers])

  defp split_modifiers(<<char, rest::binary>>, depth, current, modifiers) when char in ~c"[(",
    do: split_modifiers(rest, depth + 1, <<current::binary, char>>, modifiers)

  defp split_modifiers(<<char, rest::binary>>, depth, current, modifiers) when char in ~c"])",
    do: split_modifiers(rest, max(depth - 1, 0), <<current::binary, char>>, modifiers)

  defp split_modifiers(<<char, rest::binary>>, depth, current, modifiers),
    do: split_modifiers(rest, depth, <<current::binary, char>>, modifiers)

  # Tailwind v4 suffix `bg-red-500!` and v3 prefix `!bg-red-500`.
  defp strip_important("!" <> utility), do: {true, utility}

  defp strip_important(utility) do
    if String.ends_with?(utility, "!"),
      do: {true, String.slice(utility, 0..-2//1)},
      else: {false, utility}
  end

  @order_sensitive_modifiers ~w(* ** after backdrop before details-content file first-letter first-line marker placeholder selection)

  # As tailwind-merge: variant order is irrelevant except around arbitrary and
  # pseudo-element variants, which keep their position.
  defp sort_modifiers(modifiers) do
    {sorted, pending} =
      Enum.reduce(modifiers, {[], []}, fn modifier, {sorted, pending} ->
        if String.starts_with?(modifier, "[") or modifier in @order_sensitive_modifiers,
          do: {sorted ++ Enum.sort(pending) ++ [modifier], []},
          else: {sorted, [modifier | pending]}
      end)

    sorted ++ Enum.sort(pending)
  end

  defp conflicting_groups(:size), do: [:width, :height]
  defp conflicting_groups(:font_size), do: [:leading]

  defp conflicting_groups(:padding),
    do:
      ~w(padding_x padding_y padding_start padding_end padding_top padding_right padding_bottom padding_left)a

  defp conflicting_groups(:padding_x), do: [:padding_right, :padding_left]
  defp conflicting_groups(:padding_y), do: [:padding_top, :padding_bottom]

  defp conflicting_groups({border, :all}) when border in [:border_width, :border_color],
    do: Enum.map(~w(x y s e t r b l), &{border, &1})

  defp conflicting_groups({border, "x"}) when border in [:border_width, :border_color],
    do: [{border, "r"}, {border, "l"}]

  defp conflicting_groups({border, "y"}) when border in [:border_width, :border_color],
    do: [{border, "t"}, {border, "b"}]

  defp conflicting_groups(_group), do: []

  @text_align ~w(left right center justify start end)
  @font_size ~r/^(base|(\d+(\.\d+)?)?(xs|sm|md|lg|xl))(\/.+)?$/

  defp conflict_group(token)
       when token in ~w(flex-row flex-col flex-row-reverse flex-col-reverse),
       do: :flex_direction

  # tailwind-merge's "display" group: a caller's `hidden sm:inline-flex` must replace a
  # component default `inline-flex` instead of both applying.
  defp conflict_group(token)
       when token in ~w(block inline-block inline flex inline-flex table inline-table
                        table-caption table-cell table-column table-column-group
                        table-footer-group table-header-group table-row-group table-row
                        flow-root grid inline-grid contents list-item hidden),
       do: :display

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
  defp conflict_group("leading-" <> _), do: :leading
  defp conflict_group("text-" <> value), do: text_group(value)
  defp conflict_group("bg-" <> value), do: if(background_color?(value), do: :bg_color)
  defp conflict_group("border"), do: {:border_width, :all}
  defp conflict_group("border-" <> value), do: border_group(value)
  defp conflict_group("ring"), do: :ring_width
  defp conflict_group("ring-inset"), do: nil
  defp conflict_group("ring-offset-" <> value), do: ring_group(value, :ring_offset)
  defp conflict_group("ring-" <> value), do: ring_group(value, :ring)
  defp conflict_group("aspect-" <> _), do: :aspect

  defp conflict_group(token) do
    if token =~ ~r/^rounded(-[a-z0-9]+)?$/, do: :rounded
  end

  defp text_group(value) when value in @text_align, do: :text_align
  defp text_group(value) when value in ~w(wrap nowrap balance pretty ellipsis clip), do: nil
  defp text_group("shadow" <> _), do: nil

  defp text_group(value) do
    cond do
      value =~ @font_size -> :font_size
      length_value?(value) -> :font_size
      true -> :text_color
    end
  end

  @background_keywords ~w(fixed local scroll auto cover contain none no-repeat repeat
                          bottom center left left-bottom left-top right right-bottom
                          right-top top bottom-left bottom-right top-left top-right)
  @background_prefixes ~w(clip- origin- repeat- blend- linear radial conic gradient-to- position- size-)

  # tailwind-merge resolves `bg-*` as colour unless it is an attachment, clip,
  # origin, position, repeat, size, image/gradient or blend utility.
  defp background_color?(value) when value in @background_keywords, do: false

  defp background_color?(value) do
    cond do
      String.starts_with?(value, @background_prefixes) -> false
      arbitrary?(value) -> arbitrary_label(value) in [nil, "color"] and not image?(value)
      true -> true
    end
  end

  @border_sides ~w(x y s e t r b l)
  @border_styles ~w(solid dashed dotted double hidden none)

  defp border_group(value) when value in @border_styles, do: :border_style
  defp border_group(value) when value in @border_sides, do: {:border_width, value}

  defp border_group(<<side::binary-size(1), "-", rest::binary>>) when side in @border_sides,
    do: border_value_group(side, rest)

  defp border_group(value) do
    if String.starts_with?(value, ["collapse", "separate", "spacing-"]),
      do: nil,
      else: border_value_group(:all, value)
  end

  defp border_value_group(side, value) do
    if width_value?(value), do: {:border_width, side}, else: {:border_color, side}
  end

  defp ring_group(value, ring) do
    if width_value?(value), do: :"#{ring}_width", else: :"#{ring}_color"
  end

  defp width_value?(value), do: value =~ ~r/^\d+(\.\d+)?$/ or length_value?(value)

  @length_unit ~r/\d+(%|px|r?em|[sdl]?v([hwib]|min|max)|pt|pc|in|cm|mm|cap|ch|ex|r?lh|cq(w|h|i|b|min|max))|\b(calc|min|max|clamp)\(.+\)|^0$/
  @color_function ~r/^(rgba?|hsla?|hwb|(ok)?(lab|lch)|color-mix)\(.+\)$/
  @image ~r/^(url|image|image-set|cross-fade|element|(repeating-)?(linear|radial|conic)-gradient)\(.+\)$/

  # `[...]` arbitrary value or `(...)` CSS variable shorthand, with an optional `label:`.
  defp arbitrary?(value), do: value =~ ~r/^(\[.+\]|\(.+\))$/

  defp arbitrary_label(value) do
    case Regex.run(~r/^[\[(](\w[\w-]*):/, value) do
      [_, label] -> label
      nil -> nil
    end
  end

  defp arbitrary_body(value) do
    value |> String.slice(1..-2//1) |> String.replace(~r/^\w[\w-]*:/, "")
  end

  defp length_value?(value) do
    arbitrary?(value) and
      case arbitrary_label(value) do
        "length" ->
          true

        nil ->
          String.starts_with?(value, "[") and arbitrary_body(value) =~ @length_unit and
            not (arbitrary_body(value) =~ @color_function)

        _label ->
          false
      end
  end

  defp image?(value) do
    arbitrary_label(value) in ~w(image url length size bg-size position percentage) or
      (String.starts_with?(value, "[") and arbitrary_body(value) =~ @image)
  end
end
