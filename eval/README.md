# lantern-ui AI-reliability eval (flicker #3415, step 1)

Measures first-pass page quality with and without lantern docs: ten realistic
page tasks (`tasks/`), each run under two conditions — **A**: Hex dep only,
**B**: with lantern docs/skills — scored by automatic checks (`checks.exs`,
see `rubric.md`) plus a headless-Chrome screenshot per page for human grading.

## How to (re)run

Prereqs: `claude` CLI, `mise` (Elixir via shims), Google Chrome, network
access to github.com. No database needed (demo boots DB-free; eval pages use
static data).

```bash
# Full baseline: 10 tasks x 2 conditions (slow: ~5 min per combo —
# model run + deps.get/compile + server boot + screenshot).
eval/run.sh

# Subsets:
eval/run.sh --task ticket-index --cond A
eval/run.sh --task ticket-index --cond B --model sonnet

# Re-score / re-screenshot an existing checkout without spending model quota:
eval/run.sh --task ticket-index --cond A --skip-model --skip-build --skip-shot
```

Each combo writes to `results/<task>-<cond>/`:

- `prompt.txt` — exact prompt the model got (brief + task + condition appendix;
  B also inlines the docs bundle).
- `demo/` — fresh `lantern-demo` checkout at `demo-pin.txt` + the model's diff.
- `run.log` — raw `claude -p` transcript tail.
- `changed.txt`, `score.txt` — model's files + automatic score.
- `build.log`, `server.log`, `shot.log`, `screenshot.png`.
- `score.json` — `{task, condition, model, demo_sha, auto, compile, screenshot}`.

`--skip-*` runs carry forward the previous `score.json` values they don't
recompute, so re-scoring never erases a proven compile/screenshot.

## Recording the baseline

After a full run, summarize `results/*/score.json` into
`results/baseline-<YYYY-MM-DD>.md` (one row per task x condition: auto/100,
compile, screenshot, human grades, notes) and commit the PNGs. Human grades
follow `rubric.md` and are filled in by hand.
