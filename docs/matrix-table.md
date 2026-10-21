# Matrix table

`use LanternUI` (or `use LanternUI, only: [:matrix_table]`) imports `matrix_table/1`,
`matrix_row/1` and `matrix_cell/1`. It is a fixed grid of states: rows are
environments, columns are components (apps and databases), every cell is one of
five states. The caller owns data, order, nesting and every write; there is no
JS, hook or motion.

| Piece | Contract |
|---|---|
| `matrix_table` | Required `caption` (screen readers) and `:col` slots (`kind` = quiet second line); optional `corner` heading for the pinned column. |
| `matrix_row` | Required `label`; `depth` indents fork children; optional `navigate`/`patch`/`href` on the row head; `:meta` slot for a quiet line (production, expiry, flags). |
| `matrix_cell` | `state` is `present`, `degraded`, `failed`, `in_rule` or `absent`; `label` replaces the default words; `navigate`/`patch`/`href` open what the cell names; `add_label` turns an absent cell into a native `+` button (`phx-*` pass through). |

```heex
<.matrix_table caption="Environments across components" corner="Environment">
  <:col kind="app">web</:col>
  <:col kind="database">primary</:col>
  <.matrix_row label="main" navigate={~p"/p/1/environments/main"}>
    <:meta>production</:meta>
    <.matrix_cell state="present" label="Ready" navigate={~p"/p/1/apps/9"} />
    <.matrix_cell state="in_rule" navigate={~p"/p/1/environments/main"} />
  </.matrix_row>
  <.matrix_row label="dev/maya" depth={1}>
    <.matrix_cell state="degraded" navigate={~p"/p/1/apps/12"} />
    <.matrix_cell state="absent" add_label="Add primary to dev/maya" phx-click="add" phx-value-env="maya" />
  </.matrix_row>
  <.table_placeholder_row colspan={3} icon="chevron-down" label="3 previews" phx-click="show_previews" />
</.matrix_table>
```

## Accessibility

- A real `table` with a caption, `th scope="col"` and `th scope="row"`; screen readers announce row and column for each cell.
- State is a dot **and** words. A custom `label` is followed by the state name for screen readers ("Deploy failed, failed"); dots are `aria-hidden`.
- A cell is a link **or** an add button, never nested. The add button's name is the full sentence ("Add web to dev/maya"). An absent cell without `add_label` has no control.
- Links and buttons are native tab stops; the first column is pinned (`position: sticky`) while the wrap scrolls horizontally, and the scroll-fade cue comes from the table wrap.
- Static, so identical under `prefers-reduced-motion`.

## Not here

Reversed axes, column groups or chooser, per-cell secrets/profile rows, a pool
row and a preview column are app decisions the project-show design dropped.
Overflow is a `table_placeholder_row` ("+N previews") in the body. Use
`data_table` for sortable records.

Runnable demo: `/matrix_table` on `MIX_ENV=test mix run --no-halt test/qa/server.exs`.
