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

    test "item without new options renders identical baseline markup" do
      # Frozen contract from 8ac5d64: no details, no leading at, no marker slot,
      # no data-label-position. Existing call sites (e.g. flicker activity rail) stay stable.
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item status={:done} label="Deployed" at="2h ago" title="enventory" />
          </Timeline.timeline>
          """
        end)

      expected = """
      <ol class="lui-timeline">
        
        <li class="lui-timeline-item" data-status="done">
        <div class="lui-timeline-marker" aria-hidden="true">
          
            <span class="lui-timeline-dot"></span>
          
          <span class="lui-timeline-connector"></span>
        </div>
        <div class="lui-timeline-content">
          <span class="lui-timeline-title">enventory</span>
          <span class="lui-timeline-label">Deployed</span>
          <span class="lui-timeline-at">2h ago</span>
          
        </div>
      </li>

      </ol>
      """

      assert normalize_ws(html) == normalize_ws(expected)
      refute html =~ "<details"
      refute html =~ "data-label-position"
      refute html =~ "data-slot"
      refute html =~ "lui-timeline-detail"
    end

    test "detail slot produces details/summary and open respects the attr" do
      closed =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="foodfeed" label="Deploying" at="40s" status={:active}>
              <:detail>
                <pre>==> Building release</pre>
              </:detail>
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      open =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="foodfeed" label="Deploying" at="40s" status={:active} open>
              <:detail>
                <pre>==> Building release</pre>
              </:detail>
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      closed_doc = Floki.parse_fragment!(closed)
      open_doc = Floki.parse_fragment!(open)

      assert Floki.find(closed_doc, "details.lui-timeline-details") != []
      assert Floki.find(closed_doc, "summary.lui-timeline-summary") != []
      assert Floki.find(closed_doc, ".lui-timeline-detail") != []
      assert Floki.text(Floki.find(closed_doc, "summary")) =~ "foodfeed"
      assert Floki.text(Floki.find(closed_doc, "summary")) =~ "Deploying"
      assert Floki.text(Floki.find(closed_doc, ".lui-timeline-detail")) =~ "Building release"

      # at stays in the summary for inline position
      assert Floki.find(closed_doc, "summary .lui-timeline-at") != []

      # closed: no open attribute; open: present
      [closed_details] = Floki.find(closed_doc, "details.lui-timeline-details")
      [open_details] = Floki.find(open_doc, "details.lui-timeline-details")
      refute List.keyfind(elem(closed_details, 1), "open", 0)
      assert List.keyfind(elem(open_details, 1), "open", 0)
    end

    test "without detail slot there is no details element" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="plain" label="Queued" at="now">
              Waiting on the build.
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      refute html =~ "<details"
      refute html =~ "<summary"
      refute html =~ "lui-timeline-detail"
      assert html =~ "lui-timeline-body"
      assert html =~ "Waiting on the build."
    end

    test "label_position leading moves at out of content and inherits from timeline" do
      html =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline label_position={:leading}>
            <Timeline.timeline_item title="enventory" label="Deployed" at="2h ago" status={:done} />
            <Timeline.timeline_item
              title="override-inline"
              label="Active"
              at="now"
              status={:active}
              label_position={:inline}
            />
          </Timeline.timeline>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [leading, inline] = Floki.find(doc, "li.lui-timeline-item")

      assert Floki.attribute(leading, "data-label-position") == ["leading"]
      # at is outside content (direct child of the item), not inside the content grid
      assert Floki.find(leading, ".lui-timeline-content .lui-timeline-at") == []
      assert Floki.find(leading, ".lui-timeline-at") != []
      assert Floki.text(Floki.find(leading, ".lui-timeline-at")) =~ "2h ago"

      # item override wins over parent inheritance
      assert Floki.attribute(inline, "data-label-position") == []
      assert Floki.find(inline, ".lui-timeline-content .lui-timeline-at") != []

      # host-tunable column width is declared
      css = File.read!("priv/static/lantern_ui.css")
      assert css =~ "--lui-timeline-label-w"
    end

    test "marker slot wins over icon and over the status dot" do
      over_icon =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="avatar" icon="check-circle" status={:done}>
              <:marker>
                <img src="/avatar.png" alt="" />
              </:marker>
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      over_dot =
        render(fn assigns ->
          ~H"""
          <Timeline.timeline>
            <Timeline.timeline_item title="avatar" status={:active}>
              <:marker>
                <span class="custom-marker">G</span>
              </:marker>
            </Timeline.timeline_item>
          </Timeline.timeline>
          """
        end)

      icon_doc = Floki.parse_fragment!(over_icon)
      dot_doc = Floki.parse_fragment!(over_dot)

      assert Floki.find(icon_doc, ".lui-timeline-dot[data-slot='marker']") != []
      assert Floki.find(icon_doc, ".lui-timeline-dot[data-slot='marker'] img") != []
      # icon must not render when marker slot is present
      refute Floki.find(icon_doc, ".lui-timeline-dot svg.lui-icon") != []

      assert Floki.find(dot_doc, ".lui-timeline-dot[data-slot='marker'] .custom-marker") != []
      assert Floki.text(Floki.find(dot_doc, ".custom-marker")) =~ "G"
      # plain empty dot is replaced by slotted content
      refute over_dot =~ ~s(<span class="lui-timeline-dot"></span>)
    end
  end

  defp normalize_ws(html) do
    html
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
