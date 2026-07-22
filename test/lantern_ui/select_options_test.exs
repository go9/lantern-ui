defmodule LanternUI.SelectOptionsTest do
  @moduledoc """
  `select/1` accepts multiple option shapes: bare values, `{label, value}`
  tuples, and `%{label:, value:}` maps.

  The map shape previously fell through to `to_string/1` on a map and crashed
  with a `Protocol.UndefinedError` (surfaced by playground's /admin/settings
  font pickers, flicker #992).
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Select

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "accepts %{label:, value:} map options and renders them" do
    html =
      render(fn assigns ->
        ~H"""
        <Select.select
          name="brand_font"
          value="inter"
          options={[%{label: "Inter", value: "inter"}, %{label: "Poppins", value: "poppins"}]}
        />
        """
      end)

    assert html =~ ~s(data-value="inter")
    assert html =~ "Inter"
    assert html =~ ~s(data-value="poppins")
    assert html =~ "Poppins"
  end

  test "still accepts {label, value} tuples and bare values" do
    html =
      render(fn assigns ->
        ~H"""
        <Select.select name="f" options={[{"Tuple", "t"}, "bare"]} />
        """
      end)

    assert html =~ ~s(data-value="t")
    assert html =~ "Tuple"
    assert html =~ ~s(data-value="bare")
  end
end
