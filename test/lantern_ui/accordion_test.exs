defmodule LanternUI.AccordionTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Accordion

  @hook_owned ["aria-expanded"]

  defmodule FluxonMigrationFixture do
    use Phoenix.Component
    use LanternUI, only: [:accordion]

    def representative(assigns) do
      ~H"""
      <.accordion
        id="migration"
        class="root-extra"
        multiple
        prevent_all_closed
        animation_duration={175}
        data-testid="accordion"
      >
        <.accordion_item
          id="first"
          class="item-extra"
          expanded
          icon={false}
          data-testid="item"
        >
          <:header class="header-extra">First header</:header>
          <:panel class="panel-extra">First panel</:panel>
        </.accordion_item>
        <.accordion_item id="second">
          <:header>Second header</:header>
          <:panel>Second panel</:panel>
        </.accordion_item>
      </.accordion>
      """
    end
  end

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp basic(assigns) do
    ~H"""
    <Accordion.accordion id="faq">
      <Accordion.accordion_item id="shipping">
        <:header>Shipping</:header>
        <:panel>We ship worldwide.</:panel>
      </Accordion.accordion_item>
      <Accordion.accordion_item id="returns" expanded>
        <:header>Returns</:header>
        <:panel>Thirty days.</:panel>
      </Accordion.accordion_item>
    </Accordion.accordion>
    """
  end

  describe "Fluxon 2.3.1 migration parity" do
    test "registry imports and module introspection expose both public functions" do
      assert {:accordion, Accordion} in LanternUI.__components__()
      assert {:accordion, 1} in Accordion.__info__(:functions)
      assert {:accordion_item, 1} in Accordion.__info__(:functions)

      assert {:representative, 1} in FluxonMigrationFixture.__info__(:functions)
    end

    test "representative use Fluxon call renders after changing only the importer" do
      html = render(&FluxonMigrationFixture.representative/1)
      doc = Floki.parse_fragment!(html)

      root = Floki.find(doc, "#migration")
      assert Floki.attribute(root, "class") == ["lui-accordion root-extra"]
      assert Floki.attribute(root, "phx-hook") == ["LanternAccordion"]
      assert Floki.attribute(root, "data-multiple") == ["true"]
      assert Floki.attribute(root, "data-prevent-all-closed") == ["true"]
      assert Floki.attribute(root, "data-animation-duration") == ["175"]
      assert Floki.attribute(root, "style") == ["--lui-accordion-duration: 175ms"]
      assert Floki.attribute(root, "data-testid") == ["accordion"]

      item = Floki.find(doc, "#first")
      assert Floki.attribute(item, "class") == ["lui-accordion-item item-extra"]
      assert Floki.attribute(item, "data-testid") == ["item"]

      assert Floki.attribute(Floki.find(doc, "#first-trigger"), "class") == [
               "lui-accordion-trigger header-extra"
             ]

      assert Floki.attribute(Floki.find(doc, "#first-panel .lui-accordion-body"), "class") == [
               "lui-accordion-body panel-extra"
             ]

      assert Floki.find(doc, "#first-trigger .lui-accordion-icon") == []
      assert Floki.find(doc, "#second-trigger .lui-accordion-icon") != []
    end

    test "Fluxon defaults are single-open, closable, 300ms, collapsed, and icon-visible" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)
      root = Floki.find(doc, "#faq")

      assert Floki.attribute(root, "data-multiple") == ["false"]
      assert Floki.attribute(root, "data-prevent-all-closed") == ["false"]
      assert Floki.attribute(root, "data-animation-duration") == ["300"]
      assert Floki.attribute(Floki.find(doc, "#shipping-trigger"), "aria-expanded") == ["false"]
      assert Floki.find(doc, "#shipping-trigger .lui-accordion-icon") != []
    end

    test "container and item ids are optional and generated with valid relationships" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion>
            <Accordion.accordion_item>
              <:header>Generated</:header>
              <:panel>Content</:panel>
            </Accordion.accordion_item>
          </Accordion.accordion>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [root_id] = Floki.attribute(Floki.find(doc, ".lui-accordion"), "id")
      [item_id] = Floki.attribute(Floki.find(doc, ".lui-accordion-item"), "id")
      assert root_id =~ ~r/^accordion-\d+$/
      assert item_id =~ ~r/^accordion-item-\d+$/

      assert Floki.attribute(Floki.find(doc, "##{item_id}-trigger"), "aria-controls") == [
               "#{item_id}-panel"
             ]
    end

    test "multiple and prevent-all-closed remain independently configurable" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" multiple>
            <Accordion.accordion_item id="one">
              <:header>One</:header>
              <:panel>Panel</:panel>
            </Accordion.accordion_item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(data-multiple="true")
      assert html =~ ~s(data-prevent-all-closed="false")
    end

    test "global phx and data attrs pass through on both public components" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="a" phx-click="root" data-root="yes">
            <Accordion.accordion_item id="one" phx-click="item" data-item="yes">
              <:header>One</:header>
              <:panel>Panel</:panel>
            </Accordion.accordion_item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(phx-click="root")
      assert html =~ ~s(data-root="yes")
      assert html =~ ~s(phx-click="item")
      assert html =~ ~s(data-item="yes")
    end

    test "consumer classes merge base-first on root, item, header, and panel" do
      html = render(&FluxonMigrationFixture.representative/1)
      assert html =~ ~s(class="lui-accordion root-extra")
      assert html =~ ~s(class="lui-accordion-item item-extra")
      assert html =~ ~s(class="lui-accordion-trigger header-extra")
      assert html =~ ~s(class="lui-accordion-body panel-extra")
    end
  end

  describe "WAI-ARIA structure and initial state" do
    test "renders namespaced header buttons and persistent labelled panels" do
      html = render(&basic/1)

      assert html =~ ~s(id="shipping-trigger")
      assert html =~ ~s(id="shipping-panel")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~s(data-part="item")
      assert html =~ "We ship worldwide."
      assert html =~ "Thirty days."
      assert html =~ ~s(role="heading")
      assert html =~ ~s(aria-level="3")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-labelledby="shipping-trigger")
    end

    test "expanded item is visible and collapsed item remains hidden in the DOM" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)

      assert Floki.attribute(Floki.find(doc, "#returns-trigger"), "aria-expanded") == ["true"]
      assert Floki.attribute(Floki.find(doc, "#returns-panel"), "hidden") == []
      assert Floki.attribute(Floki.find(doc, "#shipping-trigger"), "aria-expanded") == ["false"]
      assert Floki.attribute(Floki.find(doc, "#shipping-panel"), "hidden") == ["hidden"]
      assert html =~ ~s(data-state="open")
      assert html =~ ~s(data-state="closed")
    end

    test "passes the structural ARIA conformance gate" do
      html = render(&basic/1)
      assert ARIAConformance.audit(html, hook_owned: @hook_owned) == []
    end

    test "every collapsed panel stays rendered so aria-controls does not dangle" do
      html = render(&basic/1)
      assert html =~ ~s(id="shipping-panel")
      assert html =~ ~s(hidden)

      violations = ARIAConformance.audit(html, hook_owned: @hook_owned)
      assert Enum.all?(violations, &(&1.kind != :dangling_idref))
    end

    test "the root exposes the namespaced hook and every item exposes hook anatomy" do
      html = render(&basic/1)
      assert html =~ ~s(phx-hook="LanternAccordion")
      assert length(Floki.find(Floki.parse_fragment!(html), ~s([data-part="item"]))) == 2
      assert length(Floki.find(Floki.parse_fragment!(html), ~s([data-part="trigger"]))) == 2
      assert length(Floki.find(Floki.parse_fragment!(html), ~s([data-part="panel"]))) == 2
    end
  end
end
