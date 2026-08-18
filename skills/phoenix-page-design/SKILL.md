---
name: phoenix-page-design
description: Design consistent Phoenix LiveView pages with LanternUI. Covers breadcrumb-owned titles and actions, tables and resource lists, record navigation, long-form inputs, secondary content, accessibility, and rendered-page verification.
license: MIT
metadata:
  source: https://github.com/go9/lantern-ui
---

# Phoenix page design with LanternUI

Consistency is product behavior. Reuse LanternUI components; do not rebuild shell, table, breadcrumb, filter, stat, empty state, button, badge, or modal in each app.

Application policy may override this guide. Record deliberate exception where reviewers can see it.

## 1. One title, one owner

Prefer last breadcrumb as page title. Avoid repeating same title in page wrapper, content header, and data component. Detail pages may need visible heading when breadcrumb alone lacks context; do not duplicate labels without purpose.

Render breadcrumbs once, normally in layout.

## 2. Page actions live with page identity

Put create, import, export, history, and destructive page-level actions in breadcrumb action area. Parent navigation belongs in breadcrumb, not a “back” action.

When action can fold into overflow menu, put `navigate`, `patch`, `href`, `phx-click`, and confirmation attrs on action slot. Overflow renderer may use slot attrs without rendering slot body.

## 3. Pick navigation, filters, or tabs deliberately

- Different resources: separate routes.
- Presets over one dataset: data-table filter/tab slots.
- Workflow step or state view: tabs only when stable URL/state contract makes sense.

Do not add tabs as default grouping mechanism.

## 4. Choose data component

Use `data_table` when page needs sorting, search, filters, pagination, bulk actions, or several columns. Use `resource_list` for small resource indexes without table machinery.

For `data_table`, decide every capability explicitly:

| Capability | Enable when |
|---|---|
| sorting | user benefits from alternate meaningful order |
| bulk actions | one action applies to many rows |
| filters | rows have useful known buckets |
| search | user knows identifier or string to find |
| stats | summary changes decision before opening row |

Sortable fields must exist in backing query/schema allowlist. Disable checkboxes when no bulk action exists.

Use fill layout only when parent has bounded height and component should own body scrolling.

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

Use semantic tokens. Icon-only actions require accessible labels. Validate action overflow and mobile navigation, not only wide desktop state.

## 9. Rendered-page review

Inspect browser surface, not only HEEx diff. Check:

- one page identity/title
- one breadcrumb nav
- actions remain reachable at narrow widths
- table/list reaches intended bounds
- sticky and scroll behavior works
- sorting/filter/search produce real result changes
- record links have stable routes
- empty/error/loading states communicate next action
- focus order and labels work
- no hardcoded product color bypasses theme

Use browser automation for geometry and state when layout can fail silently.
