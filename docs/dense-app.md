# Dense-app primitives

Linear-shaped building blocks extracted from flicker tickets/suggestions/hub
(#1404 / #1407 / #1408). Styled by default with `--lantern-*` tokens. Register
the hooks bundle for `segmented` and `side_panel_toggle`.

## List row

```heex
<.list_row
  identifier="#241"
  title="Visible progress ring"
  parent="Dense primitives"
  navigate={~p"/tickets/241"}
>
  <:leading><.status_glyph status={:in_progress} /></:leading>
  <:meta><.badge size="sm">ui</.badge></:meta>
  <:trailing>Sep 3</:trailing>
</.list_row>
```

## Group band

```heex
<.group_band
  name="In progress"
  count={12}
  group="tickets:in_progress"
  data-lantern-persist="tickets:in_progress"
>
  <:glyph><.status_glyph status={:in_progress} /></:glyph>
  <:action navigate={~p"/tickets/new?status=in_progress"} label="New ticket in In progress">
    <.icon name="plus" />
  </:action>
</.group_band>
<.list_row group="tickets:in_progress" identifier="#241" title="Visible progress ring" navigate={~p"/tickets/241"} />
```

`group` (with no `navigate`/`patch`/`href`) makes the name row a collapse
button. Rows (or any sibling) with the same `group` hide client-side. Match
`data-lantern-persist` to the group key so the collapsed set survives
patches and reloads — see [Behaviours](behaviours.md).

## Inspector rail

```heex
<.inspector aria-label="Ticket">
  <.inspector_section title="Properties">
    <.property_row label="Repo">enventory_new</.property_row>
    <.property_row label="Status">{@status}</.property_row>
  </.inspector_section>
</.inspector>
```

## Icon button

```heex
<.icon_button label="Toggle panel" kbd="]">
  <.icon name="view-columns" />
</.icon_button>
```

## Segmented control

```heex
<.segmented id="scope" value={@scope} label="View">
  <:segment value="all" patch={~p"/tickets"}>All</:segment>
  <:segment value="active" patch={~p"/tickets?scope=active"}>Active</:segment>
  <:segment value="backlog" patch={~p"/tickets?scope=backlog"}>Backlog</:segment>
</.segmented>
```

## State glyphs

```heex
<.status_glyph status={:in_progress} />
<.priority_glyph priority={:high} />
<.run_glyph state={:verifying} />
<.sync_glyph state={:live} />
<.source_glyph source={:repo} />
<.state_glyph kind="status" value="cancelled" />
<.state_glyph kind="priority" value="none" />
<.state_glyph kind="run" value="claiming_env" />
<.state_glyph kind="sync" value="empty" />
<.state_glyph kind="source" value="ticket_memory" />
```

`:selected_for_dev` draws the same empty ring as `:todo`. Run states are
`queued`, `claiming_env`, `running`, `verifying`, `passed`, `failed`,
`blocked`. Sync states are `syncing`, `live`, `failed`, `empty`. Source
kinds are `repo`, `doc`, `ticket_memory`, `upload`.

## Progress ring

```heex
<.progress_ring value={7} max={19} label="Completion">7 / 19</.progress_ring>
```

`completed`/`scope` is the flicker-shaped alias of `value`/`max`. The track uses
`--lantern-border-strong` and the value stroke is thicker, so 7/19 is visible.

## Side panel

```heex
<.side_panel_toggle
  id="tickets-panel-toggle"
  panel_id="tickets-panel"
  panel_key="tickets"
  open={@panel_open}
  phx-click="toggle_panel"
/>

<.side_panel id="tickets-panel" open={@panel_open} aria-label="Project panel">
  <.inspector>…</.inspector>
</.side_panel>
```

Handle `set_panel` (`%{"open" => bool}`) to apply the stored preference. The
toggle defaults open at ≥1280px when `localStorage` is empty. Not resizable —
that stays with the host until the build-pipeline ticket.

Copyable page compositions that use these primitives live in [Recipes](recipes.md).
