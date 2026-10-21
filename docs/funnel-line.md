# Counted stage filters

Use `funnel_line/1` when counts also choose the visible records. This is one
filter group, not a tab list or a progress indicator. For metrics without
filtering use `stat_grid/1`; for panels use `tabs_list/1`.

```heex
<.funnel_line id="reports" label="Where reports are" value={@bucket} on_change="filter">
  <:stage value="needs" label="Needs you" count={@counts.needs} />
  <:stage value="work" label="In work" count={@counts.work} />
  <:stage value="shipped" label="Shipped" count={@counts.shipped} />
  <:stage value="told" label="Told" count={@counts.told} />
  <:stage value="snoozed" label="Snoozed" count={@counts.snoozed} overflow />
  <:stage value="held" label="Held" count={@counts.held} overflow />
</.funnel_line>
```

```elixir
def handle_event("filter", %{"value" => bucket}, socket) do
  # Validate against your allowed bucket keys and filter your records here.
  {:noreply, assign(socket, :bucket, bucket)}
end
```

Counts are non-negative integers calculated by the host from mutually exclusive
buckets. Count a cluster once. In Suggestions, Shipped means shipped but reporters
not yet told; derive Told from delivery state, not votes. Those rules belong in
the application, not this component. Needs you is the application's default.

Primary stages always render, including zero. Overflow stages follow a divider
and render only above zero, except the selected stage stays visible at zero.
This follows the prototype's behavior when the last record leaves a bucket.
The host chooses the next selection if it wants to hide that empty stage.
Slot values must be unique; labels and counts are escaped text.

The required `id` and encoded stage keys produce stable button ids across
reorders and count updates. `label` names a `role="group"`; each native button
announces its label, count, and `aria-pressed`. Selection belongs to the server.
Use Tab/Shift+Tab to move and Enter/Space to select; focus remains on the button
after a patch. Narrow lines scroll horizontally, including as buttons receive
keyboard focus. Focus styling comes from `button/1`; there is no animation,
smooth scrolling, hook, tab panel, or custom keyboard model.

`on_change` accepts an event string or `Phoenix.LiveView.JS`; `target` optionally
targets a LiveComponent. `class` and global attributes apply to the group.
There are no stage colors, icons, disabled states, link modes, count formatting
options, secondary totals, or automatic bucket calculations.

Run the interactive demo with `MIX_ENV=test PORT=4013 mix run --no-halt
test/qa/server.exs`, then visit `/funnel`. It exercises filtering and a selected
overflow stage becoming empty. `BASE=http://127.0.0.1:4013 CHROME_PATH=/path/to/chrome
node test/qa/funnel.mjs` checks keyboard activation, server updates, mobile scroll,
dark theme, and reduced motion, and saves screenshots.
