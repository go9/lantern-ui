defmodule LanternUI.StageStripTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LanternUI, only: [:stage_strip]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @stages [
    %{label: "Triaged", state: :done},
    %{label: "Drafted", state: :active},
    %{label: "Decided", state: :waiting},
    %{label: "In work", state: :pending},
    %{label: "Shipped", state: :skipped},
    %{label: "Told", state: :failed}
  ]

  defp render(stages) do
    assigns = %{__changed__: nil, stages: stages}

    ~H"""
    <.stage_strip stages={@stages} id="journey" class="extra" data-report="19" />
    """
    |> rendered_to_string()
  end

  test "public import renders six ordered pips and one complete accessible summary" do
    html = render(@stages)
    doc = Floki.parse_fragment!(html)
    [root] = Floki.find(doc, "#journey.lui-stage-strip.extra")
    assert Floki.attribute(root, "role") == ["img"]
    assert Floki.attribute(root, "data-report") == ["19"]

    summary =
      "Triaged done, Drafted in progress, Decided waiting on you, In work pending, Shipped skipped, Told failed"

    assert Floki.attribute(root, "aria-label") == ["Progress: " <> summary]
    assert Floki.attribute(root, "title") == [summary]
    pips = Floki.find(root, ".lui-stage-strip-pip[aria-hidden=true]")
    assert Floki.attribute(pips, "data-state") == ~w(done active waiting pending skipped failed)
    assert LanternUI.ARIAConformance.audit(html) == []
    assert Floki.find(root, "[tabindex], button, a, [phx-hook], [aria-valuenow]") == []
  end

  test "stage count and names are caller owned, and unsafe label text is escaped" do
    html = render([%{label: "<Queue> & review", state: :waiting}])
    doc = Floki.parse_fragment!(html)
    assert length(Floki.find(doc, ".lui-stage-strip-pip")) == 1
    assert Floki.attribute(doc, "aria-label") == ["Progress: <Queue> & review waiting on you"]
    assert Floki.find(doc, "queue, script") == []
  end

  test "server rerenders replace state words and pip states together" do
    before = render([%{label: "Told", state: :failed}]) |> Floki.parse_fragment!()
    after_retry = render([%{label: "Told", state: :done}]) |> Floki.parse_fragment!()
    assert Floki.attribute(before, "aria-label") == ["Progress: Told failed"]
    assert Floki.attribute(after_retry, "aria-label") == ["Progress: Told done"]

    assert Floki.attribute(Floki.find(after_retry, ".lui-stage-strip-pip"), "data-state") == [
             "done"
           ]
  end

  test "empty or malformed stages cannot silently claim a workflow state" do
    for stages <- [
          [],
          [%{label: "Told", state: :unknown}],
          [%{label: " ", state: :done}],
          [%{state: :done}]
        ] do
      assert_raise ArgumentError, fn -> render(stages) end
    end
  end
end
