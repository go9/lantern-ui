defmodule LanternUI.ProvenanceBadgeTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1, render_component: 2]
  use LanternUI, only: [:provenance_badge, :button]

  alias LanternUI.Components.ProvenanceBadge

  defp example(assigns) do
    ~H"""
    <.provenance_badge
      id="origin"
      state={@state}
      source={@source}
      class={["custom", @extra_class]}
      aria-describedby="context"
      data-record="api"
    >
      <:revert>
        <.button
          id="revert-api"
          size="xs"
          variant="ghost"
          type="button"
          label="Revert API branch to Production"
          phx-click="revert"
          phx-value-id="api"
        >
          Revert
        </.button>
      </:revert>
    </.provenance_badge>
    <span id="context">API branch</span>
    """
  end

  defp doc(state, source \\ "Production") do
    example(%{__changed__: nil, state: state, source: source, extra_class: "extra"})
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  test "import registry exposes exactly the new component" do
    assert LanternUI.__components__().provenance_badge == ProvenanceBadge
    assert LanternUI.__component_imports__(ProvenanceBadge) == [provenance_badge: 1]
  end

  test "all origin and temporal states have visible words, without relying on color or tooltips" do
    for {state, label} <- [
          {"own", "Own"},
          {"inherited", "Inherited from Production"},
          {"override", "Override of Production"},
          {"current", "Current"},
          {"historical", "Historical (superseded)"},
          {"unknown", "Unknown"}
        ] do
      tree = doc(state)
      assert Floki.attribute(tree, "#origin", "data-state") == [state]
      assert tree |> Floki.find("#origin .lui-badge") |> Floki.text() |> String.trim() == label
      assert Floki.attribute(tree, "#origin .lui-badge", "data-size") == ["sm"]
      assert Floki.find(tree, "[role], [tabindex], [aria-hidden], [phx-hook], [title]") == []
      assert Floki.attribute(tree, "#origin", "aria-describedby") == ["context"]
      assert Floki.find(tree, "#context") != []
      assert Floki.find(tree, "#origin.custom.extra[data-record=api]") != []
    end
  end

  test "absent, nil and unrecognized runtime states never claim evidence is current" do
    for attrs <- [[], [state: nil], [state: "future"], [state: ""]] do
      tree =
        render_component(&ProvenanceBadge.provenance_badge/1, attrs) |> Floki.parse_fragment!()

      assert Floki.attribute(tree, ".lui-provenance-badge", "data-state") == ["unknown"]
      assert String.trim(Floki.text(tree)) == "Unknown"
      assert Floki.find(tree, "button, a, [tabindex], [aria-current]") == []
    end
  end

  test "revert is a native named button only on overrides, with caller event and identity" do
    tree = doc("override")
    assert Floki.attribute(tree, "#revert-api", "type") == ["button"]

    assert Floki.attribute(tree, "#revert-api", "aria-label") == [
             "Revert API branch to Production"
           ]

    assert Floki.attribute(tree, "#revert-api", "phx-click") == ["revert"]
    assert Floki.attribute(tree, "#revert-api", "phx-value-id") == ["api"]
    assert Floki.find(tree, "button[disabled], button[tabindex]") == []

    for state <- ~w(own inherited current historical unknown invalid) do
      assert Floki.find(doc(state), "#revert-api") == []
    end

    tree =
      render_component(&ProvenanceBadge.provenance_badge/1, state: "override")
      |> Floki.parse_fragment!()

    assert Floki.find(tree, "button") == []
  end

  test "source is optional, escaped, and applies only to inheritance states" do
    for state <- ~w(inherited override), source <- [nil, "", " "] do
      label = if state == "inherited", do: "Inherited", else: "Override"

      assert doc(state, source) |> Floki.find(".lui-badge") |> Floki.text() |> String.trim() ==
               label
    end

    tree = doc("inherited", "<script>parent</script>")
    assert Floki.find(tree, "script") == []

    assert tree |> Floki.find(".lui-badge") |> Floki.text() |> String.trim() ==
             "Inherited from <script>parent</script>"

    for state <- ~w(own current historical unknown) do
      refute doc(state)
             |> Floki.find(".lui-badge")
             |> Floki.text()
             |> String.contains?("Production")
    end
  end
end
