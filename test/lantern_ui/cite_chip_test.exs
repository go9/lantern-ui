defmodule LanternUI.CiteChipTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LanternUI, only: [:cite_chip]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp render(active, number, source) do
    assigns = %{__changed__: nil, active: active, number: number, source: source}

    ~H"""
    <.cite_chip
      id="cite-search"
      class="extra"
      label={"Open citation: " <> @source}
      number={@number}
      active={@active}
      phx-click="preview"
      phx-value-source="search"
      aria-controls="source-preview"
      data-answer="7"
    >
      {@source}
    </.cite_chip>
    <aside id="source-preview" aria-label="Source preview">Source content</aside>
    """
    |> rendered_to_string()
  end

  test "public import renders a non-submit native button with full name and event passthrough" do
    html = render(false, 1, "lib/search.ex:12–18")
    doc = Floki.parse_fragment!(html)
    [button] = Floki.find(doc, "button#cite-search.lui-btn.lui-cite-chip.extra")
    assert Floki.attribute(button, "type") == ["button"]
    assert Floki.attribute(button, "aria-label") == ["Open citation: lib/search.ex:12–18"]
    assert Floki.attribute(button, "aria-pressed") == ["false"]
    assert Floki.attribute(button, "phx-click") == ["preview"]
    assert Floki.attribute(button, "phx-value-source") == ["search"]
    assert Floki.attribute(button, "data-answer") == ["7"]
    assert Floki.attribute(button, "aria-controls") == ["source-preview"]
    assert length(Floki.find(doc, "#source-preview")) == 1
    assert Floki.find(button, ".lui-cite-chip-number[aria-hidden=true]") |> Floki.text() == "1"
    assert Floki.find(button, "[phx-hook], [tabindex], a, button button") == []
    assert LanternUI.ARIAConformance.audit(html) == []
  end

  test "server selection updates pressed state without changing its accessible name" do
    for active <- [false, true] do
      doc = render(active, 2, "#212") |> Floki.parse_fragment!()
      button = Floki.find(doc, "button")
      assert Floki.attribute(button, "aria-pressed") == [to_string(active)]
      assert Floki.attribute(button, "aria-label") == ["Open citation: #212"]
    end
  end

  test "unnumbered attached context supports memory and escapes source text" do
    doc = render(false, nil, "Memory <retention> & policy") |> Floki.parse_fragment!()
    assert Floki.find(doc, ".lui-cite-chip-number, retention") == []
    assert Floki.find(doc, "button") |> Floki.text() =~ "Memory <retention> & policy"
  end

  test "default state has no invented preview relationship or hook" do
    assigns = %{}

    html =
      ~H"""
      <.cite_chip label="Open citation: memory 167">memory</.cite_chip>
      """
      |> rendered_to_string()

    doc = Floki.parse_fragment!(html)
    assert Floki.attribute(doc, "aria-pressed") == ["false"]
    assert Floki.find(doc, "[aria-controls], [phx-hook], [id]") == []
  end
end
