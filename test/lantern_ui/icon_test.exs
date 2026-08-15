defmodule LanternUI.IconTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp render_icon(name) do
    assigns = %{name: name}

    ~H"""
    <LanternUI.Components.Icon.icon name={@name} />
    """
    |> rendered_to_string()
  end

  test "a known name renders its path data" do
    html = render_icon("chevron-down")

    assert html =~ "<path"
    assert html =~ "lui-icon"
  end

  test "an unknown name renders the svg with no path instead of raising" do
    html = capture_log(fn -> send(self(), {:html, render_icon("not-a-real-icon")}) end)
    assert is_binary(html)

    receive do
      {:html, html} ->
        # The svg survives — the layout keeps its box.
        assert html =~ "lui-icon"
        # Probe proving the refute below is not vacuous: a KNOWN name on the
        # same code path does emit a <path>, so its absence here is meaningful.
        assert render_icon("chevron-down") =~ "<path"
        refute html =~ "<path"
    end
  end

  test "an unknown name warns with the offending name" do
    log = capture_log(fn -> render_icon("not-a-real-icon") end)

    assert log =~ "unknown icon name"
    assert log =~ "not-a-real-icon"
  end

  test "a known name does not warn" do
    log = capture_log(fn -> render_icon("chevron-down") end)

    refute log =~ "unknown icon name"
  end
end
