---
name: lantern-recipes
description: copy these before writing any list/rail/inbox/overview page in a lantern app; never hand-roll rows, glyphs, rings or rails
license: MIT
metadata:
  source: https://github.com/go9/lantern-ui
---

# Lantern recipes

Copy these before writing any list/rail/inbox/overview/conversation/trace page in a lantern app; never hand-roll rows, glyphs, rings or rails.

HEEx is built only from lantern components (lantern classes and `--lantern-*` tokens are fine; no raw Tailwind utilities, no arbitrary values). Same source as `docs/recipes.md` and `test/support/recipes/`.

Origins: flicker #1404 tickets list, #1407 suggestions inbox, #1408 project hub.

Use `<.page_shell layout="strip">` when the page should show the trail, notice and actions on one row under the app bar (opt-in; the default is the stacked topline). Put a workspace or org switcher in `app_shell`'s `<:sidebar_header>` slot, not the top bar.

Every routed page renders exactly one `<.page_shell>`: it owns the breadcrumb row (the last crumb is the current page and title), one visually hidden `h1`, and the action row. Pass ancestors as `breadcrumbs`, the title as `title`, and page actions as `actions` descriptors. `<.page_header>` is deprecated and removed in 1.0. The one exception is the sign-in page (Block 7): it is not an app route and has no shell, so it uses a card title.

Grouped tables and group headers are banned; use a flat list with a status column + filter chips. Whatever a group header said (status name, count) must stay visible per row or in the filter chips with counts.

## Page recipes

Index, detail, settings, form and empty pages for the shadcn app preset: copy from `docs/page-recipes.md` (`page_container`, `page_heading`, `page_section`, `index_toolbar`, `detail_layout`, `settings_page layout="stacked"` + `settings_form`, `form_group`, `form_actions`, `empty_state kind=`). Settings: stacked sections, ONE Save per form disabled until dirty, no tabs for about four small sections.

## Page blocks

Whole pages that look finished — copy one block from the recipe index at the top of `docs/recipes.md` ("Page blocks", same source as `test/support/blocks/`, screenshots in `test/fixtures/blocks_gallery/`). Never hand-roll a shell, dashboard, index, detail, settings, form, login, or confirm flow.

- **app_shell** — the full frame: sidebar nav, a page shell (breadcrumb trail, title, actions), content.
- **dashboard** — stat cards, one chart, recent activity.
- **index** — flat table, filter chips with counts, search, pagination, row click.
- **detail** — page shell with its actions, body card, right inspector panel.
- **settings** — stacked section cards, each with its own form and save row.
- **form** — single card, inline validation errors, cancel/save footer.
- **login** — centered card, one primary action, SSO second.
- **destructive** — confirm dialog plus empty, loading, and error states.

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

## Flat table with placeholder row

**When to use:** A dense record table: URL sort and filters, a status/kind column on every row, counted filter chips, an optional cards slot for the narrow layout, and a subdued full-width add/intent row. The add row is a real button (Tab / Enter / Space, optional `kbd`); do not fake a disabled record. Pass `fill` when the parent has a bounded height so rows scroll inside the table; without it the table grows with the document and headers stick only in the wrap's horizontal scrollport. No grouped bands. Row navigate opens the record; extra per-row controls go in `:row_action`, not a second click on the row. Multi-row matrix heads are not this recipe.

```heex
<.data_table
  id="entities"
  rows={@entities}
  meta={@meta}
  path="/entities"
  title="Entities"
  fill
  row_navigate={& &1.href}
  search_field={:name}
  show_checkboxes={false}
>
  <:filter
    field={:kind}
    label="Kind"
    options={[{"Secret (1)", "secret"}, {"Config (1)", "config"}]}
    prompt="All kinds"
  />
  <:col :let={entity} label="Name" field={:name} sortable>{entity.name}</:col>
  <:col :let={entity} label="Kind">{entity.kind}</:col>
  <:col :let={entity} label="Status">
    <.status_glyph status={entity.status} />
    <span>{entity.status |> Atom.to_string() |> String.replace("_", " ")}</span>
  </:col>
  <:card :let={entity}>
    <.list_row identifier={entity.name} title={entity.name} navigate={entity.href}>
      <:leading><.status_glyph status={entity.status} /></:leading>
      <:meta>
        <.badge size="sm">{entity.kind}</.badge>
      </:meta>
    </.list_row>
  </:card>
  <:placeholder label="Add entity" kbd="A" event="add_entity" />
</.data_table>
```

## Record page with inspector rail

**When to use:** A record page: a `page_shell` names the record and carries its actions, the body card's header holds the panel toggle, the card body holds the long content (LiveCode in flicker; the description card is the host slot), and a collapsible side panel shows property rows.

**Origin:** flicker #1404 ticket show.

```heex
<.page_shell id="ticket-shell" title={@ticket.title} breadcrumbs={@crumbs}>
  <.card title="Description" description={@ticket.identifier}>
    <:actions>
      <.side_panel_toggle
        id="ticket-panel-toggle"
        panel_id="ticket-panel"
        panel_key="ticket"
        open={@panel_open}
        kbd="]"
      />
    </:actions>
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
</.page_shell>
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

**When to use:** A project hub: a `page_shell` names the project, a progress card leads the content, then a stats strip and flat children. Do not invent a custom overview grid.

**Origin:** flicker #1408 project hub.

```heex
<.page_shell
  id="project-shell"
  title={@project.name}
  breadcrumbs={[%{label: "Projects", navigate: "/projects"}]}
>
  <.stack gap="lg">
    <.card title="Progress" description={@project.summary}>
      <.progress
        shape="ring"
        completed={@project.completed}
        scope={@project.scope}
        label="Progress"
      >
        {@project.completed} / {@project.scope}
      </.progress>
    </.card>
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
  </.stack>
</.page_shell>
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

## Conversation thread

**When to use:** An inbox thread: conversation list, follow-aware transcript, an action card in the stream, and a composer that keeps a pending or rejected draft. Do not add a chat framework. `follow={true}` starts at the latest message; scrolling away pauses follow and makes Jump to latest keyboard reachable; appending while the reader is in history must not steal the viewport. Keep `@draft` on send failure (the textarea value is the assign). Give action buttons stable ids so a patch cannot drop focus. Autosize and Enter-to-send are out of scope — use the existing textarea and an explicit Send.

**Origin:** lantern-ui Chat Kit, composed for Ask / Inbox.

```heex
<.card_grid>
  <.card flush title="Inbox">
    <.scroll_area label="Threads" data-lantern-list-nav style="max-height: 24rem;">
      <.list_row
        :for={thread <- @threads}
        identifier={thread.identifier}
        title={thread.title}
        subtitle={thread.preview}
        navigate={thread.href}
        selected={thread.selected}
        data-lantern-list-item
      >
        <:leading><.avatar size="sm" initials={thread.initials} /></:leading>
        <:meta>
          <.badge :if={thread.unread} size="sm" color="info">{thread.unread}</.badge>
        </:meta>
        <:trailing>{thread.date}</:trailing>
      </.list_row>
    </.scroll_area>
  </.card>
  <.card title={@thread.title} description={@thread.meta}>
    <.message_scroller
      id="thread"
      label="Conversation"
      follow={true}
      busy={@streaming}
      on_seen="seen"
      style="height: 24rem;"
    >
      <.message_scroller_item
        :for={message <- @messages}
        id={"message-#{message.id}"}
        message_id={message.id}
        scroll_anchor={message.role == :assistant}
      >
        <.message
          align={if message.role == :user, do: "end", else: "start"}
          tone={if message.role == :user, do: "primary", else: "surface"}
        >
          <:avatar><.avatar size="sm" initials={message.initials} /></:avatar>
          <:header>{message.author}</:header>
          {message.content}
          <:footer>{message.at}</:footer>
        </.message>
      </.message_scroller_item>
      <.message_scroller_item
        :if={@action}
        id={"action-#{@action.id}"}
        message_id={"action-#{@action.id}"}
      >
        <.card title={@action.title} description={@action.summary}>
          {@action.body}
          <:footer>
            <.button
              id={"action-#{@action.id}-approve"}
              variant="solid"
              phx-click="approve"
              phx-value-id={@action.id}
            >
              Approve
            </.button>
            <.button
              id={"action-#{@action.id}-reject"}
              variant="outline"
              color="danger"
              phx-click="reject"
              phx-value-id={@action.id}
            >
              Reject
            </.button>
          </:footer>
        </.card>
      </.message_scroller_item>
    </.message_scroller>
    <:footer>
      <.stack gap="sm">
        <.alert :if={@send_error} color="danger" title="Message not sent">{@send_error}</.alert>
        <form phx-change="draft" phx-submit="send">
          <.stack gap="sm">
            <.textarea
              id="composer"
              name="draft"
              value={@draft}
              label="Message"
              rows={3}
              placeholder="Write a reply"
            />
            <.button type="submit" variant="solid" disabled={@streaming}>Send</.button>
          </.stack>
        </form>
      </.stack>
    </:footer>
  </.card>
</.card_grid>
```

## Run trace

**When to use:** A live run or Ask trace: timeline events with disclosure payloads inside a follow-aware scroller. Mark each event as a scroller item (`data-part="item"`, `data-message-id`, optional `data-scroll-anchor`) so append/follow/jump-to-latest reuse Chat Kit. Keep collecting events when the reader has scrolled away — pausing follow is not pausing ingest. Live / paused / done is a text badge (never color or motion alone); the spinner is extra and already static under `prefers-reduced-motion`. Native `details` keep their open state across patches after mount. Do not group events into bands; filter or a phase column if you need grouping.

**Origin:** lantern-ui timeline + log_view + message_scroller, composed for RunTrace / index logs.

```heex
<.card title={@run.title} description={@run.summary}>
  <:actions>
    <.badge :if={@run.state == :live} color="info" size="sm">Live</.badge>
    <.badge :if={@run.state == :paused} color="warning" size="sm">Paused</.badge>
    <.badge :if={@run.state == :done} color="success" size="sm">Done</.badge>
    <.loading :if={@run.state == :live} size="sm" label="Run is live" />
    <.button :if={@run.state == :live} size="sm" phx-click="pause_run">Pause run</.button>
    <.button :if={@run.state == :paused} size="sm" variant="solid" phx-click="resume_run">
      Resume run
    </.button>
  </:actions>
  <.message_scroller
    id="run-trace"
    label="Run trace"
    follow={@follow}
    busy={@run.state == :live}
    style="height: 24rem;"
  >
    <.timeline>
      <.timeline_item
        :for={event <- @events}
        id={"event-#{event.id}"}
        title={event.title}
        label={event.label}
        at={event.at}
        status={event.status}
        open={event.open}
        data-part="item"
        data-message-id={event.id}
        data-scroll-anchor={event.anchor || nil}
      >
        <:detail :if={event.detail}>
          <.log_view id={"event-#{event.id}-payload"} label="Payload">
            <.log_line at={event.at} channel={event.channel} severity={event.severity}>
              {event.detail}
            </.log_line>
          </.log_view>
        </:detail>
      </.timeline_item>
    </.timeline>
  </.message_scroller>
</.card>
```
