// Capture the committed regression gallery. Run against the test QA host:
// BASE=http://127.0.0.1:4013 OUT=/tmp/lantern-regressions/after \
// CHROME_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
// PUPPETEER_CORE=/tmp/lantern-chart-qa/node_modules/puppeteer-core node test/qa/regressions_capture.mjs
import { createRequire } from "node:module"
import fs from "node:fs"
import path from "node:path"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const base = process.env.BASE || "http://127.0.0.1:4013"
const out = process.env.OUT || "/tmp/lantern-regressions/after"
const chrome = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fs.mkdirSync(out, { recursive: true })
const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ["--no-sandbox"] })
const files = []

for (const width of [1440, 1100, 390]) {
  for (const theme of ["light", "dark"]) {
    const page = await browser.newPage()
    await page.setViewport({ width, height: 900, deviceScaleFactor: 1 })
    const url = `${base}/regressions?theme=${theme}`
    await page.goto(url, { waitUntil: "networkidle0" })
    await page.waitForSelector("#qa-regression-chart svg")

    const shot = async (state) => {
      const file = `${width}-${theme}-${state}.png`
      await page.screenshot({ path: path.join(out, file), fullPage: true })
      files.push(file)
    }
    await shot("page")
    const view = await page.$("#qa-regression-table-display [data-part=trigger] button")
    if (view) { await view.click(); await new Promise((resolve) => setTimeout(resolve, 300)); await shot("view-open") }
    await page.keyboard.press("Escape")
    await page.evaluate(() => {
      document.activeElement?.blur()
      document.querySelector("#qa-regression-chart svg")?.scrollIntoView({ block: "center" })
    })
    await new Promise((resolve) => setTimeout(resolve, 150))
    const position = await page.evaluate(() => {
      const chart = document.querySelector("#qa-regression-chart")
      const svg = chart.querySelector("svg")
      const rect = svg.getBoundingClientRect()
      const data = JSON.parse(chart.dataset.interaction)
      const viewBox = svg.viewBox.baseVal
      const point = data[Math.min(27, data.length - 1)]
      return { x: rect.left + point.x / viewBox.width * rect.width, y: rect.top + rect.height / 2 }
    })
    await page.mouse.move(position.x, position.y)
    await page.waitForFunction(() => !document.querySelector('#qa-regression-chart [data-part="html-tooltip"]')?.hidden, { timeout: 3000 })
    await new Promise((resolve) => setTimeout(resolve, 100))
    await shot("chart-hover")
    await page.goto(`${url}&expand=1`, { waitUntil: "networkidle0" })
    await shot("expanded")
    await page.close()
  }
}
await browser.close()
const cards = files.map((file) => `<a href="${file}"><img src="${file}" alt="${file}"><span>${file}</span></a>`).join("\n")
fs.writeFileSync(path.join(out, "index.html"), `<!doctype html><meta charset="utf-8"><title>Lantern regression gallery</title><style>body{font:14px system-ui;background:#eee;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}a{display:block;color:#222;background:white;padding:8px;text-decoration:none}img{display:block;width:100%;height:280px;object-fit:contain;object-position:top}span{display:block;margin:8px}</style><h1>Lantern regression gallery</h1><main>${cards}</main>`)
console.log(`${files.length} screenshots in ${out}`)
