defmodule LanternUI.CommandTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Command

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp palette(assigns \\ %{}) do
    render(
      fn assigns ->
        ~H"""
        <Command.command id="cmd">
          <Command.command_group label="Tickets">
            <Command.command_item value="t-1">Fix the proxy</Command.command_item>
            <Command.command_item value="t-2">Rotate the key</Command.command_item>
          </Command.command_group>
          <Command.command_separator />
          <Command.command_empty>No results</Command.command_empty>
        </Command.command>
        """
      end,
      assigns
    )
  end

  describe "root" do
    test "renders the hook, dialog chrome, and the closed default" do
      html = palette()

      assert html =~ ~s(id="cmd")
      assert html =~ ~s(class="lui-command")
      assert html =~ ~s(phx-hook="LanternCommand")
      assert html =~ ~s(data-part="backdrop")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~s(data-part="input")
      assert html =~ ~s(data-part="list")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-label="Command palette")
      # closed until open_dialog/1 fires
      assert html =~ "hidden"
      refute html =~ "data-open"
    end

    test "hook configuration rides on data-* with command_* event defaults" do
      html = palette()

      assert html =~ ~s(data-on-search="command_search")
      assert html =~ ~s(data-on-select="command_select")
      assert html =~ ~s(data-debounce="200")
      assert html =~ ~s(data-hotkey="k")
      assert html =~ ~s(data-search-on-open="true")
      assert html =~ ~s(data-close-on-esc="true")
      assert html =~ ~s(data-close-on-outside="true")
      assert html =~ ~s(data-close-on-select="true")
    end

    test "opt-outs render as false / absent, never as a silently ignored attr" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command
            id="cmd"
            open
            hotkey={nil}
            on_search={nil}
            on_select={nil}
            debounce={50}
            search_on_open={false}
            close_on_esc={false}
            close_on_outside_click={false}
            close_on_select={false}
          >
            <Command.command_empty>None</Command.command_empty>
          </Command.command>
          """
        end)

      assert html =~ "data-open"
      assert html =~ ~s(data-debounce="50")
      assert html =~ ~s(data-search-on-open="false")
      assert html =~ ~s(data-close-on-esc="false")
      assert html =~ ~s(data-close-on-outside="false")
      assert html =~ ~s(data-close-on-select="false")
      refute html =~ "data-hotkey"
      refute html =~ "data-on-search"
      refute html =~ "data-on-select"
    end

    test "label names both the dialog and the listbox; placeholder reaches the input" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd" label="Search flicker" placeholder="Find anything…">
            <Command.command_empty>None</Command.command_empty>
          </Command.command>
          """
        end)

      [dialog] = Floki.parse_fragment!(html) |> Floki.find(~s([role="dialog"]))
      [listbox] = Floki.parse_fragment!(html) |> Floki.find(~s([role="listbox"]))

      assert Floki.attribute(dialog, "aria-label") == ["Search flicker"]
      assert Floki.attribute(listbox, "aria-label") == ["Search flicker"]
      assert html =~ ~s(placeholder="Find anything…")
    end

    test "loading row is hidden until loading is set" do
      assert palette() =~ ~s(data-part="loading")

      assert Floki.parse_fragment!(palette()) |> Floki.find(~s([data-part="loading"][hidden])) !=
               []

      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd" loading>
            <Command.command_empty>None</Command.command_empty>
          </Command.command>
          """
        end)

      assert Floki.parse_fragment!(html) |> Floki.find(~s([data-part="loading"][hidden])) == []
    end

    test "footer slot renders only when given" do
      refute palette() =~ "lui-command-footer"

      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_empty>None</Command.command_empty>
            <:footer>↑↓ to navigate</:footer>
          </Command.command>
          """
        end)

      assert html =~ "lui-command-footer"
      assert html =~ "↑↓ to navigate"
    end
  end

  describe "global-mount safety (flicker: a global phx-change=\"search\" broke 5 tests)" do
    test "renders no form element and no phx-change/phx-submit binding" do
      html = palette()

      assert Floki.parse_fragment!(html) |> Floki.find("form") == []
      refute html =~ "phx-change"
      refute html =~ "phx-submit"
      refute html =~ "phx-keyup"
    end

    test "default event names are namespaced, not generic" do
      [root] = palette() |> Floki.parse_fragment!() |> Floki.find(~s([phx-hook="LanternCommand"]))

      assert Floki.attribute(root, "data-on-search") == ["command_search"]
      assert Floki.attribute(root, "data-on-select") == ["command_select"]
      refute Floki.attribute(root, "data-on-search") == ["search"]
      refute Floki.attribute(root, "data-on-select") == ["select"]
    end
  end

  describe "consumer-driven filtering" do
    test "renders every item it is handed, in order, with no client-side matching config" do
      html = palette()

      items = Floki.parse_fragment!(html) |> Floki.find(~s([data-part="item"]))

      assert length(items) == 2
      assert html =~ "Fix the proxy"
      assert html =~ "Rotate the key"
      # No search-mode/threshold knobs: the component never decides what matches.
      refute html =~ "data-search-mode"
      refute html =~ "data-search-threshold"
    end
  end

  describe "group" do
    test "labels itself through a resolvable idref and auto-generates an id" do
      html = palette()
      doc = Floki.parse_fragment!(html)

      [group] = Floki.find(doc, ~s([data-part="group"]))
      [labelledby] = Floki.attribute(group, "aria-labelledby")
      [id] = Floki.attribute(group, "id")

      assert String.starts_with?(id, "lui-cmd-group-")
      assert Floki.find(doc, "##{labelledby}") != []
      assert Floki.find(doc, "##{labelledby}") |> Floki.text() == "Tickets"
      assert Floki.attribute(group, "role") == ["group"]
    end

    test "an unlabelled group carries no dangling aria-labelledby" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_group>
              <Command.command_item value="a">A</Command.command_item>
            </Command.command_group>
          </Command.command>
          """
        end)

      [group] = Floki.parse_fragment!(html) |> Floki.find(~s([data-part="group"]))

      assert Floki.attribute(group, "aria-labelledby") == []
      refute html =~ "lui-command-group-label"
    end

    test "an explicit id wins over the generated one" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_group id="grp" label="Pages">
              <Command.command_item value="a">A</Command.command_item>
            </Command.command_group>
          </Command.command>
          """
        end)

      assert html =~ ~s(id="grp")
      assert html =~ ~s(aria-labelledby="grp-label")
      assert html =~ ~s(id="grp-label")
    end
  end

  describe "item" do
    test "is an option button carrying its value and an addressable id" do
      html = palette()
      doc = Floki.parse_fragment!(html)

      [first, _second] = Floki.find(doc, ~s([data-part="item"]))

      assert Floki.attribute(first, "role") == ["option"]
      # server-rendered literal; LanternCommand flips it with the highlight
      assert Floki.attribute(first, "aria-selected") == ["false"]
      assert Floki.attribute(first, "data-value") == ["t-1"]
      assert Floki.attribute(first, "type") == ["button"]
      assert Floki.attribute(first, "tabindex") == ["-1"]
      assert [id] = Floki.attribute(first, "id")
      assert String.starts_with?(id, "lui-cmd-item-")
    end

    test "items get distinct ids so aria-activedescendant can address each one" do
      ids =
        palette()
        |> Floki.parse_fragment!()
        |> Floki.find(~s([data-part="item"]))
        |> Floki.attribute("id")

      assert length(ids) == 2
      assert Enum.uniq(ids) == ids
    end

    test "non-string values are stringified for the select payload" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_item value={42}>Answer</Command.command_item>
          </Command.command>
          """
        end)

      assert html =~ ~s(data-value="42")
    end

    test "disabled items are marked for both the browser and assistive tech" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_item value="a" disabled>Nope</Command.command_item>
          </Command.command>
          """
        end)

      [item] = Floki.parse_fragment!(html) |> Floki.find(~s([data-part="item"]))

      assert Floki.attribute(item, "disabled") == ["disabled"]
      assert Floki.attribute(item, "aria-disabled") == ["true"]
    end

    test "icon, description, and shortcut slots render into their own parts" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_item value="t-1">
              Fix the proxy
              <:icon>ICON</:icon>
              <:description>flicker #1234</:description>
              <:shortcut>⌘1</:shortcut>
            </Command.command_item>
          </Command.command>
          """
        end)

      assert html =~ "lui-command-item-icon"
      assert html =~ "ICON"
      assert html =~ "lui-command-item-description"
      assert html =~ "flicker #1234"
      assert html =~ "lui-command-shortcut"
      assert html =~ "⌘1"
    end

    test "per-item phx-click passes through (the hook suppresses its own push)" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd">
            <Command.command_item value="a" phx-click="go" phx-value-id="7">Go</Command.command_item>
          </Command.command>
          """
        end)

      assert html =~ ~s(phx-click="go")
      assert html =~ ~s(phx-value-id="7")
    end
  end

  describe "empty, separator, shortcut" do
    test "empty state is a status region the hook can toggle" do
      [empty] = palette() |> Floki.parse_fragment!() |> Floki.find(~s([data-part="empty"]))

      assert Floki.attribute(empty, "role") == ["status"]
      assert Floki.attribute(empty, "class") == ["lui-command-empty"]
      assert Floki.text(empty) =~ "No results"
    end

    test "separator carries role=separator" do
      [sep] = palette() |> Floki.parse_fragment!() |> Floki.find(~s([data-part="separator"]))

      assert Floki.attribute(sep, "role") == ["separator"]
    end

    test "standalone shortcut renders a kbd" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command_shortcut>⌘K</Command.command_shortcut>
          """
        end)

      assert html =~ "<kbd"
      assert html =~ "lui-command-shortcut"
      assert html =~ "⌘K"
    end
  end

  describe "class merge order" do
    test "consumer classes land last on every surface they target" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command
            id="cmd"
            container_class="mine-root"
            class="mine-panel"
            backdrop_class="mine-backdrop"
            list_class="mine-list"
          >
            <Command.command_group label="G" class="mine-group">
              <Command.command_item value="a" class="mine-item">A</Command.command_item>
            </Command.command_group>
            <Command.command_separator class="mine-sep" />
            <Command.command_empty class="mine-empty">None</Command.command_empty>
          </Command.command>
          """
        end)

      assert html =~ ~s(class="lui-command mine-root")
      assert html =~ ~s(class="lui-command-panel mine-panel")
      assert html =~ ~s(class="lui-command-backdrop mine-backdrop")
      assert html =~ ~s(class="lui-command-list mine-list")
      assert html =~ ~s(class="lui-command-group mine-group")
      assert html =~ ~s(class="lui-command-item mine-item")
      assert html =~ ~s(class="lui-command-separator mine-sep")
      assert html =~ ~s(class="lui-command-empty mine-empty")
    end
  end

  describe "registry + hook wiring" do
    test "command is importable through use LanternUI" do
      assert LanternUI.__components__()[:command] == Command
    end

    test "the LanternCommand hook is exported from the hooks bundle" do
      js = File.read!("priv/static/lantern_ui_hooks.js")

      assert js =~ "const LanternCommand = {"
      # once in the Hooks map, once in the named export block
      assert js |> String.split("\n  LanternCommand,") |> length() == 3
    end

    test "a LiveComponent target routes events to the component, not the parent" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd" target="#my-component">
            <Command.command_empty>none</Command.command_empty>
          </Command.command>
          """
        end)

      assert html =~ ~s(data-target="#my-component")
    end

    test "a target also emits phx-target so LiveView and its test harness route correctly" do
      html =
        render(fn assigns ->
          ~H"""
          <Command.command id="cmd" target="#my-component">
            <Command.command_empty>none</Command.command_empty>
          </Command.command>
          """
        end)

      # data-target drives the hook's own pushEventTo. phx-target is what
      # LiveView and LiveViewTest understand — without it a consumer cannot
      # test its own palette, because events route to the parent LiveView and
      # the component's handlers never run.
      assert html =~ ~s(data-target="#my-component")
      assert html =~ ~s(phx-target="#my-component")
    end

    test "the hook pushes to the target when one is given" do
      js = File.read!("priv/static/lantern_ui_hooks.js")

      hook =
        js
        |> String.split("const LanternCommand = {")
        |> Enum.at(1)
        |> String.split("\n// ── ")
        |> hd()

      # Without this the palette cannot be used from a LiveComponent at all —
      # events reach the parent LiveView, which then has to define handlers it
      # does not own. A global app-shell palette is always a LiveComponent.
      assert hook =~ "pushEventTo(target, event, payload)"
      refute hook =~ "this.pushEvent(event, { query:"
    end

    test "updated/0 re-asserts hidden, or the palette vanishes while you type" do
      js = File.read!("priv/static/lantern_ui_hooks.js")

      updated =
        js
        |> String.split("const LanternCommand = {")
        |> Enum.at(1)
        |> String.split("\n// ── ")
        |> hd()
        |> String.split("updated() {")
        |> Enum.at(1)
        |> String.split("\n  },")
        |> hd()

      # The render carries `hidden={!@open}` and @open defaults to false, so
      # EVERY server patch caused by on_search re-adds the attribute. Without
      # this line the palette disappears on the first keystroke while the hook
      # still believes it is open — found by driving it in a real browser,
      # invisible to every render-level test in this file.
      assert updated =~ "this.el.hidden = !this.open",
             "LanternCommand.updated() must re-assert visibility after a patch"
    end

    test "every data-part the hook queries exists in the render" do
      js = File.read!("priv/static/lantern_ui_hooks.js")

      hook =
        js
        |> String.split("const LanternCommand = {")
        |> Enum.at(1)
        |> String.split("\n// ── ")
        |> hd()

      queried =
        Regex.scan(~r/data-part="([a-z-]+)"/, hook)
        |> Enum.map(&Enum.at(&1, 1))
        |> Enum.uniq()
        # rendered by modal/sheet, optional here
        |> List.delete("close")

      html = palette()

      for part <- queried do
        assert html =~ ~s(data-part="#{part}"),
               "hook queries [data-part=#{part}] but the component never renders it"
      end
    end
  end
end
