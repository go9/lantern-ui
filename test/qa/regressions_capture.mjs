// Capture the committed regression gallery. Run against the test QA host:
// BASE=http://127.0.0.1:4013 OUT=/tmp/lantern-regressions/after \
// CHROME_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
// PUPPETEER_CORE=/tmp/lantern-chart-qa/node_modules/puppeteer-core node test/qa/regressions_capture.mjs
// Set BASELINE=1 when running this against the pre-change origin/main checkout.
import { createRequire } from "node:module"
import fs from "node:fs"
import path from "node:path"
import assert from "node:assert/strict"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const base = process.env.BASE || "http://127.0.0.1:4013"
const out = process.env.OUT || "/tmp/lantern-regressions/after"
const baseline = process.env.BASELINE === "1"
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
    await page.evaluate(() => { document.body.style.background = getComputedStyle(document.querySelector("#qa-regressions")).backgroundColor })

    const shot = async (state) => {
      const file = `${width}-${theme}-${state}.png`
      const height = await page.evaluate(() => document.querySelector("#qa-regressions").scrollHeight)
      await page.screenshot({ path: path.join(out, file), clip: { x: 0, y: 0, width, height }, captureBeyondViewport: true })
      files.push(file)
    }
    await shot("page")
    const controls = await page.evaluate(() => {
      const selectors = ["#qa-segmented", ".qa-control-row > .lui-btn", ".qa-control-row .lui-icon-btn-tip .lui-btn", "#qa-regression-table .lui-dt-search", "#qa-regression-table-filters [data-part=trigger] button", "#qa-regression-table-display [data-part=trigger] button", "#qa-regression-table .lui-dt-expand"]
      return selectors.map((selector) => {
        const node = document.querySelector(selector)
        return node ? { selector, height: node.getBoundingClientRect().height } : null
      }).filter(Boolean)
    })
    if (!baseline) {
      for (const control of controls) assert.ok(Math.abs(control.height - controls[0].height) <= 1, `${width} ${theme} ${control.selector}: ${control.height} vs ${controls[0].height}`)
      const row = await page.evaluate(() => [...document.querySelectorAll("#qa-regression-table .lui-td .lui-thumbnail")].map((node) => node.getBoundingClientRect().width))
      assert.ok(row.length >= 3 && row.every((size) => size === row[0]), "thumbnail footprints differ")
      const table = await page.evaluate(() => {
        const cell = document.querySelector("#qa-regression-table .lui-thumbnail-cell")
        const image = cell.querySelector(".lui-thumbnail").getBoundingClientRect()
        const name = cell.querySelector("span").getBoundingClientRect()
        const status = document.querySelector("#qa-regression-table .lui-tr .lui-td:nth-child(2)").getBoundingClientRect()
        const edge = document.querySelector("#qa-regression-table .lui-tr .lui-td:last-child")
        return { gap: name.left - image.right, imageCenter: (image.top + image.bottom) / 2, nameCenter: (name.top + name.bottom) / 2, statusCenter: (status.top + status.bottom) / 2, radius: getComputedStyle(edge).borderBottomRightRadius }
      })
      assert.ok(Math.abs(table.gap - 12) <= 1, `thumbnail gap is ${table.gap}px`)
      assert.ok(Math.abs(table.imageCenter - table.nameCenter) <= 1 && Math.abs(table.imageCenter - table.statusCenter) <= 1, "row content is not vertically centered")
      assert.equal(table.radius, "0px", "row separator has a rounded edge")
      const thumb = await page.$("#qa-row-1-image")
      await thumb.hover()
      await page.waitForSelector(".lui-thumbnail-preview")
      const preview = await page.evaluate(() => {
        const thumb = document.querySelector("#qa-row-1-image").getBoundingClientRect()
        const panel = document.querySelector(".lui-thumbnail-preview")
        const bounds = panel.getBoundingClientRect()
        const style = getComputedStyle(panel)
        return { offset: bounds.left >= thumb.right ? bounds.left - thumb.right : bounds.right <= thumb.left ? thumb.left - bounds.right : bounds.top >= thumb.bottom ? bounds.top - thumb.bottom : thumb.top - bounds.bottom, border: style.borderWidth, shadow: style.boxShadow }
      })
      assert.equal(preview.offset, 8, "thumbnail preview offset differs from 8px")
      assert.notEqual(preview.border, "0px", "thumbnail preview has no border")
      assert.notEqual(preview.shadow, "none", "thumbnail preview has no shadow")
      await shot("thumbnail-hover")
      await page.mouse.move(0, 0)
      await thumb.focus()
      await page.waitForSelector(".lui-thumbnail-preview")
      await page.keyboard.press("Escape")
      assert.equal(await page.$(".lui-thumbnail-preview"), null, "Escape did not dismiss preview")
      await page.$eval("#qa-row-2-image", (node) => node.dispatchEvent(new MouseEvent("mouseenter")))
      assert.equal(await page.$(".lui-thumbnail-preview"), null, "placeholder opened a preview")
    }
    const view = await page.$("#qa-regression-table-display [data-part=trigger] button")
    if (view) {
      await view.click()
      await new Promise((resolve) => setTimeout(resolve, 300))
      if (!baseline) {
        const panel = await page.evaluate(() => {
          const root = document.querySelector("#qa-regression-table-display")
          const box = root.querySelector("[data-part=column-toggle]")
          const options = [...root.querySelectorAll(".lui-dt-view-option,.lui-dt-savedview,.lui-dt-savedview-action,.lui-dt-reset-display")]
          return { checkbox: box.classList.contains("lui-checkbox"), sizes: options.map((node) => getComputedStyle(node).fontSize), footer: !!root.querySelector(".lui-dt-view-footer") }
        })
        assert.ok(panel.checkbox && panel.footer, "View panel missed Lantern checkbox or footer")
        assert.equal(new Set(panel.sizes).size, 1, "View menu font sizes differ")
      }
      await shot("view-open")
    }
    await page.keyboard.press("Escape")
    await page.evaluate(() => {
      document.activeElement?.blur()
      document.querySelector("#qa-regression-chart svg")?.scrollIntoView({ block: "center" })
    })
    await new Promise((resolve) => setTimeout(resolve, 150))
    if (!baseline) {
      const emptyDay = await page.evaluate(() => {
        const chart = document.querySelector("#qa-regression-chart")
        const svg = chart.querySelector("svg")
        const frame = svg.getBoundingClientRect()
        const point = chart.querySelector('[data-chart-point="20"]')
        return { x: frame.left + Number(point.getAttribute("cx")) * frame.width / svg.viewBox.baseVal.width, y: frame.top + frame.height / 2 }
      })
      await page.mouse.move(emptyDay.x, emptyDay.y)
      await page.waitForFunction(() => document.querySelector('#qa-regression-chart [data-part="html-tooltip-date"]')?.textContent === "Sep 21", { timeout: 3000 })
    }
    const position = await page.evaluate(() => {
      const chart = document.querySelector("#qa-regression-chart")
      const bar = [...chart.querySelectorAll(".lui-time-series-chart__bar")].at(-1)
      const rect = bar.getBoundingClientRect()
      return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 }
    })
    await page.mouse.move(position.x, position.y)
    await page.waitForFunction(() => !document.querySelector('#qa-regression-chart [data-part="html-tooltip"]')?.hasAttribute("hidden"), { timeout: 3000 })
    if (!baseline) {
      const hover = await page.evaluate(() => {
        const chart = document.querySelector("#qa-regression-chart")
        const bar = [...chart.querySelectorAll(".lui-time-series-chart__bar")].at(-1).getBoundingClientRect()
        const tip = chart.querySelector('[data-part="html-tooltip"]').getBoundingClientRect()
        const frame = chart.querySelector("svg").getBoundingClientRect()
        return { label: chart.querySelector('[data-part="html-tooltip-date"]').textContent, bar: bar.toJSON(), tip: tip.toJSON(), frame: frame.toJSON() }
      })
      assert.equal(hover.label, "Sep 28")
      assert.ok(hover.tip.left >= hover.frame.left && hover.tip.right <= hover.frame.right, "tooltip exceeds chart width")
      assert.ok(hover.tip.right <= hover.bar.left || hover.tip.left >= hover.bar.right, "tooltip covers bar")
      const reference = await page.evaluate(() => {
        const chart = document.querySelector("#qa-regression-chart svg")
        const bar = chart.querySelector(".lui-time-series-chart__bar")
        const label = chart.querySelector(".lui-time-series-chart__reference text")
        const background = chart.querySelector(".lui-time-series-chart__reference rect")
        return { aboveBars: !!(bar.compareDocumentPosition(label) & Node.DOCUMENT_POSITION_FOLLOWING), background: !!background && getComputedStyle(background).fill !== "none" }
      })
      assert.ok(reference.aboveBars && reference.background, "reference label is not painted above bars with a background")
      const labelClear = await page.evaluate(() => {
        const chart = document.querySelector("#qa-regression-chart")
        const label = chart.querySelector(".lui-time-series-chart__reference rect").getBoundingClientRect()
        const tip = chart.querySelector('[data-part="html-tooltip"]').getBoundingClientRect()
        return tip.right <= label.left || tip.left >= label.right || tip.bottom <= label.top || tip.top >= label.bottom
      })
      assert.ok(labelClear, "chart tooltip covers the reference label")
    }
    await new Promise((resolve) => setTimeout(resolve, 100))
    await shot("chart-hover")
    await page.goto(`${url}&expand=1`, { waitUntil: "networkidle0" })
    await page.evaluate(() => { document.body.style.background = getComputedStyle(document.querySelector("#qa-regressions")).backgroundColor })
    if (!baseline) assert.equal(await page.$eval("#qa-regression-table-overview", (node) => getComputedStyle(node).display), "none")
    await shot("expanded")
    await page.close()
  }
}
await browser.close()
const cards = files.map((file) => `<a href="${file}"><img src="${file}" alt="${file}"><span>${file}</span></a>`).join("\n")
fs.writeFileSync(path.join(out, "index.html"), `<!doctype html><meta charset="utf-8"><title>Lantern regression gallery</title><style>body{font:14px system-ui;background:#eee;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px}a{display:block;color:#222;background:white;padding:8px;text-decoration:none}img{display:block;width:100%;height:280px;object-fit:contain;object-position:top}span{display:block;margin:8px}</style><h1>Lantern regression gallery</h1><main>${cards}</main>`)
console.log(`${files.length} screenshots in ${out}`)
