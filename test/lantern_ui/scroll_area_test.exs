defmodule LanternUI.ScrollAreaTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.ScrollArea

  defp render(fun) do
    fun.(%{__changed__: nil}) |> rendered_to_string()
  end

  describe "scroll_area/1" do
    test "renders the base class, default orientation, and slot content" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area>Feed</ScrollArea.scroll_area>
          """
        end)

      assert html =~ ~s(class="lui-scroll-area")
      assert html =~ ~s(data-orientation="vertical")
      assert html =~ "Feed"
    end

    test "no phx-hook — native scrolling stays browser-owned" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area>Feed</ScrollArea.scroll_area>
          """
        end)

      refute html =~ "phx-hook"
    end

    test "label makes it a focusable, keyboard-scrollable named region" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area label="Recent activity">Feed</ScrollArea.scroll_area>
          """
        end)

      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="Recent activity")
      assert html =~ ~s(tabindex="0")
    end

    test "without a label there is no bare focus stop and no unnamed region" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area>Feed</ScrollArea.scroll_area>
          """
        end)

      refute html =~ "role="
      refute html =~ "tabindex"
    end

    test "orientation renders as data-*" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area orientation="horizontal">Feed</ScrollArea.scroll_area>
          """
        end)

      assert html =~ ~s(data-orientation="horizontal")
    end

    test "merges consumer class after the base and passes globals through" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area class="feed" id="activity" style="max-height: 20rem;">
            Feed
          </ScrollArea.scroll_area>
          """
        end)

      assert html =~ ~s(class="lui-scroll-area feed")
      assert html =~ ~s(id="activity")
      assert html =~ ~s(style="max-height: 20rem;")
    end

    test "ARIA gate: labeled region is conformant with no hook-owned attributes" do
      html =
        render(fn assigns ->
          ~H"""
          <ScrollArea.scroll_area label="Recent activity">Feed</ScrollArea.scroll_area>
          """
        end)

      assert ARIAConformance.audit(html) == []
    end
  end
end
