# Task 06 — Paginated data_table with search

Add a paginated, searchable people directory page to the demo app.

- Route: `live("/eval/people", EvalPeopleLive, :index)`
- Module: `LanternDemoWeb.EvalPeopleLive`
- Data: 25 static people, each with `name`, `email`, `role`
  (`:admin` | `:member` | `:viewer`), and `joined` date string.

Requirements:

1. Render the directory with the lantern `data_table` (or `table` +
   `pagination` if `data_table` does not support the feature).
2. A search box filters rows by name or email (server-side, on change).
3. Pagination at 10 rows per page with page controls; page resets to 1 when
   the search query changes. Empty search results show an empty message
   (lantern `empty_state` preferred).
4. Role renders as a lantern `badge`, not raw text.

Deliverables: the LiveView module file(s) + the route registration.
