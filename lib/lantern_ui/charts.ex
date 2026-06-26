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
  attr(:id, :string, required: true)
  attr(:series, :list, default: [])
  attr(:height, :integer, default: 250)
  attr(:class, :string, default: nil)

  attr(:value_format, :any,
    default: :number,
    doc: "`:number` | `:currency` | a 1-arity function `(number -> String.t())`"
  )

  attr(:empty_message, :string, default: "No data")
  attr(:aria_label, :string, default: "Area chart")

  def area_chart(assigns) do
    assigns =
      assigns.series
      |> normalize_dated()
      |> area_geometry(assigns.height, assigns.value_format)
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
            <text :for={{l, x} <- @x_ticks} x={x} y={@height - 8} text-anchor="middle">{l}</text>
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
  attr(:id, :string, required: true)
  attr(:series, :list, default: [])
  attr(:height, :integer, default: 40)
  attr(:class, :string, default: nil)
  attr(:aria_label, :string, default: "Sparkline")

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
  """
  attr(:id, :string, required: true)
  attr(:series, :list, default: [])
  attr(:height, :integer, default: 180)
  attr(:class, :string, default: nil)
  attr(:value_format, :any, default: :number)
  attr(:empty_message, :string, default: "No data")
  attr(:aria_label, :string, default: "Bar chart")

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
          <rect
            :for={b <- @bars}
            x={b.x}
            y={b.y}
            width={b.w}
            height={b.h}
            rx="4"
            fill={@accent}
            opacity="0.9"
          />
        </g>
        <g fill="currentColor" fill-opacity="0.6" font-size="11.5" text-anchor="middle">
          <text :for={b <- @bars} x={b.cx} y={b.y - 6} font-weight="500">{b.value}</text>
        </g>
        <g fill="currentColor" fill-opacity="0.45" font-size="11" text-anchor="middle">
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

  defp area_geometry([], _height, _fmt), do: %{has_data: false, fg_muted: @fg_muted}

  defp area_geometry(points, height, fmt) do
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
    smooth? = length(px) <= @smooth_max

    y_ticks = Enum.map(ticks, fn t -> {format_value(t, fmt), Geometry.round1(yf.(t))} end)

    count = length(points)
    label_fun = if span <= 95, do: &short_label/1, else: &long_label/1

    x_ticks =
      0..4
      |> Enum.map(&round(&1 / 4 * (count - 1)))
      |> Enum.uniq()
      |> Enum.map(fn i ->
        {d, _} = Enum.at(points, i)
        {label_fun.(d), Geometry.round1(xf.(d))}
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
      |> Enum.map(fn item -> {bar_label(item), bar_value(item)} end)
      |> Enum.reject(fn {_l, v} -> is_nil(v) end)

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
          |> Enum.map(fn {{label, v}, i} ->
            bh = v / maxv * inner_h
            bx = m.left + i * band + (band - barw) / 2

            %{
              x: Geometry.round1(bx),
              y: Geometry.round1(baseline - bh),
              w: Geometry.round1(barw),
              h: Geometry.round1(bh),
              cx: Geometry.round1(bx + barw / 2),
              label: label,
              value: format_value(v, fmt)
            }
          end)

        %{
          has_data: true,
          vb_w: @vb_w,
          baseline: Geometry.round1(baseline),
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
end
