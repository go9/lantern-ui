defmodule LanternUI.SheetTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Sheet

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "renders hook, placement, dialog wiring, header/body/footer" do
    html =
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="edit" placement="right" title="Edit theme">
          BODY
          <:footer>FOOT</:footer>
        </Sheet.sheet>
        """
      end)

    assert html =~ ~s(id="edit")
    assert html =~ ~s(class="lui-sheet")
    assert html =~ ~s(phx-hook="LanternSheet")
    assert html =~ ~s(data-placement="right")
    assert html =~ ~s(data-close-on-esc="true")
    assert html =~ ~s(data-part="backdrop")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ "Edit theme"
    assert html =~ "BODY"
    assert html =~ "FOOT"
    assert html =~ ~s(data-part="close")
    # closed by default (hidden attr present)
    assert html =~ "hidden"
  end

  test "open renders visible; prevent_closing drops the close button + dismissals" do
    html =
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="s" open prevent_closing>X</Sheet.sheet>
        """
      end)

    assert html =~ ~s(data-open)
    refute html =~ ~s(data-part="close")
    assert html =~ ~s(data-close-on-esc="false")
    assert html =~ ~s(data-close-on-outside="false")
  end

  test "on_close renders a JS command marker and nil on_close renders nothing" do
    with_close =
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="s" on_close={Phoenix.LiveView.JS.push("close_settings")}>X</Sheet.sheet>
        """
      end)

    without_close =
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="s">X</Sheet.sheet>
        """
      end)

    assert with_close =~ ~s(data-on-close=)
    refute without_close =~ ~s(data-on-close=)
  end

  test "custom header slot replaces the title" do
    html =
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="s" title="ignored">
          <:header>CUSTOM</:header>
          B
        </Sheet.sheet>
        """
      end)

    assert html =~ "CUSTOM"
    refute html =~ "lui-sheet-title"
  end

  test "left/right sheet panels size against the containing block, not the viewport" do
    css = File.read!("priv/static/lantern_ui.css")

    assert css =~
             ~r/\.lui-sheet\[data-placement="right"\] \.lui-sheet-panel \{[^}]*width: min\(28rem, 100%\);/

    assert css =~
             ~r/\.lui-sheet\[data-placement="left"\] \.lui-sheet-panel \{[^}]*width: min\(28rem, 100%\);/

    refute css =~ ~r/width: min\(28rem, 100vw\)/
  end
end
