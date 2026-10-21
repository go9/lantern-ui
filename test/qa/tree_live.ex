defmodule LanternUI.QA.TreeLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  @deep_expanded ~w(prod prod-apps prod-dbs staging staging-apps dev)

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"

    {:ok,
     assign(socket,
       theme: theme,
       current_id: "dev-api",
       expanded_ids: @deep_expanded
     )}
  end

  def handle_event("toggle_theme", _params, socket) do
    next = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, :theme, next)}
  end

  def handle_event("tree_select", %{"id" => id}, socket) do
    {:noreply, assign(socket, :current_id, id)}
  end

  def handle_event("tree_toggle", %{"id" => id} = params, socket) do
    expanded = params["expanded"] in [true, "true"]
    ids = socket.assigns.expanded_ids

    next =
      if expanded do
        Enum.uniq([id | ids])
      else
        List.delete(ids, id)
      end

    {:noreply, assign(socket, :expanded_ids, next)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="qa-tree-root"
      class={@theme}
      style="min-height: 100vh; padding: var(--lantern-space-lg); background: var(--lantern-surface); color: var(--lantern-fg); box-sizing: border-box;"
    >
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: var(--lantern-space-lg); gap: var(--lantern-space-md);">
        <div>
          <h1 style="font-size: var(--lantern-text-headline, 1.125rem); font-weight: 650; margin: 0 0 var(--lantern-space-xs) 0;">
            Tree
          </h1>
          <p style="margin: 0; color: var(--lantern-fg-muted); font-size: var(--lantern-text-sm);">
            Current vs selected, connectors, empty / leaf / error. Arrows, Home, End, typeahead.
          </p>
        </div>
        <.button id="theme-toggle" phx-click="toggle_theme">Theme: {@theme}</.button>
      </div>

      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr)); gap: var(--lantern-space-lg);">
        <.card title="Environments">
          <.tree
            id="qa-env-tree"
            label="Environments"
            current_id={@current_id}
            expanded_ids={@expanded_ids}
            on_select="tree_select"
            on_toggle="tree_toggle"
          >
            <.tree_item id="prod" label="production">
              <:icon><.icon name="cloud" /></:icon>
              <:trailing>live</:trailing>
              <.tree_item id="prod-apps" label="apps">
                <.tree_item id="prod-api" label="api" />
                <.tree_item id="prod-web" label="web" />
                <.tree_item id="prod-worker" label="worker" />
              </.tree_item>
              <.tree_item id="prod-dbs" label="databases">
                <.tree_item id="prod-primary" label="primary" />
                <.tree_item id="prod-replica" label="replica" state="error">
                  <:trailing>unreachable</:trailing>
                </.tree_item>
              </.tree_item>
            </.tree_item>
            <.tree_item id="staging" label="staging">
              <:icon><.icon name="cloud" /></:icon>
              <.tree_item id="staging-apps" label="apps">
                <.tree_item id="staging-api" label="api" />
              </.tree_item>
            </.tree_item>
            <.tree_item id="dev" label="development">
              <:icon><.icon name="cloud" /></:icon>
              <.tree_item id="dev-api" label="api" />
              <.tree_item id="dev-web" label="web" />
            </.tree_item>
          </.tree>
        </.card>

        <.card title="Leaves only">
          <.tree id="qa-leaf-tree" label="Columns" current_id="col-name">
            <.tree_item id="col-name" label="name" />
            <.tree_item id="col-kind" label="kind" />
            <.tree_item id="col-updated" label="updated_at" />
          </.tree>
        </.card>

        <.card title="Empty">
          <.tree id="qa-empty-tree" label="Sources">
            <:empty>
              <.empty_state icon="folder-open" title="No sources">
                Add a repository to populate this tree.
              </.empty_state>
            </:empty>
          </.tree>
        </.card>
      </div>
    </div>
    """
  end
end
