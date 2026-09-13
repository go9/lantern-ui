defmodule LanternUI.Charts do
  @moduledoc """
  Native LiveView chart components — server-rendered SVG, minimal JS.

  Geometry (scales, ticks, paths) is computed in Elixir by
  `LanternUI.Charts.Geometry` and rendered as SVG, so charts re-render through
  normal LiveView assigns. The only client JS is the optional `ChartHover` hook
  (`priv/static/lantern_ui_hooks.js`), used by `area_chart/1` for the
  crosshair/tooltip.

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
  attr(:class, :string, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:aria_label, :string, default: "Sparkline", doc: "Accessible name for the SVG.")

  def sparkline(assigns) do
    assigns = assign(assigns, spark_geometry(assigns.series, assigns.height))

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
    ticks = Geometry.nice_ticks(vmin, vmax, 5)
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

        vmax = all_points |> Enum.map(fn {_t, v} -> v end) |> Enum.max()
        ticks = Geometry.nice_ticks(0, vmax, 4)
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
