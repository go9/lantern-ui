# Task 01 — Ticket index (flat list + status filter + row click)

Add a ticket index page to the demo app.

- Route: `live("/eval/tickets", EvalTicketsLive, :index)`
- Module: `LanternDemoWeb.EvalTicketsLive`
- Data: 8 static tickets, each with `id` (e.g. `"TCK-101"`), `title`,
  `status` (`:open` | `:in_progress` | `:done`), `priority`
  (`:low` | `:medium` | `:high`), and `updated` date string. Note: the
  status glyph has no `:open` value — map it to the closest glyph value
  (mapping domain values onto the glyph vocabulary is part of the work).

Requirements:

1. A **flat** ticket list — one row per ticket. No grouping, no group headers.
2. A status filter above the list (`All`, `Open`, `In progress`, `Done`) that
   filters the rows. Use `tabs_list` with `variant="segmented"` for the
   filter (the old `segmented` component is deprecated), else lantern
   `badge`s or `button`s as filter chips.
3. Each row shows a priority glyph, the ticket id, a status glyph, the title,
   and the updated date. Prefer `list_row` + `status_glyph`/`priority_glyph`.
4. Clicking a row navigates to `/eval/tickets/:id` (a stub detail page —
   a simple placeholder heading is fine).

Deliverables: the LiveView module file(s) + the route registration.
