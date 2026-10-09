# Browser QA

The control sizing consistency kitchen sink runs in headless Chrome/Brave with `puppeteer-core`:

```sh
MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs &
BASE=http://127.0.0.1:4013 CHROME_PATH=/path/to/chrome node test/qa/run.mjs --consistency
```

The gate checks standard sizing, mixed toolbar heights, horizontal overflow, and clipped control labels/icons at 1440px and 390px in light and dark themes. Run `--consistency --consistency-legacy` with `QA_BASELINE_CSS` set to the pre-scale `priv/static/lantern_ui.css` to also compare representative legacy computed styles against that stylesheet. CI extracts this baseline from `origin/main` and runs both modes.

Set `QA_REPORT_DIR` to save screenshots and JSON measurements. Mutation evidence is recorded in [control-scale-mutation.md](evidence/control-scale-mutation.md).
