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
              %{
                :"phx-click" => "save",
                :"phx-value-record-id" => "r-1",
                id: "save",
                label: "Save",
                icon: "check",
                priority: 10
              },
              %{id: "export", label: "Export", navigate: "/export"},
              %{:"phx-click" => "delete", id: "delete", label: "Delete", destructive: true}
            ]}
          />
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "#page-actions[phx-hook='LanternActionBar']") != []
      assert Floki.find(doc, "#page-actions[data-promoted]") == []
      assert Floki.find(doc, "#page-actions-save-inline") != []
      assert Floki.find(doc, "#page-actions-save-menu") != []

      assert Floki.attribute(Floki.find(doc, "#page-actions-save-inline"), "phx-value-record-id") ==
               ["r-1"]

      assert Floki.attribute(Floki.find(doc, "#page-actions-save-menu"), "phx-value-record-id") ==
               ["r-1"]

      assert Floki.find(doc, "#page-actions-export-inline") != []
      assert Floki.find(doc, "#page-actions-export-menu[href='/export']") != []
      assert Floki.find(doc, "#page-actions-delete-inline") != []
      assert Floki.find(doc, "#page-actions-delete-menu[data-tone='danger']") != []
      assert Floki.find(doc, "[role='menu']") != []
      assert Floki.text(Floki.find(doc, ".lui-sr-only")) =~ "More"
    end

    test "scopes duplicate action ids to their own bars" do
      html =
        render(fn assigns ->
          ~H"""
          <div>
            <ActionBar.action_bar id="left" actions={[%{id: "edit", label: "Edit"}]} />
            <ActionBar.action_bar id="right" actions={[%{id: "edit", label: "Edit"}]} />
          </div>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert length(Floki.find(doc, "#left-edit-inline")) == 1
      assert length(Floki.find(doc, "#left-edit-menu")) == 1
      assert length(Floki.find(doc, "#right-edit-inline")) == 1
      assert length(Floki.find(doc, "#right-edit-menu")) == 1
    end

    test "rejects repeated action ids within the same bar" do
      assert_raise ArgumentError, ~r/action ids must be unique within an action bar/, fn ->
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="duplicate-actions"
            actions={[
              %{id: "edit", label: "Edit"},
              %{id: "edit", label: "Edit again"}
            ]}
          />
          """
        end)
      end
    end

    test "promotion follows priority and skips disabled or non-promotable actions" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="ordered"
            actions={[
              %{id: "low", label: "Low", priority: 1},
              %{id: "high", label: "High", priority: 20},
              %{id: "locked", label: "Locked", priority: 100, enabled: false},
              %{id: "background", label: "Background", priority: 90, promotable: false},
              %{id: "middle", label: "Middle", priority: 10}
            ]}
          />
          """
        end)

      actions = Floki.parse_fragment!(html) |> Floki.find(".lui-action-bar-action")

      indexes =
        Map.new(actions, fn action ->
          [id] = Floki.attribute(action, "data-action-id")
          [index] = Floki.attribute(action, "data-promoted-index")
          {id, index}
        end)

      assert indexes == %{
               "high" => "1",
               "middle" => "2",
               "low" => "3",
               "locked" => "0",
               "background" => "0"
             }
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

      doc = Floki.parse_fragment!(html)
      assert [notice] = Floki.find(doc, "[data-action-bar-notice][data-tone='promo']")
      assert Floki.attribute(notice, "data-notice-id") == ["sync-4"]
      assert Floki.attribute(notice, "data-tone-slots") == ["data-tone-slots"]
      assert Floki.attribute(notice, "role") == ["status"]

      assert Floki.attribute(Floki.find(doc, "#page-actions"), "data-dismissal-event") == [
               "dismiss_notice"
             ]

      assert Floki.attribute(Floki.find(doc, "[data-part='dismiss']"), "aria-label") == [
               "Hide update"
             ]

      assert Floki.find(doc, "button#page-actions-locked-menu[disabled]") != []
      assert Floki.text(Floki.find(doc, "#page-actions-locked-menu")) =~ "Requires access"
      assert Floki.attribute(notice, "data-server-dismissed") == ["false"]
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

      doc = Floki.parse_fragment!(html)
      assert [notice] = Floki.find(doc, "[data-action-bar-notice][hidden]")
      assert Floki.attribute(notice, "data-server-dismissed") == ["true"]
    end

    test "danger notices use alert semantics on first render" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar id="danger" notice={%{id: "incident", tone: "danger", title: "Failed"}} />
          """
        end)

      assert [notice] =
               Floki.parse_fragment!(html) |> Floki.find("[data-action-bar-notice][role='alert']")

      assert Floki.text(notice) =~ "Failed"
    end
  end
end
