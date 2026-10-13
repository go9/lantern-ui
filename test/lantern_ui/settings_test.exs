defmodule LanternUI.SettingsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Navlist
  alias LanternUI.Components.Settings
  alias LanternUI.Components.Tabs

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp parse(html), do: Floki.parse_fragment!(html)
  defp q(doc, selector), do: Floki.find(doc, selector)
  defp text(nodes), do: nodes |> Floki.text() |> String.trim()

  describe "settings_page/1" do
    test "renders title, subtitle, actions and patch tabs" do
      html =
        render(
          fn assigns ->
            ~H"""
            <Settings.settings_page title="Account" subtitle="Manage your account.">
              <:actions><button>Export</button></:actions>
              <:tabs>
                <Tabs.tabs_list active_tab={@tab} aria-label="Settings">
                  <:tab name="general" patch="/settings">General</:tab>
                  <:tab name="connection" patch="/settings?tab=connection">Connection</:tab>
                </Tabs.tabs_list>
              </:tabs>
              <p>body</p>
            </Settings.settings_page>
            """
          end,
          %{tab: "connection"}
        )

      doc = parse(html)
      assert text(q(doc, "h2.lui-page-title")) == "Account"
      assert text(q(doc, "p.lui-page-desc")) == "Manage your account."
      assert html =~ "Export"

      active = q(doc, ".lui-settings-page-tabs [aria-selected=true]")
      assert Floki.attribute(active, "href") == ["/settings?tab=connection"]
      assert Floki.attribute(active, "data-phx-link") == ["patch"]
    end

    test "omits subtitle, actions and tabs wrappers when not given" do
      html =
        render(fn assigns ->
          ~H"""
          <Settings.settings_page title="Account">
            <p>body</p>
          </Settings.settings_page>
          """
        end)

      refute html =~ "lui-page-desc"
      refute html =~ "lui-page-header-actions"
      refute html =~ "lui-settings-page-tabs"
    end
  end

  describe "settings_section/1" do
    test "renders label column, fields and right-aligned actions, labelled by its title" do
      html =
        render(fn assigns ->
          ~H"""
          <Settings.settings_section id="profile" title="Profile" description="Your name.">
            <input name="name" />
            <:actions><button type="submit">Save</button></:actions>
          </Settings.settings_section>
          """
        end)

      doc = parse(html)
      section = q(doc, "section.lui-settings-section#profile")
      assert Floki.attribute(section, "aria-labelledby") == ["profile-title"]
      assert text(q(doc, "h3#profile-title")) == "Profile"
      assert text(q(doc, ".lui-settings-section-desc")) == "Your name."

      assert Enum.count(q(doc, ".lui-settings-section-body > input")) == 1

      assert text(q(doc, ".lui-settings-section-body > .lui-settings-section-actions")) =~ "Save"
    end

    test "without id or actions renders no label wiring or footer" do
      html =
        render(fn assigns ->
          ~H"""
          <Settings.settings_section title="Profile"><input /></Settings.settings_section>
          """
        end)

      refute html =~ "aria-labelledby"
      refute html =~ "lui-settings-section-actions"
      refute html =~ "lui-settings-section-desc"
    end
  end

  describe "danger_zone/1" do
    test "is a settings section with a bordered list of items" do
      html =
        render(fn assigns ->
          ~H"""
          <Settings.danger_zone id="danger">
            <Settings.danger_zone_item title="Delete account" description="Cannot be undone.">
              <:action><button>Delete</button></:action>
            </Settings.danger_zone_item>
            <Settings.danger_zone_item title="Transfer">
              <:action><button>Transfer</button></:action>
            </Settings.danger_zone_item>
          </Settings.danger_zone>
          """
        end)

      doc = parse(html)
      assert Enum.count(q(doc, "section.lui-settings-section.lui-danger-zone")) == 1
      assert text(q(doc, "h3#danger-title")) == "Danger zone"

      items = q(doc, ".lui-danger-zone-list > .lui-danger-zone-item")
      assert Enum.count(items) == 2
      assert html =~ "Cannot be undone."
      assert Enum.count(q(doc, ".lui-danger-zone-item-desc")) == 1
      assert text(q(doc, ".lui-danger-zone-item-action")) =~ "Delete"
    end
  end

  describe "navlink/1 with :item children" do
    defp group(assigns) do
      ~H"""
      <Navlist.navlink icon="adjustments-horizontal" expanded={@expanded}>
        Settings
        <:item navigate="/settings" active={@page == :general}>General</:item>
        <:item patch="/settings/workspace" active={@page == :workspace}>Workspace</:item>
      </Navlist.navlink>
      """
    end

    test "renders a details group, open when a child is active" do
      html = render(&group/1, %{page: :workspace, expanded: false})
      doc = parse(html)

      details = q(doc, "details.lui-navlink-group")
      assert Floki.attribute(details, "open") != []
      assert html =~ "ignore_attrs"
      assert text(q(doc, "summary.lui-navlink")) =~ "Settings"

      active = q(doc, ".lui-navlink-items > a[aria-current=page]")
      assert text(active) =~ "Workspace"
      assert Floki.attribute(active, "href") == ["/settings/workspace"]
      assert Enum.count(q(doc, ".lui-navlink-items > a")) == 2
    end

    test "renders closed when no child is active, open when expanded" do
      closed = parse(render(&group/1, %{page: :other, expanded: false}))
      assert Floki.attribute(q(closed, "details"), "open") == []
      assert Enum.count(q(closed, "[aria-current]")) == 0

      open = parse(render(&group/1, %{page: :other, expanded: true}))
      assert Floki.attribute(q(open, "details"), "open") != []
    end

    test "a navlink without items still renders a plain link" do
      html =
        render(fn assigns ->
          ~H"""
          <Navlist.navlink navigate="/x">X</Navlist.navlink>
          """
        end)

      refute html =~ "<details"
      assert html =~ ~s(href="/x")
    end
  end

  test "use LanternUI imports the settings components" do
    imports = LanternUI.__component_imports__(Settings)

    assert {:settings_page, 1} in imports
    assert {:settings_section, 1} in imports
    assert {:danger_zone, 1} in imports
    assert {:danger_zone_item, 1} in imports
  end
end
