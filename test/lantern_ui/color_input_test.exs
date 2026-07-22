defmodule LanternUI.ColorInputTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.ColorInput

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "renders a native color input carrying name and value, plus label and hex readout" do
    html =
      render(fn assigns ->
        ~H"""
        <ColorInput.color_input name="theme[primary]" value="#4f46e5" label="Primary" />
        """
      end)

    assert html =~ ~s(type="color")
    assert html =~ ~s(name="theme[primary]")
    assert html =~ ~s(value="#4f46e5")
    assert html =~ "Primary"
    # read-only hex readout is display-only (not a submitted control)
    assert html =~ ~s(class="lui-color-hex")
    assert html =~ ~s(readonly)
    refute html =~ ~s(type="hidden")
  end

  test "FormField clause derives id, name, and value" do
    form = Phoenix.Component.to_form(%{"primary" => "#ff0000"}, as: :theme)

    html =
      render(
        fn assigns ->
          ~H"""
          <ColorInput.color_input field={@form[:primary]} label="Primary" />
          """
        end,
        %{form: form}
      )

    assert html =~ ~s(type="color")
    assert html =~ ~s(id="theme_primary")
    assert html =~ ~s(name="theme[primary]")
    assert html =~ ~s(value="#ff0000")
  end

  test "errors flip the wrap to invalid and render the message" do
    html =
      render(fn assigns ->
        ~H"""
        <ColorInput.color_input
          id="brand"
          name="brand"
          value="#000000"
          errors={["is not a valid color"]}
        />
        """
      end)

    assert html =~ ~s(data-invalid)
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(aria-describedby="brand-error")
    assert html =~ "is not a valid color"
  end

  test "use LanternUI imports color_input" do
    assert Map.get(LanternUI.__components__(), :color_input) == LanternUI.Components.ColorInput
  end
end
