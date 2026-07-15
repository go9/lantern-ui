defmodule LanternUI.Components.Tooltip do
  @moduledoc """
  Tooltip - mirrors Fluxon's `tooltip/1` API with a small LiveView hook for
  hover/focus timing and viewport-aware placement.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true, doc: "Stable DOM id for the tooltip hook.")
  attr(:value, :string, default: nil, doc: "Plain-text tip when no :content slot is given.")

  attr(:placement, :string,
    default: "top",
    values: ~w(top bottom left right),
    doc: "Preferred side of the trigger; may flip for viewport fit."
  )

  attr(:delay, :integer, default: 200, doc: "Milliseconds before the tip appears on hover/focus.")
  attr(:arrow, :boolean, default: true, doc: "Show the small pointer arrow toward the trigger.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Trigger element that shows the tip.")
  slot(:content, doc: "Rich tip body; overrides `value` when present.")

  def tooltip(assigns) do
    ~H"""
    <span
      id={@id}
      class={Class.merge(["lui-tooltip-wrap", @class])}
      phx-hook="LanternTooltip"
      data-placement={@placement}
      data-delay={@delay}
      {@rest}
    >
      <span data-part="trigger" class="lui-tooltip-trigger" tabindex="0">
        {render_slot(@inner_block)}
      </span>
      <span data-part="panel" class="lui-tooltip" role="tooltip" hidden>
        <%= if @content != [] do %>
          {render_slot(@content)}
        <% else %>
          {@value}
        <% end %>
        <span :if={@arrow} class="lui-tooltip-arrow" data-part="arrow"></span>
      </span>
    </span>
    """
  end
end
