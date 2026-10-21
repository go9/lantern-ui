defmodule LanternUI.TreeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Tree

  @hook_owned ["tabindex", "aria-selected"]

  defmodule ImportFixture do
    use Phoenix.Component
    use LanternUI, only: [:tree]

    def representative(assigns) do
      ~H"""
      <.tree
        id="envs"
        label="Environments"
        current_id="prod-api"
        expanded_ids={["prod"]}
        on_select="tree_select"
        on_toggle="tree_toggle"
        class="root-extra"
        data-testid="tree"
      >
        <.tree_item id="prod" label="Production" class="item-extra" data-testid="prod">
          <:icon><span class="prod-icon">P</span></:icon>
          <:trailing>2</:trailing>
          <.tree_item id="prod-api" label="api" />
          <.tree_item id="prod-web" label="web" disabled />
        </.tree_item>
        <.tree_item id="staging" label="Staging" state="error">
          <:trailing>failed</:trailing>
        </.tree_item>
      </.tree>
      """
    end
  end

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp basic(assigns) do
    ~H"""
    <Tree.tree id="envs" label="Environments" current_id="prod-api" expanded_ids={["prod"]}>
      <Tree.tree_item id="prod" label="Production">
        <Tree.tree_item id="prod-api" label="api" />
        <Tree.tree_item id="prod-web" label="web" />
      </Tree.tree_item>
      <Tree.tree_item id="staging" label="Staging" />
    </Tree.tree>
    """
  end

  describe "registry and import surface" do
    test "use LanternUI imports tree/1 and tree_item/1" do
      assert LanternUI.__components__()[:tree] == Tree
      assert {:tree, 1} in Tree.__info__(:functions)
      assert {:tree_item, 1} in Tree.__info__(:functions)
      assert {:representative, 1} in ImportFixture.__info__(:functions)
    end

    test "representative call renders after changing only the importer" do
      html = render(&ImportFixture.representative/1)
      doc = Floki.parse_fragment!(html)

      root = Floki.find(doc, "#envs")
      assert Floki.attribute(root, "class") == ["lui-tree root-extra"]
      assert Floki.attribute(root, "role") == ["tree"]
      assert Floki.attribute(root, "aria-label") == ["Environments"]
      assert Floki.attribute(root, "phx-hook") == ["LanternTree"]
      assert Floki.attribute(root, "data-on-select") == ["tree_select"]
      assert Floki.attribute(root, "data-on-toggle") == ["tree_toggle"]
      assert Floki.attribute(root, "data-testid") == ["tree"]

      prod = Floki.find(doc, "#prod")
      assert Floki.attribute(prod, "class") == ["lui-tree-item item-extra"]
      assert Floki.attribute(prod, "data-testid") == ["prod"]
      assert html =~ "prod-icon"
    end
  end

  describe "WAI-ARIA structure and controlled state" do
    test "renders tree, treeitem, and group roles with parentage" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)

      assert Floki.attribute(Floki.find(doc, "#envs"), "role") == ["tree"]
      assert Floki.attribute(Floki.find(doc, "#prod"), "role") == ["treeitem"]
      assert Floki.attribute(Floki.find(doc, "#prod"), "aria-expanded") == ["true"]
      assert Floki.attribute(Floki.find(doc, "#prod"), "data-part") == ["item"]

      group = Floki.find(doc, "#prod [data-part=group]")
      assert Floki.attribute(group, "role") == ["group"]
      assert Floki.attribute(group, "hidden") == []

      assert Floki.find(doc, "#staging [data-part=group]") == []
      assert Floki.attribute(Floki.find(doc, "#staging"), "aria-expanded") == []
    end

    test "current is aria-current, not implied by expansion or focus" do
      html = render(&basic/1)
      doc = Floki.parse_fragment!(html)

      assert Floki.attribute(Floki.find(doc, "#prod-api"), "aria-current") == ["true"]
      assert Floki.attribute(Floki.find(doc, "#prod-api"), "tabindex") == ["0"]
      assert Floki.attribute(Floki.find(doc, "#prod"), "aria-current") == []
      assert Floki.attribute(Floki.find(doc, "#prod"), "tabindex") == ["-1"]
      assert Floki.attribute(Floki.find(doc, "#staging"), "aria-current") == []
    end

    test "collapsed groups stay in the DOM and are hidden" do
      html =
        render(fn assigns ->
          ~H"""
          <Tree.tree id="envs" label="Environments" expanded_ids={[]}>
            <Tree.tree_item id="prod" label="Production">
              <Tree.tree_item id="prod-api" label="api" />
            </Tree.tree_item>
          </Tree.tree>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, "#prod"), "aria-expanded") == ["false"]
      assert Floki.attribute(Floki.find(doc, "#prod [data-part=group]"), "hidden") == ["hidden"]
      assert Floki.find(doc, "#prod-api") != []
    end

    test "without current_id the first root is the tab stop" do
      html =
        render(fn assigns ->
          ~H"""
          <Tree.tree id="envs" label="Environments">
            <Tree.tree_item id="prod" label="Production" />
            <Tree.tree_item id="staging" label="Staging" />
          </Tree.tree>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, "#prod"), "tabindex") == ["0"]
      assert Floki.attribute(Floki.find(doc, "#staging"), "tabindex") == ["-1"]
    end

    test "a trailing-only item is a leaf even when the slot is used" do
      html =
        render(fn assigns ->
          ~H"""
          <Tree.tree id="envs" label="Environments">
            <Tree.tree_item id="replica" label="replica" state="error">
              <:trailing>unreachable</:trailing>
            </Tree.tree_item>
          </Tree.tree>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, "#replica"), "aria-expanded") == []
      assert Floki.find(doc, "#replica [data-part=group]") == []
      assert html =~ "unreachable"
    end

    test "icon and trailing slots do not hide real nested children" do
      html = render(&ImportFixture.representative/1)
      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, "#prod"), "aria-expanded") == ["true"]
      assert Floki.find(doc, "#prod-api") != []
      assert Floki.attribute(Floki.find(doc, "#staging"), "aria-expanded") == []
    end

    test "disabled and error state land on the item" do
      html = render(&ImportFixture.representative/1)
      doc = Floki.parse_fragment!(html)
      assert Floki.attribute(Floki.find(doc, "#prod-web"), "aria-disabled") == ["true"]
      assert Floki.attribute(Floki.find(doc, "#staging"), "data-state") == ["error"]
      assert html =~ "failed"
    end

    test "empty slot renders inside the tree when there are no items" do
      html =
        render(fn assigns ->
          ~H"""
          <Tree.tree id="empty" label="Sources">
            <:empty><span class="empty-copy">No sources</span></:empty>
          </Tree.tree>
          """
        end)

      assert html =~ ~s(role="tree")
      assert html =~ ~s(class="lui-tree-empty")
      assert html =~ "No sources"
      refute html =~ ~s(role="treeitem")
    end

    test "consumer classes merge base-first and rest attrs pass through" do
      html = render(&ImportFixture.representative/1)
      assert html =~ ~s(class="lui-tree root-extra")
      assert html =~ ~s(class="lui-tree-item item-extra")
      assert html =~ ~s(data-testid="prod")
    end

    test "passes the structural ARIA conformance gate" do
      html = render(&basic/1)
      assert ARIAConformance.audit(html, hook_owned: @hook_owned) == []
    end
  end

  describe "CSS tokens" do
    test "bundled CSS styles connectors through lantern tree tokens" do
      css = File.read!("priv/static/lantern_ui.css")
      assert css =~ ".lui-tree"
      assert css =~ ".lui-tree-group"
      assert css =~ "--lantern-tree-indent"
      assert css =~ "--lantern-tree-connector"
      theme = File.read!("priv/static/lantern_ui_theme.css")
      assert theme =~ "--lantern-tree-indent: var(--lantern-space-lg);"
      assert theme =~ "--lantern-tree-connector: var(--lantern-border);"
    end
  end
end
