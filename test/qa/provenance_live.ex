defmodule LanternUI.QA.ProvenanceLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, state: "override")}

  def handle_event("revert", _, socket),
    do: {:noreply, assign(socket, :state, "inherited")}

  def render(assigns) do
    ~H"""
    <.page_shell id="provenance" title="Provenance">
      <.table id="origins">
        <.table_head>
          <:col>Entity</:col><:col>Source</:col>
        </.table_head>
        <.table_body>
          <.table_row>
            <:cell>API branch</:cell>
            <:cell>
              <.provenance_badge id="api-origin" state={@state} source="Production">
                <:revert>
                  <.button
                    id="revert-api"
                    size="xs"
                    variant="ghost"
                    label="Revert API branch to Production"
                    phx-click="revert"
                  >
                    Revert
                  </.button>
                </:revert>
              </.provenance_badge>
            </:cell>
          </.table_row>
        </.table_body>
      </.table>
      <.description_list>
        <:item label="Local profile"><.provenance_badge state="own" /></:item>
        <:item label="Inherited profile">
          <.provenance_badge state="inherited" source="Organization" />
        </:item>
        <:item label="Evidence #212"><.provenance_badge state="current" /></:item>
        <:item label="Evidence #208"><.provenance_badge state="historical" /></:item>
        <:item label="Evidence #230"><.provenance_badge /></:item>
      </.description_list>
    </.page_shell>
    """
  end
end
