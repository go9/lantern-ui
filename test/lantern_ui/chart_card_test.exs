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

  test "chart_card omits optional slots and a nil value" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_card id="empty-card" title="Empty chart" value={nil}>
          Chart content
        </Charts.chart_card>
        """
      end)

    assert html =~ "Chart content"
    refute html =~ "lui-chart-card__value"
    refute html =~ "lui-chart-card__tabs"
    refute html =~ "lui-chart-card__ranges"
    refute html =~ "lui-chart-card__settings"
    refute html =~ "lui-chart-card__footer"
  end

  test "chart_card renders one empty message and action without stale value or footer" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_card id="empty-sales" title="Sales" value="—" empty="No sales yet">
          <:empty_action><a href="/sales">Add a sale</a></:empty_action>
          <span>Duplicate chart empty</span>
          <:footer_note>Duplicate explanation</:footer_note>
        </Charts.chart_card>
        """
      end)

    assert html =~ "No sales yet"
    assert html =~ "Add a sale"
    refute html =~ "Duplicate chart empty"
    refute html =~ "Duplicate explanation"
    refute html =~ ">—<"
  end

  test "multiple chart cards keep their section and heading ids distinct" do
    html =
      render(fn assigns ->
        ~H"""
        <div>
          <Charts.chart_card id="first-card" title="First">First chart</Charts.chart_card>
          <Charts.chart_card id="second-card" title="Second">Second chart</Charts.chart_card>
        </div>
        """
      end)

    assert html =~ ~s(id="first-card" class="lui-chart-card")
    assert html =~ ~s(id="first-card-title")
    assert html =~ ~s(id="second-card" class="lui-chart-card")
    assert html =~ ~s(id="second-card-title")
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

  test "chart_settings accepts atom chart types and marks the selected atom option" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_settings
          id="atom-settings"
          type={:stacked_area}
          allowed_types={[:line, :stacked_area]}
          series={[]}
        />
        """
      end)

    assert html =~ ~s(<option value="stacked_area" selected>)
    assert html =~ "Stacked area"
    assert html =~ ~s(<option value="line">)
  end

  test "chart_settings preserves an explicitly empty visible series selection" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_settings
          id="empty-selection-settings"
          series={[%{id: :collection, label: "Collection"}]}
          visible_series={[]}
        />
        """
      end)

    refute html =~ ~s(name="chart_settings[visible_series][]" value="collection" checked)
  end

  test "chart_settings renders a custom trigger without its default trigger" do
    html =
      render(fn assigns ->
        ~H"""
        <Charts.chart_settings id="custom-settings">
          <:trigger><button type="button">Custom settings</button></:trigger>
        </Charts.chart_settings>
        """
      end)

    assert html =~ "Custom settings"
    refute html =~ ~s(class="lui-chart-settings__trigger")
  end
end
