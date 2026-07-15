# Spec: navlist family + loading (Fluxon v2 parity, hookless)

## Objective

Add two components to lantern_ui mirroring Fluxon v2's public API so consumer
call sites swap with `use Fluxon` -> `use LanternUI`. Both are server-render +
CSS only (NO JS hooks). Study existing files first
(lib/lantern_ui/components/badge.ex for attr/data-attr style,
lib/lantern_ui/components/layout.ex for nav_item/nav_group — reuse its nav CSS
patterns, and separator.ex). Match the repo's exact style: `attr(...)` with
parens, one alias per line, `Class.merge`, `doc:` on every attr/slot (concise,
behavior-describing).

## 1. navlist / navheading / navlink  (module LanternUI.Components.Navlist)

Fluxon API to mirror:
- `navlist/1` — attrs: `heading` (:string, optional — renders a navheading at
  top when given), `class`, `rest` (:global). slot `inner_block` required
  (the navlinks). Renders `<nav class="lui-navlist">` with an optional
  `<div class="lui-navlist-heading">{heading}</div>` then the inner_block.
- `navheading/1` — attrs: `class`, `rest`. slot `inner_block` required.
  Renders `<div class="lui-navlist-heading">`.
- `navlink/1` — attrs: `active` (:boolean, default false), `navigate`, `patch`,
  `href` (:string, default nil), `class`, `rest` (:global, include
  ~w(phx-click phx-value-id phx-target method)). slot `inner_block` required.
  Renders a `<.link>` when navigate/patch/href given, else a `<button>` — class
  `lui-navlink` (+ `lui-navlink-active` when active), `aria-current={@active && "page"}`.
  Support an optional leading `icon` attr (:string, default nil) rendering
  `<Icon.icon name={@icon} class="lui-navlink-icon" />` before the inner_block.

Register in lib/lantern_ui.ex @components: `navlist: LanternUI.Components.Navlist`.

## 2. loading  (module LanternUI.Components.Loading, fn loading/1)

Fluxon API: attrs `variant` (:string, default "ring", values
~w(ring dots-bounce dots-fade dots-scale)), `size` (:string, default "md",
values ~w(xs sm md lg xl)), `class`, `rest` (:global), `label` (:string,
default "Loading" — for aria-label / sr-only text).
- Render `<span class="lui-loading" data-variant role="status" aria-label>` with
  an sr-only `<span class="lui-sr-only">{@label}</span>`.
- `ring`: an SVG or bordered-circle CSS spinner that rotates (border trick:
  `border` with one side accent, `animation: lui-spin 0.6s linear infinite`).
- `dots-bounce` / `dots-fade` / `dots-scale`: three `<span class="lui-loading-dot">`
  with staggered `animation-delay`, animating translateY / opacity / scale
  respectively.
- Size scales the ring diameter / dot size via `data-size` (xs ~0.75rem …
  xl ~2rem). Color = `currentColor` so it inherits (accent where placed).
- Honor `@media (prefers-reduced-motion: reduce)` — freeze animations.

## CSS

Append to priv/static/lantern_ui.css under banner comments, namespaced `lui-*`,
token-based (--lantern-accent, --lantern-fg-muted, --lantern-border,
--lantern-radius-sm, --lantern-duration, --lantern-text-sm). Add a `.lui-sr-only`
utility if not present (clip/absolute/1px). navlink styling should match the
look of `.lui-nav-item` in the existing CSS (reuse its visual language:
padding, radius, hover surface-sunken, active = accent-soft bg + accent text).

## Tests

Add test/lantern_ui/navlist_loading_test.exs — render tests:
- navlist with heading renders the heading + inner links; navlink with
  navigate renders a link with aria-current when active; navlink without
  navigate/href renders a button; icon renders when given.
- loading renders each variant's data-variant + role="status" + sr-only label;
  size sets data-size.
Update test/lantern_ui/components_test.exs — the sorted registry key assertion
gains `:loading` and `:navlist` in sorted position.

## Constraints (MANDATORY)

- Server-render + CSS only. No phx-hook, no JS.
- Additive; don't modify other components.
- `mix format` ONLY the files you changed (list them). Never bare `mix format`.

## Verification (run; all pass)

    mix deps.get
    mix compile --warnings-as-errors
    mix test
    mix format --check-formatted <changed files>

Do not commit.
