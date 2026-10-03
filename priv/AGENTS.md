# LanternUI agent rules

Paste target: the consuming app's `AGENTS.md`. Installed by
`mix lantern_ui.install_skills`, which replaces the catalog section below
with the current registry — do not edit the catalog by hand.

<!-- lantern-ui:rules:start -->

## LanternUI — build with components, not markup

LanternUI is a native Phoenix LiveView component set: server-rendered HEEx,
themed via CSS variables. No React, no JS UI libraries.

### Banned patterns (enforced by `mix lantern.lint`)

- Grouped lists and group headers are banned. One flat list: a status column
  on each row, rows ordered by status then recency, counts in the rows or in
  filter chips. Whatever a group header would have said stays visible per row
  or in the chips.
- Never hand-roll a table or button element where a component exists:
  table/1, data_table/1, resource_list/1 for tables; button/1 (size="icon"
  for icon-only) or dialog action slots for buttons.
- Never use palette color classes (red-500, slate-200) or hex-in-class
  values. Use semantic tokens (next section).
- Never use arbitrary pixel values. Dense chrome is text-meta (11px),
  text-caption (12px), text-mono-meta. The text-foreground-softer alias is
  deprecated; use text-foreground-soft.
- Unknown component or attribute names get a did-you-mean hint from the
  lint — trust it over a guess. `stat` was never a component (use
  stat_card/1); neither was bare `toast` (use toast_group/1 on the page plus
  LanternUI.send_toast/3).

### Tokens

Type: text-meta, text-caption, text-mono-meta. Greys: text-foreground,
text-foreground-soft, text-foreground-softest, text-muted-foreground.
Semantic: text-danger, bg-danger, text-success, bg-success, text-warning,
bg-warning. Components read --lantern-* CSS variables; see the lantern README
theming section and docs/scale.md.

### Page layout

Title and actions live in the breadcrumb bar; no tabs as a default grouping
mechanism; data_table fill only inside a bounded-height parent; row click
opens the record's own route; disable checkboxes when there is no bulk
action; records get routes, not inline expansion. Full checklist: the
phoenix-page-design skill.

### Recipes first

Copy the blocks in lantern's docs/recipes.md (same source the recipe tests
render) wherever a recipe fits — flat ticket list, record page with
inspector rail, three-column inbox, project overview, icon toolbar, capacity
strip. Never hand-roll rows, glyphs, rings, or rails.

### Starters

List page (title and actions belong to the table header; status stays a
column, never a group):

```heex
<.data_table
  id="tickets"
  rows={@tickets}
  meta={@meta}
  path="/tickets"
  title="Tickets"
  fill
  views={["list"]}
  show_checkboxes={false}
  search_field={:title}
  data-lantern-list-nav
>
  <:filter
    field={:status}
    label="Status"
    options={[{"In progress (1)", "in_progress"}, {"To do (1)", "todo"}]}
    prompt="All statuses"
  />
  <:list_item :let={ticket}>
    <.list_row
      identifier={ticket.identifier}
      title={ticket.title}
      navigate={ticket.href}
      data-lantern-list-item
    >
      <:leading>
        <.status_glyph status={ticket.status} />
        <span>{ticket.status |> Atom.to_string() |> String.replace("_", " ")}</span>
      </:leading>
      <:trailing>{ticket.date}</:trailing>
    </.list_row>
  </:list_item>
</.data_table>
```

Record page (breadcrumb owns the panel toggle; properties go in a dense
description list inside the side panel):

```heex
<.breadcrumb_bar id="ticket-crumb">
  <.breadcrumb home="/" items={@crumbs} />
  <:actions label="Toggle panel">
    <.side_panel_toggle
      id="ticket-panel-toggle"
      panel_id="ticket-panel"
      panel_key="ticket"
      open={@panel_open}
      kbd="]"
    />
  </:actions>
</.breadcrumb_bar>
<.page_header title={@ticket.title} description={@ticket.identifier} />
<.card title="Description">
  {@ticket.body}
</.card>
<.side_panel id="ticket-panel" open={@panel_open} aria-label="Ticket properties">
  <.inspector aria-label="Ticket">
    <.inspector_section title="Properties">
      <.description_list layout="dense">
        <:item label="Status">{@ticket.status}</:item>
        <:item label="Priority">{@ticket.priority}</:item>
      </.description_list>
    </.inspector_section>
  </.inspector>
</.side_panel>
```

Overview strip (stats plus ring; never a custom metric grid):

```heex
<.stat_grid>
  <:stat label="Open" value={@open_count} />
  <:stat label="Shipped" value={@shipped_count} href="/orders?status=shipped" />
  <:stat label="Revenue" value={@formatted_revenue} />
</.stat_grid>
```

Toast feedback (the group renders once, usually in the layout; events push
messages — there is no bare toast component):

```heex
<.toast_group flash={@flash} />
```

```elixir
{:noreply, LanternUI.send_toast(socket, :info, "Slack notifications on")}
```

<!-- lantern-ui:catalog:start -->
<!-- replaced by `mix lantern_ui.install_skills` with the registry catalog -->
<!-- lantern-ui:catalog:end -->

<!-- lantern-ui:rules:end -->
