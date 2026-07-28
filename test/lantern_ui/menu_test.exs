defmodule LanternUI.MenuTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Menu

  # `aria-expanded` is a server-rendered literal the hook flips at runtime;
  # the hooks also own the roving `tabindex`. See the ARIA gate moduledoc.
  @hook_owned ["aria-expanded"]

  defmodule ImporterFixture do
    use Phoenix.Component
    use LanternUI, only: [:menu]

    def representative(assigns) do
      ~H"""
      <.menu id="file-actions" label="File">
        <.menu_item phx-click="new">New</.menu_item>
        <.menu_separator />
        <.menu_item phx-click="delete" data-danger>Delete</.menu_item>
      </.menu>
      """
    end
  end

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp basic_menu(assigns) do
    ~H"""
    <Menu.menu id="actions" label="Actions">
      <Menu.menu_item phx-click="edit">Edit</Menu.menu_item>
      <Menu.menu_item phx-click="duplicate" disabled>Duplicate</Menu.menu_item>
      <Menu.menu_separator />
      <Menu.menu_item phx-click="delete" data-danger>Delete</Menu.menu_item>
    </Menu.menu>
    """
  end

  defp basic_menubar(assigns) do
    ~H"""
    <Menu.menubar id="editor" label="Editor">
      <Menu.menubar_menu id="file" label="File">
        <Menu.menu_item phx-click="new">New</Menu.menu_item>
        <Menu.menu_item phx-click="open">Open…</Menu.menu_item>
      </Menu.menubar_menu>
      <Menu.menubar_menu id="edit" label="Edit">
        <Menu.menu_item phx-click="undo">Undo</Menu.menu_item>
      </Menu.menubar_menu>
    </Menu.menubar>
    """
  end

  describe "registry" do
    test "menu is importable via use LanternUI and exposes all four functions" do
      assert {:menu, Menu} in LanternUI.__components__()
      assert {:menu, 1} in Menu.__info__(:functions)
      assert {:menu_item, 1} in Menu.__info__(:functions)
      assert {:menu_separator, 1} in Menu.__info__(:functions)
      assert {:menubar, 1} in Menu.__info__(:functions)
      assert {:menubar_menu, 1} in Menu.__info__(:functions)

      assert render(&ImporterFixture.representative/1) =~ ~s(phx-hook="LanternMenu")
    end
  end

  describe "menu/1 — APG menu button" do
    test "root wires the hook, placement, and hook anatomy" do
      html = render(&basic_menu/1)
      doc = Floki.parse_fragment!(html)

      root = Floki.find(doc, "#actions")
      assert Floki.attribute(root, "class") == ["lui-menu"]
      assert Floki.attribute(root, "phx-hook") == ["LanternMenu"]
      assert Floki.attribute(root, "data-placement") == ["bottom-start"]
      assert length(Floki.find(doc, ~s([data-part="trigger"]))) == 1
      assert length(Floki.find(doc, ~s([data-part="menu"]))) == 1
    end

    test "the component-owned trigger carries the full menu-button ARIA contract" do
      doc = Floki.parse_fragment!(render(&basic_menu/1))
      trigger = Floki.find(doc, "#actions-trigger")

      assert Floki.attribute(trigger, "aria-haspopup") == ["menu"]
      assert Floki.attribute(trigger, "aria-expanded") == ["false"]
      assert Floki.attribute(trigger, "aria-controls") == ["actions-menu"]
      assert Floki.attribute(trigger, "data-part") == ["trigger"]
      assert Floki.attribute(trigger, "type") == ["button"]
    end

    test "the popup is a hidden, trigger-labelled role=menu with tabindex=-1 items" do
      doc = Floki.parse_fragment!(render(&basic_menu/1))
      menu = Floki.find(doc, "#actions-menu")

      assert Floki.attribute(menu, "role") == ["menu"]
      assert Floki.attribute(menu, "aria-labelledby") == ["actions-trigger"]
      assert Floki.attribute(menu, "hidden") == ["hidden"]

      items = Floki.find(doc, ~s([role="menuitem"]))
      assert length(items) == 3
      assert Enum.all?(items, &(Floki.attribute(&1, "tabindex") == ["-1"]))
      assert Floki.find(doc, ~s(#actions-menu [role="separator"])) != []
    end

    test "disabled items render the disabled attribute the hooks skip" do
      doc = Floki.parse_fragment!(render(&basic_menu/1))
      assert length(Floki.find(doc, ~s([role="menuitem"][disabled]))) == 1
    end

    test "auto-generates an id when omitted" do
      html =
        render(fn assigns ->
          ~H"""
          <Menu.menu label="More">
            <Menu.menu_item>One</Menu.menu_item>
          </Menu.menu>
          """
        end)

      assert html =~ ~r/id="lui-menu-\d+"/
      assert html =~ ~s(phx-hook="LanternMenu")
    end

    test "trigger slot replaces the label inside the component-owned button" do
      html =
        render(fn assigns ->
          ~H"""
          <Menu.menu id="m">
            <:trigger>Custom trigger</:trigger>
            <Menu.menu_item>One</Menu.menu_item>
          </Menu.menu>
          """
        end)

      assert html =~ "Custom trigger"
      # the trigger is still the component's button — ARIA stays wired
      assert html =~ ~s(aria-controls="m-menu")
    end

    test "consumer classes merge base-first; global attrs pass through" do
      html =
        render(fn assigns ->
          ~H"""
          <Menu.menu id="m" label="X" class="panel-x" container_class="root-x" data-testid="menu">
            <Menu.menu_item class="item-x" phx-click="go">Go</Menu.menu_item>
          </Menu.menu>
          """
        end)

      assert html =~ ~s(class="lui-menu root-x")
      assert html =~ ~s(class="lui-menu-panel panel-x")
      assert html =~ ~s(class="lui-menu-item item-x")
      assert html =~ ~s(data-testid="menu")
      assert html =~ ~s(phx-click="go")
    end

    test "passes the structural ARIA conformance gate" do
      html = render(&basic_menu/1)
      assert ARIAConformance.audit(html, hook_owned: @hook_owned) == []
    end
  end

  describe "menubar/1 — APG menubar" do
    test "root is a labelled role=menubar running the menubar hook" do
      doc = Floki.parse_fragment!(render(&basic_menubar/1))
      root = Floki.find(doc, "#editor")

      assert Floki.attribute(root, "role") == ["menubar"]
      assert Floki.attribute(root, "aria-label") == ["Editor"]
      assert Floki.attribute(root, "phx-hook") == ["LanternMenubar"]
    end

    test "each entry is a role=menuitem trigger controlling its labelled submenu" do
      doc = Floki.parse_fragment!(render(&basic_menubar/1))

      for id <- ~w(file edit) do
        trigger = Floki.find(doc, "##{id}-trigger")
        assert Floki.attribute(trigger, "role") == ["menuitem"]
        assert Floki.attribute(trigger, "aria-haspopup") == ["menu"]
        assert Floki.attribute(trigger, "aria-expanded") == ["false"]
        assert Floki.attribute(trigger, "aria-controls") == ["#{id}-menu"]

        menu = Floki.find(doc, "##{id}-menu")
        assert Floki.attribute(menu, "role") == ["menu"]
        assert Floki.attribute(menu, "aria-labelledby") == ["#{id}-trigger"]
        assert Floki.attribute(menu, "hidden") == ["hidden"]
      end
    end

    test "submenu items are tabindex=-1; top-level triggers leave roving to the hook" do
      doc = Floki.parse_fragment!(render(&basic_menubar/1))

      # Popup items are out of the tab order until the hook roves them.
      items = Floki.find(doc, ~s([data-part="menu"] [role="menuitem"]))
      assert length(items) == 3
      assert Enum.all?(items, &(Floki.attribute(&1, "tabindex") == ["-1"]))

      # Triggers render without tabindex (natively focusable buttons); the
      # hook establishes the single roving tab stop on mount.
      triggers = Floki.find(doc, ~s([data-part="trigger"]))
      assert length(triggers) == 2
      assert Enum.all?(triggers, &(Floki.attribute(&1, "tabindex") == []))
    end

    test "auto-generates ids when omitted" do
      html =
        render(fn assigns ->
          ~H"""
          <Menu.menubar label="Bar">
            <Menu.menubar_menu label="Only">
              <Menu.menu_item>One</Menu.menu_item>
            </Menu.menubar_menu>
          </Menu.menubar>
          """
        end)

      assert html =~ ~r/id="lui-menubar-\d+"/
      assert html =~ ~r/id="lui-menubar-menu-\d+-trigger"/
    end

    test "passes the structural ARIA conformance gate" do
      html = render(&basic_menubar/1)
      assert ARIAConformance.audit(html, hook_owned: @hook_owned) == []
    end
  end

  describe "hook registration (the silent no-op trap)" do
    test "LanternMenu and LanternMenubar are exported from the Hooks object" do
      hooks = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui_hooks.js"))

      assert hooks =~ "const LanternMenu = {"
      assert hooks =~ "const LanternMenubar = {"
      # both must appear inside the Hooks export or the phx-hook is a no-op
      [_before, exports] = String.split(hooks, "export const Hooks = {", parts: 2)
      [hooks_block, _rest] = String.split(exports, "}", parts: 2)
      assert hooks_block =~ "LanternMenu"
      assert hooks_block =~ "LanternMenubar"
    end
  end
end
