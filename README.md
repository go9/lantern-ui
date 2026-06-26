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
{:lantern_ui, github: "go9/lantern-ui"}
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

## JS hook (required for area_chart hover)

`area_chart` uses `ChartHover` and `line_chart` uses `LineHover` for their
crosshair/tooltips — both ship in `LanternHooks`, so the single import below
registers them. In `assets/js/app.js`:

```js
import LanternHooks from "../../deps/lantern_ui/priv/static/lantern_ui_hooks.js"

let Hooks = { ...LanternHooks /* , ...yourOtherHooks */ }
let liveSocket = new LiveSocket("/live", Socket, { params: {/* ... */}, hooks: Hooks })
```

`sparkline` and `bar_chart` need no JavaScript.

## Theming

Components read colors from CSS variables with chained fallbacks:

| Purpose | Variable chain |
|---|---|
| accent | `--lantern-accent` → `--color-primary-500` → `#3b82f6` |
| text | `--lantern-fg` → `--foreground` → `#111827` |
| muted text | `--lantern-fg-muted` → `--foreground-softer` → `#6b7280` |
| surface (tooltip) | `--lantern-surface` → `--background-base` → `#ffffff` |

- **Using Fluxon** (or any system defining those tokens)? Do nothing — charts
  inherit your tokens through the fallbacks and match automatically. Don't import
  the bundled theme (it would override with its own `--lantern-*`).
- **Standalone / public?** Import the optional light + dark theme:

  ```css
  /* assets/css/app.css */
  @import "../../deps/lantern_ui/priv/static/lantern_ui.css";
  ```

- **Recolor** by setting any `--lantern-*` variable yourself.

## Value formatting

`area_chart` and `bar_chart` accept `value_format`: `:number` (default),
`:currency` (USD-style `$` prefix), or a 1-arity function `(number -> String.t())`.
Any other value is treated as `:number`. Custom-function output is rendered as
plain text — it is HTML-escaped before it reaches the tooltip.

## License

MIT — see [LICENSE](LICENSE).
