# Task 02 — Settings form with validation

Add a workspace settings form page to the demo app.

- Route: `live("/eval/settings", EvalSettingsLive, :index)`
- Module: `LanternDemoWeb.EvalSettingsLive`
- Fields: workspace name (required, min 3 chars), contact email (required,
  must contain `@`), weekly digest (boolean), theme (`:light` | `:dark` |
  `:system`).

Requirements:

1. Build the form with lantern `form` components (not raw `<input>` tags).
2. Validate on change and on submit; show inline field errors for invalid
   input (e.g. empty name, email without `@`).
3. On valid submit, show a success flash or lantern toast (`toast_group` +
   `LanternUI.send_toast/3`) saying "Settings saved", and keep
   the entered values.
4. Every input has a visible associated label.

Deliverables: the LiveView module file(s) + the route registration.
