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
  alias LanternUI.Components.Accordion
  alias LanternUI.Components.Dropdown
  alias LanternUI.Components.Menu
  alias LanternUI.Components.Modal
  alias LanternUI.Components.Pagination
  alias LanternUI.Components.Popover
  alias LanternUI.Components.Radio
  alias LanternUI.Components.Sheet
  alias LanternUI.Components.Slider
  alias LanternUI.Components.Switch
  alias LanternUI.Components.Tabs
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

  describe "accordion/1 zag markup" do
    test "hook root is the Zag root; items carry stable ids and anatomy" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="faq">
            <Accordion.accordion_item id="ship" expanded>
              <:header>Shipping</:header>
              <:panel>Worldwide.</:panel>
            </Accordion.accordion_item>
            <Accordion.accordion_item id="ret">
              <:header>Returns</:header>
              <:panel>Thirty days.</:panel>
            </Accordion.accordion_item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(phx-hook="LanternAccordion")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="accordion" data-part="root")
      assert html =~ ~s(data-scope="accordion" data-part="item")
      assert html =~ ~s(data-scope="accordion" data-part="item-trigger")
      assert html =~ ~s(data-scope="accordion" data-part="item-content")
      assert html =~ ~s(id="ship-trigger")
      assert html =~ ~s(id="ship-panel")
      assert html =~ ~s(data-value="ship")
    end

    test "controlled mode renders the server value" do
      html =
        render(fn assigns ->
          ~H"""
          <Accordion.accordion id="faq" controlled value={["ret"]}>
            <Accordion.accordion_item id="ship">
              <:header>Shipping</:header>
              <:panel>Worldwide.</:panel>
            </Accordion.accordion_item>
            <Accordion.accordion_item id="ret">
              <:header>Returns</:header>
              <:panel>Thirty days.</:panel>
            </Accordion.accordion_item>
          </Accordion.accordion>
          """
        end)

      assert html =~ ~s(data-controlled)
      assert html =~ ~s(data-value="[&quot;ret&quot;]")
    end
  end

  describe "slider/1 zag markup" do
    test "hook root carries data-zag and the hidden input stays the form surface" do
      html =
        render(fn assigns ->
          ~H"""
          <Slider.slider id="vol" name="volume" value={40} label="Volume" />
          """
        end)

      assert html =~ ~s(phx-hook="LanternSlider")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(id="vol-slider")
      assert html =~ ~s(data-scope="slider" data-part="root")
      assert html =~ ~s(data-scope="slider" data-part="control")
      assert html =~ ~s(data-scope="slider" data-part="range")
      assert html =~ ~s(data-scope="slider" data-part="thumb")
      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="volume" value="40")
      assert html =~ ~s(role="slider")
    end
  end

  describe "tabs_list/1 zag markup" do
    test "hooked tablists carry data-zag and trigger anatomy; links intact" do
      html =
        render(fn assigns ->
          ~H"""
          <Tabs.tabs_list id="scope" active_tab="all">
            <:tab name="all" patch="/tickets">All</:tab>
            <:tab name="active" patch="/tickets?scope=active">Active</:tab>
          </Tabs.tabs_list>
          """
        end)

      assert html =~ ~s(phx-hook="LanternTabs")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="tabs")
      assert html =~ ~s(data-active-tab="all")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-value="all")
      assert html =~ ~s(href="/tickets")
      assert html =~ ~s(role="tab")
    end

    test "radiogroup lists stay off Zag on the legacy keyboard path" do
      html =
        render(fn assigns ->
          ~H"""
          <Tabs.tabs_list id="scope" role="radiogroup">
            <:tab name="all">All</:tab>
          </Tabs.tabs_list>
          """
        end)

      assert html =~ ~s(phx-hook="LanternTabs")
      refute html =~ ~s(data-zag)
    end
  end

  describe "pagination/1 zag markup" do
    test "nav root carries data-zag with URL-truth attrs; links intact" do
      html =
        render(fn assigns ->
          ~H"""
          <Pagination.pagination
            meta={%{current_page: 3, total_pages: 10, page_size: 10, total_count: 100}}
            patch_fn={fn params -> "/orders?#{URI.encode_query(params)}" end}
          />
          """
        end)

      assert html =~ ~s(phx-hook="LanternPagination")
      assert html =~ ~s(data-zag)
      assert html =~ ~s(data-scope="pagination" data-part="root")
      assert html =~ ~s(data-value="3")
      assert html =~ ~s(data-total-pages="10")
      assert html =~ ~s(aria-label="Pagination")
      assert html =~ ~s(data-part="item")
      assert html =~ ~s(href="/orders?page=4")
    end
  end
end
