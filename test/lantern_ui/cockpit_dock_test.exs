defmodule LanternUI.CockpitDockTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  use LanternUI, only: [:cockpit_dock]

  defp fixture(assigns) do
    ~H"""
    <.cockpit_dock id="dock" label="Cockpit" open={@open} view={@view} class="extra" data-testid="d">
      <:header>
        <h2>Cockpit</h2>
      </:header>
      <:list><button>Open chat</button></:list>
      <:thread :if={@thread}><textarea>draft</textarea></:thread>
    </.cockpit_dock>
    """
  end

  defp doc(open, view, thread \\ true),
    do:
      %{__changed__: nil, open: open, view: view, thread: thread}
      |> fixture()
      |> rendered_to_string()
      |> Floki.parse_fragment!()

  test "landmark, name, classes and passthrough" do
    d = doc(true, "list")
    assert LanternUI.__components__()[:cockpit_dock] == LanternUI.Components.CockpitDock
    root = Floki.find(d, "aside#dock")
    assert Floki.attribute(root, "aria-label") == ["Cockpit"]
    assert Floki.attribute(root, "class") == ["lui-side-panel lui-cockpit-dock extra"]
    assert Floki.attribute(root, "data-testid") == ["d"]
    assert Floki.attribute(root, "hidden") == []
    assert Floki.text(Floki.find(d, "[data-part=header]")) =~ "Cockpit"
  end

  test "closed dock is hidden for everyone" do
    assert Floki.attribute(Floki.find(doc(false, "list"), "#dock"), "hidden") == ["hidden"]
  end

  test "view switches visibility; both stay mounted so drafts survive" do
    d = doc(true, "thread")
    assert Floki.attribute(Floki.find(d, "#dock-list"), "hidden") == ["hidden"]
    assert Floki.attribute(Floki.find(d, "#dock-thread"), "hidden") == []
    assert Floki.attribute(Floki.find(d, "#dock"), "data-view") == ["thread"]
    assert Floki.text(Floki.find(d, "#dock-thread textarea")) == "draft"

    d = doc(true, "list")
    assert Floki.attribute(Floki.find(d, "#dock-list"), "hidden") == []
    assert Floki.attribute(Floki.find(d, "#dock-thread"), "hidden") == ["hidden"]
  end

  test "thread view without a thread slot falls back to the list" do
    d = doc(true, "thread", false)
    assert Floki.attribute(Floki.find(d, "#dock-list"), "hidden") == []
    assert Floki.find(d, "#dock-thread") == []
    assert Floki.attribute(Floki.find(d, "#dock"), "data-view") == ["list"]
  end
end
