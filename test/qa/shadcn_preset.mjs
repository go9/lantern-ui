// shadcn "app" preset gate: measures the projects-index fixture against the
// spec table (the Flicker prototype's computed styles at 1440, 14px root).
//
//   MIX_ENV=test PORT=4231 mix run --no-halt test/qa/server.exs &
//   BASE=http://127.0.0.1:4231 CHROME_PATH=/path/to/chrome node test/qa/shadcn_preset.mjs
//
// QA_PRESET_SHOTS=dir  also writes default/shadcn/app shots (light + dark).
// Row padding is read from the first cell (the table markup pads cells, the
// prototype pads rows); that mapping is the only one.
import { createRequire } from "node:module"
import fs from "node:fs"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const BASE = process.env.BASE || "http://127.0.0.1:4231"
const CHROME = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
const SHOTS = process.env.QA_PRESET_SHOTS
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

const SPEC = {
  light: {
    "row height": 39.5, "row padding X": "14px", "row padding Y": "7px",
    "row font size": "13.5px", "row line height": "20.25px", "name font weight": "500",
    "name font family": '"Inter Variable", system-ui, sans-serif',
    "state font size": "13px", "state line height": "19.5px",
    "card radius": "7px", "border color": "oklch(0.9 0.005 286)",
    background: "oklch(0.985 0.002 286)", "card background": "rgba(0, 0, 0, 0)",
    "card shadow": "none", "header height": 42, "sidebar width": 224, "search width": 196,
    "action height": 24.5, "action radius": "5.6px", "action border": "oklch(0.9 0.005 286)",
    "action background": "oklch(0.985 0.002 286)", "action font size": "11.2px",
  },
  dark: {
    "row height": 39.5, "row padding X": "14px", "row padding Y": "7px",
    "row font size": "13.5px", "row line height": "20.25px", "name font weight": "500",
    "name font family": '"Inter Variable", system-ui, sans-serif',
    "state font size": "13px", "state line height": "19.5px",
    "card radius": "7px", "border color": "oklch(0.32 0.011 286)",
    background: "oklch(0.2 0.006 286)", "card background": "rgba(0, 0, 0, 0)",
    "card shadow": "none", "header height": 42, "sidebar width": 224, "search width": 196,
    "action height": 24.5, "action radius": "5.6px", "action border": "oklch(0.36 0.012 286)",
    "action background": "oklab(0.36 0.00330765 -0.0115351 / 0.3)", "action font size": "11.2px",
  },
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true })
const page = await browser.newPage()
await page.setViewport({ width: 1440, height: 1000 })
let failures = 0
const rows = []

async function load(preset, theme) {
  await page.goto(`${BASE}/shadcn_preset?preset=${preset}&theme=${theme}`, { waitUntil: "networkidle2" })
  await page.waitForSelector(".lui-datatable .lui-tr")
  await page.evaluate(() => document.fonts.ready)
  await sleep(300)
}

for (const theme of ["light", "dark"]) {
  await load("app", theme)
  const actual = await page.evaluate(() => {
    const row = document.querySelector(".lui-datatable tbody .lui-tr")
    const cell = row.querySelector(".lui-td")
    const card = document.querySelector(".lui-datatable .lui-table-wrap")
    const state = row.querySelector("[data-index-state]")
    const title = row.querySelector("a, .lui-td")
    const input = document.querySelector(".lui-dt-search")
    const button = row.querySelector(".lui-btn")
    const v = (e, k) => (e ? getComputedStyle(e)[k] : "MISSING")
    const h = (e) => (e ? e.getBoundingClientRect().height : "MISSING")
    return {
      "row height": h(row), "row padding X": v(cell, "paddingLeft"), "row padding Y": v(cell, "paddingTop"),
      "row font size": v(cell, "fontSize"), "row line height": v(cell, "lineHeight"),
      "name font weight": v(title, "fontWeight"), "name font family": v(title, "fontFamily"),
      "state font size": v(state, "fontSize"), "state line height": v(state, "lineHeight"),
      "card radius": v(card, "borderRadius"), "border color": v(card, "borderTopColor"),
      background: v(document.querySelector("#preset-scope"), "backgroundColor"),
      "card background": v(card, "backgroundColor"), "card shadow": v(card, "boxShadow"),
      "header height": h(document.querySelector(".lui-appbar")),
      "sidebar width": document.querySelector(".lui-app-sidebar").getBoundingClientRect().width,
      "search width": input ? input.getBoundingClientRect().width : "MISSING",
      "action height": h(button), "action radius": v(button, "borderRadius"),
      "action border": v(button, "borderTopColor"), "action background": v(button, "backgroundColor"),
      "action font size": v(button, "fontSize"),
    }
  })
  for (const [key, want] of Object.entries(SPEC[theme])) {
    const got = actual[key]
    const numeric = typeof want === "number" || /^-?[\d.]+px$/.test(want)
    const ok = numeric ? Math.abs(parseFloat(got) - parseFloat(want)) <= 1 : got === want
    if (!ok) failures++
    rows.push({ theme, property: key, spec: want, lantern: got, result: ok ? "PASS" : "FAIL" })
  }
  if (SHOTS) {
    fs.mkdirSync(SHOTS, { recursive: true })
    for (const preset of ["default", "shadcn", "app"]) {
      await load(preset, theme)
      await page.screenshot({ path: `${SHOTS}/${preset}-${theme}.png` })
    }
  }
}
await browser.close()
console.table(rows)
console.log(`${rows.length - failures}/${rows.length} rows pass`)
process.exitCode = failures ? 1 : 0
