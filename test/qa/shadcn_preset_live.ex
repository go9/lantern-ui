defmodule LanternUI.QA.ShadcnPresetLive do
  @moduledoc false
  # Projects-index fixture for the shadcn "app" preset. `?preset=app|shadcn|default`
  # picks the scope, `?theme=dark` adds `.dark`. The attributes live on a wrapper
  # div, as a subtree scope; `test/qa/shadcn_preset.mjs` measures it.
  use Phoenix.LiveView
  use LanternUI

  @rows [
    %{id: "acme", name: "Acme storefront", state: "Synced", tickets: 4},
    %{id: "beacon", name: "Beacon API", state: "Stale", tickets: 12},
    %{id: "comet", name: "Comet docs", state: "Off", tickets: 2}
  ]

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    {:noreply,
     assign(socket,
       rows: @rows,
       preset: params["preset"] || "app",
       dark?: params["theme"] == "dark",
       meta: %{params: params, flop: %{order_by: [:name], order_directions: [:asc]}}
     )}
  end

  def render(assigns) do
    ~H"""
    <div
      id="preset-scope"
      class={@dark? && "dark"}
      data-lantern-theme={@preset in ~w(app shadcn) && "shadcn"}
      data-lantern-preset={@preset == "app" && "app"}
      style="background: var(--lantern-surface); color: var(--lantern-fg); font-family: var(--lantern-font);"
    >
      <.app_shell id="preset-shell" compact nav_label="Main">
        <:brand>Flicker</:brand>
        <:header>
          <.breadcrumb aria_label="Breadcrumb">
            <:item current>Projects</:item>
          </.breadcrumb>
        </:header>
        <:sidebar>
          <.nav_item
            id="nav-projects"
            label="Projects"
            icon="folder"
            navigate="/shadcn_preset"
            active
          />
          <.nav_item id="nav-factory" label="Factory" icon="cog-6-tooth" navigate="/shadcn_preset" />
        </:sidebar>
        <.page_shell id="projects-page" layout="bare" title="Projects">
          <.data_table
            id="projects"
            rows={@rows}
            meta={@meta}
            path="/shadcn_preset"
            search_field={:name}
            search_placeholder="Search projects"
            show_checkboxes={false}
            column_settings={false}
            pagination={false}
            active_view="table"
            row_navigate={fn row -> "/shadcn_preset?p=#{row.id}" end}
          >
            <:col :let={row} field={:name} label="Project">{row.name}</:col>
            <:col :let={row} label="Index"><span data-index-state>{row.state}</span></:col>
            <:col :let={row} label="Tickets">{row.tickets}</:col>
            <:row_action :let={row}>
              <.button size="xs" variant="outline" label={"Open #{row.name}"}>Open</.button>
            </:row_action>
          </.data_table>
        </.page_shell>
      </.app_shell>
    </div>
    """
  end
end
