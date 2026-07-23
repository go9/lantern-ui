defmodule LanternUI.AlertDialogTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.ARIAConformance
  alias LanternUI.Components.AlertDialog

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp dialog_html do
    render(fn assigns ->
      ~H"""
      <AlertDialog.alert_dialog id="delete-project">
        <:title>Delete this project?</:title>
        <:description>This action cannot be undone.</:description>
        <:cancel><button phx-click="cancel-delete">Keep project</button></:cancel>
        <:action><button phx-click="confirm-delete">Delete project</button></:action>
      </AlertDialog.alert_dialog>
      """
    end)
  end

  test "renders required anatomy in safe, stable order on the shared modal hook" do
    html = dialog_html()
    document = Floki.parse_fragment!(html)

    assert html =~ ~s(phx-hook="LanternModal")
    assert html =~ ~s(data-close-on-esc="true")
    assert html =~ ~s(data-close-on-outside="false")
    assert html =~ ~s(data-initial-focus="[data-part=&#39;alert-dialog-cancel&#39;]")
    refute html =~ ~s(data-part="close")

    assert Floki.find(document, ".lui-alert-dialog-title") |> Floki.text() =~
             "Delete this project?"

    assert Floki.find(document, ".lui-alert-dialog-description") |> Floki.text() =~
             "This action cannot be undone."

    assert Floki.find(document, ".lui-alert-dialog-actions button")
           |> Enum.map(&Floki.text/1) == ["Keep project", "Delete project"]

    assert html =~ ~s(phx-click="cancel-delete")
    assert html =~ ~s(phx-click="confirm-delete")
  end

  test "renders resolvable alertdialog title and description relationships" do
    html = dialog_html()
    document = Floki.parse_fragment!(html)
    [panel] = Floki.find(document, ~s([role="alertdialog"]))

    assert Floki.attribute(panel, "aria-modal") == ["true"]
    assert Floki.attribute(panel, "aria-labelledby") == ["delete-project-title"]
    assert Floki.attribute(panel, "aria-describedby") == ["delete-project-description"]
    assert Floki.find(document, "#delete-project-title") != []
    assert Floki.find(document, "#delete-project-description") != []
    assert ARIAConformance.audit(html) == []
  end

  test "all four semantic slots are declared required" do
    required_slots =
      AlertDialog.__components__()
      |> get_in([:alert_dialog, :slots])
      |> Enum.filter(& &1.required)
      |> Enum.map(& &1.name)
      |> Enum.sort()

    assert required_slots == Enum.sort([:title, :description, :cancel, :action])
  end

  test "CSS uses theme and density tokens and includes a narrow layout" do
    css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))

    assert css =~ ".lui-alert-dialog"
    assert css =~ "color: var(--lantern-fg)"
    assert css =~ "color: var(--lantern-fg-muted)"
    assert css =~ "gap: var(--lantern-gap"
    assert css =~ "@media (max-width: 480px)"
  end
end
