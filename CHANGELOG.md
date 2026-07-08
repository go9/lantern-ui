# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and the project adheres to
[Semantic Versioning](https://semver.org).

## [Unreleased]

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
