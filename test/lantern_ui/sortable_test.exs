defmodule LanternUI.SortableTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Sortable

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()

  test "sortable/1 renders the hook root contract" do
    html =
      render(fn assigns ->
        ~H"""
        <Sortable.sortable id="col-1" key="1" group="board" event="drop" reorder phx-target="#x">
          <div data-part="item" data-id="9" draggable="true">x</div>
        </Sortable.sortable>
        """
      end)

    assert html =~ ~s(id="col-1")
    assert html =~ ~s(class="lui-sortable")
    assert html =~ ~s(phx-hook="LanternSortable")
    assert html =~ ~s(data-key="1")
    assert html =~ ~s(data-group="board")
    assert html =~ ~s(data-event="drop")
    assert html =~ ~s(data-reorder)
    assert html =~ ~s(phx-target="#x")
  end

  test "drop_zone/1 renders the landing part, variants and the action slot" do
    html =
      render(fn assigns ->
        ~H"""
        <Sortable.drop_zone variant="target">
          Scans land here
          <:action><button>x</button></:action>
        </Sortable.drop_zone>
        <Sortable.drop_zone>Drop here</Sortable.drop_zone>
        """
      end)

    assert html =~ ~s(data-part="drop-zone")
    assert html =~ ~s(data-variant="target")
    assert html =~ ~s(data-variant="default")
    assert html =~ ~s(class="lui-drop-zone-action")
    assert html =~ "Scans land here"
  end

  test "the module is registered, so `use LanternUI` imports sortable/1 and drop_zone/1" do
    assert LanternUI.__components__()[:sortable] == Sortable
  end
end
