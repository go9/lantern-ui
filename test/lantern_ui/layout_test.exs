defmodule LanternUI.LayoutTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Layout

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "app_shell/1" do
    test "renders the top bar (brand/header/actions), sidebar, main, collapse control + hook" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="app">
            <:brand>BRAND</:brand>
            <:header>CTX</:header>
            <:actions>MENU</:actions>
            <:sidebar>NAV</:sidebar>
            BODY
          </Layout.app_shell>
          """
        end)

      assert html =~ ~s(id="app")
      assert html =~ ~s(phx-hook="LanternSidebar")
      assert html =~ ~s(class="lui-appbar")
      assert html =~ ~s(class="lui-appbar-brand")
      assert html =~ "BRAND"
      assert html =~ ~s(class="lui-appbar-header")
      assert html =~ "CTX"
      assert html =~ ~s(class="lui-appbar-actions")
      assert html =~ "MENU"
      assert html =~ ~s(class="lui-app-sidebar")
      assert html =~ "NAV"
      assert html =~ ~s(class="lui-app-sidebar-foot")
      assert html =~ ~s(data-part="sidebar-collapse")
      assert html =~ ~s(class="lui-app-main")
      assert html =~ "BODY"
    end

    test "collapsed sets data-collapsed; omitting it does not" do
      collapsed =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="a" collapsed>
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      assert collapsed =~ ~s(data-collapsed)

      open =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="b">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute open =~ ~s(data-collapsed)
    end

    test "header and actions bars are omitted when their slots are empty" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="c">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute html =~ "lui-appbar-header"
      refute html =~ "lui-appbar-actions"
    end
  end

  describe "nav_item/1" do
    test "renders a link with active state, aria-current, icon and label" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Dashboard" icon="chart-bar" navigate="/dash" active />
          """
        end)

      assert html =~ ~s(href="/dash")
      assert html =~ "lui-nav-item-active"
      assert html =~ ~s(aria-current="page")
      assert html =~ ~s(title="Dashboard")
      assert html =~ ~s(class="lui-nav-item-label")
      assert html =~ "Dashboard"
      assert html =~ "<svg"
    end

    test "renders a button (not a link) when given phx-click" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Act" phx-click="go" />
          """
        end)

      assert html =~ ~s(<button)
      assert html =~ ~s(phx-click="go")
      refute html =~ ~s(href=)
    end
  end

  describe "nav_group/1" do
    test "renders the group label" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_group label="Workspace">
            <Layout.nav_item label="Home" navigate="/" />
          </Layout.nav_group>
          """
        end)

      assert html =~ "lui-nav-group-label"
      assert html =~ "Workspace"
    end
  end
end
