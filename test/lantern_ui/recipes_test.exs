defmodule LanternUI.RecipesTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Recipes

  @heex_dir Path.expand("../support/recipes", __DIR__)

  defp render_recipe(name) do
    assigns = Map.put(Recipes.fixture_assigns(), :__changed__, nil)
    apply(Recipes, name, [assigns]) |> rendered_to_string()
  end

  defp heex_body(name) do
    Path.join(@heex_dir, "#{name}.html.heex")
    |> File.read!()
    |> String.trim()
  end

  test "every recipe renders from the shared HEEx with fixture assigns" do
    for name <- Recipes.names() do
      html = render_recipe(name)
      assert is_binary(html) and html != "", "#{name} rendered empty"
    end
  end

  test "docs and skill include every recipe HEEx verbatim" do
    docs = File.read!("docs/recipes.md")
    skill = File.read!("skills/lantern-recipes/SKILL.md")

    assert length(Recipes.names()) == 7

    for name <- Recipes.names() do
      body = heex_body(name)
      assert docs =~ body, "#{name} HEEx missing from docs/recipes.md"
      assert skill =~ body, "#{name} HEEx missing from skills/lantern-recipes/SKILL.md"
    end
  end

  test "linear list row is a group_band plus the Linear field set" do
    html = render_recipe(:linear_list_row)
    assert html =~ "lui-group-band"
    assert html =~ "In progress"
    assert html =~ "lui-list-row"
    assert html =~ "#241"
    assert html =~ "Visible progress ring"
    assert html =~ "lui-state-glyph"
    assert html =~ ~s(data-kind="priority")
    assert html =~ ~s(data-kind="status")
    assert html =~ "lui-badge"
    assert html =~ "lui-progress-ring"
    assert html =~ "Sep 3"
  end

  test "grouped list ships segmented view plus Filter/Display icon buttons" do
    html = render_recipe(:grouped_list)
    assert html =~ "lui-segmented"
    assert html =~ "All"
    assert html =~ "Active"
    assert html =~ "Backlog"
    assert html =~ ~s(aria-label="Filter")
    assert html =~ ~s(aria-label="Display")
    assert html =~ "lui-icon-btn-kbd"
    assert html =~ "data-lantern-list-nav"
    assert html =~ "data-collapsed"
  end

  test "record page puts the side_panel toggle in the breadcrumb bar" do
    html = render_recipe(:record_page)
    assert html =~ "lui-app-breadcrumb"
    assert html =~ "lui-page-title"
    assert html =~ ~s(aria-controls="ticket-panel")
    assert html =~ "lui-side-panel"
    assert html =~ "lui-inspector"
    assert html =~ "lui-property-row"
  end

  test "inbox is list, reading pane, and properties" do
    html = render_recipe(:inbox)
    assert html =~ "Inbox · 12"
    assert html =~ "lui-card-grid"
    assert html =~ "Inbox three-column layout"
    assert html =~ "Promote this suggestion"
    assert html =~ "lui-inspector"
  end

  test "project overview combines header, ring, stats, and grouped children" do
    html = render_recipe(:project_overview)
    assert html =~ "lantern-ui"
    assert html =~ "lui-progress-ring"
    assert html =~ "7 / 19"
    assert html =~ "lui-stat-grid"
    assert html =~ "Apps"
    assert html =~ "lui-group-band"
    assert html =~ "#241"
  end

  test "icon toolbar exposes kbd hints" do
    html = render_recipe(:icon_toolbar)
    assert html =~ ~s(aria-label="Promote to ticket")
    assert html =~ ">P</kbd>"
    assert html =~ ">H</kbd>"
    assert html =~ ">E</kbd>"
  end

  test "capacity strip is stats plus badges" do
    html = render_recipe(:capacity_strip)
    assert html =~ "Slots"
    assert html =~ "Busy"
    assert html =~ "Waiting"
    assert html =~ "Cost"
    assert html =~ "$12"
    assert html =~ "3 waiting"
    assert html =~ "5 busy"
  end
end
