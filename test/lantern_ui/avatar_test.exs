defmodule LanternUI.AvatarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Avatar

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()

  test "renders size, shape, root part, and inner content" do
    html =
      render(fn assigns ->
        ~H"""
        <Avatar.avatar size="lg" shape="square">CN</Avatar.avatar>
        """
      end)

    assert html =~ ~s(class="lui-avatar")
    assert html =~ ~s(data-part="avatar")
    assert html =~ ~s(data-size="lg")
    assert html =~ ~s(data-shape="square")
    assert html =~ "CN"
  end

  test "appends consumer class after the base class" do
    html =
      render(fn assigns ->
        ~H"""
        <Avatar.avatar class="ring-2">A</Avatar.avatar>
        """
      end)

    assert html =~ ~s(class="lui-avatar ring-2")
  end
end
