defmodule LanternUI.Components.Tooltip do
  @moduledoc """
  Tooltip - mirrors Fluxon's `tooltip/1` API with a small LiveView hook for
  hover/focus timing and viewport-aware placement.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:placement, :string, default: "top", values: ~w(top bottom left right))
  attr(:delay, :integer, default: 200)
  attr(:arrow, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:content)

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
