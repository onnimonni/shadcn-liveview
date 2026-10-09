defmodule ShadcnLiveview.Components.Calendar do
  @moduledoc """
  Date-computed DayPicker-style calendar. Supply a stable id and a Date month.

  Navigation sends the on_month_change event with id and ISO month; selection sends
  on_select with id and ISO date. In a LiveView handle_event, pass the calendar's
  current assigns to change_month/2 or select_date/2 and assign the returned map.
  This controlled API keeps independent calendars and server-side disabled rules
  isolated. The optional day slot receives the Date, replacing the day number.
  Range selection follows DayPicker's default optional, zero-minimum range model:
  the first click completes a same-day range, clicking it again clears selection,
  and subsequent clicks edit the existing endpoints rather than restart the range.
  locale accepts en-US or en-GB; week_starts_on is 0 (Sunday) through 6 (Saturday).
  Month bounds are normalized once per render. Keyboard focus prefers an eligible
  selected day, then today, then the first visible enabled day in the shown months.
  Arrow keys move by day/week; Home/End respect week_starts_on. PageUp/PageDown
  move months (Shift moves years), preserving focus across controlled month patches.
  Set phx-target on the root (or optional target) to route both native navigation/
  selection commands and hook month changes to a LiveComponent. Hook events also
  inherit the nearest containing phx-target without moving any caller DOM.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias ShadcnLiveview.Helpers

  @styles %{
    months: "relative flex flex-col gap-4 md:flex-row rdp-months",
    month: "flex w-full flex-col gap-4 rdp-month",
    nav: "absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1 rdp-nav",
    month_caption:
      "flex h-(--cell-size) w-full items-center justify-center px-(--cell-size) rdp-month_caption",
    month_grid: "w-full border-collapse rdp-month_grid",
    weekdays: "flex rdp-weekdays",
    weekday:
      "flex-1 rounded-(--cell-radius) text-[0.8rem] font-normal text-muted-foreground select-none rdp-weekday",
    week: "mt-2 flex w-full rdp-week",
    outside: "text-muted-foreground aria-selected:text-muted-foreground rdp-outside",
    disabled: "text-muted-foreground opacity-50 rdp-disabled",
    hidden: "invisible rdp-hidden",
    today:
      "rounded-(--cell-radius) bg-muted text-foreground data-[selected=true]:rounded-none rdp-today",
    range_start:
      "relative isolate z-0 rounded-l-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:right-0 after:w-4 after:bg-muted rdp-range_start",
    range_middle: "rounded-none rdp-range_middle",
    range_end:
      "relative isolate z-0 rounded-r-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:left-0 after:w-4 after:bg-muted rdp-range_end"
  }
  @months ~w(January February March April May June July August September October November December)
  @weekdays ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)

  attr :id, :string, required: true
  attr :month, :any, required: true
  attr :today, :any, default: nil
  attr :mode, :string, default: nil, values: [nil, "single", "multiple", "range"]
  attr :selected, :any, default: nil
  attr :disabled, :any, default: []
  attr :disabled_before, :any, default: nil
  attr :disabled_after, :any, default: nil
  attr :start_month, :any, default: nil
  attr :end_month, :any, default: nil
  attr :locale, :string, default: "en-US", values: ["en-US", "en-GB"]
  attr :week_starts_on, :integer, default: nil
  attr :show_outside_days, :boolean, default: true
  attr :fixed_weeks, :boolean, default: false
  attr :number_of_months, :integer, default: 1
  attr :hide_navigation, :boolean, default: false
  attr :on_month_change, :string, default: "calendar-month"
  attr :on_select, :string, default: "calendar-select"
  attr :target, :any, default: nil
  attr :class, :string, default: nil
  attr :class_names, :map, default: %{}
  attr :rest, :global
  slot :day

  @doc "Renders a computed month grid and controlled LiveView navigation/selection."
  def calendar(assigns) do
    assigns = assign(assigns, calendar_state(assigns))
    target = assigns.target || Map.get(assigns.rest, :"phx-target")
    assigns = assign(assigns, target: target, rest: Map.delete(assigns.rest, :"phx-target"))

    ~H"""
    <div
      id={@id}
      data-slot="calendar"
      lang={@locale}
      data-mode={@mode}
      data-multiple-months={truth(@number_of_months > 1)}
      class={
        Helpers.classes([
          "w-fit rdp-root group/calendar bg-background p-2 [--cell-radius:var(--radius-md)] [--cell-size:--spacing(7)] in-data-[slot=card-content]:bg-transparent in-data-[slot=popover-content]:bg-transparent rtl:**:[.rdp-button\\_next>svg]:rotate-180 rtl:**:[.rdp-button\\_previous>svg]:rotate-180",
          @class
        ])
      }
      phx-hook=".Calendar"
      phx-target={@target}
      phx-value-month={Date.to_iso8601(Date.beginning_of_month(@month))}
      phx-value-month-count={@number_of_months}
      phx-value-week-start={@week_starts_on || if(@locale == "en-GB", do: 1, else: 0)}
      phx-value-month-event={@on_month_change}
      phx-value-start={if @start_month, do: Date.to_iso8601(Date.beginning_of_month(@start_month))}
      phx-value-end={if @end_month, do: Date.to_iso8601(Date.end_of_month(@end_month))}
      phx-value-disabled-before={if @disabled_before, do: Date.to_iso8601(@disabled_before)}
      phx-value-disabled-after={if @disabled_after, do: Date.to_iso8601(@disabled_after)}
      {@rest}
    >
      <div class={style(@class_names, :months)}>
        <nav :if={!@hide_navigation} class={style(@class_names, :nav)} aria-label="Navigation bar">
          <button
            type="button"
            class={
              Helpers.classes([
                "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 gap-1.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 size-(--cell-size) p-0 select-none aria-disabled:opacity-50",
                "rdp-button_previous"
              ])
            }
            tabindex={if @previous_disabled, do: "-1"}
            aria-disabled={truth(@previous_disabled)}
            aria-label="Go to the Previous Month"
            phx-click={
              if !@previous_disabled,
                do: push(@on_month_change, %{id: @id, month: Date.to_iso8601(@previous)}, @target)
            }
          >
            <.chevron direction="left" disabled={@previous_disabled} />
          </button>
          <button
            type="button"
            class={
              Helpers.classes([
                "group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 gap-1.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 size-(--cell-size) p-0 select-none aria-disabled:opacity-50",
                "rdp-button_next"
              ])
            }
            tabindex={if @next_disabled, do: "-1"}
            aria-disabled={truth(@next_disabled)}
            aria-label="Go to the Next Month"
            phx-click={
              if !@next_disabled,
                do: push(@on_month_change, %{id: @id, month: Date.to_iso8601(@next)}, @target)
            }
          >
            <.chevron direction="right" disabled={@next_disabled} />
          </button>
        </nav>
        <div :for={month <- @months} class={style(@class_names, :month)}>
          <div class={style(@class_names, :month_caption)}>
            <span
              class="font-medium select-none cn-calendar-caption text-sm rdp-caption_label"
              role="status"
              aria-live="polite"
            >{month.caption}</span>
          </div>
          <table
            role="grid"
            aria-multiselectable={to_string(@mode in ["multiple", "range"])}
            aria-label={month.caption}
            class={style(@class_names, :month_grid)}
          >
            <thead aria-hidden="true">
              <tr class={style(@class_names, :weekdays)}>
                <th
                  :for={weekday <- @weekdays}
                  aria-label={weekday}
                  class={style(@class_names, :weekday)}
                  scope="col"
                >
                  {String.slice(weekday, 0, 2)}
                </th>
              </tr>
            </thead>
            <tbody class="rdp-weeks">
              <tr :for={week <- month.weeks} class={style(@class_names, :week)}>
                <td
                  :for={cell <- week}
                  class={cell_class(cell, @class_names)}
                  role="gridcell"
                  aria-selected={truth(cell.selected)}
                  aria-label={if is_nil(@mode) and not cell.hidden, do: cell.label}
                  data-day={cell.iso_date}
                  data-month={cell.outside_month}
                  data-selected={truth(cell.selected)}
                  data-disabled={truth(cell.disabled)}
                  data-hidden={truth(cell.hidden)}
                  data-outside={truth(cell.outside)}
                  data-today={truth(cell.today)}
                >
                  <%= if not cell.hidden do %>
                    <%= if @mode do %>
                      <button
                        type="button"
                        data-slot="button"
                        data-variant="ghost"
                        data-size="icon"
                        class="group/button shrink-0 items-center justify-center rounded-lg border-transparent bg-clip-padding text-sm whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 relative isolate z-10 flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 border-0 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-(--cell-radius) data-[range-end=true]:rounded-r-(--cell-radius) data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-muted data-[range-middle=true]:text-foreground data-[range-start=true]:rounded-(--cell-radius) data-[range-start=true]:rounded-l-(--cell-radius) data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-foreground [&>span]:text-xs [&>span]:opacity-70 rdp-day rdp-day_button"
                        data-day={local_date(cell.date, @locale)}
                        data-selected-single={
                          if cell.selected,
                            do:
                              to_string(
                                not cell.range_start and not cell.range_end and not cell.range_middle
                              )
                        }
                        data-range-start={
                          if @mode == "range" and @selected, do: to_string(cell.range_start)
                        }
                        data-range-end={
                          if @mode == "range" and @selected, do: to_string(cell.range_end)
                        }
                        data-range-middle={
                          if @mode == "range" and @selected, do: to_string(cell.range_middle)
                        }
                        disabled={cell.disabled}
                        tabindex={if cell.date == @focus, do: "0", else: "-1"}
                        aria-label={cell.label}
                        phx-click={push(@on_select, %{id: @id, date: cell.iso_date}, @target)}
                      >
                        {if @day == [], do: cell.date.day, else: render_slot(@day, cell.date)}
                      </button>
                    <% else %>
                      {if @day == [], do: cell.date.day, else: render_slot(@day, cell.date)}
                    <% end %>
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Calendar">
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          this.onFocus = event => {
            const day = event.target.closest("td[data-day] button");
            if (day) this.rove(day);
          };
          this.onKey = event => {
            const cell = event.target.closest("td[data-day]");
            if (!cell || !event.target.matches("button") || event.target.disabled) return;
            const date = new Date(cell.dataset.day + "T00:00:00Z");
            const rtl = getComputedStyle(this.el).direction === "rtl";
            const step = {ArrowLeft: rtl ? 1 : -1, ArrowRight: rtl ? -1 : 1, ArrowUp: -7, ArrowDown: 7};
            let direction = step[event.key];
            if (direction) date.setUTCDate(date.getUTCDate() + direction);
            else if (event.key === "Home" || event.key === "End") {
              const weekday = (date.getUTCDay() - Number(this.el.getAttribute("phx-value-week-start")) + 7) % 7;
              direction = event.key === "Home" ? 1 : -1;
              date.setUTCDate(date.getUTCDate() + (event.key === "Home" ? -weekday : 6 - weekday));
            } else if (event.key === "PageUp" || event.key === "PageDown") {
              direction = event.key === "PageUp" ? -1 : 1;
              const month = date.getUTCMonth() + direction * (event.shiftKey ? 12 : 1);
              const last = new Date(Date.UTC(date.getUTCFullYear(), month + 1, 0)).getUTCDate();
              date.setUTCFullYear(date.getUTCFullYear(), month, Math.min(date.getUTCDate(), last));
            } else return;
            event.preventDefault();
            this.move(date, direction);
          };
          this.el.addEventListener("focusin", this.onFocus);
          this.el.addEventListener("keydown", this.onKey);
        },
        rove(day) {
          this.el.querySelectorAll("td[data-day] button").forEach(button => button.tabIndex = button === day ? 0 : -1);
        },
        find(iso) { return this.el.querySelector('td[data-day="' + iso + '"] button:not(:disabled)'); },
        move(date, direction) {
          const iso = date.toISOString().slice(0, 10);
          const minimum = this.el.getAttribute("phx-value-start"), maximum = this.el.getAttribute("phx-value-end");
          if ((minimum && iso < minimum) || (maximum && iso > maximum)) return;
          const before = this.el.getAttribute("phx-value-disabled-before"), after = this.el.getAttribute("phx-value-disabled-after");
          if (before && iso < before) {
            if (direction > 0) this.move(new Date(before + "T00:00:00Z"), direction);
            return;
          }
          if (after && iso > after) {
            if (direction < 0) this.move(new Date(after + "T00:00:00Z"), direction);
            return;
          }
          const cell = this.el.querySelector('td[data-day="' + iso + '"]');
          if (cell?.hasAttribute("data-disabled")) {
            date.setUTCDate(date.getUTCDate() + (direction < 0 ? -1 : 1));
            this.move(date, direction); return;
          }
          const first = this.el.getAttribute("phx-value-month");
          const last = new Date(first + "T00:00:00Z");
          const count = Number(this.el.getAttribute("phx-value-month-count"));
          last.setUTCMonth(last.getUTCMonth() + count);
          if (iso >= first && iso < last.toISOString().slice(0, 10)) {
            const day = this.find(iso); if (day) { this.rove(day); day.focus(); }
            return;
          }
          const event = this.el.getAttribute("phx-value-month-event"); if (!event) return;
          this.pendingFocus = iso;
          date.setUTCDate(1);
          if (iso > first) date.setUTCMonth(date.getUTCMonth() - count + 1);
          this.sendEvent(event, {id: this.el.id, month: date.toISOString().slice(0, 10)});
        },
        beforeUpdate() { this.restoreFocus = this.el.contains(document.activeElement) ? document.activeElement.closest("td[data-day]")?.dataset.day : null; },
        updated() {
          const iso = this.pendingFocus || this.restoreFocus;
          const day = iso && this.find(iso);
          if (day) { this.pendingFocus = null; this.rove(day); day.focus(); }
        },
        destroyed() {
          this.el.removeEventListener("focusin", this.onFocus);
          this.el.removeEventListener("keydown", this.onKey);
        }
      }
    </script>
    """
  end

  attr :direction, :string, required: true
  attr :disabled, :boolean, required: true

  defp chevron(assigns) do
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
      class={"lucide lucide-chevron-#{@direction} cn-rtl-flip size-4 rdp-chevron"}
      aria-hidden="true"
      tabler={"IconChevron#{String.capitalize(@direction)}"}
      hugeicons={"Arrow#{String.capitalize(@direction)}Icon"}
      phosphor={"Caret#{String.capitalize(@direction)}Icon"}
      remixicon={if @direction == "left", do: "RiArrowLeftSLine", else: "RiArrowRightSLine"}
      disabled={@disabled}
    ><path d={if @direction == "left", do: "m15 18-6-6 6-6", else: "m9 18 6-6-6-6"} /></svg>
    """
  end

  defp truth(true), do: "true"
  defp truth(_), do: nil
  defp style(overrides, name), do: Map.get(overrides, name, Map.fetch!(@styles, name))
  defp push(nil, _, _), do: nil
  defp push(event, values, target) when target in [nil, ""], do: JS.push(event, value: values)
  defp push(event, values, target), do: JS.push(event, value: values, target: target)
  defp caption(date), do: "#{Enum.at(@months, date.month - 1)} #{date.year}"
  defp local_date(date, "en-GB"), do: "#{pad(date.day)}/#{pad(date.month)}/#{date.year}"
  defp local_date(date, _), do: "#{date.month}/#{date.day}/#{date.year}"
  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  defp calendar_state(assigns) do
    month = Date.beginning_of_month(assigns.month)
    start = week_start(assigns.week_starts_on, assigns.locale)
    end_month = month_start(assigns.end_month)

    state =
      assign(assigns,
        today: today_date(assigns.today),
        start_date: month_start(assigns.start_month),
        end_date: month_end(end_month)
      )

    months =
      Enum.map(0..(max(assigns.number_of_months, 1) - 1), fn offset ->
        month_state(shift_month(month, offset), start, state)
      end)

    %{
      month: month,
      today: state.today,
      months: months,
      focus: focus_date(months),
      weekdays: Enum.map(0..6, &Enum.at(@weekdays, Integer.mod(start + &1, 7))),
      previous: shift_month(month, -1),
      next: shift_month(month, 1),
      previous_disabled: at_or_before_date?(month, state.start_date),
      next_disabled: after_date?(shift_month(month, assigns.number_of_months), end_month)
    }
  end

  defp today_date(nil), do: Date.utc_today()
  defp today_date(false), do: Date.utc_today()
  defp today_date(date), do: date
  defp week_start(nil, "en-GB"), do: 1
  defp week_start(nil, _), do: 0
  defp week_start(start, _), do: start
  defp month_start(nil), do: nil
  defp month_start(date), do: Date.beginning_of_month(date)
  defp month_end(nil), do: nil
  defp month_end(date), do: Date.end_of_month(date)
  defp before_date?(_, nil), do: false
  defp before_date?(date, bound), do: Date.compare(date, bound) == :lt
  defp after_date?(_, nil), do: false
  defp after_date?(date, bound), do: Date.compare(date, bound) == :gt
  defp at_or_before_date?(_, nil), do: false
  defp at_or_before_date?(date, bound), do: Date.compare(date, bound) != :gt

  defp month_state(date, start, state) do
    first = Date.add(date, -Integer.mod(Date.day_of_week(date) - start, 7))
    count = grid_count(first, date, state.fixed_weeks)
    days = Enum.map(0..(count - 1), &cell(Date.add(first, &1), date, state))
    %{date: date, caption: caption(date), weeks: Enum.chunk_every(days, 7)}
  end

  defp grid_count(_, _, true), do: 42

  defp grid_count(first, date, false),
    do: div(Date.diff(Date.end_of_month(date), first) + 7, 7) * 7

  defp focus_date(months) do
    {selected, today, first} = Enum.reduce(months, {nil, nil, nil}, &month_focus/2)
    selected || today || first
  end

  defp month_focus(month, focus), do: Enum.reduce(month.weeks, focus, &week_focus/2)
  defp week_focus(week, focus), do: Enum.reduce(week, focus, &day_focus/2)
  defp day_focus(%{disabled: true}, focus), do: focus
  defp day_focus(%{hidden: true}, focus), do: focus
  defp day_focus(%{outside: true}, focus), do: focus

  defp day_focus(cell, {selected, today, first}) do
    {if(cell.selected, do: selected || cell.date, else: selected),
     if(cell.today, do: today || cell.date, else: today), first || cell.date}
  end

  defp ordinal(n) when rem(n, 100) in 11..13, do: "#{n}th"

  defp ordinal(n),
    do:
      "#{n}#{case rem(n, 10) do
        1 -> "st"
        2 -> "nd"
        3 -> "rd"
        _ -> "th"
      end}"

  @doc "Moves a Date to the first day of another month, including year boundaries."
  def shift_month(date, offset) do
    index = date.year * 12 + date.month - 1 + offset
    Date.new!(Integer.floor_div(index, 12), Integer.mod(index, 12) + 1, 1)
  end

  defp disabled?(date, state) do
    before_date?(date, state[:disabled_before]) or after_date?(date, state[:disabled_after]) or
      disabled_date?(date, state[:disabled])
  end

  defp disabled_date?(_, true), do: true
  defp disabled_date?(date, fun) when is_function(fun, 1), do: fun.(date)
  defp disabled_date?(date, dates) when is_list(dates), do: date in dates
  defp disabled_date?(_, _), do: false

  defp cell(date, month, assigns) do
    outside = date.month != month.month or date.year != month.year
    selected = selected?(date, assigns.mode, assigns.selected)

    {range_start, range_end, range_middle} =
      range_state(date, assigns.mode, assigns.selected, selected)

    today = date == assigns.today
    iso_date = Date.to_iso8601(date)

    %{
      date: date,
      iso_date: iso_date,
      outside_month: outside_month(outside, iso_date),
      outside: outside,
      disabled: disabled?(date, assigns),
      hidden: hidden?(date, outside, assigns),
      selected: selected,
      today: today,
      range_start: range_start,
      range_end: range_end,
      range_middle: range_middle,
      label: today_label(today) <> day_label(date, assigns.locale) <> selection_label(selected)
    }
  end

  defp outside_month(true, iso_date), do: String.slice(iso_date, 0, 7)
  defp outside_month(false, _), do: nil

  defp range_state(date, "range", selection, selected) when is_map(selection) do
    first = date == selection[:from]
    last = date == selection[:to]
    {first, last, selected and not first and not last}
  end

  defp range_state(_, _, _, _), do: {false, false, false}

  defp day_label(date, locale) do
    weekday = Enum.at(@weekdays, Integer.mod(Date.day_of_week(date), 7))
    month = Enum.at(@months, date.month - 1)
    format_day_label(date, locale, weekday, month)
  end

  defp format_day_label(date, "en-GB", weekday, month),
    do: "#{weekday}, #{date.day} #{month} #{date.year}"

  defp format_day_label(date, _, weekday, month),
    do: "#{weekday}, #{month} #{ordinal(date.day)}, #{date.year}"

  defp today_label(true), do: "Today, "
  defp today_label(false), do: ""
  defp selection_label(true), do: ", selected"
  defp selection_label(false), do: ""

  defp selected?(date, "single", %Date{} = selected), do: date == selected
  defp selected?(date, "multiple", selected) when is_list(selected), do: date in selected

  defp selected?(date, "range", %{from: %Date{} = first, to: %Date{} = last}),
    do: Date.compare(date, first) != :lt and Date.compare(date, last) != :gt

  defp selected?(date, "range", %{from: %Date{} = first}), do: date == first
  defp selected?(_, _, _), do: false

  defp hidden?(date, outside, assigns) do
    (outside and not assigns.show_outside_days) or before_date?(date, assigns.start_date) or
      after_date?(date, assigns.end_date)
  end

  defp cell_class(cell, overrides) do
    ([
       Map.get(
         overrides,
         :day,
         "group/day relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius) [&:first-child[data-selected=true]_button]:rounded-l-(--cell-radius) rdp-day"
       ),
       if(cell.selected, do: Map.get(overrides, :selected, "rdp-selected"))
     ] ++
       Enum.map(
         [:today, :outside, :disabled, :hidden, :range_start, :range_middle, :range_end],
         fn key -> if Map.fetch!(cell, key), do: style(overrides, key) end
       ))
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  @doc "Returns updated controlled assigns for an ISO month navigation event."
  def change_month(state, %{"month" => iso}) do
    month = iso |> Date.from_iso8601!() |> Date.beginning_of_month()

    if before_date?(month, month_start(state[:start_month])) or
         after_date?(month, month_start(state[:end_month])),
       do: state,
       else: Map.put(state, :month, month)
  end

  @doc "Applies a date selection event, preserving server-side disabled bounds."
  def select_date(state, %{"date" => iso}) do
    date = Date.from_iso8601!(iso)

    if disabled?(date, state) do
      state
    else
      Map.put(state, :selected, next_selection(date, state[:mode], state[:selected]))
    end
  end

  defp next_selection(date, "single", date), do: nil
  defp next_selection(date, "single", _), do: date
  defp next_selection(date, "multiple", nil), do: [date]

  defp next_selection(date, "multiple", dates) when is_list(dates) do
    if date in dates, do: List.delete(dates, date), else: dates ++ [date]
  end

  # react-day-picker 10.0.2 utils/addToRange: min=0, max=0, required=false.
  defp next_selection(date, "range", %{from: %Date{} = first, to: %Date{} = last}) do
    cond do
      date == first and date == last -> nil
      date == first or date == last -> %{from: date, to: date}
      Date.compare(date, first) == :lt -> %{from: date, to: last}
      true -> %{from: first, to: date}
    end
  end

  defp next_selection(date, "range", %{from: %Date{} = first}) do
    if Date.compare(date, first) == :lt,
      do: %{from: date, to: first},
      else: %{from: first, to: date}
  end

  defp next_selection(_, "range", %{to: %Date{}}), do: nil
  defp next_selection(date, "range", _), do: %{from: date, to: date}
  defp next_selection(_, _, selected), do: selected
end
