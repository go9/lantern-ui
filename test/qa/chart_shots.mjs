import fs from "node:fs"
import path from "node:path"

export function ensureChartShotsDir(root) {
  const chartShots = path.join(root, "charts")
  fs.mkdirSync(chartShots, { recursive: true })
  return chartShots
}
