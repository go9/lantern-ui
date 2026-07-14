defmodule LanternUI.Components.Toast do
  @moduledoc """
  Toast notification stack. Render once in a LiveView layout and push messages
  with `LanternUI.send_toast/4`.

  `placement` positions the stack in any corner or edge-center; toasts enter
  from the nearest screen edge (sliding down from the top, up from the bottom).

      <.toast_group placement="bottom-center" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  @placements ~w(top-left top-center top-right bottom-left bottom-center bottom-right)

  attr(:id, :string, default: "lantern-toasts")
  attr(:placement, :string, default: "top-right", values: @placements)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def toast_group(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-toasts", @class])}
      phx-hook="LanternToast"
      data-placement={@placement}
      aria-live="polite"
      {@rest}
    >
    </div>
    """
  end
end
