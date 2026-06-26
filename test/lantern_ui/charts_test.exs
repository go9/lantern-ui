defmodule LanternUI.ChartsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defp area(series, opts \\ []) do
    render_component(
      &LanternUI.Charts.area_chart/1,
      Keyword.merge([id: "c", series: series], opts)
    )
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
end
