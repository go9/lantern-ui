# Task 16 — Destructive flow with undo toast

Add an inbox-style list with delete + undo to the demo app. Static
in-memory data, no DB.

- Route: `live("/eval/inbox-undo", EvalUndoLive, :index)`
- Module: `LanternDemoWeb.EvalUndoLive`
- Data: 8 static items (`id`, `title`, `status` `:open | :in_progress |
  :done`, `updated` string).

Requirements:

1. A flat item list (one row per item, `list_row` preferred) with a per-row
   status column (glyph/chip) — no grouping — and a per-row delete action
   (icon-only `button` with `size="icon"` + `aria-label`, or a row action).
2. Deleting a row removes it immediately AND shows a toast
   (`toast_group` + `LanternUI.send_toast/3`) with an **Undo action that
   restores the deleted row in its original position**. The toast must stay
   visible long enough to click (at least ~8 seconds).
3. Deleting all rows shows an `empty_state` (with a "Restore all" or reset
   action that brings the items back).
4. A status filter (`tabs_list` with `variant="segmented"`: All / Open /
   In progress / Done) above the list; heading ("Inbox") + description line
   in the breadcrumb bar; semantic tokens only.

Deliverables: the LiveView module file(s) + the route registration.
