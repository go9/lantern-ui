defmodule LanternUI.AlertTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Alert

  defp render_alert(assigns) do
    assigns = Map.put(assigns, :__changed__, nil)

    ~H"""
    <Alert.alert
      id={@id}
      color={@color}
      title={@title}
      tone_slots={@tone_slots}
      role={@role}
    />
    """
    |> rendered_to_string()
  end

  test "legacy info alert keeps its default role and does not opt in to tone slots" do
    html =
      render_alert(%{
        id: "legacy-info",
        color: "info",
        title: "Saved",
        tone_slots: false,
        role: "alert"
      })

    [alert] = Floki.parse_fragment!(html) |> Floki.find("#legacy-info")
    assert Floki.attribute(alert, "data-color") == ["info"]
    assert Floki.attribute(alert, "data-tone") == ["info"]
    assert Floki.attribute(alert, "data-tone-slots") == []
    assert Floki.attribute(alert, "role") == ["alert"]
  end

  test "semantic tone slots and custom announcement role are explicit opt-ins" do
    html =
      render_alert(%{
        id: "status",
        color: "promo",
        title: "Update",
        tone_slots: true,
        role: "status"
      })

    [alert] = Floki.parse_fragment!(html) |> Floki.find("#status")
    assert Floki.attribute(alert, "data-tone-slots") == ["data-tone-slots"]
    assert Floki.attribute(alert, "role") == ["status"]
  end
end
