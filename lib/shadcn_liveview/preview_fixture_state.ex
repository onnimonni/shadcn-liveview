defmodule ShadcnLiveview.Preview.FixtureState do
  @moduledoc false

  # Calendar transitions require the caller's complete initial rules, not just the
  # clicked date. Each iframe owns its map independently, including paired calendars.
  @calendars %{
    "calendar-default" => %{month: ~D[2024-10-01], mode: nil, selected: nil},
    "calendar-leap" => %{month: ~D[2024-02-01], mode: "single", selected: ~D[2024-02-29]},
    "calendar-common" => %{month: ~D[2023-02-01], mode: nil, selected: nil},
    "calendar-range" => %{
      month: ~D[2024-02-01],
      mode: "range",
      selected: %{from: ~D[2024-02-10], to: ~D[2024-02-12]},
      disabled_before: ~D[2024-02-05],
      disabled_after: ~D[2024-02-25],
      start_month: ~D[2024-02-01],
      end_month: ~D[2024-02-01]
    },
    "calendar-british" => %{month: ~D[2024-02-01], mode: "single", selected: nil},
    "calendar-multiple" => %{
      month: ~D[2024-02-01],
      mode: "multiple",
      selected: [~D[2024-02-05], ~D[2024-02-21]],
      disabled: [~D[2024-02-08], ~D[2024-02-09]]
    },
    "calendar-year" => %{month: ~D[2024-12-01], mode: nil, selected: nil},
    "calendar-first" => %{month: ~D[2024-01-01], mode: "single", selected: ~D[2024-01-10]},
    "calendar-second" => %{month: ~D[2024-03-01], mode: "single", selected: ~D[2024-03-20]}
  }

  def calendar(id), do: Map.fetch!(@calendars, id)
end
