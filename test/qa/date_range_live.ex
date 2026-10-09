defmodule LanternUI.QA.DateRangeLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"

    {:ok,
     assign(socket,
       theme: theme,
       date_range_1: %{
         "preset" => "30D",
         "start_date" => "2026-09-10",
         "end_date" => "2026-10-09",
         "compare_previous" => "true"
       },
       date_range_2: %{
         "preset" => "7D",
         "start_date" => "2026-10-03",
         "end_date" => "2026-10-09",
         "compare_previous" => "false"
       },
       date_range_custom: %{
         "preset" => "custom",
         "start_date" => "2026-10-15",
         "end_date" => "2026-10-01",
         "compare_previous" => "false"
       },
       error_msg: "Start date cannot be after end date"
     )}
  end

  def handle_event("toggle_theme", _params, socket) do
    next_theme = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, :theme, next_theme)}
  end

  def handle_event("range_1_change", %{"date_range" => params}, socket) do
    {:noreply, assign(socket, :date_range_1, params)}
  end

  def handle_event("range_2_change", %{"chart_range" => params}, socket) do
    {:noreply, assign(socket, :date_range_2, params)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="qa-date-range-root"
      data-lantern-theme={@theme}
      style="min-height: 100vh; padding: 2rem; background: var(--lantern-bg); color: var(--lantern-fg); box-sizing: border-box;"
    >
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 2rem;">
        <div>
          <h1 style="font-size: 1.5rem; font-weight: 700; margin: 0 0 0.25rem 0;">
            Date Range Popover QA Matrix
          </h1>
          <p style="margin: 0; color: var(--lantern-fg-muted); font-size: 0.875rem;">
            Verifying presets (7D/30D/90D/MTD/QTD/YTD/Custom), form events, and error states
          </p>
        </div>
        <button
          type="button"
          id="theme-toggle"
          phx-click="toggle_theme"
          style="padding: 0.5rem 1rem; border-radius: 6px; border: 1px solid var(--lantern-border); background: var(--lantern-surface); color: var(--lantern-fg); cursor: pointer;"
        >
          Theme: {@theme}
        </button>
      </div>

      <div style="display: flex; flex-direction: column; gap: 2rem;">
        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            1. Standard Anchored Popover (Presets and Compare)
          </h2>
          <div style="display: flex; align-items: center; gap: 1.5rem; flex-wrap: wrap;">
            <.date_range_popover
              id="qa-date-popover-1"
              preset={@date_range_1["preset"]}
              start_date={@date_range_1["start_date"]}
              end_date={@date_range_1["end_date"]}
              compare_previous={@date_range_1["compare_previous"] == "true"}
              phx-change="range_1_change"
            />
            <div style="font-size: 0.875rem; color: var(--lantern-fg-muted);">
              Active preset: <code style="font-weight: 600;">{@date_range_1["preset"]}</code>
              |
              Dates:
              <code style="font-weight: 600;">{@date_range_1["start_date"]} – {@date_range_1[
                "end_date"
              ]}</code>
              |
              Compare: <code style="font-weight: 600;">{@date_range_1["compare_previous"]}</code>
            </div>
          </div>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            2. Inside Chart Card Range Controls Slot
          </h2>
          <.chart_card id="qa-chart-card" title="Platform Analytics" value="98,420">
            <:range_controls>
              <.date_range_popover
                id="qa-date-popover-2"
                name_prefix="chart_range"
                preset={@date_range_2["preset"]}
                start_date={@date_range_2["start_date"]}
                end_date={@date_range_2["end_date"]}
                compare_previous={@date_range_2["compare_previous"] == "true"}
                phx-change="range_2_change"
              />
            </:range_controls>
            <div style="height: 120px; display: flex; align-items: center; justify-content: center; background: var(--lantern-surface-subtle); border-radius: 6px; color: var(--lantern-fg-muted); font-size: 0.875rem;">
              Chart content area
            </div>
          </.chart_card>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            3. Custom Range with Validation Error State
          </h2>
          <div style="display: flex; align-items: center; gap: 1.5rem; flex-wrap: wrap;">
            <.date_range_popover
              id="qa-date-popover-error"
              preset={@date_range_custom["preset"]}
              start_date={@date_range_custom["start_date"]}
              end_date={@date_range_custom["end_date"]}
              error={@error_msg}
              apply_button={true}
            />
            <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">
              Displays inline danger notice and aria-invalid states
            </span>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
