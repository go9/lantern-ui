# Task 09 — Onboarding multi-field form

Add a team-member onboarding form page to the demo app.

- Route: `live("/eval/onboarding", EvalOnboardingLive, :index)`
- Module: `LanternDemoWeb.EvalOnboardingLive`
- Fields: full name (required), work email (required, must contain `@`),
  department (`:engineering` | `:design` | `:ops`, required),
  start date (required), equipment needed (zero or more of
  `:laptop` | `:monitor` | `:keyboard`), remote (`:yes` | `:no`, required).

Requirements:

1. Use lantern `form` components throughout: text inputs, `select`,
   checkboxes (multi), radios — matching each field kind. No raw
   `<input>`/`<select>` tags.
2. Validate on submit; show inline errors next to each invalid field and a
   summary count ("3 fields need attention").
3. On valid submit, show a success flash or lantern toast (`toast_group` +
   `LanternUI.send_toast/3`) and a summary of the
   entered values on the page.
4. Every input has a visible associated label.

Deliverables: the LiveView module file(s) + the route registration.
