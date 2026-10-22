// Page-recipe gate: index, detail, settings, form and empty pages in the app preset,
// light + dark at 1440 and 375. Asserts layout and density, not pixels.
//
//   MIX_ENV=test PORT=4231 mix run --no-halt test/qa/server.exs &
//   BASE=http://127.0.0.1:4231 CHROME_PATH=/path/to/chrome node test/qa/recipe_pages.mjs
//
// QA_RECIPE_SHOTS=dir  also writes <page>-<theme>-<width>.png for every case.
import { createRequire } from "node:module"
import fs from "node:fs"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const BASE = process.env.BASE || "http://127.0.0.1:4231"
const CHROME = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
const SHOTS = process.env.QA_RECIPE_SHOTS
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

const CASES = [
  { name: "index", q: "page=index" },
  { name: "index-loading", q: "page=index&state=loading" },
  { name: "index-empty", q: "page=index&state=empty" },
  { name: "index-nomatch", q: "page=index&state=nomatch" },
  { name: "index-error", q: "page=index&state=error" },
  { name: "detail", q: "page=detail" },
  { name: "settings", q: "page=settings" },
  { name: "settings-dirty", q: "page=settings&dirty=1" },
  { name: "settings-nav", q: "page=settings&nav=1" },
  { name: "form", q: "page=form" },
  { name: "empty", q: "page=empty" },
]

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true })
const page = await browser.newPage()
let failures = 0, checks = 0
const fail = (c, msg) => { failures++; console.log(`FAIL ${c}: ${msg}`) }
const ok = (c, cond, msg) => { checks++; if (!cond) fail(c, msg) }

if (SHOTS) fs.mkdirSync(SHOTS, { recursive: true })

for (const width of [1440, 375]) {
  await page.setViewport({ width, height: 1000 })
  for (const theme of ["light", "dark"]) {
    for (const c of CASES) {
      const id = `${c.name}/${theme}/${width}`
      await page.goto(`${BASE}/recipe_pages?${c.q}&theme=${theme}`, { waitUntil: "networkidle2" })
      await page.waitForSelector(".lui-page-container")
      await page.evaluate(() => document.fonts.ready)
      await sleep(250)
      const m = await page.evaluate(() => {
        const px = (e) => (e ? e.getBoundingClientRect() : null)
        const container = document.querySelector(".lui-page-container")
        const heading = document.querySelector(".lui-page-heading-title, .lui-settings-page-title")
        const first = document.querySelector(".lui-datatable, .lui-page-section, .lui-settings-section, .lui-form-group, .lui-empty, .lui-skeleton")
        const root = parseFloat(getComputedStyle(document.documentElement).fontSize)
        const main = document.querySelector(".lui-page-container")
        const controls = [...main.querySelectorAll(".lui-btn, .lui-input-wrap, .lui-select-trigger")]
        const rows = [...main.querySelectorAll(".lui-datatable tbody .lui-tr")]
        const forms = [...main.querySelectorAll("form")]
        return {
          root,
          overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
          containerW: px(container).width,
          containerLeft: px(container).left,
          headingLeft: px(heading)?.left ?? null,
          firstLeft: document.querySelector(".lui-settings-nav") ? px(document.querySelector(".lui-settings-nav")).left : px(first)?.left ?? null,
          maxControl: Math.max(0, ...controls.map((e) => px(e).height)),
          maxRow: Math.max(0, ...rows.map((e) => px(e).height)),
          rowCount: rows.length,
          tablist: !!main.querySelector("[role=tablist]:not(.lui-segmented, [data-variant=segmented])"),
          saves: forms.map((f) => ({
            n: f.querySelectorAll("button[type=submit]").length,
            inRow: !!f.querySelector(".lui-input-row button, .lui-input-wrap button[type=submit]"),
            disabled: f.querySelector("button[type=submit]")?.disabled ?? null,
            hint: f.querySelector(".lui-settings-dirty")?.textContent.trim() ?? null,
          })),
          panelW: px(document.querySelector(".lui-settings-panel"))?.width ?? null,
          empties: [...main.querySelectorAll(".lui-empty")].map((e) => ({
            icon: !!e.querySelector(".lui-empty-icon"), title: !!e.querySelector(".lui-empty-title"),
            actions: e.querySelectorAll(".lui-empty-actions .lui-btn").length,
            role: e.getAttribute("role"), kind: e.dataset.kind,
          })),
        }
      })
      ok(id, m.overflow <= 0, `horizontal overflow ${m.overflow}px`)
      ok(id, m.headingLeft === null || Math.abs(m.headingLeft - m.containerLeft - 0) < 40, "heading not inside the container gutter")
      ok(id, m.firstLeft === null || m.headingLeft === null || Math.abs(m.firstLeft - m.headingLeft) <= 1, `content left ${m.firstLeft} != heading left ${m.headingLeft}`)
      ok(id, m.containerW <= (c.name === "form" ? 36 : 80) * m.root + 1, `container ${m.containerW}px wider than its named max`)
      ok(id, m.maxRow <= 44, `row ${m.maxRow}px > 44`)
      ok(id, m.maxControl <= 32.5, `control ${m.maxControl}px > 32`)
      if (c.name.startsWith("settings")) {
        ok(id, m.saves.length >= 2 && m.saves.every((s) => s.n === 1 && !s.inRow), "each settings form needs exactly one Save, never inside a field row")
        ok(id, !m.tablist, "settings page with <=4 sections must not render tabs")
        ok(id, m.panelW <= 36 * m.root + 1, `settings panel ${m.panelW}px > 36rem`)
        const first = m.saves[0]
        if (c.name === "settings-dirty") ok(id, first.disabled === false && first.hint === "Unsaved changes", "dirty form: Save enabled with hint")
        else ok(id, first.disabled === true && !first.hint, "clean form: Save disabled, no hint")
      }
      if (c.name === "index") ok(id, m.rowCount === 4, "index shows its rows")
      if (c.name.startsWith("index-") && c.name !== "index-loading") ok(id, m.empties.length === 1 && m.empties[0].actions === 1, "state shows exactly one empty panel with one action")
      if (c.name === "index-error") ok(id, m.empties[0].role === "alert", "error state is an alert")
      if (c.name === "empty") {
        ok(id, m.empties.length === 4 && m.empties.every((e) => e.icon && e.title), "four empty kinds, each icon + title")
        ok(id, m.empties.every((e) => e.actions <= 1), "at most one action per empty state")
      }
      if (SHOTS) await page.screenshot({ path: `${SHOTS}/${c.name}-${theme}-${width}.png`, fullPage: true })
    }
  }
}
await browser.close()
console.log(`${checks - failures}/${checks} checks pass`)
process.exitCode = failures ? 1 : 0
