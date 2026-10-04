# Task 14 — Command palette + keyboard-navigable list

Add a searchable command palette over a keyboard-navigable list to the demo
app. Static in-memory data, no DB.

- Route: `live("/eval/palette", EvalPaletteLive, :index)`
- Module: `LanternDemoWeb.EvalPaletteLive`
- Data: 10 static commands (`value`, `title`, `hint`/`shortcut` text, target
  `#` anchor or path string) grouped into two `command_group`s
  ("Navigate", "Actions"), plus 8 static record rows (`id`, `title`, `status`
  `:open | :in_progress | :done`).

Requirements:

1. A lantern `command` palette (with `command_group`, `command_item`,
   `command_empty`, `command_shortcut` where they fit): typing filters the
   items, an empty query state shows when nothing matches, and selecting an
   item navigates or toasts. A visible hint (`⌘K` kbd text + button) opens
   the palette; Escape closes it.
2. Below the palette hint, a flat record list where **arrow keys move the
   active row** (visible highlight on the active row) and **Enter opens the
   active record** (navigate to a stub `#`/detail anchor — a flash/toast
   confirming which record was opened is fine). The list also works with a
   mouse (row click opens).
3. Status renders as a per-row status column (glyph/chip) — no grouping.
   Icon-only buttons carry `aria-label`; the palette input has a label.
4. Heading ("Command palette") + description line; semantic tokens only.

Deliverables: the LiveView module file(s) + the route registration.
