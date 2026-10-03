defmodule LanternUI.BlocksTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Blocks

  @heex_dir Path.expand("../support/blocks", __DIR__)

  defp render_block(name) do
    assigns = Map.put(Blocks.fixture_assigns(), :__changed__, nil)
    apply(Blocks, name, [assigns]) |> rendered_to_string()
  end

  defp heex_body(name) do
    Path.join(@heex_dir, "#{name}.html.heex")
    |> File.read!()
    |> String.trim()
  end

  test "every block renders from the shared HEEx with fixture assigns" do
    for name <- Blocks.names() do
      html = render_block(name)
      assert is_binary(html) and html != "", "#{name} rendered empty"
    end
  end

  test "docs include every block HEEx verbatim" do
    docs = File.read!("docs/recipes.md")

    assert length(Blocks.names()) == 8

    for name <- Blocks.names() do
      body = heex_body(name)
      assert docs =~ body, "#{name} HEEx missing from docs/recipes.md"
    end
  end

  test "lantern-recipes skill points at the block index" do
    skill = File.read!("skills/lantern-recipes/SKILL.md")

    assert skill =~ "docs/recipes.md"

    for name <- Blocks.names() do
      assert skill =~ Atom.to_string(name), "#{name} missing from skills/lantern-recipes/SKILL.md"
    end
  end

  test "app shell carries brand, nav, breadcrumb header, and content" do
    html = render_block(:app_shell)
    assert html =~ "lui-app"
    assert html =~ "Acme"
    assert html =~ "lui-app-sidebar"
    assert html =~ "Dashboard"
    assert html =~ "Tickets"
    assert html =~ "badge"
    assert html =~ "lui-breadcrumb"
    assert html =~ "lui-page-title"
    assert html =~ "New ticket"
  end

  test "dashboard shows stats, a chart, and recent activity" do
    html = render_block(:dashboard)
    assert html =~ "Dashboard"
    assert html =~ "lui-stat-grid"
    assert html =~ "Open tickets"
    assert html =~ "P95 review lag"
    assert html =~ "Merged per day"
    assert html =~ ~s(role="img")
    assert html =~ "Recent activity"
    assert html =~ "lui-list-row"
    assert html =~ "#241"
  end

  test "index is a flat data_table with chips, filter, search, and pagination" do
    html = render_block(:index)
    assert html =~ "lui-datatable"
    assert html =~ "In progress"
    assert html =~ ~s(aria-label="Status")
    assert html =~ "All statuses"
    assert html =~ ~s(aria-label="Search…")
    assert html =~ "lui-list-row"
    assert html =~ ~s(href="/tickets/241")
    assert html =~ "data-lantern-list-item"
    refute html =~ "lui-group-band"
    refute html =~ "data-lantern-group"
  end

  test "detail pairs the record with an inspector panel" do
    html = render_block(:detail)
    assert html =~ "lui-app-breadcrumb"
    assert html =~ "Visible progress ring"
    assert html =~ ~s(aria-controls="ticket-panel")
    assert html =~ "lui-side-panel"
    assert html =~ "lui-inspector"
    assert html =~ "Properties"
    assert html =~ "People"
    assert html =~ "Ada Lovelace"
  end

  test "settings stacks one form per section card" do
    html = render_block(:settings)
    assert html =~ "Settings"
    assert html =~ "Profile"
    assert html =~ "Notifications"
    assert html =~ "Appearance"
    assert html =~ ~s(id="settings-name")
    assert html =~ "lui-switch"
    assert html =~ "Save profile"
    assert html =~ "Save notifications"
    assert html =~ "Save appearance"
  end

  test "form surfaces validation errors with a next action" do
    html = render_block(:form)
    assert html =~ "New ticket"
    assert html =~ "lui-alert"
    assert html =~ "can&#39;t be blank"
    assert html =~ ~s(id="ticket-title")
    assert html =~ "Create ticket"
    assert html =~ "Cancel"
  end

  test "login is a centered card with a single primary action" do
    html = render_block(:login)
    assert html =~ "Welcome back"
    assert html =~ ~s(type="email")
    assert html =~ ~s(type="password")
    assert html =~ "Sign in"
    assert html =~ "or continue with"
    assert html =~ "Continue with SSO"
  end

  test "destructive pairs the confirm dialog with empty, loading, and error states" do
    html = render_block(:destructive)
    assert html =~ "Danger zone"
    assert html =~ "Delete workspace"
    assert html =~ "alertdialog"
    assert html =~ "lui-empty"
    assert html =~ "Loading tickets"
    assert html =~ "didn&#39;t load"
    assert html =~ "Retry"
  end
end
