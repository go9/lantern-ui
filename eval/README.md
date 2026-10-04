# lantern-ui AI reliability eval

Round 1 established the original baseline. Round 2 adds eight harder tasks and a third guidance condition; the round-two report and screenshot gallery are [here](results/round2-2026-10-03.md) and [here](gallery-round2.html).

## Conditions

- **A:** dependency only.
- **B:** dependency plus lantern docs and recipes skill bundle.
- **C:** B plus `llms.txt`, `priv/AGENTS.md`, recipe blocks, and a required `mix lantern.lint` instruction.

The model is `claude -p --model sonnet`. Round 2 uses the demo skeleton commit in `demo-pin.txt` and lantern-ui git commit `1d5d4e02a950d9631fbfa008c13cf1d369ac113a`, recorded in every score file. The older round-one Hex pin is intentionally retained in the round-one baseline data.

## Run the round-two matrix

Prerequisites: `claude`, `mise` with Elixir 1.19.5 / OTP 28, Google Chrome, Node/npm, and network access to GitHub.

```bash
# One task/condition/repeat
eval/run.sh --task ticket-index --cond C --rep 2

# Complete 9-task × 3-condition matrix
eval/run.sh --rep 2

# Re-score an existing run without invoking the model, rebuilding, or taking a shot
eval/run.sh --task ticket-index --cond C --rep 2 --skip-model --skip-build --skip-shot
```

Tasks are `ticket-index`, `ticket-flow`, `settings-tabs`, `ops-dashboard`, `command-palette`, `themed-preview`, `undo-delete`, `wizard`, and `state-matrix`. Use separate batches of at most four distinct tasks; never run two tasks with the same task id at once because each task uses a fixed screenshot port.

Each run writes `results/<task>-<condition>-r<repeat>/`. The committed artifacts are `score.json`, `score.txt`, and `screenshot.png`; per-run logs, prompts, and demo checkouts are ignored. `score.json` records the exact lantern-ui package SHA. The runner measures compile, changed-file lint, weighted rubric score, recipe-block fidelity, screenshot status, and axe violations. Block fidelity and axe findings are reported beside the weighted score; they do not change its weights.

## Round-one baseline

`results/baseline-2026-10-03.md` records the original ten tasks across A/B. Round-one task directories and scores remain the historical baseline, except for the explicitly rerun dead combo `themed-preview-C-r1`. The `ticket-index-C-r1` compile failure is retained as failure data: it used lantern_ui Hex 0.8.3, which did not provide `stack/1`.

## Rubric and screenshots

`checks.exs` scores component use, banned-pattern checks, accessibility smoke, and expected deliverables. `--min-comps`, `--block`, and `--lint-findings` configure round-two gates. `shot.mjs` captures the route and runs axe-core when the local browser dependencies are installed. The self-contained round-two gallery embeds downscaled JPEGs so it can be opened without the result directories.
