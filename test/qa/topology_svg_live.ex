defmodule LanternUI.QA.TopologySvgLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, picked: nil)}

  def handle_event("pick_node", %{"node" => id}, socket),
    do: {:noreply, assign(socket, :picked, id)}

  def render(assigns) do
    ~H"""
    <.page_shell id="topology-demo" title="Topology">
      <.topology_svg
        id="topology"
        label="foodfeed resources on staging"
        on_select="pick_node"
        selected={@picked}
        nodes={[
          %{id: "web", label: "web", detail: "Flicker", state: :degraded},
          %{id: "worker", label: "worker", detail: "Flicker"},
          %{id: "primary", label: "primary", detail: "Neon", column: 1},
          %{id: "docs", label: "docs", detail: "not on staging", column: 1, state: :absent}
        ]}
        edges={[
          %{from: "web", to: "primary", label: "DATABASE_URL"},
          %{from: "worker", to: "docs", label: "DOCS_BUCKET"}
        ]}
      />
      <p id="picked">{@picked || "Select a node."}</p>
    </.page_shell>
    """
  end
end
