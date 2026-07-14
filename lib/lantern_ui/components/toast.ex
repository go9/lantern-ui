defmodule LanternUI.Components.Toast do
  @moduledoc """
  Toast notification stack. Render once in a LiveView layout and push messages
  with `LanternUI.send_toast/4`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, default: "lantern-toasts")
  attr(:placement, :string, default: "top-right", values: ~w(top-right bottom-right top-center))
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
