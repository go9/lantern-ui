# Recipes

Copy these before writing any list, rail, inbox, or overview page in a lantern app. Never hand-roll rows, glyphs, rings, or rails.

Each recipe is one when-to-use line plus one HEEx block built **only** from lantern components (lantern classes and `--lantern-*` tokens are fine; no raw Tailwind utilities, no arbitrary `text-[Npx]` values). The HEEx is the same source the test suite renders (`test/support/recipes/`).

Origins are the flicker pages these shapes were extracted from:

- tickets list — [orlando-umbrella/flicker#1404](https://github.com/orlando-umbrella/flicker/pull/1404)
- suggestions inbox — [orlando-umbrella/flicker#1407](https://github.com/orlando-umbrella/flicker/pull/1407)
- project hub — [orlando-umbrella/flicker#1408](https://github.com/orlando-umbrella/flicker/pull/1408)

Swap the fixture assigns (`@ticket`, `@paths`, …) for the host's LiveView assigns. String paths in the recipes compile without verified routes; prefer `~p` in the app.

## Fill list pages

**When to use:** The page body is a single `data_table`. Pass `fill` (and give the parent a bounded flex height, e.g. flicker's `page_layout fill`) so the rows area scrolls inside the table and pagination stays at the bottom of the viewport. List, cards, and table views all honour this; without `fill` a long list grows and pushes the pager below the fold.

Grouped tables and group headers are banned. A page that listed rows under tinted collapsible group headers becomes one flat list: a status column on each row, rows ordered by status then recency, and quick-filter chips or a tabs-free filter. Whatever the group header said (status name, count) must stay visible per row or in the filter chips with counts.

## Linear-style list row

**When to use:** A dense issue row — priority glyph, id, status glyph, title, tags, progress ring, date — in a flat list.

**Origin:** flicker #1404 tickets list.

```heex
<.list_row
  identifier={@ticket.identifier}
  title={@ticket.title}
  parent={@ticket.parent}
  navigate={@ticket.href}
>
  <:leading>
    <.priority_glyph priority={@ticket.priority} />
    <.status_glyph status={@ticket.status} />
  </:leading>
  <:meta>
    <.badge size="sm">{@ticket.tag}</.badge>
    <.progress shape="ring" completed={@ticket.completed} scope={@ticket.scope} size="sm" />
  </:meta>
  <:trailing>{@ticket.date}</:trailing>
</.list_row>
```

## Flat ticket list with toolbar

**When to use:** A ticket index as one flat `data_table`: a status column on each row (glyph + name), rows ordered by status then recency, a status filter with counts, and search. Title and actions live in the table header; no tabs, no group bands. Row click opens the record.

**Origin:** flicker #1404 tickets list.

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
      parent={ticket.parent}
      navigate={ticket.href}
      selected={ticket.selected}
      data-lantern-list-item
    >
      <:leading>
        <.status_glyph status={ticket.status} />
        <span>{ticket.status |> Atom.to_string() |> String.replace("_", " ")}</span>
      </:leading>
      <:meta>
        <.badge size="sm">{ticket.tag}</.badge>
      </:meta>
      <:trailing>{ticket.date}</:trailing>
    </.list_row>
  </:list_item>
</.data_table>
```

## Record page with inspector rail

**When to use:** A record page: breadcrumb actions hold the panel toggle, title plus a long body (LiveCode in flicker; the description card is the host slot), and a collapsible side panel of property rows.

**Origin:** flicker #1404 ticket show.

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
        <:item label="Tags">
          <.badge size="sm">{@ticket.tag}</.badge>
        </:item>
      </.description_list>
    </.inspector_section>
  </.inspector>
</.side_panel>
```

## Three-column inbox

**When to use:** Inbox · reading pane · properties. List on the left, selected record in the middle, inspector on the right.

**Origin:** flicker #1407 suggestions inbox.

```heex
<.card_grid>
  <.card flush title={"Inbox · #{@inbox_count}"}>
    <:actions>
      <.button size="icon" variant="ghost" label="Filter" kbd="F">
        <.icon name="funnel" />
      </.button>
    </:actions>
    <.scroll_area label="Inbox" data-lantern-list-nav>
      <.list_row
        :for={item <- @inbox_items}
        identifier={item.identifier}
        title={item.title}
        navigate={item.href}
        selected={item.selected}
        data-lantern-list-item
      >
        <:leading><.status_glyph status={item.status} /></:leading>
        <:meta>
          <.badge size="sm">{item.kind}</.badge>
        </:meta>
      </.list_row>
    </.scroll_area>
  </.card>
  <.card title={@selected.title} description={@selected.meta}>
    {@selected.body}
  </.card>
  <.card flush title="Properties">
    <.inspector aria-label="Suggestion">
      <.inspector_section title="Properties">
        <.description_list layout="dense">
          <:item label="Status">{@selected.status}</:item>
          <:item label="Source">{@selected.source}</:item>
        </.description_list>
      </.inspector_section>
    </.inspector>
  </.card>
</.card_grid>
```

## Project overview

**When to use:** Hub header, a progress ring with a stats strip, then flat children. Do not invent a custom overview grid.

**Origin:** flicker #1408 project hub.

```heex
<.page_header title={@project.name} description={@project.summary}>
  <:actions>
    <.progress
      shape="ring"
      completed={@project.completed}
      scope={@project.scope}
      label="Progress"
    >
      {@project.completed} / {@project.scope}
    </.progress>
  </:actions>
</.page_header>
<.stat_grid>
  <:stat label="Apps" value={@stats.apps} />
  <:stat label="Databases" value={@stats.databases} />
  <:stat label="Environments" value={@stats.environments} />
</.stat_grid>
<.card flush title="Tickets">
  <.list_row
    :for={child <- @children}
    identifier={child.identifier}
    title={child.title}
    navigate={child.href}
  >
    <:leading><.status_glyph status={child.status} /></:leading>
    <:trailing>{child.date}</:trailing>
  </.list_row>
</.card>
```

## Icon toolbar with kbd hints

**When to use:** Icon-only actions with an accessible label and a keyboard hint in the tooltip. Used on the inbox thread chrome.

**Origin:** flicker #1407 suggestions inbox.

```heex
<.card>
  <:actions>
    <.button size="icon" label="Promote to ticket" kbd="P" variant="solid">
      <.icon name="arrow-up-tray" />
    </.button>
    <.button size="icon" label="Snooze" kbd="H" variant="ghost">
      <.icon name="clock" />
    </.button>
    <.button size="icon" label="Mark resolved" kbd="E" variant="ghost">
      <.icon name="check" />
    </.button>
    <.button size="icon" label="More" variant="ghost">
      <.icon name="ellipsis-horizontal" />
    </.button>
  </:actions>
  Inbox thread
</.card>
```

## Capacity strip

**When to use:** N slots · busy · waiting · cost as lantern stats and badges. Do not hand-roll a metric row.

**Origin:** flicker #1408 project hub (factory capacity on the hub).

```heex
<.stat_grid>
  <:stat label="Slots" value={@capacity.slots} />
  <:stat label="Busy" value={@capacity.busy} />
  <:stat label="Waiting" value={@capacity.waiting} />
  <:stat label="Cost" value={@capacity.cost} />
</.stat_grid>
<.badge color="warning" size="sm">{@capacity.waiting} waiting</.badge>
<.badge color="success" size="sm">{@capacity.busy} busy</.badge>
```
