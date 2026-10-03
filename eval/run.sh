#!/usr/bin/env bash
# Eval runner (flicker #3415, step 1).
#
# For each <task> x <cond> combo: fresh lantern-demo checkout at eval/demo-pin.txt,
# run the model via `claude -p`, collect changed files, score with checks.exs,
# `mix compile`, boot the server and screenshot the route with headless Chrome.
#
# Usage:
#   eval/run.sh [--task ID] [--cond A|B] [--model sonnet]
#               [--skip-model] [--skip-build] [--skip-shot]
#
# --skip-model reuses an existing checkout in eval/results/<task>-<cond>/demo
# (useful to re-score / re-screenshot without spending model quota).
# Exit 0 if the harness ran; per-combo failures are recorded in score.json,
# never fatal to other combos.
set -u

# Same toolchain for the model subprocess and our own build/score steps, so the
# model can actually run `mix compile` per the brief. (`mise x --` is used
# below as a backstop in case shims are missing.)
if [ -d "$HOME/.local/share/mise/shims" ]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS="$EVAL_DIR/results"
DEMO_PIN="$(tr -d '[:space:]' < "$EVAL_DIR/demo-pin.txt")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
MODEL="sonnet"
TASK_FILTER=""
COND_FILTER=""
SKIP_MODEL=0
SKIP_BUILD=0
SKIP_SHOT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --task) TASK_FILTER="$2"; shift 2 ;;
    --cond) COND_FILTER="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --skip-model) SKIP_MODEL=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --skip-shot) SKIP_SHOT=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

TASKS="$(ls "$EVAL_DIR/tasks"/[0-9]*.md | xargs -n1 basename | sed 's/^[0-9]*-//;s/\.md$//')"
[ -n "$TASK_FILTER" ] && TASKS="$TASK_FILTER"
CONDS="A B"
[ -n "$COND_FILTER" ] && CONDS="$COND_FILTER"

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

task_index() {
  ls "$EVAL_DIR/tasks"/[0-9]*.md | xargs -n1 basename | grep -n "$1" | cut -d: -f1
}

run_combo() {
  task="$1"; cond="$2"
  out="$RESULTS/$task-$cond"
  demo="$out/demo"
  mkdir -p "$out"

  echo "=== $task [$cond] ==="

  # Fresh checkout per model run (contract); reuse only for --skip-model reruns.
  if [ "$SKIP_MODEL" -eq 0 ]; then rm -rf "$demo"; fi
  if [ ! -d "$demo/.git" ]; then
    rm -rf "$demo"
    git clone -q https://github.com/go9/lantern-demo "$demo" 2>"$out/clone.log" || {
      echo "clone failed (see clone.log)"; echo '{"error":"clone failed"}' > "$out/score.json"; return 0; }
    (cd "$demo" && git checkout -q "$DEMO_PIN") || {
      echo "pin checkout failed"; echo '{"error":"pin checkout failed"}' > "$out/score.json"; return 0; }
  fi

  # Build prompt: brief + task + condition appendix (+ docs bundle for B).
  {
    cat "$EVAL_DIR/tasks/_brief.md"
    echo
    cat "$EVAL_DIR/tasks"/[0-9]*-"$task".md
    echo
    cat "$EVAL_DIR/cond-$cond.md"
    if [ "$cond" = "B" ]; then
      for f in docs/recipes.md skills/lantern-recipes/SKILL.md docs/dense-app.md docs/scale.md docs/behaviours.md; do
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

  # Score.
  # shellcheck disable=SC2046,SC2086
  mise x -- elixir "$EVAL_DIR/checks.exs" $(expects_for "$task") -- $FILES \
    > "$out/score.txt" 2>&1 || true
  score="$(grep -E '^SCORE:' "$out/score.txt" | head -1 || echo 'SCORE: 0/100')"

  # Skips carry forward the previous value (a re-score must not erase a proven
  # compile pass or screenshot).
  prev_compile="skipped"; prev_shot="skipped"
  if [ -f "$out/score.json" ]; then
    prev_compile="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('compile','skipped'))")"
    prev_shot="$(python3 -c "import json;print(json.load(open('$out/score.json')).get('screenshot','skipped'))")"
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

  # Screenshot.
  shot="$prev_shot"
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
      if "$CHROME" --headless --disable-gpu --no-sandbox \
          --window-size=1280,900 "--screenshot=$out/screenshot.png" \
          "http://localhost:$port$route" > "$out/shot.log" 2>&1; then
        shot="ok"
      else
        shot="chrome-failed"
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
  'task': '$task', 'condition': '$cond', 'model': '$MODEL',
  'demo_sha': '$DEMO_PIN', 'auto': '''$score'''.strip(),
  'compile': '$compile', 'screenshot': '$shot',
}, open('$out/score.json', 'w'), indent=2)
"
  echo "$score | compile=$compile shot=$shot"
}

for t in $TASKS; do
  for c in $CONDS; do
    run_combo "$t" "$c"
  done
done

echo "done. results in $RESULTS"
