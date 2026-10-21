defmodule LanternUI.DiffViewerTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LanternUI, only: [:diff_viewer]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @old "a\nb\nc\nd\ne\nf\ng\nh\ni\nj"
  @new "a\nb\nc\nd\nE\nf\ng\nh\ni\nj"

  defp render(old, new, extra \\ []) do
    assigns = %{__changed__: nil, old: old, new: new, extra: extra}

    ~H"""
    <.diff_viewer id="d" old={@old} new={@new} class="extra" {@extra} />
    """
    |> rendered_to_string()
  end

  test "unified rows carry kind, line numbers, sign and screen-reader words" do
    html = render(@old, @new, old_label: "Server", new_label: "Draft")
    doc = Floki.parse_fragment!(html)
    [root] = Floki.find(doc, "#d.lui-diff.extra")
    assert Floki.attribute(root, "role") == ["region"]
    assert Floki.attribute(root, "tabindex") == ["0"]

    assert Floki.attribute(root, "aria-label") ==
             ["Changes from Server to Draft: 1 line added, 1 line removed"]

    assert Floki.attribute(Floki.find(root, "tr.lui-diff-row"), "data-kind") ==
             ~w(eq eq eq eq del add eq eq eq)

    [del] = Floki.find(root, "tr[data-kind=del]")
    assert Floki.text(Floki.find(del, ".lui-diff-text")) == "e"
    assert Floki.text(Floki.find(del, ".lui-diff-sign .lui-sr-only")) == "Removed"

    assert Floki.attribute(Floki.find(del, ".lui-diff-sign [aria-hidden]"), "aria-hidden") == [
             "true"
           ]

    assert Floki.text(Floki.find(del, ".lui-diff-no")) == "5"
    [add] = Floki.find(root, "tr[data-kind=add]")
    assert Floki.text(Floki.find(add, ".lui-diff-sign .lui-sr-only")) == "Added"
    assert Floki.find(root, "caption.lui-sr-only") != []
    assert Floki.find(root, "th[scope=col]") != []
    assert LanternUI.ARIAConformance.audit(html) == []
  end

  test "long unchanged runs collapse around changes, not at the ends of the file" do
    doc = Floki.parse_fragment!(render(@old, @new, context: 1))
    assert Floki.text(Floki.find(doc, ".lui-diff-gap")) =~ "3 unchanged lines"
    assert Floki.text(Floki.find(doc, ".lui-diff-gap")) =~ "4 unchanged lines"
    assert Floki.find(doc, ".lui-diff-gap") |> length() == 2
    texts = Floki.find(doc, ".lui-diff-text") |> Enum.map(&Floki.text/1)
    assert texts == ~w(d e E f)
  end

  test "equal texts say so and render no table" do
    doc = Floki.parse_fragment!(render("x\ny", "x\ny"))
    assert Floki.text(Floki.find(doc, ".lui-diff-empty")) == "No differences"
    assert Floki.find(doc, "table") == []
  end

  test "split mode pairs removed and added lines and leaves the missing side empty" do
    html = render("a\nb\nc", "a\nB\nB2\nc", mode: :split)
    doc = Floki.parse_fragment!(html)
    assert Floki.attribute(Floki.find(doc, ".lui-diff"), "data-mode") == ["split"]
    rows = Floki.find(doc, "tr.lui-diff-row")
    assert length(rows) == 4
    [_, r2, r3, _] = rows

    assert r2 |> Floki.find(".lui-diff-text") |> Enum.map(&String.trim(Floki.text(&1))) == [
             "−Removed: b",
             "+Added: B"
           ]

    assert r3 |> Floki.find(".lui-diff-text") |> Enum.map(&Floki.attribute(&1, "data-kind")) == [
             [],
             ["add"]
           ]

    assert LanternUI.ARIAConformance.audit(html) == []
  end

  test "text is escaped and whitespace-preserving data stays text" do
    doc = Floki.parse_fragment!(render("<b>x</b>", "<script>y</script>"))
    assert Floki.find(doc, "script, b") == []
    assert Floki.text(doc) =~ "<script>y</script>"
  end

  test "empty old text is all additions" do
    doc = Floki.parse_fragment!(render("", "one\ntwo"))
    assert Floki.attribute(Floki.find(doc, "tr.lui-diff-row"), "data-kind") == ~w(add add)
  end
end
