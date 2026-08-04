defmodule LanternUI.MessageScrollerTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.MessageScroller

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()

  test "renders the accessible follow-aware scroller" do
    html =
      render(fn assigns ->
        ~H"""
        <MessageScroller.message_scroller id="messages">Transcript</MessageScroller.message_scroller>
        """
      end)

    assert html =~ ~s(id="messages")
    assert html =~ ~s(phx-hook="LanternMessageScroller")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-label="Messages")
    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(role="log")
    assert html =~ ~s(aria-live="polite")
    assert html =~ ~s(aria-relevant="additions")
    assert html =~ ~s(aria-busy="false")
    assert html =~ ~s(data-follow="true")
    assert html =~ ~s(aria-label="Jump to latest")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(tabindex="-1")
    assert html =~ ~s(data-active="false")
  end

  test "renders follow and peek data attributes" do
    html =
      render(fn assigns ->
        ~H"""
        <MessageScroller.message_scroller id="messages" follow peek={72}>
          Transcript
        </MessageScroller.message_scroller>
        """
      end)

    assert html =~ ~s(data-follow="true")
    assert html =~ ~s(data-peek="72")
  end

  test "message_scroller_item renders optional identity and anchor data" do
    html =
      render(fn assigns ->
        ~H"""
        <MessageScroller.message_scroller_item message_id="m-1" scroll_anchor>
          Message
        </MessageScroller.message_scroller_item>
        """
      end)

    assert html =~ ~s(class="lui-message-scroller-item")
    assert html =~ ~s(data-message-id="m-1")
    assert html =~ "data-scroll-anchor"
  end

  test "message_scroller_item omits the scroll anchor when not set" do
    html =
      render(fn assigns ->
        ~H"""
        <MessageScroller.message_scroller_item>Message</MessageScroller.message_scroller_item>
        """
      end)

    refute html =~ "data-scroll-anchor"
  end
end
