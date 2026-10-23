defmodule LanternUI.EpicPiecesTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  use LanternUI,
    only: [
      :status_trail,
      :step_glyph,
      :evidence_badge,
      :decision_row,
      :passage,
      :agent_rail,
      :message,
      :data_table
    ]

  alias LanternUI.ARIAConformance

  defp html(rendered), do: rendered_to_string(rendered)

  test "status_trail marks the current status with step and modifier" do
    assigns = %{__changed__: nil}

    out = html(~H|<.status_trail status="in_progress" step="Test" modifier="waiting" />|)
    assert out =~ ~s(aria-current="step")
    assert out =~ "Selected for dev"
    assert out =~ "In development"
    assert out =~ "Test"
    assert out =~ "waiting"
    assert out =~ ~s(data-state="passed")
    assert out =~ ~s(data-state="upcoming")
  end

  test "step_glyph always shows the label and speaks the state" do
    assigns = %{__changed__: nil}
    out = html(~H|<.step_glyph step="review" state="needs_you" />|)
    assert out =~ "Review"
    assert out =~ "needs you"
    assert out =~ ~s(data-state="needs_you")
    assert html(~H|<.step_glyph step="plan" state="bogus" />|) =~ ~s(data-state="not_started")
  end

  test "evidence_badge variants" do
    assigns = %{__changed__: nil}
    assert html(~H|<.evidence_badge kind="ci" />|) =~ "Checked by CI"
    assert html(~H|<.evidence_badge kind="run" />|) =~ "Reported by the run"
    assert html(~H|<.evidence_badge kind="claim" />|) =~ "Agent claim, not checked"
  end

  test "decision_row form posts options; pointer is a link without a button" do
    assigns = %{__changed__: nil}

    form =
      html(~H"""
      <.decision_row
        id="d1"
        question="Ship?"
        decides="Release timing"
        options={[%{value: "yes", label: "Yes"}]}
        on_answer="answer"
      />
      """)

    assert form =~ ~s(phx-submit="answer")
    assert form =~ ~s(name="option")
    assert form =~ "Decides: Release timing"

    pointer =
      html(
        ~H|<.decision_row id="d1" question="Ship?" variant="pointer" href="/x" link_label="Go" />|
      )

    assert pointer =~ ~s(href="/x")
    refute pointer =~ "<button"
    refute pointer =~ "<form"

    answered = html(~H|<.decision_row id="d1" question="Ship?" answered="Yes" />|)
    assert answered =~ "Answered: Yes"
    refute answered =~ "<form"
  end

  test "passage shows counts and comment event" do
    assigns = %{__changed__: nil}
    out = html(~H|<.passage id="p1" open={2} resolved={1} on_comment="comment">Text</.passage>|)
    assert out =~ ~s(phx-click="comment")
    assert out =~ ~s(phx-value-passage="p1")
    assert out =~ "2 open, 1 resolved"
    refute html(~H|<.passage id="p1">Text</.passage>|) =~ "<button"
  end

  test "message renders the quote slot" do
    assigns = %{__changed__: nil}

    out =
      html(~H"""
      <.message><:quote>old text</:quote>reply</.message>
      """)

    assert out =~ ~s(<blockquote class="lui-message-quote">)
    assert out =~ "old text"
    refute html(~H|<.message>reply</.message>|) =~ "blockquote"
  end

  describe "agent_rail" do
    defp agents do
      [
        %{id: "e1", name: "Idle epic", initials: "IE", status: :idle},
        %{id: "e2", name: "Working epic", initials: "WE", status: :working, count: 0},
        %{id: "e3", name: "Waiting epic", initials: "WA", status: :waiting, count: 3},
        %{
          id: "w1",
          name: "Worker one",
          initials: "W1",
          status: :working,
          kind: :worker,
          parent_id: "e2"
        }
      ]
    end

    test "sorts waiting, working, idle; nests workers; counts total" do
      assigns = %{__changed__: nil, agents: agents()}
      out = html(~H|<.agent_rail id="rail" agents={@agents} />|)

      assert out =~ ~r/Waiting epic.*Working epic.*Worker one.*Idle epic/s
      assert out =~ ~s(data-size="sm")
      assert out =~ ~s(<span class="lui-agent-rail-total">4</span>)
      assert out =~ "Waiting epic, waiting on you, 3 waiting"
      assert out =~ ~s(phx-click="ask")
      assert ARIAConformance.audit(out) == []
    end

    test "max collapses idle epics into +N" do
      assigns = %{__changed__: nil, agents: agents()}
      out = html(~H|<.agent_rail id="rail" agents={@agents} max={2} on_more="more" />|)
      refute out =~ "Idle epic"
      assert out =~ "+1"
      assert out =~ ~s(phx-click="more")
    end

    test "closed shows only the toggle; top_bar variant has no list" do
      assigns = %{__changed__: nil, agents: agents()}
      closed = html(~H|<.agent_rail id="rail" agents={@agents} open={false} />|)
      refute closed =~ "lui-agent-bubble"
      assert closed =~ ~s(aria-expanded="false")

      bar = html(~H|<.agent_rail id="rail" agents={@agents} variant="top_bar" />|)
      refute bar =~ "lui-agent-bubble"
      assert bar =~ ~s(data-variant="top_bar")

      given = html(~H|<.agent_rail id="rail" agents={@agents} total={7} />|)
      assert given =~ ~s(<span class="lui-agent-rail-total">7</span>)
    end
  end

  test "data_table expandable rows toggle with aria-expanded and show detail" do
    meta = %{
      flop: %{page_size: 25, order_by: [:name], order_directions: [:asc]},
      params: %{},
      current_page: 1,
      total_pages: 1,
      page_size: 25,
      total_count: 2
    }

    assigns = %{__changed__: nil, meta: meta, rows: [%{id: 1, name: "A"}, %{id: 2, name: "B"}]}

    out =
      html(~H"""
      <.data_table
        id="t"
        rows={@rows}
        meta={@meta}
        path="/x"
        pagination={false}
        row_toggle={fn _ -> %Phoenix.LiveView.JS{} end}
        row_expanded={&(&1.id == 2)}
      >
        <:col :let={r} label="Name">{r.name}</:col>
        <:row_detail :let={r}>detail for {r.name}</:row_detail>
      </.data_table>
      """)

    assert out =~ ~s(aria-expanded="true")
    assert out =~ ~s(aria-expanded="false")
    assert out =~ "detail for B"
    refute out =~ "detail for A"
    assert out =~ ~s(id="t-row-2-detail")
  end
end
