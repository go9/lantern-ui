defmodule LanternUI.Components.DatetimeField do
  @moduledoc """
  A segmented, directly-editable date/time field — the trigger primitive the
  date pickers compose (HeroUI-style: `2 / 3 / 2026, 8:45 AM`).

      <.datetime_field id="due" name="due" mode={:date} value="2026-02-03" />
      <.datetime_field id="at" name="at" mode={:datetime} precision={:millisecond} value={nil} />

  Each segment (month/day/year/hour/minute/…) is individually editable: type
  digits, step with ↑/↓ (wrapping), move with ←/→, clear with Backspace —
  driven by the `LanternDatetimeField` hook, DOM-local.

  ## Value contract (critical — lantern's Coercion depends on it)

  A **hidden `<input name>`** carries the canonical value; the segments are
  display sugar. Canonical strings per mode:

    * `:date` → `YYYY-MM-DD`
    * `:time` → `HH:MM:SS.mmm` (24h)
    * `:datetime` → `YYYY-MM-DDTHH:MM:SS.mmm`

  An empty hidden value means null (SQL `NULL` for lantern). Display shows a
  12-hour clock with AM/PM; the canonical value is always 24h.

  `precision` controls which time segments are shown/edited: `:minute`
  (default), `:second`, or `:millisecond`. Unshown parts are carried as zeros
  in the canonical value, so ms precision survives even at `:minute` display.
  """

  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "Stable DOM id for the datetime field hook.")

  attr(:name, :string,
    default: nil,
    doc: "omit for a non-submitting field (no name on the hidden input)"
  )

  attr(:mode, :atom,
    default: :date,
    values: [:date, :time, :datetime],
    doc: "Which segment set to show: date, time, or both."
  )

  attr(:precision, :atom,
    default: :minute,
    values: [:minute, :second, :millisecond],
    doc: "Finest time segment shown; coarser parts stay zeroed."
  )

  attr(:value, :any, default: nil, doc: "canonical string (see value contract) or nil")
  attr(:nullable, :boolean, default: true, doc: "Allow clearing all segments to empty/null.")
  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:form, :string, default: nil, doc: "the form attribute forwarded to the hidden input")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:suffix, doc: "trailing affix inside the field (e.g. the picker's toggle button)")

  def datetime_field(assigns) do
    parts = parse(assigns.value, assigns.mode)

    assigns =
      assigns
      |> assign(:segments, segments(assigns.mode, assigns.precision, parts))
      |> assign(:canonical, assigns.value || "")

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-dtf", @class])}
      phx-hook="LanternDatetimeField"
      phx-update="ignore"
      role="group"
      aria-label={aria_label(@mode)}
      data-mode={@mode}
      data-precision={@precision}
      data-nullable={@nullable && "true"}
      data-disabled={@disabled && "true"}
      {@rest}
    >
      <input type="hidden" name={@name} value={@canonical} form={@form} data-part="value" />
      <span class="lui-dtf-segs" data-part="segments">
        <%= for seg <- @segments do %>
          <span :if={seg.sep} class="lui-dtf-sep">{seg.sep}</span>
          <span
            :if={!seg.sep}
            class="lui-dtf-seg"
            data-seg={seg.key}
            data-placeholder={seg.placeholder}
            data-set={seg.text && "true"}
            role="spinbutton"
            aria-label={seg.key}
            tabindex={if(@disabled, do: "-1", else: "0")}
          >{seg.text || seg.placeholder}</span>
        <% end %>
      </span>
      <button
        :if={@nullable && !@disabled}
        type="button"
        class="lui-dtf-clear"
        data-part="clear"
        aria-label="Clear value"
        tabindex="-1"
      ><Icon.icon name="x-mark" /></button>
      <span :for={suffix <- @suffix} class="lui-dtf-suffix">{render_slot(suffix)}</span>
    </div>
    """
  end

  # ── Segment layout ────────────────────────────────────────────────────────

  defp segments(mode, precision, p) do
    date = [
      seg("month", "mm", p[:month]),
      sep("/"),
      seg("day", "dd", p[:day]),
      sep("/"),
      seg("year", "yyyy", p[:year], 4)
    ]

    time =
      [
        seg("hour", "--", p[:hour12]),
        sep(":"),
        seg("minute", "--", p[:minute])
      ] ++
        if(precision in [:second, :millisecond],
          do: [sep(":"), seg("second", "--", p[:second])],
          else: []
        ) ++
        if(precision == :millisecond,
          do: [sep("."), seg("millisecond", "---", p[:millisecond], 3)],
          else: []
        ) ++
        [sep(" "), seg("meridiem", "--", p[:meridiem])]

    case mode do
      :date -> date
      :time -> time
      :datetime -> date ++ [sep(",")] ++ time
    end
  end

  defp seg(key, placeholder, value, pad \\ 2)

  defp seg(key, placeholder, nil, _pad),
    do: %{key: key, placeholder: placeholder, text: nil, sep: nil}

  defp seg("meridiem", placeholder, value, _pad),
    do: %{key: "meridiem", placeholder: placeholder, text: value, sep: nil}

  defp seg(key, placeholder, value, pad),
    do: %{
      key: key,
      placeholder: placeholder,
      text: String.pad_leading(to_string(value), pad, "0"),
      sep: nil
    }

  defp sep(s), do: %{sep: s}

  defp aria_label(:date), do: "Date"
  defp aria_label(:time), do: "Time"
  defp aria_label(:datetime), do: "Date and time"

  # ── Canonical-value parsing (server side, for SSR of the segments) ───────

  defp parse(nil, _mode), do: %{}
  defp parse("", _mode), do: %{}

  defp parse(value, :date) do
    case Date.from_iso8601(value) do
      {:ok, d} -> %{year: d.year, month: d.month, day: d.day}
      _ -> %{}
    end
  end

  defp parse(value, :time) do
    case Time.from_iso8601(pad_time(value)) do
      {:ok, t} -> time_parts(t)
      _ -> %{}
    end
  end

  defp parse(value, :datetime) do
    case NaiveDateTime.from_iso8601(pad_datetime(value)) do
      {:ok, ndt} ->
        Map.merge(
          %{year: ndt.year, month: ndt.month, day: ndt.day},
          time_parts(NaiveDateTime.to_time(ndt))
        )

      _ ->
        %{}
    end
  end

  defp time_parts(t) do
    {h12, meridiem} =
      cond do
        t.hour == 0 -> {12, "AM"}
        t.hour < 12 -> {t.hour, "AM"}
        t.hour == 12 -> {12, "PM"}
        true -> {t.hour - 12, "PM"}
      end

    {us, _} = t.microsecond

    %{
      hour12: h12,
      minute: t.minute,
      second: t.second,
      millisecond: div(us, 1000),
      meridiem: meridiem
    }
  end

  # Accept second/ms-less canonical strings ("14:30", "2026-02-03T14:30").
  defp pad_time(v) do
    case String.split(v, ":") do
      [_h, _m] -> v <> ":00"
      _ -> v
    end
  end

  defp pad_datetime(v) do
    case String.split(v, ":") do
      [_datepart_h, _m] -> v <> ":00"
      _ -> v
    end
  end
end
