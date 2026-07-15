defmodule LanternUI.NavlistLoadingTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Loading
  alias LanternUI.Components.Navlist

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "navlist/1" do
    test "renders heading and nested navlinks" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlist heading="Workspace">
            <Navlist.navlink navigate="/dash" active>Dashboard</Navlist.navlink>
            <Navlist.navlink navigate="/settings">Settings</Navlist.navlink>
          </Navlist.navlist>
          """
        end)

      assert html =~ ~s(class="lui-navlist")
      assert html =~ ~s(class="lui-navlist-heading")
      assert html =~ "Workspace"
      assert html =~ "Dashboard"
      assert html =~ "Settings"
      assert html =~ ~s(href="/dash")
      assert html =~ "lui-navlink-active"
      assert html =~ ~s(aria-current="page")
    end

    test "navheading renders heading content" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlist>
            <Navlist.navheading>Section</Navlist.navheading>
            <Navlist.navlink navigate="/">Home</Navlist.navlink>
          </Navlist.navlist>
          """
        end)

      assert html =~ "lui-navlist-heading"
      assert html =~ "Section"
    end
  end

  describe "navlink/1" do
    test "with navigate renders a link and aria-current when active" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlink navigate="/dash" active>Dashboard</Navlist.navlink>
          """
        end)

      assert html =~ ~s(href="/dash")
      assert html =~ "lui-navlink"
      assert html =~ "lui-navlink-active"
      assert html =~ ~s(aria-current="page")
      assert html =~ "Dashboard"
      refute html =~ ~s(<button)
    end

    test "without navigate/href renders a button" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlink phx-click="go">Act</Navlist.navlink>
          """
        end)

      assert html =~ ~s(<button)
      assert html =~ ~s(type="button")
      assert html =~ ~s(phx-click="go")
      assert html =~ "lui-navlink"
      assert html =~ "Act"
      refute html =~ ~s(href=)
    end

    test "icon renders when given" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlink navigate="/" icon="chart-bar">Dash</Navlist.navlink>
          """
        end)

      assert html =~ "lui-navlink-icon"
      assert html =~ "<svg"
      assert html =~ "Dash"
    end
  end

  describe "loading/1" do
    test "defaults to ring variant with role status and sr-only label" do
      html =
        render(fn assigns ->
          ~H"""
          <Loading.loading />
          """
        end)

      assert html =~ ~s(class="lui-loading")
      assert html =~ ~s(data-variant="ring")
      assert html =~ ~s(data-size="md")
      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-label="Loading")
      assert html =~ ~s(class="lui-sr-only")
      assert html =~ "Loading"
      assert html =~ "lui-loading-ring"
    end

    test "renders each dots variant" do
      for variant <- ~w(dots-bounce dots-fade dots-scale) do
        html =
          render(
            fn assigns ->
              ~H"""
              <Loading.loading variant={@variant} />
              """
            end,
            %{variant: variant}
          )

        assert html =~ ~s(data-variant="#{variant}")
        assert html =~ ~s(role="status")
        assert html =~ "lui-loading-dot"
        assert html =~ "lui-sr-only"
      end
    end

    test "size sets data-size and custom label" do
      html =
        render(fn assigns ->
          ~H"""
          <Loading.loading size="xl" label="Saving" />
          """
        end)

      assert html =~ ~s(data-size="xl")
      assert html =~ ~s(aria-label="Saving")
      assert html =~ "Saving"
    end
  end
end
