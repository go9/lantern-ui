defmodule LanternUI.ARIAConformanceTest do
  @moduledoc """
  The ARIA gate, run across the components that declare a `role`.

  Components with no role surface (button, badge, separator, ...) are out of
  scope by construction — there is no relationship to resolve.

  Each render declares which attributes its JS hook owns at runtime; those are
  exempt from the server-render assertion. The declaration IS the contract.
  """
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.Modal
  alias LanternUI.Components.Select
  alias LanternUI.Components.Sheet
  alias LanternUI.Components.Switch
  alias LanternUI.Components.Tabs
  alias LanternUI.Components.Tooltip

  defp render(fun), do: fun.(%{__changed__: nil}) |> rendered_to_string()

  defp assert_conformant(html, opts \\ []) do
    case ARIAConformance.audit(html, opts) do
      [] ->
        :ok

      violations ->
        flunk("ARIA conformance violations:\n" <> ARIAConformance.report(violations))
    end
  end

  defp violations(html, opts), do: ARIAConformance.audit(html, opts)

  # `aria-expanded` is server-rendered as a literal and flipped by the hook at
  # runtime (lantern_ui_hooks.js:350,360,855,867,983). `aria-activedescendant`
  # is deliberately absent: this library uses roving DOM focus, a legitimate
  # APG pattern (hooks call opts[...].focus()). Do not "fix" that into
  # activedescendant — see flicker #945.
  @hook_owned ["aria-expanded"]

  describe "conformant today (regression guard)" do
    test "sheet: dialog has an accessible name and no dangling idrefs" do
      render(fn assigns ->
        ~H"""
        <Sheet.sheet id="edit" placement="right" title="Edit theme">BODY</Sheet.sheet>
        """
      end)
      |> assert_conformant()
    end
  end

  describe "defect list (#945) — regenerated mechanically, not by hand" do
    # Found by the gate, missed by a hand survey: `sheet` names its dialog with
    # `aria-label={@title}` (sheet.ex:81) but `modal` — which shares the dialog
    # runtime — declares no :title attr at all and leaves role="dialog"
    # unnamed (modal.ex:71). The only aria-label in modal.ex is on the close
    # button (:79). Two siblings, one contract, disagreeing.
    test "modal: role=dialog has no accessible name" do
      html =
        render(fn assigns ->
          ~H"""
          <Modal.modal id="m">BODY</Modal.modal>
          """
        end)

      found = violations(html, hook_owned: @hook_owned)

      assert Enum.any?(found, &(&1.kind == :missing_accessible_name and &1.role == "dialog")),
             "modal now names its dialog — promote it into the conformant block"
    end

    test "switch: no role=switch, so no aria-checked state is exposed" do
      html =
        render(fn assigns ->
          ~H"""
          <Switch.switch name="dark" checked={true} label="Dark mode" />
          """
        end)

      refute html =~ ~s(role="switch"),
             "switch now declares role=switch — promote it into the conformant block"
    end

    test "select: listbox is never referenced by the combobox" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select name="channel" value="ebay" options={["eBay", "Shopify"]} />
          """
        end)

      refute html =~ ~s(aria-controls),
             "select now wires aria-controls — promote it into the conformant block"
    end

    test "tooltip: role=tooltip panel has no id, so nothing can describe-by it" do
      html =
        render(fn assigns ->
          ~H"""
          <Tooltip.tooltip value="Hint">Trigger</Tooltip.tooltip>
          """
        end)

      assert html =~ ~s(role="tooltip")

      refute html =~ ~s(aria-describedby),
             "tooltip now wires aria-describedby — promote it into the conformant block"
    end

    test "tabs: tab role is missing its APG companions" do
      html =
        render(fn assigns ->
          ~H"""
          <Tabs.tabs id="t">
            <Tabs.tabs_list active_tab="all">
              <:tab name="all">All</:tab>
              <:tab name="pending">Pending</:tab>
            </Tabs.tabs_list>
            <Tabs.tabs_panel name="all" active={true}>A</Tabs.tabs_panel>
            <Tabs.tabs_panel name="pending" active={false}>P</Tabs.tabs_panel>
          </Tabs.tabs>
          """
        end)

      found = violations(html, hook_owned: @hook_owned)

      # This is the live defect list for tabs. It shrinks to [] as #945 lands.
      assert found != [], "tabs is now conformant — promote it into the conformant block"

      IO.puts(
        "\n  tabs violations (authoritative, from the gate):\n" <> ARIAConformance.report(found)
      )
    end
  end
end
