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

Enter on a focused `data-lantern-list-item` activates that item.

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
switches to this attribute.

## Overlay placement

Popover, dropdown, select, menu, date picker, and autocomplete panels are
positioned with `@floating-ui/dom` (flip + shift), bundled into the hooks
file. Consumers do not add that dependency themselves.

## On-demand Zag chunk (app build setup)

Zag-driven widgets each run a `@zag-js/*` machine that ships as
`priv/static/zag/<name>.js` — committed, minified, loaded only when a page
mounts a `data-zag` root. One entry per widget: `select`, `tooltip`,
`popover`, `switch`, `radio_group`, `dialog` (modal + alert_dialog),
`sheet`, `menu` (dropdown + menu), `accordion`, `slider`, `tabs`,
`pagination`. Shared code (Zag runtime,
`@floating-ui/dom`) lives in `priv/static/chunks/`, imported by the main
bundle and the entries — never duplicated. But an app only gets the
on-demand behaviour if its own esbuild emits the dynamic `import()` as a
separate chunk. With the default `iife` format esbuild inlines it: a
minified app.js goes ~74KB → ~180KB for one widget, on every page.
Verified against a scratch copy of the foodfeed esbuild setup (proof
script kept out of the repo; static + jsdom-runtime checked): `iife`
inlines, `esm` + `splitting` emits `app.js` + `chunks/` with zero Zag
code in `app.js`, the chunk fetched only on `data-zag` pages (legacy
pages work with the chunk file deleted).

Per app, two lines (no new dependency, no `Plug.Static` change —
`priv/static` is already served, chunks land beside `app.js`):

1. `config/config.exs`, esbuild args: add `--format=esm --splitting`.
   flicker/skusync also want `--target=es2020` or newer (they pin `es2017`,
   which predates dynamic `import()`; foodfeed/goprint_registry already set
   `es2022`).
2. `root.html.heex`: `type="text/javascript"` → `type="module"` on the
   `app.js` script tag (`defer` is then redundant — modules defer by
   default — but harmless to keep).

| App | esbuild today | Change |
|---|---|---|
| flicker | iife, es2017, `assets/app.js` | +`--format=esm --splitting`, target → es2020+, script `type="module"` |
| foodfeed | iife, es2022, `assets/js/app.js` | +`--format=esm --splitting`, script `type="module"` |
| skusync | iife, es2017, `assets/app.js` | same as flicker |
| goprint_registry | iife, es2022, `assets/app.js` | +`--format=esm --splitting`, script `type="module"` |

Fallback: `priv/static/lantern_ui_hooks.standalone.js` is the same code as
a single file with the Zag runtime inlined (~340KB raw / ~95KB gzip
minified, versus ~68KB / ~17KB for the main bundle without Zag; each
widget entry adds ~7–35KB raw / ~3–10KB gzip on the pages that mount it,
shared chunks cached). Take it only when the app cannot serve ESM —
every iife consumer pays the Zag bytes on every page whether or not it
renders a Zag widget.

## Action bar promotion

`action_bar/1` and `page_shell/1` render every action twice: an inline button and
an item in the "More" menu. `LanternActionBar` runs on the bar root. It writes
`data-promoted="3"`, `"2"`, or `"1"` from the bar's width (above 1100px, 740–1100px,
and below 740px). CSS hides the inline copies past that count. The hook never
moves DOM nodes, so LiveView patches stay safe, and the menu always lists every
action.

Dismissing a notice sends `on_dismiss` with the notice `id` as `phx-value-id`. The
server owns that state and sets `dismissed`. Without `on_dismiss`, the hook keeps
the dismissal in localStorage and re-applies it in `updated()`. `destroyed()`
removes the listeners and observers, so the hook is safe to tear down on any
redirect.

```heex
<.page_shell
  id="tickets-shell"
  title="Tickets"
  breadcrumbs={@crumbs}
  actions={@actions}
  notice={@notice}
  dismissed={@notice_dismissed}
  on_dismiss="dismiss_notice"
>
  ...
</.page_shell>
```
