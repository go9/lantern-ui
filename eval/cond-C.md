# Condition C — full lantern pack (docs + llms.txt + agent rules + block recipes + lint)

You have everything lantern ships for AI-assisted UI work, inlined below by
the runner. Use all of it:

- The condition-B docs bundle (recipes, dense-app primitives, type/grey
  scale, behaviours) plus the `lantern-recipes` skill — **copy the recipe
  HEEx instead of inventing your own markup** wherever a recipe fits.
- `llms.txt` — the component catalog and rules reference.
- `priv/AGENTS.md` — the agent-rules template (banned patterns, tokens,
  page layout, starters). Treat it as binding.
- `docs/recipes.md` page blocks (`app_shell`, `dashboard`, `index`,
  `detail`, `settings`, `form`, `destructive`): when the task matches a
  block, copy the block's structure (breadcrumb-bar title/actions, flat
  list with status column + chips, stack spacing) instead of composing
  your own layout.

Before finishing you MUST run `mix lantern.lint` on your new code and fix
every finding until it reports 0 findings. The lint ships inside the
`lantern_ui` Hex package — no extra dependency needed. The demo tree has a
few pre-existing findings in files you did not touch — fix only findings in
YOUR files and ignore the rest. A run with lint findings still on the board
in your own files fails the task, even if it compiles. Verify with
`mix compile` as well. Leave the server stopped.

The runner appends these files after this appendix:

- `docs/recipes.md` + `skills/lantern-recipes/SKILL.md`
- `docs/dense-app.md`, `docs/scale.md`, `docs/behaviours.md`
- `llms.txt`
- `priv/AGENTS.md`
