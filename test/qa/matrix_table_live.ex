defmodule LanternUI.QA.MatrixTableLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, added: nil)}

  def handle_event("previews", _params, socket), do: {:noreply, socket}

  def handle_event("add", %{"cell" => cell}, socket), do: {:noreply, assign(socket, added: cell)}

  def render(assigns) do
    ~H"""
    <.page_shell id="matrix-table-demo" title="Matrix table">
      <p :if={@added} id="matrix-added">Add requested: {@added}</p>
      <.matrix_table caption="Environments across components" corner="Environment" id="matrix">
        <:col kind="app">web</:col>
        <:col kind="app">worker</:col>
        <:col kind="database">primary</:col>
        <.matrix_row label="main" navigate="/matrix_table#main">
          <:meta>production</:meta>
          <.matrix_cell state="present" label="Ready" navigate="/matrix_table#web" />
          <.matrix_cell state="present" label="Ready" navigate="/matrix_table#worker" />
          <.matrix_cell state="present" label="Ready" navigate="/matrix_table#primary" />
        </.matrix_row>
        <.matrix_row label="staging" depth={1} navigate="/matrix_table#staging">
          <.matrix_cell state="degraded" navigate="/matrix_table#web" />
          <.matrix_cell state="failed" label="Deploy failed" navigate="/matrix_table#worker" />
          <.matrix_cell state="in_rule" navigate="/matrix_table#staging" />
        </.matrix_row>
        <.matrix_row label="dev/maya" depth={2}>
          <.matrix_cell state="present" label="Ready" />
          <.matrix_cell
            state="absent"
            add_label="Add worker to dev/maya"
            phx-click="add"
            phx-value-cell="worker"
          />
          <.matrix_cell
            state="absent"
            add_label="Add primary to dev/maya"
            phx-click="add"
            phx-value-cell="primary"
          />
        </.matrix_row>
        <.table_placeholder_row
          colspan={4}
          icon="chevron-down"
          label="3 previews"
          phx-click="previews"
        />
      </.matrix_table>
    </.page_shell>
    """
  end
end
