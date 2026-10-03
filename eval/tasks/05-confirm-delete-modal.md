# Task 05 — Confirm-delete modal flow

Add an API-token list page with a confirm-delete modal flow to the demo app.

- Route: `live("/eval/tokens", EvalTokensLive, :index)`
- Module: `LanternDemoWeb.EvalTokensLive`
- Data: 3 static tokens (`deploy-key`, `ci-read`, `backup-2024`), each with
  `name`, `prefix` (e.g. `"lk_live_…a3f9"`), and `created` date string.

Requirements:

1. A flat list of the tokens (name + prefix + created date), each row with
   a delete affordance (lantern `icon_button` with `aria-label`).
2. Clicking delete opens a lantern `modal` (or `alert_dialog`) asking for
   confirmation, naming the token. Confirm removes the row; cancel closes
   the dialog with no change.
3. After deletion, show a success flash or lantern toast (`toast_group` +
   `LanternUI.send_toast/3`) saying "Token deleted".
4. Focus handling: the dialog is reachable by keyboard (no pointer-only flow).

Deliverables: the LiveView module file(s) + the route registration.
