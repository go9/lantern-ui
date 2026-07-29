defmodule LanternUI.TimelineTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Timeline

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "timeline/1 + timeline_item/1" do
    test "renders an ordered list with one li per item" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="one" />
            <Timeline.timeline_item title="two" />
            <Timeline.timeline_item title="three" />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [{"ol", attrs, _}] = Floki.find(doc, "ol.lui-timeline")
      assert {"class", class} = List.keyfind(attrs, "class", 0)
      assert class =~ "lui-timeline"

      items = Floki.find(doc, "ol.lui-timeline > li.lui-timeline-item")
      assert length(items) == 3
      assert Floki.text(Enum.at(items, 0)) =~ "one"
      assert Floki.text(Enum.at(items, 1)) =~ "two"
      assert Floki.text(Enum.at(items, 2)) =~ "three"
    end

    test "data-status lands on the item and the state label text renders" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item status={:done} label="Deployed" title="enventory" at="2h ago" />
            <Timeline.timeline_item status={:active} label="Deploying" title="foodfeed" />
            <Timeline.timeline_item status={:danger} label="Failed" title="skusync" />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      items = Floki.find(doc, "li.lui-timeline-item")

      assert Floki.attribute(Enum.at(items, 0), "data-status") == ["done"]
      assert Floki.attribute(Enum.at(items, 1), "data-status") == ["active"]
      assert Floki.attribute(Enum.at(items, 2), "data-status") == ["danger"]

      # Grayscale legibility: state words are text, not color alone
      assert html =~ ~s(class="lui-timeline-label")
      assert html =~ "Deployed"
      assert html =~ "Deploying"
      assert html =~ "Failed"
      assert html =~ ~s(class="lui-timeline-at")
      assert html =~ "2h ago"
    end

    test "connector is present on non-last items and hidden on the last via CSS" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="a" />
            <Timeline.timeline_item title="b" />
            <Timeline.timeline_item title="c" />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      connectors = Floki.find(doc, "li.lui-timeline-item .lui-timeline-connector")
      assert length(connectors) == 3

      # Last-item absence is CSS-owned (:last-child), not a caller flag
      css = File.read!("priv/static/lantern_ui.css")

      assert css =~
               ~r/\.lui-timeline-item:last-child\s+\.lui-timeline-connector\s*\{[^}]*display:\s*none/
    end

    test "icon replaces the plain dot when given" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="with-icon" icon="check-circle" />
            <Timeline.timeline_item title="plain-dot" />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [with_icon, plain] = Floki.find(doc, "li.lui-timeline-item")

      assert Floki.find(with_icon, ".lui-timeline-dot svg.lui-icon") != []
      # check-circle path fragment from the icon set
      assert Floki.raw_html(with_icon) =~ "M9 12.75"

      assert Floki.find(plain, ".lui-timeline-dot svg") == []
      assert Floki.find(plain, ".lui-timeline-dot") != []
    end

    test "empty item still renders its marker" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "li.lui-timeline-item .lui-timeline-marker") != []
      assert Floki.find(doc, "li.lui-timeline-item .lui-timeline-dot") != []
      refute html =~ "lui-timeline-title"
      refute html =~ "lui-timeline-label"
      refute html =~ "lui-timeline-at"
      refute html =~ "lui-timeline-body"
    end

    test "optional body slot and class merge" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline class="rail-extra">
            <Timeline.timeline_item class="item-extra" title="enventory" status={:pending} label="Queued">
              Waiting on the build.
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      assert html =~ ~s(class="lui-timeline rail-extra")
      assert html =~ ~s(class="lui-timeline-item item-extra")
      assert html =~ ~s(class="lui-timeline-body")
      assert html =~ "Waiting on the build."
    end

    test "registry imports expose both public functions" do
      assert {:timeline, Timeline} in LanternUI.__components__()
      assert {:timeline, 1} in Timeline.__info__(:functions)
      assert {:timeline_item, 1} in Timeline.__info__(:functions)
    end

    test "default status is neutral" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="x" />
          </Timeline.timeline>
          """
        end)

      assert html =~ ~s(data-status="neutral")
    end
  end
end
