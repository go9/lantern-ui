#!/usr/bin/env bash
# Eval runner (flicker #3415 step 1, #3442 round 2).
#
# For each <task> x <cond> x <rep> combo: fresh lantern-demo checkout at
# eval/demo-pin.txt, run the model via `claude -p`, collect changed files,
# score with checks.exs, `mix compile`, `mix lantern.lint`, boot the server
# and screenshot the route with headless Chrome (puppeteer) + axe smoke.
#
# Usage:
#   eval/run.sh [--task ID] [--cond A|B|C] [--model sonnet] [--rep N]
#               [--skip-model] [--skip-build] [--skip-shot]
#
# --skip-model reuses an existing checkout in eval/results/<task>-<cond>-r<rep>/demo
# (useful to re-score / re-screenshot without spending model quota).
# Exit 0 if the harness ran; per-combo failures are recorded in score.json,
# never fatal to other combos.
set -u

if [ -d "$HOME/.local/share/mise/shims" ]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

# Round 2 toolchain pin (Elixir 1.19 / OTP 28, via mise env override so no
# repo files change). Applies to our build/score steps AND the model's
# subprocess (brief tells it to use `mise x -- mix ...`).
export MISE_ELIXIR_VERSION="1.19.5-otp-28"
export MISE_ERLANG_VERSION="28.5"

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$EVAL_DIR/results"
DEMO_PIN="$(tr -d '[:space:]' < "$EVAL_DIR/demo-pin.txt")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
MODEL="sonnet"
TASK_FILTER=""
COND_FILTER=""
REP="1"
SKIP_MODEL=0
SKIP_BUILD=0
SKIP_SHOT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --task) TASK_FILTER="$2"; shift 2 ;;
    --cond) COND_FILTER="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --rep) REP="$2"; shift 2 ;;
    --skip-model) SKIP_MODEL=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --skip-shot) SKIP_SHOT=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

TASKS="$(ls "$EVAL_DIR/tasks"/[0-9]*.md | xargs -n1 basename | sed 's/^[0-9]*-//;s/\.md$//')"
[ -n "$TASK_FILTER" ] && TASKS="$TASK_FILTER"
CONDS="A B C"
[ -n "$COND_FILTER" ] && CONDS="$COND_FILTER"

# Round-2 scope: only ticket-index + the 8 harder tasks (11-18). The other
# round-1 tasks keep their baseline scores (ceiling effect, no signal).
if [ -z "$TASK_FILTER" ]; then
  TASKS="ticket-index ticket-flow settings-tabs ops-dashboard command-palette themed-preview undo-delete wizard state-matrix"
fi

# Route = first manifest expect starting with / ; port derived from task index.
route_for() {
  python3 -c "
import json
m = json.load(open('$EVAL_DIR/tasks/manifest.json'))
exps = m['$1']['expects']
print(next(e for e in exps if e.startswith('/')))
"
}

expects_for() {
  # No quoting: manifest expects contain no spaces, and quotes produced by
  # command substitution are NOT stripped by the shell (that bug zeroed the
  # deliverables rule in the first smoke run).
  python3 -c "
import json
m = json.load(open('$EVAL_DIR/tasks/manifest.json'))
print(' '.join('--expect ' + e for e in m['$1']['expects']))
"
}

min_comps_for() {
  python3 -c "
import json
print(json.load(open('$EVAL_DIR/tasks/manifest.json'))['$1'].get('min_comps', 4))
"
}

blocks_for() {
  python3 -c "
import json
print(' '.join('--block ' + b for b in json.load(open('$EVAL_DIR/tasks/manifest.json'))['$1'].get('blocks', [])))
"
}

task_index() {
  ls "$EVAL_DIR/tasks"/[0-9]*.md | xargs -n1 basename | grep -n "$1" | cut -d: -f1
}

axe_violations() {
  python3 -c "
import json
try:
  v = json.load(open('$1'))['violations']
  print(len(v))
except Exception:
  print('error')
"
}

run_combo() {
  task="$1"; cond="$2"
  out="$RESULTS/$task-$cond-r$REP"
  demo="$out/demo"
  mkdir -p "$out"

  echo "=== $task [$cond] r$REP ==="

  # Fresh checkout per model run (contract); reuse only for --skip-model reruns.
  if [ "$SKIP_MODEL" -eq 0 ]; then rm -rf "$demo"; fi
  if [ ! -d "$demo/.git" ]; then
    rm -rf "$demo"
    git clone -q https://github.com/go9/lantern-demo "$demo" 2>"$out/clone.log" || {
      echo "clone failed (see clone.log)"; echo '{"error":"clone failed"}' > "$out/score.json"; return 0; }
    (cd "$demo" && git checkout -q "$DEMO_PIN") || {
      echo "pin checkout failed"; echo '{"error":"pin checkout failed"}' > "$out/score.json"; return 0; }
  fi

  # Build prompt: brief + task + condition appendix (+ docs bundles for B/C).
  {
    cat "$EVAL_DIR/tasks/_brief.md"
    echo
    cat "$EVAL_DIR/tasks"/[0-9]*-"$task".md
    echo
    cat "$EVAL_DIR/cond-$cond.md"
    if [ "$cond" = "B" ] || [ "$cond" = "C" ]; then
      for f in docs/recipes.md skills/lantern-recipes/SKILL.md docs/dense-app.md docs/scale.md docs/behaviours.md; do
        echo; echo "===== $f ====="; echo; cat "$EVAL_DIR/../$f"
      done
    fi
    if [ "$cond" = "C" ]; then
      for f in llms.txt priv/AGENTS.md; do
        echo; echo "===== $f ====="; echo; cat "$EVAL_DIR/../$f"
      done
    fi
  } > "$out/prompt.txt"

  if [ "$SKIP_MODEL" -eq 0 ]; then
    (cd "$demo" && claude -p --model "$MODEL" --dangerously-skip-permissions \
      "$(cat "$out/prompt.txt")" > "$out/run.log" 2>&1) || echo "model run exited nonzero (see run.log)"
  fi

  # Changed files (model's diff only, lib + router).
  (cd "$demo" && git status --porcelain | awk '{print $2}' | grep -E '^(lib/|test/)' > "$out/changed.txt" || true)
  FILES=""
  while IFS= read -r f; do
    [ -n "$f" ] && FILES="$FILES $demo/$f"
  done < "$out/changed.txt"
  [ -z "$FILES" ] && FILES="/dev/null"

  # Skips carry forward the previous value (a re-score must not erase a proven
  # compile pass, lint count, or screenshot).
  prev_compile="skipped"; prev_shot="skipped"; prev_lint="skipped"
  prev_blocks="skipped"; prev_axe="skipped"
  if [ -f "$out/score.json" ]; then
    prev_compile="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('compile','skipped'))")"
    prev_shot="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('screenshot','skipped'))")"
    prev_lint="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('lint','skipped'))")"
    prev_blocks="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('blocks','skipped'))")"
    prev_axe="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('axe','skipped'))")"
  fi

  # Build.
  compile="$prev_compile"
  if [ "$SKIP_BUILD" -eq 0 ]; then
    if (cd "$demo" && mise x -- mix deps.get > "$out/build.log" 2>&1 \
        && mise x -- mix compile >> "$out/build.log" 2>&1); then
      compile="pass"
    else
      compile="fail"
    fi
  fi

  # Lint (ships in the lantern_ui Hex dep; cond C requires the model to run
  # it, but we always measure it). Only meaningful on a compile pass.
  # The demo tree has pre-existing findings in files the model never touches,
  # so we count only findings in the model's changed files.
  lint="$prev_lint"
  if [ "$SKIP_BUILD" -eq 0 ]; then
    if [ "$compile" = "pass" ]; then
      if (cd "$demo" && mise x -- mix lantern.lint --format json > "$out/lint.json" 2> "$out/lint.log"); then
        lint="0 findings"
      else
        lint="unavailable"
      fi
      if [ "$lint" != "0 findings" ]; then
        n="$(python3 -c "
import json
try:
  chg = [l.strip() for l in open('$out/changed.txt') if l.strip()]
  fs = json.load(open('$out/lint.json'))['findings']
  print(sum(1 for f in fs if any(f['path'] == c or f['path'].endswith('/' + c) for c in chg)))
except Exception:
  print('ERR')
")"
        if [ "$n" = "ERR" ] || [ -z "$n" ]; then lint="unavailable"; else lint="$n findings"; fi
      fi
    else
      lint="no-compile"
    fi
  fi
  lint_n=""
  case "$lint" in
    [0-9]*\ findings) lint_n="$(echo "$lint" | grep -oE '^[0-9]+')" ;;
  esac

  # Score (lint count feeds the LINT gate line).
  # shellcheck disable=SC2046,SC2086
  if [ -n "$lint_n" ]; then lint_flag="--lint-findings $lint_n"; else lint_flag=""; fi
  # shellcheck disable=SC2046,SC2086
  mise x -- elixir "$EVAL_DIR/checks.exs" $(expects_for "$task") \
    --min-comps "$(min_comps_for "$task")" $(blocks_for "$task") $lint_flag -- $FILES \
    > "$out/score.txt" 2>&1 || true
  score="$(grep -E '^SCORE:' "$out/score.txt" | head -1 || echo 'SCORE: 0/100')"
  blocks="$(grep -E '^BLOCKS:' "$out/score.txt" | head -1 | sed 's/^BLOCKS: //' || echo 'skipped')"
  [ "$score" = "SCORE: 0/100" ] && [ ! -s "$out/changed.txt" ] && blocks="no-files"

  # Screenshot + axe smoke.
  shot="$prev_shot"; axe="$prev_axe"
  if [ "$SKIP_SHOT" -eq 0 ] && [ "$compile" = "pass" ]; then
    route="$(route_for "$task")"
    port="$((4110 + $(task_index "$task")))"
    (cd "$demo" && PORT="$port" mise x -- mix phx.server > "$out/server.log" 2>&1 &
     echo $! > "$out/server.pid")
    ready=0
    for _ in $(seq 1 60); do
      sleep 2
      if curl -sf -o /dev/null "http://localhost:$port$route"; then ready=1; break; fi
    done
    if [ "$ready" -eq 1 ]; then
      if node "$EVAL_DIR/shot.mjs" \
          "http://localhost:$port$route" "$out/screenshot.png" "$out/axe.json" > "$out/shot.log" 2>&1; then
        shot="ok"
        axe="$(axe_violations "$out/axe.json") violations"
      else
        cp "$out/shot.log" "$out/shot-node-error.log"
        if "$CHROME" --headless --disable-gpu --no-sandbox \
          --window-size=1280,900 "--screenshot=$out/screenshot.png" \
          "http://localhost:$port$route" >> "$out/shot.log" 2>&1; then
          shot="ok-fallback"
          axe="not-measured"
        else
          shot="chrome-failed"
        fi
      fi
    else
      shot="server-not-ready"
    fi
    # Cleanup: wrapper pid first, then anything still listening on the port
    # (killing the mise wrapper alone orphans beam — the lsof pass is the
    # backstop; setsid is not available on macOS).
    kill "$(cat "$out/server.pid")" 2>/dev/null || true
    sleep 1
    for p in $(lsof -ti tcp:"$port" 2>/dev/null); do kill "$p" 2>/dev/null || true; done
    sleep 1
  fi

  python3 -c "
import json
json.dump({
  'task': '$task', 'condition': '$cond', 'rep': $REP, 'model': '$MODEL',
  'demo_sha': '$DEMO_PIN', 'auto': '''$score'''.strip(),
  'compile': '$compile', 'lint': '$lint', 'blocks': '''$blocks'''.strip(),
  'axe': '$axe', 'screenshot': '$shot',
}, open('$out/score.json', 'w'), indent=2)
"
  echo "$score | compile=$compile lint=$lint blocks=$blocks axe=$axe shot=$shot"
}

# Axe/puppeteer deps (eval/node_modules, gitignored); install once so shot.mjs can run.
if [ ! -d "$EVAL_DIR/node_modules/puppeteer-core" ]; then
  (cd "$EVAL_DIR" && npm install --no-audit --no-fund) || echo "a11y deps install failed (shot falls back to plain Chrome)"
fi

for t in $TASKS; do
  for c in $CONDS; do
    run_combo "$t" "$c"
  done
done

echo "done. results in $RESULTS"
