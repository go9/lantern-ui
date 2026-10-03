# Task 13 — Data-heavy ops dashboard (stats + chart + sortable/filterable/paginated table)

Add an ops overview page to the demo app. Static in-memory data, no DB.

- Route: `live("/eval/ops", EvalOpsLive, :index)`
- Module: `LanternDemoWeb.EvalOpsLive`
- Data: 4 stats (label + value + change text, e.g. "Deploys 128 (+12 this
  week)", "Error rate 0.4% (-0.1pp)", "Active hosts 96", "P95 latency 210ms"),
  one 14-point series (deploys per day) for the chart, and 24 static service
  rows (`name`, `env` `prod | staging | dev`, `status` `healthy | degraded |
  down`, `p95` latency string, `error_rate` string).

Requirements:

1. Four stat cards in a row (`stat_card` / `stat_grid`).
2. One lantern chart (`area_chart` / `bar_chart` / `line_chart`) rendering the
   14-point series with readable axes (no clipped labels), below the stats.
3. A `data_table` of the 24 services with: click-to-sort column headers (at
   least name + p95), a text search box filtering by name, env filter chips
   (`tabs_list` with `variant="segmented"`: All / Prod / Staging / Dev), and
   `pagination` (8 rows per page). Sorting + filter + pagination compose
   (page resets to 1 when the filter changes). Status renders as a status
   column with glyphs/chips — never grouped headers.
4. Heading ("Operations") + description line in the breadcrumb bar / page
   header; semantic tokens only.

Deliverables: the LiveView module file(s) + the route registration.
