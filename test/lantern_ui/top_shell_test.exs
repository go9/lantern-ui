defmodule LanternUI.TopShellTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.TopShell

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp attrs(html, selector, name) do
    html
    |> Floki.parse_fragment!()
    |> Floki.find(selector)
    |> Enum.map(fn {_, attrs, _} -> Enum.find_value(attrs, fn {k, v} -> k == name && v end) end)
  end

  describe "top_shell/1" do
    setup do
      html =
        render(fn assigns ->
          ~H"""
          <TopShell.top_shell id="web" class="extra">
            <:brand>BRAND</:brand>
            <:nav>
              <TopShell.top_nav_item label="Recipes" navigate="/app" active />
              <TopShell.top_nav_item label="Settings" navigate="/app/settings" />
            </:nav>
            <:search><TopShell.command_trigger target="cmd" label="Search recipes" /></:search>
            <:actions>ACTIONS</:actions>
            <:subheader>TOOLBAR</:subheader>
            BODY
          </TopShell.top_shell>
          """
        end)

      %{html: html}
    end

    test "renders the bar regions, subheader and main with the default width", %{html: html} do
      assert attrs(html, "#web", "class") == ["lui-top extra"]
      assert attrs(html, "#web", "data-width") == ["wide"]
      assert html =~ "BRAND"
      assert html =~ "ACTIONS"
      assert attrs(html, "[data-part=subheader]", "class") == ["lui-top-sub"]
      assert html =~ "TOOLBAR"
      assert attrs(html, "main", "id") == ["web-main"]
      assert html =~ "BODY"
      refute html =~ "lui-app-sidebar"
    end

    test "nav is a named landmark with the current page marked", %{html: html} do
      assert attrs(html, "nav#web-nav", "aria-label") == ["Main"]
      assert attrs(html, ~s(a[aria-current="page"]), "href") == ["/app"]
      assert attrs(html, ~s(a[href="/app/settings"]), "aria-current") == [nil]
    end

    test "the narrow-screen toggle controls the nav", %{html: html} do
      assert attrs(html, "#web-nav-toggle", "aria-controls") == ["web-nav"]
      assert attrs(html, "#web-nav-toggle", "aria-expanded") == ["false"]
      assert attrs(html, "#web-nav-toggle", "aria-label") == ["Menu"]
      assert [js] = attrs(html, "#web-nav-toggle", "phx-click")
      assert js =~ "toggle_attr"
      assert attrs(html, "#web", "phx-key") == ["Escape"]
    end

    test "width variants and optional regions" do
      html =
        render(fn assigns ->
          ~H"""
          <TopShell.top_shell id="p" width="prose" main_id="main">
            <:brand>B</:brand>
            BODY
          </TopShell.top_shell>
          """
        end)

      assert attrs(html, "#p", "data-width") == ["prose"]
      assert attrs(html, "main", "id") == ["main"]
      refute html =~ "lui-top-nav-toggle"
      refute html =~ "lui-top-sub"
      refute html =~ "lui-top-search"
    end
  end

  describe "command_trigger/1" do
    test "is a button that opens the palette, with the hotkey hint hidden from AT" do
      html =
        render(fn assigns ->
          ~H"""
          <TopShell.command_trigger id="t" target="cmd" label="Search recipes" />
          """
        end)

      # The visible label is hidden on narrow screens, so the name is an attribute.
      assert attrs(html, "button#t", "aria-label") == ["Search recipes"]
      assert attrs(html, "button#t", "aria-haspopup") == ["dialog"]
      assert attrs(html, "button#t", "aria-controls") == ["cmd"]
      assert [js] = attrs(html, "button#t", "phx-click")
      assert js =~ "lantern:dialog:open"
      assert html =~ "Search recipes"
      assert attrs(html, "kbd", "aria-hidden") == ["true"]
    end

    test "shortcut nil hides the hint" do
      html =
        render(fn assigns ->
          ~H"""
          <TopShell.command_trigger target="cmd" shortcut={nil} />
          """
        end)

      refute html =~ "<kbd"
    end
  end

  test "is importable via use LanternUI" do
    assert {:top_shell, 1} in LanternUI.Components.TopShell.__info__(:functions)
    assert Map.has_key?(LanternUI.__components__(), :top_shell)
  end
end
