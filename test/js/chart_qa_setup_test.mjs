import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { ensureChartShotsDir } from "../qa/chart_shots.mjs"

test("chart QA creates its screenshot directory before saving files", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "lantern-chart-qa-"))

  try {
    const chartShots = ensureChartShotsDir(root)
    assert.equal(chartShots, path.join(root, "charts"))
    assert.equal(fs.statSync(chartShots).isDirectory(), true)
  } finally {
    fs.rmSync(root, { recursive: true, force: true })
  }
})
