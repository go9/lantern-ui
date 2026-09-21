# Dense-app primitives

Linear-shaped building blocks extracted from flicker tickets/suggestions/hub
(#1404 / #1407 / #1408). Styled by default with `--lantern-*` tokens. Register
the hooks bundle for `tabs_list` (`LanternTabs`; `LanternSegmented` still
works this release) and `side_panel_toggle`.

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
button. Rows with the same `group` hide client-side, including when they
sit in `data_table` `:list_item` wrappers — see [Behaviours](behaviours.md).
Match `data-lantern-persist` to the group key so the collapsed set survives
patches and reloads.

## Inspector rail

```heex
<.inspector aria-label="Ticket">
  <.inspector_section title="Properties">
    <.description_list layout="dense">
      <:item label="Repo">enventory_new</:item>
      <:item label="Status">{@status}</:item>
    </.description_list>
  </.inspector_section>
</.inspector>
```

## Icon button

```heex
<.button size="icon" label="Toggle panel" kbd="]">
  <.icon name="view-columns" />
</.button>
```

`label` is the accessible name. On `icon-*` sizes the control is wrapped in
`tooltip/1`; `kbd` is the optional hint in that tip.

## Segmented control

```heex
<.tabs_list id="scope" variant="segmented" size="sm" active_tab={@scope} aria-label="View">
  <:tab name="all" patch={~p"/tickets"}>All</:tab>
  <:tab name="active" patch={~p"/tickets?scope=active"}>Active</:tab>
  <:tab name="backlog" patch={~p"/tickets?scope=backlog"}>Backlog</:tab>
</.tabs_list>
```

Give the list an `id` so `LanternTabs` handles arrow-key activation. Pass
`role="radiogroup"` when there is no tab panel.

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
<.progress shape="ring" value={7} max={19} label="Completion">7 / 19</.progress>
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
that stays with the host until the build-pipeline ticket. The toggle is a
`button/1` with `label`/`kbd` plus the persist attrs.

## Deprecated in 0.8.2

Old names still render. They warn once per node and go away in 0.9.0.

| Deprecated | Use instead |
|---|---|
| `<.icon_button label="Filter" kbd="F">` | `<.button size="icon" label="Filter" kbd="F" variant="ghost">` |
| `<.progress_ring value={7} max={19}>` | `<.progress shape="ring" value={7} max={19}>` |
| `<.segmented id="scope" value={@scope}> <:segment>` | `<.tabs_list id="scope" variant="segmented" active_tab={@scope}> <:tab>` |
| `<.property_row label="Repo">` | `<.description_list layout="dense"> <:item label="Repo">` |

Copyable page compositions that use these primitives live in [Recipes](recipes.md).
