---
name: lantern-migration
description: Migrate a Phoenix LiveView application onto LanternUI. Covers dependency wiring, component replacement, import collisions, app shell and navigation, tables, breadcrumbs, tokens, slots, and regression checks. Use when replacing hand-built or Fluxon UI with LanternUI.
license: MIT
metadata:
  source: https://github.com/go9/lantern-ui
---

# Migrating an application to LanternUI

This skill owns consumer-side migration. Use `lantern-ui-components` when library needs a new reusable component.

Prime directive: reuse a LanternUI component when one exists. Keep genuinely app-specific UI local.

## 1. Wire dependency

Prefer released Hex version. When testing unreleased main, use reproducible full SHA:

```elixir
{:lantern_ui, git: "https://github.com/go9/lantern-ui.git", ref: "<40-char-sha>"}
```

If dependency is pinned in `mix.exs`, update pin there before `mix deps.get`; editing `mix.lock` alone is temporary.

Import from application web module:

```elixir
use LanternUI, except: [icon: 1]
```

Use function-and-arity exclusions only for real local collisions. Leave comment naming local owner and removal condition.

## 2. Replace concepts, not markup

| Existing UI | LanternUI |
|---|---|
| bespoke shell/sidebar | `app_shell`, `nav_group`, `nav_item` |
| raw table/rows | `data_table` or `resource_list` |
| hand-built breadcrumb | `breadcrumb_bar`, rendered once by layout |
| metric cards | `stat_card`, `stat_grid`, or data-table stats |
| empty/loading state | `empty_state`, `loading`, `skeleton` |
| hardcoded colors | semantic Lantern tokens |
| reusable missing concept | add component to LanternUI first |

Read component attrs and slots before use. Named-slot components may render nothing when children are passed as ordinary `inner_block`.

## 3. Shell and navigation

Use `app_shell` with `nav_group` and `nav_item`. Nested navigation belongs in `:subnav`, with initial `expanded` state derived from current route. Verify every child route remains reachable in expanded and collapsed shells.

In flex columns, an `overflow-*` child may shrink unexpectedly. Add `shrink-0` to fixed chrome such as breadcrumb bars; keep scroll ownership intentional.

## 4. Tables and records

Use `data_table` for searchable/filterable/sortable/paginated data. Use `resource_list` for small resource collections without table machinery.

Decide explicitly:

- sort fields and backing schema allowlist
- search field
- filters
- bulk actions and checkbox visibility
- table/list/card view

Record identity links to its own route. Do not use inline row expansion as substitute for detail page.

## 5. Breadcrumb ownership

Render breadcrumbs exactly once, normally in application layout. Page-level actions belong in breadcrumb action slot. When actions fold into overflow menu, destination and confirmation attrs must be slot attrs because fallback renderer may not render inner body.

## 6. Tokens

Use Lantern semantic tokens and `lui-*` component styles. Do not bulk-delete legacy variables: prove zero references in templates, CSS, and build configuration first. Light and dark token values may intentionally differ.

## 7. Missing-component loop

1. Search LanternUI components and registry.
2. If concept is reusable, add it to LanternUI with tests and release note.
3. Consume released version or pinned commit.
4. If concept is app-specific, keep it local and state why.

No temporary reusable hand-roll.

## 8. Verify real surface

Run application tests plus rendered-page checks. Confirm:

- one breadcrumb source
- all navigation destinations reachable
- no missing named-slot content
- tables fit intended viewport and pagination remains reachable
- overflow actions still work
- semantic tokens in light and dark themes
- no removed component options remain
- keyboard, focus, labels, and ARIA state work

Run library tests when library changes and application tests when consumer changes. Keep library and consumer changes in separate commits or PRs.
