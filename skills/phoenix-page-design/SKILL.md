---
name: phoenix-page-design
description: Design consistent Phoenix LiveView pages with LanternUI. Covers page-shell titles and actions, tables and resource lists, record navigation, long-form inputs, secondary content, accessibility, and rendered-page verification.
license: MIT
metadata:
  source: https://github.com/go9/lantern-ui
---

# Phoenix page design with LanternUI

Consistency is product behavior. Reuse LanternUI components; do not rebuild shell, table, breadcrumb, filter, stat, empty state, button, badge, or modal in each app.

Application policy may override this guide. Record deliberate exception where reviewers can see it.

## 1. One title, one owner

`<.page_shell title=…>` owns the page title. The trail's last crumb is the current page, and the shell adds one visually hidden `h1` with the same text. Pass ancestors as `breadcrumbs`. Do not repeat the title in a content header or a data component, and do not add a visible title row. `<.page_header>` is deprecated and removed in 1.0; migrate it to `<.page_shell>`.

`<.page_shell layout="strip">` puts the trail, the notice and the actions on one row under the app bar (trail left, actions right). It is opt-in; the default `layout` is the 0.10 stacked topline. Inside `app_shell`, the workspace switcher goes in `<:sidebar_header>`, not in the top bar; on the icon rail it must collapse to an avatar.

Render one `<.page_shell>` per route, in the page's own template. Never render a second breadcrumb row beside it; the app layout supplies the frame only.

## 2. Page actions live with page identity

Pass create, import, export, history, and destructive page-level actions as `actions` descriptors on `<.page_shell>`. Each descriptor is a map with `id` and `label`. Ids must be unique within the bar (a duplicate raises). Optional keys: `icon`; `priority` (higher is promoted inline first); `enabled: false` (or `disabled: true`) with `disabled_reason` (shown in the More menu; prefer this to hiding an action); `promotable: false` (keeps it out of the inline row); `destructive: true`; the target keys `phx-click`, `phx-value-id` (defaults to the id), `phx-target`, `navigate`, `patch`, `href`; and `data-confirm`. The shell promotes as many enabled, promotable actions as the width allows and always lists every action in the More menu, so a narrow screen never loses one. Parent navigation belongs in the breadcrumb, not a “back” action.

A dismissible notice goes on the same row: pass `notice: %{id: stable_key, tone: "info", title: ..., body: ...}` with `tone` one of `neutral`, `info`, `success`, `warning`, `danger`, `promo`. The `id` is the condition key. With `on_dismiss`, the server owns dismissal: it receives `%{"id" => notice_id}` and sets `dismissed`, so it decides when the notice returns. Without `on_dismiss`, the hook remembers dismissal per id in localStorage, so a new id shows the notice again. The notice is announced with `role="status"`; it uses `role="alert"` only when it starts visible with the danger tone.

## 3. Pick navigation, filters, or tabs deliberately

- Different resources: separate routes.
- Presets over one dataset: data-table filter/tab slots.
- Workflow step or state view: tabs only when stable URL/state contract makes sense.

Do not add tabs as default grouping mechanism.

## 4. Choose data component

Use `data_table` when page needs sorting, search, filters, pagination, bulk actions, or several columns. Use `resource_list` for small resource indexes without table machinery.

Grouped tables and group headers are banned; use a flat list with a status column + filter chips. Whatever a group header said (status name, count) must stay visible per row or in the filter chips with counts.

For `data_table`, decide every capability explicitly:

| Capability | Enable when |
|---|---|
| sorting | user benefits from alternate meaningful order |
| bulk actions | one action applies to many rows |
| filters | rows have useful known buckets |
| search | user knows identifier or string to find |
| stats | summary changes decision before opening row |

Sortable fields must exist in backing query/schema allowlist. Disable checkboxes when no bulk action exists.

Use fill layout only when parent has bounded height and component should own body scrolling. `fill` scrolls the rows area (table body, list, or cards) internally and pins pagination; a long list without it pushes the pager below the fold.

## 5. Records get routes

Record identity links to its own detail route. Avoid inline expansion for primary record view: it has no shareable URL and destabilizes table layout. Keep inline disclosure for small secondary details only.

## 6. Long-form inputs use capable editor

Use app's established editor for code, JSON, SQL, prompts, and long bodies. Use simple input/textarea only when content needs no syntax, completion, diagnostics, or structured keyboard behavior. Editor selection belongs to application dependency policy, not LanternUI.

## 7. Secondary content

Keep required warnings visible. Put optional filters, explanations, and diagnostics in collapsible sections when they would otherwise bury primary content. Ensure collapsed content remains accessible and server tests reflect actual contract.

## 8. Visible states and accessibility

Cover relevant states:

- loading
- empty
- error
- focused/keyboard navigation
- responsive overflow
- light and dark themes

Use semantic tokens. Dense chrome: `text-meta` / `text-caption` / `text-mono-meta`, never `text-[Npx]`. Greys: `text-foreground`, `-soft`, `-softest`, `text-muted-foreground` — not `-softer` (deprecated alias) and not `text-gray-*`. Icon-only actions require accessible labels. Validate action overflow and mobile navigation, not only wide desktop state.

## 9. Rendered-page review

Inspect browser surface, not only HEEx diff. Check:

- one page shell: one breadcrumb row, one visually hidden `h1`, one action row
- actions remain reachable at narrow widths
- table/list reaches intended bounds
- sticky and scroll behavior works
- sorting/filter/search produce real result changes
- record links have stable routes
- empty/error/loading states communicate next action
- focus order and labels work
- no hardcoded product color bypasses theme

Use browser automation for geometry and state when layout can fail silently.
