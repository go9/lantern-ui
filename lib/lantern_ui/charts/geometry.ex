defmodule LanternUI.Charts.Geometry do
  @moduledoc """
  Pure geometry helpers for LanternUI charts: linear scaling, "nice" axis ticks,
  and SVG path building.

  No rendering and no Phoenix here — numbers in, strings/lists out — so this module
  is easy to unit-test and reuse.
  """

  @doc """
  Map `v` from domain `{d0, d1}` onto range `{r0, r1}`.

  A degenerate domain (`d0 == d1`) maps to the range midpoint instead of dividing
  by zero.
  """
  @spec scale(number, number, number, number, number) :: float
  def scale(d0, d1, r0, r1, _v) when d0 == d1, do: (r0 + r1) / 2.0
  def scale(d0, d1, r0, r1, v), do: r0 + (v - d0) / (d1 - d0) * (r1 - r0)

  @doc """
  "Nice" axis tick values covering `[min, max]` with roughly `count` ticks.

  Returns an ascending list of floats; the first and last entries define the
  padded ("nice") domain the caller should scale against.

  A flat range is widened so there is an axis to draw, but never below zero
  when the data is not: a row of zero counts is `0..1`, not `-1..1`.

  Options:

    * `:integer` - the values are whole numbers (counts), so the step is at
      least 1 and no tick falls between them.
  """
  @spec nice_ticks(number, number, pos_integer, keyword) :: [float]
  def nice_ticks(min, max, count \\ 5, opts \\ [])

  def nice_ticks(min, max, count, opts) when count > 1 do
    {min, max} = domain(min, max)
    step = nice_num(nice_num(max - min, false) / (count - 1), true)
    step = if Keyword.get(opts, :integer, false), do: max(step, 1.0), else: step
    nmin = Float.floor(min / step) * step
    nmax = Float.ceil(max / step) * step

    nmin
    |> Stream.iterate(&(&1 + step))
    |> Enum.take_while(&(&1 <= nmax + step / 2.0))
    |> Enum.map(&Float.round(&1, 6))
  end

  @doc "Signed nice ticks whose padded domain always includes zero."
  @spec signed_nice_ticks(number, number, pos_integer) :: [float]
  def signed_nice_ticks(min, max, count \\ 5) when count > 1 do
    nice_ticks(min(min, 0), max(max, 0), count)
  end

  defp domain(min, max) when max <= min and min >= 0, do: {max(min - 1.0, 0.0), min + 1.0}
  defp domain(min, max) when max <= min, do: {min - 1.0, max + 1.0}
  defp domain(min, max), do: {min * 1.0, max * 1.0}

  defp nice_num(range, round?) do
    range = if range <= 0, do: 1.0, else: range * 1.0
    exp = Float.floor(:math.log10(range))
    frac = range / :math.pow(10.0, exp)

    nice =
      if round? do
        cond do
          frac < 1.5 -> 1.0
          frac < 3.0 -> 2.0
          frac < 7.0 -> 5.0
          true -> 10.0
        end
      else
        cond do
          frac <= 1.0 -> 1.0
          frac <= 2.0 -> 2.0
          frac <= 5.0 -> 5.0
          true -> 10.0
        end
      end

    nice * :math.pow(10.0, exp)
  end

  @doc """
  Build an SVG path `d` from pixel points `[{x, y}]`.

  With `smooth?` true the path is Catmull-Rom smoothed (good for sparse series);
  false draws straight segments (better at high density).
  """
  @spec line_path([{number, number}], boolean) :: String.t()
  def line_path([], _smooth?), do: ""
  def line_path([{x, y}], _smooth?), do: "M#{s(x)},#{s(y)}"

  def line_path([{x0, y0} | _] = pts, false) do
    rest = pts |> tl() |> Enum.map_join("", fn {x, y} -> "L#{s(x)},#{s(y)}" end)
    "M#{s(x0)},#{s(y0)}#{rest}"
  end

  def line_path([{x0, y0} | _] = pts, true) do
    arr = List.to_tuple(pts)
    last = tuple_size(arr) - 1
    at = fn i -> elem(arr, max(0, min(last, i))) end

    segments =
      Enum.map_join(0..(last - 1), " ", fn i ->
        {p0x, p0y} = at.(i - 1)
        {p1x, p1y} = at.(i)
        {p2x, p2y} = at.(i + 1)
        {p3x, p3y} = at.(i + 2)
        c1x = p1x + (p2x - p0x) / 6
        c1y = p1y + (p2y - p0y) / 6
        c2x = p2x - (p3x - p1x) / 6
        c2y = p2y - (p3y - p1y) / 6
        "C#{s(c1x)},#{s(c1y)} #{s(c2x)},#{s(c2y)} #{s(p2x)},#{s(p2y)}"
      end)

    "M#{s(x0)},#{s(y0)} #{segments}"
  end

  @doc "Build an SVG path using a supported line curve."
  @spec curve_path([{number, number}], atom) :: String.t()
  def curve_path(points, :linear), do: line_path(points, false)
  def curve_path(points, :cardinal), do: line_path(points, true)
  def curve_path(points, :monotone), do: monotone_path(points)
  def curve_path(points, :step), do: step_path(points)
  def curve_path(points, _), do: line_path(points, false)

  @doc "Build a closed band between two point lists, traversing the lower edge in reverse."
  @spec band_path([{number, number}], [{number, number}], atom) :: String.t()
  def band_path([], _lower, _curve), do: ""
  def band_path(_upper, [], _curve), do: ""

  def band_path(upper, lower, curve) do
    [{x, y} | _] = lower_reversed = Enum.reverse(lower)
    lower_start = "M#{s(x)},#{s(y)}"
    lower_commands = lower_reversed |> curve_path(curve) |> String.replace_prefix(lower_start, "")
    "#{curve_path(upper, curve)} L#{s(x)},#{s(y)}#{lower_commands} Z"
  end

  defp step_path([]), do: ""
  defp step_path([{x, y}]), do: "M#{s(x)},#{s(y)}"

  defp step_path([{x, y} | _] = points) do
    points
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce("M#{s(x)},#{s(y)}", fn [{x1, _y1}, {x2, y2}], path ->
      mid_x = (x1 + x2) / 2
      path <> " H#{s(mid_x)} V#{s(y2)} H#{s(x2)}"
    end)
  end

  defp monotone_path([]), do: ""
  defp monotone_path([{x, y}]), do: "M#{s(x)},#{s(y)}"
  defp monotone_path([_first, _second] = points), do: line_path(points, false)

  defp monotone_path([{x0, y0} | _] = points) do
    pairs = Enum.chunk_every(points, 2, 1, :discard)
    slopes = Enum.map(pairs, fn [{x1, y1}, {x2, y2}] -> (y2 - y1) / (x2 - x1) end)
    tangents = monotone_tangents(points, slopes)

    segments =
      Enum.zip([pairs, Enum.take(tangents, length(tangents) - 1), Enum.drop(tangents, 1)])
      |> Enum.map_join(" ", fn {[{x1, y1}, {x2, y2}], m1, m2} ->
        dx = x2 - x1
        c1x = x1 + dx / 3
        c1y = y1 + m1 * dx / 3
        c2x = x2 - dx / 3
        c2y = y2 - m2 * dx / 3
        "C#{s(c1x)},#{s(c1y)} #{s(c2x)},#{s(c2y)} #{s(x2)},#{s(y2)}"
      end)

    "M#{s(x0)},#{s(y0)} #{segments}"
  end

  defp monotone_tangents(points, slopes) do
    count = length(points)
    points = List.to_tuple(points)
    slopes = List.to_tuple(slopes)

    interior =
      for i <- 1..(count - 2) do
        before = elem(slopes, i - 1)
        after_slope = elem(slopes, i)

        if before * after_slope <= 0 do
          0.0
        else
          x_before = elem(elem(points, i), 0) - elem(elem(points, i - 1), 0)
          x_after = elem(elem(points, i + 1), 0) - elem(elem(points, i), 0)
          w1 = 2 * x_after + x_before
          w2 = x_after + 2 * x_before
          (w1 + w2) / (w1 / before + w2 / after_slope)
        end
      end

    [elem(slopes, 0) | interior] ++ [elem(slopes, tuple_size(slopes) - 1)]
  end

  @doc "Closed area path: the line dropped to `baseline_y` and closed back to the start."
  @spec area_path([{number, number}], number, boolean) :: String.t()
  def area_path([], _baseline, _smooth?), do: ""

  def area_path([{x0, _} | _] = pts, baseline, smooth?) do
    {lx, _} = List.last(pts)
    "#{line_path(pts, smooth?)} L#{s(lx)},#{s(baseline)} L#{s(x0)},#{s(baseline)} Z"
  end

  @doc "Round a coordinate to one decimal, as a number."
  @spec round1(number) :: float
  def round1(v), do: Float.round(v * 1.0, 1)

  defp s(v), do: v |> round1() |> Float.to_string()
end
