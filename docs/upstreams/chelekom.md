# Upstream: Mishka Chelekom

Intake record + component gap/interactivity map for using **Mishka Chelekom** as
a *reference corpus and selective contribution target* for LanternUI — never as a
dependency, generator, or public API. See flicker ticket **#921**.

## Provenance

| Field | Value |
|---|---|
| Project | Mishka Chelekom |
| Source | https://github.com/mishka-group/mishka_chelekom · https://mishka.tools/chelekom |
| Pinned commit | `aacab393db69d571e0a3130d8d00251ef27d3210` |
| Inspected | 2026-07-15 |
| License | Apache-2.0 |
| NOTICE file | **None present** at the repo root at the pinned commit (root carries `LICENSE`, `CHANGELOG.md`, `SECURITY.md`, `MCP.md`). Re-verify at the exact commit before copying any source — an Apache NOTICE, if it ever exists, must be propagated. |
| Catalog size (at pin) | **74 styled components** + **35 headless primitives** (component modules under `development/lib/development_web/components/` and `.../components/headless/`; infra modules `core_components`, `layouts`, `mishka_components` excluded from the 74). |
| Maintained | 2026-07-15 (this record). Update the pin + re-run the NOTICE check on the next intake. |

> Enumerating Chelekom's **component names** (this doc's gap map) uses facts, not
> expression, and copies no Apache-licensed source. Component behavior contracts
> are taken from the **W3C WAI-ARIA APG**, which specifies ARIA/keyboard behavior
> independently of Chelekom.

## LanternUI vs Chelekom — delivery & compatibility

| Axis | Chelekom | LanternUI |
|---|---|---|
| Delivery | Code **generator** — copies component `.ex` files into the host app | **Runtime Hex dependency** — `use LanternUI` imports function components |
| Ownership | Host owns generated snapshots; re-runs overwrite | Library owns the components; consumers upgrade the dep |
| Styling | Tailwind utility classes baked into markup | `lui-*` classes + `--lantern-*` CSS variables, **no Tailwind, no build step** |
| Theming | Tailwind config / class variants | CSS-variable tokens, bridged onto a host (Fluxon) design system |
| API shape | Chelekom's own attrs/slots | **Fluxon-compatible** where applicable (drop-in `use Fluxon` → `use LanternUI`) |
| JS | Per-component hooks, declared per generated file | One namespaced hook bundle (`Lantern*`), reused (`LanternOverlay`, `trapFocus`, `position`) |
| Floors | its own | Elixir `~> 1.15`, LiveView `~> 1.0`, **no new runtime deps** |

The two systems disagree on the two things Lantern cares most about — **API surface**
and **CSS/theming** — so any Chelekom component would be reshaped on both axes before
it fit. That reshaping, not the behavior, is where the cost lives (see the verdict).

## Intake rules (borrow / adapt / contribute / reject)

- **Borrow (ideas, always safe):** the component catalog + gap analysis; headless
  *anatomy* (named parts, semantic state attrs, keyboard/focus contracts, the APG
  references); explicit per-component JS-hook dependency declarations; (later)
  metadata-driven docs and MCP discovery as Lantern-owned capabilities.
- **Adapt (expression, gated):** only after (a) real Lantern consumer / Fluxon-migration
  demand, (b) API stays Lantern-native + Fluxon-compatible, (c) styling is `lui-*` +
  `--lantern-*`, (d) the Elixir/LiveView floors hold, (e) a11y is independently tested,
  and (f) any copied/derived expression carries **pinned provenance + full Apache-2.0
  treatment** (source commit + path, attribution, modified-file marks, license file,
  NOTICE propagation *only if one exists at the pin*, and notices **verified in the
  built Hex tarball** via `mix hex.build`).
- **Contribute upstream:** send back generally-useful fixes (a11y, LiveView patch
  behavior, focus/overlay engines, generator idempotency, catalog validation) that
  don't encode Lantern-specific API or styling.
- **Reject:** adding `mishka_chelekom` as a dep; running its generators over Lantern;
  forking; bulk-porting the catalog; importing marketing/decorative components with no
  portfolio demand.

## Pre-registered decision threshold (written BEFORE the spike)

The accordion spike measures **actual adaptation effort** vs a **clean-room estimate
for the same component**, and reports a verdict against this bar, fixed in advance so
it can't be rationalized afterward:

- **GO** — adapting Chelekom source costs **≤ ~60%** of the clean-room estimate on the
  expensive axes (API reshape, Tailwind→token CSS, hook reconciliation, a11y re-test).
  Harvesting selected headless primitives then saves meaningful time.
- **REFERENCE-ONLY** — adaptation needs so much rewriting (**> ~60%**) that copying adds
  little; use Chelekom + the APG as *spec only* and implement clean-room.
- **HYBRID** — harvest specific **behavior engines/primitives** (focus trap, overlay
  positioner, slider/menu controllers) where they're non-trivial and not fully pinned
  by APG prose; independently implement the simpler components.

Copyright protects **expression, not behavior**. Because accordion behavior is fully
specified by the public WAI-ARIA APG, a clean-room result was reachable — and taken
(see `## Spike result`).

## Interactivity classes

- **no-JS** — pure server render + CSS.
- **simple-hook** — one small client behavior (toggle, copy, observe), reusable overlay
  patterns apply.
- **complex-hook** — focus trap, roving keyboard model, drag, or overlay positioning.

## Gap map — headless primitives (the behavior-harvest candidates)

Disposition · interactivity · portfolio demand. Lantern coverage noted.

| Chelekom headless | Disposition | Interactivity | Demand | Lantern coverage |
|---|---|---|---|---|
| accordion | **already-covered (this spike, #921)** | simple-hook | medium | `LanternUI.Components.Accordion` (clean-room) |
| dialog | already-covered | complex-hook | — | `modal`, `sheet` (+ `trapFocus`) |
| alert_dialog | study-behavior-only | complex-hook | medium | `modal` variant; confirm semantics gap |
| drawer | already-covered | complex-hook | — | `sheet` |
| popover | already-covered | simple-hook | — | `popover` (+ `LanternOverlay`) |
| tooltip | already-covered | simple-hook | — | `tooltip` |
| combobox | study-behavior-only | complex-hook | medium | `select`, `autocomplete` — study for keyboard gaps |
| select | already-covered | complex-hook | — | `select` (`LanternSelect`) |
| autocomplete | already-covered | complex-hook | — | `autocomplete` |
| checkbox / checkbox_group | already-covered / study group | no-JS | low | `checkbox` (+ form) |
| radio / radio_group | already-covered | no-JS | — | `radio` |
| switch / toggle | already-covered | no-JS | — | `switch` |
| toggle_group | study-behavior-only | simple-hook | low | segmented `tabs` overlap |
| tabs | already-covered | simple-hook | — | `tabs` |
| collapsible | already-covered | simple-hook | — | `LanternCollapse` (sidebar/section) |
| separator | already-covered | no-JS | — | `separator` |
| progress | already-covered | no-JS | — | `progress` |
| field / fieldset | already-covered | no-JS | — | `form` |
| number_field | already-covered | simple-hook | — | `datetime_field`/form (spinbutton) |
| **menu / menubar** | **independently-implement** | complex-hook | **medium** | not covered — roving menu keyboard model is a real gap vs `dropdown` |
| **slider** | **independently-implement** | complex-hook | **medium** | not covered — drag + arrow-key value model |
| **scroll_area** | **independently-implement** | simple-hook | **medium** | not covered — custom scrollbar/observer |
| **meter** | **independently-implement** | no-JS | **medium** | not covered — semantic meter vs `progress` |
| otp_field | independently-implement | simple-hook | low | not covered |
| context_menu | independently-implement | complex-hook | low | not covered |
| navigation_menu | study-behavior-only | complex-hook | low | `navlist` partial |
| preview_card | independently-implement | simple-hook | low | not covered (hovercard) |
| toolbar | independently-implement | complex-hook | low | not covered |
| avatar | independently-implement | no-JS | low | not covered |
| toast | already-covered | simple-hook | — | `toast` |

## Gap map — styled components (coverage summary)

Most styled Chelekom components map to an existing Lantern component or to the
headless row above. The ones **not** covered and worth tracking by demand:

| Not covered (styled) | Disposition | Interactivity | Demand |
|---|---|---|---|
| skeleton | independently-implement | no-JS | medium (content placeholders recur; was the v1 pilot) |
| file_field | independently-implement | simple-hook | medium (uploads) |
| card | independently-implement | no-JS | medium (ubiquitous surface) |
| stat | independently-implement | no-JS | low–medium (dashboards) |
| range_field | independently-implement | complex-hook | medium (= slider) |
| rating, stepper, timeline, indicator, clipboard, keyboard, blockquote, gallery, footer, speed_dial, carousel, mega_menu, dock | independently-implement | no-JS / simple / complex | low |
| chat, jumbotron, device_mockup, image, video, shape, typography, table_content | reject | — | none (app-specific / marketing / decorative) |

Already-covered styled components (no action): accordion, alert, badge, breadcrumb,
button, checkbox_field, collapse, color_field, combobox, date_time_field, divider,
drawer, dropdown, email_field, fieldset, form_wrapper, icon, input_field, list, modal,
native_select, navbar, number_field, overlay, pagination, password_field, popover,
progress, radio_field, search_field, sidebar, spinner, table, tabs, tel_field,
text_field, textarea_field, toast, toggle_field, tooltip, url_field.

## Spike result (accordion, #921)

- **Classification: Clean-room.** `LanternUI.Components.Accordion` + the
  `LanternAccordion` hook were implemented from the **WAI-ARIA APG Accordion pattern**;
  no Chelekom source was read or copied (only the factual component-name catalog above
  was enumerated). **No Apache attribution owed.**
- **Effort (measured):** ~2–3 h for component + hook + `lui-accordion` CSS + tests +
  this doc. A **clean-room estimate for the same component** is the same ~2–3 h — because
  the expensive axes (Lantern-native API, `--lantern-*` CSS, a hook matching the
  library's `LanternOverlay`/`LanternCollapse` patterns + the ARIA conformance gate,
  independent a11y tests) are Lantern-specific work that copying Chelekom's headless
  source does **not** shorten. Adapt ÷ clean-room ≈ **1.0**, above the ~0.6 GO bar.
- **Verdict: REFERENCE-ONLY** (with **HYBRID** reserved for the handful of complex
  behavior *engines*). For components whose behavior the APG fully specifies — accordion,
  tabs, disclosure, dialog, tooltip, switch — copying Chelekom clears none of Lantern's
  API/CSS/hook/a11y bars, and the pure-MIT constraint plus clean-room reachability means
  there is no licensing upside to adapting expression either. Use Chelekom as a **catalog
  + ARIA/keyboard checklist**, implement clean-room. Reach for HYBRID only where a
  non-trivial engine (slider drag, roving menu/menubar, overlay positioning) is worth
  harvesting the *algorithm* — and even then Lantern already ships `trapFocus`/`position`,
  so most of these collapse back to REFERENCE-ONLY.
- **Effort band for future candidates:**
  - no-JS / CSS-only (skeleton, avatar, stat, card, meter, timeline): ~0.5–1 h.
  - simple-hook (rating, otp_field, scroll_area, file_field, clipboard, stepper): ~2–4 h.
  - complex-hook (menu/menubar, slider/range, context_menu, carousel, toolbar): ~4–8 h;
    reuse `LanternOverlay`/`trapFocus`/`position` to stay at the low end.

## Next candidates (separate tickets, demand-first — not this ticket)

Prioritize by **portfolio demand, not catalog size**: `menu`/`menubar` (roving keyboard
model — a genuine gap vs `dropdown`), `slider`/`range_field`, `scroll_area`, `meter`,
and `skeleton` (CSS-only, cheap). Each gets its own ticket with the render + keyboard +
LiveView-patch + a11y gate. Defer any Lantern-owned generator/MCP tooling until repeated
component work proves it removes real duplication.
