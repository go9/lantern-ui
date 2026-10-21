defmodule LanternUI.FunnelLineTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  use LanternUI, only: [:funnel_line]
  alias LanternUI.ARIAConformance

  defp render(assigns \\ %{}) do
    assigns =
      Map.merge(%{__changed__: nil, value: "needs", snoozed: 1, held: 0, primary: 7}, assigns)

    ~H"""
    <.funnel_line
      id="reports"
      label="Where reports are"
      value={@value}
      on_change="filter"
      target="#inbox"
      class="host-line"
      data-testid="filter-line"
    >
      <:stage value="needs" label="Needs you" count={@primary} />
      <:stage value="work" label="In work" count={2} />
      <:stage value="shipped" label="Shipped" count={1} />
      <:stage value="told" label="Told" count={0} />
      <:stage value="snoozed" label="Snoozed" count={@snoozed} overflow />
      <:stage value="held" label="Held" count={@held} overflow />
    </.funnel_line>
    """
    |> rendered_to_string()
  end

  test "public registry imports a named group with counted native filter buttons" do
    assert LanternUI.__components__().funnel_line == LanternUI.Components.FunnelLine
    html = render()
    doc = Floki.parse_fragment!(html)
    [group] = Floki.find(doc, "#reports")
    assert Floki.attribute(group, "class") == ["lui-funnel-line host-line"]
    assert Floki.attribute(group, "role") == ["group"]
    assert Floki.attribute(group, "aria-label") == ["Where reports are"]
    assert Floki.attribute(group, "data-testid") == ["filter-line"]
    buttons = Floki.find(group, "button")

    assert Enum.map(buttons, &(Floki.text(&1) |> String.split() |> Enum.join(" "))) ==
             ["Needs you 7", "In work 2", "Shipped 1", "Told 0", "Snoozed 1"]

    assert Floki.attribute(buttons, "type") == List.duplicate("button", 5)

    assert Floki.attribute(buttons, "aria-pressed") == [
             "true",
             "false",
             "false",
             "false",
             "false"
           ]

    assert Floki.find(doc, "[role=tab], [role=tabpanel], [phx-hook], [tabindex]") == []
    assert ARIAConformance.audit(html) == []
  end

  test "each button sends its own key to the server and optional LiveComponent target" do
    doc = render() |> Floki.parse_fragment!()
    buttons = Floki.find(doc, "button")
    assert Floki.attribute(buttons, "phx-click") == List.duplicate("filter", 5)
    assert Floki.attribute(buttons, "phx-target") == List.duplicate("#inbox", 5)
    assert Floki.attribute(buttons, "value") == ~w(needs work shipped told snoozed)
  end

  test "server selection changes exactly one pressed button" do
    doc = render(%{value: "work"}) |> Floki.parse_fragment!()

    assert Floki.attribute(Floki.find(doc, "button[aria-pressed=true]"), "value") == [
             "work"
           ]

    assert length(Floki.find(doc, "button[aria-pressed=false]")) == 4
  end

  test "zero primary counts remain; empty overflow stages and their divider disappear" do
    doc = render(%{primary: 0, snoozed: 0}) |> Floki.parse_fragment!()
    assert length(Floki.find(doc, "button")) == 4
    assert Floki.find(doc, "[data-overflow=true]") == []
    assert Floki.text(Floki.find(doc, "button") |> hd()) =~ "0"
    arrows = Floki.find(doc, ".lui-funnel-arrow")
    assert length(arrows) == 3
    assert Floki.attribute(arrows, "aria-hidden") == ["true", "true", "true"]
  end

  test "selected overflow remains at zero so the user can leave it" do
    html = render(%{value: "snoozed", snoozed: 0})
    doc = Floki.parse_fragment!(html)
    assert length(Floki.find(doc, "[data-overflow=true]")) == 1
    [selected] = Floki.find(doc, "button[aria-pressed=true]")
    assert Floki.attribute(selected, "value") == ["snoozed"]
    assert Floki.text(selected) =~ "0"
    assert ARIAConformance.audit(html) == []
  end

  test "stable encoded keys survive reorder; primary stages precede overflow and labels escape" do
    render_order = fn stages ->
      assigns = %{__changed__: nil, stages: stages}

      ~H"""
      <.funnel_line id="order" label="Filters" value="a b" on_change={%Phoenix.LiveView.JS{}}>
        <:stage
          :for={stage <- @stages}
          value={stage.key}
          label={stage.label}
          count={1}
          overflow={stage.overflow}
        />
      </.funnel_line>
      """
      |> rendered_to_string()
      |> Floki.parse_fragment!()
    end

    a = %{key: "a b", label: "<script>unsafe</script>", overflow: false}
    b = %{key: "secondary", label: "Other", overflow: true}
    c = %{key: "c", label: "Primary", overflow: false}
    before = render_order.([b, a, c])
    after_doc = render_order.([c, b, a])
    selected_id = Floki.attribute(Floki.find(before, "[aria-pressed=true]"), "id")
    assert selected_id == Floki.attribute(Floki.find(after_doc, "[aria-pressed=true]"), "id")
    assert selected_id == ["order-stage-YSBi"]

    assert Floki.attribute(Floki.find(before, "button"), "value") == [
             "a b",
             "c",
             "secondary"
           ]

    assert Floki.find(before, "script") == []
    assert Floki.text(before) =~ "<script>unsafe</script>"
    assert Floki.attribute(Floki.find(before, "button"), "phx-target") == []
  end

  test "negative and non-integer counts fail with a useful contract error" do
    for count <- [-1, 1.2, "7", nil] do
      assert_raise ArgumentError, ~r/non-negative integer/, fn -> render(%{primary: count}) end
    end
  end

  test "duplicate keys are rejected instead of producing ambiguous selection and duplicate ids" do
    assigns = %{__changed__: nil}

    assert_raise ArgumentError, ~r/values must be unique/, fn ->
      ~H"""
      <.funnel_line id="bad" label="Filters" value="same" on_change="filter">
        <:stage value="same" label="First" count={1} />
        <:stage value="same" label="Second" count={2} />
      </.funnel_line>
      """
      |> rendered_to_string()
    end
  end
end
