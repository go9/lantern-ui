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

  attr(:icon, :string, default: nil, doc: "Optional leading icon name from the icon set.")
  attr(:title, :string, required: true, doc: "Primary empty-state heading.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Supporting description under the title.")
  slot(:action, doc: "CTA buttons or links below the description.")

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
