defmodule LanternUI.Components.DateRangePopover do
  @moduledoc """
  Anchored popover for date-range selection with standard presets and comparison toggling.

  Follows a server-owned state contract (similar to `chart_settings/1`).
  When any preset or date input changes, the enclosed form emits a `phx-change`
  event with a structured params map:

      %{
        "date_range" => %{
          "preset" => "7D",
          "start_date" => "2026-10-02",
          "end_date" => "2026-10-09",
          "compare_previous" => "false"
        }
      }

  ## Presets
  Standard presets supported:
  - `"7D"`: Last 7 days
  - `"30D"`: Last 30 days
  - `"90D"`: Last 90 days
  - `"MTD"`: Month to date
  - `"QTD"`: Quarter to date
  - `"YTD"`: Year to date
  - `"custom"`: Custom range (from/to inputs)

  ## Examples

      <.date_range_popover
        id="dashboard-range"
        preset={@date_range["preset"]}
        start_date={@date_range["start_date"]}
        end_date={@date_range["end_date"]}
        compare_previous={@date_range["compare_previous"]}
        phx-change="date_range_changed"
      />
  """

  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Popover

  @standard_presets ~w(7D 30D 90D MTD QTD YTD custom)

  attr(:id, :string, required: true, doc: "Stable popover DOM id.")

  attr(:preset, :string,
    default: "30D",
    doc: "Active preset code; one of 7D, 30D, 90D, MTD, QTD, YTD, or custom."
  )

  attr(:start_date, :any,
    default: nil,
    doc: "Current start date (ISO string or Date struct)."
  )

  attr(:end_date, :any,
    default: nil,
    doc: "Current end date (ISO string or Date struct)."
  )

  attr(:today, :any,
    default: nil,
    doc:
      "Date or DateTime used as the current day for preset ranges; defaults to the selected time zone's date."
  )

  attr(:time_zone, :string,
    default: "Etc/UTC",
    doc: "Time zone used to determine today's date when `today` is not supplied."
  )

  attr(:min, :any, default: nil, doc: "Optional earliest selectable date.")
  attr(:max, :any, default: nil, doc: "Optional latest selectable date.")

  attr(:compare_previous, :boolean,
    default: false,
    doc: "Whether comparison with previous period is checked."
  )

  attr(:show_compare, :boolean,
    default: true,
    doc: "Whether to render the comparison toggle checkbox."
  )

  attr(:compare_label, :string,
    default: "Compare with previous period",
    doc: "Label for the comparison checkbox."
  )

  attr(:presets, :list,
    default: @standard_presets,
    doc: "List of preset codes offered."
  )

  attr(:placement, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "Popover anchor placement."
  )

  attr(:name_prefix, :string,
    default: "date_range",
    doc: "Form parameter namespace."
  )

  attr(:trigger_label, :string,
    default: nil,
    doc: "Optional custom label on the trigger button; auto-generated when omitted."
  )

  attr(:error, :string,
    default: nil,
    doc: "Optional validation error message to display in the panel."
  )

  attr(:disabled, :boolean,
    default: false,
    doc: "Whether the control is disabled."
  )

  attr(:editable_dates, :boolean,
    default: true,
    doc: "Whether date inputs are editable even when a non-custom preset is selected."
  )

  attr(:apply_button, :boolean,
    default: false,
    doc: "Whether to render an explicit Apply submit button."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the popover panel.")

  attr(:rest, :global,
    include: ~w(phx-change phx-submit phx-target),
    doc: "Global form event attributes."
  )

  slot(:trigger, doc: "Optional custom trigger element.")

  @doc "Renders a date range popover with presets and comparison toggling."
  def date_range_popover(assigns) do
    norm_preset = normalize_preset(assigns.preset)
    presets = Enum.map(assigns.presets, &normalize_preset/1)

    today =
      if norm_preset in ~w(7D 30D 90D MTD QTD YTD) do
        resolve_today(assigns.today, assigns.time_zone)
      end

    {start_val, end_val} =
      resolve_dates(norm_preset, assigns.start_date, assigns.end_date, today)

    display_label =
      assigns.trigger_label || format_range_label(norm_preset, start_val, end_val)

    assigns =
      assigns
      |> assign(:active_preset, norm_preset)
      |> assign(:presets, presets)
      |> assign(:start_date_val, start_val)
      |> assign(:end_date_val, end_val)
      |> assign(:min_val, iso_date(assigns.min))
      |> assign(:max_val, iso_date(assigns.max))
      |> assign(:display_label, display_label)

    ~H"""
    <Popover.popover
      id={@id}
      placement={@placement}
      modal
      class={Class.merge(["lui-date-range-popover__panel", @class])}
    >
      <%= if @trigger != [] do %>
        {render_slot(@trigger)}
      <% else %>
        <button
          type="button"
          id={"#{@id}-trigger"}
          class="lui-date-range-popover__trigger"
          disabled={@disabled}
          aria-haspopup="dialog"
        >
          <svg
            class="lui-icon lui-date-range-popover__calendar-icon"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.75"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
            <line x1="16" y1="2" x2="16" y2="6" />
            <line x1="8" y1="2" x2="8" y2="6" />
            <line x1="3" y1="10" x2="21" y2="10" />
          </svg>
          <span class="lui-date-range-popover__trigger-text">{@display_label}</span>
          <svg
            class="lui-icon lui-date-range-popover__chevron"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <polyline points="6 9 12 15 18 9" />
          </svg>
        </button>
      <% end %>

      <:content>
        <form
          id={"#{@id}-form"}
          class="lui-date-range-popover__form"
          {@rest}
        >
          <div
            :if={@presets != []}
            class="lui-date-range-popover__presets"
            role="radiogroup"
            aria-label="Date range presets"
          >
            <label
              :for={p <- @presets}
              class={[
                "lui-date-range-popover__preset-pill",
                @active_preset == p && "is-active"
              ]}
            >
              <input
                type="radio"
                name={"#{@name_prefix}[preset]"}
                value={p}
                checked={@active_preset == p}
                disabled={@disabled}
                class="lui-sr-only"
              />
              <span>{preset_display_name(p)}</span>
            </label>
          </div>

          <div class="lui-date-range-popover__custom-section">
            <div class="lui-date-range-popover__inputs">
              <label class="lui-date-range-popover__field">
                <span class="lui-date-range-popover__label">Start</span>
                <input
                  type="date"
                  name={"#{@name_prefix}[start_date]"}
                  value={@start_date_val}
                  min={@min_val}
                  max={@max_val}
                  disabled={@disabled or (@active_preset != "custom" and not @editable_dates)}
                  class="lui-date-range-popover__input"
                  aria-invalid={if @error, do: "true"}
                />
              </label>
              <span class="lui-date-range-popover__sep" aria-hidden="true">to</span>
              <label class="lui-date-range-popover__field">
                <span class="lui-date-range-popover__label">End</span>
                <input
                  type="date"
                  name={"#{@name_prefix}[end_date]"}
                  value={@end_date_val}
                  min={@min_val}
                  max={@max_val}
                  disabled={@disabled or (@active_preset != "custom" and not @editable_dates)}
                  class="lui-date-range-popover__input"
                  aria-invalid={if @error, do: "true"}
                />
              </label>
            </div>
          </div>

          <label :if={@show_compare} class="lui-date-range-popover__compare">
            <input type="hidden" name={"#{@name_prefix}[compare_previous]"} value="false" />
            <input
              type="checkbox"
              name={"#{@name_prefix}[compare_previous]"}
              value="true"
              checked={@compare_previous}
              disabled={@disabled}
            />
            <span>{@compare_label}</span>
          </label>

          <div :if={@error} class="lui-date-range-popover__error" role="alert">
            <svg
              class="lui-icon"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              aria-hidden="true"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            <span>{@error}</span>
          </div>

          <div :if={@apply_button} class="lui-date-range-popover__actions">
            <button
              type="submit"
              class="lui-date-range-popover__apply-btn"
              disabled={@disabled or @error != nil}
            >
              Apply
            </button>
          </div>
        </form>
      </:content>
    </Popover.popover>
    """
  end

  @doc """
  Normalizes preset inputs (atoms, upper/lowercase strings) into standard canonical codes.
  """
  def normalize_preset(nil), do: "30D"

  def normalize_preset(preset) do
    case to_string(preset) |> String.trim() |> String.upcase() do
      "7D" -> "7D"
      "SEVEN_DAYS" -> "7D"
      "30D" -> "30D"
      "THIRTY_DAYS" -> "30D"
      "90D" -> "90D"
      "NINETY_DAYS" -> "90D"
      "MTD" -> "MTD"
      "QTD" -> "QTD"
      "YTD" -> "YTD"
      "CUSTOM" -> "custom"
      other -> String.downcase(other)
    end
  end

  @doc """
  Returns a user-facing label for a preset code.
  """
  def preset_display_name(preset) do
    case normalize_preset(preset) do
      "7D" -> "7D"
      "30D" -> "30D"
      "90D" -> "90D"
      "MTD" -> "MTD"
      "QTD" -> "QTD"
      "YTD" -> "YTD"
      "custom" -> "Custom"
      other -> other
    end
  end

  @doc """
  Computes the `{start_date, end_date}` Date structs for a standard preset relative
  to `today` (defaults to `Date.utc_today()`), or returns `nil` for `"custom"`.
  """
  def preset_range(preset, today \\ Date.utc_today()) do
    case normalize_preset(preset) do
      "7D" ->
        %{start_date: Date.add(today, -6), end_date: today}

      "30D" ->
        %{start_date: Date.add(today, -29), end_date: today}

      "90D" ->
        %{start_date: Date.add(today, -89), end_date: today}

      "MTD" ->
        %{start_date: Date.new!(today.year, today.month, 1), end_date: today}

      "QTD" ->
        q_month = div(today.month - 1, 3) * 3 + 1
        %{start_date: Date.new!(today.year, q_month, 1), end_date: today}

      "YTD" ->
        %{start_date: Date.new!(today.year, 1, 1), end_date: today}

      _ ->
        nil
    end
  end

  @doc """
  Computes the immediately preceding date range of identical duration.
  For example, for a 7-day range from 2026-10-03 to 2026-10-09, returns
  `%{start_date: ~D[2026-09-26], end_date: ~D[2026-10-02]}`.
  """
  def comparison_range(start_date, end_date) do
    with {:ok, s} <- parse_date(start_date),
         {:ok, e} <- parse_date(end_date) do
      days = Date.diff(e, s) + 1
      prev_end = Date.add(s, -1)
      prev_start = Date.add(prev_end, -(days - 1))
      %{start_date: prev_start, end_date: prev_end}
    else
      _ -> nil
    end
  end

  @doc """
  Validates that `start_date` and `end_date` are parseable ISO dates, ordered chronologically,
  and within optional `:min` and `:max` bounds.
  """
  def validate_range(start_date, end_date, opts \\ []) do
    with {:ok, s} <- parse_date(start_date),
         {:ok, e} <- parse_date(end_date) do
      cond do
        Date.compare(s, e) == :gt ->
          {:error, "Start date cannot be after end date"}

        opts[:min] && Date.compare(s, parse_bound(opts[:min])) == :lt ->
          {:error, "Start date cannot be before #{opts[:min]}"}

        opts[:max] && Date.compare(e, parse_bound(opts[:max])) == :gt ->
          {:error, "End date cannot be after #{opts[:max]}"}

        true ->
          {:ok, %{start_date: s, end_date: e}}
      end
    else
      _ -> {:error, "Invalid date format"}
    end
  end

  @doc """
  Formats a concise trigger label for the date range.
  """
  def format_range_label(preset, start_date \\ nil, end_date \\ nil) do
    case normalize_preset(preset) do
      "7D" ->
        "Last 7 days"

      "30D" ->
        "Last 30 days"

      "90D" ->
        "Last 90 days"

      "MTD" ->
        "Month to date"

      "QTD" ->
        "Quarter to date"

      "YTD" ->
        "Year to date"

      "custom" ->
        s = iso_date(start_date)
        e = iso_date(end_date)

        if s && e do
          "#{s} – #{e}"
        else
          "Custom range"
        end

      other ->
        other
    end
  end

  @doc """
  Parses an ISO date string or Date struct into `{:ok, Date.t()}` or `{:error, :invalid}`.
  """
  def parse_date(nil), do: {:error, nil}
  def parse_date(%Date{} = d), do: {:ok, d}

  def parse_date(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, d} -> {:ok, d}
      _ -> {:error, :invalid}
    end
  end

  def parse_date(_), do: {:error, :invalid}

  defp parse_bound(%Date{} = d), do: d

  defp parse_bound(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, d} -> d
      _ -> ~D[1970-01-01]
    end
  end

  defp parse_bound(_), do: ~D[1970-01-01]

  defp resolve_dates(preset, start_d, end_d, today) do
    cond do
      preset in ~w(7D 30D 90D MTD QTD YTD) ->
        range = preset_range(preset, today)
        {iso_date(range.start_date), iso_date(range.end_date)}

      true ->
        {iso_date(start_d), iso_date(end_d)}
    end
  end

  defp resolve_today(%Date{} = today, _time_zone), do: today
  defp resolve_today(%DateTime{} = today, _time_zone), do: DateTime.to_date(today)

  defp resolve_today(today, _time_zone) when is_binary(today) do
    case Date.from_iso8601(today) do
      {:ok, date} -> date
      _ -> raise ArgumentError, "today must be a Date, DateTime, or ISO-8601 date string"
    end
  end

  defp resolve_today(nil, time_zone), do: DateTime.now!(time_zone) |> DateTime.to_date()

  defp iso_date(nil), do: nil
  defp iso_date(%Date{} = d), do: Date.to_iso8601(d)
  defp iso_date(str) when is_binary(str), do: str
  defp iso_date(other), do: to_string(other)
end
