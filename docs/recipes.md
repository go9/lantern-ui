# Recipes

Copy these before writing any list, rail, inbox, or overview page in a lantern app. Never hand-roll rows, glyphs, rings, or rails.

Each recipe is one when-to-use line plus one HEEx block built **only** from lantern components (lantern classes and `--lantern-*` tokens are fine; no raw Tailwind utilities, no arbitrary `text-[Npx]` values). The HEEx is the same source the test suite renders (`test/support/recipes/`).

Origins are the flicker pages these shapes were extracted from:

- tickets list — [orlando-umbrella/flicker#1404](https://github.com/orlando-umbrella/flicker/pull/1404)
- suggestions inbox — [orlando-umbrella/flicker#1407](https://github.com/orlando-umbrella/flicker/pull/1407)
- project hub — [orlando-umbrella/flicker#1408](https://github.com/orlando-umbrella/flicker/pull/1408)

Swap the fixture assigns (`@ticket`, `@paths`, …) for the host's LiveView assigns. String paths in the recipes compile without verified routes; prefer `~p` in the app.

## Linear-style list row

**When to use:** A dense issue row — priority glyph, id, status glyph, title, tags, progress ring, date — sitting under a tinted group band.

**Origin:** flicker #1404 tickets list.

```heex
<.group_band name="In progress" count={1}>
  <:glyph><.status_glyph status={:in_progress} /></:glyph>
  <:action navigate="/tickets/new?status=in_progress" label="New ticket in In progress">
    <.icon name="plus" />
  </:action>
</.group_band>
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
    <.progress_ring completed={@ticket.completed} scope={@ticket.scope} size="sm" />
  </:meta>
  <:trailing>{@ticket.date}</:trailing>
</.list_row>
```

## Grouped list with toolbar

**When to use:** A ticket index grouped into collapsible bands, with All/Active/Backlog on the left and Filter/Display icon buttons on the right.

**Origin:** flicker #1404 tickets list.

```heex
<.card flush>
  <:header>
    <.segmented id="tickets-scope" value={@scope} label="View">
      <:segment value="all" patch={@paths.all}>All</:segment>
      <:segment value="active" patch={@paths.active}>Active</:segment>
      <:segment value="backlog" patch={@paths.backlog}>Backlog</:segment>
    </.segmented>
  </:header>
  <:actions>
    <.icon_button label="Filter" kbd="F">
      <.icon name="funnel" />
    </.icon_button>
    <.icon_button label="Display" kbd="D">
      <.icon name="adjustments-horizontal" />
    </.icon_button>
  </:actions>
  <.scroll_area label="Tickets" data-lantern-list-nav>
    <.group_band name="In progress" count={2} patch={@paths.in_progress}>
      <:glyph><.status_glyph status={:in_progress} /></:glyph>
      <:action navigate={@paths.new_in_progress} label="New ticket in In progress">
        <.icon name="plus" />
      </:action>
    </.group_band>
    <.list_row
      :for={ticket <- @tickets}
      identifier={ticket.identifier}
      title={ticket.title}
      parent={ticket.parent}
      navigate={ticket.href}
      selected={ticket.selected}
      data-lantern-list-item
    >
      <:leading><.status_glyph status={ticket.status} /></:leading>
      <:meta>
        <.badge size="sm">{ticket.tag}</.badge>
      </:meta>
      <:trailing>{ticket.date}</:trailing>
    </.list_row>
    <.group_band name="Done" count={40} collapsed patch={@paths.done}>
      <:glyph><.status_glyph status={:done} /></:glyph>
    </.group_band>
  </.scroll_area>
</.card>
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
      <.property_row label="Status">{@ticket.status}</.property_row>
      <.property_row label="Priority">{@ticket.priority}</.property_row>
      <.property_row label="Tags">
        <.badge size="sm">{@ticket.tag}</.badge>
      </.property_row>
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
      <.icon_button label="Filter" kbd="F">
        <.icon name="funnel" />
      </.icon_button>
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
        <.property_row label="Status">{@selected.status}</.property_row>
        <.property_row label="Source">{@selected.source}</.property_row>
      </.inspector_section>
    </.inspector>
  </.card>
</.card_grid>
```

## Project overview

**When to use:** Hub header, a progress ring with a stats strip, then grouped children. Do not invent a custom overview grid.

**Origin:** flicker #1408 project hub.

```heex
<.page_header title={@project.name} description={@project.summary}>
  <:actions>
    <.progress_ring
      completed={@project.completed}
      scope={@project.scope}
      label="Progress"
    >
      {@project.completed} / {@project.scope}
    </.progress_ring>
  </:actions>
</.page_header>
<.stat_grid>
  <:stat label="Apps" value={@stats.apps} />
  <:stat label="Databases" value={@stats.databases} />
  <:stat label="Environments" value={@stats.environments} />
</.stat_grid>
<.card flush title="Tickets">
  <.group_band name="In progress" count={1}>
    <:glyph><.status_glyph status={:in_progress} /></:glyph>
  </.group_band>
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
    <.icon_button label="Promote to ticket" kbd="P" variant="primary">
      <.icon name="arrow-up-tray" />
    </.icon_button>
    <.icon_button label="Snooze" kbd="H">
      <.icon name="clock" />
    </.icon_button>
    <.icon_button label="Mark resolved" kbd="E">
      <.icon name="check" />
    </.icon_button>
    <.icon_button label="More">
      <.icon name="ellipsis-horizontal" />
    </.icon_button>
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
