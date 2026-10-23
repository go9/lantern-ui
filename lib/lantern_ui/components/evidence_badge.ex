defmodule LanternUI.Components.EvidenceBadge do
  @moduledoc """
  Who vouches for a statement: CI, the run's own report, or only the agent.

      <.evidence_badge kind="ci" />
      <.evidence_badge kind="claim" />

  Unknown kinds render the weakest label, "Agent claim, not checked".
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Badge

  @kinds %{
    "ci" => {"Checked by CI", "success"},
    "run" => {"Reported by the run", "info"},
    "claim" => {"Agent claim, not checked", "warning"}
  }

  attr(:kind, :string, default: "claim", values: ~w(ci run claim))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def evidence_badge(assigns) do
    {label, color} = Map.get(@kinds, assigns.kind, @kinds["claim"])
    assigns = assign(assigns, label: label, color: color)

    ~H"""
    <Badge.badge size="sm" color={@color} class={Class.merge(["lui-evidence-badge", @class])} {@rest}>
      {@label}
    </Badge.badge>
    """
  end
end
