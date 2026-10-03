# Task 17 — Onboarding wizard with step state

Add a 4-step onboarding wizard to the demo app. Static in-memory state
(assigns only), no DB.

- Route: `live("/eval/wizard", EvalWizardLive, :index)` — the current step
  lives in `?step=` (`1`–`4`, default `1`); unknown values fall back to `1`.
- Module: `LanternDemoWeb.EvalWizardLive`
- Steps: 1 Account (name + work email inputs), 2 Profile (role `select` +
  bio `textarea`), 3 Preferences (two `switch`/`checkbox` rows + a plan
  `select`), 4 Review (read-only summary of everything + Submit).

Requirements:

1. **Step state in the URL:** Back/Next are `patch` navigations changing
   `?step=` (deep links + back button work); the wizard reads the step from
   `handle_params`, not from client-only state.
2. A visible **progress indicator** (lantern `progress` and/or numbered step
   list) showing current step out of 4.
3. **Per-step validation:** Next refuses to advance with inline errors
   (blank name, non-email email on step 1; nothing selected on step 3's plan
   select). Entered values survive Back/Next navigation.
4. **Review + submit:** step 4 renders a read-only summary
   (`description_list` preferred) plus a Submit button; submitting shows a
   success state (`empty_state` or success card — not a bare string) and a
   toast confirmation.
5. Heading ("Onboarding") in the breadcrumb bar; every input labeled;
   semantic tokens only.

Deliverables: the LiveView module file(s) + the route registration.
