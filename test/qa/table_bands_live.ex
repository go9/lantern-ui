defmodule LanternUI.QA.TableBandsLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  @rows [
    %{id: "acme", name: "Acme", tickets: 4, state: "queued"},
    %{id: "beacon", name: "Beacon", tickets: 12, state: "stale"},
    %{id: "comet", name: "Comet", tickets: 2, state: "off"}
  ]
  def mount(_params, _session, socket), do: {:ok, assign(socket, pinned: ["acme"])}

  def handle_params(params, _, socket) do
    field = if params["order_by"] == ["tickets"], do: :tickets, else: :name
    dir = if params["order_directions"] == ["desc"], do: :desc, else: :asc
    rows = Enum.sort_by(@rows, &Map.fetch!(&1, field), dir)

    groups = [
      {"Pinned", Enum.filter(rows, &(&1.id in socket.assigns.pinned))},
      {"All projects", Enum.reject(rows, &(&1.id in socket.assigns.pinned))}
    ]

    {:noreply,
     assign(socket,
       params: params,
       rows: rows,
       groups: groups,
       view: params["view"] || "table",
       meta: %{params: params, flop: %{order_by: [field], order_directions: [dir]}}
     )}
  end

  def handle_event("pin", %{"id" => id}, socket) do
    pins =
      if id in socket.assigns.pinned,
        do: List.delete(socket.assigns.pinned, id),
        else: [id | socket.assigns.pinned]

    socket = assign(socket, pinned: pins)
    handle_params(socket.assigns.params, nil, socket)
  end

  def render(assigns) do
    ~H"""
    <div style="background: var(--lantern-surface); min-height: 100vh;">
      <main style="padding: 2rem; max-width: 60rem;">
        <h1>Projects</h1>
        <.data_table
          id="projects"
          group={@groups}
          meta={@meta}
          path="/table_bands"
          active_view={@view}
          column_settings={false}
          show_checkboxes={false}
          pagination={false}
        >
          <:col :let={row} field={:name} label="Project" sortable>{row.name}</:col>
          <:col :let={row} field={:tickets} label="Tickets" sortable>{row.tickets}</:col>
          <:col :let={row} label="Index">
            <span style="display: inline-flex; align-items: center; gap: var(--lantern-space-xs);"><.sync_glyph state={
              row.state
            } /> {row.state}</span>
          </:col>
          <:card :let={row}>
            <strong>{row.name}</strong>
            <p style="display: flex; align-items: center; gap: var(--lantern-space-xs);">
              <.sync_glyph state={row.state} /> {row.state}
            </p>
            <span>{row.tickets} open</span>
          </:card>
          <:row_action :let={row}>
            <.button
              id={"pin-#{row.id}"}
              size="icon-sm"
              variant="ghost"
              pressed={row.id in @pinned}
              reveal
              label={"Pin #{row.name}"}
              phx-click="pin"
              phx-value-id={row.id}
            >
              <.icon name="bookmark" />
            </.button>
          </:row_action>
        </.data_table>
      </main>
    </div>
    """
  end
end
