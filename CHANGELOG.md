# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and the project adheres to
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Fixed
- **Sheet dismissal now runs `on_close` JS commands (flicker #1357).** Close
  button, backdrop, Escape, and programmatic dismissal all execute the command.
- **The app shell breadcrumb bar now sits flush under the appbar.** Removed
  extra top padding above the sticky breadcrumb bar when it is the first element
  of the main column; the bar's own padding is retained.
- **A menu item can now be a link (flicker #1331).** `menu_item/1` renders a
  `<button>` unless given `navigate`, `patch` or `href`, in which case it
  renders a `<.link>`. Both keep `role="menuitem"` and `tabindex="-1"`, which is
  what the hooks' roving-focus model selects on, so the keyboard contract is
  unchanged. `disabled` on the link variant becomes `data-disabled` +
  `aria-disabled`, since anchors have no `disabled` attribute — the hooks' item
  query already skips both.

  `breadcrumb_bar/1` and `app_shell/1`'s action slots forward `navigate` /
  `patch` / `href` to the folded item. **This closes a silent failure:** a
  folded entry renders from the slot ATTRS, not the slot body, and the slot
  carried no destination — so an action whose inline button navigated became a
  menu item with no click target. It rendered, it was clickable, and nothing
  happened. Reported in flicker as "none of the items in the action dropdown are
  opening"; it affected every navigating entry past `:max_inline`.

### Added
- **Chat kit components (flicker #1358).** Added `avatar/1`, `message/1`, and
  follow-aware `message_scroller/1` with `message_scroller_item/1`, including
  token-only styling and the `LanternMessageScroller` hook.
- **`data_table/1` gains a `list` view (flicker #1202).** Third view alongside
  `table` and `cards`: a headerless index row for resource lists (projects,
  apps, databases). Opt-in via a `:list_item` slot (mirrors `:card`); the
  toolbar, search, filters, sort controls, and pagination stay. Each row
  places slot content left and optional `:row_action` trailing right without
  wrapping the row in an anchor so actions stay independently clickable.
  View toggle shows a list option only when `:list_item` is given. Callers
  without `:list_item` render as before.
- **`resource_list/1` + `resource_list_item/1` — simple resource index
  (flicker #1202).** Compound list for pages that show a handful of resources
  (projects, apps, databases, buckets) without data-table machinery. `layout`
  is `:list` (full-width rows, hairline separators between items) or `:grid`
  (auto-fill card grid). Optional `navigate`/`patch`/`href` makes the whole
  row the link hit target; trailing slot holds badges/meta. Host owns any
  list/grid toggle; no search, sort, pagination, or JS. No Fluxon equivalent.
- **`timeline/1` + `timeline_item/1` — vertical event sequence with a marker
  rail (flicker #1202).** Ordered list of steps: status dot (or optional
  icon), title, state label, preformatted `at` timestamp, and optional body.
  `status` paints the marker via `data-status` (`done`/`active`/`pending`/
  `danger`/`neutral`); the state `label` always renders as text so items stay
  legible in grayscale. Connector lines between markers hide on the last item
  via CSS `:last-child`. Pure presentational CSS, no JS. No Fluxon equivalent.
  Additive shapes: `:detail` slot wraps title/label/at in a native
  `<details>`/`<summary>` disclosure (`open` for initial state); 
  `label_position={:leading}` (set on `timeline/1`, overridable per item)
  places `at` in a fixed-width column left of the rail (`--lui-timeline-label-w`);
  `:marker` slot replaces the dot/icon (e.g. avatar). Unused options leave
  existing markup unchanged.
- **`breadcrumb_bar/1` gains an `:actions` slot (Linear action bar, flicker #1202).**
  Trail left, actions right-aligned on the same sticky chrome. The first
  `:max_inline` entries (default 2) render as quick buttons; everything after
  that folds into a More menu built on the existing APG `menu/1` (no new JS).
  The cap is fixed rather than width-based, because a responsive cap has to hide
  an inline button that is not in the menu, which makes that action unreachable
  at narrow widths. Without `:actions`, markup is unchanged. `app_shell/1`
  exposes the same region through optional `:breadcrumb_actions` so the slot
  chrome stays consistent with `breadcrumb_bar/1`.
- **`command/1` — command palette (⌘K dialog).** Modal combobox over a listbox,
  modelled on shadcn's Base UI `command` and built on the same dialog runtime as
  `modal/1` (`LanternUI.open_dialog/1` / `close_dialog/1`, focus trap, scroll
  lock, Escape/backdrop dismissal), plus a global Meta/Ctrl+`hotkey`. Parts:
  `command_group/1`, `command_item/1` (with `:icon` / `:description` /
  `:shortcut` slots), `command_empty/1`, `command_separator/1`,
  `command_shortcut/1`. Keyboard: ↑/↓/Home/End move the highlight, Enter
  activates, Escape closes; focus stays in the input and the highlight is
  published with `aria-activedescendant`.

  **Filtering is the consumer's.** The component renders exactly the items it is
  handed and pushes the query upward, so a LiveView can answer from a database
  or a search index — there are no client-side match knobs.

  **Safe to mount globally.** The `LanternCommand` hook pushes `on_search`
  (`%{"query" => query}`, debounced) and `on_select` (`%{"value" => value}`)
  itself, so the palette renders no `<form>` and carries no `phx-change` /
  `phx-submit`; event names default to the `command_*` namespace. A global
  component with a generic `phx-change="search"` makes a host app's own
  `element("form")` and `form[phx-change="search"]` test selectors ambiguous —
  this one cannot. An item that carries its own `phx-click` does not also push
  `on_select`, so per-item bindings are never double-fired. No Fluxon
  equivalent.
- **Skeleton variants + labeled status.** `skeleton/1` gains
  `variant="block|text|circle"` (rendered as `data-variant`) and an opt-in
  `label` that wraps the placeholder in a polite `role="status"` region with a
  visually hidden label. Bare `<.skeleton />` renders as before; reduced motion
  still disables the pulse. (flicker #1026)
- **`scroll_area/1` — themed scrollbar wrapper (flicker #1024).** Pure CSS over
  native overflow scrolling (no JS hook): `scrollbar-width`/`scrollbar-color`
  plus `::-webkit-scrollbar`, themed via `--lantern-scrollbar-thumb`/`-track`/
  `-size` with token fallbacks. `orientation` picks the scroll axis; `label`
  renders a focusable, keyboard-scrollable `role="region"` per the WAI-ARIA
  guidance for scrollable containers. No Fluxon equivalent.
- **`slider/1`** — single-thumb slider on the WAI-ARIA APG slider pattern
  (flicker #1023). `field`/`name`/`value` form surface like the other form
  controls, with the value in a hidden input so `phx-change`/submit behave
  natively. The `LanternSlider` hook owns pointer drag plus Arrow/Home/End/
  PageUp/PageDown stepping on the `role="slider"` thumb; `value_text` templates
  `aria-valuetext` (e.g. `"{value}%"`). No Fluxon equivalent.
- **`menu/1` + `menubar/1` — the WAI-ARIA APG menu-button and menubar
  patterns** (`menu_item`, `menu_separator`, `menubar_menu`; no Fluxon
  equivalent). Clean-room from the APG: the component owns the trigger button
  so `aria-haspopup`/`aria-expanded`/`aria-controls` are always wired, the
  popup is a trigger-labelled `role="menu"`, and the `LanternMenu` /
  `LanternMenubar` hooks run the full keyboard model on the shared overlay
  primitives — wrapping ArrowUp/Down, Home/End, roving tabindex, Escape back
  to the trigger, and horizontal ArrowLeft/Right across menubar entries that
  carries an open submenu along.
- **jsdom-backed hook tests (`npm test`).** `test/js/helpers/dom.mjs` mounts a
  hook from `priv/static/lantern_ui_hooks.js` against a real DOM with spies for
  `pushEvent`/`pushEventTo`, so client behaviour can be asserted directly
  instead of inferred from rendered HTML. `test/js/command_hook_test.mjs` covers
  the palette end to end: visibility across LiveView patches, event targeting,
  the keyboard model, the debounce, and the empty state. `mix test` and
  `npm test` are both run by CI. jsdom is a devDependency of a private
  `package.json`; the Hex package is unchanged and still ships a
  dependency-free hooks module.

### Fixed
- **`command`: search and selection were completely broken (stack overflow).**
  `LanternCommand` defined `push` twice. JavaScript keeps only the last
  definition in an object literal, so the `pushEvent`/`pushEventTo` router added
  for LiveComponent support was silently unreachable and the surviving method
  recursed into itself — every keystroke past the debounce threw
  `RangeError: Maximum call stack size exceeded`, and `on_select` never
  reached the server either. The router is now `pushTo/2` and the search push
  is `pushSearch/0`. A bundle-wide test fails on any duplicated hook method,
  since nothing else — not `node --check`, not the compiler, not a render
  test — reports one.

### Changed
- **Breadcrumb + page_header density cut ~3×.** Trail is 0.6875rem with 0.75rem
  icons and a ~1.35rem sticky bar; page title is 0.9375rem with minimal margins.
  `app_shell` main drops top padding when a breadcrumb strip is present. Saves
  vertical real estate without changing the goprint home/chevron structure.
- **Breadcrumb matches goprint chrome.** Leading optional `home` link (house
  icon), chevron separators by default (text `separator` still available),
  compact 0.8125rem labels. Sticky `breadcrumb_bar` no longer uses a negative
  top margin under `app_shell` (that was clipping titles). `page_header` title
  is body font at 1.125rem with normal casing — not brand-display caps.

### Changed
- **Breadcrumb chrome is layout-owned and compact.** `app_shell` gains a
  `:breadcrumb` slot that renders a sticky `lui-app-breadcrumb` region under
  the appbar (goprint-style density). New `breadcrumb_bar/1` exposes the same
  chrome for hosts that still own their outer shell; `page_header/1` is the
  matching compact title row. `<.breadcrumb>` now also accepts an `items`
  list of `%{label:, path:}` maps (product app chrome) in addition to the
  existing `:item` slots, and the trail defaults to a tighter separator/`sm`
  type size.

### Added
- **`meter`** (flicker #1025) — semantic `role="meter"` for scalar measurements
  within a known range (APG Meter pattern), distinct from `progress` (task
  completion). `aria-valuenow/min/max`, optional `aria-valuetext`, sizes, and
  optional `low`/`high`/`optimum` thresholds that color the fill via
  `data-state` (optimal/suboptimal/critical). Pure CSS, no JS. No Fluxon
  equivalent.
- **`nav_item` now nests (Fluxon-parity expandable nav) via a `:subnav` slot.**
  Pass a `:subnav` of nested `nav_item`s and the item becomes a toggle with a
  chevron over a `grid-rows`-based slide panel, opened/closed client-side with
  `JS.toggle_attribute` on `data-expanded` — the same expandable pattern Fluxon's
  `navlink` used, now built into `app_shell`'s `nav_item`. `expanded` sets the
  initial open state (e.g. `expanded={@in_this_section?}`); the subnav is hidden
  on the collapsed icon rail.

### Fixed
- **`app_shell/1` gets a real mobile navigation drawer.** Below 768px the
  sidebar used to flatten into a horizontal scrolling strip under the app bar,
  which is unusable once the nav has more than a handful of items — group labels
  were dropped and everything else had to be side-scrolled through a ~3-item
  window. It is now an off-canvas drawer behind a hamburger in the bar, over a
  scrim, with the full grouped nav and labels. It closes on scrim click, Escape,
  widening past the breakpoint, and on tapping a nav item — so a `navigate` link
  no longer leaves the drawer covering the page it just went to. The collapsed
  icon-rail rules are now scoped to `min-width: 769px`, so a persisted
  `data-collapsed` no longer strips the labels (or the `:subnav` chevrons) out
  of the mobile drawer.

- **`app_shell`: a full-height `data_table fill` no longer leaves a ~4rem dead
  band at the bottom.** `.lui-app-main`'s 4rem bottom gutter is sized for
  scrolling content; under a `.lui-datatable-fill` panel it sat *below* the table
  so the pinned pagination stopped ~64px short of the viewport. When main directly
  holds a fill table, the bottom gutter now matches the sides (1.5rem), so the
  table reaches the bottom with a balanced inset.

### Added
- **`accordion/1` + `accordion_item/1` — a headless-driven, WAI-ARIA APG
  accordion with the Fluxon 2.3.1 public API.** A Fluxon call migrates by
  changing only `use Fluxon` to `use LanternUI`: container `multiple`,
  `prevent_all_closed`, and `animation_duration` options; item `expanded` and
  `icon` options; required `header`/`panel` slots with slot classes; optional
  generated ids; and global attrs are supported. The namespaced
  `LanternAccordion` hook owns open/close and the APG keyboard model
  (`Enter`/`Space` toggle, `ArrowUp`/`ArrowDown`/`Home`/`End` between headers).
  Nested accordions are isolated; client state and focused headers survive
  generated-id LiveView patches/reconnects; the sole required-open trigger is
  exposed as `aria-disabled`. Panels stay in the DOM (`hidden`) so ARIA idrefs
  always resolve and collapsed content leaves the tab order + a11y tree. The
  chevron respects both `animation_duration` and `prefers-reduced-motion`. Passes the ARIA conformance
  gate. Implemented **clean-room** from the public Fluxon API facts and W3C
  WAI-ARIA APG; no commercial Fluxon or Chelekom expression copied (see
  `docs/upstreams/chelekom.md`, flicker #921).
- **`skeleton`** (flicker #1029) — a standalone CSS-only decorative loading
  placeholder with class/style/global attribute passthrough, token-driven
  color and radius, a visible default geometry, and reduced-motion-safe pulse.
- **`stat_card` / `stat_grid`** (flicker #1009) — standalone, responsive KPI
  summaries extracted from DataTable's existing overview stat renderer. Cards
  support label/value plus optional subtitle, host heroicon, navigation target,
  and merged classes; unlinked cards use non-interactive semantics and long
  values wrap safely. An empty slot-driven grid emits no wrapper. DataTable now
  delegates its `:stat` structure and appearance to the same renderer.

### Changed
- **`nav_item` icons accept host heroicons (`hero-*`), not just lantern's icon
  set.** `icon="chart-bar"` still renders a lantern inline SVG, but `icon="hero-home"`
  now renders as the host's CSS-mask span (the same convention Phoenix apps use for
  `<.icon name="hero-…">`) so an app can migrate its hand-rolled sidebar onto
  `app_shell` + `nav_group`/`nav_item` while keeping its own heroicons — lantern
  doesn't have to own every glyph (it has no `home`/`cog`). The mask span is
  constrained to lantern's icon size via a marker class that out-specifies the
  `.hero-*` size regardless of stylesheet order. Requires the host's heroicons CSS
  to be loaded (already true in the target apps).
- **`app_shell` main is now a bounded, independently-scrolling region on desktop
  — so `data_table fill` works inside it.** Previously `.lui-app` was
  `min-height: 100vh` (whole-page scroll) and `.lui-app-main` had no height/flex,
  so a `.lui-datatable-fill` child had no bounded parent to fill: full-height
  tables with pinned header/overview/pagination silently didn't fill. Now, at
  `min-width: 769px`, `.lui-app` is viewport-height with `overflow: hidden` and
  `.lui-app-main` is a `box-sizing: border-box` flex column of height
  `calc(100vh - appbar)` with `overflow-y: auto`. Normal pages scroll inside main
  exactly as before (the bar is already `position: fixed`); a fill table now fills
  the height and pins its chrome. Mobile (≤768px, sidebar becomes a strip) keeps
  natural page scroll. This unblocks migrating apps off hand-rolled shells onto
  `app_shell` without losing full-height tables.

### Fixed
- **`data_table fill` now pins the column header.** In fill mode the table body
  is the scroll region, but nothing in `lantern_ui.css` was sticky — so on any
  list taller than the viewport the `<thead>` scrolled away with the rows and
  you lost the column labels (and the sort controls) exactly when a long list
  makes them matter most. The header/chrome/overview/pagination already stayed
  pinned; only the column header was lost. `.lui-th` is now `position: sticky`
  inside a fill-mode scroll region. Because `.lui-table` uses
  `border-collapse: collapse` the border belongs to the table rather than the
  cell — a sticky `th` therefore drops its `border-bottom` on scroll — so the
  hairline is redrawn as an inset shadow. Scoped to fill mode; default tables
  are unchanged.
- **`lantern_ui_compat.css` now defines the `--lantern-*` component tokens.**
  The file's docs said to import it *instead of* `lantern_ui_theme.css` and that
  it "themes LanternUI for free", but it only defined the Fluxon host tokens —
  never the `--lantern-*` values the components actually read. Following the
  documented path left every `--lantern-*` undefined, so components rendered
  with square corners (no `--lantern-radius`), no surfaces/backgrounds (no
  `--lantern-surface`), and broken dropdowns. Every migrating app hit this and
  had to hand-vendor the bridge (flicker did; enventory/skusync/goprint/foodfeed
  forgot and shipped broken styling). compat.css now carries the bridge, so
  `import compat` alone themes the components. Backward compatible — an app's own
  `--lantern-*` overrides declared after the import still win.

### Changed
- **`use LanternUI, only:/except:`** now accepts Fluxon-style `function: arity`
  pairs in addition to component-key atoms — so a host can drop a single
  colliding function (`use LanternUI, except: [icon: 1]`) instead of a whole
  module. Enables clean drop-in over apps that already define `icon`, etc.

### Added
- **`alert_dialog`** (flicker #1028) — semantic destructive confirmation composed
  on the existing `LanternModal` runtime. Requires title, description, cancel,
  and action slots; wires `alertdialog` label/description idrefs, focuses the
  cancel control first, ignores outside clicks, and retains Escape dismissal,
  focus trapping, and trigger-focus restoration.
- **`progress`** (flicker) — determinate + indeterminate progress bar / meter (sizes, semantic colors, optional shimmer), pure CSS.
- **`color_input`** — native color picker (Fluxon parity): a real
  `<input type="color">` styled as a swatch plus a read-only hex readout,
  no JS. Standard field chrome (label/sublabel/description/help/errors),
  FormField-aware, `size` xs–xl. Accepts the `name`/`value`/`label` surface
  the playground theme editor already uses.
- **`autocomplete`** (flicker #892, #1027) — static and async typeahead (Fluxon
  2.3.1 public API parity): local contains/starts-with/exact matching or debounced
  LiveView `on_search`, loading and custom empty states, nested option groups,
  rich option/header/footer/affix slots, clear/open-on-focus modes, and
  active-descendant keyboard/ARIA behavior. FormField-aware over a hidden value
  input; selected labels and focus survive result patches. `LanternAutocomplete`
  hook.

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
