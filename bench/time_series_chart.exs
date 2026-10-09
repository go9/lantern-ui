alias LanternUI.Charts

IO.puts("LanternUI time_series_chart full server render benchmark")
IO.puts("#{System.version()} / OTP #{:erlang.system_info(:otp_release)}")

for count <- [365, 1000], series_count <- [1, 4] do
  series =
    for series_index <- 1..series_count do
      %{
        id: "series-#{series_index}",
        label: "Series #{series_index}",
        points:
          for point_index <- 1..count do
            %{
              x: point_index,
              y: :math.sin(point_index / 25 + series_index) * 100 + series_index * 10
            }
          end
      }
    end

  render = fn ->
    assigns = %{
      __changed__: nil,
      id: "bench-#{count}-#{series_count}",
      series: series,
      type: :line,
      curve: :linear,
      visible_series: nil,
      comparison: [],
      annotations: [],
      orientation: :vertical,
      glyphs: false,
      grid: true,
      axes: true,
      empty_message: "No data",
      aria_label: "Benchmark chart",
      value_format: :number,
      height: 360,
      class: nil
    }

    assigns
    |> Charts.time_series_chart()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  _ = render.()

  samples =
    for _ <- 1..101 do
      started = System.monotonic_time()
      html = render.()
      elapsed = System.convert_time_unit(System.monotonic_time() - started, :native, :microsecond)
      {elapsed / 1000, byte_size(html)}
    end

  times = samples |> Enum.map(&elem(&1, 0)) |> Enum.sort()
  bytes = samples |> Enum.map(&elem(&1, 1)) |> Enum.max()
  p95 = Enum.at(times, ceil(length(times) * 0.95) - 1)
  median = Enum.at(times, div(length(times), 2))

  IO.puts(
    "#{series_count} series x #{count} points: median #{Float.round(median, 2)} ms, p95 #{Float.round(p95, 2)} ms, max HTML #{bytes} bytes"
  )
end
