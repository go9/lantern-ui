# Eval task brief (prepended to every task prompt)

You are working in a fresh checkout of `go9/lantern-demo` (commit SHA in
`eval-pin.txt`), a Phoenix LiveView demo app. The `lantern_ui` Hex package is
already a dependency — check `mix.exs` for the pinned version.

## Hard constraints (violations fail the task)

1. **Flat lists only.** Grouped lists/tables — tinted collapsible group headers
   over row groups (`group_band`, or any hand-rolled equivalent) — are a banned
   design. Use a flat list or `data_table` plus a status column and filter chips.
2. **Use lantern components where one exists** (`button` with `size="icon"`
   for icon-only actions, `badge`, `card`, `table`/`data_table`, `modal` /
   `alert_dialog`, `toast_group` + `LanternUI.send_toast/3`, `form` inputs,
   `list_row`, `status_glyph`/`priority_glyph`, `progress` with `shape="ring"`,
   `tabs_list` with `variant="segmented"` for filter chips,
   `stat_card`/`stat_grid`, charts, `empty_state`, `skeleton`/`loading`,
   `breadcrumb`, `navlist`, `side_panel`/`inspector` with a dense
   `description_list`). The old `icon_button`, `segmented`, `progress_ring`,
   and `property_row` names are deprecated — use the replacements above.
   There is no bare `toast` or `stat` component. Do NOT hand-roll
   `<table>`, `<button>`, dialogs, or toasts from raw HTML/Tailwind when a
   lantern component covers it.
3. **Semantic color tokens only** (`text-foreground`, `text-muted-foreground`,
   `bg-card`, `border-base`, `text-danger`, …). No hardcoded palette colors
   (`red-500`, `slate-200`, …), no hex-in-class (`bg-[#fff]`), no arbitrary
   pixel values (`text-[11px]`, `w-[320px]`).
4. **Accessibility basics:** every form input has an associated `<label>`;
   icon-only buttons carry `aria-label`; live feedback uses flash or toast
   (not silent state changes).

## Working rules

- Data is static/in-memory for the task (module attributes or assigns).
  No migrations, no database, no new Hex deps.
- Keep the diff minimal: add one LiveView + route (names given in the task),
  touch shared files only to register the route.
- Verify with `mix compile` before finishing. Leave the server stopped.
