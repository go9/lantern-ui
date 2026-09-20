defmodule LanternUI.DenseAppTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.GroupBand
  alias LanternUI.Components.IconButton
  alias LanternUI.Components.Inspector
  alias LanternUI.Components.ListRow
  alias LanternUI.Components.ProgressRing
  alias LanternUI.Components.Segmented
  alias LanternUI.Components.SidePanel
  alias LanternUI.Components.StateGlyph

  defmodule ImporterFixture do
    use Phoenix.Component

    use LanternUI,
      only: [
        :icon,
        :list_row,
        :group_band,
        :inspector,
        :icon_button,
        :segmented,
        :state_glyph,
        :progress_ring,
        :side_panel
      ]

    def representative(assigns) do
      ~H"""
      <.list_row title="Row" />
      <.group_band name="In progress" />
      <.inspector aria-label="Properties">
        <.inspector_section title="Meta">
          <.property_row label="Repo">demo</.property_row>
        </.inspector_section>
      </.inspector>
      <.icon_button label="New" tooltip={false}><.icon name="plus" /></.icon_button>
      <.segmented id="scope-imp" value="all" label="View">
        <:segment value="all">All</:segment>
      </.segmented>
      <.status_glyph status={:done} />
      <.priority_glyph priority={:high} />
      <.progress_ring value={7} max={19} />
      <.side_panel id="panel-imp" open>Body</.side_panel>
      """
    end
  end

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "list_row/1" do
    test "renders title, identifier, parent prefix, and slots" do
      html =
        render(fn assigns ->
          ~H"""
          <ListRow.list_row identifier="#241" title="Visible ring" parent="Primitives">
            <:leading><span class="lead">L</span></:leading>
            <:meta><span class="chip">ui</span></:meta>
            <:trailing>Sep 3</:trailing>
          </ListRow.list_row>
          """
        end)

      assert html =~ ~s(class="lui-list-row")
      assert html =~ ~s(class="lui-list-row-id")
      assert html =~ "#241"
      assert html =~ "Primitives ›"
      assert html =~ "Visible ring"
      assert html =~ "lead"
      assert html =~ "ui"
      assert html =~ "Sep 3"
      refute html =~ "<a"
    end

    test "navigate/patch/href make the row a link; selected sets data-selected" do
      nav =
        render(fn assigns ->
          ~H"""
          <ListRow.list_row title="Go" navigate="/t/1" selected />
          """
        end)

      doc = Floki.parse_fragment!(nav)
      assert Floki.find(doc, "a.lui-list-row") != []
      assert Floki.attribute(Floki.find(doc, "a.lui-list-row"), "href") == ["/t/1"]
      assert Floki.find(doc, "a.lui-list-row[data-selected]") != []
    end
  end

  describe "group_band/1" do
    test "renders name, count, glyph, and a plus action" do
      html =
        render(fn assigns ->
          ~H"""
          <GroupBand.group_band name="In progress" count={12}>
            <:glyph><span class="g">G</span></:glyph>
            <:action navigate="/new" label="New ticket in In progress">+</:action>
          </GroupBand.group_band>
          """
        end)

      assert html =~ "lui-group-band"
      assert html =~ "In progress"
      assert html =~ "12"
      assert html =~ "g"
      assert html =~ ~s(aria-label="New ticket in In progress")
      assert html =~ ~s(href="/new")
      refute html =~ "data-collapsed"
    end

    test "collapsed band with patch is an expand link and uses the right chevron" do
      html =
        render(fn assigns ->
          ~H"""
          <GroupBand.group_band name="Done" count={40} collapsed patch="/tickets?show_done=1" />
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "[data-collapsed]") != []
      assert Floki.find(doc, "a.lui-group-band-main") != []

      assert Floki.attribute(Floki.find(doc, "a.lui-group-band-main"), "href") == [
               "/tickets?show_done=1"
             ]
    end
  end

  describe "inspector/1 + property_row/1" do
    test "section heading and label/value rows wrap a dl" do
      html =
        render(fn assigns ->
          ~H"""
          <Inspector.inspector aria-label="Ticket">
            <Inspector.inspector_section title="Properties">
              <Inspector.property_row label="Repo">enventory_new</Inspector.property_row>
              <Inspector.property_row label="Status">
                <button type="button">In progress</button>
              </Inspector.property_row>
            </Inspector.inspector_section>
          </Inspector.inspector>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "aside.lui-inspector") != []
      assert Floki.text(Floki.find(doc, ".lui-inspector-heading")) =~ "Properties"
      assert Floki.find(doc, "dl.lui-inspector-list") != []
      assert Floki.text(Floki.find(doc, ".lui-property-label")) =~ "Repo"
      assert Floki.text(Floki.find(doc, ".lui-property-value")) =~ "enventory_new"
      assert Floki.find(doc, ".lui-property-value button") != []
    end
  end

  describe "icon_button/1" do
    test "requires a label as aria-label and wraps a tooltip with optional kbd" do
      html =
        render(fn assigns ->
          ~H"""
          <IconButton.icon_button label="Toggle panel" kbd="]">
            x
          </IconButton.icon_button>
          """
        end)

      assert html =~ ~s(aria-label="Toggle panel")
      assert html =~ "lui-icon-btn"
      assert html =~ "lui-tooltip"
      assert html =~ ~s(class="lui-icon-btn-kbd")
      assert html =~ "]"
      assert html =~ ~s(data-size="icon")
      assert html =~ ~s(data-variant="ghost")
    end

    test "tooltip={false} skips the wrap; primary maps to solid; navigate is a link" do
      html =
        render(fn assigns ->
          ~H"""
          <IconButton.icon_button label="New" variant="primary" tooltip={false} navigate="/new">
            +
          </IconButton.icon_button>
          """
        end)

      refute html =~ "lui-tooltip"
      assert html =~ ~s(data-variant="solid")
      assert html =~ "<a"
      assert html =~ ~s(href="/new")
    end
  end

  describe "segmented/1" do
    test "marks the matching segment active and uses radiogroup/radio" do
      html =
        render(fn assigns ->
          ~H"""
          <Segmented.segmented id="scope" value="active" label="View">
            <:segment value="all" patch="/t">All</:segment>
            <:segment value="active" patch="/t?scope=active">Active</:segment>
            <:segment value="backlog" phx-click="set_scope">Backlog</:segment>
          </Segmented.segmented>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, ".lui-segmented"), "role") == ["radiogroup"]
      assert Floki.attribute(Floki.find(doc, ".lui-segmented"), "aria-label") == ["View"]
      assert html =~ ~s(phx-hook="LanternSegmented")

      items = Floki.find(doc, "[data-part=segment]")
      assert length(items) == 3
      assert Floki.attribute(Enum.at(items, 1), "aria-checked") == ["true"]
      assert Floki.attribute(Enum.at(items, 1), "class") |> hd() =~ "lui-segmented-item-active"
      assert Floki.attribute(Enum.at(items, 1), "tabindex") == ["0"]
      assert Floki.attribute(Enum.at(items, 0), "tabindex") == ["-1"]
      assert Floki.find(doc, "button[data-value=backlog]") != []
    end

    test "ARIA gate: labelled radiogroup is conformant" do
      html =
        render(fn assigns ->
          ~H"""
          <Segmented.segmented id="scope-a" value="all" label="View">
            <:segment value="all">All</:segment>
            <:segment value="active" phx-click="x">Active</:segment>
          </Segmented.segmented>
          """
        end)

      assert ARIAConformance.audit(html) == []
    end
  end

  describe "state_glyph/1" do
    test "status set: backlog dotted, todo empty, in_progress half, done check, cancelled x" do
      backlog =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="status" value="backlog" />
          """
        end)

      todo =
        render(fn assigns ->
          ~H"""
          <StateGlyph.status_glyph status={:todo} />
          """
        end)

      selected =
        render(fn assigns ->
          ~H"""
          <StateGlyph.status_glyph status={:selected_for_dev} />
          """
        end)

      progress =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="status" value={:in_progress} />
          """
        end)

      done =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="status" value="done" />
          """
        end)

      cancelled =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="status" value="cancelled" />
          """
        end)

      assert backlog =~ ~s(stroke-dasharray="1.6 2.2")
      refute todo =~ "stroke-dasharray"
      refute todo =~ "M7 3.5"
      assert selected =~ ~s(data-value="selected_for_dev")
      refute selected =~ "stroke-dasharray"
      assert progress =~ "M7 3.5a3.5 3.5 0 0 1 0 7z"
      assert done =~ "M4.4 7.2l1.8 1.8"
      assert cancelled =~ "M5 5l4 4"
      assert backlog =~ ~s(aria-hidden="true")
    end

    test "priority set: urgent badge, bars, none dashes, flicker alias" do
      urgent =
        render(fn assigns ->
          ~H"""
          <StateGlyph.priority_glyph priority={:urgent} />
          """
        end)

      high =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="priority" value="high" />
          """
        end)

      none =
        render(fn assigns ->
          ~H"""
          <StateGlyph.state_glyph kind="priority" value="none" />
          """
        end)

      assert urgent =~ ~s(data-kind="priority")
      assert urgent =~ ~s(data-value="urgent")
      assert urgent =~ "M7 3.6v4.2"
      assert high =~ ~s(opacity="1")
      assert none =~ "M2 7h2.5"
    end
  end

  describe "progress_ring/1" do
    test "value/max and completed/scope both produce a visible dasharray" do
      generic =
        render(fn assigns ->
          ~H"""
          <ProgressRing.progress_ring value={7} max={19} label="Completion" />
          """
        end)

      alias =
        render(fn assigns ->
          ~H"""
          <ProgressRing.progress_ring completed={7} scope={19}>7 / 19</ProgressRing.progress_ring>
          """
        end)

      assert generic =~ "lui-progress-ring-track"
      assert generic =~ "lui-progress-ring-value"
      assert generic =~ "stroke-dasharray"
      assert generic =~ ~s(role="progressbar")
      assert generic =~ ~s(aria-valuenow="7")
      assert generic =~ ~s(aria-valuemax="19")
      assert generic =~ ~s(data-progress-pct="37")

      assert alias =~ "7 / 19"
      assert alias =~ ~s(data-progress-pct="37")
      assert alias =~ "lui-progress-ring-label"
    end

    test "zero max is a decorative empty ring" do
      html =
        render(fn assigns ->
          ~H"""
          <ProgressRing.progress_ring scope={0} completed={0} />
          """
        end)

      assert html =~ ~s(aria-hidden="true")
      refute html =~ "progressbar"
      assert html =~ ~s(data-progress-pct="0")
    end
  end

  describe "side_panel/1" do
    test "open panel is visible; closed panel is hidden" do
      open =
        render(fn assigns ->
          ~H"""
          <SidePanel.side_panel id="p1" open aria-label="Project">Hello</SidePanel.side_panel>
          """
        end)

      closed =
        render(fn assigns ->
          ~H"""
          <SidePanel.side_panel id="p2">Hello</SidePanel.side_panel>
          """
        end)

      refute open =~ " hidden"
      assert closed =~ "hidden"
      assert open =~ "Hello"
    end

    test "toggle carries the hook, storage key, and aria-controls" do
      html =
        render(fn assigns ->
          ~H"""
          <SidePanel.side_panel_toggle
            id="tickets-panel-toggle"
            panel_id="tickets-panel"
            panel_key="tickets"
            open
          />
          """
        end)

      assert html =~ ~s(phx-hook="LanternSidePanel")
      assert html =~ ~s(data-panel-key="tickets")
      assert html =~ ~s(aria-pressed="true")
      assert html =~ ~s(aria-controls="tickets-panel")
      assert html =~ ~s(aria-label="Toggle panel")
      assert html =~ "viewBox=\"0 0 16 16\""
    end
  end

  describe "registry" do
    test "all eight primitives import through use LanternUI" do
      keys = LanternUI.__components__()
      assert keys[:list_row] == ListRow
      assert keys[:group_band] == GroupBand
      assert keys[:inspector] == Inspector
      assert keys[:icon_button] == IconButton
      assert keys[:segmented] == Segmented
      assert keys[:state_glyph] == StateGlyph
      assert keys[:progress_ring] == ProgressRing
      assert keys[:side_panel] == SidePanel

      html = render(&ImporterFixture.representative/1)
      assert html =~ "lui-list-row"
      assert html =~ "lui-group-band"
      assert html =~ "lui-inspector"
      assert html =~ "lui-icon-btn"
      assert html =~ "lui-segmented"
      assert html =~ "lui-state-glyph"
      assert html =~ "lui-progress-ring"
      assert html =~ "lui-side-panel"
    end

    test "CSS uses tokens, a visible ring track, and hidden side panels" do
      css = File.read!("priv/static/lantern_ui.css")
      assert css =~ ".lui-list-row"
      assert css =~ ".lui-group-band"
      assert css =~ ".lui-inspector"
      assert css =~ ".lui-segmented"
      assert css =~ ".lui-state-glyph"
      assert css =~ ".lui-progress-ring-track"
      assert css =~ "stroke: var(--lantern-border-strong)"
      assert css =~ ".lui-progress-ring-value"
      assert css =~ "stroke-width: 4"
      assert css =~ ".lui-side-panel[hidden]"
      assert css =~ "var(--lantern-accent-soft)"
      assert css =~ "var(--lantern-surface-hover)"
      refute css =~ ~r/\.lui-list-row[^{]*\{[^}]*#[0-9a-fA-F]{3,8}/
    end
  end
end
