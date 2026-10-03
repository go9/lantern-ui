defmodule LanternUI.ZagWidgetsTest do
  @moduledoc """
  Zag-driven widget rollout A (flicker #3416, step 2, PR A).

  Tooltip, popover, switch, and radio render Zag anatomy
  (`data-scope` + `data-part`) under the unchanged public attrs and
  `lui-*` styling, with `data-zag` marking roots the owning hook lazily
  upgrades to a `@zag-js/*` machine. Native inputs stay the form surface
  for switch/radio.
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Popover
  alias LanternUI.Components.Radio
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
end
