defmodule LanternUI.SliderTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Slider

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "APG slider contract (server render)" do
    test "thumb carries role=slider with valuenow/min/max and is focusable" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} min={10} max={90} step={5} label="Volume" />
          """
        end)

      assert html =~ ~s(role="slider")
      assert html =~ ~s(aria-valuemin="10")
      assert html =~ ~s(aria-valuemax="90")
      assert html =~ ~s(aria-valuenow="40")
      assert html =~ ~s(tabindex="0")
    end

    test "labelled render passes the ARIA gate (aria-valuetext is hook-updated)" do
      render(fn assigns ->
        ~H"""
        <Slider.slider name="volume" value={40} label="Volume" value_text="{value}%" />
        """
      end)
      |> then(fn html ->
        assert ARIAConformance.audit(html) == [],
               "ARIA violations:\n" <> ARIAConformance.report(ARIAConformance.audit(html))
      end)
    end

    test "accessible name: aria-labelledby resolves to the label; name fallback without one" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" />
          """
        end)

      assert html =~ ~s(aria-labelledby="volume-label")
      assert html =~ ~s(id="volume-label")
      refute html =~ ~s(aria-label="volume")

      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} />
          """
        end)

      assert html =~ ~s(aria-label="volume")
      refute html =~ "aria-labelledby"
    end

    test "value_text renders an interpolated aria-valuetext; absent otherwise" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" value_text="{value}%" />
          """
        end)

      assert html =~ ~s(aria-valuetext="40%")

      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" />
          """
        end)

      refute html =~ "aria-valuetext"
    end

    test "value is clamped to min..max and defaults to min when nil" do
      over =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="v" value={500} label="V" />
          """
        end)

      under =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="v" value={-5} label="V" />
          """
        end)

      empty =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="v" min={20} label="V" />
          """
        end)

      assert over =~ ~s(aria-valuenow="100")
      assert under =~ ~s(aria-valuenow="0")
      assert empty =~ ~s(aria-valuenow="20")
    end

    test "disabled removes the thumb from the tab order and marks state" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" disabled />
          """
        end)

      assert html =~ ~s(tabindex="-1")
      assert html =~ ~s(aria-disabled="true")
      assert html =~ "data-disabled"
    end
  end

  describe "hook wiring" do
    test "hook root has a stable id, the LanternSlider hook, and config data-*" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} step={5} label="Volume" value_text="{value}%" />
          """
        end)

      assert html =~ ~s(id="volume-slider")
      assert html =~ ~s(phx-hook="LanternSlider")
      assert html =~ ~s(data-min="0")
      assert html =~ ~s(data-max="100")
      assert html =~ ~s(data-step="5")
      assert html =~ ~s(data-value-text="{value}%")
    end

    test "data-part markers for the hook queries are present" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" />
          """
        end)

      for part <- ~w(input track range thumb) do
        assert html =~ ~s(data-part="#{part}")
      end
    end

    test "server renders the position as a CSS custom property" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" min={0} max={200} value={50} label="Volume" />
          """
        end)

      assert html =~ "--lui-slider-pct: 25.0%"
    end
  end

  describe "form integration" do
    test "hidden input carries id/name/value; phx-change rides on it" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" phx-change="set-volume" />
          """
        end)

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(id="volume")
      assert html =~ ~s(name="volume")
      assert html =~ ~s(value="40")
      assert html =~ ~s(phx-change="set-volume")
    end

    test "field derives id, name, and value" do
      form = Phoenix.Component.to_form(%{"volume" => "60"}, as: :settings)

      html =
        render(
          fn assigns ->
            ~H"""
            <Slider.slider field={@form[:volume]} label="Volume" />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(id="settings_volume")
      assert html =~ ~s(name="settings[volume]")
      assert html =~ ~s(aria-valuenow="60")
    end

    test "errors render with a resolvable describedby and flip data-invalid" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider name="volume" value={40} label="Volume" errors={["is out of range"]} />
          """
        end)

      assert html =~ "is out of range"
      assert html =~ ~s(aria-describedby="volume-error")
      assert html =~ ~s(id="volume-error")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "data-invalid"
    end
  end

  test "consumer class merges after the base class" do
    html =
      render(fn assigns ->
        ~H"""
        <Slider.slider name="volume" value={40} label="Volume" class="mt-2" />
        """
      end)

    assert html =~ ~s(class="lui-field mt-2")
  end
end
