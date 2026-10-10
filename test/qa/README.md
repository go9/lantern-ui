# Browser QA

The control sizing consistency kitchen sink runs in headless Chrome/Brave with `puppeteer-core`:

```sh
MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs &
BASE=http://127.0.0.1:4013 CHROME_PATH=/path/to/chrome node test/qa/run.mjs --consistency
```

The gate checks standard sizing, mixed toolbar heights, horizontal overflow, and clipped control labels/icons at 1440px and 390px in light and dark themes. CI also runs the shell matrix, which checks the legacy control token against a consumer override and verifies it does not break strip/sidebar row alignment.

Set `QA_REPORT_DIR` to save screenshots and JSON measurements. Mutation evidence is recorded in [control-scale-mutation.md](evidence/control-scale-mutation.md).

The floating-layer first-frame check samples every animation frame from first
visibility through 300ms later. It covers table Filters and View,
chart settings, date range, the workspace switcher, and the action-bar More
menu at 1440px and 1100px:

```sh
MIX_ENV=test PORT=4020 mix run --no-halt test/qa/server.exs &
BASE=http://127.0.0.1:4020 CHROME_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  QA_STABILITY_SHOTS=/tmp/lantern-position-stability node test/qa/position_stability.mjs
```
