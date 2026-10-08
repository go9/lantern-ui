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
      assert Floki.find(doc, "#page-actions-action-c2F2ZQ-inline") != []
      assert Floki.find(doc, "#page-actions-action-c2F2ZQ-menu") != []

      assert Floki.attribute(
               Floki.find(doc, "#page-actions-action-c2F2ZQ-inline"),
               "phx-value-record-id"
             ) ==
               ["r-1"]

      assert Floki.attribute(
               Floki.find(doc, "#page-actions-action-c2F2ZQ-menu"),
               "phx-value-record-id"
             ) ==
               ["r-1"]

      assert Floki.find(doc, "#page-actions-action-ZXhwb3J0-inline") != []
      assert Floki.find(doc, "#page-actions-action-ZXhwb3J0-menu[href='/export']") != []
      assert Floki.find(doc, "#page-actions-action-ZGVsZXRl-inline") != []
      assert Floki.find(doc, "#page-actions-action-ZGVsZXRl-menu[data-tone='danger']") != []
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
      assert length(Floki.find(doc, "#left-action-ZWRpdA-inline")) == 1
      assert length(Floki.find(doc, "#left-action-ZWRpdA-menu")) == 1
      assert length(Floki.find(doc, "#right-action-ZWRpdA-inline")) == 1
      assert length(Floki.find(doc, "#right-action-ZWRpdA-menu")) == 1
    end

    test "encodes unusual descriptor ids in the bar-prefixed DOM ids" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar id="safe-actions" actions={[%{id: "delete:item", label: "Delete"}]} />
          """
        end)

      doc = Floki.parse_fragment!(html)
      [inline] = Floki.find(doc, ".lui-action-bar-action[data-action-id='delete:item'] button")
      [menu_item] = Floki.find(doc, "[role='menuitem'][data-action-id='delete:item']")
      [inline_id] = Floki.attribute(inline, "id")
      [menu_id] = Floki.attribute(menu_item, "id")

      assert inline_id == "safe-actions-action-ZGVsZXRlOml0ZW0-inline"
      assert menu_id == "safe-actions-action-ZGVsZXRlOml0ZW0-menu"
      refute inline_id =~ ~r/[\s:]/
      refute menu_id =~ ~r/[\s:]/
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

    test "promotion order follows priority then source order and leaves destructive menu items last" do
      html =
        render(fn assigns ->
          ~H"""
          <ActionBar.action_bar
            id="ordered"
            actions={[
              %{id: "low", label: "Low", priority: 1},
              %{id: "high", label: "High", priority: 30},
              %{id: "tie-first", label: "First tie", priority: 20},
              %{id: "locked", label: "Locked", priority: 100, enabled: false},
              %{id: "disabled", label: "Disabled", priority: 95, disabled: true},
              %{id: "background", label: "Background", priority: 90, promotable: false},
              %{id: "tie-second", label: "Second tie", priority: 20},
              %{id: "middle", label: "Middle", priority: 10},
              %{id: "delete", label: "Delete", priority: 0, destructive: true}
            ]}
          />
          """
        end)

      doc = Floki.parse_fragment!(html)

      inline_actions = Floki.find(doc, "#ordered .lui-action-bar-action")

      inline_order =
        Enum.map(inline_actions, fn action ->
          [id] = Floki.attribute(action, "data-action-id")
          [index] = Floki.attribute(action, "data-promoted-index")
          {id, index}
        end)

      assert inline_order == [
               {"high", "1"},
               {"tie-first", "2"},
               {"tie-second", "3"},
               {"middle", "4"},
               {"low", "5"},
               {"delete", "6"},
               {"locked", "0"},
               {"disabled", "0"},
               {"background", "0"}
             ]

      menu_order =
        doc
        |> Floki.find("#ordered [role='menuitem']")
        |> Enum.map(fn item -> Floki.attribute(item, "data-action-id") |> hd() end)

      assert menu_order == [
               "low",
               "high",
               "tie-first",
               "locked",
               "disabled",
               "background",
               "tie-second",
               "middle",
               "delete"
             ]
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
              %{id: "locked", label: "Locked", enabled: false, disabled_reason: "Requires access"},
              %{id: "disabled", label: "Disabled", disabled: true, disabled_reason: "Unavailable"}
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

      assert Floki.find(doc, "button#page-actions-action-bG9ja2Vk-menu[disabled]") != []

      assert Floki.text(Floki.find(doc, "#page-actions-action-bG9ja2Vk-menu")) =~
               "Requires access"

      assert Floki.find(doc, "button#page-actions-action-ZGlzYWJsZWQ-menu[disabled]") != []
      assert Floki.text(Floki.find(doc, "#page-actions-action-ZGlzYWJsZWQ-menu")) =~ "Unavailable"
      assert Floki.attribute(notice, "data-server-dismissed") == ["false"]
      assert Floki.attribute(notice, "aria-label") == ["Update. Ready"]
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
