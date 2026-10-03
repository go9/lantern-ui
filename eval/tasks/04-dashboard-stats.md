# Task 04 — Dashboard stat cards + one chart

Add a small overview dashboard page to the demo app.

- Route: `live("/eval/overview", EvalOverviewLive, :index)`
- Module: `LanternDemoWeb.EvalOverviewLive`
- Data: 4 static stats (label + value + optional change text, e.g.
  "Deployments 128 (+12 this week)", "Error rate 0.4% (-0.1)",
  "Active users 1,024", "P95 latency 210ms") and one 12-point series
  (deploys per day) for the chart.

Requirements:

1. Four stat cards in a row using the lantern `stat_card` component
   (or `stat_grid`, or `card` + lantern type scale if those do not fit).
2. One chart below the cards rendering the 12-point series with a lantern
   chart component (area/bar/line — whichever fits). Axes must be readable
   (no clipped labels).
3. Semantic tokens for all colors; no hardcoded chart hex colors if the
   chart component accepts token-based theming.
4. Page has a heading ("Overview") and a short description line.

Deliverables: the LiveView module file(s) + the route registration.
