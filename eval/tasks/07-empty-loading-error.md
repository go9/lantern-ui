# Task 07 — Empty / loading / error states

Add a report page that demonstrates empty, loading, and error states to the
demo app.

- Route: `live("/eval/report", EvalReportLive, :index)`
- Module: `LanternDemoWeb.EvalReportLive`
- Data: none remote — simulate with a `:state` assign cycled by three
  buttons ("Show data", "Show empty", "Simulate error"). Loading appears
  briefly (1s) whenever the state button is pressed before the new state
  renders.

Requirements:

1. Data state: a simple flat list of 3 report lines (title + value).
2. Empty state: lantern `empty_state` with a title, description, and a
   primary action button.
3. Loading state: lantern `skeleton` or `loading` placeholder (no blank page).
4. Error state: an error message with a "Retry" button that returns to the
   data state. Use semantic danger tokens, not hardcoded red.
5. The three state-switch buttons are visible in all states (so a grader can
   cycle them).

Deliverables: the LiveView module file(s) + the route registration.
