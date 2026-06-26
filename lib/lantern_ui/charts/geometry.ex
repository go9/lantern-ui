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
  """
  @spec nice_ticks(number, number, pos_integer) :: [float]
  def nice_ticks(min, max, count \\ 5)

  def nice_ticks(min, max, count) when count > 1 do
    {min, max} = if max <= min, do: {min - 1.0, max + 1.0}, else: {min * 1.0, max * 1.0}
    step = nice_num(nice_num(max - min, false) / (count - 1), true)
    nmin = Float.floor(min / step) * step
    nmax = Float.ceil(max / step) * step

    nmin
    |> Stream.iterate(&(&1 + step))
    |> Enum.take_while(&(&1 <= nmax + step / 2.0))
    |> Enum.map(&Float.round(&1, 6))
  end

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
