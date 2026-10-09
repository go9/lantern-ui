import assert from "node:assert/strict"
import test from "node:test"
import { readFile } from "node:fs/promises"

const css = await readFile(new URL("../../priv/static/lantern_ui.css", import.meta.url), "utf8")

test("shell row, page gutter, control scale, and expanded table use shared tokens", () => {
  assert.match(css, /--lui-strip-h:\s*2\.75rem/)
  assert.match(css, /--lui-page-gutter:\s*1\.5rem/)
  assert.match(css, /--lui-control-sm-h:\s*1\.75rem/)
  assert.match(css, /--lui-control-md-h:\s*2rem/)
  assert.match(css, /--lui-control-lg-h:\s*2\.25rem/)
  assert.match(css, /\.lui-app-sidebar-header[^}]*height:\s*var\(--lui-strip-h\)/s)
  assert.match(css, /--lui-table-expand-top:\s*calc\(var\(--lui-appbar-h\) \+ var\(--lui-strip-h\) \+ var\(--lui-page-gap\)\)/)
  assert.match(css, /\.lui-app-main:has\(\.lui-page-shell-strip\) \{ padding-top:\s*0; \}/)
  assert.match(css, /\.lui-dt-chromerow :is\(button, input, select, \[role="tab"\], \.lui-dt-chip, \.lui-dt-expand\) \{[^}]*min-height:\s*var\(--lui-control-md-h\)/s)
  assert.match(css, /\.lui-dt-search \{ order: 1; flex: 1 0 100%; width: 100%; min-width: 0; \}/)
  assert.match(css, /\.lui-dt-bulkbar :is\(button, input, select, \[role="button"\]\) \{ min-height: var\(--lui-control-md-h\); \}/)
  assert.match(css, /\.lui-dt-chromerow \.lui-dt-quickfilters \.lui-tab \{[^}]*height: var\(--lui-control-md-h\)/s)
})
