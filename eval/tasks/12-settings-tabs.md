# Task 12 — Settings with server-driven tabs and a controlled select

Add a settings page with URL-driven tabs to the demo app. Static
in-memory state (assigns only), no DB.

- Route: `live("/eval/settings-tabs", EvalSettingsTabsLive, :index)` —
  the active tab is read from `?tab=` (`profile`, `notifications`, `billing`;
  default `profile`). Unknown `?tab=` falls back to `profile`.
- Module: `LanternDemoWeb.EvalSettingsTabsLive`

Requirements:

1. **Server-driven tabs:** tab switches are `patch` navigations that change
   `?tab=` (back button + deep links work). The tab control reflects the
   URL state on first render (no client-only tab state). Use lantern `tabs`
   / `tabs_list` for the tab bar.
2. **Profile tab:** a stacked section card with its own form and save row —
   display name (`input`), bio (`textarea`), timezone (controlled `select`:
   `value` bound to the assign, `on-change` updates the assign immediately).
   Save shows a toast confirmation.
3. **Notifications tab:** two or three `switch` / `checkbox` preference rows
   with labels, plus a save row that toasts confirmation.
4. **Billing tab:** a plan `select` (Hobby / Team / Enterprise) plus a
   read-only current-plan line; changing the plan updates the read-only line
   and toasts.
5. Title and actions in the breadcrumb bar; semantic tokens only; every input
   has an associated label.

Deliverables: the LiveView module file(s) + the route registration.
