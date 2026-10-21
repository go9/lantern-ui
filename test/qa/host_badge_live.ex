defmodule LanternUI.QA.HostBadgeLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def render(assigns) do
    ~H"""
    <main
      class="lui-settings-page"
      style="min-height: 100vh; box-sizing: border-box; padding: var(--lantern-space-lg); background: var(--lantern-surface); color: var(--lantern-fg);"
    >
      <h1>Host identity</h1>
      <p>One identity label in resource lists and creation choices.</p>
      <.table id="host-resources">
        <.table_head>
          <:col>Resource</:col>
          <:col>Host</:col>
        </.table_head>
        <.table_body>
          <.table_row>
            <:cell>foodfeed</:cell>
            <:cell><.host_badge host="Flicker" /></:cell>
          </.table_row>
          <.table_row>
            <:cell>foodfeed-db</:cell>
            <:cell><.host_badge host="Flicker" /></:cell>
          </.table_row>
        </.table_body>
      </.table>
      <fieldset>
        <legend>Host for a new resource</legend>
        <label>
          <input type="radio" name="host" value="flicker" checked />
          <.host_badge host="Flicker" />
        </label>
        <label>
          <input type="radio" name="host" value="fly" disabled />
          <.host_badge host="Fly" coming_soon />
        </label>
        <label>
          <input type="radio" name="host" value="neon" disabled />
          <.host_badge host="Neon" coming_soon />
        </label>
      </fieldset>
    </main>
    """
  end
end
