defmodule LanternUI.QA.ChartsLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  @types ~w(line area stacked_area bar stacked_bar grouped_bar points)

  def mount(params, _session, socket) do
    type = if params["type"] in @types, do: String.to_existing_atom(params["type"]), else: :line
    theme = if params["theme"] == "dark", do: "dark", else: "light"
    orientation = if params["orientation"] == "horizontal", do: :horizontal, else: :vertical

    series = [
      %{
        id: :collection,
        label: "Collection",
        color: "var(--lantern-chart-1)",
        points: [
          %{x: "Apr", y: -18},
          %{x: "May", y: 26},
          %{x: "Jun", y: 41},
          %{x: "Jul", y: 22},
          %{x: "Aug", y: 56}
        ]
      },
      %{
        id: :inventory,
        label: "Inventory",
        color: "var(--lantern-chart-2)",
        points: [
          %{x: "Apr", y: 32},
          %{x: "May", y: -12},
          %{x: "Jun", y: 19},
          %{x: "Jul", y: 33},
          %{x: "Aug", y: -9}
        ]
      }
    ]

    {:ok,
     assign(socket,
       type: type,
       orientation: orientation,
       empty: params["empty"] == "1",
       theme: theme,
       series: series,
       selected_point: nil,
       settings_payload: %{},
       page_title: "Time series QA"
     ), layout: false}
  end

  def handle_event("chart_settings", %{"chart_settings" => payload}, socket) do
    {:noreply, assign(socket, settings_payload: payload)}
  end

  def handle_event("chart_select", payload, socket) do
    {:noreply, assign(socket, selected_point: payload)}
  end

  def render(assigns) do
    ~H"""
    <style>
      .lui-chart-qa { max-width: 70rem; margin: 2rem auto; padding: 1rem; color: var(--lantern-fg); }
      .lui-chart-qa { width: 100%; min-height: 100vh; max-width: none; box-sizing: border-box; margin: 0; background: var(--lantern-surface-sunken); }
      .lui-chart-qa header, .lui-chart-qa section { max-width: 70rem; margin-left: auto; margin-right: auto; }
      .lui-chart-qa header { margin-bottom: 1rem; }
      .lui-chart-qa header p { margin: 0; color: var(--lantern-accent); font-size: .7rem; letter-spacing: .1em; }
      .lui-chart-qa h1 { margin: .25rem 0; font-size: 1.4rem; }
      .lui-chart-qa header span { color: var(--lantern-fg-muted); font-size: .8rem; }
      .lui-chart-qa section { padding: 1rem; border: 1px solid var(--lantern-border); border-radius: var(--lantern-radius-lg); background: var(--lantern-surface); }
      @media (max-width: 40rem) { .lui-chart-qa { margin: .5rem auto; padding: .5rem; } .lui-chart-qa section { padding: .75rem; } }
    </style>
    <main class={"lui-chart-qa #{@theme}"}>
      <header>
        <p>PORTFOLIO PERFORMANCE</p>
        <h1>Generic chart · {@type}</h1>
        <span>Positive and negative values · April–August</span>
      </header>
      <.chart_card
        id="qa-chart-card"
        title="Portfolio value"
        value="$8,420"
        empty={if @empty, do: "No history in this period", else: nil}
      >
        <:tabs><.button size="sm" variant="ghost">Value</.button></:tabs>
        <:range_controls>
          <.button size="sm" variant="outline">1M</.button>
          <.button size="sm" variant="outline">1Y</.button>
        </:range_controls>
        <:settings_trigger>
          <.chart_settings
            id="qa-chart-settings"
            series={@series}
            type={Atom.to_string(@type)}
            curve="monotone"
            glyphs
            phx-change="chart_settings"
          />
        </:settings_trigger>
        <.time_series_chart
          id="qa-time-series"
          aria_label={"Portfolio performance, #{@type} chart"}
          series={@series}
          type={@type}
          orientation={@orientation}
          curve={:monotone}
          comparison={[
            %{
              id: :collection,
              label: "Previous period",
              points: [
                %{x: "Apr", y: -12},
                %{x: "May", y: 18},
                %{x: "Jun", y: 28},
                %{x: "Jul", y: 14},
                %{x: "Aug", y: 39}
              ]
            }
          ]}
          annotations={
            if @type in [:bar, :stacked_bar, :grouped_bar],
              do: [],
              else: [%{id: :midpoint, x: "Jun", label: "Mid period", tone: :warning}]
          }
          select_event="chart_select"
          glyphs
        />
        <:footer_note>Illustrative data · updated daily</:footer_note>
      </.chart_card>
      <p :if={@selected_point} id="qa-chart-selection">
        Selected {@selected_point["x"]}: {Jason.encode!(@selected_point["values"])}
      </p>
      <output id="qa-chart-settings-payload" data-payload={Jason.encode!(@settings_payload)} hidden></output>
    </main>
    """
  end
end
