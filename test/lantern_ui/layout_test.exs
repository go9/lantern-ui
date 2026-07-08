defmodule LanternUI.LayoutTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Layout

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "sidebar_layout/1" do
    test "renders sidebar + topbar + main with the persistence hook" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.sidebar_layout id="app">
            <:sidebar>SIDE</:sidebar>
            <:topbar>TOP</:topbar>
            BODY
          </Layout.sidebar_layout>
          """
        end)

      assert html =~ ~s(id="app")
      assert html =~ ~s(phx-hook="LanternSidebar")
      assert html =~ ~s(class="lui-sidebar")
      assert html =~ "SIDE"
      assert html =~ ~s(class="lui-topbar")
      assert html =~ "TOP"
      assert html =~ ~s(class="lui-shell-content")
      assert html =~ "BODY"
    end

    test "collapsed sets data-collapsed; omitting it does not" do
      collapsed =
        render(fn assigns ->
          ~H"""
          <Layout.sidebar_layout id="a" collapsed>
            <:sidebar>x</:sidebar>y
          </Layout.sidebar_layout>
          """
        end)

      assert collapsed =~ ~s(data-collapsed)

      open =
        render(fn assigns ->
          ~H"""
          <Layout.sidebar_layout id="b"><:sidebar>x</:sidebar>y</Layout.sidebar_layout>
          """
        end)

      refute open =~ ~s(data-collapsed)
    end

    test "topbar section is omitted when not given" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.sidebar_layout id="c"><:sidebar>x</:sidebar>y</Layout.sidebar_layout>
          """
        end)

      refute html =~ "lui-topbar"
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
      # icon svg present
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

  describe "sidebar_toggle/1" do
    test "renders the toggle button the hook keys on" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.sidebar_toggle />
          """
        end)

      assert html =~ ~s(data-part="toggle")
      assert html =~ ~s(aria-label="Toggle sidebar")
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
