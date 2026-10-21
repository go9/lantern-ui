# Standalone QA host for the floating-panel matrix: a bare Phoenix endpoint
# with only lantern_ui's own CSS + hooks (no host app styles to blame).
#
#   MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs
#
# Then `node test/qa/run.mjs` (see test/qa/README.md).
Logger.configure(level: :warning)
Code.require_file("matrix_live.ex", __DIR__)
Code.require_file("charts_live.ex", __DIR__)
Code.require_file("tiles_live.ex", __DIR__)
Code.require_file("stats_live.ex", __DIR__)
Code.require_file("date_range_live.ex", __DIR__)
Code.require_file("kbd_live.ex", __DIR__)
Code.require_file("consistency_live.ex", __DIR__)
Code.require_file("regressions_live.ex", __DIR__)
Code.require_file("settings_live.ex", __DIR__)
Code.require_file("project_nav_live.ex", __DIR__)
Code.require_file("conversation_live.ex", __DIR__)
Code.require_file("trace_live.ex", __DIR__)
Code.require_file("tree_live.ex", __DIR__)
Code.require_file("index_primitives_live.ex", __DIR__)
Code.require_file("table_bands_live.ex", __DIR__)
Code.require_file("provenance_live.ex", __DIR__)
Code.require_file("split_pane_live.ex", __DIR__)
Code.require_file("stage_strip_live.ex", __DIR__)
Code.require_file("diff_viewer_live.ex", __DIR__)
Code.require_file("funnel_live.ex", __DIR__)
Code.require_file("cite_chip_live.ex", __DIR__)
Code.require_file("host_badge_live.ex", __DIR__)

defmodule LanternUI.QA.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-lantern-density="compact">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>QA matrix</title>
        <link rel="stylesheet" href="/lantern_ui_theme.css" />
        <link rel="stylesheet" href="/lantern_ui.css" />
        <style>
          body { margin: 0; background: var(--lantern-bg); color: var(--lantern-fg); font-family: var(--lantern-font); }
        </style>
        <script type="module">
          import { Socket } from "/js/phoenix.mjs"
          import { LiveSocket } from "/js/phoenix_live_view.esm.js"
          import Hooks from "/lantern_ui_hooks.js"
          const csrf = document.querySelector("meta[name=csrf-token]").content
          const ls = new LiveSocket("/live", Socket, { params: { _csrf_token: csrf }, hooks: Hooks })
          ls.connect()
          window.liveSocket = ls
        </script>
      </head>
      <body>{@inner_content}</body>
    </html>
    """
  end
end

defmodule LanternUI.QA.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:put_root_layout, html: {LanternUI.QA.Layouts, :root})
    plug(:protect_from_forgery)
  end

  scope "/" do
    pipe_through(:browser)
    live("/stage_strip", LanternUI.QA.StageStripLive)
    live("/cite_chip", LanternUI.QA.CiteChipLive)
    live("/host_badge", LanternUI.QA.HostBadgeLive)
    live("/diff_viewer", LanternUI.QA.DiffViewerLive)
    live("/qa", LanternUI.QA.MatrixLive)
    live("/charts", LanternUI.QA.ChartsLive)
    live("/tiles", LanternUI.QA.TilesLive)
    live("/stats", LanternUI.QA.StatsLive)
    live("/date_range", LanternUI.QA.DateRangeLive)
    live("/kbd", LanternUI.QA.KbdLive)
    live("/consistency", LanternUI.QA.ConsistencyLive)
    live("/regressions", LanternUI.QA.RegressionsLive)
    live("/settings", LanternUI.QA.SettingsLive)
    live("/project_nav", LanternUI.QA.ProjectNavLive)
    live("/conversation", LanternUI.QA.ConversationLive)
    live("/trace", LanternUI.QA.TraceLive)
    live("/tree", LanternUI.QA.TreeLive)
    live("/index_primitives", LanternUI.QA.IndexPrimitivesLive)
    live("/table_bands", LanternUI.QA.TableBandsLive)
    live("/provenance", LanternUI.QA.ProvenanceLive)
    live("/split_pane", LanternUI.QA.SplitPaneLive)
    live("/funnel", LanternUI.QA.FunnelLive)
  end
end

defmodule LanternUI.QA.Endpoint do
  use Phoenix.Endpoint, otp_app: :lantern_ui

  @session [store: :cookie, key: "_qa", signing_salt: "qa_salt_qa"]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session]])

  plug(Plug.Static, at: "/", from: Path.expand("../../priv/static", __DIR__), gzip: false)
  plug(Plug.Static, at: "/js", from: {:phoenix, "priv/static"}, only: ~w(phoenix.mjs))

  plug(Plug.Static,
    at: "/js",
    from: {:phoenix_live_view, "priv/static"},
    only: ~w(phoenix_live_view.esm.js)
  )

  plug(Plug.Session, @session)
  plug(LanternUI.QA.Router)
end

port = String.to_integer(System.get_env("PORT", "4013"))

Application.put_env(:lantern_ui, LanternUI.QA.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: port],
  server: true,
  secret_key_base: String.duplicate("qa", 40),
  live_view: [signing_salt: "qa_lv_salt_qa"],
  check_origin: false
)

{:ok, _} = Supervisor.start_link([LanternUI.QA.Endpoint], strategy: :one_for_one)
IO.puts("QA matrix host on http://127.0.0.1:#{port}/qa?ctx=plain&cmp=select")
Process.sleep(:infinity)
