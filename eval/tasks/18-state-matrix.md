# Task 18 — Empty / loading / error states across a page

Add a report page demonstrating all four data states to the demo app.
Static in-memory data, no DB.

- Route: `live("/eval/users-report", EvalUsersReportLive, :index)` — the
  visible state is driven by `?state=` (`loaded`, `empty`, `loading`,
  `error`; default `loaded`); unknown values fall back to `loaded`.
- Module: `LanternDemoWeb.EvalUsersReportLive`
- Data: 6 static user rows (`name`, `email`, `role`, `status`
  `active | invited | suspended`).

Requirements:

1. A **state switcher** (`tabs_list` with `variant="segmented"`: Loaded /
   Empty / Loading / Error) that `patch`es `?state=` so each state is
   deep-linkable.
2. **Loaded:** a flat `data_table`/`table` of the 6 users with a status
   column (glyph/chip per row, no grouping).
3. **Empty:** lantern `empty_state` with a title, body text, and a primary
   action button (which returns to the loaded state).
4. **Loading:** lantern `skeleton`/`loading` placeholder rows (same column
   shape as the table — visibly a loading table, not a spinner alone).
5. **Error:** a danger `alert` (or error card) with the failure text and a
   **Retry button that returns to the loaded state**.
6. Heading ("Users report") + description line in the breadcrumb bar;
   semantic tokens only.

Deliverables: the LiveView module file(s) + the route registration.
