# Eval rubric (flicker #3415, step 1)

Each task × condition run gets two scores: an **automatic score** (0–100, from
`checks.exs` + `mix compile`, no human judgement) and a **human screenshot
grade** (1–5 per criterion, graded from the committed screenshot).

## Automatic checks (100 pts)

| Rule | Pts | What fails it |
|---|---|---|
| `no_group_band` | 20 | Any `group_band`, `GroupBand`, `group-band` (or equivalent tinted group-header markup) in new code. Banned design — zero tolerance. |
| `no_hand_table` | 15 | Raw `<table>` without a lantern `table`/`data_table`/`resource_list` covering the same content. |
| `no_hand_button` | 10 | Any raw `<button>` in new code (use `button`/`icon_button`/dialog actions). |
| `no_palette` | 10 | Hardcoded palette classes (`red-500`, `slate-200`, …) or hex-in-class (`bg-[#fff]`). 0 hits = 10, 1–2 = 5, 3+ = 0. |
| `no_arbitrary` | 10 | Arbitrary pixel values (`text-[11px]`, `w-[320px]`, …). Same 10/5/0 scale. |
| `lantern_usage` | 15 | Distinct lantern components used (`<.name` against the known inventory). ≥4 = 15, scaled linearly below. |
| `a11y` | 10 | Form inputs without an associated label (`<label` or `label=`), or `icon_button` without `aria-label`/`label`. |
| `deliverables` | 10 | Expected route strings + module names (from `manifest.json`) present in the diff. Scaled by fraction found. |

`mix compile` is recorded separately as **pass/fail** (it gates the screenshot:
no compile → no screenshot → human grade `n/a`). It is not part of the 100
because a compile failure already zeroes the run's value; the table shows it
as its own column.

Scope: checks scan **only files the model added/changed** (runner passes the
`git status --porcelain` list), never the pre-existing demo tree.

## Human screenshot grade (1–5 each, from the committed PNG)

1. **Layout** — page reads as the intended design (list/filter/detail/shell in
   the right places, no overflow at 1280px).
2. **Density** — looks like a dense dev-tool UI, not a marketing page
   (compact rows, restrained type, no giant hero spacing).
3. **Token fit** — colors/surfaces match the demo app's theme (no alien
   palette, readable contrast).
4. **Interaction affordance** — clickable/filterable/toggleable elements look
   interactive; states (empty/loading/error) are visibly distinct.
5. **No banned design** — human backstop for `no_group_band` (grouped look
   achieved without the literal component name).

## Baseline table

`results/baseline-<date>.md` holds one row per task × condition:
`task | cond | auto/100 | compile | screenshot | human grades | notes`.
The PNGs live next to it (`results/<task>-<cond>/screenshot.png`).
