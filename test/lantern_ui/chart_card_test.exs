defmodule LanternUI.ChartCardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Charts

  defp render(fun) do
    fun.(%{__changed__: nil}) |> rendered_to_string()
  end

  test "chart_card renders the title, value, header slots, content, and footer in order" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_card id="portfolio-card" title="Portfolio" value="$8,420">
          <:tabs><span>Value tab</span></:tabs>
          <:range_controls><span>Range</span></:range_controls>
          <:settings_trigger><span>Settings control</span></:settings_trigger>
          <div>Chart content</div>
          <:footer_note>Prices update daily</:footer_note>
        </Charts.chart_card>
        """
      end)

    assert html =~ ~s(aria-labelledby="portfolio-card-title")
    assert html =~ ~s(id="portfolio-card-title")
    assert html =~ "$8,420"

    for text <- ["Value tab", "Range", "Settings control", "Chart content", "Prices update daily"] do
      assert html =~ text
    end

    assert :binary.match(html, "Settings control") < :binary.match(html, "Chart content")
    assert :binary.match(html, "Chart content") < :binary.match(html, "Prices update daily")
  end

  test "chart_settings emits native fields under the documented form event and defaults visible series" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_settings
          id="portfolio-settings"
          phx-change="chart_settings"
          series={[
            %{id: :collection, label: "Collection"},
            %{id: :inventory, label: "Inventory"}
          ]}
          type="area"
          curve="monotone"
          cumulative
          compare_previous
        />
        """
      end)

    assert html =~ ~s(id="portfolio-settings-form")
    assert html =~ ~s(phx-change="chart_settings")
    assert html =~ ~s(name="chart_settings[type]")
    assert html =~ ~s(name="chart_settings[curve]")
    assert html =~ ~s(name="chart_settings[visible_series][]" value="collection" checked)
    assert html =~ ~s(name="chart_settings[visible_series][]" value="inventory" checked)
    assert html =~ ~s(name="chart_settings[cumulative]" value="true" checked)
    assert html =~ ~s(name="chart_settings[compare_previous]" value="true" checked)
    assert html =~ "Cumulative values"
    assert html =~ "Compare previous period"
  end
end
