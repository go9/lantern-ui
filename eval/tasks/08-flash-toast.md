# Task 08 — Flash / toast feedback on action

Add a notification-preferences page with toast feedback to the demo app.

- Route: `live("/eval/notifications", EvalNotificationsLive, :index)`
- Module: `LanternDemoWeb.EvalNotificationsLive`
- Data: 3 static channels (`Email`, `Slack`, `SMS`), each with a boolean
  `enabled` assign.

Requirements:

1. Each channel is a row with its name and a lantern toggle (`switch` or
   `checkbox`). Toggling flips the state immediately.
2. Every toggle shows user-visible feedback via flash or lantern toast
   (a `toast_group` on the page + `LanternUI.send_toast/3` — there is no
   bare `toast` component), e.g. "Slack notifications on".
3. Toggles are keyboard-operable lantern components (not clickable divs).
4. Page has a heading ("Notifications") and one line of description.

Deliverables: the LiveView module file(s) + the route registration.
