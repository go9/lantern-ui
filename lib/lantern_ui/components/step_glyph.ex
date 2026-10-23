defmodule LanternUI.Components.StepGlyph do
  @moduledoc """
  One labelled workflow step (Plan, Implement, Test, Review, Release) with a
  state glyph. The label is always visible; the state is also spoken.

      <.step_glyph step="review" state="needs_you" />

  States: not_started, running, done, failed, needs_you, skipped. Unknown
  values fall back to not_started. Lay several out in a flex row yourself.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @steps ~w(plan implement test review release)
  @states ~w(not_started running done failed needs_you skipped)
  @words %{
    "not_started" => "not started",
    "running" => "running",
    "done" => "done",
    "failed" => "failed",
    "needs_you" => "needs you",
    "skipped" => "skipped"
  }

  attr(:step, :string, required: true, values: @steps)
  attr(:state, :string, default: "not_started", values: @states)
  attr(:label, :string, default: nil, doc: "Override of the visible label.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def step_glyph(assigns) do
    state = if assigns.state in @states, do: assigns.state, else: "not_started"

    assigns =
      assign(assigns,
        state: state,
        text: assigns.label || String.capitalize(assigns.step),
        word: Map.fetch!(@words, state)
      )

    ~H"""
    <span
      class={Class.merge(["lui-step-glyph", @class])}
      data-step={@step}
      data-state={@state}
      {@rest}
    >
      <svg class="lui-step-glyph-icon" viewBox="0 0 14 14" fill="none" aria-hidden="true">
        <circle cx="7" cy="7" r="5.5" stroke="currentColor" stroke-width="1.5" />
        <%= case @state do %>
          <% "done" -> %>
            <path d="M4.5 7.2l1.8 1.8 3.2-3.6" stroke="currentColor" stroke-width="1.5" />
          <% "failed" -> %>
            <path d="M5 5l4 4M9 5l-4 4" stroke="currentColor" stroke-width="1.5" />
          <% "running" -> %>
            <path d="M7 1.5a5.5 5.5 0 010 11z" fill="currentColor" />
          <% "needs_you" -> %>
            <circle cx="7" cy="7" r="2" fill="currentColor" />
          <% "skipped" -> %>
            <path d="M4.5 7h5" stroke="currentColor" stroke-width="1.5" />
          <% _ -> %>
        <% end %>
      </svg>
      <span class="lui-step-glyph-label">{@text}</span>
      <span class="lui-sr-only">, {@word}</span>
    </span>
    """
  end
end
