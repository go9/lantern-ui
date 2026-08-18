defmodule LanternUI.WaterfallTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Waterfall

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp style(el) do
    el |> Floki.attribute("style") |> List.first() || ""
  end

  describe "waterfall/1" do
    test "renders a ruler tick per tick, positioned by pct" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall
            id="wf"
            label="Phase"
            ticks={[%{label: "0s", pct: 0.0}, %{label: "30s", pct: 50.0}, %{label: "60s", pct: 100.0}]}
          >
            <Waterfall.waterfall_lane label="plan" left={0.0} width={50.0} />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      ticks = Floki.find(doc, ".lui-waterfall-ruler-track .lui-waterfall-tick")
      assert length(ticks) == 3
      assert style(Enum.at(ticks, 1)) =~ "left: 50.0%"
      assert Floki.text(Enum.at(ticks, 2)) =~ "60s"
      assert Floki.find(doc, ".lui-waterfall-ruler-label") |> Floki.text() =~ "Phase"
    end

    test "ruler, gridline layer and lanes share ONE grid template" do
      # This is the component's entire claim: a percentage means the same thing
      # on the ruler, on the gridline layer, and on every lane. The three are
      # separate elements, so nothing but this shared rule keeps them aligned —
      # if one ever gets its own template the bars stop being comparable and
      # the ruler silently becomes decoration.
      rule =
        "priv/static/lantern_ui.css"
        |> File.read!()
        |> String.split("\n\n")
        |> Enum.find(&(&1 =~ "grid-template-columns: var(--lui-waterfall-label-w)"))

      assert rule, "no waterfall grid template rule found"
      assert rule =~ ".lui-waterfall-ruler,"
      assert rule =~ ".lui-waterfall-body,"
      assert rule =~ ".lui-waterfall-lane-inner {"
    end

    test "active bars are colored by --lui-waterfall-active with the accent as fallback" do
      # "Running" must be overridable separately from the accent: a host whose
      # accent resolves near danger red would otherwise paint healthy in-flight
      # work in the failure color. Every color the active bar carries — fill,
      # text, and the still-running fade — must route through the token, or an
      # override leaves a red remnant.
      css = File.read!("priv/static/lantern_ui.css")

      active_rules =
        css
        |> String.split("\n\n")
        |> Enum.filter(&(&1 =~ ~s([data-status="active"] .lui-waterfall-bar)))

      assert active_rules != [], "no active waterfall bar rules found"

      for rule <- active_rules do
        assert rule =~ "var(--lui-waterfall-active, var(--lantern-accent))",
               "active rule does not route through the token:\n#{rule}"

        refute rule =~ ~r/var\(--lantern-accent\)(?!\))/,
               "active rule still uses the accent directly:\n#{rule}"
      end
    end

    test "gridlines are drawn once for the whole chart, not per lane" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall ticks={[%{label: "a", pct: 25.0}, %{label: "b", pct: 75.0}]}>
            <Waterfall.waterfall_lane label="one" left={0.0} width={10.0} />
            <Waterfall.waterfall_lane label="two" left={10.0} width={10.0} />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert length(Floki.find(doc, "li.lui-waterfall-lane")) == 2

      # Two ticks and two lanes: four gridlines would mean per-lane copies,
      # which can drift apart. There must be exactly one shared layer.
      lines = Floki.find(doc, ".lui-waterfall-gridline")
      assert length(lines) == 2
      assert style(Enum.at(lines, 0)) =~ "left: 25.0%"
      assert style(Enum.at(lines, 1)) =~ "left: 75.0%"

      assert Floki.find(doc, "li.lui-waterfall-lane .lui-waterfall-gridline") == []
      assert length(Floki.find(doc, ".lui-waterfall-body > .lui-waterfall-grid")) == 1
    end

    test "a waterfall with no ticks renders no gridlines and still lays out bars" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="one" left={12.5} width={20.0} bar_label="3s" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, ".lui-waterfall-gridline") == []
      assert [bar] = Floki.find(doc, ".lui-waterfall-bar")
      assert style(bar) =~ "left: 12.5%"
    end
  end

  describe "waterfall_lane/1" do
    test "positions the bar from left/width and labels it" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="implement" left={31.4} width={52.1} bar_label="7m 02s" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [bar] = Floki.find(doc, ".lui-waterfall-bar")
      assert style(bar) =~ "left: 31.4%"
      assert style(bar) =~ "width: 52.1%"
      assert Floki.text(bar) =~ "7m 02s"
      assert bar |> Floki.attribute("title") |> List.first() == "7m 02s"
    end

    test "a zero-width bar still gets a visible floor" do
      # A phase that took 4ms of a 20-minute run rounds to 0% and would vanish.
      # It must stay visible and clickable without moving its start.
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="fast" left={80.0} width={0.0} bar_label="4ms" />
          </Waterfall.waterfall>
          """
        end)

      assert [bar] = html |> Floki.parse_fragment!() |> Floki.find(".lui-waterfall-bar")
      assert style(bar) =~ "left: 80.0%"
      refute style(bar) =~ "width: 0.0%"
      assert style(bar) =~ "width: 0.4%"
    end

    test "queued lanes claim no position on the axis" do
      # The failure this guards is a waterfall that invents a start time for
      # work that has not started, which reads as fact.
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="test" queued bar_label="queued" left={99.0} width={44.0} />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [lane] = Floki.find(doc, "li.lui-waterfall-lane")
      assert lane |> Floki.attribute("data-queued") |> List.first() == "true"

      assert [bar] = Floki.find(doc, ".lui-waterfall-bar")
      assert bar |> Floki.attribute("data-queued") |> List.first() == "true"
      refute style(bar) =~ "left:"
      refute style(bar) =~ "width:"
      assert Floki.text(bar) =~ "queued"
    end

    test "status lands on the lane, and state_label carries it for assistive tech" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="plan" status={:done} state_label="Passed" />
            <Waterfall.waterfall_lane label="implement" status={:danger} state_label="Failed" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      lanes = Floki.find(doc, "li.lui-waterfall-lane")
      assert Enum.at(lanes, 0) |> Floki.attribute("data-status") == ["done"]
      assert Enum.at(lanes, 1) |> Floki.attribute("data-status") == ["danger"]

      # State is never color-only.
      assert Floki.find(doc, ".lui-sr-only") |> Floki.text() =~ "Passed"
      assert Floki.find(doc, ".lui-sr-only") |> Floki.text() =~ "Failed"
    end

    test "navigate makes the whole lane one link; without it there is no anchor" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="plan" navigate="/runs/1?phase=plan" />
            <Waterfall.waterfall_lane label="test" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      anchors = Floki.find(doc, "a.lui-waterfall-lane-inner")
      assert length(anchors) == 1
      assert anchors |> Floki.attribute("href") == ["/runs/1?phase=plan"]

      # The non-link lane must not become <a href="#">, which is what
      # Phoenix's link/1 renders when handed no destination.
      assert length(Floki.find(doc, "div.lui-waterfall-lane-inner")) == 1
      refute Floki.attribute(doc, "a", "href") |> Enum.member?("#")
    end

    test "selected is marked on the lane, not only styled" do
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="plan" selected />
            <Waterfall.waterfall_lane label="test" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      lanes = Floki.find(doc, "li.lui-waterfall-lane")
      assert Enum.at(lanes, 0) |> Floki.attribute("data-selected") == ["true"]
      assert Enum.at(lanes, 1) |> Floki.attribute("data-selected") == []
    end

    test "the icon is a slot, so a host app's own icon set works" do
      # An earlier cut took an icon NAME and rendered it with the library's
      # curated set. flicker passes heroicon names from its own pipeline, and
      # Map.fetch! on an unknown key crashed the whole run page. A shared
      # component does not get to dictate the host's icon vocabulary.
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall>
            <Waterfall.waterfall_lane label="plan">
              <:icon><svg data-test="host-icon"></svg></:icon>
            </Waterfall.waterfall_lane>
            <Waterfall.waterfall_lane label="test" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [_] = Floki.find(doc, ".lui-waterfall-lane-icon svg[data-test=host-icon]")
      assert length(Floki.find(doc, ".lui-waterfall-lane-icon")) == 1
    end

    test "ticks from one waterfall do not leak into the next" do
      # This drove the design: an earlier cut inherited ticks through process
      # state, and because HEEx defers slot evaluation the SECOND waterfall's
      # Process.put landed before the first one's lanes rendered — the first
      # chart drew the second's axis. Drawing gridlines in the root makes the
      # leak unrepresentable.
      html =
        render(fn assigns ->
          ~H"""
          <Waterfall.waterfall ticks={[%{label: "a", pct: 10.0}]}>
            <Waterfall.waterfall_lane label="one" />
          </Waterfall.waterfall>
          <Waterfall.waterfall ticks={[]}>
            <Waterfall.waterfall_lane label="two" />
          </Waterfall.waterfall>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [first, second] = Floki.find(doc, ".lui-waterfall")
      assert length(Floki.find(first, ".lui-waterfall-gridline")) == 1
      assert Floki.find(second, ".lui-waterfall-gridline") == []
    end
  end
end
