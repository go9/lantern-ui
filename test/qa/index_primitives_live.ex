defmodule LanternUI.QA.IndexPrimitivesLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, pinned: true)}

  def handle_event("pin", _, socket),
    do: {:noreply, assign(socket, :pinned, !socket.assigns.pinned)}

  def render(assigns) do
    ~H"""
    <main style="padding: 2rem; max-width: 60rem;">
      <h1>Index primitives</h1>
      <div style="display: flex; gap: 1rem; margin-block: 1rem;">
        <span :for={state <- ~w(queued paused stale blocked off)}>
          <.sync_glyph state={state} /> {state}
        </span>
      </div>
      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <span>Acme</span>
        <.button
          id="pin-acme"
          size="icon-sm"
          variant="ghost"
          pressed={@pinned}
          reveal
          label={if @pinned, do: "Unpin Acme", else: "Pin Acme"}
          phx-click="pin"
        >
          <.icon name="bookmark" />
        </.button>
      </div>
    </main>
    """
  end
end
