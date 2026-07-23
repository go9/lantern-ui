defmodule LanternUI.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Accordion

  # `aria-expanded` is server-rendered as a literal and flipped by the hook at
  # runtime — declared hook-owned, matching the ARIA conformance gate.
  @hook_owned ["aria-expanded"]

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp basic(assigns) do
    ~H"""
    <Accordion.accordion id="faq">
      <:item title="Shipping">We ship worldwide.</:item>
      <:item title="Returns" expanded>Thirty days.</:item>
      <:item title="Warranty" disabled>Soon.</:item>
    </Accordion.accordion>
    """
  end

  describe "structure + registry" do
    test "registered so `use LanternUI` imports it" do
      assert {:accordion, Accordion} in LanternUI.__components__()
    end

    test "roots with the hook and single-open default" do
      html = render(&basic/1)
      assert html =~ ~s(id="faq")
      assert html =~ ~s(class="lui-accordion")
      assert html =~ ~s(phx-hook="LanternAccordion")
      assert html =~ ~s(data-multiple="false")
    end

    test "multiple opens the single-open gate" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" multiple>
            <:item title="One">1</:item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(data-multiple="true")
    end

    test "each item renders header button + panel with namespaced ids" do
      html = render(&basic/1)

      assert html =~ ~s(id="faq-0-trigger")
      assert html =~ ~s(id="faq-0-panel")
      assert html =~ ~s(id="faq-2-trigger")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~s(data-part="item")
      assert html =~ ~s(<button type="button")
      assert html =~ "We ship worldwide."
      assert html =~ "Thirty days."
    end
  end

  describe "ARIA contract" do
    test "trigger wires aria-expanded + aria-controls; panel is a labelled region" do
      html = render(&basic/1)

      assert html =~ ~s(aria-controls="faq-0-panel")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-labelledby="faq-0-trigger")
      # header buttons are wrapped in a heading with a level
      assert html =~ ~s(role="heading")
      assert html =~ ~s(aria-level="3")
    end

    test "heading_level flows to aria-level" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" heading_level={2}>
            <:item title="One">1</:item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(aria-level="2")
    end

    test "expanded item is open + visible; collapsed items are aria-expanded=false and hidden" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)

      # item 1 (expanded) — open, panel not hidden
      trigger1 = Floki.find(doc, "#faq-1-trigger")
      assert Floki.attribute(trigger1, "aria-expanded") == ["true"]
      panel1 = Floki.find(doc, "#faq-1-panel")
      assert Floki.attribute(panel1, "hidden") == []

      # item 0 (collapsed) — closed, panel hidden
      trigger0 = Floki.find(doc, "#faq-0-trigger")
      assert Floki.attribute(trigger0, "aria-expanded") == ["false"]
      panel0 = Floki.find(doc, "#faq-0-panel")
      assert Floki.attribute(panel0, "hidden") == ["hidden"]

      # data-state mirrors it on the item
      assert html =~ ~s(data-state="open")
      assert html =~ ~s(data-state="closed")
    end

    test "disabled item renders a disabled, non-focusable button" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)
      trigger2 = Floki.find(doc, "#faq-2-trigger")
      assert Floki.attribute(trigger2, "disabled") == ["disabled"]
    end

    test "passes the structural ARIA conformance gate (idrefs resolve, no dangling refs)" do
      html = render(&basic/1)
      assert ARIAConformance.audit(html, hook_owned: @hook_owned) == []
    end

    test "collapsed panels stay in the DOM so aria-controls never dangles" do
      # The classic conditional-child trap: rendering panels `:if={@open}` would
      # leave aria-controls on collapsed triggers pointing at nothing. Panels are
      # always rendered (hidden), so every idref resolves.
      html = render(&basic/1)
      assert html =~ ~s(id="faq-0-panel")
      assert html =~ ~s(id="faq-2-panel")
      violations = ARIAConformance.audit(html, hook_owned: @hook_owned)
      assert Enum.all?(violations, &(&1.kind != :dangling_idref))
    end
  end

  describe "customization" do
    test "merges consumer classes onto root and item, base-first" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" class="mt-4">
            <:item title="One" class="special">1</:item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(class="lui-accordion mt-4")
      assert html =~ "lui-accordion-item special"
    end

    test "passes through global attrs on the root" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" data-testid="acc">
            <:item title="One">1</:item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(data-testid="acc")
    end
  end
end
