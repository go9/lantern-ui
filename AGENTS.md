# lantern-ui — contributor and agent guide

LanternUI is a Phoenix LiveView component library (HEEx components, server-rendered
SVG charts, small JS hooks). It is published to Hex as `lantern_ui`. Consumers read
`llms.txt` / `priv/AGENTS.md`; this file is for people and agents working **on** the
library.

## Layout

- `lib/lantern_ui/components/*.ex` — one module per component. `lib/lantern_ui.ex` is the registry (`use LanternUI`).
- `assets/js/lantern_ui_hooks.js` and `assets/js/zag/*` — hooks. `priv/static/` holds the **committed** bundles; rebuild with `npm run build` and commit them.
- `priv/static/lantern_ui.css`, `lantern_ui_theme.css` — all styling (`lui-*` classes, `--lantern-*` tokens).
- `docs/` — recipes, behaviours, scale. `skills/` — agent skills for consumers. `eval/` — the AI-reliability eval harness.
- `test/` — ExUnit; `test/js/` — jsdom hook tests (`npm test`).

## Commands

```bash
mix deps.get && npm ci
mix test                              # ExUnit
npm test                              # JS hook tests
mix format --check-formatted          # CI runs Elixir 1.19 / OTP 28; older Elixir formats HEEx differently
mix lantern.lint                      # banned patterns / unknown components
mix lantern.llms --check              # llms.txt must be regenerated when component docs change
npm run build                         # rebuild committed bundles
# floating-panel matrix (needs Chrome + puppeteer-core): see header of test/qa/run.mjs
# MIX_ENV=test PORT=4013 mix run test/qa/server.exs & ; BASE=http://127.0.0.1:4013 node test/qa/run.mjs
```

## Rules

- Public attrs are API. Add, don't rename; deprecate before removing and note it in `CHANGELOG.md`.
- Style with `lui-*` classes and `--lantern-*` tokens. No hardcoded colours, no arbitrary pixel values.
- Grouped lists / group headers are banned. Lists are flat: a status column on each row, filter chips with counts.
- Hooks must be safe to destroy at any time (`destroyed()` runs on every LiveView redirect, even if `mounted()` returned early).
- Server-rendered `hidden` / `aria-*` state must be owned by exactly one side (server or hook); test visibility, not only internal state.
- Every behaviour change needs a test; UI changes need a screenshot.
- Keep it small: reuse before adding, delete before extending.

## Releasing

Version in `mix.exs`, dated section in `CHANGELOG.md`, then the maintainer runs `mix hex.publish` and tags `vX.Y.Z`. Agents prepare the release PR but never publish.
