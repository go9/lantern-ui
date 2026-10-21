defmodule LanternUI.HostBadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  use LanternUI, only: [:host_badge]

  test "public import composes the small neutral badge with readable host identity" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.host_badge host="Flicker" />
      """)

    doc = Floki.parse_fragment!(html)

    assert [_] = Floki.find(doc, "span.lui-badge.lui-host-badge")
    assert Floki.text(doc) |> String.trim() == "Flicker"
    assert Floki.attribute(doc, "data-size") == ["sm"]
    assert Floki.attribute(doc, "data-color") == ["neutral"]
    assert Floki.attribute(doc, "data-coming-soon") == ["false"]
    assert Floki.attribute(doc, "aria-disabled") == []
    assert Floki.find(doc, "[role], [tabindex], a, button, input, [phx-hook]") == []
  end

  test "unavailable names are visible, ARIA disabled, and never activators" do
    for host <- ["Fly", "Neon", "Private cell"] do
      doc =
        render_component(&LanternUI.Components.HostBadge.host_badge/1,
          host: host,
          coming_soon: true
        )
        |> Floki.parse_fragment!()

      assert Floki.text(doc) |> String.replace(~r/\s+/, " ") |> String.trim() ==
               "#{host} · Coming soon"

      assert Floki.attribute(doc, ".lui-host-badge", "aria-disabled") == ["true"]
      assert Floki.attribute(doc, ".lui-host-badge", "data-coming-soon") == ["true"]

      assert Floki.find(doc, "a, button, input, [href], [tabindex], [phx-click], [aria-live]") ==
               []
    end
  end

  test "merges classes and passes through caller annotations while escaping names" do
    doc =
      render_component(&LanternUI.Components.HostBadge.host_badge/1,
        host: "<script>host</script>",
        class: ["custom", nil],
        id: "resource-host",
        "data-resource": "app",
        "aria-describedby": "host-help"
      )
      |> Floki.parse_fragment!()

    assert [_] = Floki.find(doc, "#resource-host.lui-badge.lui-host-badge.custom")
    assert Floki.attribute(doc, "data-resource") == ["app"]
    assert Floki.attribute(doc, "aria-describedby") == ["host-help"]
    assert Floki.text(doc) |> String.trim() == "<script>host</script>"
    assert Floki.find(doc, "script") == []
  end
end
