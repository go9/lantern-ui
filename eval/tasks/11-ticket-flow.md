# Task 11 — Ticket flow (list → detail → edit form with validation)

Add a three-page ticket flow to the demo app. Static in-memory data, no DB.

- Routes:
  - `live("/eval/flow/tickets", EvalTicketFlowLive, :index)`
  - `live("/eval/flow/tickets/:id", EvalTicketFlowDetailLive, :show)`
  - `live("/eval/flow/tickets/:id/edit", EvalTicketFlowEditLive, :edit)`
- Modules: `LanternDemoWeb.EvalTicketFlowLive`, `LanternDemoWeb.EvalTicketFlowDetailLive`,
  `LanternDemoWeb.EvalTicketFlowEditLive` (one module with three actions is fine
  if all three routes render).
- Data: 6 static tickets (`id` like `"FLW-1"`, `title`, `status`
  `:open | :in_progress | :done`, `priority` `:low | :medium | :high`,
  `updated` string, plus a one-paragraph `description`). Note: the status
  glyph has no `:open` value — map it to the closest glyph value.

Requirements:

1. **List** (`/eval/flow/tickets`): flat ticket list, one row per ticket, no
   grouping. Status filter chips above the list (`All`, `Open`, `In progress`,
   `Done`) using `tabs_list` with `variant="segmented"`. Each row shows a
   priority glyph, id, status glyph, title, updated date (prefer `list_row` +
   `status_glyph`/`priority_glyph`). Row click navigates to the detail page.
2. **Detail** (`/eval/flow/tickets/:id`): a `breadcrumb` with the ticket id
   plus `Edit` / `Delete` actions, a body card with the description, and a
   right-side inspector (`inspector` or `side_panel` + dense
   `description_list`) showing status, priority, updated. Unknown id renders
   `empty_state`. Delete removes the ticket (in-memory), flashes/toasts
   confirmation, and navigates back to the list.
3. **Edit** (`/eval/flow/tickets/:id/edit`): a `form` page (single card,
   cancel/save footer) editing title, status (`select`), priority (`select`).
   Blank title is invalid: show an inline validation error and refuse to save.
   Save toasts confirmation (`toast_group` + `LanternUI.send_toast/3`) and
   navigates to the detail page.
4. Title and page actions live in the breadcrumb bar / page header — not in
   ad-hoc headings with raw buttons.

Deliverables: the LiveView module file(s) + the route registrations.
