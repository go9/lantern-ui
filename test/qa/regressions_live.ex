defmodule LanternUI.QA.RegressionsLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    days = for offset <- 0..29, do: Date.add(~D[2026-09-01], offset)

    points =
      for {day, index} <- Enum.with_index(days),
          do: %{x: day, y: if(index in [4, 27], do: 38 + index, else: 0)}

    rows = [
      %{id: 1, name: "Item One", image: "/qa-thumbnail.svg", status: "Active"},
      %{id: 2, name: "Item Two", image: nil, status: "Draft"},
      %{id: 3, name: "Item Three", image: "/qa-thumbnail.svg", status: "Active"}
    ]

    {:ok,
     assign(socket,
       theme: if(params["theme"] == "dark", do: "dark", else: "light"),
       expanded?: params["expand"] == "1",
       rows: rows,
       points: points,
       meta: %{
         flop: %{},
         params: %{},
         current_page: 1,
         total_pages: 1,
         page_size: 10,
         total_count: 3
       }
     ), layout: false}
  end

  def handle_params(params, _uri, socket),
    do: {:noreply, assign(socket, :expanded?, params["expand"] == "1")}

  def handle_event("chart_select", _payload, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <main class={@theme} id="qa-regressions">
      <style>
        #qa-regressions { min-height:100vh; padding:1.5rem; background:var(--lantern-surface); color:var(--lantern-fg); font-family:var(--lantern-font); }
        #qa-regressions > header, #qa-regressions > section { max-width:72rem; margin:0 auto 1.5rem; }
        #qa-regressions h1 { margin:0 0 1rem; font-size:1.5rem; }
        #qa-regressions h2 { margin:0 0 .75rem; font-size:1rem; }
        .qa-control-row { display:flex; align-items:center; gap:.5rem; flex-wrap:wrap; }
        .qa-overview { padding:1rem; color:var(--lantern-fg-muted); }
        @media (max-width:40rem) { #qa-regressions { padding:.75rem; } }
      </style>
      <header>
        <h1>Component regression gallery</h1>
      </header>
      <section>
        <h2>Controls</h2>
        <div class="qa-control-row">
          <.tabs_list
            id="qa-segmented"
            variant="segmented"
            size="md"
            active_tab="day"
            aria-label="Range"
          >
            <:tab name="day">Day</:tab><:tab name="week">Week</:tab><:tab name="month">Month</:tab>
          </.tabs_list>
          <.button variant="outline" size="md">Compare</.button>
          <.button variant="outline" size="icon-md" label="Settings"><.icon name="adjustments-horizontal" /></.button>
        </div>
      </section>
      <section>
        <h2>Table</h2>
        <.data_table
          id="qa-regression-table"
          rows={@rows}
          meta={@meta}
          path="/regressions"
          search_field={:name}
          expandable
          expanded={@expanded?}
          saved_view_event="saved-view"
        >
          <:overview>
            <div class="qa-overview">Overview · Activity across the last month</div>
          </:overview>
          <:view id="recent" name="Recent items" params={%{"order_by" => ["name"]}} />
          <:filter
            field={:status}
            label="Status"
            options={[{"Active", "Active"}, {"Draft", "Draft"}]}
          />
          <:col :let={row} label="Item" field={:name}>
            <span class="lui-thumbnail-cell">
              <.thumbnail id={"qa-row-#{row.id}-image"} src={row.image} alt={row.name} />
              <span>{row.name}</span>
            </span>
          </:col>
          <:col :let={row} label="Status" field={:status}>{row.status}</:col>
        </.data_table>
      </section>
      <section>
        <h2>Sparse daily bars</h2>
        <.chart_card id="qa-regression-chart-card" title="Daily activity">
          <:range_controls>
            <.tabs_list
              id="qa-chart-range"
              variant="segmented"
              size="md"
              active_tab="month"
              aria-label="Chart range"
            >
              <:tab name="week">Week</:tab><:tab name="month">Month</:tab>
            </.tabs_list>
          </:range_controls>
          <:settings_trigger><.chart_settings id="qa-regression-chart-settings" /></:settings_trigger>
          <.time_series_chart
            id="qa-regression-chart"
            type={:bar}
            aria_label="Daily activity"
            series={[
              %{id: :activity, label: "Activity", color: "var(--lantern-chart-1)", points: @points}
            ]}
            reference_lines={[%{label: "Average", value: 38.59}]}
            value_format={:currency}
            select_event="chart_select"
          />
        </.chart_card>
      </section>
    </main>
    """
  end
end
