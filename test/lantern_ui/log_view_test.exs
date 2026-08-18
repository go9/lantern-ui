defmodule LanternUI.LogViewTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.LogView

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "log_view/1" do
    test "renders an ordered list with one li per line" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view id="trace" label="Trace">
            <LogView.log_line at="12:04:03">ls -la</LogView.log_line>
            <LogView.log_line at="12:04:04">cat mix.exs</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [_] = Floki.find(doc, "div#trace.lui-log-view")
      assert length(Floki.find(doc, "ol.lui-log-view-lines > li.lui-log-line")) == 2
      assert Floki.find(doc, ".lui-log-view-label") |> Floki.text() =~ "Trace"
    end

    test "the header is omitted entirely when there is nothing to put in it" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line>plain</LogView.log_line>
          </LogView.log_view>
          """
        end)

      assert html |> Floki.parse_fragment!() |> Floki.find(".lui-log-view-header") == []
    end

    test "actions render in the header beside the label" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view label="Trace">
            <:actions><button>Errors only</button></:actions>
            <LogView.log_line>x</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)

      assert Floki.find(doc, ".lui-log-view-header .lui-log-view-actions button") |> Floki.text() ==
               "Errors only"
    end

    test "the scroll box is the root, so a long line never widens the page" do
      # The rule this guards: wide content scrolls inside its own container.
      # If overflow ever moves off the root, one 400-char line pushes the whole
      # document sideways — the failure mode this component exists to prevent.
      rule =
        "priv/static/lantern_ui.css"
        |> File.read!()
        |> String.split("\n\n")
        |> Enum.find(&(&1 =~ ".lui-log-view {"))

      assert rule, "no .lui-log-view rule found"
      assert rule =~ "overflow: auto;"
      assert rule =~ "min-width: 0;"
    end

    test "wrap is opt-in and lands on the root for the lines to read" do
      wrapped =
        render(fn assigns ->
          ~H"""
          <LogView.log_view wrap>
            <LogView.log_line>x</LogView.log_line>
          </LogView.log_view>
          """
        end)

      plain =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line>x</LogView.log_line>
          </LogView.log_view>
          """
        end)

      assert wrapped |> Floki.parse_fragment!() |> Floki.attribute("data-wrap") == ["true"]
      assert plain |> Floki.parse_fragment!() |> Floki.attribute("data-wrap") == []
    end
  end

  describe "log_line/1" do
    test "severity lands on the line AND is announced, never color-only" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line severity={:error}>boom</LogView.log_line>
            <LogView.log_line severity={:warning}>hmm</LogView.log_line>
            <LogView.log_line severity={:neutral}>fine</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      lines = Floki.find(doc, "li.lui-log-line")
      assert Enum.at(lines, 0) |> Floki.attribute("data-severity") == ["error"]
      assert Enum.at(lines, 1) |> Floki.attribute("data-severity") == ["warning"]
      assert Enum.at(lines, 2) |> Floki.attribute("data-severity") == ["neutral"]

      assert Enum.at(lines, 0) |> Floki.find(".lui-sr-only") |> Floki.text() =~ "Error"
      assert Enum.at(lines, 1) |> Floki.find(".lui-sr-only") |> Floki.text() =~ "Warning"

      # Neutral is the absence of a claim; announcing "Neutral" on every
      # ordinary line is noise in a screen reader running a 400-line log.
      assert Enum.at(lines, 2) |> Floki.find(".lui-sr-only") == []
    end

    test "gutter, channel, body and meta each render in their own cell" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line at="12:04:03" channel="bash" meta="412ms">ls -la src</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "time.lui-log-line-at") |> Floki.text() == "12:04:03"
      assert Floki.find(doc, ".lui-log-line-channel") |> Floki.text() == "bash"
      assert Floki.find(doc, ".lui-log-line-body") |> Floki.text() == "ls -la src"
      assert Floki.find(doc, ".lui-log-line-meta") |> Floki.text() == "412ms"
    end

    test "a line missing at/channel keeps the body in the same column" do
      # Explicit grid-column placement, not flow order: otherwise one line
      # without a timestamp slides its body left and the log stops scanning.
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line at="12:04:03" channel="bash">with</LogView.log_line>
            <LogView.log_line>without</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "time.lui-log-line-at") |> length() == 1
      assert Floki.find(doc, ".lui-log-line-channel") |> length() == 1
      assert Floki.find(doc, ".lui-log-line-body") |> length() == 2

      css = File.read!("priv/static/lantern_ui.css")
      assert css =~ ~r/\.lui-log-line-body \{\s*grid-column: 3;/
      assert css =~ ~r/\.lui-log-line-meta \{\s*grid-column: 4;/
    end

    test "a :detail slot turns the line into a native disclosure" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line at="12:04:03" severity={:error}>
              failed
              <:detail>stack trace here</:detail>
            </LogView.log_line>
            <LogView.log_line>no detail</LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert [details] = Floki.find(doc, "details.lui-log-line-details")
      assert Floki.find(details, "summary.lui-log-line-row") |> Floki.text() =~ "failed"
      assert Floki.find(details, ".lui-log-line-detail") |> Floki.text() =~ "stack trace here"

      # A line with no detail must not become a disclosure that opens onto
      # nothing.
      assert length(Floki.find(doc, "div.lui-log-line-row")) == 1
    end

    test "open controls the disclosure's initial state" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line open>
              a
              <:detail>d</:detail>
            </LogView.log_line>
            <LogView.log_line>
              b
              <:detail>d</:detail>
            </LogView.log_line>
          </LogView.log_view>
          """
        end)

      doc = Floki.parse_fragment!(html)
      [first, second] = Floki.find(doc, "details.lui-log-line-details")
      assert Floki.attribute(first, "open") == ["open"]
      assert Floki.attribute(second, "open") == []
    end

    test "selected is marked on the line, not only styled" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line selected>a</LogView.log_line>
            <LogView.log_line>b</LogView.log_line>
          </LogView.log_view>
          """
        end)

      lines = html |> Floki.parse_fragment!() |> Floki.find("li.lui-log-line")
      assert Enum.at(lines, 0) |> Floki.attribute("data-selected") == ["true"]
      assert Enum.at(lines, 1) |> Floki.attribute("data-selected") == []
    end

    test "phx bindings pass through to the line" do
      html =
        render(fn assigns ->
          ~H"""
          <LogView.log_view>
            <LogView.log_line phx-click="select" phx-value-id="7">a</LogView.log_line>
          </LogView.log_view>
          """
        end)

      line = html |> Floki.parse_fragment!() |> Floki.find("li.lui-log-line")
      assert Floki.attribute(line, "phx-click") == ["select"]
      assert Floki.attribute(line, "phx-value-id") == ["7"]
    end
  end
end
