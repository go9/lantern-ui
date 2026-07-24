# LanternUI

Native Phoenix LiveView UI components — server-rendered SVG charts (and more over
time), themeable via CSS variables. **No React, no JavaScript charting library.**

Part of the lantern family: [`lantern`](https://github.com/go9/lantern) is an
embeddable Postgres table viewer; `lantern_ui` is the UI component set.

## What's here

- `LanternUI.Charts.area_chart/1` — time-series area + line with an interactive
  crosshair/tooltip.
- `LanternUI.Charts.sparkline/1` — compact trend, no axes.
- `LanternUI.Charts.bar_chart/1` — categorical bars.
- `LanternUI.Charts.line_chart/1` — multi-series time-series lines with a legend
  and a shared crosshair tooltip (built for resource/monitoring metrics).
- `LanternUI.Components.Accordion.accordion/1` + `accordion_item/1` — a
  Fluxon-compatible, WAI-ARIA accordion with single/multiple-open behavior.
- `LanternUI.Charts.Geometry` — pure scaling / "nice" ticks / SVG path helpers.

Geometry is computed in Elixir, so charts re-render through normal LiveView
assigns. The only client JS is one small hook (`ChartHover`) for the area chart's
tooltip.

## Installation

From Hex (once published):

```elixir
def deps do
  [{:lantern_ui, "~> 0.1"}]
end
```

Or from git while iterating:

```elixir
{:lantern_ui, "~> 0.3"}
# or track main:
# {:lantern_ui, github: "go9/lantern-ui"}
```

## Usage

```heex
<LanternUI.Charts.area_chart
  id="price-history"
  series={[%{date: "2024-01-01", value: 24.5}, %{date: "2024-02-01", value: 27.1}]}
  value_format={:currency}
  height={250}
/>

<LanternUI.Charts.sparkline id="trend" series={[3, 5, 4, 6, 8, 7, 9]} />

<LanternUI.Charts.bar_chart
  id="sales"
  series={[%{label: "Q1", value: 42}, %{label: "Q2", value: 31}]}
/>

<LanternUI.Charts.line_chart
  id="pod-cpu"
  series={[
    %{label: "web-1", color: "var(--color-primary)",
      points: [{~U[2024-11-20 14:00:00Z], 0.25}, {~U[2024-11-20 14:05:00Z], 0.31}]},
    %{label: "web-2", points: [{~U[2024-11-20 14:00:00Z], 0.18}, {~U[2024-11-20 14:05:00Z], 0.22}]}
  ]}
  value_format={&"#{&1} cores"}
/>
```

`line_chart` `series`: a list of `%{label, color, points: [{datetime, number}]}`
(`color` optional; `points` accept `{datetime, value}` tuples or `%{time, value}`
maps; datetime = `DateTime`/`NaiveDateTime`/`Date`/ISO-8601 string).

`area_chart` `series`: a list of `%{date: iso8601 | Date, value: number}`.

### Accordion

`accordion/1` and `accordion_item/1` mirror Fluxon 2.3.1, so an existing call can
migrate by changing only `use Fluxon` to `use LanternUI`:

```heex
<.accordion id="faq" prevent_all_closed animation_duration={300}>
  <.accordion_item id="shipping" expanded>
    <:header>Where do you ship?</:header>
    <:panel>Worldwide.</:panel>
  </.accordion_item>
  <.accordion_item id="returns" icon={false}>
    <:header class="font-semibold">What is the return window?</:header>
    <:panel class="prose">Thirty days.</:panel>
  </.accordion_item>
</.accordion>
```

Both ids are optional and generated when omitted. `multiple` allows several
panels open; `prevent_all_closed` keeps one open. The panel remains in the DOM
and is hidden when collapsed so ARIA relationships stay valid. The indicator
uses `animation_duration`; `prefers-reduced-motion: reduce` disables its
transition.

### Destructive confirmations

Use `alert_dialog/1` instead of hand-building destructive modal semantics. Its
four slots are required; cancel is focused first, backdrop clicks are ignored,
and Escape closes while restoring focus to the trigger.

```heex
<.button phx-click={LanternUI.open_dialog("delete-project")}>Delete…</.button>

<.alert_dialog id="delete-project">
  <:title>Delete this project?</:title>
  <:description>This permanently deletes the project and its data.</:description>
  <:cancel>
    <.button phx-click={LanternUI.close_dialog("delete-project")}>Cancel</.button>
  </:cancel>
  <:action>
    <.button color="danger" phx-click="delete-project">Delete project</.button>
  </:action>
</.alert_dialog>
```

The application owns action and cancel events. Use an alert dialog only for an
important, usually irreversible confirmation, not for informational content.

## JS hooks (mandatory for Accordion and interactive components)

**Register the complete `LanternHooks` bundle whenever Accordion is used.**
Without `LanternAccordion`, headers do not toggle, keyboard navigation does not
run, and `prevent_all_closed` cannot be enforced. Interactive components,
including `alert_dialog` through `LanternModal`, ship their hooks in the same
bundle. `area_chart` uses `ChartHover`, and `line_chart` uses `LineHover`; the
single import below registers all shipped hooks. In `assets/js/app.js`:

```js
import LanternHooks from "../../deps/lantern_ui/priv/static/lantern_ui_hooks.js"

let Hooks = { ...LanternHooks /* , ...yourOtherHooks */ }
let liveSocket = new LiveSocket("/live", Socket, { params: {/* ... */}, hooks: Hooks })
```

`sparkline` and `bar_chart` need no JavaScript. Accordion always requires the
hook bundle above.

## Autocomplete

`autocomplete` filters local options by default and keeps the selected value in a
normal hidden form input:

```heex
<.autocomplete field={@form[:country]} options={@countries} clearable />
```

For remote data, the LiveView owns the result list. Set `on_search`; the hook
pushes `%{"query" => query}` after `search_threshold` and `debounce`, displays its
loading state, and stops loading when the patched options arrive:

```heex
<.autocomplete
  field={@form[:user_id]}
  options={@user_results}
  on_search="search_users"
  search_threshold={2}
  debounce={250}
  open_on_focus
  clearable
>
  <:option :let={{name, id}}>
    <strong>{name}</strong> <small>#{id}</small>
  </:option>
  <:empty_state>No matching users</:empty_state>
</.autocomplete>
```

Options may be nested labelled groups. A Fluxon-style `{label, children}` is a
group when `children` is a non-empty tuple list. Use
`{:group, label, children}` for an empty group or scalar children; this explicit
form preserves existing `{label, list_value}` options without ambiguity.
`inner_prefix`, `inner_suffix`, `outer_prefix`, `outer_suffix`, `header`, and
`footer` slots customize the surrounding states without moving search or
selection ownership into LanternUI.

The `animation`, `animation_enter`, and `animation_leave` attrs are accepted as
Fluxon compatibility no-ops. Like Lantern's modal, autocomplete motion is
controlled by the bundled CSS and duration tokens.

## Theming

Components read colors from CSS variables with chained fallbacks:

| Purpose | Variable chain |
|---|---|
| accent | `--lantern-accent` → `--color-primary-500` → `#3b82f6` |
| text | `--lantern-fg` → `--foreground` → `#111827` |
| muted text | `--lantern-fg-muted` → `--foreground-softer` → `#6b7280` |
| surface (tooltip) | `--lantern-surface` → `--background-base` → `#ffffff` |

Two stylesheets ship in `priv/static`:

- **`lantern_ui.css` — component styles, always import it** when using any
  `lui-*` component (button, pickers, modal, dropdown, …). Charts don't need it.
- **`lantern_ui_theme.css` — the optional default theme** (tokens, light/dark,
  density modes).

Pick per host:

- **Standalone / public?** Import both:

  ```css
  /* assets/css/app.css */
  @import "../../deps/lantern_ui/priv/static/lantern_ui.css";
  @import "../../deps/lantern_ui/priv/static/lantern_ui_theme.css";
  ```

- **Using Fluxon** (or any system defining design tokens)? Import only the
  component styles and bridge `--lantern-*` onto your tokens (full example in
  the `lantern_ui.css` header). Charts need neither — they inherit through
  their built-in fallbacks.
- **Recolor** by setting any `--lantern-*` variable yourself.

## Value formatting

`area_chart` and `bar_chart` accept `value_format`: `:number` (default),
`:currency` (USD-style `$` prefix), or a 1-arity function `(number -> String.t())`.
Any other value is treated as `:number`. Custom-function output is rendered as
plain text — it is HTML-escaped before it reaches the tooltip.

## License

MIT — see [LICENSE](LICENSE).
