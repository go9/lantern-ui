defmodule LanternUI.Components.StatusTrail do
  @moduledoc """
  Lifecycle trail: Backlog > Selected for dev > In development > Done, with the
  current step and an optional waiting/paused word after the current status.

      <.status_trail status="in_progress" step="Test" modifier="waiting" />

  Static server render. Passed statuses are muted; the current one carries
  `aria-current="step"`. Unknown statuses fall back to backlog.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @statuses [
    {"backlog", "Backlog"},
    {"selected_for_dev", "Selected for dev"},
    {"in_progress", "In development"},
    {"done", "Done"}
  ]

  attr(:status, :string, required: true, values: Enum.map(@statuses, &elem(&1, 0)))
  attr(:step, :string, default: nil, doc: "Current step label, shown after the current status.")
  attr(:modifier, :string, default: nil, values: [nil, "waiting", "paused"])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def status_trail(assigns) do
    keys = Enum.map(@statuses, &elem(&1, 0))
    current = Enum.find_index(keys, &(&1 == assigns.status)) || 0
    assigns = assign(assigns, statuses: Enum.with_index(@statuses), current: current)

    ~H"""
    <ol class={Class.merge(["lui-status-trail", @class])} {@rest}>
      <li
        :for={{{key, label}, i} <- @statuses}
        class="lui-status-trail-item"
        data-state={
          cond do
            i < @current -> "passed"
            i == @current -> "current"
            true -> "upcoming"
          end
        }
        data-status={key}
        aria-current={i == @current && "step"}
      >
        <span class="lui-status-trail-label">{label}</span>
        <span :if={i == @current && @step} class="lui-status-trail-step">{@step}</span>
        <span :if={i == @current && @modifier} class="lui-status-trail-modifier">{@modifier}</span>
        <span :if={i < length(@statuses) - 1} class="lui-status-trail-sep" aria-hidden="true">&gt;</span>
      </li>
    </ol>
    """
  end
end
