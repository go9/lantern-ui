# Recipes

Copy these before writing any list, rail, inbox, or overview page in a lantern app. Never hand-roll rows, glyphs, rings, or rails.

Each recipe is one when-to-use line plus one HEEx block built **only** from lantern components (lantern classes and `--lantern-*` tokens are fine; no raw Tailwind utilities, no arbitrary `text-[Npx]` values). The HEEx is the same source the test suite renders (`test/support/recipes/`).

Origins are the flicker pages these shapes were extracted from:

- tickets list — [orlando-umbrella/flicker#1404](https://github.com/orlando-umbrella/flicker/pull/1404)
- suggestions inbox — [orlando-umbrella/flicker#1407](https://github.com/orlando-umbrella/flicker/pull/1407)
- project hub — [orlando-umbrella/flicker#1408](https://github.com/orlando-umbrella/flicker/pull/1408)

Swap the fixture assigns (`@ticket`, `@paths`, …) for the host's LiveView assigns. String paths in the recipes compile without verified routes; prefer `~p` in the app.

## Page shell

Every routed page renders exactly one `<.page_shell>`. It owns the page's breadcrumb row (the last crumb is the current page, and it is the page title), one visually hidden `h1`, and the action row. Pass ancestors as `breadcrumbs`, the title as `title`, and page actions as `actions` descriptors. Do not put a second breadcrumb row or a visible title beside it. `<.page_header>` is deprecated and removed in 1.0; migrate to `<.page_shell>`. The one exception is the sign-in page (Block 7): it is not an app route and has no shell, so it uses a card title.

## Page blocks

Whole pages that look finished, copied as one block. Each block is one when-to-use line plus one HEEx block built **only** from lantern components (same source as `test/support/blocks/`), and each renders in both the default theme and the shadcn preset — see `test/fixtures/blocks_gallery/` for the screenshots.

Blocks inherit the host's body font and measure: the gallery fixture sets `font-family: var(--lantern-font)` on the body the way a host app does, `stack/1` owns vertical rhythm, and only the page measure (max-width, centering) stays an inline style. No Tailwind utilities anywhere — the blocks render identically with or without a host utility layer. Screenshots live in `test/fixtures/blocks_gallery/` (the HTML docs regenerate via `mix test`; only the JPEGs are committed).

- **app_shell** — use this when the page needs the full frame: sidebar nav, a page shell (breadcrumb trail, title, actions), and content in one shell.
- **dashboard** — use this when the page answers "where do we stand": stat cards, one chart, recent activity.
- **index** — use this when the page is a record list: flat table, filter chips with counts, search, pagination, row click.
- **detail** — use this when the page is one record: page shell with its actions, body card, right inspector panel.
- **settings** — use this when the page edits preferences: stacked section cards, each with its own form and save row.
- **form** — use this when the page creates or edits one record: single card, inline validation errors, cancel/save footer.
- **login** — use this when the page signs someone in: centered card, one primary action, SSO second.
- **destructive** — use this when the page ends something: confirm dialog plus the empty, loading, and error states around it.

## Fill list pages

**When to use:** The page body is a single `data_table`. Pass `fill` (and give the parent a bounded flex height, e.g. flicker's `page_layout fill`) so the rows area scrolls inside the table and pagination stays at the bottom of the viewport. List, cards, and table views all honour this; without `fill` a long list grows and pushes the pager below the fold.

Grouped tables and group headers are banned. A page that listed rows under tinted collapsible group headers becomes one flat list: a status column on each row, rows ordered by status then recency, and quick-filter chips or a tabs-free filter. Whatever the group header said (status name, count) must stay visible per row or in the filter chips with counts.

## Media grid

**When to use:** A visual collection where each item needs an image, optional selection, a short caption, and actions. Supply `on_select` for server-owned selection; the component keeps the checkbox and its event hook keyboard accessible.

```heex
<.media_tile_grid min="180px">
  <.media_tile
    :for={item <- @items}
    id={item.id}
    image_src={item.image_url}
    image_alt={item.name}
    selectable
    selected={item.id in @selected_ids}
    on_select="toggle_item"
  >
    <:caption>
      <strong>{item.name}</strong>
      <span>{item.description}</span>
    </:caption>
  </.media_tile>
</.media_tile_grid>
```

## Metric cards with trends

**When to use:** A compact dashboard summary with a small trend line. Sparklines are decorative unless `sparkline_label` gives an informative trend an accessible name. Tone accents use the theme's semantic tokens; metric and subtitle text keep foreground tokens for light and dark contrast.

```heex
<.stat_grid>
  <:stat
    :for={metric <- @metrics}
    id={metric.id}
    label={metric.label}
    value={metric.value}
    subtitle={metric.context}
    tone={metric.tone}
    sparkline_series={metric.history}
    sparkline_label={metric.trend_label}
  />
</.stat_grid>
```

## Date range filter

**When to use:** A dashboard date filter with standard presets and a custom range. The selected preset owns its calculated dates; custom mode keeps the caller's dates. Supply `today` (and `time_zone` when deriving it) when the page needs reproducible ranges. The popover traps focus while open.

```heex
<.date_range_popover
  id="activity-range"
  preset={@range["preset"]}
  start_date={@range["start_date"]}
  end_date={@range["end_date"]}
  today={@today}
  time_zone="Etc/UTC"
  phx-change="range_changed"
/>
```

## Keyboard shortcut hint

**When to use:** A small keycap beside an action label or a shortcut hint in help text. Pass symbolic glyph keys through `keys` so assistive technology receives names such as “Command” and “Shift.”

```heex
<.button variant="outline">
  Save
  <.kbd keys={[:command, "S"]} />
</.button>
```

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

## Block 1: app shell with sidebar and page shell

**When to use:** The page needs the full frame — brand, a workspace switcher at the top of the sidebar, sidebar nav with groups and count badges, and a `page_shell` with its breadcrumb trail, title, and actions — in one shell. `layout="strip"` puts the trail on the left and the notice and actions on the right of one row under the app bar; leave it off for the 0.10 stacked topline with its floating action row. `compact` opts the app chrome into the slim topline (36px, 38px at 46.1875rem and below); leave it off to keep the 0.9 layout. `:sidebar_header` holds the switcher; on the icon rail it should collapse to an avatar (`.lui-app[data-collapsed]`). Pass the trail to `<.page_shell breadcrumbs>`, not to the app shell's `:breadcrumb` slot, so the route keeps one breadcrumb row. Hosts with plain `use LanternUI` write `<.app_shell>`; the fixture below calls it fully qualified only because the test module defines its own `app_shell/1` template function.

```heex
<LanternUI.Components.Layout.app_shell id="demo-app" compact>
  <:brand>
    <.icon name="sparkles" />
    <span class="lui-brand-name">Acme</span>
  </:brand>
  <:header>
    <.badge size="sm" variant="soft">Production</.badge>
  </:header>
  <:actions>
    <.avatar size="sm" initials="AL" />
  </:actions>
  <:sidebar_header>
    <.avatar size="sm" initials="AW" />
    <span class="lui-brand-name">Acme workspace</span>
  </:sidebar_header>
  <:sidebar>
    <.nav_group label="Workspace">
      <.nav_item label="Dashboard" icon="chart-bar" navigate="/" active />
      <.nav_item label="Tickets" icon="document" navigate="/tickets" badge={12} />
      <.nav_item label="Inbox" icon="inbox" navigate="/inbox" badge={3} />
    </.nav_group>
    <.nav_group label="Manage">
      <.nav_item label="Projects" icon="folder" navigate="/projects" />
      <.nav_item label="Settings" icon="adjustments-horizontal" navigate="/settings" />
    </.nav_group>
  </:sidebar>
  <:sidebar_footer>
    <.nav_link label="Documentation" icon="globe-alt" href="/docs" />
  </:sidebar_footer>
  <.page_shell
    id="tickets-shell"
    layout="strip"
    title="Tickets"
    breadcrumbs={@shell_crumbs}
    actions={[
      %{id: "new", label: "New ticket", icon: "plus", priority: 10, navigate: "/tickets/new"}
    ]}
  >
    <.card title="Getting started" description="Three steps to a finished page.">
      <p style="margin: 0;">
        Pick a block from the recipe index, swap the fixture assigns for the host LiveView assigns, and ship.
      </p>
      <:footer>Blocks render in the default theme and the shadcn preset.</:footer>
    </.card>
  </.page_shell>
</LanternUI.Components.Layout.app_shell>
```

## Block 2: dashboard with stats, chart, and activity

**When to use:** The page answers "where do we stand" — a stat-cards row, one chart card, and a recent-activity card. No tabs, no custom metric grids.

```heex
<.page_shell
  id="dashboard-shell"
  title="Dashboard"
  breadcrumbs={@shell_crumbs}
  actions={[
    %{id: "export", label: "Export", icon: "arrow-down-tray", priority: 1, "phx-click": "export"},
    %{id: "new", label: "New ticket", icon: "plus", priority: 10, navigate: "/tickets/new"}
  ]}
>
  <.stack gap="lg" style="max-width: 1120px; margin: 0 auto;">
    <.stat_grid>
      <:stat :for={stat <- @stats} label={stat.label} value={stat.value} subtitle={stat.subtitle} />
    </.stat_grid>
    <.card title="Merged per day" description="Last 14 days across 4 repos.">
      <.area_chart
        id="dashboard-merged"
        series={@series}
        height={220}
        aria_label="Merged tickets per day"
      />
    </.card>
    <.card flush title="Recent activity" description="Latest updates, most recent first.">
      <.list_row
        :for={item <- @activity}
        identifier={item.identifier}
        title={item.title}
        navigate={item.href}
      >
        <:leading><.status_glyph status={item.status} /></:leading>
        <:trailing>{item.date}</:trailing>
      </.list_row>
    </.card>
  </.stack>
</.page_shell>
```

## Generic time-series chart

Use `time_series_chart/1` when a dashboard needs named series, stacked or
grouped bars, or an opt-in line, area, or points view. Each series owns a stable
id and an ordered list of `%{x, y}` points. All x values in one chart use the
same domain type: dates/date-times, numbers, or category strings. NaiveDateTime
values are interpreted as UTC. A series
`color` may be a single CSS custom-property reference such as
`"var(--lantern-chart-1)"`; invalid CSS is ignored and the chart palette is
used. Missing x keys break line and area paths; stacked area and bar modes treat
missing values as zero. Stacks accumulate positive and negative values on
separate sides of zero.

```heex
<.time_series_chart
  id="portfolio-performance"
  aria_label="Portfolio value over time"
  series={[
    %{id: :collection, label: "Collection", points: @collection_points},
    %{id: :inventory, label: "Inventory", points: @inventory_points}
  ]}
  type={@chart_type}
  curve={@curve}
  visible_series={@visible_series}
/>
```

The SVG keeps the requested pixel `height` (240 by default); the hook fits its
server-rendered 960px geometry to the measured container width on mount and
ResizeObserver changes. Without JavaScript, SVG aspect ratio stays uniform.
Tick labels are skipped when they would overlap, and y labels get measured left
padding.

The component includes zero in its signed y domain. Chart choices and visible
series remain LiveView assigns; validate form events in the parent LiveView and
pass the resulting values back as attrs. Set `type` to `:stacked_area`, `:bar`,
`:stacked_bar`, or `:grouped_bar` for those renderers, and use
`orientation={:horizontal}` for horizontal bars. Comparison series align on x
keys and render as a dashed overlay. Annotations use the same x keys and may
set a semantic `tone`. A chart with non-empty points must use one x domain
throughout: dates/date-times, numbers, or category strings. Mixed domains raise
`ArgumentError` with the conflicting domain kinds; malformed points are ignored,
and a truly empty chart uses `empty_message`.

Opt into selection events when a caller-owned panel should follow the point a
reader chooses. `select_event` pushes on pointer click/tap and keyboard Enter or
Space;
`hover_event` is optional and debounced. Both events carry `%{chart_id, x,
values}`, where `x` is the normalized x key and `values` maps each series id to
its raw value (or `nil` when that series has no point at the key). If a
comparison series repeats a primary series id, its value key is
`comparison:<id>:<index>`. Date keys remain ISO dates; date-time keys remain
ISO date-times. The chart continues to render from server assigns. For bar
types, `reference_lines` draws
token-colored dashed values and adds their labels and values to the data table;
the caller remains responsible for computing averages.

```heex
<.time_series_chart
  id="monthly-sales"
  type={:bar}
  select_event="select_sales_month"
  hover_event="hover_sales_month"
  reference_lines={[%{label: "Average", value: @average_sales}]}
  series={@sales_series}
/>
```

Handle `"select_sales_month"` or `"hover_sales_month"` in the parent LiveView's
`handle_event/3`; validate the chart id and x key before updating any panel.

Dense bars have a measurable server-rendered markup cost: each SVG bar is about
100 bytes, so 1,000 bars add roughly 100 KB before the chart wrapper, labels, and
other SVG content. Keep that cost in mind when choosing grouped or stacked bars
for large series.

`mise exec -- mix run bench/time_series_chart.exs` measures the full server render
(normalization, geometry, SVG, interaction data, and HTML encoding) over 101
samples after warmup. On an Apple M1 Mac mini with Elixir 1.15.7 / OTP 26, the
single-series p95 was 13.88 ms for 365 points and 43.78 ms for 1,000 points;
maximum HTML sizes were 178,316 and 485,372 bytes. Four series measured 34.8 ms
p95 / 300,444 bytes at 365 points and 103.44 ms p95 / 815,859 bytes at 1,000
points. The single-series 1,000-point result meets the 50 ms target; the four
series result is a larger workload with proportionally more paths and serialized
interaction data.

Compose the chart with `chart_card/1` when it needs a headline and caller-owned
tabs, ranges, settings, or footer content. `chart_settings/1` uses the existing
Popover and sends one native `phx-change` event; the parent validates the nested
`chart_settings` params and passes the resulting assigns back to both components.

```heex
<.chart_card id="portfolio-card" title="Portfolio value" value={@total_value}>
  <:tabs><.button size="sm" variant="ghost">Value</.button></:tabs>
  <:range_controls>
    <.button size="sm" variant="outline" phx-click="range" phx-value-range="6M">6M</.button>
    <.button size="sm" variant="outline" phx-click="range" phx-value-range="1Y">1Y</.button>
  </:range_controls>
  <:settings_trigger>
    <.chart_settings
      id="portfolio-settings"
      series={@series}
      type={Atom.to_string(@chart_type)}
      curve={Atom.to_string(@curve)}
      visible_series={@visible_series}
      grid={@grid}
      axes={@axes}
      glyphs={@glyphs}
      cumulative={@cumulative}
      compare_previous={@compare_previous}
      phx-change="chart_settings"
    />
  </:settings_trigger>
  <.time_series_chart
    id="portfolio-chart"
    aria_label="Portfolio value over time"
    series={@series}
    type={@chart_type}
    curve={@curve}
    visible_series={@visible_series}
    grid={@grid}
    axes={@axes}
    glyphs={@glyphs}
  />
  <:footer_note>Values update daily.</:footer_note>
</.chart_card>
```

The settings form submits `%{"chart_settings" => params}` in one event. `type`
and `curve` are strings in the submitted event; the component accepts chart
types as either atoms or strings. `visible_series` is an array of checked ids
and is omitted when none are checked. `grid`, `axes`, `glyphs`, `cumulative`, and
`compare_previous` submit as `"true"` or `"false"` strings. Settings and range
state stay with the parent LiveView. The chart's hover tooltip follows the
nearest shared x value, keyboard points support arrows plus Home/End/Escape, and
the expandable data table remains available for assistive technology and print.

## Block 3: flat index table with filter chips

**When to use:** The page is a record list — one flat `data_table` with filter chips carrying counts, a status column on each row, search, pagination, row click, and an empty state. Title and the primary action live in the `page_shell`; no tabs, no group bands. `row_navigate` (or `row_patch`) makes each row one real link — Enter, middle-click and open-in-new-tab work, and checkboxes, buttons and menus inside the row keep their own clicks; use `row_click` with a `JS` command when the row is not a link. Do not also put `navigate` on the `list_row`. `fill` pins pagination only when the parent bounds the height (see "Fill list pages" above) — without a bound the table takes its natural height.

```heex
<.page_shell
  id="tickets-shell"
  title="Tickets"
  breadcrumbs={@shell_crumbs}
  actions={[
    %{id: "new", label: "New ticket", icon: "plus", priority: 10, navigate: "/tickets/new"}
  ]}
>
  <.stack gap="lg" style="max-width: 1120px; margin: 0 auto;">
    <.data_table
      id="tickets"
      rows={@tickets}
      meta={@meta}
      path="/tickets"
      fill
      views={["list"]}
      show_checkboxes={false}
      search_field={:title}
      row_navigate={& &1.href}
      data-lantern-list-nav
    >
      <:tab label="All" count={24} />
      <:tab label="In progress" count={9} filters={[%{field: "status", value: "in_progress"}]} />
      <:tab label="To do" count={11} filters={[%{field: "status", value: "todo"}]} />
      <:tab label="Done" count={4} filters={[%{field: "status", value: "done"}]} />
      <:filter
        field={:status}
        label="Status"
        options={[
          {"In progress (9)", "in_progress"},
          {"To do (11)", "todo"},
          {"Done (4)", "done"}
        ]}
        prompt="All statuses"
      />
      <:list_item :let={ticket}>
        <.list_row
          identifier={ticket.identifier}
          title={ticket.title}
          parent={ticket.parent}
          selected={ticket.selected}
        >
          <:leading>
            <.status_glyph status={ticket.status} />
            <span class="lui-list-row-status">
              {ticket.status |> Atom.to_string() |> String.replace("_", " ")}
            </span>
          </:leading>
          <:meta>
            <.badge size="sm">{ticket.tag}</.badge>
          </:meta>
          <:trailing>{ticket.date}</:trailing>
        </.list_row>
      </:list_item>
      <:empty>
        <.empty_state icon="document" title="No tickets match">
          Try a different search, or create the first ticket.
          <:action>
            <.button size="sm" variant="solid" navigate="/tickets/new">New ticket</.button>
          </:action>
        </.empty_state>
      </:empty>
    </.data_table>
  </.stack>
</.page_shell>
```

## Block 4: detail page with inspector panel

**When to use:** The page is one record — a `page_shell` names the record and holds the edit action, the body card's header holds the panel toggle, a body card carries the content, and a collapsible side panel shows inspector sections.

```heex
<.page_shell
  id="ticket-shell"
  title={@ticket.title}
  breadcrumbs={@detail_crumbs}
  actions={[
    %{
      id: "edit",
      label: "Edit",
      icon: "pencil-square",
      priority: 10,
      navigate: "/tickets/241/edit"
    }
  ]}
>
  <.stack gap="lg" style="max-width: 1120px; margin: 0 auto;">
    <div style="display: flex; gap: 1.25rem; align-items: flex-start;">
      <.card title="Description" description={@ticket.identifier} style="flex: 1; min-width: 0;">
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
        <:footer>
          <.progress
            shape="ring"
            completed={@ticket.completed}
            scope={@ticket.scope}
            size="sm"
            label="Completion"
          >
            {@ticket.completed} / {@ticket.scope}
          </.progress>
        </:footer>
      </.card>
      <.side_panel id="ticket-panel" open={@panel_open} aria-label="Ticket properties">
        <.inspector aria-label="Ticket">
          <.inspector_section title="Properties">
            <.description_list layout="dense">
              <:item label="Status">
                <.status_glyph status={@ticket.status} /> in progress
              </:item>
              <:item label="Priority">
                <.priority_glyph priority={@ticket.priority} /> high
              </:item>
              <:item label="Tags">
                <.badge size="sm">{@ticket.tag}</.badge>
              </:item>
            </.description_list>
          </.inspector_section>
          <.inspector_section title="People">
            <.description_list layout="dense">
              <:item label="Owner">Ada Lovelace</:item>
              <:item label="Reviewer">Grace Hopper</:item>
            </.description_list>
          </.inspector_section>
        </.inspector>
      </.side_panel>
    </div>
  </.stack>
</.page_shell>
```

## Block 5: settings with one form per section

**When to use:** The page edits preferences — stacked section cards, each with its own controls and its own save row in the footer, so saving one section never moves the others.

```heex
<.page_shell id="settings-shell" title="Settings" breadcrumbs={@shell_crumbs}>
  <.stack gap="lg" style="max-width: 760px; margin: 0 auto;">
    <.card title="Profile" description="How your name appears on tickets and reviews.">
      <.stack gap="md">
        <.input id="settings-name" name="name" label="Display name" value="Ada Lovelace" />
        <.input
          id="settings-email"
          name="email"
          type="email"
          label="Email"
          value="ada@acme.test"
          help_text="Receipts and review requests land here."
        />
      </.stack>
      <:footer>
        <span>Saved 2m ago</span>
        <.button size="sm" variant="solid">Save profile</.button>
      </:footer>
    </.card>
    <.card title="Notifications" description="Pick which pings are worth interrupting you.">
      <.stack gap="sm">
        <.switch id="settings-mentions" name="mentions" label="Mentions" checked value="true" />
        <.switch
          id="settings-review"
          name="review_requests"
          label="Review requests"
          checked
          value="true"
        />
        <.switch id="settings-weekly" name="weekly_digest" label="Weekly digest" value="false" />
      </.stack>
      <:footer>
        <span>Saved 1h ago</span>
        <.button size="sm" variant="solid">Save notifications</.button>
      </:footer>
    </.card>
    <.card title="Appearance" description="Density and theme for this workspace.">
      <.stack gap="md">
        <.select
          native
          id="settings-theme"
          name="theme"
          label="Theme"
          options={[{"System", "system"}, {"Light", "light"}, {"Dark", "dark"}]}
          value="system"
          prompt="Pick a theme"
        />
        <.textarea
          id="settings-signature"
          name="signature"
          label="Review signature"
          value="Ship it."
          help_text="Appended to approvals you write."
        />
      </.stack>
      <:footer>
        <span>Saved yesterday</span>
        <.button size="sm" variant="solid">Save appearance</.button>
      </:footer>
    </.card>
  </.stack>
</.page_shell>
```

## Block 6: create/edit form with validation errors

**When to use:** The page creates or edits one record — a single card, an error summary on top, inline errors on the failing controls, and cancel/save in the footer.

```heex
<.page_shell id="ticket-new-shell" title="New ticket" breadcrumbs={@form_crumbs}>
  <.stack gap="lg" style="max-width: 760px; margin: 0 auto;">
    <.card title="Details" description="Small, sharp titles get picked up fastest.">
      <.stack gap="md">
        <.alert color="danger" title="2 problems need attention">
          Title can't be blank. Pick a status so the ticket lands in the right list.
        </.alert>
        <.input
          id="ticket-title"
          name="title"
          label="Title"
          placeholder="Visible progress ring"
          value=""
          errors={["can't be blank"]}
        />
        <.textarea
          id="ticket-body"
          name="body"
          label="Description"
          placeholder="What changes, and how will the reviewer see it?"
          value=""
          help_text="Markdown welcome. Screenshots beat paragraphs."
        />
        <.select
          native
          id="ticket-status"
          name="status"
          label="Status"
          options={[{"To do", "todo"}, {"In progress", "in_progress"}, {"Done", "done"}]}
          value=""
          prompt="Pick a status"
          errors={["can't be blank"]}
        />
      </.stack>
      <:footer>
        <.button size="sm" variant="ghost" navigate="/tickets">Cancel</.button>
        <.button size="sm" variant="solid">Create ticket</.button>
      </:footer>
    </.card>
  </.stack>
</.page_shell>
```

## Block 7: login page

**When to use:** The page signs someone in — a centered card, one primary action, SSO second, and a muted invite line. No app shell, no sidebar.

```heex
<div style="max-width: 400px; margin: 3rem auto 0;">
  <.card title="Welcome back" description="Sign in to your workspace.">
    <.stack gap="md">
      <div style="display: flex; align-items: center; gap: 0.5rem;">
        <.icon name="sparkles" />
        <span class="lui-brand-name">Acme</span>
      </div>
      <.input
        id="login-email"
        name="email"
        type="email"
        label="Email"
        placeholder="ada@acme.test"
        autocomplete="email"
      />
      <.input
        id="login-password"
        name="password"
        type="password"
        label="Password"
        placeholder="••••••••"
        autocomplete="current-password"
        errors={["is incorrect — try again or reset it"]}
      />
      <.button variant="solid" style="width: 100%;">Sign in</.button>
      <.separator text="or continue with" />
      <.button variant="outline" style="width: 100%;">Continue with SSO</.button>
    </.stack>
    <:footer>No account yet? Ask your workspace admin for an invite.</:footer>
  </.card>
</div>
```

## Block 8: confirm-destructive dialog plus empty/loading/error states

**When to use:** The page ends something — the danger card carries the trigger, an `alert_dialog` states the consequence, and the same page shows the empty, loading, and error states so none of them ships unstyled.

```heex
<.page_shell id="danger-shell" title="Danger zone" breadcrumbs={@shell_crumbs}>
  <.stack gap="lg" style="max-width: 1120px; margin: 0 auto;">
    <.card
      title="Delete workspace"
      description="Removes every ticket, inbox item, and invite. This cannot be undone."
    >
      <.button variant="solid" color="danger">Delete workspace…</.button>
    </.card>
    <.alert_dialog id="delete-workspace" open>
      <:title>Delete this workspace?</:title>
      <:description>
        Every ticket, inbox item, and invite goes with it. Type the workspace name to confirm.
      </:description>
      <:cancel><.button variant="outline">Cancel</.button></:cancel>
      <:action><.button variant="solid" color="danger">Delete workspace</.button></:action>
    </.alert_dialog>
    <.card_grid min="16rem">
      <.card title="Empty">
        <.empty_state icon="document" title="No tickets yet">
          Create the first one to get the list going.
          <:action><.button size="sm" variant="solid">New ticket</.button></:action>
        </.empty_state>
      </.card>
      <.card title="Loading">
        <.stack gap="sm">
          <.loading label="Loading tickets…" />
          <.skeleton style="height: 0.875rem;" />
          <.skeleton style="height: 0.875rem; width: 62%;" />
        </.stack>
      </.card>
      <.card title="Error">
        <.stack gap="sm">
          <.alert color="danger" title="Tickets didn't load">
            The request timed out. Check your connection and try again.
          </.alert>
          <div><.button size="sm" variant="outline">Retry</.button></div>
        </.stack>
      </.card>
    </.card_grid>
  </.stack>
</.page_shell>
```
