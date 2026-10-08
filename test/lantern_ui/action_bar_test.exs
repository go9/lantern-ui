defmodule LanternUI.ActionBarTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.ActionBar

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "action_bar/1" do
    test "renders every action inline and in the Zag More menu" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="page-actions"
            more_actions_label="More"
            actions={[
              %{:"phx-click" => "save", id: "save", label: "Save", icon: "check", priority: 10},
              %{id: "export", label: "Export", navigate: "/export"},
              %{:"phx-click" => "delete", id: "delete", label: "Delete", destructive: true}
            ]}
          />
          """
        end)

      assert html =~ ~s(id="page-actions")
      assert html =~ ~s(phx-hook="LanternActionBar")
      assert html =~ ~s(data-promoted="3")
      assert html =~ ~s(id="save-inline")
      assert html =~ ~s(id="save-menu")
      assert html =~ ~s(id="export-inline")
      assert html =~ ~s(id="export-menu")
      assert html =~ ~s(id="delete-inline")
      assert html =~ ~s(id="delete-menu")
      assert html =~ ~s(lui-sr-only">More</span>)
      assert html =~ ~s(role="menu")
      assert html =~ ~s(href="/export")
      assert html =~ ~s(data-tone="danger")
    end

    test "keeps disabled actions in More with their reason and renders a dismissible notice" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="page-actions"
            notice={%{id: "sync-4", tone: "promo", title: "Update", body: "Ready"}}
            on_dismiss="dismiss_notice"
            dismiss_label="Hide update"
            actions={[
              %{id: "locked", label: "Locked", enabled: false, disabled_reason: "Requires access"}
            ]}
          />
          """
        end)

      assert html =~ ~s(data-action-bar-notice)
      assert html =~ ~s(data-tone="promo")
      assert html =~ ~s(data-notice-id="sync-4")
      assert html =~ ~s(data-dismissal-event="dismiss_notice")
      assert html =~ ~s(aria-label="Hide update")
      assert html =~ ~s(disabled aria-label="Locked")
      assert html =~ "Requires access"
      assert html =~ ~s(id="locked-menu")
      assert html =~ ~s(data-server-dismissed="false")
    end

    test "server dismissal is rendered as hidden state" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="page-actions"
            dismissed
            notice={%{id: "sync-4", title: "Update", body: "Ready"}}
          />
          """
        end)

      assert html =~ ~s(data-server-dismissed="true")
      assert html =~ ~s(hidden data-action-bar-notice)
    end
  end
end
