defmodule LanternUI.Components.ProvenanceBadge do
  @moduledoc """
  Provenance labels for inherited configuration and temporal retrieval evidence.
  Composes the existing badge; it does not resolve inheritance or edit values.

      <.provenance_badge state="inherited" source="Production" />
      <.provenance_badge state="historical" />
      <.provenance_badge state="override" source="Production">
        <:revert>
          <.button size="xs" variant="ghost" phx-click="revert"
            label="Revert API branch to Production">Revert</.button>
        </:revert>
      </.provenance_badge>

  Use `own`, `inherited`, or `override` for environment entities and profile
  assignments; `current`, `historical`, or `unknown` for evidence. Missing or
  unrecognized runtime states render Unknown, never Current. Historical is
  explicitly labelled superseded and stays visible.

  Plain text carries the meaning without color, tooltips, live-region roles,
  or tab stops. The optional revert slot renders only for overrides. Supply a
  native button with a contextual accessible name and a stable id in moving
  rows. The consuming app owns permission checks, confirmation, events and
  focus after removal. There is no hook, motion, or client-owned ARIA state.
  See `docs/provenance-badge.md` and the `/provenance` QA demo.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Badge

  @states ~w(own inherited override current historical unknown)

  attr(:state, :string,
    default: "unknown",
    values: @states,
    doc: "Configuration origin or temporal evidence state; defaults safely to unknown."
  )

  attr(:source, :string,
    default: nil,
    doc: "Parent name for inherited/override labels; ignored for other states."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root.")
  attr(:rest, :global, doc: "HTML and phx attributes on the root.")

  slot(:revert,
    doc: "Optional caller-owned revert button, rendered only when state is override."
  )

  def provenance_badge(assigns) do
    state = if assigns.state in @states, do: assigns.state, else: "unknown"

    label =
      case state do
        "own" ->
          "Own"

        "inherited" ->
          if present?(assigns.source), do: "Inherited from #{assigns.source}", else: "Inherited"

        "override" ->
          if present?(assigns.source), do: "Override of #{assigns.source}", else: "Override"

        "current" ->
          "Current"

        "historical" ->
          "Historical (superseded)"

        "unknown" ->
          "Unknown"
      end

    assigns = assign(assigns, state: state, label: label)

    ~H"""
    <span class={Class.merge(["lui-provenance-badge", @class])} data-state={@state} {@rest}>
      <Badge.badge size="sm">{@label}</Badge.badge>
      {if @state == "override", do: render_slot(@revert)}
    </span>
    """
  end

  defp present?(source), do: is_binary(source) and String.trim(source) != ""
end
