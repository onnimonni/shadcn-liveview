defmodule ShadcnLiveview.CalendarTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  alias Phoenix.HTML.Safe

  import ShadcnLiveview.Components.Calendar

  alias ShadcnLiveview.Components.Calendar

  test "month arithmetic crosses leap and year boundaries" do
    assert Calendar.shift_month(~D[2024-01-31], 1) == ~D[2024-02-01]
    assert Calendar.shift_month(~D[2024-12-31], 1) == ~D[2025-01-01]
    assert Calendar.shift_month(~D[2024-01-01], -1) == ~D[2023-12-01]
  end

  test "navigation respects calendar bounds" do
    state = %{month: ~D[2024-02-01], start_month: ~D[2024-02-01], end_month: ~D[2024-04-01]}
    assert Calendar.change_month(state, %{"month" => "2024-01-01"}) == state
    assert Calendar.change_month(state, %{"month" => "2024-05-01"}) == state
    assert Calendar.change_month(state, %{"month" => "2024-03-01"}).month == ~D[2024-03-01]
  end

  test "single selection toggles without changing another calendar" do
    state = %{month: ~D[2024-02-01], mode: "single", selected: ~D[2024-02-29]}
    assert Calendar.select_date(state, %{"date" => "2024-02-29"}).selected == nil
    assert Calendar.select_date(state, %{"date" => "2024-02-20"}).selected == ~D[2024-02-20]
    assert state.selected == ~D[2024-02-29]
  end

  test "disabled bounds and explicit disabled dates are enforced on the server" do
    state = %{
      mode: "single",
      selected: nil,
      disabled_before: ~D[2024-02-05],
      disabled_after: ~D[2024-02-25],
      disabled: [~D[2024-02-10]]
    }

    for date <- ["2024-02-04", "2024-02-26", "2024-02-10"] do
      assert Calendar.select_date(state, %{"date" => date}) == state
    end

    assert Calendar.select_date(state, %{"date" => "2024-02-05"}).selected == ~D[2024-02-05]
  end

  test "multiple selection adds and removes dates" do
    state = %{mode: "multiple", selected: [~D[2024-02-05]]}
    selected = Calendar.select_date(state, %{"date" => "2024-02-06"})
    assert selected.selected == [~D[2024-02-05], ~D[2024-02-06]]
    assert Calendar.select_date(selected, %{"date" => "2024-02-05"}).selected == [~D[2024-02-06]]
  end

  test "an empty range selects a completed same-day range and the same endpoint clears it" do
    state = %{mode: "range", selected: nil}
    first = Calendar.select_date(state, %{"date" => "2024-02-20"})
    assert first.selected == %{from: ~D[2024-02-20], to: ~D[2024-02-20]}
    assert Calendar.select_date(first, %{"date" => "2024-02-20"}).selected == nil
    assert Calendar.select_date(%{state | selected: %{}}, %{"date" => "2024-02-20"}) == first

    cleared = Calendar.select_date(first, %{"date" => "2024-02-20"})

    assert Calendar.select_date(cleared, %{"date" => "2024-02-10"}).selected ==
             %{from: ~D[2024-02-10], to: ~D[2024-02-10]}
  end

  test "incomplete ranges order earlier and later picks and complete an equal start" do
    for selection <- [%{from: ~D[2024-02-20]}, %{from: ~D[2024-02-20], to: nil}],
        {clicked, expected} <- [
          {"2024-02-10", %{from: ~D[2024-02-10], to: ~D[2024-02-20]}},
          {"2024-02-20", %{from: ~D[2024-02-20], to: ~D[2024-02-20]}},
          {"2024-02-21", %{from: ~D[2024-02-20], to: ~D[2024-02-21]}}
        ] do
      state = %{mode: "range", selected: selection}
      assert Calendar.select_date(state, %{"date" => clicked}).selected == expected
    end
  end

  test "completed ranges edit endpoints on earlier, later, inside and endpoint picks" do
    state = %{mode: "range", selected: %{from: ~D[2024-02-10], to: ~D[2024-02-20]}}

    # DayPicker addToRange defaults: min=0, max=0, required=false.
    for {clicked, expected} <- [
          {"2024-02-05", %{from: ~D[2024-02-05], to: ~D[2024-02-20]}},
          {"2024-02-25", %{from: ~D[2024-02-10], to: ~D[2024-02-25]}},
          {"2024-02-15", %{from: ~D[2024-02-10], to: ~D[2024-02-15]}},
          {"2024-02-10", %{from: ~D[2024-02-10], to: ~D[2024-02-10]}},
          {"2024-02-20", %{from: ~D[2024-02-20], to: ~D[2024-02-20]}}
        ] do
      assert Calendar.select_date(state, %{"date" => clicked}).selected == expected
    end

    endpoint = Calendar.select_date(state, %{"date" => "2024-02-20"})
    assert Calendar.select_date(endpoint, %{"date" => "2024-02-20"}).selected == nil
  end

  test "bounded range fixture rejects disabled clicks but permits inclusive bounds" do
    state = %{
      month: ~D[2024-02-01],
      mode: "range",
      selected: %{from: ~D[2024-02-10], to: ~D[2024-02-12]},
      disabled_before: ~D[2024-02-05],
      disabled_after: ~D[2024-02-25],
      start_month: ~D[2024-02-01],
      end_month: ~D[2024-02-01]
    }

    for clicked <- ["2024-02-04", "2024-02-26"] do
      assert Calendar.select_date(state, %{"date" => clicked}) == state
    end

    assert Calendar.select_date(state, %{"date" => "2024-02-05"}).selected ==
             %{from: ~D[2024-02-05], to: ~D[2024-02-12]}

    assert Calendar.select_date(state, %{"date" => "2024-02-25"}).selected ==
             %{from: ~D[2024-02-10], to: ~D[2024-02-25]}

    # Disabled dates inside a range do not reset it without excludeDisabled.
    disabled_middle = Map.put(state, :disabled, [~D[2024-02-15]])
    assert Calendar.select_date(disabled_middle, %{"date" => "2024-02-15"}) == disabled_middle

    assert Calendar.select_date(disabled_middle, %{"date" => "2024-02-20"}).selected ==
             %{from: ~D[2024-02-10], to: ~D[2024-02-20]}
  end

  test "multiple month grids cross the year boundary and advertise their layout" do
    assigns = %{}

    document =
      parse(~H"""
      <.calendar id="year" month={~D[2024-12-01]} today={~D[2024-02-15]} number_of_months={2} />
      """)

    assert Floki.attribute(document, "#year", "data-multiple-months") == ["true"]
    assert Floki.attribute(document, "table", "aria-label") == ["December 2024", "January 2025"]
    assert Floki.attribute(document, "[data-day='2025-01-01']", "data-outside") == ["true"]

    assert Floki.attribute(document, "[data-day='2025-01-01'][data-outside]", "data-month") == [
             "2025-01"
           ]
  end

  test "focus prefers an eligible selection across months over today" do
    assigns = %{}

    document =
      parse(~H"""
      <.calendar
        id="focus"
        month={~D[2024-12-01]}
        today={~D[2024-12-15]}
        number_of_months={2}
        mode="single"
        selected={~D[2025-01-10]}
      />
      """)

    assert Floki.attribute(document, "button[tabindex='0']", "data-day") == ["1/10/2025"]
    assert Floki.attribute(document, "[data-slot=calendar]", "data-multiple-months") == ["true"]
  end

  test "disabled selections fall back to today or the first eligible visible day" do
    for today <- [~D[2024-02-15], ~D[2023-02-15]] do
      assigns = %{today: today}

      document =
        parse(~H"""
        <.calendar
          id="fallback"
          month={~D[2024-02-01]}
          today={@today}
          mode="single"
          selected={~D[2024-02-10]}
          disabled={[~D[2024-02-10]]}
          disabled_before={~D[2024-02-05]}
          show_outside_days={false}
        />
        """)

      expected = if today.year == 2024, do: "2/15/2024", else: "2/5/2024"
      assert Floki.attribute(document, "button[tabindex='0']", "data-day") == [expected]
      assert Floki.find(document, "[data-hidden] button") == []
      assert Floki.attribute(document, "#fallback", "data-multiple-months") == []
    end
  end

  test "range rendering retains endpoints, middle days and inclusive month bounds" do
    assigns = %{}

    document =
      parse(~H"""
      <.calendar
        id="range"
        month={~D[2024-02-01]}
        today={~D[2024-02-15]}
        mode="range"
        selected={%{from: ~D[2024-02-10], to: ~D[2024-02-12]}}
        start_month={~D[2024-02-10]}
        end_month={~D[2024-02-20]}
      />
      """)

    assert Floki.attribute(document, "button[data-range-start=true]", "data-day") == ["2/10/2024"]

    assert Floki.attribute(document, "button[data-range-middle=true]", "data-day") == [
             "2/11/2024"
           ]

    assert Floki.attribute(document, "button[data-range-end=true]", "data-day") == ["2/12/2024"]
    assert length(Floki.find(document, "td[data-hidden]")) == 6
    assert Floki.find(document, "td[data-hidden] button") == []
    assert length(Floki.find(document, "nav button[aria-disabled=true]")) == 2
    assert Floki.find(document, "td[data-day='2024-02-01'][data-hidden]") == []
    assert Floki.find(document, "td[data-day='2024-02-29'][data-hidden]") == []
  end

  test "British dates keep Monday weeks, ordinal-free labels and leap day selection" do
    assigns = %{}

    document =
      parse(~H"""
      <.calendar
        id="british"
        month={~D[2024-02-01]}
        today={~D[2024-02-29]}
        mode="single"
        selected={~D[2024-02-29]}
        locale="en-GB"
      />
      """)

    assert hd(Floki.attribute(document, "th", "aria-label")) == "Monday"
    assert Floki.attribute(document, "button[tabindex='0']", "data-day") == ["29/02/2024"]

    assert Floki.attribute(document, "button[tabindex='0']", "aria-label") == [
             "Today, Thursday, 29 February 2024, selected"
           ]
  end

  defp parse(rendered) do
    rendered
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end
end
