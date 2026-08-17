---
name: lantern-ui-components
description: Author or modify components in LanternUI. Covers component anatomy, attrs and slots, IDs, tokens, hooks, accessibility contracts, registration, and tests. Use when adding, extending, porting, or reviewing a LanternUI component.
license: MIT
metadata:
  source: https://github.com/go9/lantern-ui
---

# Authoring LanternUI components

LanternUI is a runtime Phoenix LiveView component library. Consumers call `use LanternUI`; components stay server-rendered, use minimal JavaScript, and theme through `--lantern-*` CSS variables.

Code wins when this guide drifts. Fix guide and code together.

## Keep component small

1. Reuse an existing component or helper.
2. Preserve Fluxon-compatible names and primary attrs when an equivalent exists.
3. Add no runtime dependency for behavior Phoenix, LiveView, CSS, or existing helpers cover.
4. Keep app-specific policy in consuming app, not library.

## Component shape

```elixir
defmodule LanternUI.Components.Foo do
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def foo(assigns) do
    ~H"""
    <div class={Class.merge(["lui-foo", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
```

- File: `lib/lantern_ui/components/foo.ex`.
- Module: `LanternUI.Components.Foo`.
- Base class first, consumer `@class` last.
- Spread `@rest` last. Add `include:` for global attrs LiveView would otherwise reject.
- Render enums as `data-*`; do not build modifier-class matrices.

## Pick correct ID contract

| Need | Contract |
|---|---|
| Hook or caller addresses element | required stable `id` |
| Floating chrome nobody addresses | optional generated `id` |
| Form control | derive from form field |
| Pure presentation | no `id` |

Every hook root needs stable `id`. Child IDs derive from root: `#{@id}-panel`, `#{@id}-error`.

## CSS and tokens

- Use `lui-*` classes.
- Put styles in `priv/static/lantern_ui.css`.
- Use `--lantern-*` variables for every visual value.
- Use `data-variant`, `data-size`, `data-color`, `data-state`, and similar attrs for variants.
- No Tailwind dependency. No hardcoded product colors.

## Hooks

Write a hook only when CSS and LiveView cannot provide required client behavior.

- Name hooks `Lantern<Feature>`.
- Export hook from `priv/static/lantern_ui_hooks.js` and register it in `Hooks`.
- Match `phx-hook` name exactly.
- Use `data-part` as hook structure contract, not style contract.
- Reuse existing overlay behavior when keyboard and focus model match.
- Use `phx-update="ignore"` only when hook owns child DOM.

## Accessibility contract

Define before coding:

- semantic role
- accessible name
- state attributes
- ID references
- keyboard and focus model
- server-owned versus hook-owned attributes

Every `aria-controls`, `aria-labelledby`, and `aria-describedby` target must render in same component state. Icon-only controls need `aria-label`. Follow WAI-ARIA Authoring Practices for interaction patterns.

## Registration and silent failures

Check all five:

1. Component registered in `@components` in `lib/lantern_ui.ex`.
2. Hook exported and registered.
3. Hook root has stable `id`.
4. Styles use library tokens.
5. Slot attrs needed by overflow/fallback renderers live on slot, not only inner body.

`breadcrumb_bar` actions and data-table list actions may render visible and overflow copies. LiveView tests see both because they have no CSS engine. Select intended tier with stable `data-part` selector; do not delete fallback copy.

## Form controls

Handle `%Phoenix.HTML.FormField{}` first. Derive ID/name/value, gate errors through `used_input?`, translate errors with public form helper, then delegate to plain attr clause. Wire label, `aria-invalid`, error ID, and hidden unchecked/empty values.

## Tests

Use focused ExUnit component tests. Assert contracts, not snapshots:

- exported function/import registration
- `lui-*` root class and class merge
- `data-*` variants
- slots and passthrough attrs
- hook name and parts
- roles, states, labels, and ID references
- form wiring

Run:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

Update `CHANGELOG.md` for component behavior changes.
