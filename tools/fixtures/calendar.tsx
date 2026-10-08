import React from "react"
import { enGB } from "date-fns/locale"
import { Calendar } from "../../vendor/shadcn/ui/calendar"
import type { ComponentFixture } from "../fixtures"

const date = (year: number, month: number, day = 1) => new Date(year, month - 1, day)
const today = date(2024, 2, 15)

export const fixtures: ComponentFixture[] = [
  {
    name: "calendar", family: "calendar", title: "Calendar", category: "forms",
    renderReact: () => <Calendar id="calendar-default" month={date(2024, 10)} today={today} />,
    heex: `<.calendar id="calendar-default" month={~D[2024-10-01]} today={~D[2024-02-15]} />`
  },
  {
    name: "calendar-leap-selection", family: "calendar", title: "Leap day selection", category: "forms",
    renderReact: () => <Calendar id="calendar-leap" month={date(2024, 2)} today={today} mode="single" selected={date(2024, 2, 29)} />,
    heex: `<.calendar id="calendar-leap" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-02-29]} />`,
    liveHeex: `<.calendar id="calendar-leap" month={Map.get(@state, "calendar-leap", %{month: ~D[2024-02-01]}).month} today={~D[2024-02-15]} mode="single" selected={Map.get(Map.get(@state, "calendar-leap", %{}), :selected, ~D[2024-02-29])} />`
  },
  {
    name: "calendar-common-february", family: "calendar", title: "Non-leap February", category: "forms",
    renderReact: () => <Calendar id="calendar-common" month={date(2023, 2)} today={today} showOutsideDays={false} />,
    heex: `<.calendar id="calendar-common" month={~D[2023-02-01]} today={~D[2024-02-15]} show_outside_days={false} />`
  },
  {
    name: "calendar-bounded-range", family: "calendar", title: "Bounded selected range", category: "forms",
    renderReact: () => <Calendar id="calendar-range" month={date(2024, 2)} today={today} mode="range" selected={{ from: date(2024, 2, 10), to: date(2024, 2, 12) }} disabled={[{ before: date(2024, 2, 5) }, { after: date(2024, 2, 25) }]} startMonth={date(2024, 2)} endMonth={date(2024, 2)} showOutsideDays={false} />,
    heex: `<.calendar id="calendar-range" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="range" selected={%{from: ~D[2024-02-10], to: ~D[2024-02-12]}} disabled_before={~D[2024-02-05]} disabled_after={~D[2024-02-25]} start_month={~D[2024-02-01]} end_month={~D[2024-02-01]} show_outside_days={false} />`
  },
  {
    name: "calendar-british-week", family: "calendar", title: "British locale and Monday weeks", category: "forms",
    renderReact: () => <Calendar id="calendar-british" month={date(2024, 2)} today={today} locale={enGB} mode="single" />,
    heex: `<.calendar id="calendar-british" month={~D[2024-02-01]} today={~D[2024-02-15]} locale="en-GB" mode="single" />`
  },
  {
    name: "calendar-fixed-multiple", family: "calendar", title: "Fixed six weeks with disabled multiple dates", category: "forms",
    renderReact: () => <Calendar id="calendar-multiple" month={date(2024, 2)} today={today} mode="multiple" selected={[date(2024, 2, 5), date(2024, 2, 21)]} disabled={[date(2024, 2, 8), date(2024, 2, 9)]} weekStartsOn={1} fixedWeeks />,
    heex: `<.calendar id="calendar-multiple" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="multiple" selected={[~D[2024-02-05], ~D[2024-02-21]]} disabled={[~D[2024-02-08], ~D[2024-02-09]]} week_starts_on={1} fixed_weeks />`
  },
  {
    name: "calendar-year-boundary", family: "calendar", title: "Two months crossing a year boundary", category: "forms",
    renderReact: () => <Calendar id="calendar-year" month={date(2024, 12)} today={today} numberOfMonths={2} />,
    heex: `<.calendar id="calendar-year" month={~D[2024-12-01]} today={~D[2024-02-15]} number_of_months={2} />`
  },
  {
    name: "calendar-independent-instances", family: "calendar", title: "Independent calendars", category: "forms",
    renderReact: () => <><Calendar id="calendar-first" month={date(2024, 1)} today={today} mode="single" selected={date(2024, 1, 10)} /><Calendar id="calendar-second" month={date(2024, 3)} today={today} mode="single" selected={date(2024, 3, 20)} /></>,
    heex: `<.calendar id="calendar-first" month={~D[2024-01-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-01-10]} /><.calendar id="calendar-second" month={~D[2024-03-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-03-20]} />`
  }
]
