# Task 03 — Record detail with inspector side panel

Add a server detail page with an inspector side panel to the demo app.

- Route: `live("/eval/servers/:id", EvalServerLive, :show)`
- Module: `LanternDemoWeb.EvalServerLive`
- Data: 3 static servers (`web-01`, `db-01`, `cache-01`), each with `id`,
  `role`, `region`, `status` (`:healthy` | `:degraded` | `:down`), `uptime`,
  and `version`. Unknown ids show a not-found message. Note: `:healthy` /
  `:degraded` / `:down` are not status-glyph values — use a lantern `badge`
  for health, or map onto the closest glyph value.

Requirements:

1. Main column: server id as heading, status shown with a lantern status
   indicator (`status_glyph` or `badge`), plus uptime and version.
2. A side panel (lantern `side_panel` or `inspector` + `property_row`) showing
   label/value rows: Role, Region, Status, Uptime, Version.
3. The panel can be collapsed/expanded and the main content reflows.
4. A back link to `/eval/servers` (a stub index — a simple list of links
   to the three servers is fine).

Deliverables: the LiveView module file(s) + the route registration(s).
