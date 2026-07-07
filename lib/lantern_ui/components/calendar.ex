defmodule LanternUI.Components.Calendar do
  @moduledoc """
  A month-grid calendar primitive — the pane the date pickers compose.

      <.calendar id="cal" selected={~D[2026-02-03]} />
      <.calendar id="cal" month={~D[2026-02-01]} week_start={1} min="2026-01-01" />

  Server-renders the full initial grid (6 rows × 7 days, WAI-ARIA grid roles);
  the `LanternCalendar` JS hook takes over month navigation and keyboard
  interaction client-side (no LiveView round-trips — works in dead views and
  embedded hosts). Selecting a day writes the ISO date to the element's
  `data-value` and emits a `lantern:change` CustomEvent; pickers listen to that.

  States: selected day = monochrome-primary fill, today = coral ring,
  adjacent-month days dimmed, out-of-`min`/`max` days disabled.
  """

  use Phoenix.Component

  alias LanternUI.Class

  @week_days ~w(Su Mo Tu We Th Fr Sa)

  attr(:id, :string, required: true)
  attr(:month, Date, default: nil, doc: "month to display; defaults to selected || today")
  attr(:selected, Date, default: nil)
  attr(:week_start, :integer, default: 0, values: 0..6)
  attr(:min, :string, default: nil, doc: "ISO date; earlier days are disabled")
  attr(:max, :string, default: nil, doc: "ISO date; later days are disabled")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def calendar(assigns) do
    month = assigns.month || assigns.selected || Date.utc_today()
    month = Date.beginning_of_month(month)

    assigns =
      assigns
      |> assign(:month, month)
      |> assign(:weeks, weeks(month, assigns.week_start))
      |> assign(:weekday_labels, weekday_labels(assigns.week_start))
      |> assign(:today, Date.utc_today())
      |> assign(:min_d, assigns.min && Date.from_iso8601!(assigns.min))
      |> assign(:max_d, assigns.max && Date.from_iso8601!(assigns.max))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-cal", @class])}
      phx-hook="LanternCalendar"
      phx-update="ignore"
      data-month={Date.to_iso8601(@month)}
      data-value={@selected && Date.to_iso8601(@selected)}
      data-week-start={@week_start}
      data-min={@min}
      data-max={@max}
      {@rest}
    >
      <div class="lui-cal-head">
        <button type="button" class="lui-cal-nav" data-part="prev" aria-label="Previous month">
          <LanternUI.Components.Icon.icon name="chevron-left" />
        </button>
        <span class="lui-cal-title" data-part="title" aria-live="polite">{title(@month)}</span>
        <button type="button" class="lui-cal-nav" data-part="next" aria-label="Next month">
          <LanternUI.Components.Icon.icon name="chevron-right" />
        </button>
      </div>

      <div role="grid" data-part="grid" class="lui-cal-grid" aria-label="Calendar">
        <div role="row" class="lui-cal-row">
          <span :for={wd <- @weekday_labels} role="columnheader" class="lui-cal-wd">{wd}</span>
        </div>
        <div :for={week <- @weeks} role="row" class="lui-cal-row">
          <button
            :for={day <- week}
            type="button"
            role="gridcell"
            class="lui-cal-day"
            data-date={Date.to_iso8601(day)}
            data-outside={day.month != @month.month || nil}
            data-today={day == @today || nil}
            aria-selected={day == @selected && "true"}
            aria-label={Calendar.strftime(day, "%B %-d, %Y")}
            disabled={disabled?(day, @min_d, @max_d)}
            tabindex={if(focusable?(day, @selected, @month), do: "0", else: "-1")}
          >
            {day.day}
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc false
  def weeks(month_start, week_start) do
    days_back = Integer.mod(Date.day_of_week(month_start, :sunday) - 1 - week_start, 7)
    first = Date.add(month_start, -days_back)

    for w <- 0..5 do
      for d <- 0..6, do: Date.add(first, w * 7 + d)
    end
  end

  defp weekday_labels(week_start) do
    {a, b} = Enum.split(@week_days, week_start)
    b ++ a
  end

  defp title(month), do: Calendar.strftime(month, "%B %Y")

  defp disabled?(day, min_d, max_d) do
    (min_d && Date.before?(day, min_d)) || (max_d && Date.after?(day, max_d)) || false
  end

  # Roving tabindex: the selected day (when visible) or the 1st of the month.
  defp focusable?(day, selected, month) do
    if selected && selected.month == month.month && selected.year == month.year,
      do: day == selected,
      else: day == month
  end
end
