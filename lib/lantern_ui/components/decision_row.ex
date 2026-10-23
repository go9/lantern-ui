defmodule LanternUI.Components.DecisionRow do
  @moduledoc """
  One open decision: the question, what it decides, and an inline answer.

      <.decision_row id="d-12" question="Ship the migration first?"
        decides="Whether release waits on #3901"
        options={[%{value: "yes", label: "Yes"}, %{value: "no", label: "No"}]}
        on_answer="answer_decision" />

      <.decision_row id="d-12" question="…" variant="pointer"
        href="/epics/7/cockpit" link_label="Answer in the cockpit" />

  The `form` variant is a `phx-submit` form sending `decision_id`, `option` and `note`.
  The `pointer` variant is a link only: no form, no button. `answered` shows
  the recorded answer instead of either.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button

  attr(:id, :string, required: true)
  attr(:question, :string, required: true)
  attr(:decides, :string, default: nil, doc: "What the answer decides.")
  attr(:options, :list, default: [], doc: "`%{value: string, label: string}` choices.")
  attr(:variant, :string, default: "form", values: ~w(form pointer))
  attr(:answered, :string, default: nil, doc: "Recorded answer; replaces the form/link.")
  attr(:on_answer, :string, default: "answer_decision", doc: "phx-submit event (form variant).")
  attr(:target, :any, default: nil, doc: "phx-target for the form.")
  attr(:href, :string, default: nil)
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:link_label, :string, default: "Answer")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def decision_row(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-decision-row", @class])}
      data-variant={@variant}
      data-answered={@answered && "true"}
      {@rest}
    >
      <p class="lui-decision-question">{@question}</p>
      <p :if={@decides} class="lui-decision-decides">Decides: {@decides}</p>
      <p :if={@answered} class="lui-decision-answer">Answered: {@answered}</p>
      <.link
        :if={!@answered && @variant == "pointer"}
        class="lui-decision-link"
        href={@href}
        navigate={@navigate}
        patch={@patch}
      >
        {@link_label}
      </.link>
      <form
        :if={!@answered && @variant == "form"}
        id={"#{@id}-form"}
        class="lui-decision-form"
        phx-submit={@on_answer}
        phx-target={@target}
      >
        <input type="hidden" name="decision_id" value={@id} />
        <fieldset :if={@options != []} class="lui-decision-options">
          <legend class="lui-sr-only">{@question}</legend>
          <label :for={opt <- @options} class="lui-decision-option">
            <input type="radio" name="option" value={opt.value} />
            <span>{opt.label}</span>
          </label>
        </fieldset>
        <input
          type="text"
          name="note"
          class="lui-input lui-decision-note"
          placeholder="Note (optional)"
          aria-label={"Note for: #{@question}"}
          autocomplete="off"
        />
        <Button.button type="submit" size="sm" color="primary">Answer</Button.button>
      </form>
    </div>
    """
  end
end
