defmodule LanternUI.MessageTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Message

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()

  test "defaults to start alignment and surface tone" do
    html =
      render(fn assigns ->
        ~H"""
        <Message.message>Hello</Message.message>
        """
      end)

    assert html =~ ~s(class="lui-message")
    assert html =~ ~s(data-align="start")
    assert html =~ ~s(class="lui-message-bubble" data-tone="surface")
    assert html =~ "Hello"
  end

  test "supports end alignment and primary tone" do
    html =
      render(fn assigns ->
        ~H"""
        <Message.message align="end" tone="primary">Reply</Message.message>
        """
      end)

    assert html =~ ~s(data-align="end")
    assert html =~ ~s(class="lui-message-bubble" data-tone="primary")
  end

  test "renders avatar, header, and footer slots in their wrapper parts" do
    html =
      render(fn assigns ->
        ~H"""
        <Message.message>
          <:avatar>AV</:avatar>
          <:header>HEAD</:header>
          Body
          <:footer>FOOT</:footer>
        </Message.message>
        """
      end)

    assert html =~ ~s(class="lui-message-avatar")
    assert html =~ ~s(class="lui-message-header")
    assert html =~ ~s(class="lui-message-footer")
    assert html =~ "AV"
    assert html =~ "HEAD"
    assert html =~ "FOOT"
  end

  test "appends consumer class on the message row" do
    html =
      render(fn assigns ->
        ~H"""
        <Message.message class="highlight">Body</Message.message>
        """
      end)

    assert html =~ ~s(class="lui-message highlight")
  end
end
