// Real-browser regression QA for floating layer first paint.
// MIX_ENV=test PORT=4020 mix run --no-halt test/qa/server.exs
// BASE=http://127.0.0.1:4020 CHROME_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
//   QA_STABILITY_SHOTS=/tmp/lantern-position-stability node test/qa/position_stability.mjs
import { createRequire } from "node:module"
import fs from "node:fs"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const BASE = process.env.BASE || "http://127.0.0.1:4020"
const CHROME = process.env.CHROME_PATH || "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
const SHOTS = process.env.QA_STABILITY_SHOTS || "/tmp/lantern-position-stability"
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new", args: ["--no-sandbox"] })
const rows = []
fs.mkdirSync(SHOTS, { recursive: true })

const surfaces = [
  { name: "collection-filters", route: "/consistency?theme=blue", trigger: "#qa-consistency-table-filters [data-part=trigger] button", panel: "#qa-consistency-table-filters [data-part=content]" },
  { name: "collection-display", route: "/consistency?theme=blue", trigger: "#qa-consistency-table-display [data-part=trigger] button", panel: "#qa-consistency-table-display [data-part=content]" },
  { name: "inventory-filters", route: "/qa?ctx=app_page_shell", trigger: "#qa-app-shell-table-filters [data-part=trigger] button", panel: "#qa-app-shell-table-filters [data-part=content]" },
  { name: "inventory-collapsed-filters", route: "/qa?ctx=app_page_shell_compact", trigger: "#qa-app-shell-table-filters [data-part=trigger] button", panel: "#qa-app-shell-table-filters [data-part=content]" },
  { name: "collection-shell-filters", route: "/qa?ctx=page_shell_strip", trigger: "#qa-strip-table-filters [data-part=trigger] button", panel: "#qa-strip-table-filters [data-part=content]" },
  { name: "collection-shell-collapsed-filters", route: "/qa?ctx=page_shell_strip_compact", trigger: "#qa-strip-table-filters [data-part=trigger] button", panel: "#qa-strip-table-filters [data-part=content]" },
  { name: "chart-settings", route: "/charts", trigger: "#qa-chart-settings .lui-chart-settings__trigger", panel: "#qa-chart-settings [data-part=content]" },
  { name: "date-range", route: "/date_range", trigger: "#qa-date-popover-1 [data-part=trigger]", panel: "#qa-date-popover-1 [data-part=content]" },
  { name: "org-switcher", route: "/qa?ctx=sidebar_header", trigger: "#qa-sidebar-switcher [data-part=trigger] button", panel: "#qa-sidebar-switcher [data-part=content]" },
  { name: "org-switcher-collapsed", route: "/qa?ctx=sidebar_header_collapsed", trigger: "#qa-sidebar-switcher [data-part=trigger] button", panel: "#qa-sidebar-switcher [data-part=content]" },
  { name: "action-bar-more", route: "/qa?ctx=action_bar", trigger: "#qa-action-bar .lui-action-bar-more-trigger", panel: "#qa-action-bar [data-part=content]" },
]

for (const width of [1440, 1100]) {
  for (const surface of surfaces) {
    const page = await browser.newPage()
    await page.setViewport({ width, height: 1000 })
    const row = { width, surface: surface.name, problems: [] }
    try {
      const route = `${surface.route}${surface.route.includes("?") ? "&" : "?"}expand=1`
      await page.goto(`${BASE}${route}`, { waitUntil: "networkidle2" })
      await page.waitForSelector(".phx-connected", { timeout: 8000 })
      await page.waitForSelector(surface.trigger, { visible: true, timeout: 5000 })
      await page.$eval(surface.trigger, (trigger) => trigger.scrollIntoView({ block: "center", inline: "nearest" }))
      await sleep(80)
      await page.evaluate((panelSelector) => {
        window.__positionSamples = []
        const sample = () => {
          const panel = document.querySelector(panelSelector)
          if (panel && !panel.hidden && !panel.closest("[hidden]")) {
            const rect = panel.getBoundingClientRect()
            const style = getComputedStyle(panel)
            if (rect.width && rect.height && style.visibility === "visible" && style.display !== "none") {
              window.__positionSamples.push({ time: performance.now(), x: rect.x, y: rect.y, width: rect.width, height: rect.height })
            }
          }
          requestAnimationFrame(sample)
        }
        requestAnimationFrame(sample)
      }, surface.panel)
      await page.click(surface.trigger)
      await page.waitForFunction(() => window.__positionSamples?.length > 0, { timeout: 2500 })
      await sleep(300)
      const samples = await page.evaluate(() => window.__positionSamples)
      const first = samples[0]
      const last = samples.at(-1)
      const delta = (a, b) => Math.max(Math.abs(a.x - b.x), Math.abs(a.y - b.y), Math.abs(a.width - b.width), Math.abs(a.height - b.height))
      row.samples = samples.length
      row.first = first
      row.after300ms = last
      row.maxMovement = Math.max(...samples.map((sample) => delta(first, sample)))
      if (row.maxMovement > 1) row.problems.push(`panel moved ${row.maxMovement.toFixed(2)}px after first visible frame`)
      await page.screenshot({ path: `${SHOTS}/${surface.name}-${width}.png` })
      if (surface.name === "collection-filters") {
        await page.click("#qa-consistency-table-filters [data-part=add-filter]")
        await page.screenshot({ path: `${SHOTS}/collection-filter-editor-${width}.png` })
      }
    } catch (error) {
      row.problems.push(error.message.split("\n")[0])
      await page.screenshot({ path: `${SHOTS}/${surface.name}-${width}-error.png` }).catch(() => {})
    }
    row.status = row.problems.length ? "FAIL" : "ok"
    rows.push(row)
    if (row.problems.length) console.error(`FAIL ${width} ${surface.name}: ${row.problems.join("; ")}`)
    await page.close()
  }
}

await browser.close()
fs.writeFileSync(`${SHOTS}/position-stability.json`, JSON.stringify(rows, null, 2))
const failed = rows.filter((row) => row.problems.length)
console.log(`${rows.length} first-frame stability cases, ${failed.length} failing`)
process.exit(failed.length ? 1 : 0)
