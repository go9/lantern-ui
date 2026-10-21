defmodule LanternUI.QA.CockpitDockLive do
  use Phoenix.LiveView
  use LanternUI

  def mount(_, _, socket), do: {:ok, assign(socket, view: "list", open: true)}
  def handle_event("open", _, socket), do: {:noreply, assign(socket, :view, "thread")}
  def handle_event("back", _, socket), do: {:noreply, assign(socket, :view, "list")}
  def handle_event("toggle", _, socket), do: {:noreply, update(socket, :open, &(!&1))}

  def render(assigns) do
    ~H"""
    <.page_shell id="dock-demo" title="Cockpit dock">
      <div style="display:flex;min-height:24rem">
        <div style="flex:1">
          <.button phx-click="toggle" aria-controls="dock" aria-expanded={to_string(@open)}>
            Toggle cockpit
          </.button>
        </div>
        <.cockpit_dock id="dock" label="Cockpit" open={@open} view={@view}>
          <:header><strong>Cockpit</strong></:header>
          <:list>
            <.list_row
              title="Needs you: approve deploy"
              subtitle="Waiting 5m"
              href="#thread"
              phx-click="open"
            />
            <.list_row
              title="Search regression"
              subtitle="Agent working"
              href="#thread"
              phx-click="open"
            />
          </:list>
          <:thread>
            <div style="padding:.75rem">
              <.button phx-click="back">Back</.button>
              <p>Approve the deploy to continue.</p>
            </div>
          </:thread>
        </.cockpit_dock>
      </div>
    </.page_shell>
    """
  end
end
