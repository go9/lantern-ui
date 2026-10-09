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

    assert [{"div", [{"class", "lui-dt-stat lui-dt-stat-static"}], children}] =
             Floki.parse_fragment!(html)

    assert Floki.find(Floki.parse_fragment!(html), ".lui-dt-stat-label") ==
             [{"span", [{"class", "lui-dt-stat-label"}], ["Open orders"]}]

    assert {"span", [{"class", "lui-dt-stat-value"}], ["42"]} in children
    refute html =~ "<a"
    refute html =~ "href="
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

    assert [{"a", attributes, _children}] = Floki.parse_fragment!(html)
    assert {"href", "/orders?status=shipped"} in attributes
    assert {"class", "lui-dt-stat dashboard-stat"} in attributes
    refute html =~ "lui-dt-stat-static"
    assert html =~ ~s(class="lui-dt-stat-icon hero-truck")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(<span class="lui-dt-stat-sub">Last 24 hours</span>)
  end

  test "stat_grid requires slot labels and accepts values from attributes or inner content" do
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

    [stat_slot] = Stat.__components__().stat_grid.slots
    label_attr = Enum.find(stat_slot.attrs, &(&1.name == :label))
    value_attr = Enum.find(stat_slot.attrs, &(&1.name == :value))
    assert label_attr.required
    refute value_attr.required
  end

  test "long unbroken values retain their content and have narrow-width wrapping styles" do
    value = String.duplicate("LONGUNBROKENVALUE", 20)

    html =
      render(
        fn assigns ->
          ~H"""
          <Stat.stat_grid><:stat label="Identifier" value={@value} /></Stat.stat_grid>
          """
        end,
        %{value: value}
      )

    assert Floki.text(Floki.parse_fragment!(html)) =~ value

    css = File.read!("priv/static/lantern_ui.css")
    assert css =~ ~r/\.lui-dt-stat \{[^}]*min-width: 0;/
    assert css =~ ~r/\.lui-dt-stat-value \{[^}]*max-width: 100%;[^}]*overflow-wrap: anywhere;/
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

  test "stat_card renders a sparkline slot" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card id="stat-spark" label="Revenue" value="$42,500" tone="success">
          <:sparkline>
            <LanternUI.Charts.sparkline id="spark-rev" series={[10, 15, 20, 25, 30]} />
          </:sparkline>
        </Stat.stat_card>
        """
      end)

    assert html =~ ~s(data-tone="success")
    assert html =~ ~s(class="lui-dt-stat-sparkline")
    assert html =~ ~s(id="spark-rev")
    assert html =~ "<svg"
  end

  test "stat_card renders a sparkline from sparkline_series attribute with currentColor tone" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card
          id="stat-series"
          label="Conversion"
          value="4.2%"
          tone="promo"
          sparkline_series={[1, 3, 2, 5, 4]}
        />
        """
      end)

    assert html =~ ~s(data-tone="promo")
    assert html =~ ~s(class="lui-dt-stat-sparkline")
    assert html =~ ~s(id="stat-series-spark")
    assert html =~ ~s(color:currentColor)
    assert html =~ ~s(aria-hidden="true")
  end

  test "sparkline is decorative by default and can be named when informative" do
    decorative =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card label="Revenue" value="42" sparkline_series={[1, 2, 3]} />
        """
      end)

    assert decorative =~ ~s(class="lui-dt-stat-sparkline" aria-hidden="true")

    informative =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card
          label="Revenue"
          value="42"
          sparkline_series={[1, 2, 3]}
          sparkline_label="Revenue trend over three months"
        />
        """
      end)

    assert informative =~ ~s(role="img" aria-label="Revenue trend over three months")
    refute informative =~ ~s(aria-hidden="true")
  end

  test "stat_card supports all semantic tones and normalizes atoms" do
    for tone <- [:neutral, :info, :success, :warning, :danger, :promo] do
      html =
        render(
          fn assigns ->
            ~H"""
            <Stat.stat_card label="Metric" value="100" tone={@tone} />
            """
          end,
          %{tone: tone}
        )

      assert html =~ ~s(data-tone="#{tone}")
    end

    untoned =
      render(fn assigns ->
        ~H"""
        <Stat.stat_card label="Metric" value="100" />
        """
      end)

    refute untoned =~ "data-tone"
  end

  test "tone accents use theme tokens while text keeps contrast-safe foreground tokens" do
    css = File.read!("priv/static/lantern_ui.css")
    assert css =~ ~r/\.lui-dt-stat-value[^}]*color: var\(--lantern-fg\)/
    assert css =~ ~r/\.lui-dt-stat-sub[^}]*color: var\(--lantern-fg-muted\)/
    refute css =~ ~r/\.lui-dt-stat\[data-tone\] \.lui-dt-stat-sub/

    tone_rules =
      Regex.scan(~r/\.lui-dt-stat\[data-tone="[^"]+"\]\s*\{([^}]+)\}/, css,
        capture: :all_but_first
      )
      |> List.flatten()
      |> Enum.join(" ")

    refute tone_rules =~ ~r/#[0-9a-f]{3,8}/i
    assert tone_rules =~ "--lantern-info"
    assert tone_rules =~ "--lantern-success"
    assert tone_rules =~ "--lantern-warning"
    assert tone_rules =~ "--lantern-danger"
    assert tone_rules =~ "--lantern-accent"
  end

  test "stat_grid slot forwards tone and sparkline_series" do
    html =
      render(fn assigns ->
        ~H"""
        <Stat.stat_grid id="slotted-grid">
          <:stat label="Slotted" value="99" tone="warning" sparkline_series={[1, 2, 3]} />
        </Stat.stat_grid>
        """
      end)

    assert html =~ ~s(data-tone="warning")
    assert html =~ ~s(class="lui-dt-stat-sparkline")
    assert html =~ "<svg"
  end
end
