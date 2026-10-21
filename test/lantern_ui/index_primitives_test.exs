defmodule LanternUI.IndexPrimitivesTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias LanternUI.Components.{Button, Icon, StateGlyph}

  defp buttons(assigns) do
    ~H"""
    <Button.button id="pin" size="icon-sm" label="Pin Acme" pressed={@pressed} reveal>
      <Icon.icon name="bookmark" />
    </Button.button>
    <Button.button id="plain">Save</Button.button>
    """
  end

  test "toggle state includes false, ordinary buttons omit aria-pressed" do
    for pressed <- [true, false] do
      doc =
        buttons(%{__changed__: nil, pressed: pressed})
        |> rendered_to_string()
        |> Floki.parse_document!()

      assert Floki.attribute(doc, "#pin", "aria-pressed") == [to_string(pressed)]
      assert Floki.find(doc, "#pin.lui-reveal svg path") != []
      assert Floki.attribute(doc, "#plain", "aria-pressed") == []
      assert Floki.attribute(doc, "#pin", "tabindex") == []
    end
  end

  test "index states have distinct paths and retain accessible labeling" do
    paths =
      for state <- ~w(queued paused stale blocked off) do
        doc =
          Phoenix.LiveViewTest.render_component(&StateGlyph.sync_glyph/1,
            state: state,
            label: state
          )
          |> Floki.parse_document!()

        assert Floki.attribute(doc, "svg", "data-value") == [state]
        assert Floki.attribute(doc, "svg", "aria-label") == [state]
        assert Floki.attribute(doc, "svg", "aria-hidden") == []
        Floki.find(doc, "svg > *") |> Floki.raw_html()
      end

    assert length(Enum.uniq(paths)) == 5
  end
end
