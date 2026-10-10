# Upgrade guide

## Unreleased table View control

`data_table` now presents column visibility, density, layout choices, and optional
saved views in one **View** popover. The existing `:view` slots,
`saved_view_event`, `active_saved_view`, and save/load event payloads remain
valid. Pages without saved-view assigns get no Saved views section. The public
`view_label` attr still overrides the button label; its default is now `"View"`.
Browser selectors targeting `-views`, `.lui-dt-views-trigger`, or the menu item
markup should target `-display` and its View popover instead.

Expanded tables now omit their overview while `expanded` is true and restore it
when the URL-owned state becomes false.

This guide covers the package released as `lantern_ui 0.9.0` through the current
`0.10.1` main line. Hex published `0.10.0` on 2026-10-08. Main is newer than
the latest Hex release: its 0.10.1 and Unreleased entries have not been
published. Check `mix hex.info lantern_ui` before choosing a dependency pin.

## 0.9.x to 0.10.x

### Breaking changes and required review

- **`page_header/1` now warns at compile time and will be removed in 1.0.** A
  consumer using `mix compile --warnings-as-errors` must migrate every call
  before upgrading. `mix lantern.lint` reports it as `deprecated_component`.
  The other 0.8.2 deprecations (`icon_button`, `segmented`, `progress_ring`,
  and `property_row`) still render and have no scheduled removal.

  Before:

  ```heex
  <.breadcrumb_bar>
    <.breadcrumb.breadcrumb>
      <:item navigate="/">Home</:item>
      <:item current>Orders</:item>
    </.breadcrumb.breadcrumb>
  </.breadcrumb_bar>
  <.page_header title={@title}>
    <:actions><.button navigate={@new_path}>New</.button></:actions>
  </.page_header>
  ```

  After (pass ancestors only; the shell adds the current title as the final
  breadcrumb):

  ```heex
  <.page_shell
    id="orders-page"
    title={@title}
    breadcrumbs={@ancestor_breadcrumbs}
    actions={[%{id: "new", label: "New", navigate: @new_path}]}
  >
    ...
  </.page_shell>
  ```

  A 0.9 breadcrumb list commonly included the current page with `path: nil`.
  Reusing that list unchanged duplicates the title in the new shell. Each crumb
  should instead carry `label` and one of `navigate`, `patch`, or `href` (`path`
  remains accepted as an `href` alias). `page_shell` renders one visually hidden
  `h1`; do not add a second page title beside it. The sign-in page is not a
  routed app page and should remain outside the shell.

- **`data_table` filter interaction and toolbar markup changed.** When filters
  are configured, the former dropdown is now a Zag `Filters & view` popover.
  Changes made inside it are staged until Apply; Reset affects panel controls,
  while Clear filters removes active filters. Search and quick-filter links
  still update immediately. Update browser tests or callers that assumed an
  immediate filter patch. The table toolbar also adds active filter chips,
  changes view controls, and exposes saved-view hooks. Custom CSS or JS tied to
  old table chrome markup (including `.lui-dt-viewtoggle`) needs a markup review.

- **Run the new lint rules.** `mix lantern.lint` adds `single_page_shell`,
  `hand_input`, and the `deprecated_component` report for `page_header`.
  `hand_input` reports raw `<input>`, `<textarea>`, and `<select>` controls;
  use `input/1`, `textarea/1`, and `select/1` where applicable. Hidden inputs are
  exempt. The rules inspect source text and can require an `allow_rules` entry or
  a `lantern-lint:ignore` comment for intentional legacy code. Lint failures do
  not mean the Elixir API failed to compile, but they can fail an app's lint CI.

- **Visible markup contracts changed on existing table chrome.** Table filter
  and view controls now use Popover/Zag markup, a labeled filter button, and
  additional chips and controls. Consumer selectors, snapshots, and JS queries
  that target component internals must be checked against the new markup.
  Public component attrs/events remain additive except for the `page_header`
  compile warning and the filter interaction change described above.

- **`use LanternUI` imports function components only.** Other public functions,
  including date-range helpers such as `parse_date/1`, remain available through
  their component module names and are not added to the consumer's local import
  namespace. Apps can keep helpers named `parse_date/1`, `format_date/1`, or
  similar without renaming them to avoid a LanternUI import conflict.

There is no new package dependency or raised runtime floor in the release diff:
`elixir: "~> 1.15"`, `phoenix_live_view: "~> 1.0"`, and `jason: "~> 1.0"` remain.
The library does not add a Flop dependency. The Zag chunks and ESM loading
requirements were introduced before 0.9.0; apps already using LanternUI's
on-demand Zag widgets should continue serving `priv/static/chunks/` and
`priv/static/zag/` and using an ESM build with splitting (or the standalone
bundle). The chart and table additions do not introduce a new consumer JS
package.

### Additive APIs and opt-in features

- `page_shell/1`, `action_bar/1`, and the `app_shell compact` attr are opt-in.
  Existing pages that do not call them keep their old HEEx structure.
- `alert/1` accepts `tone_slots`; tone-slot backgrounds are opt-in with
  `tone_slots` / `data-tone-slots`. The new `promo` badge/alert tone is new and
  uses the consumer-defined `--lantern-tone-promo-bg` and
  `--lantern-accent-text` tokens when present.
- New shell tokens: `--lui-topline-h`, `--lui-actionbar-h`, and
  `--lui-shell-h`.
- The select hook now dispatches `input` and `change` reliably when values
  change, including form-associated controls in overlays. This is a behavior
  correction for consumers that depended on the old missed change event.

## 0.10.1 (main only; not yet on Hex)

`page_shell layout="strip"` and the `app_shell` `:sidebar_header` slot are
opt-in. Without either, the 0.10.0 shell markup and behavior are retained.
Strip adds `--lui-strip-h`, folds ancestor crumbs into a menu at narrow widths,
and is hidden in print. A sidebar header remains visible on the collapsed icon
rail; reduce it to an avatar at that breakpoint.

## 0.11 (Unreleased on main): table chrome and media

Additive features include filter chips and staged filter/view popover, optional
URL-owned expanded tables, server-owned select-all-matching state, print
styles, `media_tile/1` and `media_tile_grid/1`, and optional stat-card tone and
sparkline. Existing data-table pages can still see the changed chrome and
filter interaction listed above without using the new optional attrs. The
table toolbar selector/markup change therefore needs an app review even when
the app does not opt into expanded tables or all-matching selection.

## 0.12 (Unreleased on main): charts and date ranges

Additive APIs include `time_series_chart/1`, `chart_card/1`, `chart_settings/1`,
chart select/hover events, reference lines, `date_range_popover/1`, `kbd/1`,
and `kbd_group/1`. The chart palette adds `--lantern-chart-1` through
`--lantern-chart-6`; promo styling may use `--lantern-accent-text`. Existing
charts do not gain selection events unless configured.

## Styling changes and how to keep the old look or adopt the new look

### Control sizing (0.12, unreleased)

Sized controls now share `--lui-control-h-sm`, `--lui-control-h-md`, and
`--lui-control-h-lg` tokens (28px, 32px, and 36px). Button sizes `xs`/`sm`
map to 28px, `md` to 32px, and `lg`/`xl` to 36px; related controls use
matching font, icon, radius, focus-ring, and gap tokens. Badges keep their
compact component-specific heights. The default metrics and focus outline
change for controls covered by the scale.

To restore their pre-scale metrics inside a subtree, add
`data-lui-control-scale="legacy"` to an ancestor. This opts that subtree out
of the control-scale rules; it does not roll back unrelated styling or markup
changes described in this guide. Remove the attribute to use the shared scale.

The shell changes above are opt-in. Tone-slot alert backgrounds are opt-in.
However, not every visual change is currently selectable. The new print media
rules change the existing `.lui-app` from its fixed-height, overflow-hidden
screen layout to `min-height: 0; height: auto; overflow: visible` for printing.
They hide the app bar/sidebar, table chrome, pagination and row actions; table
rows return to document flow with a repeating header and page-break rules.
These changes affect browser print output without a consumer source change.

At widths up to 40rem, existing data-table chrome now orders quick filters and
chips above search, hides the flex spacer, and puts the filter popover into a
full-width bottom sheet (`.lui-dt-chromerow`, `.lui-dt-search`,
`.lui-dt-spacer`, `.lui-dt-filterpanel`). The underlying filter control is also
new Popover/Zag markup on all widths. These can alter existing table pages
without a consumer source change. Desktop screen geometry for the existing
`.lui-app` root is otherwise unchanged by this diff.

The theme stylesheet adds chart tokens but does not redefine the legacy tone
background slots. `--lantern-accent-text` is a consumer-overridable fallback
used by the new promo tone. New chart colors and promo styling affect pages
only when those new APIs/tones are used. Inspect the app's own token overrides
and custom `.lui-*` selectors as part of upgrade review.

There is no global legacy-style switch for the existing `.lui-app` and
data-table styling changes described above. The control-scale opt-out applies
only to control metrics and focus styles; it does not restore the exact 0.9
appearance. Per-selector overrides can restore individual declarations but
are not a supported complete rollback. Apps choosing the new look can upgrade
to 0.10.x/main and opt in to `page_shell`, `compact`, `strip`, tone slots, and
other new components as needed.

## Deprecations and removal timeline

- `page_header/1`: deprecated in 0.10; migrate to `page_shell/1`. Removal is
  planned for 1.0.
- `icon_button/1`, `segmented/1`, `progress_ring/1`, and `property_row/1`:
  deprecated since 0.8.2. They still render; the current registry schedules no
  removal for them.

## Upgrade verification

For each consumer app, run:

```sh
mix deps.get
mix compile --warnings-as-errors
mix test
mix lantern.lint
```

Then inspect pages using `app_shell`, `data_table`, overlays, alerts, and
custom LanternUI selectors at desktop/mobile sizes in light and dark themes.
Apps with `page_header` will fail a warnings-as-errors compile until migrated.
