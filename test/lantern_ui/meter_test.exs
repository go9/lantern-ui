defmodule LanternUI.MeterTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Meter

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "meter/1" do
    test "renders role=meter with value, range, fill width, and defaults" do
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={40} />
          """
        end)

      assert html =~ ~s(class="lui-meter")
      assert html =~ ~s(role="meter")
      assert html =~ ~s(aria-valuenow="40")
      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="100")
      assert html =~ ~s(aria-label="Meter")
      assert html =~ ~s(style="width: 40.0%")
      assert html =~ ~s(data-size="md")
      refute html =~ "data-state"
      refute html =~ "aria-valuetext"
    end

    test "custom min/max scales the fill and is reflected in ARIA" do
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={7} min={0} max={14} label="pH" value_text="7 pH" />
          """
        end)

      assert html =~ ~s(aria-valuemin="0")
      assert html =~ ~s(aria-valuemax="14")
      assert html =~ ~s(aria-valuenow="7")
      assert html =~ ~s(aria-valuetext="7 pH")
      assert html =~ ~s(aria-label="pH")
      assert html =~ ~s(style="width: 50.0%")
    end

    test "fill width clamps outside the range" do
      for {value, width} <- [{-10, "0.0%"}, {150, "100.0%"}] do
        html =
          render(fn assigns ->
            assigns = assign(assigns, :value, value)

            ~H"""
            <Meter.meter value={@value} />
            """
          end)

        assert html =~ ~s(style="width: #{width}")
      end
    end

    test "low/high/optimum drive data-state by region distance" do
      # optimum in middle region: middle → optimal, low/high regions → suboptimal
      for {value, state} <- [{50, "optimal"}, {10, "suboptimal"}, {92, "suboptimal"}] do
        html =
          render(fn assigns ->
            assigns = assign(assigns, :value, value)

            ~H"""
            <Meter.meter value={@value} low={20} high={80} optimum={50} />
            """
          end)

        assert html =~ ~s(data-state="#{state}"), "value #{value} expected #{state}"
      end

      # optimum in high region: low region is two regions away → critical
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={5} low={20} high={80} optimum={95} />
          """
        end)

      assert html =~ ~s(data-state="critical")
    end

    test "optimum defaults to the range midpoint (HTML <meter> spec)" do
      # implied optimum = (0 + 100) / 2 = 50, the middle region
      for {value, state} <- [{50, "optimal"}, {90, "suboptimal"}, {10, "suboptimal"}] do
        html =
          render(fn assigns ->
            assigns = assign(assigns, :value, value)

            ~H"""
            <Meter.meter value={@value} low={20} high={80} />
            """
          end)

        assert html =~ ~s(data-state="#{state}"), "value #{value} expected #{state}"
      end

      # warn-above-high with only `high`: healthy values stay optimal
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={50} high={80} />
          """
        end)

      assert html =~ ~s(data-state="optimal")
    end

    test "size and class merge onto the root" do
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={10} size="lg" class="extra" />
          """
        end)

      assert html =~ ~s(data-size="lg")
      assert html =~ ~s(class="lui-meter extra")
    end

    test "ARIA gate: meter with label is conformant" do
      html =
        render(fn assigns ->
          ~H"""
          <Meter.meter value={68} low={20} high={80} label="Battery" value_text="68 percent" />
          """
        end)

      assert ARIAConformance.audit(html, []) == []
    end
  end
end
