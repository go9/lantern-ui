# Task 10 — App shell + nav

Add an admin section shell with navigation to the demo app.

- Routes: `live("/eval/admin", EvalAdminLive, :index)`,
  `live("/eval/admin/users", EvalAdminUsersLive, :index)`,
  `live("/eval/admin/billing", EvalAdminBillingLive, :index)`
- Modules: `LanternDemoWeb.EvalAdminLive`, `LanternDemoWeb.EvalAdminUsersLive`,
  `LanternDemoWeb.EvalAdminBillingLive` (shared nav extracted to a function
  component or `live_component` if you prefer).

Requirements:

1. All three pages share one shell: sidebar or top nav built with lantern
   `navlist` (or layout components), with items Overview (`/eval/admin`),
   Users (`/eval/admin/users`), Billing (`/eval/admin/billing`).
2. The current page's nav item is visually marked active on each page.
3. Each page shows a lantern `breadcrumb` (e.g. Admin / Users) plus a page
   heading and one paragraph of stub content.
4. Semantic tokens only; the shell works at 1280px width with no horizontal
   overflow.

Deliverables: the LiveView module file(s) + the route registrations.
