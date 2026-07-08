defmodule LanternUI.Components.DatePicker do
  @moduledoc """
  Date/time pickers — Fluxon-compatible API composed from LanternUI primitives.

      <.date_picker field={@form[:due]} label="Due date" />
      <.date_time_picker field={@form[:starts_at]} precision={:millisecond} />
      <.time_picker name="alarm" value="08:45:00.000" />

  The trigger is a segmented, directly-editable `datetime_field` (keyboard-first:
  type straight into the segments); the calendar popover is for mouse users and
  APG-grid keyboard navigation. `time_picker` is segments-only (no popover) —
  a LanternUI extension Fluxon doesn't offer.

  ## Value contract

  The hidden input submits the canonical string (`YYYY-MM-DD`,
  `HH:MM:SS.mmm`, `YYYY-MM-DDTHH:MM:SS.mmm`); empty = null. `value` accepts
  that string or a `Date` / `Time` / `NaiveDateTime` / `DateTime` struct.

  ## Fluxon compatibility

  Attrs mirror Fluxon's pickers: `field`/`name`/`value`, `label`, `sublabel`,
  `description`, `help_text`, `errors`, `size`, `disabled`, `min`/`max`,
  `week_start`, and the `inner/outer_prefix/suffix` slots. `display_format` /
  `time_format` are accepted for drop-in compatibility but not yet honored —
  v1 renders the fixed segmented US format (`m/d/yyyy, h:mm AM`).
  """

  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Calendar
  alias LanternUI.Components.DatetimeField
  alias LanternUI.Components.Form
  alias LanternUI.Components.Icon

  @doc "Date-only picker (`YYYY-MM-DD`)."
  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:disabled, :boolean, default: false)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:value, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:errors, :list, default: [])
  attr(:min, :string, default: nil)
  attr(:max, :string, default: nil)
  attr(:week_start, :integer, default: 0, values: 0..6)
  attr(:display_format, :string, default: nil, doc: "accepted for Fluxon compat; not yet honored")

  attr(:form, :string,
    default: nil,
    doc:
      "HTML form attribute forwarded to the hidden value input (for editors outside the form element)"
  )

  attr(:rest, :global)
  slot(:inner_prefix)
  slot(:outer_prefix)
  slot(:inner_suffix)
  slot(:outer_suffix)

  def date_picker(assigns), do: picker(assign(assigns, :mode, :date))

  @doc "Date + time picker (`YYYY-MM-DDTHH:MM:SS.mmm`)."
  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:disabled, :boolean, default: false)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:value, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:errors, :list, default: [])
  attr(:min, :string, default: nil)
  attr(:max, :string, default: nil)
  attr(:week_start, :integer, default: 0, values: 0..6)
  attr(:precision, :atom, default: :minute, values: [:minute, :second, :millisecond])
  attr(:display_format, :string, default: nil, doc: "accepted for Fluxon compat; not yet honored")
  attr(:time_format, :string, default: nil, doc: "accepted for Fluxon compat; not yet honored")

  attr(:form, :string,
    default: nil,
    doc:
      "HTML form attribute forwarded to the hidden value input (for editors outside the form element)"
  )

  attr(:rest, :global)
  slot(:inner_prefix)
  slot(:outer_prefix)
  slot(:inner_suffix)
  slot(:outer_suffix)

  def date_time_picker(assigns), do: picker(assign(assigns, :mode, :datetime))

  @doc "Time-only picker (`HH:MM:SS.mmm`, segments only — no popover)."
  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:disabled, :boolean, default: false)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:value, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:errors, :list, default: [])
  attr(:precision, :atom, default: :minute, values: [:minute, :second, :millisecond])

  attr(:form, :string,
    default: nil,
    doc:
      "HTML form attribute forwarded to the hidden value input (for editors outside the form element)"
  )

  attr(:rest, :global)
  slot(:inner_prefix)
  slot(:outer_prefix)
  slot(:inner_suffix)
  slot(:outer_suffix)

  def time_picker(assigns), do: picker(assign(assigns, :mode, :time))

  # ── Shared implementation ─────────────────────────────────────────────────

  defp picker(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> picker()
  end

  defp picker(assigns) do
    assigns =
      assigns
      |> assign(:canonical, canonical(assigns.value, assigns.mode))
      |> assign(:precision, Map.get(assigns, :precision, :minute))
      |> assign_new(:form, fn -> nil end)
      |> assign_new(:min, fn -> nil end)
      |> assign_new(:max, fn -> nil end)
      |> assign_new(:week_start, fn -> 0 end)
      |> assign(:invalid?, assigns.errors != [])

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div class="lui-input-row">
        <span :for={slot <- @outer_prefix} class="lui-outer-affix">{render_slot(slot)}</span>

        <div
          id={"#{@id}-picker"}
          class="lui-picker"
          phx-hook="LanternPicker"
          data-mode={@mode}
          data-invalid={@invalid? || nil}
        >
          <DatetimeField.datetime_field
            id={"#{@id}-fieldset"}
            name={@name}
            form={@form}
            mode={@mode}
            precision={@precision}
            value={@canonical}
            disabled={@disabled}
            class="lui-picker-trigger"
            data-part="trigger"
            aria-describedby={@invalid? && "#{@id}-error"}
            {@rest}
          >
            <:suffix>
              <span :for={slot <- @inner_prefix} class="lui-inner-affix">{render_slot(slot)}</span>
              <button
                :if={@mode != :time}
                type="button"
                class="lui-picker-toggle"
                data-part="toggle"
                disabled={@disabled}
                aria-haspopup="dialog"
                aria-expanded="false"
                aria-label="Open calendar"
              >
                <Icon.icon name="calendar-days" />
              </button>
              <span :for={slot <- @inner_suffix} class="lui-inner-affix">{render_slot(slot)}</span>
            </:suffix>
          </DatetimeField.datetime_field>

          <div
            :if={@mode != :time}
            data-part="panel"
            hidden
            role="dialog"
            aria-label={if @mode == :datetime, do: "Choose date and time", else: "Choose date"}
            class="lui-picker-panel"
          >
            <Calendar.calendar
              id={"#{@id}-calendar"}
              selected={selected_date(@canonical, @mode)}
              week_start={@week_start}
              min={@min}
              max={@max}
              class="lui-picker-cal"
            />
            <%!-- Time pane: an unnamed (non-submitting) time field the picker
                 hook keeps in two-way sync with the trigger's time segments. --%>
            <div :if={@mode == :datetime} class="lui-picker-time">
              <span class="lui-picker-time-label">Time</span>
              <DatetimeField.datetime_field
                id={"#{@id}-panel-time"}
                mode={:time}
                precision={@precision}
                value={panel_time(@canonical)}
                aria-label="Time"
                data-part="panel-time"
                class="lui-picker-time-field"
              />
            </div>
            <div class="lui-picker-foot">
              <button
                type="button"
                class="lui-btn"
                data-variant="ghost"
                data-color="primary"
                data-size="sm"
                data-part="today"
              >
                {if @mode == :datetime, do: "Now", else: "Today"}
              </button>
              <button
                type="button"
                class="lui-btn"
                data-variant="ghost"
                data-color="primary"
                data-size="sm"
                data-part="clear-panel"
              >
                Clear
              </button>
              <span class="lui-picker-foot-space"></span>
              <button
                type="button"
                class="lui-btn"
                data-variant="solid"
                data-color="primary"
                data-size="sm"
                data-part="done"
              >
                Done
              </button>
            </div>
          </div>
        </div>

        <span :for={slot <- @outer_suffix} class="lui-outer-affix">{render_slot(slot)}</span>
      </div>

      <p :if={@help_text && !@invalid?} class="lui-help">{@help_text}</p>
      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end

  # The time slice of a canonical datetime, for seeding the panel's time pane.
  defp panel_time(nil), do: nil

  defp panel_time(canonical) do
    case String.split(canonical, "T") do
      [_date, time] -> time
      _ -> nil
    end
  end

  # ── Value normalization ───────────────────────────────────────────────────

  @doc false
  def canonical(nil, _mode), do: nil
  def canonical("", _mode), do: nil

  def canonical(%Date{} = d, :date), do: Date.to_iso8601(d)
  def canonical(%Date{} = d, :datetime), do: Date.to_iso8601(d) <> "T00:00:00.000"

  def canonical(%Time{} = t, :time), do: fmt_time(t)

  def canonical(%NaiveDateTime{} = ndt, :datetime),
    do: Date.to_iso8601(NaiveDateTime.to_date(ndt)) <> "T" <> fmt_time(NaiveDateTime.to_time(ndt))

  def canonical(%NaiveDateTime{} = ndt, :date), do: Date.to_iso8601(NaiveDateTime.to_date(ndt))
  def canonical(%NaiveDateTime{} = ndt, :time), do: fmt_time(NaiveDateTime.to_time(ndt))

  def canonical(%DateTime{} = dt, mode), do: canonical(DateTime.to_naive(dt), mode)

  def canonical(value, _mode) when is_binary(value), do: value

  defp fmt_time(%Time{} = t) do
    {us, _} = t.microsecond
    ms = div(us, 1000)

    :io_lib.format("~2..0B:~2..0B:~2..0B.~3..0B", [t.hour, t.minute, t.second, ms])
    |> IO.iodata_to_binary()
  end

  defp selected_date(nil, _mode), do: nil

  defp selected_date(canonical, :date) do
    case Date.from_iso8601(canonical) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp selected_date(canonical, :datetime) do
    canonical |> String.split("T") |> hd() |> selected_date(:date)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
