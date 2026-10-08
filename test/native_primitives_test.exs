defmodule ShadcnLiveview.NativePrimitivesTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview
  alias Phoenix.HTML.Safe

  test "selection context preserves multiple choices, controlled precedence and instance isolation" do
    assigns = %{}

    document =
      parse(~H"""
      <form id="choices">
        <.native_select
          :let={selection}
          id="colors"
          name="colors"
          multiple
          default_value={["red", "blue"]}
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
        <.native_select :let={selection} id="number" name="number" value={2} default_value={1} size="sm">
          <.native_select_option value={1} selected={"1" in selection}>One</.native_select_option>
          <.native_select_option value={2} selected={"2" in selection}>Two</.native_select_option>
        </.native_select>
        <.native_select id="ordinary" name="ordinary">
          <.native_select_option value="first">First</.native_select_option>
          <.native_select_option value="second" selected>Second</.native_select_option>
        </.native_select>
      </form>
      """)

    assert Floki.attribute(document, "#colors option[selected]", "value") == ["red", "blue"]
    assert Floki.attribute(document, "#number option[selected]", "value") == ["2"]
    assert Floki.attribute(document, "#ordinary option[selected]", "value") == ["second"]
    assert Floki.find(document, "select[value]") == []
  end

  test "select attrs remain on the native element and empty value remains a selected option" do
    assigns = %{}

    document =
      parse(~H"""
      <.native_select
        :let={selection}
        id="empty"
        name="choice"
        value=""
        required
        form="external"
        aria-label="Choice"
        class="w-[180px] min-w-24 max-w-64"
      >
        <.native_select_option value="other" selected={"other" in selection}>
          Other
        </.native_select_option>
        <.native_select_option value="" selected={"" in selection}>None</.native_select_option>
        <.native_select_opt_group label="Unavailable" disabled>
          <.native_select_option value="disabled" disabled>Disabled</.native_select_option>
        </.native_select_opt_group>
      </.native_select>
      <.native_select id="disabled" name="disabled" disabled>
        <.native_select_option value="one">One</.native_select_option>
      </.native_select>
      """)

    assert Floki.attribute(document, "#empty option[selected]", "value") == [""]
    assert Floki.find(document, "select#empty[required][form=external][aria-label=Choice]") != []
    assert Floki.find(document, "#empty optgroup[disabled] option[disabled]") != []
    assert Floki.find(document, "select#disabled[disabled][name=disabled]") != []
    assert Floki.find(document, "[data-slot=native-select-wrapper][name]") == []
    [wrapper_class | _] = Floki.attribute(document, "[data-slot=native-select-wrapper]", "class")
    assert "w-[180px]" in String.split(wrapper_class)
    refute "w-fit" in String.split(wrapper_class)
    assert "min-w-24" in String.split(wrapper_class)
    assert "max-w-64" in String.split(wrapper_class)
  end

  test "progress visual percentage never becomes a Radix root value" do
    for {value, max, expected_max, transform} <- [
          {nil, nil, "100", "translateX(-100%)"},
          {0, 100, "100", "translateX(-100%)"},
          {25.5, 100, "100", "translateX(-74.5%)"},
          {100, 100, "100", "translateX(-0%)"},
          {50, 200, "200", "translateX(-50%)"},
          {125, 80, "80", "translateX(--25%)"},
          {40, 0, "100", "translateX(-60%)"}
        ] do
      assigns = %{value: value, max: max}

      document =
        parse(~H"""
        <.progress value={@value} max={@max} />
        """)

      assert Floki.attribute(document, "[data-slot=progress]", "aria-valuemax") == [expected_max]
      assert Floki.attribute(document, "[data-slot=progress]", "aria-valuemin") == ["0"]
      assert Floki.attribute(document, "[data-slot=progress]", "role") == ["progressbar"]
      assert Floki.attribute(document, "[data-slot=progress]", "data-max") == [expected_max]

      assert Floki.attribute(document, "[data-slot=progress-indicator]", "data-max") == [
               expected_max
             ]

      assert Floki.attribute(document, "[data-state]", "data-state") == [
               "indeterminate",
               "indeterminate"
             ]

      assert Floki.find(document, "[aria-valuenow], [aria-valuetext], [data-value]") == []

      assert Floki.attribute(document, "[data-slot=progress-indicator]", "style") == [
               "transform:" <> transform
             ]
    end
  end

  test "progress permits consumer ARIA and custom dimensions without losing bounds" do
    assigns = %{}

    document =
      parse(~H"""
      <.progress
        id="upload"
        value={75}
        aria-label="Upload"
        aria-valuetext="Uploading"
        class="w-[180px] min-w-24 max-w-64 h-2"
      />
      """)

    assert Floki.attribute(document, "#upload", "aria-valuetext") == ["Uploading"]
    [class] = Floki.attribute(document, "#upload", "class")
    assert "w-[180px]" in String.split(class)
    assert "h-2" in String.split(class)
    assert "min-w-24" in String.split(class)
    assert "max-w-64" in String.split(class)
    refute "w-full" in String.split(class)
    refute "h-1" in String.split(class)
  end

  test "width overrides do not erase size height or independent width bounds" do
    alias ShadcnLiveview.Helpers

    assert Helpers.classes(["size-4", "w-6"]) == "size-4 w-6"
    assert Helpers.classes(["size-4", "h-6"]) == "size-4 h-6"
    assert Helpers.classes(["w-6 h-8", "size-4"]) == "size-4"

    assert Helpers.classes(["w-full min-w-0 max-w-64", "w-[180px]"]) ==
             "min-w-0 max-w-64 w-[180px]"
  end

  test "padding overrides preserve independent axes and logical sides" do
    alias ShadcnLiveview.Helpers

    assert Helpers.classes(["px-(--card-spacing)", "p-6"]) == "p-6"
    assert Helpers.classes(["px-3 py-2 ps-1", "p-6"]) == "p-6"
    assert Helpers.classes(["p-6", "px-3"]) == "p-6 px-3"
    assert Helpers.classes(["px-3 py-2", "pr-4"]) == "px-3 py-2 pr-4"
    assert Helpers.classes(["ps-1", "px-3"]) == "ps-1 px-3"
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_document!()
  end
end
