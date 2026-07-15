# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and the project adheres to
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Added
- **`navlist` / `navheading` / `navlink`** (flicker #890) — standalone
  structured nav (Fluxon parity): navlist with optional heading, navlink that
  renders a link (navigate/patch/href) or button, active state + optional icon.
- **`loading`** (flicker #891) — spinner (Fluxon parity): variants
  `ring` / `dots-bounce` / `dots-fade` / `dots-scale`, sizes xs–xl,
  `role="status"` + sr-only label, reduced-motion aware.

### Added
- **`sheet`** (flicker #883) — slide-over/drawer panel mirroring Fluxon's
  `sheet/1`. Shares the dialog runtime with `modal` (`open_dialog`/`close_dialog`),
  slides from `left`/`right`/`top`/`bottom` with enter+exit animation, focus
  trap, scroll lock, Escape/backdrop dismiss, optional header title + sticky
  footer slot. `LanternSheet` hook; `[hidden]` display guard.

### Changed
- **Fluxon token compatibility** (flicker #882): every `--lantern-*` color now
  chains through the matching Fluxon semantic token (`--primary`,
  `--foreground`, `--foreground-soft/softer`, `--foreground-primary`,
  `--background-base/accent`, `--surface`, `--border-base`,
  `--danger/success/warning/info`) before its hard fallback. A flicker/Fluxon
  theme — defined in exactly those names — now flows straight into lantern-ui
  with no bridge and no component changes; standalone keeps the shadcn
  monochrome look via the fallbacks. Non-destructive: only the theme file
  gained the mapping layer. Under a theme, `--lantern-primary`/`--lantern-accent`
  both pick up the brand `--primary` (matches flicker's single-brand look).

### Changed
- **`toast_group` placement** now supports all six positions — `top-left`,
  `top-center`, `top-right`, `bottom-left`, `bottom-center`, `bottom-right`
  (was three). Toasts enter from the nearest screen edge (slide down from the
  top, up from the bottom) and the newest stays closest to the edge.

## [0.7.0] - 2026-07-11

### Added
- **data_table closure primitives** (flicker #874) — five standalone components:
  - `badge` — status pill (Fluxon-API: color × variant × size)
  - `table` / `table_head` / `table_body` / `table_row` — presentational table
    family (Fluxon-API), the substrate the upcoming `data_table` composes
  - `tabs` / `tabs_list` / `tabs_panel` — segmented or underline tabs
    (Fluxon-API), server-driven; tabs given `patch`/`navigate` render as links
    so tab state can live in the URL
  - `select` — FormField-aware select (Fluxon-API): rich listbox path
    (`LanternSelect` hook — positioning, keyboard nav, type-ahead) over a
    hidden input, plus a `native` fallback; `searchable`/`multiple` accepted
    for compatibility, implemented later
  - `pagination` — pager + page-size control (lantern extension; replaces
    flop_phoenix's pager). Duck-typed against `Flop.Meta`'s shape, so no flop
    dependency; all navigation is patch-based
- `Form.translate_error/1` is now public.
- **`data_table`** (flicker #867) — the admin table that replaces the per-app
  `admin_table` copies. API mirrors the enventory/skusync baseline (col/
  bulk_action/row_action/toolbar/header_action/empty slots, selected_ids,
  toggle_select / select_all_page / clear_selection events). Flop.Meta
  duck-typed (no flop dep); sorting + pagination are patch navigation that
  preserves existing query params (filters); bulk bar, selected-row styling,
  EmptyState fallback, composed on the new primitives.
- **`data_table` chrome** (flicker #868): collapsible stat-card overview strip
  (`:stat` slots, persisted per-id via the new generic `LanternCollapse`
  hook), patch-link tabs with count badges mapping to Flop filter presets
  (`:tab` slots, active tab detected from current filters), built-in debounced
  search (`search_field`) and typed filter selects (`:filter` slots) that
  build Flop filter params client-side and patch the URL — zero page-level
  handlers (`LanternTableChrome` hook rides LiveView's own patch navigation) —
  and a table ⇄ cards view toggle (`:card` slot + `view` attr).
- **`data_table` toolbar rework** (review): filters moved into a popover
  ("Filters" button with active-count badge + clear-filters), the toolbar is
  one right-aligned row (filters → search → actions), the bulk bar gains
  "Select all N" (emits `select_all_matching` for whole-result-set selection),
  and collapse hooks re-apply their state after LiveView patches (the
  overview/sidebar collapse no longer resets on re-render).
- **`data_table` title section**: `subtitle` attr and `info_modal_id` — an ⓘ
  button beside the title that opens the given modal via
  `LanternUI.open_dialog` (baseline `admin_table` parity).
- **`data_table` card shell + chrome row** (design review): the table renders
  as a contained card (header with title/info, hairline sections, footer
  pagination); tabs ("quick filters") share one chrome row with everything
  else — left-to-right: tabs · quick actions (`toolbar` slot) · search · view
  toggle · settings popover (rightmost). `:filter` slots gain `type`:
  `:select` (default), `:text`, and `:range` (min/max → `>=`/`<=` Flop
  filters).
- **`select`: `multiple` + `searchable` implemented** (Fluxon parity): multi
  keeps the listbox open, maintains one hidden `name[]` input per pick, shows
  a count label, honors `max`; search filters options client-side
  (`search_threshold` auto-enables at N options; `search_input_placeholder` /
  `search_no_results_text` honored). `data_table` `:filter` slots accept
  `multiple`/`searchable` and emit Flop `in` filters with `value[]` lists.

## [0.6.0] - 2026-07-08

### Changed
- **`Layout` reshaped into an app shell** (breaking): `sidebar_layout` →
  `app_shell` — a full-width top bar (`:brand` corner + `:header` inline
  context + `:actions` right) over a fixed collapsible left sidebar, with the
  collapse control at the sidebar foot. Mirrors a typical product app layout so
  a Fluxon layout can migrate onto it. `nav_group`/`nav_item` unchanged.

### Added
- `--lantern-font-brand` token (brand/heading face; defaults to the body font,
  override to e.g. Space Grotesk).
- Icons: cursor-arrow-rays, sparkles, pencil-square, calendar, check-circle,
  window, chevron-up-down, inbox, presentation-chart-line, arrow-trending-up,
  view-columns.

## [0.5.0] - 2026-07-08

### Added
- **App-shell layout** (`LanternUI.Components.Layout`) — the core Fluxon-style
  navigation chrome: `sidebar_layout` (fixed sidebar + main + optional topbar),
  `sidebar_header` (logo corner), `sidebar_nav` / `nav_group` / `nav_item`
  (grouped nav with icons + active state), and `sidebar_toggle` (collapse to an
  icon rail, persisted per-id in localStorage via the new `LanternSidebar`
  hook). Collapses to a horizontal strip on narrow viewports.
- Icons: `bars-3`, `squares-2x2`, `chart-bar`, `circle-stack`, `cloud`.

## [0.4.1] - 2026-07-08

### Changed
- **CSS split into two artifacts** (per the embeddable-core architecture):
  `lantern_ui.css` is now the always-required component styles, and the
  optional default theme (tokens, light/dark, density) moved to
  `lantern_ui_theme.css`. Standalone hosts import both; Fluxon/token-bearing
  hosts import only the component styles and bridge `--lantern-*` onto their
  own tokens (example in the file header). Migration: add
  `lantern_ui_theme.css` next to your existing `lantern_ui.css` import.

## [0.4.0] - 2026-07-08

### Added
- **Modal** (`modal/1` + `LanternUI.open_dialog/1,2` / `close_dialog/1,2`) —
  Fluxon-compatible dialog on the shared overlay runtime: focus trap,
  Escape/outside dismissal, `prevent_closing`, placement, token-driven fade.
- **Dropdown menu** (`dropdown/1` + `dropdown_header/separator/link/button/custom`) —
  Fluxon-compatible family with WAI-ARIA menu keyboard navigation.
- **Checkbox** (`checkbox/1`) — Fluxon-compatible, `FormField`-aware, hidden
  unchecked-value input, label/description/error states.
- **Breadcrumb** (`breadcrumb/1`) — path navigation for file/tree UIs
  (lantern-ui extension).
- **Empty state** (`empty_state/1`) — quiet zero states with icon, title,
  description, and action slot (lantern-ui extension).
- Icons: `folder`, `folder-open`, `document`, `arrow-up-tray`,
  `arrow-down-tray`, `arrow-path`, `trash`.
- Hooks: `LanternModal`, `LanternDropdown`.

## [0.3.3] - 2026-07-08

### Fixed
- Picker panel now carries the popover chrome itself (background, border,
  shadow) — the time pane and footer no longer float transparent below the
  calendar's box.
- Open panels follow their anchor during scroll/resize instead of staying
  pinned to the viewport.
- The panel time pane no longer shows its own `∅` clear glyph (the footer's
  Clear covers it).

### Added
- Explicit `.light` token block, so a subtree can force light mode under a
  dark OS (mirror of `.dark`).

## [0.3.2] - 2026-07-08

### Added
- `date_time_picker` panel now includes a **time pane** — a non-submitting
  segmented time field under the calendar, kept in two-way sync with the
  trigger (new `lantern:set-time` event on the field hook). Picking a time
  with no date yet defaults the date to today.

### Fixed
- Segmented field no longer wraps onto multiple lines in narrow hosts
  (explicit `flex-wrap: nowrap` + overflow guards on `.lui-dtf`).

## [0.3.1] - 2026-07-07

### Fixed
- `date_picker` / `date_time_picker` / `time_picker` now accept a `form`
  attribute and forward it to the hidden value input, so the pickers work as
  editors rendered outside their `<form>` element (e.g. lantern's table cell
  editors, which submit via `form="..."`).

## [0.3.0] - 2026-07-07

### Added
- **Component system foundation**: full design-token set in
  `priv/static/lantern_ui.css` (semantic colors, shadcn-density scale — 32px
  controls / 13px text — monochrome primary + coral accent, light/dark,
  `data-lantern-density` modes), the `use LanternUI` importer with
  Fluxon-compatible `:only`/`:except`, `LanternUI.Class` helpers, and a
  dependency-free JS runtime core (`position`, `trapFocus`, `onDismiss`,
  `LanternOverlay`).
- **Primitives** (Fluxon-compatible API, `lui-*` namespaced CSS, zero build
  step): `button`/`button_group`, `icon` (curated inline Heroicons-outline
  set), `form.input`/`label`/`error`, `calendar` (WAI-ARIA month grid +
  `LanternCalendar` hook with the full APG keyboard model), and the segmented
  `datetime_field` (typeable/steppable segments to millisecond precision,
  hidden canonical input, clear-to-null) with the `LanternDatetimeField` hook.
- **Pickers**: `date_picker`, `date_time_picker` (calendar popover with
  Today/Now · Clear · Done), and `time_picker` (segments-only). Canonical
  values `YYYY-MM-DD` / `HH:MM:SS.mmm` / `YYYY-MM-DDTHH:MM:SS.mmm`; empty =
  null. Accepts Date/Time/NaiveDateTime/DateTime structs or strings.

### Fixed
- `line_chart` crosshair tooltip: size the box to the longest label + value so
  long series names (e.g. Kubernetes pod names) no longer collide with the
  right-aligned value.

### Added
- `LanternUI.Charts.line_chart/1` — multi-series time-series line chart with a
  legend and a shared crosshair tooltip (`LineHover` hook). Accepts
  `%{label, color, points: [{datetime, number}]}` series; 0-based y axis; built
  for resource/monitoring metrics.
- Initial chart set as native Phoenix LiveView function components under
  `LanternUI.Charts`: `area_chart/1`, `sparkline/1`, `bar_chart/1`.
- `LanternUI.Charts.Geometry` — pure scaling, "nice" tick, and SVG path helpers.
- `ChartHover` LiveView JS hook (`priv/static/lantern_ui_hooks.js`) for the
  crosshair + tooltip on `area_chart`.
- Optional standalone theme (`priv/static/lantern_ui.css`); components otherwise
  inherit host CSS variables (Fluxon-compatible).

[Unreleased]: https://github.com/go9/lantern-ui
[0.3.0]: https://github.com/go9/lantern-ui/releases/tag/v0.3.0
