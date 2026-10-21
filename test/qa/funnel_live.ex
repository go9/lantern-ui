defmodule LanternUI.QA.FunnelLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI, only: [:funnel_line, :button]

  def mount(_params, _session, socket),
    do: {:ok, assign(socket, bucket: "needs", snoozed: 1)}

  def handle_event("filter", %{"value" => value}, socket),
    do: {:noreply, assign(socket, :bucket, value)}

  def handle_event("empty_snoozed", _, socket),
    do: {:noreply, assign(socket, :snoozed, 0)}

  def render(assigns) do
    ~H"""
    <main style="padding: var(--lantern-space-lg); background: var(--lantern-surface); min-height: 100vh; box-sizing: border-box;">
      <h1>Counted stage filters</h1>
      <.funnel_line id="reports" label="Where reports are" value={@bucket} on_change="filter">
        <:stage value="needs" label="Needs you" count={7} />
        <:stage value="work" label="In work" count={2} />
        <:stage value="shipped" label="Shipped" count={1} />
        <:stage value="told" label="Told" count={0} />
        <:stage value="snoozed" label="Snoozed" count={@snoozed} overflow />
        <:stage value="held" label="Held" count={0} overflow />
      </.funnel_line>
      <p id="filtered" role="status">Showing: {@bucket}</p>
      <.button id="empty-snoozed" phx-click="empty_snoozed">Empty snoozed bucket</.button>
    </main>
    """
  end
end
