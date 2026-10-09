defmodule LanternUI.QA.StatsLive do
  use Phoenix.LiveView

  alias LanternUI.Components.Stat
  alias LanternUI.Charts

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"
    {:ok, assign(socket, theme: theme)}
  end

  def handle_event("toggle_theme", _params, socket) do
    next = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, theme: next)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="stats-qa"
      class={["stats-qa-page", @theme == "dark" && "dark"]}
      style="padding: 1.5rem; max-width: 1200px; margin: 0 auto; background: var(--lantern-surface); color: var(--lantern-fg); min-height: 100vh;"
    >
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem;">
        <div>
          <h1 style="font-size: 1.5rem; font-weight: 700; margin: 0 0 0.25rem 0;">
            Stat Cards & Sparklines QA Matrix
          </h1>
          <p style="margin: 0; color: var(--lantern-fg-muted); font-size: 0.875rem;">
            Verifying :sparkline slot, sparkline_series, and data-tone variants
          </p>
        </div>
        <button
          id="theme-toggle"
          phx-click="toggle_theme"
          style="padding: 0.4rem 0.8rem; border-radius: 6px; border: 1px solid var(--lantern-border); background: var(--lantern-surface-raised); color: var(--lantern-fg); cursor: pointer;"
        >
          Theme: {@theme}
        </button>
      </div>

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1.1rem; font-weight: 600; margin-bottom: 0.75rem;">
          Semantic Tone Variants in Stat Grid
        </h2>
        <Stat.stat_grid id="tones-grid">
          <:stat
            id="stat-neutral"
            label="Total Visitors"
            value="128,490"
            subtitle="Trailing 30 days"
            tone="neutral"
            sparkline_series={[40, 45, 42, 50, 48, 55, 60]}
          />
          <:stat
            id="stat-info"
            label="New Signups"
            value="1,420"
            subtitle="+8.4% vs last week"
            tone="info"
            sparkline_series={[10, 14, 18, 15, 22, 28, 35]}
          />
          <:stat
            id="stat-success"
            label="Gross Revenue"
            value="$42,850"
            subtitle="+14.2% growth"
            tone="success"
            sparkline_series={[20, 24, 22, 30, 38, 42, 52]}
          />
          <:stat
            id="stat-warning"
            label="Avg Response Time"
            value="240ms"
            subtitle="Slight degradation"
            tone="warning"
            sparkline_series={[180, 190, 210, 205, 230, 240]}
          />
          <:stat
            id="stat-danger"
            label="Error Rate"
            value="2.84%"
            subtitle="+1.2% spike"
            tone="danger"
            sparkline_series={[0.8, 1.1, 0.9, 1.4, 2.2, 2.84]}
          />
          <:stat
            id="stat-promo"
            label="Conversion Rate"
            value="6.4%"
            subtitle="Promo tier active"
            tone="promo"
            sparkline_series={[2.1, 2.5, 3.2, 4.0, 5.2, 6.4]}
          />
        </Stat.stat_grid>
      </section>

      <section style="margin-bottom: 2rem;">
        <h2 style="font-size: 1.1rem; font-weight: 600; margin-bottom: 0.75rem;">
          Standalone Stat Cards with Custom :sparkline Slot
        </h2>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;">
          <Stat.stat_card
            id="stat-custom-success"
            label="Daily Orders"
            value="342"
            subtitle="+18.5% today"
            tone="success"
          >
            <:sparkline>
              <Charts.sparkline
                id="spark-orders"
                series={[12, 18, 14, 22, 28, 35]}
                color="currentColor"
              />
            </:sparkline>
          </Stat.stat_card>

          <Stat.stat_card
            id="stat-custom-danger"
            label="Failed Deliveries"
            value="3"
            subtitle="Requires review"
            tone="danger"
          >
            <:sparkline>
              <Charts.sparkline
                id="spark-failed"
                series={[0, 1, 0, 0, 2, 3]}
                color="currentColor"
              />
            </:sparkline>
          </Stat.stat_card>

          <Stat.stat_card
            id="stat-linked"
            label="Open Pull Requests"
            value="14"
            subtitle="Click to view repository"
            href="#pr-link"
            tone="info"
          >
            <:sparkline>
              <Charts.sparkline
                id="spark-prs"
                series={[18, 16, 15, 14, 14]}
                color="currentColor"
              />
            </:sparkline>
          </Stat.stat_card>
        </div>
      </section>
    </div>
    """
  end
end
