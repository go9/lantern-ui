defmodule LanternUI.SplitPaneTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  use LanternUI, only: [:split_pane]

  defp fixture(assigns) do
    ~H"""
    <.split_pane
      id="reports"
      label="Report list width"
      size={@size}
      min={20}
      max={80}
      mobile_pane="secondary"
      storage_key="user:project"
      class="extra"
      data-testid="split"
    >
      <:primary><button>Choose report</button></:primary>
      <:secondary>
        <h2>Report detail</h2>
      </:secondary>
    </.split_pane>
    """
  end

  test "imported component renders slots, stable parts, scoped storage and passthrough" do
    assert LanternUI.__components__()[:split_pane] == LanternUI.Components.SplitPane

    doc =
      fixture(%{__changed__: nil, size: 35}) |> rendered_to_string() |> Floki.parse_fragment!()

    assert Floki.attribute(Floki.find(doc, "#reports"), "class") == ["lui-split-pane extra"]
    assert Floki.attribute(Floki.find(doc, "#reports"), "phx-hook") == ["LanternSplitPane"]
    assert Floki.attribute(Floki.find(doc, "#reports"), "data-testid") == ["split"]
    assert Floki.attribute(Floki.find(doc, "#reports"), "data-storage-key") == ["user:project"]
    assert Floki.attribute(Floki.find(doc, "#reports"), "data-mobile-pane") == ["secondary"]
    assert Floki.text(Floki.find(doc, "#reports-primary")) =~ "Choose report"
    assert Floki.text(Floki.find(doc, "#reports-secondary")) =~ "Report detail"
    separator = Floki.find(doc, "[role=separator]")

    for {attr, value} <- [
          {"aria-label", "Report list width"},
          {"aria-orientation", "vertical"},
          {"aria-valuemin", "20"},
          {"aria-valuemax", "80"},
          {"aria-valuenow", "35"},
          {"tabindex", "0"}
        ] do
      assert Floki.attribute(separator, attr) == [value]
    end

    [target] = Floki.attribute(separator, "aria-controls")
    assert length(Floki.find(doc, "##{target}")) == 1
    assert Floki.attribute(separator, "phx-mounted") |> hd() =~ "ignore_attrs"

    assert Floki.attribute(Floki.find(doc, "#reports-primary"), "style") == [
             "--lantern-split-size: 0.35"
           ]
  end

  test "rejects invalid initial bounds instead of rendering an invalid ARIA range" do
    for size <- [0, 90] do
      assert_raise ArgumentError, ~r/0 < min <= size <= max < 100/, fn ->
        fixture(%{__changed__: nil, size: size}) |> rendered_to_string()
      end
    end
  end
end
