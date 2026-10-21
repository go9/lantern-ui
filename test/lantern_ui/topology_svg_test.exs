defmodule LanternUI.TopologySvgTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LanternUI, only: [:topology_svg]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @nodes [
    %{id: "web", label: "web", detail: "Flicker", state: :degraded},
    %{id: "primary", label: "primary", column: 1},
    %{id: "docs", label: "docs", detail: "not on dev", column: 1, state: :absent}
  ]
  @edges [
    %{from: "web", to: "primary", label: "DATABASE_URL"},
    %{from: "web", to: "docs"}
  ]

  defp render(extra \\ %{}) do
    assigns =
      Map.merge(%{__changed__: nil, nodes: @nodes, edges: @edges, selected: "primary"}, extra)

    ~H"""
    <.topology_svg
      id="topo"
      class="extra"
      label="Resources on dev"
      on_select="pick"
      selected={@selected}
      nodes={@nodes}
      edges={@edges}
      data-x="1"
    />
    """
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  test "renders a labelled focusable scroll region with passthrough" do
    doc = render()
    [root] = Floki.find(doc, "div#topo.lui-topology.extra")
    assert Floki.attribute(root, "role") == ["region"]
    assert Floki.attribute(root, "aria-label") == ["Resources on dev"]
    assert Floki.attribute(root, "tabindex") == ["0"]
    assert Floki.attribute(root, "data-x") == ["1"]
  end

  test "every node is a native button with pressed state and event payload" do
    doc = render()
    buttons = Floki.find(doc, "button.lui-topology-node")
    assert length(buttons) == 3
    assert Enum.all?(buttons, &(Floki.attribute(&1, "type") == ["button"]))
    assert Enum.all?(buttons, &(Floki.attribute(&1, "phx-click") == ["pick"]))

    pressed =
      Map.new(
        buttons,
        &{hd(Floki.attribute(&1, "data-node")), hd(Floki.attribute(&1, "aria-pressed"))}
      )

    assert pressed == %{"web" => "false", "primary" => "true", "docs" => "false"}
    assert Floki.attribute(hd(Floki.find(doc, "[data-node=web]")), "phx-value-node") == ["web"]
  end

  test "state is in words and attributes, not colour alone" do
    doc = render()
    assert Floki.text(Floki.find(doc, "[data-node=web]")) =~ ", degraded"
    assert Floki.text(Floki.find(doc, "[data-node=docs]")) =~ ", not present"
    assert Floki.attribute(hd(Floki.find(doc, "[data-node=docs]")), "data-state") == ["absent"]
    refute Floki.text(Floki.find(doc, "[data-node=primary]")) =~ ", "
  end

  test "edges are decorative, dashed to absent nodes, and listed for screen readers" do
    doc = render()
    edges = Floki.find(doc, "g.lui-topology-edge")
    assert Enum.all?(edges, &(Floki.attribute(&1, "aria-hidden") == ["true"]))
    assert Enum.map(edges, &hd(Floki.attribute(&1, "data-dashed"))) == ["false", "true"]
    assert Floki.text(Floki.find(doc, "g.lui-topology-edge text")) == "DATABASE_URL"

    [list] = Floki.find(doc, "ul.lui-sr-only[aria-label=Connections]")
    assert Floki.text(list) =~ "web connects to primary via DATABASE_URL"
    assert Floki.text(list) =~ "web connects to docs"
  end

  test "no edge list when there are no edges" do
    assert Floki.find(render(%{edges: []}), "ul.lui-sr-only") == []
  end

  test "invalid graphs raise" do
    bad = fn nodes, edges ->
      assert_raise ArgumentError, ~r/topology_svg/, fn ->
        render(%{nodes: nodes, edges: edges})
      end
    end

    bad.([], [])
    bad.([%{id: "a", label: " "}], [])
    bad.([%{id: "a", label: "a"}, %{id: "a", label: "b"}], [])
    bad.([%{id: "a", label: "a", state: :weird}], [])
    bad.(@nodes, [%{from: "web", to: "nope"}])
    bad.(@nodes, [%{from: "primary", to: "web"}])
    bad.(@nodes, [%{from: "primary", to: "docs"}])
  end
end
