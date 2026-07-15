# Spec: backfill attr/slot `doc:` strings across lantern_ui components

## Objective

Add a `doc:` description to every `attr(...)` and `slot ... do`/`slot(...)`
declaration in `lib/lantern_ui/components/*.ex` (and `lib/lantern_ui/charts.ex`)
that lacks one. These power the demo's API-reference table AND hexdocs. Purely
additive — do NOT change any attr/slot name, type, default, values, or the
component logic. Only add `doc:` (and, for `slot ... do` blocks, a `doc:` on the
inner attrs too).

## Rules for good descriptions

- **Describe the effect, not the name.** Say what the attr DOES to rendering or
  behavior. Read the component body to get it right.
  - GOOD: `attr(:variant, :string, ..., doc: "Surface style: solid fills, outline is bordered, ghost is transparent.")`
  - BAD (restates name): `doc: "The variant of the button."`
- **Concise** — one line, roughly 6–14 words, no trailing period required but fine.
- **Accurate to THIS component.** e.g. on `select`, `multiple` → "Allow choosing
  several options; submits one hidden name[] input each." Not a generic guess.
- **Standard attrs get standard short docs** (use these consistently):
  - `:id` → "Stable DOM id (state is persisted per id)." OR just "Element id." if no persistence.
  - `:class` → "Extra classes merged onto the root element."
  - `:rest` (`:global`) → "Arbitrary HTML/`phx-*` attributes passed through."
  - `:field` (Phoenix.HTML.FormField) → "Form field; derives id, name, value, and errors."
  - `:disabled` → "Render disabled and non-interactive."
- For enum attrs (with `values:`), the doc can note the default/meaning, not
  re-list the values (the table shows them).
- Don't touch attrs that ALREADY have a `doc:` — leave them exactly as-is.
- Match the file's existing formatting: single-line `attr(:x, :type, doc: "…")`
  when short; multi-line when the line would exceed ~98 cols (mix format will
  reflow — run it).

## Slots

For each `slot :name do ... end` and `slot(:name)`, add `doc:`. If a slot block
has inner `attr(...)` entries, give those a `doc:` too (same rules).

## Files

All of `lib/lantern_ui/components/*.ex` plus `lib/lantern_ui/charts.ex`.
~354 attrs currently lack docs. Work through every file.

## Constraints (MANDATORY)

- Additive only: never alter a name/type/default/values or any rendering code.
- One `alias`/style per the file's existing convention.
- `mix format` ONLY the files you changed (list them explicitly). Never bare
  `mix format`.

## Verification (run; all must pass)

    mix deps.get
    mix compile --warnings-as-errors
    mix test
    mix format --check-formatted <the files you changed>

Do not commit.
