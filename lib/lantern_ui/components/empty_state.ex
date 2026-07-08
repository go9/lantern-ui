defmodule LanternUI.Components.EmptyState do
  @moduledoc """
  Quiet empty/zero state for tables, lists, and panels (a lantern-ui extension —
  Fluxon has no equivalent).

      <.empty_state icon="folder-open" title="No objects">
        Drop files here or
        <:action><.button size="sm" phx-click="upload">Upload</.button></:action>
      </.empty_state>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:icon, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)
  slot(:action)

  def empty_state(assigns) do
    ~H"""
    <div class={Class.merge(["lui-empty", @class])} {@rest}>
      <LanternUI.Components.Icon.icon :if={@icon} name={@icon} class="lui-empty-icon" />
      <p class="lui-empty-title">{@title}</p>
      <p :if={@inner_block != []} class="lui-empty-desc">{render_slot(@inner_block)}</p>
      <div :if={@action != []} class="lui-empty-actions">
        <span :for={a <- @action}>{render_slot(a)}</span>
      </div>
    </div>
    """
  end
end
