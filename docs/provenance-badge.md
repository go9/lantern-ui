# Provenance badge

`use LanternUI` imports `provenance_badge/1`. The badge shares Lantern's existing
neutral badge style. Its words carry the state in both themes.

```heex
<.provenance_badge state="own" />
<.provenance_badge state="inherited" source="Production" />
<.provenance_badge state="override" source="Production">
  <:revert>
    <.button id="revert-api" size="xs" variant="ghost" phx-click="revert_branch"
      phx-value-id="api" label="Revert API branch to Production">Revert</.button>
  </:revert>
</.provenance_badge>
<.provenance_badge state="current" />
<.provenance_badge state="historical" />
<.provenance_badge />
```

`state` accepts `own`, `inherited`, `override`, `current`, `historical`, `unknown`.
It defaults to `unknown`; nil or unrecognized runtime values also render **Unknown**.
Historical renders **Historical (superseded)** and must stay visible in retrieval
results. The caller passes the server-authored state; the component infers nothing
from timestamps or confidence.

`source` is an optional parent name for inherited and override states. Pass the
actual parent whenever known: **Inherited from Production** / **Override of
Production**. Other states ignore it. `class` and global HTML/`phx-*` attributes
pass to the root. There is no content slot that could hide or replace the state.

The optional `:revert` slot renders only for `override`. Supply a native button
with a contextual accessible name and a stable id when rows move. The caller owns
the event, authorization, confirmation and focus when the button disappears.
This remains a label and one action beside the existing editor.

The label is plain text, with no status live region, tooltip, tab stop or ARIA
state to synchronize. Native buttons support Tab, Enter and Space. No JS or motion
is added; reduced motion needs no alternate implementation.

The runnable demo is `test/qa/provenance_live.ex` at `/provenance` in the QA host:

```sh
MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs
BASE=http://127.0.0.1:4013 CHROME_PATH=/usr/bin/chromium node test/qa/provenance.mjs
```

Consumers: environment entity Source cells (including branch overrides), project
and environment profile assignments, and Suggestions' Triaged retrieval evidence.
Origin and temporal states share the same presentation; callers choose the
appropriate state for each use.

Deliberately omitted: an inheritance resolver, editor, source navigation, evidence
viewer, timestamps, replacement graph, color/size/variant options and JS hooks.
