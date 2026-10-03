defmodule LanternUI.ZagWidgetsTest do
  @moduledoc """
  Zag-driven widget rollout A (flicker #3416, step 2, PR A + PR B).

  Tooltip, popover, switch, radio, modal/alert_dialog, sheet, dropdown,
  and menu render Zag anatomy (`data-scope` + `data-part`) under the
  unchanged public attrs and `lui-*` styling, with `data-zag` marking roots
  the owning hook lazily upgrades to a `@zag-js/*` machine. Native inputs
  stay the form surface for switch/radio; `LanternUI.open_dialog/2` and
  `close_dialog/2` keep working through `lantern:dialog:*` events.
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.AlertDialog
  alias LanternUI.Components.Dropdown
  alias LanternUI.Components.Menu
  alias LanternUI.Components.Modal
  alias LanternUI.Components.Popover
  alias LanternUI.Components.Radio
  alias LanternUI.Components.Sheet
  alias LanternUI.Components.Switch
  alias LanternUI.Components.Tooltip

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "tooltip/1 zag markup" do
    test "marks the hook root and keeps the public hook name and attrs" do
      html =
        render(fn assigns ->
          ~H"""
          <Tooltip.tooltip id="t1" value="Tip" placement="bottom" delay={125}>
            Hover
          </Tooltip.tooltip>
          """
        end)

      assert html =~ ~s(phx-hook="LanternTooltip")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-placement="bottom")
      assert html =~ ~s(data-delay="125")
      assert html =~ ~s(data-default-value="false")
      refute html =~ ~s(data-controlled)
      assert html =~ ~s(data-scope="tooltip" data-part="trigger")
      assert html =~ ~s(data-scope="tooltip" data-part="positioner")
      assert html =~ ~s(data-scope="tooltip" data-part="content")
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Tooltip.tooltip id="t1" value="Tip" controlled open>
            Hover
          </Tooltip.tooltip>
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="true")
      refute html =~ ~s(data-default-value)
    end
  end

  describe "popover/1 zag markup" do
    test "marks the hook root and keeps the public hook name and attrs" do
      html =
        render(fn assigns ->
          ~H"""
          <Popover.popover id="p1" placement="bottom-end">
            <button>Filters</button>
            <:content>Body</:content>
          </Popover.popover>
          """
        end)

      assert html =~ ~s(phx-hook="LanternOverlay")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="popover" data-part="trigger")
      assert html =~ ~s(data-scope="popover" data-part="positioner")
      assert html =~ ~s(data-scope="popover" data-part="content")
      assert html =~ ~s(role="dialog")
      refute html =~ ~s(role="menu")
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Popover.popover id="p1" controlled open>
            <button>t</button>
            <:content>c</:content>
          </Popover.popover>
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="true")
    end
  end

  describe "switch/1 zag markup" do
    test "hook root carries data-zag and the native form contract is intact" do
      html =
        render(fn assigns ->
          ~H"""
          <Switch.switch id="s1" name="notify" checked label="Notifications" />
          """
        end)

      assert html =~ ~s(phx-hook="LanternSwitch")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(id="s1-switch")
      assert html =~ ~s(data-input-id="s1")
      assert html =~ ~s(data-default-value="true")
      assert html =~ ~s(data-scope="switch" data-part="root")
      assert html =~ ~s(data-scope="switch" data-part="control")
      assert html =~ ~s(data-scope="switch" data-part="thumb")
      # native form contract: hidden unchecked value + named checkbox
      assert html =~ ~s(type="hidden" name="notify" value="false")
      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(id="s1")
      assert html =~ ~s(class="lui-switch-input")
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Switch.switch id="s1" name="notify" controlled checked={false} />
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="false")
    end
  end

  describe "radio/1 zag markup" do
    test "fieldset root carries data-zag and native inputs stay the form surface" do
      html =
        render(fn assigns ->
          ~H"""
          <Radio.radio name="plan" value="pro" label="Plan">
            <:radio value="basic" label="Basic" />
            <:radio value="pro" label="Pro" />
          </Radio.radio>
          """
        end)

      assert html =~ ~s(phx-hook="LanternRadio")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="radio-group" data-part="root")
      assert html =~ ~s(data-name="plan")
      assert html =~ ~s(data-default-value="pro")
      assert html =~ ~s(data-scope="radio-group" data-part="item")
      assert html =~ ~s(data-scope="radio-group" data-part="item-control")
      assert html =~ ~s(type="radio")
      assert html =~ ~s(name="plan")
      assert html =~ ~r/value="pro"[^>]*checked/
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Radio.radio name="plan" value="basic" controlled>
            <:radio value="basic" label="Basic" />
            <:radio value="pro" label="Pro" />
          </Radio.radio>
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="basic")
    end
  end

  describe "modal/1 zag markup" do
    test "hook root carries data-zag and dialog anatomy, dialog contracts intact" do
      html =
        render(fn assigns ->
          ~H"""
          <Modal.modal id="m1">Hello</Modal.modal>
          """
        end)

      assert html =~ ~s(phx-hook="LanternModal")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-role="dialog")
      assert html =~ ~s(data-default-value="false")
      assert html =~ ~s(data-scope="dialog" data-part="backdrop")
      assert html =~ ~s(data-scope="dialog" data-part="positioner")
      assert html =~ ~s(data-scope="dialog" data-part="content")
      assert html =~ ~s(data-scope="dialog" data-part="close-trigger")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ "Hello"
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Modal.modal id="m1" controlled open>Hello</Modal.modal>
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="true")
    end
  end

  describe "alert_dialog/1 zag markup" do
    test "composes the Zag modal with alertdialog role and real title ids" do
      html =
        render(fn assigns ->
          ~H"""
          <AlertDialog.alert_dialog id="del">
            <:title>Delete?</:title>
            <:description>Irreversible.</:description>
            <:cancel><button>Cancel</button></:cancel>
            <:action><button>Delete</button></:action>
          </AlertDialog.alert_dialog>
          """
        end)

      assert html =~ ~s(phx-hook="LanternModal")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-role="alertdialog")
      assert html =~ ~s(role="alertdialog")
      assert html =~ ~s(aria-labelledby="del-title")
      assert html =~ ~s(aria-describedby="del-description")
      assert html =~ ~s(data-title-id="del-title")
      assert html =~ ~s(data-description-id="del-description")
    end
  end

  describe "sheet/1 zag markup" do
    test "hook root carries data-zag, placement, and dialog anatomy" do
      html =
        render(fn assigns ->
          ~H"""
          <Sheet.sheet id="s" placement="left" title="Edit">Body</Sheet.sheet>
          """
        end)

      assert html =~ ~s(phx-hook="LanternSheet")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-placement="left")
      assert html =~ ~s(data-scope="dialog" data-part="backdrop")
      assert html =~ ~s(data-scope="dialog" data-part="positioner")
      assert html =~ ~s(data-scope="dialog" data-part="content")
      assert html =~ ~s(role="dialog")
      assert html =~ "Edit"
      assert html =~ "Body"
    end
  end

  describe "dropdown/1 zag markup" do
    test "hook root carries data-zag and menu anatomy with role=menu" do
      html =
        render(fn assigns ->
          ~H"""
          <Dropdown.dropdown id="dd" label="Actions">
            <Dropdown.dropdown_button phx-click="go">Go</Dropdown.dropdown_button>
          </Dropdown.dropdown>
          """
        end)

      assert html =~ ~s(phx-hook="LanternDropdown")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="menu" data-part="trigger")
      assert html =~ ~s(data-scope="menu" data-part="positioner")
      assert html =~ ~s(data-scope="menu" data-part="content")
      assert html =~ ~s(role="menu")
      assert html =~ ~s(role="menuitem")
      assert html =~ "Go"
    end
  end

  describe "menu/1 zag markup" do
    test "component-owned trigger keeps stable ids under menu anatomy" do
      html =
        render(fn assigns ->
          ~H"""
          <Menu.menu id="file" label="File">
            <Menu.menu_item phx-click="new">New</Menu.menu_item>
          </Menu.menu>
          """
        end)

      assert html =~ ~s(phx-hook="LanternMenu")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(id="file-trigger")
      assert html =~ ~s(id="file-menu")
      assert html =~ ~s(data-scope="menu" data-part="trigger")
      assert html =~ ~s(data-scope="menu" data-part="content")
      assert html =~ ~s(role="menu")
      assert html =~ ~s(aria-labelledby="file-trigger")
      assert html =~ "New"
    end
  end
end
