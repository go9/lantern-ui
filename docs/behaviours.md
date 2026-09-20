# Library behaviours

These ship in the hooks bundle and install themselves on import. No page-local
`phx-hook` and no extra `Hooks` entry. Markup is enough.

```js
import LanternHooks from "../../deps/lantern_ui/priv/static/lantern_ui_hooks.js"
```

Rebuild the bundle after editing `assets/js/` with `npm run build` and commit
`priv/static/lantern_ui_hooks.js`.

## List keyboard nav

`data-lantern-list-nav` on the list, `data-lantern-list-item` on each row.
While focus is inside the list: `j` / `ArrowDown` and `k` / `ArrowUp` move a
roving tabindex, `Home` / `End` jump, `Enter` activates the item's own link
(or clicks the item). The focused row gets a visible ring.

```heex
<ul data-lantern-list-nav>
  <li :for={row <- @rows} data-lantern-list-item>
    <.link navigate={~p"/tickets/#{row}"}>{row.title}</.link>
  </li>
</ul>
```

Do not bind `j`/`k` on a typing target (`input`, `textarea`, `select`,
`contenteditable`) — those keys stay characters there.

Enter on a focused `data-lantern-list-item` activates that item. Enter
elsewhere inside the list (a group-band collapse button) is left alone.

## Group collapse

`data-lantern-collapse="<key>"` on the band's control (a `<button>`). Click,
Enter, or Space toggles `data-collapsed` on the closest `.lui-group-band` and
the `hidden` attribute on every element in the same parent that carries
`data-lantern-group="<key>"`. `aria-expanded` tracks the open state.

`group_band` with `group=` (and no `navigate`/`patch`/`href`) wires the
button. `list_row` with `group=` sets `data-lantern-group`. Any sibling may
carry that attribute — it is not list-row-only.

```heex
<div>
  <.group_band name="In progress" count={2} group="tickets:in_progress">
    <:glyph><.status_glyph status={:in_progress} /></:glyph>
  </.group_band>
  <.list_row group="tickets:in_progress" title={ticket.title} navigate={ticket.href} />
</div>
```

The collapsed set is remembered in memory so a LiveView morph re-applies it
(same MutationObserver restore as persist). To also survive a full reload,
put `data-lantern-persist` on the band with **the same key**:

```heex
<.group_band
  name="In progress"
  group="tickets:in_progress"
  data-lantern-persist="tickets:in_progress"
>
```

That writes `lantern:persist:tickets:in_progress` as `open` / `closed`. Do
not also put `data-lantern-persist-toggle` on the collapse button — collapse
is the writer for this key. Namespace keys per page (`tickets:done` vs
`runs:done`) so two lists do not share a collapsed set.

The chevron stays the server-rendered down icon; CSS rotates
`.lui-group-band[data-collapsed] .lui-group-band-main[data-lantern-collapse] .lui-group-band-chevron`
so a client toggle does not need a re-render.

## Persist open/collapsed

`data-lantern-persist="<key>"` stores `open` / `closed` in `localStorage`
(`lantern:persist:<key>`). Failures (quota, private mode) are ignored.

On a `<details>`:

```heex
<details data-lantern-persist="hub:filters">
  <summary>Filters</summary>
  ...
</details>
```

On any other element, add a toggle (and optional panel):

```heex
<div data-lantern-persist="hub:side" data-open="true">
  <button type="button" data-lantern-persist-toggle aria-expanded="true">
    Inspector
  </button>
  <div data-lantern-persist-panel>
    ...
  </div>
</div>
```

`side_panel` in a consuming app can keep a temporary page-local hook until it
switches to this attribute. Same key space as group collapse; a group band
uses persist with the group key, and should not also carry
`data-lantern-persist-toggle`.

## Overlay placement

Popover, dropdown, select, menu, date picker, and autocomplete panels are
positioned with `@floating-ui/dom` (flip + shift), bundled into the hooks
file. Consumers do not add that dependency themselves.
