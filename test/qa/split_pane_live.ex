defmodule LanternUI.QA.SplitPaneLive do
  use Phoenix.LiveView
  use LanternUI

  def mount(_, _, socket), do: {:ok, assign(socket, :mobile_pane, "primary")}
  def handle_event("detail", _, socket), do: {:noreply, assign(socket, :mobile_pane, "secondary")}
  def handle_event("back", _, socket), do: {:noreply, assign(socket, :mobile_pane, "primary")}
  def handle_event("patch", _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <.page_shell
      id="split-demo"
      title="Split pane"
    >
      <.split_pane
        id="suggestions"
        label="Suggestions list width"
        storage_key="qa-suggestions"
        mobile_pane={@mobile_pane}
      >
        <:primary>
          <.list_row
            title="Search loses the selected filter"
            subtitle="Bug · received today"
            href="#report-detail"
            phx-click="detail"
          />
          <.list_row
            title="Export filtered results"
            subtitle="Feature request · received yesterday"
            href="#report-detail"
            phx-click="detail"
          />
        </:primary>
        <:secondary>
          <.card id="report-detail" title="Search loses the selected filter">
            <p>The selected filter clears after returning from a report.</p>
            <.button phx-click="back">Back to list</.button>
          </.card>
        </:secondary>
      </.split_pane>
    </.page_shell>
    """
  end
end
