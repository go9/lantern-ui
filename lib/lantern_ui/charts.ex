defmodule LanternUI.Charts do
  @moduledoc """
  Native LiveView chart components — server-rendered SVG, minimal JS.

  Geometry (scales, ticks, paths) is computed in Elixir by
  `LanternUI.Charts.Geometry` and rendered as SVG, so charts re-render through
  normal LiveView assigns. Client JavaScript is limited to the optional
  `ChartHover` hook for `area_chart/1` and `ChartInteraction` for the generic
  time-series chart; both update only server-rendered overlay elements.

  ## Theming

  Colors come from CSS variables with chained fallbacks, so components match a host
  design system (e.g. Fluxon) automatically and still render standalone:

      accent   var(--lantern-accent,  var(--color-primary-500, #3b82f6))
      text     var(--lantern-fg,      var(--foreground,        #111827))
      muted    var(--lantern-fg-muted,var(--foreground-softer, #6b7280))
      surface  var(--lantern-surface, var(--background-base,   #ffffff))

  ## Value formatting

  `area_chart/1` and `bar_chart/1` accept `value_format`: `:number` (default),
  `:currency`, or a 1-arity function `(number -> String.t())`.
  """
  use Phoenix.Component

  alias LanternUI.Charts.Geometry
  alias LanternUI.Class

  @vb_w 700
  @margin %{top: 12, right: 14, bottom: 26, left: 46}
  @smooth_max 90

  @accent "var(--lantern-accent, var(--color-primary-500, #3b82f6))"
  @fg "var(--lantern-fg, var(--foreground, #111827))"
  @fg_muted "var(--lantern-fg-muted, var(--foreground-softer, #6b7280))"

  @doc """
  A time-series area + line chart.

  `series` is a list of maps like `%{date: "2024-01-15", value: 24.8}` (ISO-8601
  date string or `Date`, numeric value). Empty series render an empty state.

  Requires the `ChartHover` JS hook for the crosshair/tooltip (see module docs).
  """
  attr(:id, :string, required: true, doc: "Stable DOM id for the chart root and hover hook.")
  attr(:series, :list, default: [], doc: "Dated points: %{date: ISO|Date, value: number}.")
  attr(:height, :integer, default: 250, doc: "SVG viewBox height in CSS pixels.")
  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:value_format, :any,
    default: :number,
    doc: "`:number` | `:currency` | a 1-arity function `(number -> String.t())`"
  )

  attr(:empty_message, :string, default: "No data", doc: "Copy shown when series is empty.")
  attr(:aria_label, :string, default: "Area chart", doc: "Accessible name for the SVG.")

  attr(:smooth, :boolean,
    default: true,
    doc:
      "Curve the line between points. Set false for values counted per discrete " <>
        "bucket (per month, per build): a spline through them bulges into the " <>
        "empty periods either side and reads as activity that never happened."
  )

  def area_chart(assigns) do
    assigns =
      assigns.series
      |> normalize_dated()
      |> area_geometry(assigns.height, assigns.value_format, assigns.smooth)
      |> then(&assign(assigns, &1))

    ~H"""
    <div id={@id} class={@class}>
      <div
        :if={@has_data}
        id={"#{@id}-hover"}
        phx-hook="ChartHover"
        data-points={@points_json}
        data-top={@plot_top}
        data-bottom={@plot_bottom}
      >
        <svg
          viewBox={"0 0 #{@vb_w} #{@height}"}
          role="img"
          aria-label={@aria_label}
          style={"display:block;width:100%;height:auto;font-family:inherit;color:#{@fg}"}
        >
          <g stroke="currentColor" stroke-opacity="0.08">
            <line :for={{_l, y} <- @y_ticks} x1={@plot_left} x2={@plot_right} y1={y} y2={y} />
          </g>
          <g fill="currentColor" fill-opacity="0.5" font-size="11">
            <text :for={{l, y} <- @y_ticks} x={@plot_left - 8} y={y + 3} text-anchor="end">{l}</text>
            <text :for={{l, x, anchor} <- @x_ticks} x={x} y={@height - 8} text-anchor={anchor}>
              {l}
            </text>
          </g>
          <g style={"color:#{@accent}"}>
            <defs>
              <linearGradient id={"#{@id}-grad"} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="currentColor" stop-opacity="0.25" />
                <stop offset="100%" stop-color="currentColor" stop-opacity="0" />
              </linearGradient>
            </defs>
            <path d={@area_d} fill={"url(##{@id}-grad)"} />
            <path
              d={@line_d}
              fill="none"
              stroke="currentColor"
              stroke-width="1.5"
              stroke-linejoin="round"
              stroke-linecap="round"
            />
          </g>
          <g class="lantern-hover" style={"opacity:0;color:#{@accent}"}></g>
        </svg>
      </div>
      <div
        :if={!@has_data}
        style={"display:flex;min-height:180px;align-items:center;justify-content:center;font-size:14px;color:#{@fg_muted}"}
      >
        {@empty_message}
      </div>
    </div>
    """
  end

  @doc """
  A compact trend sparkline (no axes).

  `series` is a list of numbers. Renders nothing when empty.
  """
  attr(:id, :string, required: true, doc: "Stable DOM id for the sparkline SVG.")
  attr(:series, :list, default: [], doc: "Numeric values plotted left-to-right.")
  attr(:height, :integer, default: 40, doc: "SVG viewBox height in CSS pixels.")

  attr(:color, :string,
    default: nil,
    doc: "Optional stroke and fill color; defaults to var(--lantern-chart-1)."
  )

  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:aria_label, :string, default: "Sparkline", doc: "Accessible name for the SVG.")

  def sparkline(assigns) do
    accent = assigns[:color] || @accent
    geom = spark_geometry(assigns.series, assigns.height) |> Map.put(:accent, accent)
    assigns = assign(assigns, geom)

    ~H"""
    <svg
      :if={@has_data}
      id={@id}
      class={@class}
      viewBox={"0 0 160 #{@height}"}
      role="img"
      aria-label={@aria_label}
      style={"display:block;width:100%;height:auto;color:#{@accent}"}
    >
      <defs>
        <linearGradient id={"#{@id}-grad"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="currentColor" stop-opacity="0.25" />
          <stop offset="100%" stop-color="currentColor" stop-opacity="0" />
        </linearGradient>
      </defs>
      <path d={@area_d} fill={"url(##{@id}-grad)"} />
      <path d={@line_d} fill="none" stroke="currentColor" stroke-width="1.75" stroke-linejoin="round" />
      <circle cx={@end_x} cy={@end_y} r="2.6" fill="currentColor" />
    </svg>
    """
  end

  @doc """
  A categorical bar chart.

  `series` is a list of maps like `%{label: "Q1", value: 42}`. Empty series render
  an empty state.

  A category may carry an `:href`, which makes that bar a link:

      <.bar_chart id="stages" series={[
        %{label: "Open", value: 12, href: "/orders?status=open"},
        %{label: "Shipped", value: 40, href: "/orders?status=shipped"}
      ]} />

  A linked bar navigates through LiveView and is reachable by keyboard. Its hit
  area is the whole column rather than the drawn bar, so a category sitting at
  zero — the one a reader is most likely to want to check — can still be
  clicked. Categories without an `:href` are drawn exactly as before.
  """
  attr(:id, :string, required: true, doc: "Stable DOM id for the chart root.")

  attr(:series, :list,
    default: [],
    doc: "Categories: %{label: String.t(), value: number, href: String.t() | nil}."
  )

  attr(:height, :integer, default: 180, doc: "SVG viewBox height in CSS pixels.")
  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:value_format, :any,
    default: :number,
    doc: "`:number` | `:currency` | a 1-arity function `(number -> String.t())`"
  )

  attr(:empty_message, :string, default: "No data", doc: "Copy shown when series is empty.")
  attr(:aria_label, :string, default: "Bar chart", doc: "Accessible name for the SVG.")

  def bar_chart(assigns) do
    assigns = assign(assigns, bar_geometry(assigns.series, assigns.height, assigns.value_format))

    ~H"""
    <div id={@id} class={@class}>
      <svg
        :if={@has_data}
        viewBox={"0 0 #{@vb_w} #{@height}"}
        role="img"
        aria-label={@aria_label}
        style={"display:block;width:100%;height:auto;font-family:inherit;color:#{@fg}"}
      >
        <g>
          <%= for b <- @bars do %>
            <.link
              :if={b.href}
              navigate={b.href}
              class="lui-bar-link"
              aria-label={"#{b.label}: #{b.value}"}
            >
              <rect x={b.band_x} y={@plot_top} width={b.band_w} height={b.band_h} fill="transparent" />
              <rect x={b.x} y={b.y} width={b.w} height={b.h} rx="4" fill={@accent} opacity="0.9" />
            </.link>
            <rect
              :if={!b.href}
              x={b.x}
              y={b.y}
              width={b.w}
              height={b.h}
              rx="4"
              fill={@accent}
              opacity="0.9"
            />
          <% end %>
        </g>
        <%!-- The labels sit over the bars, and a glyph is a click target of its
              own, so a click that landed on the "12" would miss the link under
              it. They are decoration either way. --%>
        <g
          fill="currentColor"
          fill-opacity="0.6"
          font-size="11.5"
          text-anchor="middle"
          pointer-events="none"
        >
          <text :for={b <- @bars} x={b.cx} y={b.y - 6} font-weight="500">{b.value}</text>
        </g>
        <g
          fill="currentColor"
          fill-opacity="0.45"
          font-size="11"
          text-anchor="middle"
          pointer-events="none"
        >
          <text :for={b <- @bars} x={b.cx} y={@baseline + 16}>{b.label}</text>
        </g>
        <line
          x1={@plot_left}
          x2={@plot_right}
          y1={@baseline}
          y2={@baseline}
          stroke="currentColor"
          stroke-opacity="0.15"
        />
      </svg>
      <div
        :if={!@has_data}
        style={"display:flex;min-height:120px;align-items:center;justify-content:center;font-size:14px;color:#{@fg_muted}"}
      >
        {@empty_message}
      </div>
    </div>
    """
  end

  # ── geometry assembly ───────────────────────────────────────────────────────

  defp area_geometry([], _height, _fmt, _smooth), do: %{has_data: false, fg_muted: @fg_muted}

  defp area_geometry(points, height, fmt, smooth) do
    plot_left = @margin.left
    plot_right = @vb_w - @margin.right
    plot_top = @margin.top
    plot_bottom = height - @margin.bottom

    {d0, _} = hd(points)
    {dn, _} = List.last(points)
    span = Date.diff(dn, d0)
    xf = fn d -> Geometry.scale(0, span, plot_left, plot_right, Date.diff(d, d0)) end

    values = Enum.map(points, fn {_d, v} -> v end)
    {vmin, vmax} = Enum.min_max(values)
    # An area is read as an amount measured up from its baseline, so the
    # baseline is zero unless the data goes below it; whole-number series (counts)
    # get whole-number ticks.
    ticks =
      Geometry.nice_ticks(min(vmin, 0), vmax, 5, integer: Enum.all?(values, &is_integer/1))

    ymin = hd(ticks)
    ymax = List.last(ticks)
    yf = fn v -> Geometry.scale(ymin, ymax, plot_bottom, plot_top, v) end

    px = Enum.map(points, fn {d, v} -> {xf.(d), yf.(v)} end)
    smooth? = smooth and length(px) <= @smooth_max

    y_ticks = Enum.map(ticks, fn t -> {format_value(t, fmt), Geometry.round1(yf.(t))} end)

    count = length(points)
    label_fun = if span <= 95, do: &short_label/1, else: &long_label/1

    x_ticks =
      0..4
      |> Enum.map(&round(&1 / 4 * (count - 1)))
      |> Enum.uniq()
      |> Enum.map(fn i ->
        {d, _} = Enum.at(points, i)
        {label_fun.(d), Geometry.round1(xf.(d)), tick_anchor(i, count)}
      end)

    points_json =
      points
      |> Enum.map(fn {d, v} ->
        %{
          x: Geometry.round1(xf.(d)),
          y: Geometry.round1(yf.(v)),
          p: format_value(v, fmt),
          d: full_label(d)
        }
      end)
      |> Jason.encode!()

    %{
      has_data: true,
      vb_w: @vb_w,
      plot_left: plot_left,
      plot_right: plot_right,
      plot_top: plot_top,
      plot_bottom: plot_bottom,
      line_d: Geometry.line_path(px, smooth?),
      area_d: Geometry.area_path(px, plot_bottom, smooth?),
      y_ticks: y_ticks,
      x_ticks: x_ticks,
      points_json: points_json,
      accent: @accent,
      fg: @fg,
      fg_muted: @fg_muted
    }
  end

  # The first and last labels sit on the plot edges, so centring them pushes half
  # the text outside the viewBox and the browser clips it ("Sep '2"). Anchor the
  # end ticks inward instead.
  defp tick_anchor(0, _count), do: "start"
  defp tick_anchor(i, count) when i == count - 1, do: "end"
  defp tick_anchor(_i, _count), do: "middle"

  defp spark_geometry(series, height) do
    nums = Enum.filter(series, &is_number/1)

    case nums do
      [] ->
        %{has_data: false, accent: @accent}

      _ ->
        w = 160
        pad = 5
        n = length(nums)
        {mn, mx} = Enum.min_max(nums)
        xf = fn i -> Geometry.scale(0, max(n - 1, 1), pad, w - pad, i) end
        yf = fn v -> Geometry.scale(mn, mx, height - pad, pad, v) end
        px = nums |> Enum.with_index() |> Enum.map(fn {v, i} -> {xf.(i), yf.(v)} end)
        smooth? = n <= @smooth_max
        {ex, ey} = List.last(px)

        %{
          has_data: true,
          line_d: Geometry.line_path(px, smooth?),
          area_d: Geometry.area_path(px, height - pad, smooth?),
          end_x: Geometry.round1(ex),
          end_y: Geometry.round1(ey),
          accent: @accent
        }
    end
  end

  defp bar_geometry(series, height, fmt) do
    items =
      series
      |> Enum.map(fn item -> {bar_label(item), bar_value(item), bar_href(item)} end)
      |> Enum.reject(fn {_l, v, _h} -> is_nil(v) end)

    case items do
      [] ->
        %{has_data: false, accent: @accent, fg_muted: @fg_muted}

      _ ->
        m = %{top: 18, right: 8, bottom: 24, left: 8}
        inner_w = @vb_w - m.left - m.right
        inner_h = height - m.top - m.bottom
        raw_max = items |> Enum.map(&elem(&1, 1)) |> Enum.max()
        maxv = if raw_max <= 0, do: 1.0, else: raw_max * 1.1
        n = length(items)
        band = inner_w / n
        barw = band * 0.56
        baseline = m.top + inner_h

        bars =
          items
          |> Enum.with_index()
          |> Enum.map(fn {{label, v, href}, i} ->
            bh = v / maxv * inner_h
            bx = m.left + i * band + (band - barw) / 2

            %{
              x: Geometry.round1(bx),
              y: Geometry.round1(baseline - bh),
              w: Geometry.round1(barw),
              h: Geometry.round1(bh),
              cx: Geometry.round1(bx + barw / 2),
              # The whole column, for a link's hit area: a bar at zero has no
              # height to click.
              band_x: Geometry.round1(m.left + i * band),
              band_w: Geometry.round1(band),
              band_h: Geometry.round1(inner_h),
              href: href,
              label: label,
              value: format_value(v, fmt)
            }
          end)

        %{
          has_data: true,
          vb_w: @vb_w,
          baseline: Geometry.round1(baseline),
          plot_top: m.top,
          plot_left: m.left,
          plot_right: @vb_w - m.right,
          bars: bars,
          accent: @accent,
          fg: @fg,
          fg_muted: @fg_muted
        }
    end
  end

  # ── parsing & formatting ────────────────────────────────────────────────────

  defp normalize_dated(series) do
    series
    |> Enum.map(fn item -> {parse_date(item), parse_number(item)} end)
    |> Enum.reject(fn {d, v} -> is_nil(d) or is_nil(v) end)
    |> Enum.sort_by(fn {d, _} -> d end, Date)
  end

  defp parse_date(%{date: d}), do: to_date(d)
  defp parse_date(%{"date" => d}), do: to_date(d)
  defp parse_date(_), do: nil

  defp to_date(%Date{} = d), do: d

  defp to_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp to_date(_), do: nil

  defp parse_number(%{value: v}) when is_number(v), do: v
  defp parse_number(%{"value" => v}) when is_number(v), do: v
  defp parse_number(_), do: nil

  defp bar_value(%{value: v}) when is_number(v), do: v
  defp bar_value(%{"value" => v}) when is_number(v), do: v
  defp bar_value(_), do: nil

  defp bar_href(%{href: h}) when is_binary(h), do: h
  defp bar_href(%{"href" => h}) when is_binary(h), do: h
  defp bar_href(_), do: nil

  defp bar_label(%{label: l}), do: to_string(l)
  defp bar_label(%{"label" => l}), do: to_string(l)
  defp bar_label(_), do: ""

  defp format_value(v, :currency), do: "$" <> :erlang.float_to_binary(v * 1.0, decimals: 2)
  defp format_value(v, fun) when is_function(fun, 1), do: fun.(v)
  defp format_value(v, _), do: number_label(v)

  defp number_label(v) do
    f = v * 1.0

    if Float.round(f) == f and abs(f) < 1.0e9 do
      f |> trunc() |> Integer.to_string()
    else
      :erlang.float_to_binary(f, decimals: 2)
    end
  end

  defp short_label(d), do: "#{month(d)} #{d.day}"
  defp long_label(d), do: "#{month(d)} '#{d.year |> rem(100) |> pad2()}"
  defp full_label(d), do: "#{month(d)} #{d.day}, #{d.year}"
  defp month(d), do: Calendar.strftime(d, "%b")
  defp pad2(n) when n < 10, do: "0#{n}"
  defp pad2(n), do: "#{n}"

  # ── line chart (multi-series) ───────────────────────────────────────────────

  @line_palette ~w(#3b82f6 #16a34a #f59e0b #dc2626 #8b5cf6 #0891b2 #db2777 #65a30d)
  @series_color_regex ~r/\Avar\(--[a-zA-Z_][a-zA-Z0-9_-]*\)\z/
  @time_series_palette [
    "var(--lantern-chart-1, var(--lantern-accent, currentColor))",
    "var(--lantern-chart-2, var(--lantern-success, currentColor))",
    "var(--lantern-chart-3, var(--lantern-warning, currentColor))",
    "var(--lantern-chart-4, var(--lantern-danger, currentColor))",
    "var(--lantern-chart-5, var(--lantern-info, currentColor))",
    "var(--lantern-chart-6, var(--lantern-fg-muted, currentColor))"
  ]

  @doc """
  A multi-series time-series line chart with a legend and a shared crosshair tooltip.

  `series` is a list of maps:

      %{label: "web-1", color: "var(--color-primary)", points: [{~U[..], 0.25}, ...]}

  Each `points` entry is `{datetime, number}` or `%{time: datetime, value: number}`
  (datetime = `DateTime`, `NaiveDateTime`, `Date`, or ISO-8601 string). `color` is
  optional (a palette is used when absent). All series share a 0-based y axis.

  Requires the `LineHover` JS hook for the crosshair/tooltip.
  """
  attr(:id, :string, required: true, doc: "Stable DOM id for the chart root and hover hook.")
  attr(:series, :list, default: [], doc: "Named series maps with points and optional color.")
  attr(:height, :integer, default: 200, doc: "SVG viewBox height in CSS pixels.")
  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:value_format, :any,
    default: :number,
    doc: "`:number` | `:currency` | a 1-arity function `(number -> String.t())`"
  )

  attr(:legend, :boolean, default: true, doc: "Show the series color key under the chart.")
  attr(:empty_message, :string, default: "No data", doc: "Copy shown when series is empty.")
  attr(:aria_label, :string, default: "Line chart", doc: "Accessible name for the SVG.")

  def line_chart(assigns) do
    assigns = assign(assigns, line_geometry(assigns.series, assigns.height, assigns.value_format))

    ~H"""
    <div id={@id} class={@class}>
      <div
        :if={@has_data}
        id={"#{@id}-hover"}
        phx-hook="LineHover"
        data-series={@series_json}
        data-top={@plot_top}
        data-bottom={@plot_bottom}
      >
        <svg
          viewBox={"0 0 #{@vb_w} #{@height}"}
          role="img"
          aria-label={@aria_label}
          style={"display:block;width:100%;height:auto;font-family:inherit;color:#{@fg}"}
        >
          <g stroke="currentColor" stroke-opacity="0.08">
            <line :for={{_l, y} <- @y_ticks} x1={@plot_left} x2={@plot_right} y1={y} y2={y} />
          </g>
          <g fill="currentColor" fill-opacity="0.5" font-size="11">
            <text :for={{l, y} <- @y_ticks} x={@plot_left - 8} y={y + 3} text-anchor="end">{l}</text>
            <text :for={{l, x, anchor} <- @x_ticks} x={x} y={@height - 8} text-anchor={anchor}>
              {l}
            </text>
          </g>
          <g :for={s <- @lines} style={"color:#{s.color}"}>
            <path
              d={s.d}
              fill="none"
              stroke="currentColor"
              stroke-width="1.75"
              stroke-linejoin="round"
              stroke-linecap="round"
            />
          </g>
          <g class="lantern-hover"></g>
        </svg>
        <div
          :if={@legend}
          style="display:flex;flex-wrap:wrap;gap:6px 16px;margin-top:8px;padding:0 4px"
        >
          <span
            :for={s <- @lines}
            style={"display:inline-flex;align-items:center;gap:6px;font-size:12px;color:#{@fg_muted}"}
          >
            <span style={"width:10px;height:3px;border-radius:2px;background:#{s.color}"}></span>{s.label}
          </span>
        </div>
      </div>
      <div
        :if={!@has_data}
        style={"display:flex;min-height:140px;align-items:center;justify-content:center;font-size:14px;color:#{@fg_muted}"}
      >
        {@empty_message}
      </div>
    </div>
    """
  end

  @doc """
  Render a generic series-first chart using server-computed SVG geometry.

  A series is `%{id: stable_id, label: label, color: "var(--token)", points: [%{x: key, y: number}]}`.
  The x domain must be homogeneous: dates/date-times, numbers, or category strings.
  Missing x keys break line and area paths. Invalid points are ignored; duplicate
  series ids and duplicate x keys within a series retain their first occurrence.
  """
  attr(:id, :string, required: true, doc: "Stable chart id.")

  attr(:series, :list,
    default: [],
    doc: "Series maps with id, label, optional CSS token color and %{x, y} points."
  )

  attr(:height, :integer, default: 280, doc: "SVG viewBox height.")
  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:type, :atom,
    default: :line,
    values: [:line, :area, :points, :stacked_area, :bar, :stacked_bar, :grouped_bar],
    doc: "Series renderer: line, area, points, stacked area, or bar grouping mode."
  )

  attr(:curve, :atom,
    default: :linear,
    values: [:linear, :monotone, :step, :cardinal],
    doc: "Line interpolation: :linear, :monotone, :step or :cardinal."
  )

  attr(:visible_series, :list, default: nil, doc: "Visible series ids; nil shows all.")
  attr(:comparison, :list, default: [], doc: "Optional previous-period series set.")
  attr(:annotations, :list, default: [], doc: "Optional markers keyed by x.")

  attr(:select_event, :string,
    default: nil,
    doc: "Optional LiveView event pushed when an x value is selected."
  )

  attr(:hover_event, :string,
    default: nil,
    doc: "Optional debounced LiveView event pushed while hovering."
  )

  attr(:reference_lines, :list,
    default: [],
    doc: "Optional horizontal reference lines: %{label, value}."
  )

  attr(:orientation, :atom,
    default: :vertical,
    values: [:vertical, :horizontal],
    doc: "Bar orientation; applies to bar chart types."
  )

  attr(:glyphs, :boolean, default: false, doc: "Render a marker at each available point.")
  attr(:grid, :boolean, default: true, doc: "Show horizontal y-axis grid lines.")
  attr(:axes, :boolean, default: true, doc: "Show x and y labels.")

  attr(:empty_message, :string,
    default: "No data",
    doc: "Copy shown when no valid series remains."
  )

  attr(:aria_label, :string, default: "Time series chart", doc: "Accessible name for the SVG.")

  attr(:value_format, :any,
    default: :number,
    doc: "`:number`, `:currency`, or a 1-arity number formatter."
  )

  def time_series_chart(assigns) do
    assigns = assign(assigns, time_series_geometry(assigns))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-time-series-chart", @class])}
      data-chart-type={@chart_type}
      data-interaction={Jason.encode!(@interaction_points)}
      data-series-label={Jason.encode!(@interaction_labels)}
      data-series-id={if @interaction_enabled, do: Jason.encode!(@interaction_series_ids)}
      data-select-event={@select_event}
      data-hover-event={@hover_event}
      phx-hook="ChartInteraction"
    >
      <svg
        :if={@has_data}
        viewBox={"0 0 #{@vb_w} #{@height}"}
        role="group"
        aria-label={@aria_label}
        class="lui-time-series-chart__svg"
      >
        <g :if={@show_grid} class="lui-time-series-chart__grid" aria-hidden="true">
          <line :for={y <- @grid_y} x1={@plot_left} x2={@plot_right} y1={y} y2={y} />
          <line :for={x <- @grid_x} y1={@plot_top} y2={@plot_bottom} x1={x} x2={x} />
        </g>
        <line
          :if={@zero_y}
          class="lui-time-series-chart__zero"
          x1={@plot_left}
          x2={@plot_right}
          y1={@zero_y}
          y2={@zero_y}
        />
        <line
          :if={@zero_x}
          class="lui-time-series-chart__zero"
          x1={@zero_x}
          x2={@zero_x}
          y1={@plot_top}
          y2={@plot_bottom}
        />
        <g :if={@show_axes} class="lui-time-series-chart__labels">
          <text :for={{label, y} <- @y_ticks} x={@plot_left - 8} y={y + 3} text-anchor="end">
            {label}
          </text>
          <text :for={{label, x, anchor} <- @x_ticks} x={x} y={@height - 8} text-anchor={anchor}>
            {label}
          </text>
        </g>
        <g :for={path <- @paths} class={path.class} style={"--lui-series-color:#{path.color}"}>
          <path :if={path.fill != ""} d={path.fill} class="lui-time-series-chart__area" />
          <path
            :if={path.line != ""}
            d={path.line}
            class="lui-time-series-chart__line"
            stroke-dasharray={
              cond do
                path.class == "lui-time-series-chart__comparison" -> "4 4"
                String.ends_with?(path.class, "__gain-negative") -> "4 2"
                true -> nil
              end
            }
          />
          <circle
            :for={{x, y} <- path.points}
            class="lui-time-series-chart__point"
            cx={x}
            cy={y}
            r="3"
          />
          <rect
            :for={bar <- path.bars}
            class="lui-time-series-chart__bar"
            x={bar.x}
            y={bar.y}
            width={bar.width}
            height={bar.height}
            rx="2"
          />
        </g>
        <g :for={reference <- @reference_lines} class="lui-time-series-chart__reference">
          <line
            :if={!reference.vertical}
            x1={@plot_left}
            x2={@plot_right}
            y1={reference.position}
            y2={reference.position}
          />
          <line
            :if={reference.vertical}
            x1={reference.position}
            x2={reference.position}
            y1={@plot_top}
            y2={@plot_bottom}
          />
          <text
            x={if(reference.vertical, do: reference.position + 4, else: @plot_left + 4)}
            y={if(reference.vertical, do: @plot_top + 12, else: reference.position - 4)}
          >
            {reference.label}: {reference.value_label}
          </text>
        </g>
        <g :for={marker <- @markers} class={"lui-time-series-chart__annotation tone-#{marker.tone}"}>
          <line :if={!marker.horizontal} x1={marker.x} x2={marker.x} y1={@plot_top} y2={@plot_bottom} />
          <line :if={marker.horizontal} x1={@plot_left} x2={@plot_right} y1={marker.y} y2={marker.y} />
          <text
            x={if(marker.horizontal, do: @plot_left + 4, else: marker.x + 4)}
            y={if(marker.horizontal, do: marker.y - 4, else: @plot_top + 12)}
          >
            {marker.label}
          </text>
        </g>
        <g class="lui-time-series-chart__interaction" aria-hidden="true" hidden>
          <line
            data-part="crosshair"
            x1={@plot_left}
            x2={@plot_left}
            y1={@plot_top}
            y2={@plot_bottom}
          />
          <circle
            :for={{_label, index} <- Enum.with_index(@interaction_labels)}
            data-part="series-point"
            data-series-index={index}
            style={"--lui-series-color:#{Enum.at(@interaction_colors, index)}"}
          />
          <g
            data-part="tooltip"
            data-base-x={@plot_left + 8}
            data-base-y={@plot_top + 8}
            data-plot-left={@plot_left + 4}
            data-plot-right={@plot_right - 4}
            data-plot-top={@plot_top + 4}
            data-plot-bottom={@plot_bottom - 4}
            data-tooltip-width="196"
            data-tooltip-height={28 + 17 * @interaction_series_count}
          >
            <rect
              x={@plot_left + 8}
              y={@plot_top + 8}
              width="196"
              height={28 + 17 * @interaction_series_count}
              rx="6"
            />
            <text data-part="tooltip-date" x={@plot_left + 18} y={@plot_top + 26}></text>
            <text
              :for={{_label, index} <- Enum.with_index(@interaction_labels)}
              data-part="tooltip-row"
              data-series-index={index}
              x={@plot_left + 18}
              y={@plot_top + 44 + 17 * index}
            >
            </text>
          </g>
        </g>
        <circle
          :for={{point, index} <- Enum.with_index(@interaction_points)}
          class="lui-time-series-chart__focus-point"
          data-chart-point={index}
          id={"#{@id}-point-#{index}"}
          cx={point.x}
          cy={Enum.find(point.coords, &(!is_nil(&1))) || @plot_bottom}
          r="8"
          tabindex={if(index == 0, do: "0", else: "-1")}
          aria-label={interaction_aria_label(point, @interaction_labels)}
          role="button"
        />
      </svg>
      <div :if={!@has_data} class="lui-time-series-chart__empty">{@empty_message}</div>
      <div :if={@legend != []} class="lui-time-series-chart__legend" aria-label="Series">
        <span :for={item <- @legend} class="lui-time-series-chart__legend-item">
          <i style={"--lui-series-color:#{item.color}"} aria-hidden="true"></i>{item.label}
        </span>
      </div>
      <details :if={@has_data} class="lui-time-series-chart__table-details">
        <summary>View chart data</summary>
        <table>
          <caption>{@aria_label} data table</caption>
          <thead>
            <tr>
              <th scope="col">Date / category</th><th :for={label <- @interaction_labels} scope="col">
                {label}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr :for={point <- @interaction_points}>
              <th scope="row">{point.label}</th>
              <td :for={value <- point.values}>{value || "—"}</td>
            </tr>
          </tbody>
          <tfoot :if={@reference_lines != []}>
            <tr :for={reference <- @reference_lines}>
              <th scope="row">{reference.label}</th>
              <td colspan={max(length(@interaction_labels), 1)}>{reference.value_label}</td>
            </tr>
          </tfoot>
        </table>
      </details>
      <span class="lui-time-series-chart__live" data-part="live" aria-live="polite" aria-atomic="true"></span>
    </div>
    """
  end

  @doc """
  A token-styled chart card for a title, value, caller controls, and chart content.

  Supply `:settings_trigger` with a `chart_settings/1` component when settings are
  needed. Tabs, ranges, settings, and footer content remain caller-owned.
  """
  attr(:id, :string, required: true, doc: "Stable chart card id.")
  attr(:title, :string, required: true, doc: "Card heading.")
  attr(:value, :any, default: nil, doc: "Optional headline value displayed beside the title.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the card.")
  slot(:tabs, doc: "Optional chart tabs or other header controls.")
  slot(:range_controls, doc: "Consumer-owned date-range controls.")
  slot(:settings_trigger, doc: "A chart_settings/1 control, usually a popover trigger and panel.")
  slot(:footer_note, doc: "Optional explanatory note below the chart.")
  slot(:inner_block, required: true, doc: "Chart content.")

  def chart_card(assigns) do
    ~H"""
    <section
      id={@id}
      class={Class.merge(["lui-chart-card", @class])}
      aria-labelledby={"#{@id}-title"}
    >
      <header class="lui-chart-card__header">
        <div class="lui-chart-card__heading">
          <h2 id={"#{@id}-title"} class="lui-chart-card__title">{@title}</h2>
          <div :if={@value != nil} class="lui-chart-card__value">{@value}</div>
        </div>
        <div class="lui-chart-card__actions">
          <div :if={@tabs != []} class="lui-chart-card__tabs">{render_slot(@tabs)}</div>
          <div :if={@range_controls != []} class="lui-chart-card__ranges">
            {render_slot(@range_controls)}
          </div>
          <div :if={@settings_trigger != []} class="lui-chart-card__settings">
            {render_slot(@settings_trigger)}
          </div>
        </div>
      </header>
      <div class="lui-chart-card__content">{render_slot(@inner_block)}</div>
      <footer :if={@footer_note != []} class="lui-chart-card__footer">
        {render_slot(@footer_note)}
      </footer>
    </section>
    """
  end

  @doc """
  Native server-owned chart controls inside LanternUI's existing Popover.

  Every control emits one `phx-change` event with a nested `chart_settings`
  params map. The parent owns parsing, validation, and the resulting chart assigns.
  """
  attr(:id, :string, required: true, doc: "Stable settings popover id.")
  attr(:rest, :global, include: ~w(phx-change phx-target), doc: "Native form event attributes.")
  attr(:series, :list, default: [], doc: "Series to expose as visibility checkboxes.")

  attr(:allowed_types, :list,
    default: ~w(line area stacked_area bar stacked_bar grouped_bar points),
    doc: "Chart type values offered by the native select."
  )

  attr(:type, :any, default: "line", doc: "Current chart type as an atom or string.")
  attr(:curve, :string, default: "linear", doc: "Current line or area curve.")
  attr(:visible_series, :list, default: nil, doc: "Visible ids; nil checks every series.")
  attr(:grid, :boolean, default: true, doc: "Whether horizontal grid lines are enabled.")
  attr(:axes, :boolean, default: true, doc: "Whether chart axes are enabled.")
  attr(:glyphs, :boolean, default: false, doc: "Whether point glyphs are enabled.")
  attr(:cumulative, :boolean, default: false, doc: "Whether the consumer uses cumulative values.")

  attr(:compare_previous, :boolean,
    default: false,
    doc: "Whether the consumer includes previous-period comparison data."
  )

  slot(:trigger, doc: "Optional custom popover trigger; defaults to a labeled Settings button.")

  def chart_settings(assigns) do
    types =
      assigns.allowed_types
      |> Enum.map(&to_string/1)
      |> Enum.filter(&(&1 in ~w(line area stacked_area bar stacked_bar grouped_bar points)))

    visible_ids = assigns.visible_series || Enum.map(assigns.series, &to_string(&1.id))

    assigns =
      assigns
      |> assign(:allowed_types, if(types == [], do: ["line"], else: types))
      |> assign(:type, to_string(assigns.type))
      |> assign(:visible_ids, MapSet.new(Enum.map(visible_ids, &to_string/1)))

    ~H"""
    <LanternUI.Components.Popover.popover id={@id} class="lui-chart-settings__panel">
      <LanternUI.Components.Button.button
        :if={@trigger == []}
        variant="outline"
        size="sm"
        class="lui-chart-settings__trigger"
        label="Chart settings"
      >
        Settings
      </LanternUI.Components.Button.button>
      {render_slot(@trigger)}
      <:content>
        <form
          id={"#{@id}-form"}
          class="lui-chart-settings"
          {@rest}
        >
          <label class="lui-chart-settings__field">
            <span>Chart type</span>
            <select name="chart_settings[type]" value={@type}>
              <option :for={type <- @allowed_types} value={type} selected={@type == type}>
                {chart_type_label(type)}
              </option>
            </select>
          </label>
          <label class="lui-chart-settings__field">
            <span>Curve</span>
            <select name="chart_settings[curve]" value={@curve}>
              <option
                :for={curve <- ~w(linear monotone step cardinal)}
                value={curve}
                selected={@curve == curve}
              >
                {String.capitalize(curve)}
              </option>
            </select>
          </label>
          <fieldset class="lui-chart-settings__series">
            <legend>Visible series</legend>
            <label :for={series <- @series} class="lui-chart-settings__check">
              <input
                type="checkbox"
                name="chart_settings[visible_series][]"
                value={to_string(series.id)}
                checked={MapSet.member?(@visible_ids, to_string(series.id))}
              />
              <span>{series.label}</span>
            </label>
          </fieldset>
          <fieldset class="lui-chart-settings__toggles">
            <legend>Display</legend>
            <label class="lui-chart-settings__check">
              <input type="hidden" name="chart_settings[grid]" value="false" />
              <input type="checkbox" name="chart_settings[grid]" value="true" checked={@grid} />
              <span>Grid lines</span>
            </label>
            <label class="lui-chart-settings__check">
              <input type="hidden" name="chart_settings[axes]" value="false" />
              <input type="checkbox" name="chart_settings[axes]" value="true" checked={@axes} />
              <span>Axes and labels</span>
            </label>
            <label class="lui-chart-settings__check">
              <input type="hidden" name="chart_settings[glyphs]" value="false" />
              <input type="checkbox" name="chart_settings[glyphs]" value="true" checked={@glyphs} />
              <span>Point glyphs</span>
            </label>
            <label class="lui-chart-settings__check">
              <input type="hidden" name="chart_settings[cumulative]" value="false" />
              <input
                type="checkbox"
                name="chart_settings[cumulative]"
                value="true"
                checked={@cumulative}
              />
              <span>Cumulative values</span>
            </label>
            <label class="lui-chart-settings__check">
              <input type="hidden" name="chart_settings[compare_previous]" value="false" />
              <input
                type="checkbox"
                name="chart_settings[compare_previous]"
                value="true"
                checked={@compare_previous}
              />
              <span>Compare previous period</span>
            </label>
          </fieldset>
        </form>
      </:content>
    </LanternUI.Components.Popover.popover>
    """
  end

  defp chart_type_label(type) do
    case to_string(type) do
      "stacked_area" -> "Stacked area"
      "stacked_bar" -> "Stacked bar"
      "grouped_bar" -> "Grouped bar"
      type -> String.capitalize(type)
    end
  end

  defp time_series_geometry(assigns) do
    series = normalize_time_series(assigns.series)
    visible = assigns.visible_series && MapSet.new(assigns.visible_series)
    series = Enum.filter(series, &(is_nil(visible) or MapSet.member?(visible, &1.id)))
    comparison = normalize_time_series(assigns.comparison)
    comparison = Enum.filter(comparison, &(is_nil(visible) or MapSet.member?(visible, &1.id)))
    all_points = Enum.flat_map(series ++ comparison, & &1.points)

    case {all_points, x_domain_kind(all_points)} do
      {[], _} ->
        %{
          has_data: false,
          chart_type: assigns.type,
          legend: [],
          interaction_labels: [],
          interaction_colors: [],
          interaction_points: [],
          interaction_series_ids: [],
          interaction_enabled:
            not is_nil(assigns.select_event) or not is_nil(assigns.hover_event),
          reference_lines: [],
          interaction_series_count: 0
        }

      {_, nil} ->
        kinds = all_points |> Enum.map(fn point -> point.key |> elem(0) end) |> Enum.uniq()
        names = Enum.map_join(kinds, ", ", &x_domain_name/1)

        raise ArgumentError,
              "time_series_chart expects one homogeneous x domain (dates/date-times, numbers, or category strings); received mixed domains: #{names}"

      {_, kind} ->
        build_time_series_geometry(assigns, series, comparison, all_points, kind)
    end
  end

  defp build_time_series_geometry(assigns, series, comparison, all_points, kind) do
    plot_left = @margin.left
    plot_right = @vb_w - @margin.right
    plot_top = 18
    plot_bottom = assigns.height - @margin.bottom
    primary_points = Enum.flat_map(series, & &1.points)
    interaction_series = series ++ comparison
    reference_specs = normalize_reference_lines(assigns.reference_lines, assigns.value_format)
    axis_points = if primary_points == [], do: all_points, else: primary_points
    axis_keys = axis_points |> Enum.map(& &1.key) |> Enum.uniq() |> sort_x_keys(kind)
    axis_key_set = MapSet.new(axis_keys)
    aligned_points = Enum.filter(all_points, &MapSet.member?(axis_key_set, &1.key))
    x_positions = axis_keys |> Enum.with_index() |> Map.new(fn {key, index} -> {key, index} end)
    count = length(axis_keys)

    x_value = fn key -> x_key_value(key) end
    x_min = axis_keys |> hd() |> x_value.()
    x_max = axis_keys |> List.last() |> x_value.()

    xf = fn key ->
      if kind == :category do
        band = (plot_right - plot_left) / max(count, 1)
        plot_left + (Map.fetch!(x_positions, key) + 0.5) * band
      else
        Geometry.scale(x_min, x_max, plot_left, plot_right, x_value.(key))
      end
    end

    values =
      chart_domain_values(series, axis_keys, assigns.type, aligned_points) ++
        if(assigns.type in [:bar, :stacked_bar, :grouped_bar],
          do: Enum.map(reference_specs, & &1.value),
          else: []
        )

    ticks = Geometry.signed_nice_ticks(Enum.min(values), Enum.max(values), 5)
    ymin = hd(ticks)
    ymax = List.last(ticks)
    yf = fn y -> Geometry.scale(ymin, ymax, plot_bottom, plot_top, y) end
    numeric_x = fn value -> Geometry.scale(ymin, ymax, plot_left, plot_right, value) end
    zero_y = Geometry.round1(yf.(0))

    curve =
      if assigns.curve in [:linear, :monotone, :step, :cardinal], do: assigns.curve, else: :linear

    x_ticks = time_series_x_ticks(axis_keys, kind, xf)

    interaction_positions =
      time_series_interaction_positions(
        interaction_series,
        length(series),
        axis_keys,
        x_positions,
        assigns,
        {plot_left, plot_right},
        {plot_top, plot_bottom},
        xf,
        yf,
        numeric_x
      )

    {paths, grid_x, zero_x, x_ticks, y_ticks, grid_y, zero_y} =
      if assigns.orientation == :horizontal and assigns.type in [:bar, :stacked_bar, :grouped_bar] do
        horizontal_x_ticks =
          Enum.map(
            ticks,
            &{format_value(&1, assigns.value_format), Geometry.round1(numeric_x.(&1)), "middle"}
          )

        category_y_ticks =
          Enum.with_index(axis_keys)
          |> Enum.map(fn {key, index} ->
            {x_key_label(key, kind),
             Geometry.round1(plot_top + (index + 0.5) * ((plot_bottom - plot_top) / count))}
          end)

        horizontal_paths =
          build_bar_paths(
            assigns,
            series,
            axis_keys,
            x_positions,
            {plot_left, plot_right},
            {plot_top, plot_bottom},
            yf,
            numeric_x,
            :horizontal
          )

        horizontal_paths =
          horizontal_paths ++
            build_horizontal_comparison_paths(
              comparison,
              axis_keys,
              numeric_x,
              plot_top,
              plot_bottom
            )

        {horizontal_paths, Enum.map(ticks, &Geometry.round1(numeric_x.(&1))),
         Geometry.round1(numeric_x.(0)), horizontal_x_ticks, category_y_ticks, [], nil}
      else
        chart_paths =
          case assigns.type do
            :stacked_area ->
              build_stacked_area_paths(series, axis_keys, xf, yf, curve)

            type when type in [:bar, :stacked_bar, :grouped_bar] ->
              build_bar_paths(
                assigns,
                series,
                axis_keys,
                x_positions,
                {plot_left, plot_right},
                {plot_top, plot_bottom},
                yf,
                numeric_x,
                :vertical
              )

            _ ->
              build_line_paths(assigns, series, axis_keys, xf, yf, curve, zero_y)
          end

        compare_paths = build_comparison_paths(comparison, axis_keys, xf, yf, curve)

        {chart_paths ++ compare_paths, [], nil, x_ticks,
         Enum.map(ticks, &{format_value(&1, assigns.value_format), Geometry.round1(yf.(&1))}),
         Enum.map(ticks, &Geometry.round1(yf.(&1))), zero_y}
      end

    annotation_orientation =
      if assigns.type in [:bar, :stacked_bar, :grouped_bar],
        do: assigns.orientation,
        else: :vertical

    markers =
      build_annotation_markers(
        assigns.annotations,
        kind,
        x_positions,
        xf,
        plot_top,
        plot_bottom,
        annotation_orientation
      )

    %{
      has_data: all_points != [],
      chart_type: assigns.type,
      height: assigns.height,
      vb_w: @vb_w,
      plot_left: plot_left,
      plot_right: plot_right,
      plot_top: plot_top,
      plot_bottom: plot_bottom,
      grid_y: grid_y,
      grid_x: grid_x,
      y_ticks: y_ticks,
      x_ticks: x_ticks,
      paths: paths,
      zero_y: zero_y,
      zero_x: zero_x,
      markers: markers,
      show_grid: assigns.grid,
      show_axes: assigns.axes,
      legend:
        series
        |> Enum.with_index()
        |> Enum.map(fn {s, i} ->
          %{
            label: s.label,
            color: s.color || Enum.at(@time_series_palette, rem(i, length(@time_series_palette)))
          }
        end),
      interaction_labels: Enum.map(interaction_series, & &1.label),
      interaction_series_ids: interaction_value_ids(interaction_series),
      interaction_enabled: not is_nil(assigns.select_event) or not is_nil(assigns.hover_event),
      interaction_colors:
        interaction_series
        |> Enum.with_index()
        |> Enum.map(fn {item, index} ->
          item.color || Enum.at(@time_series_palette, rem(index, length(@time_series_palette)))
        end),
      interaction_series_count: length(interaction_series),
      reference_lines:
        if(assigns.type in [:bar, :stacked_bar, :grouped_bar],
          do:
            Enum.map(reference_specs, fn reference ->
              value_position =
                if assigns.orientation == :horizontal,
                  do: numeric_x.(reference.value),
                  else: yf.(reference.value)

              Map.merge(reference, %{
                position: Geometry.round1(value_position),
                vertical: assigns.orientation == :horizontal
              })
            end),
          else: []
        ),
      interaction_points:
        Enum.map(axis_keys, fn key ->
          %{
            x: Geometry.round1(xf.(key)),
            label: x_key_label(key, kind),
            values:
              Enum.map(interaction_series, fn item ->
                case Enum.find(item.points, &(&1.key == key)) do
                  nil -> nil
                  point -> format_value(point.y, assigns.value_format)
                end
              end),
            positions: Enum.map(interaction_positions, &Map.get(&1, key)),
            coords: Enum.map(interaction_positions, &get_in(&1, [key, :y]))
          }
          |> maybe_add_interaction_payload(key, interaction_series, assigns)
        end)
    }
  end

  defp interaction_value_ids(interaction_series) do
    interaction_series
    |> Enum.with_index()
    |> Enum.reduce({[], MapSet.new()}, fn {item, index}, {ids, seen} ->
      id = to_string(item.id)
      candidate = if MapSet.member?(seen, id), do: "comparison:#{id}:#{index}", else: id
      value_id = unique_interaction_id(candidate, seen, 2)
      {ids ++ [value_id], MapSet.put(seen, value_id)}
    end)
    |> elem(0)
  end

  defp unique_interaction_id(candidate, seen, suffix) do
    if MapSet.member?(seen, candidate) do
      unique_interaction_id("#{candidate}:#{suffix}", seen, suffix + 1)
    else
      candidate
    end
  end

  defp maybe_add_interaction_payload(point, key, interaction_series, assigns) do
    if is_nil(assigns.select_event) and is_nil(assigns.hover_event) do
      point
    else
      x_value =
        Enum.find_value(interaction_series, fn item ->
          case Enum.find(item.points, &(&1.key == key)) do
            nil -> nil
            item_point -> item_point.x_payload
          end
        end) || x_key_payload(key)

      raw_values =
        Enum.map(interaction_series, fn item ->
          case Enum.find(item.points, &(&1.key == key)) do
            nil -> nil
            item_point -> item_point.y
          end
        end)

      Map.merge(point, %{x_value: x_value, raw_values: raw_values})
    end
  end

  defp normalize_reference_lines(lines, value_format) when is_list(lines) do
    Enum.flat_map(lines, fn line ->
      value = fetch_key(line, :value)

      if finite_number?(value) do
        [
          %{
            label: to_string(fetch_key(line, :label) || "Reference"),
            value: value,
            value_label: format_value(value, value_format)
          }
        ]
      else
        []
      end
    end)
  end

  defp normalize_reference_lines(_, _), do: []

  defp x_key_payload({:time, value}) do
    case DateTime.from_unix(value, :microsecond) do
      {:ok, datetime} -> DateTime.to_iso8601(datetime)
      _ -> value
    end
  end

  defp x_key_payload({:number, value}), do: value
  defp x_key_payload({:category, label}), do: label

  defp time_series_interaction_positions(
         interaction_series,
         primary_count,
         axis_keys,
         x_positions,
         assigns,
         {plot_left, plot_right},
         {plot_top, plot_bottom},
         xf,
         yf,
         numeric_x
       ) do
    count = max(length(axis_keys), 1)
    vertical_band = (plot_right - plot_left) / count
    horizontal_band = (plot_bottom - plot_top) / count
    stacked? = assigns.type in [:stacked_area, :stacked_bar]
    initial = {Map.new(axis_keys, &{&1, 0}), Map.new(axis_keys, &{&1, 0})}

    {positions, _stack} =
      Enum.with_index(interaction_series)
      |> Enum.map_reduce(initial, fn {item, series_index}, {positive, negative} ->
        values = Map.new(item.points, &{&1.key, &1.y})

        {item_positions, positive, negative} =
          Enum.reduce(axis_keys, {%{}, positive, negative}, fn key, {result, pos, neg} ->
            case Map.fetch(values, key) do
              :error ->
                {Map.put(result, key, nil), pos, neg}

              {:ok, value} ->
                primary_stack? = stacked? and series_index < primary_count

                {point_x, point_y, pos, neg} =
                  cond do
                    primary_stack? and assigns.type == :stacked_area ->
                      if value >= 0 do
                        base = Map.fetch!(pos, key)
                        next = base + value
                        {xf.(key), yf.(next), Map.put(pos, key, next), neg}
                      else
                        base = Map.fetch!(neg, key)
                        next = base + value
                        {xf.(key), yf.(next), pos, Map.put(neg, key, next)}
                      end

                    primary_stack? and assigns.orientation == :horizontal ->
                      {base, next, pos, neg} =
                        if value >= 0 do
                          base = Map.fetch!(pos, key)
                          next = base + value
                          {base, next, Map.put(pos, key, next), neg}
                        else
                          base = Map.fetch!(neg, key)
                          next = base + value
                          {base, next, pos, Map.put(neg, key, next)}
                        end

                      {numeric_x.((base + next) / 2),
                       plot_top + (Map.fetch!(x_positions, key) + 0.5) * horizontal_band, pos,
                       neg}

                    primary_stack? ->
                      {base, next, pos, neg} =
                        if value >= 0 do
                          base = Map.fetch!(pos, key)
                          next = base + value
                          {base, next, Map.put(pos, key, next), neg}
                        else
                          base = Map.fetch!(neg, key)
                          next = base + value
                          {base, next, pos, Map.put(neg, key, next)}
                        end

                      {plot_left + (Map.fetch!(x_positions, key) + 0.5) * vertical_band,
                       yf.((base + next) / 2), pos, neg}

                    assigns.type in [:bar, :grouped_bar] and
                        assigns.orientation == :horizontal ->
                      {numeric_x.(value),
                       plot_top + (Map.fetch!(x_positions, key) + 0.5) * horizontal_band, pos,
                       neg}

                    true ->
                      {xf.(key), yf.(value), pos, neg}
                  end

                position = %{x: Geometry.round1(point_x), y: Geometry.round1(point_y)}
                {Map.put(result, key, position), pos, neg}
            end
          end)

        {item_positions, {positive, negative}}
      end)

    positions
  end

  defp interaction_aria_label(point, labels) do
    values =
      point.values
      |> Enum.zip(labels)
      |> Enum.map_join(", ", fn {value, label} -> "#{label}: #{value || "no data"}" end)

    "#{point.label}. #{values}"
  end

  defp chart_domain_values(series, axis_keys, type, points)
       when type in [:stacked_area, :stacked_bar] do
    raw_values = Enum.map(points, & &1.y)
    series_maps = Enum.map(series, &Map.new(&1.points, fn point -> {point.key, point.y} end))

    stacked_values =
      Enum.map(axis_keys, fn key ->
        Enum.reduce(series_maps, {0, 0}, fn item, {positive, negative} ->
          value = Map.get(item, key, 0)
          if value >= 0, do: {positive + value, negative}, else: {positive, negative + value}
        end)
      end)
      |> Enum.flat_map(fn {positive, negative} -> [positive, negative] end)

    raw_values ++ stacked_values
  end

  defp chart_domain_values(_series, _keys, _type, points), do: Enum.map(points, & &1.y)

  defp build_line_paths(assigns, series, axis_keys, xf, yf, curve, zero_y) do
    series
    |> Enum.with_index()
    |> Enum.flat_map(fn {item, series_index} ->
      values_by_key = Map.new(item.points, &{&1.key, &1.y})

      runs =
        axis_keys
        |> Enum.with_index()
        |> Enum.map(fn {key, index} ->
          case Map.fetch(values_by_key, key) do
            {:ok, value} -> {index, key, value}
            :error -> nil
          end
        end)
        |> split_point_runs()

      color =
        item.color ||
          Enum.at(@time_series_palette, rem(series_index, length(@time_series_palette)))

      Enum.flat_map(runs, fn run ->
        points = Enum.map(run, fn {_index, key, value} -> {xf.(key), yf.(value), value} end)

        segments =
          if length(series) == 1 and assigns.type in [:line, :area],
            do: split_signed_segments(points, zero_y),
            else: [{:series, points}]

        Enum.map(segments, fn {sign, segment} ->
          coords = Enum.map(segment, fn {x, y, _value} -> {x, y} end)
          signed? = sign in [:positive, :negative]

          segment_color =
            if sign == :positive, do: "var(--lantern-success)", else: "var(--lantern-danger)"

          line = if assigns.type == :points, do: "", else: Geometry.curve_path(coords, curve)
          fill = if assigns.type == :area, do: baseline_area_path(coords, zero_y, curve), else: ""

          %{
            class:
              "lui-time-series-chart__series" <>
                if(signed?, do: " lui-time-series-chart__gain-#{sign}", else: ""),
            color: if(signed? and is_nil(item.color), do: segment_color, else: color),
            line: line,
            fill: fill,
            points: if(assigns.glyphs or assigns.type == :points, do: coords, else: []),
            bars: []
          }
        end)
      end)
    end)
  end

  defp baseline_area_path([], _baseline, _curve), do: ""

  defp baseline_area_path(points, baseline, curve) do
    {first_x, _} = hd(points)
    {last_x, _} = List.last(points)

    "#{Geometry.curve_path(points, curve)} L#{Geometry.round1(last_x)},#{baseline} L#{Geometry.round1(first_x)},#{baseline} Z"
  end

  defp split_signed_segments(points, zero_y) do
    case points do
      [] ->
        []

      [first | rest] ->
        sign = first_nonzero_sign(points, :positive)
        split_signed_segments(rest, zero_y, sign, [first], [])
    end
  end

  defp split_signed_segments([], _zero_y, sign, current, segments),
    do: Enum.reverse([{sign, Enum.reverse(current)} | segments])

  defp split_signed_segments([point = {_x, _y, 0} | rest], zero_y, sign, current, segments) do
    next_sign = first_nonzero_sign(rest, sign)

    if next_sign == sign do
      split_signed_segments(rest, zero_y, sign, [point | current], segments)
    else
      segment = {sign, Enum.reverse([point | current])}
      split_signed_segments(rest, zero_y, next_sign, [point], [segment | segments])
    end
  end

  defp split_signed_segments([point = {x2, _y2, value2} | rest], zero_y, sign, current, segments) do
    point_sign = first_nonzero_sign([point], sign)

    if point_sign == sign do
      split_signed_segments(rest, zero_y, sign, [point | current], segments)
    else
      {x1, _y1, value1} = hd(current)
      ratio = abs(value1) / (abs(value1) + abs(value2))
      cross = {x1 + (x2 - x1) * ratio, zero_y, 0}
      segment = {sign, Enum.reverse([cross | current])}
      split_signed_segments(rest, zero_y, point_sign, [point, cross], [segment | segments])
    end
  end

  defp first_nonzero_sign(points, fallback) do
    Enum.find_value(points, fallback, fn
      {_, _, value} when value < 0 -> :negative
      {_, _, value} when value > 0 -> :positive
      _ -> nil
    end)
  end

  defp build_stacked_area_paths(series, axis_keys, xf, yf, _curve) do
    initial = {Map.new(axis_keys, &{&1, 0}), Map.new(axis_keys, &{&1, 0})}

    {paths, _final} =
      Enum.with_index(series)
      |> Enum.map_reduce(initial, fn {item, series_index}, {positive, negative} ->
        values = Map.new(item.points, &{&1.key, &1.y})

        color =
          item.color ||
            Enum.at(@time_series_palette, rem(series_index, length(@time_series_palette)))

        {positive_band, next_positive} =
          Enum.map_reduce(axis_keys, positive, fn key, totals ->
            base = Map.fetch!(totals, key)
            value = max(Map.get(values, key, 0), 0)
            {{key, base, base + value}, Map.put(totals, key, base + value)}
          end)

        {negative_band, next_negative} =
          Enum.map_reduce(axis_keys, negative, fn key, totals ->
            base = Map.fetch!(totals, key)
            value = min(Map.get(values, key, 0), 0)
            {{key, base, base + value}, Map.put(totals, key, base + value)}
          end)

        bands =
          [positive_band, negative_band]
          |> Enum.reject(fn band ->
            Enum.all?(band, fn {_key, base, top} -> base == 0 and top == 0 end)
          end)
          |> Enum.map(fn band ->
            lower = Enum.map(band, fn {key, base, _top} -> {xf.(key), yf.(base)} end)
            upper = Enum.map(band, fn {key, _base, top} -> {xf.(key), yf.(top)} end)

            %{
              class: "lui-time-series-chart__series",
              color: color,
              line: "",
              # Linear fill boundaries preserve the lower/upper ordering at every x.
              fill: Geometry.band_path(upper, lower, :linear),
              points: [],
              bars: []
            }
          end)

        {bands, {next_positive, next_negative}}
      end)

    List.flatten(paths)
  end

  defp build_bar_paths(
         assigns,
         series,
         axis_keys,
         x_positions,
         {left, right},
         {top, bottom},
         yf,
         numeric_x,
         orientation
       ) do
    count = length(axis_keys)

    band =
      if orientation == :vertical,
        do: (right - left) / max(count, 1),
        else: (bottom - top) / max(count, 1)

    cluster? = assigns.type == :grouped_bar or (assigns.type == :bar and length(series) > 1)
    width = band * if(cluster?, do: 0.76 / max(length(series), 1), else: 0.68)
    positive = Map.new(axis_keys, &{&1, 0})
    negative = Map.new(axis_keys, &{&1, 0})

    {_series, _pos, _neg, bars_by_series} =
      Enum.with_index(series)
      |> Enum.reduce({[], positive, negative, []}, fn {item, series_index},
                                                      {built, pos, neg, all_bars} ->
        values = Map.new(item.points, &{&1.key, &1.y})

        {bars, pos, neg} =
          Enum.reduce(axis_keys, {[], pos, neg}, fn key, {bars, p, n} ->
            value = Map.get(values, key, 0)
            index = Map.fetch!(x_positions, key)

            {base, next, p, n} =
              if assigns.type == :stacked_bar do
                if value >= 0 do
                  base = Map.fetch!(p, key)
                  next = base + value
                  {base, next, Map.put(p, key, next), n}
                else
                  base = Map.fetch!(n, key)
                  next = base + value
                  {base, next, p, Map.put(n, key, next)}
                end
              else
                {0, value, p, n}
              end

            if value == 0 do
              {bars, p, n}
            else
              offset = if cluster?, do: (series_index - (length(series) - 1) / 2) * width, else: 0

              bar =
                if orientation == :vertical do
                  center = left + (index + 0.5) * band + offset
                  y1 = yf.(base)
                  y2 = yf.(next)

                  %{
                    x: Geometry.round1(center - width / 2),
                    y: Geometry.round1(min(y1, y2)),
                    width: Geometry.round1(width),
                    height: Geometry.round1(max(abs(y2 - y1), 0.5))
                  }
                else
                  center = top + (index + 0.5) * band + offset

                  x1 = numeric_x.(base)
                  x2 = numeric_x.(next)

                  %{
                    x: Geometry.round1(min(x1, x2)),
                    y: Geometry.round1(center - width / 2),
                    width: Geometry.round1(max(abs(x2 - x1), 0.5)),
                    height: Geometry.round1(width)
                  }
                end

              {[bar | bars], p, n}
            end
          end)

        color =
          item.color ||
            Enum.at(@time_series_palette, rem(series_index, length(@time_series_palette)))

        {built ++ [item], pos, neg,
         all_bars ++
           [
             %{
               class: "lui-time-series-chart__series",
               color: color,
               line: "",
               fill: "",
               points: [],
               bars: Enum.reverse(bars)
             }
           ]}
      end)

    bars_by_series
  end

  defp build_comparison_paths(series, axis_keys, xf, yf, curve) do
    Enum.flat_map(series, fn item ->
      values = Map.new(item.points, &{&1.key, &1.y})

      runs =
        axis_keys
        |> Enum.with_index()
        |> Enum.map(fn {key, index} ->
          case Map.fetch(values, key) do
            {:ok, value} -> {index, key, value}
            :error -> nil
          end
        end)
        |> split_point_runs()

      Enum.map(runs, fn run ->
        points = Enum.map(run, fn {_index, key, value} -> {xf.(key), yf.(value)} end)

        %{
          class: "lui-time-series-chart__comparison",
          color: "var(--lantern-fg-muted)",
          line: Geometry.curve_path(points, curve),
          fill: "",
          points: [],
          bars: []
        }
      end)
    end)
  end

  defp build_horizontal_comparison_paths(series, axis_keys, numeric_x, top, bottom) do
    band = (bottom - top) / max(length(axis_keys), 1)

    Enum.flat_map(series, fn item ->
      values = Map.new(item.points, &{&1.key, &1.y})

      runs =
        axis_keys
        |> Enum.with_index()
        |> Enum.map(fn {key, index} ->
          case Map.fetch(values, key) do
            {:ok, value} -> {index, key, value}
            :error -> nil
          end
        end)
        |> split_point_runs()

      Enum.map(runs, fn run ->
        points =
          Enum.map(run, fn {index, _key, value} ->
            {numeric_x.(value), top + (index + 0.5) * band}
          end)

        %{
          class: "lui-time-series-chart__comparison",
          color: "var(--lantern-fg-muted)",
          line: Geometry.line_path(points, false),
          fill: "",
          points: [],
          bars: []
        }
      end)
    end)
  end

  defp build_annotation_markers(annotations, kind, x_positions, xf, top, bottom, orientation)
       when is_list(annotations) do
    Enum.flat_map(annotations, fn annotation ->
      x = normalize_x(fetch_key(annotation, :x))

      if x && elem(x.key, 0) == kind && Map.has_key?(x_positions, x.key) do
        tone = fetch_key(annotation, :tone)
        tone = if tone in [:accent, :success, :warning, :danger], do: tone, else: :accent

        marker =
          if orientation == :horizontal do
            band = (bottom - top) / max(map_size(x_positions), 1)

            %{
              horizontal: true,
              y: Geometry.round1(top + (Map.fetch!(x_positions, x.key) + 0.5) * band)
            }
          else
            %{horizontal: false, x: Geometry.round1(xf.(x.key))}
          end

        [Map.merge(marker, %{label: to_string(fetch_key(annotation, :label) || ""), tone: tone})]
      else
        []
      end
    end)
  end

  defp build_annotation_markers(_, _kind, _x_positions, _xf, _top, _bottom, _orientation), do: []

  defp normalize_time_series(series) when is_list(series) do
    {normalized, _ids} =
      series
      |> Enum.with_index()
      |> Enum.reduce({[], MapSet.new()}, fn {series, index}, {acc, ids} ->
        id = fetch_key(series, :id) || "series-#{index}"

        if MapSet.member?(ids, id) do
          {acc, ids}
        else
          points = normalize_time_points(fetch_key(series, :points))

          item = %{
            id: id,
            label: to_string(fetch_key(series, :label) || id),
            color: normalize_series_color(fetch_key(series, :color)),
            points: points
          }

          {acc ++ [item], MapSet.put(ids, id)}
        end
      end)

    normalized
  end

  defp normalize_time_series(_), do: []

  defp normalize_time_points(points) when is_list(points) do
    {result, _seen} =
      Enum.reduce(points, {[], MapSet.new()}, fn point, {acc, seen} ->
        x = fetch_key(point, :x)
        y = fetch_key(point, :y)
        normalized_x = normalize_x(x)

        if normalized_x && finite_number?(y) && not MapSet.member?(seen, normalized_x.key) do
          {[
             %{
               key: normalized_x.key,
               value: normalized_x.value,
               label: normalized_x.label,
               x_payload: normalized_x.x_payload,
               y: y
             }
             | acc
           ], MapSet.put(seen, normalized_x.key)}
        else
          {acc, seen}
        end
      end)

    Enum.reverse(result)
  end

  defp normalize_time_points(_), do: []

  defp normalize_x(%Date{} = date) do
    value = (Date.to_gregorian_days(date) - 719_528) * 86_400_000_000

    %{
      key: {:time, value},
      value: value,
      label: Date.to_iso8601(date),
      x_payload: Date.to_iso8601(date)
    }
  end

  defp normalize_x(%DateTime{} = datetime) do
    value = DateTime.to_unix(datetime, :microsecond)

    %{
      key: {:time, value},
      value: value,
      label: Calendar.strftime(datetime, "%b %-d"),
      x_payload: DateTime.to_iso8601(datetime)
    }
  end

  defp normalize_x(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> normalize_x()
  end

  defp normalize_x(value) when is_number(value) and abs(value) <= 1.0e15 do
    %{key: {:number, value}, value: value, label: number_label(value), x_payload: value}
  end

  defp normalize_x(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} ->
        normalized = normalize_x(date)
        %{normalized | x_payload: value}

      _ ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _} ->
            normalized = normalize_x(datetime)
            %{normalized | x_payload: value}

          _ ->
            %{key: {:category, value}, value: value, label: value, x_payload: value}
        end
    end
  end

  defp normalize_x(_), do: nil

  defp x_domain_kind(points) do
    kinds = points |> Enum.map(fn point -> point.key |> elem(0) end) |> Enum.uniq()
    if length(kinds) == 1, do: hd(kinds), else: nil
  end

  defp x_domain_name(:time), do: "dates/date-times"
  defp x_domain_name(:number), do: "numbers"
  defp x_domain_name(:category), do: "category strings"

  defp sort_x_keys(keys, :category), do: keys
  defp sort_x_keys(keys, _kind), do: Enum.sort(keys)

  defp x_key_value({:time, value}), do: value
  defp x_key_value({:number, value}), do: value
  defp x_key_value({:category, _}), do: 0

  defp time_series_x_ticks(keys, kind, xf) do
    count = length(keys)

    indices =
      0..min(count - 1, 4)
      |> Enum.map(&round(&1 * (count - 1) / max(min(count - 1, 4), 1)))
      |> Enum.uniq()

    Enum.map(indices, fn index ->
      point = Enum.at(keys, index)
      label = x_key_label(point, kind)
      {label, Geometry.round1(xf.(point)), tick_anchor(index, count)}
    end)
  end

  defp x_key_label({:category, label}, :category), do: label
  defp x_key_label({:number, value}, :number), do: number_label(value)

  defp x_key_label({:time, value}, :time) do
    case DateTime.from_unix(value, :microsecond) do
      {:ok, datetime} -> Calendar.strftime(datetime, "%b %-d")
      _ -> ""
    end
  end

  defp split_point_runs(points) do
    points
    |> Enum.reduce({[], []}, fn
      nil, {runs, []} -> {runs, []}
      nil, {runs, current} -> {[Enum.reverse(current) | runs], []}
      point, {runs, current} -> {runs, [point | current]}
    end)
    |> then(fn {runs, current} ->
      Enum.reverse(if(current == [], do: runs, else: [Enum.reverse(current) | runs]))
    end)
  end

  defp fetch_key(map, key) when is_map(map),
    do: Map.get(map, key, Map.get(map, Atom.to_string(key)))

  defp fetch_key(_, _), do: nil

  defp finite_number?(value) when is_integer(value), do: abs(value) <= 1.0e15
  defp finite_number?(value) when is_float(value), do: value == value and abs(value) <= 1.0e15
  defp finite_number?(_), do: false

  defp normalize_series_color(color) when is_binary(color) do
    color = String.trim(color)

    if Regex.match?(@series_color_regex, color), do: color, else: nil
  end

  defp normalize_series_color(_), do: nil

  defp line_geometry(series, height, fmt) do
    norm =
      series
      |> Enum.map(&normalize_line_series/1)
      |> Enum.reject(fn s -> s.points == [] end)

    all_points = Enum.flat_map(norm, & &1.points)

    case all_points do
      [] ->
        %{has_data: false, fg_muted: @fg_muted}

      _ ->
        plot_left = @margin.left
        plot_right = @vb_w - @margin.right
        plot_top = @margin.top
        plot_bottom = height - @margin.bottom

        times = Enum.map(all_points, fn {t, _} -> t end)
        t0 = Enum.min_by(times, &DateTime.to_unix/1)
        tn = Enum.max_by(times, &DateTime.to_unix/1)
        span = DateTime.diff(tn, t0)
        xf = fn t -> Geometry.scale(0, span, plot_left, plot_right, DateTime.diff(t, t0)) end

        values = Enum.map(all_points, fn {_t, v} -> v end)

        ticks =
          Geometry.nice_ticks(0, Enum.max(values), 4, integer: Enum.all?(values, &is_integer/1))

        ymax = List.last(ticks)
        yf = fn v -> Geometry.scale(0, ymax, plot_bottom, plot_top, v) end
        label_for = time_label_fun(span)

        lines =
          norm
          |> Enum.with_index()
          |> Enum.map(fn {s, i} ->
            px = Enum.map(s.points, fn {t, v} -> {xf.(t), yf.(v)} end)

            %{
              label: s.label,
              color: line_color_at(s.color, i),
              d: Geometry.line_path(px, length(px) <= @smooth_max)
            }
          end)

        y_ticks = Enum.map(ticks, fn t -> {format_value(t, fmt), Geometry.round1(yf.(t))} end)

        x_ticks =
          0..4
          |> Enum.map(fn k ->
            t = DateTime.add(t0, round(k / 4 * span), :second)
            {label_for.(t), Geometry.round1(xf.(t)), tick_anchor(k, 5)}
          end)
          |> Enum.uniq()

        series_json =
          norm
          |> Enum.with_index()
          |> Enum.map(fn {s, i} ->
            pts =
              Enum.map(s.points, fn {t, v} ->
                %{
                  x: Geometry.round1(xf.(t)),
                  y: Geometry.round1(yf.(v)),
                  v: format_value(v, fmt),
                  t: label_for.(t)
                }
              end)

            %{label: s.label, color: line_color_at(s.color, i), pts: pts}
          end)
          |> Jason.encode!()

        %{
          has_data: true,
          vb_w: @vb_w,
          plot_left: plot_left,
          plot_right: plot_right,
          plot_top: plot_top,
          plot_bottom: plot_bottom,
          y_ticks: y_ticks,
          x_ticks: x_ticks,
          lines: lines,
          series_json: series_json,
          fg: @fg,
          fg_muted: @fg_muted
        }
    end
  end

  defp line_color_at(color, _i) when is_binary(color), do: color
  defp line_color_at(_nil, i), do: Enum.at(@line_palette, rem(i, length(@line_palette)))

  defp normalize_line_series(s) do
    points =
      s
      |> line_points()
      |> Enum.map(&parse_point/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn {t, _} -> DateTime.to_unix(t) end)

    %{label: bar_label(s), color: line_color(s), points: points}
  end

  defp line_color(%{color: c}) when is_binary(c), do: c
  defp line_color(%{"color" => c}) when is_binary(c), do: c
  defp line_color(_), do: nil

  defp line_points(%{points: p}) when is_list(p), do: p
  defp line_points(%{"points" => p}) when is_list(p), do: p
  defp line_points(_), do: []

  defp parse_point({t, v}) when is_number(v), do: with_dt(to_datetime(t), v)
  defp parse_point(%{value: v} = m) when is_number(v), do: with_dt(to_datetime(point_time(m)), v)

  defp parse_point(%{"value" => v} = m) when is_number(v),
    do: with_dt(to_datetime(point_time(m)), v)

  defp parse_point(_), do: nil

  defp with_dt(nil, _v), do: nil
  defp with_dt(dt, v), do: {dt, v}

  defp point_time(%{time: t}), do: t
  defp point_time(%{"time" => t}), do: t
  defp point_time(%{date: t}), do: t
  defp point_time(%{"date" => t}), do: t
  defp point_time(_), do: nil

  defp to_datetime(%DateTime{} = dt), do: dt
  defp to_datetime(%NaiveDateTime{} = ndt), do: DateTime.from_naive!(ndt, "Etc/UTC")
  defp to_datetime(%Date{} = d), do: DateTime.new!(d, ~T[00:00:00], "Etc/UTC")

  defp to_datetime(s) when is_binary(s) do
    case DateTime.from_iso8601(s) do
      {:ok, dt, _} ->
        dt

      _ ->
        case NaiveDateTime.from_iso8601(s) do
          {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
          _ -> nil
        end
    end
  end

  defp to_datetime(_), do: nil

  defp time_label_fun(span) when span <= 2 * 86_400, do: fn t -> Calendar.strftime(t, "%H:%M") end
  defp time_label_fun(_span), do: fn t -> "#{month(t)} #{t.day}" end
end
