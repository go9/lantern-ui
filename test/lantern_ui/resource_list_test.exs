defmodule LanternUI.ResourceListTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.ResourceList

  defmodule ImporterFixture do
    use Phoenix.Component
    use LanternUI, only: [:resource_list]

    def representative(assigns) do
      ~H"""
      <.resource_list>
        <.resource_list_item title="alpha" />
      </.resource_list>
      """
    end
  end

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "resource_list/1 + resource_list_item/1" do
    test "renders an unordered list with one li per item" do
      html =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="one" />
            <ResourceList.resource_list_item title="two" />
            <ResourceList.resource_list_item title="three" />
          </ResourceList.resource_list>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [{"ul", attrs, _}] = Floki.find(doc, "ul.lui-resource-list")
      assert {"class", class} = List.keyfind(attrs, "class", 0)
      assert class =~ "lui-resource-list"

      items = Floki.find(doc, "ul.lui-resource-list > li.lui-resource-list-item")
      assert length(items) == 3
      assert Floki.text(Enum.at(items, 0)) =~ "one"
      assert Floki.text(Enum.at(items, 1)) =~ "two"
      assert Floki.text(Enum.at(items, 2)) =~ "three"
    end

    test "data-layout reflects the layout attr and defaults to list" do
      default =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="x" />
          </ResourceList.resource_list>
          """
        end)

      grid =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list layout={:grid}>
            <ResourceList.resource_list_item title="x" />
          </ResourceList.resource_list>
          """
        end)

      assert default =~ ~s(data-layout="list")
      assert grid =~ ~s(data-layout="grid")
    end

    test "navigate makes the whole row an anchor" do
      html =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item
              title="enventory"
              subtitle="enventory"
              navigate="/projects/enventory"
            />
          </ResourceList.resource_list>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [item] = Floki.find(doc, "li.lui-resource-list-item")
      links = Floki.find(item, "a.lui-resource-list-row")
      assert length(links) == 1
      assert Floki.attribute(links, "href") == ["/projects/enventory"]
      assert Floki.find(links, ".lui-resource-list-title") != []
      assert Floki.find(links, ".lui-resource-list-subtitle") != []
    end

    test "item without navigate, patch, or href renders no anchor" do
      html =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="plain" />
          </ResourceList.resource_list>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [item] = Floki.find(doc, "li.lui-resource-list-item")
      assert Floki.find(item, "a") == []
      assert Floki.find(item, "div.lui-resource-list-row") != []
      assert Floki.text(item) =~ "plain"
    end

    test "trailing slot renders inside meta" do
      html =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="foodfeed">
              <span class="meta-badge">Setup required</span>
              <span class="meta-badge">4 configs</span>
            </ResourceList.resource_list_item>
          </ResourceList.resource_list>
          """
        end)

      doc = Floki.parse_fragment!(html)
      meta = Floki.find(doc, ".lui-resource-list-meta")
      assert meta != []
      assert Floki.text(meta) =~ "Setup required"
      assert Floki.text(meta) =~ "4 configs"
      assert length(Floki.find(meta, ".meta-badge")) == 2
    end

    test "subtitle is optional" do
      with_sub =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="Named" subtitle="named-slug" />
          </ResourceList.resource_list>
          """
        end)

      without_sub =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="Named" />
          </ResourceList.resource_list>
          """
        end)

      assert with_sub =~ ~s(class="lui-resource-list-subtitle")
      assert with_sub =~ "named-slug"
      refute without_sub =~ "lui-resource-list-subtitle"
    end

    test "class merge on list and item roots" do
      html =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list class="list-extra">
            <ResourceList.resource_list_item class="item-extra" title="x" />
          </ResourceList.resource_list>
          """
        end)

      assert html =~ ~s(class="lui-resource-list list-extra")
      assert html =~ ~s(class="lui-resource-list-item item-extra")
    end

    test "patch and href also make the row a link" do
      patch =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="p" patch="/p" />
          </ResourceList.resource_list>
          """
        end)

      href =
        render(fn assigns ->
          ~H"""
          <ResourceList.resource_list>
            <ResourceList.resource_list_item title="h" href="https://example.com" />
          </ResourceList.resource_list>
          """
        end)

      patch_doc = Floki.parse_fragment!(patch)
      href_doc = Floki.parse_fragment!(href)

      assert Floki.find(patch_doc, "a.lui-resource-list-row") != []
      assert Floki.attribute(Floki.find(patch_doc, "a.lui-resource-list-row"), "href") == ["/p"]

      assert Floki.find(href_doc, "a.lui-resource-list-row") != []

      assert Floki.attribute(Floki.find(href_doc, "a.lui-resource-list-row"), "href") == [
               "https://example.com"
             ]
    end

    test "registry imports expose both public functions" do
      assert {:resource_list, ResourceList} in LanternUI.__components__()
      assert {:resource_list, 1} in ResourceList.__info__(:functions)
      assert {:resource_list_item, 1} in ResourceList.__info__(:functions)

      assert render(&ImporterFixture.representative/1) =~ "lui-resource-list"
    end

    test "CSS owns list separators between items and the grid card layout" do
      css = File.read!("priv/static/lantern_ui.css")

      assert css =~
               ~r/\.lui-resource-list\[data-layout="list"\]\s*>\s*\.lui-resource-list-item\s*\+\s*\.lui-resource-list-item/

      assert css =~ ~r/repeat\(\s*auto-fill\s*,\s*minmax\(\s*18rem\s*,\s*1fr\s*\)\s*\)/
      assert css =~ "a.lui-resource-list-row:focus-visible"
      assert css =~ "var(--lantern-surface-hover)"
      assert css =~ "var(--lantern-border)"
      refute css =~ ~r/\.lui-resource-list[^{]*\{[^}]*#[0-9a-fA-F]{3,8}/
    end
  end
end
