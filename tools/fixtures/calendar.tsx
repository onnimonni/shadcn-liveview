import React from "react"
import { enGB } from "date-fns/locale"
import type { DateRange } from "react-day-picker"
import { Calendar } from "../../vendor/shadcn/ui/calendar"
import type { ComponentFixture } from "../fixtures"

const date = (year: number, month: number, day = 1) => new Date(year, month - 1, day)
const today = date(2024, 2, 15)

type CalendarProps = React.ComponentProps<typeof Calendar>

function LiveSingleCalendar(props: Omit<Extract<CalendarProps, { mode: "single" }>, "required">) {
  const [selected, setSelected] = React.useState(props.selected)
  return <Calendar {...props} mode="single" required={false} selected={selected} onSelect={setSelected} />
}

function LiveMultipleCalendar(props: Omit<Extract<CalendarProps, { mode: "multiple" }>, "required">) {
  const [selected, setSelected] = React.useState(props.selected)
  return <Calendar {...props} mode="multiple" required={false} selected={selected} onSelect={setSelected} />
}

function LiveRangeCalendar(props: Omit<Extract<CalendarProps, { mode: "range" }>, "required">) {
  const [selected, setSelected] = React.useState<DateRange | undefined>(props.selected)
  return <Calendar {...props} mode="range" required={false} selected={selected} onSelect={setSelected} />
}

function LiveCalendar(props: CalendarProps) {
  const [month, setMonth] = React.useState(props.month)
  if (props.mode === "single") {
    return <LiveSingleCalendar {...props} month={month} onMonthChange={setMonth} />
  }
  if (props.mode === "multiple") {
    return <LiveMultipleCalendar {...props} month={month} onMonthChange={setMonth} />
  }
  if (props.mode === "range") {
    return <LiveRangeCalendar {...props} month={month} onMonthChange={setMonth} />
  }
  return <Calendar {...props} month={month} onMonthChange={setMonth} />
}

export const fixtures: ComponentFixture[] = [
  {
    name: "calendar", family: "calendar", title: "Calendar", category: "forms",
    renderReact: () => <Calendar id="calendar-default" month={date(2024, 10)} today={today} />,
    renderLiveReact: () => <LiveCalendar id="calendar-default" month={date(2024, 10)} today={today} />,
    heex: `<.calendar id="calendar-default" month={~D[2024-10-01]} today={~D[2024-02-15]} />`,
    liveHeex: `<.calendar id="calendar-default" month={Map.get(@state, "calendar-default", %{month: ~D[2024-10-01]}).month} today={~D[2024-02-15]} />`
  },
  {
    name: "calendar-leap-selection", family: "calendar", title: "Leap day selection", category: "forms",
    renderReact: () => <Calendar id="calendar-leap" month={date(2024, 2)} today={today} mode="single" selected={date(2024, 2, 29)} />,
    renderLiveReact: () => <LiveCalendar id="calendar-leap" month={date(2024, 2)} today={today} mode="single" selected={date(2024, 2, 29)} />,
    heex: `<.calendar id="calendar-leap" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-02-29]} />`,
    liveHeex: `<.calendar id="calendar-leap" month={Map.get(@state, "calendar-leap", %{month: ~D[2024-02-01]}).month} today={~D[2024-02-15]} mode="single" selected={Map.get(Map.get(@state, "calendar-leap", %{}), :selected, ~D[2024-02-29])} />`
  },
  {
    name: "calendar-common-february", family: "calendar", title: "Non-leap February", category: "forms",
    renderReact: () => <Calendar id="calendar-common" month={date(2023, 2)} today={today} showOutsideDays={false} />,
    renderLiveReact: () => <LiveCalendar id="calendar-common" month={date(2023, 2)} today={today} showOutsideDays={false} />,
    heex: `<.calendar id="calendar-common" month={~D[2023-02-01]} today={~D[2024-02-15]} show_outside_days={false} />`,
    liveHeex: `<.calendar id="calendar-common" month={Map.get(@state, "calendar-common", %{month: ~D[2023-02-01]}).month} today={~D[2024-02-15]} show_outside_days={false} />`
  },
  {
    name: "calendar-bounded-range", family: "calendar", title: "Bounded selected range", category: "forms",
    renderReact: () => <Calendar id="calendar-range" month={date(2024, 2)} today={today} mode="range" selected={{ from: date(2024, 2, 10), to: date(2024, 2, 12) }} disabled={[{ before: date(2024, 2, 5) }, { after: date(2024, 2, 25) }]} startMonth={date(2024, 2)} endMonth={date(2024, 2)} showOutsideDays={false} />,
    renderLiveReact: () => <LiveCalendar id="calendar-range" month={date(2024, 2)} today={today} mode="range" selected={{ from: date(2024, 2, 10), to: date(2024, 2, 12) }} disabled={[{ before: date(2024, 2, 5) }, { after: date(2024, 2, 25) }]} startMonth={date(2024, 2)} endMonth={date(2024, 2)} showOutsideDays={false} />,
    heex: `<.calendar id="calendar-range" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="range" selected={%{from: ~D[2024-02-10], to: ~D[2024-02-12]}} disabled_before={~D[2024-02-05]} disabled_after={~D[2024-02-25]} start_month={~D[2024-02-01]} end_month={~D[2024-02-01]} show_outside_days={false} />`,
    liveHeex: `<.calendar id="calendar-range" month={Map.get(@state, "calendar-range", %{month: ~D[2024-02-01]}).month} today={~D[2024-02-15]} mode="range" selected={Map.get(Map.get(@state, "calendar-range", %{}), :selected, %{from: ~D[2024-02-10], to: ~D[2024-02-12]})} disabled_before={~D[2024-02-05]} disabled_after={~D[2024-02-25]} start_month={~D[2024-02-01]} end_month={~D[2024-02-01]} show_outside_days={false} />`
  },
  {
    name: "calendar-british-week", family: "calendar", title: "British locale and Monday weeks", category: "forms",
    renderReact: () => <Calendar id="calendar-british" month={date(2024, 2)} today={today} locale={enGB} mode="single" />,
    renderLiveReact: () => <LiveCalendar id="calendar-british" month={date(2024, 2)} today={today} locale={enGB} mode="single" />,
    heex: `<.calendar id="calendar-british" month={~D[2024-02-01]} today={~D[2024-02-15]} locale="en-GB" mode="single" />`,
    liveHeex: `<.calendar id="calendar-british" month={Map.get(@state, "calendar-british", %{month: ~D[2024-02-01]}).month} today={~D[2024-02-15]} locale="en-GB" mode="single" selected={Map.get(Map.get(@state, "calendar-british", %{}), :selected)} />`
  },
  {
    name: "calendar-fixed-multiple", family: "calendar", title: "Fixed six weeks with disabled multiple dates", category: "forms",
    renderReact: () => <Calendar id="calendar-multiple" month={date(2024, 2)} today={today} mode="multiple" selected={[date(2024, 2, 5), date(2024, 2, 21)]} disabled={[date(2024, 2, 8), date(2024, 2, 9)]} weekStartsOn={1} fixedWeeks />,
    renderLiveReact: () => <LiveCalendar id="calendar-multiple" month={date(2024, 2)} today={today} mode="multiple" selected={[date(2024, 2, 5), date(2024, 2, 21)]} disabled={[date(2024, 2, 8), date(2024, 2, 9)]} weekStartsOn={1} fixedWeeks />,
    heex: `<.calendar id="calendar-multiple" month={~D[2024-02-01]} today={~D[2024-02-15]} mode="multiple" selected={[~D[2024-02-05], ~D[2024-02-21]]} disabled={[~D[2024-02-08], ~D[2024-02-09]]} week_starts_on={1} fixed_weeks />`,
    liveHeex: `<.calendar id="calendar-multiple" month={Map.get(@state, "calendar-multiple", %{month: ~D[2024-02-01]}).month} today={~D[2024-02-15]} mode="multiple" selected={Map.get(Map.get(@state, "calendar-multiple", %{}), :selected, [~D[2024-02-05], ~D[2024-02-21]])} disabled={[~D[2024-02-08], ~D[2024-02-09]]} week_starts_on={1} fixed_weeks />`
  },
  {
    name: "calendar-year-boundary", family: "calendar", title: "Two months crossing a year boundary", category: "forms",
    renderReact: () => <Calendar id="calendar-year" month={date(2024, 12)} today={today} numberOfMonths={2} />,
    renderLiveReact: () => <LiveCalendar id="calendar-year" month={date(2024, 12)} today={today} numberOfMonths={2} />,
    heex: `<.calendar id="calendar-year" month={~D[2024-12-01]} today={~D[2024-02-15]} number_of_months={2} />`,
    liveHeex: `<.calendar id="calendar-year" month={Map.get(@state, "calendar-year", %{month: ~D[2024-12-01]}).month} today={~D[2024-02-15]} number_of_months={2} />`
  },
  {
    name: "calendar-independent-instances", family: "calendar", title: "Independent calendars", category: "forms",
    renderReact: () => <><Calendar id="calendar-first" month={date(2024, 1)} today={today} mode="single" selected={date(2024, 1, 10)} /><Calendar id="calendar-second" month={date(2024, 3)} today={today} mode="single" selected={date(2024, 3, 20)} /></>,
    renderLiveReact: () => <><LiveCalendar id="calendar-first" month={date(2024, 1)} today={today} mode="single" selected={date(2024, 1, 10)} /><LiveCalendar id="calendar-second" month={date(2024, 3)} today={today} mode="single" selected={date(2024, 3, 20)} /></>,
    heex: `<.calendar id="calendar-first" month={~D[2024-01-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-01-10]} /><.calendar id="calendar-second" month={~D[2024-03-01]} today={~D[2024-02-15]} mode="single" selected={~D[2024-03-20]} />`,
    liveHeex: `<.calendar id="calendar-first" month={Map.get(@state, "calendar-first", %{month: ~D[2024-01-01]}).month} today={~D[2024-02-15]} mode="single" selected={Map.get(Map.get(@state, "calendar-first", %{}), :selected, ~D[2024-01-10])} /><.calendar id="calendar-second" month={Map.get(@state, "calendar-second", %{month: ~D[2024-03-01]}).month} today={~D[2024-02-15]} mode="single" selected={Map.get(Map.get(@state, "calendar-second", %{}), :selected, ~D[2024-03-20])} />`
  }
]
