defmodule LanternUI.StatTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Stat

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "stat_card renders a minimal unlinked metric without optional content" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card label="Open orders" value="42" />
        """
      end)

    assert html =~ ~s(class="lui-dt-stat lui-dt-stat-static")
    assert html =~ ~s(<span class="lui-dt-stat-label">Open orders</span>)
    assert html =~ ~s(<span class="lui-dt-stat-value">42</span>)
    assert html =~ ~s(href="#")
    refute html =~ "lui-dt-stat-icon"
    refute html =~ "lui-dt-stat-sub"
    assert :binary.match(html, "Open orders") < :binary.match(html, "42")
  end

  test "stat_card renders a linked metric with icon, subtitle, and merged class" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card
          label="Shipped"
          value={128}
          subtitle="Last 24 hours"
          icon="hero-truck"
          href="/orders?status=shipped"
          class="dashboard-stat"
        />
        """
      end)

    assert html =~ ~s(href="/orders?status=shipped")
    assert html =~ ~s(class="lui-dt-stat dashboard-stat")
    refute html =~ "lui-dt-stat-static"
    assert html =~ ~s(class="lui-dt-stat-icon hero-truck")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(<span class="lui-dt-stat-sub">Last 24 hours</span>)
  end

  test "stat_grid renders one-to-many slot cards and passes root attributes" do
    html =
      render(
        fn assigns ->
          ~H"""
          <Stat.stat_grid id="order-stats" class="dashboard-grid" aria-label="Order summary">
            <:stat label="Open" value={42} />
            <:stat label="Packed">{@packed}</:stat>
            <:stat label="Shipped" value={128} href="/orders?status=shipped" />
          </Stat.stat_grid>
          """
        end,
        %{packed: 17}
      )

    assert html =~ ~s(id="order-stats")
    assert html =~ ~s(class="lui-dt-stats lui-stat-grid dashboard-grid")
    assert html =~ ~s(aria-label="Order summary")
    assert length(Regex.scan(~r/class="lui-dt-stat(?: |")/, html)) == 3
    assert html =~ ">42<"
    assert html =~ ">17<"
    assert html =~ ">128<"
  end

  test "stat_grid emits no wrapper when it has no stat slots" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_grid id="empty-stats" />
        """
      end)

    refute html =~ "empty-stats"
    refute html =~ "lui-stat-grid"
  end
end
