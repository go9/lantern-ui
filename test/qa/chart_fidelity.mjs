// Native-size and interaction fidelity matrix. Use a scratch puppeteer-core install:
// BASE=http://127.0.0.1:4023 PUPPETEER_CORE=/tmp/lantern-chart-qa/node_modules/puppeteer-core \
// CHROME_PATH='/Applications/Brave Browser.app/Contents/MacOS/Brave Browser' \
// QA_SHOTS=/tmp/lantern-chart-fidelity node test/qa/chart_fidelity.mjs
import { createRequire } from 'node:module'
import fs from 'node:fs'

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || 'puppeteer-core')
const base = process.env.BASE || 'http://127.0.0.1:4023'
const shots = process.env.QA_SHOTS || '/tmp/lantern-chart-fidelity'
const chrome = process.env.CHROME_PATH || '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
const widths = process.env.QA_VW ? [Number(process.env.QA_VW)] : [1440, 1100, 390]
const types = process.env.QA_TYPE ? [process.env.QA_TYPE] : ['line', 'area', 'stacked_area', 'bar', 'stacked_bar', 'grouped_bar', 'points']
fs.mkdirSync(shots, { recursive: true })
const browser = await puppeteer.launch({ executablePath: chrome, headless: 'new', args: ['--no-sandbox'] })
const results = []

for (const width of widths) for (const theme of ['light', 'dark']) for (const type of types) {
  const page = await browser.newPage()
  const row = { width, theme, type, problems: [] }
  try {
    await page.setViewport({ width, height: 900 })
    await page.goto(`${base}/charts?type=${type}&theme=${theme}`, { waitUntil: 'networkidle2' })
    await page.waitForSelector('.phx-connected', { timeout: 8000 })
    await page.waitForFunction(() => {
      const svg = document.querySelector('#qa-time-series svg')
      return svg && Math.abs(svg.viewBox.baseVal.width - svg.getBoundingClientRect().width) <= 1
    }, { timeout: 4000 })
    const measurements = await page.$eval('#qa-time-series', (root) => {
      const svg = root.querySelector('svg')
      const svgRect = svg.getBoundingClientRect()
      const ticks = [...svg.querySelectorAll('.lui-time-series-chart__x-tick')].filter((el) => !el.hasAttribute('hidden')).map((el) => el.getBoundingClientRect())
      const yTicks = [...svg.querySelectorAll('.lui-time-series-chart__y-tick')].map((el) => el.getBoundingClientRect())
      const glyph = svg.querySelector('.lui-time-series-chart__y-tick')
      const box = glyph.getBBox()
      const rect = glyph.getBoundingClientRect()
      return {
        svgWidth: svgRect.width, viewWidth: svg.viewBox.baseVal.width,
        svgHeight: svgRect.height, viewHeight: svg.viewBox.baseVal.height,
        glyphScaleX: rect.width / box.width, glyphScaleY: rect.height / box.height,
        xCollisions: ticks.some((tick, index) => index && tick.left < ticks[index - 1].right + 7),
        xClip: ticks.some((tick) => tick.left < svgRect.left - 1 || tick.right > svgRect.right + 1),
        yClip: yTicks.some((tick) => tick.left < svgRect.left - 1),
      }
    })
    row.measurements = measurements
    if (Math.abs(measurements.svgWidth - measurements.viewWidth) > 1) row.problems.push('viewBox width differs from container')
    if (Math.abs(measurements.svgHeight - measurements.viewHeight) > 1) row.problems.push('viewBox height differs from requested height')
    if (Math.abs(measurements.glyphScaleX - 1) > .02 || Math.abs(measurements.glyphScaleY - 1) > .02) row.problems.push('glyphs distorted')
    if (measurements.xCollisions || measurements.xClip || measurements.yClip) row.problems.push('tick collision or clipping')
    if (width === 1440 && type === 'line') {
      await page.$eval('#qa-chart-card', (card) => { card.style.width = '560px' })
      await page.waitForFunction(() => {
        const svg = document.querySelector('#qa-time-series svg')
        return Math.abs(svg.viewBox.baseVal.width - svg.getBoundingClientRect().width) <= 1 && svg.viewBox.baseVal.width < 700
      }, { timeout: 3000 })
      await page.$eval('#qa-chart-card', (card) => { card.style.width = '' })
      await page.waitForFunction(() => {
        const svg = document.querySelector('#qa-time-series svg')
        return Math.abs(svg.viewBox.baseVal.width - svg.getBoundingClientRect().width) <= 1 && svg.viewBox.baseVal.width > 900
      }, { timeout: 3000 })
    }

    const barTypes = ['bar', 'stacked_bar', 'grouped_bar']
    if (barTypes.includes(type)) {
      const bars = await page.$$('#qa-time-series .lui-time-series-chart__bar')
      for (const bar of bars.slice(0, Math.min(bars.length, 3))) {
        const box = await bar.boundingBox()
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2)
        await new Promise((resolve) => setTimeout(resolve, 40))
        const diff = await page.$eval('#qa-time-series', (root) => {
          const bar = root.querySelector('.lui-time-series-chart__bar[data-active]')
          const crosshair = root.querySelector('[data-part="crosshair"]')
          if (!bar || crosshair.closest('[hidden]')) return null
          const br = bar.getBoundingClientRect(), cr = crosshair.getBoundingClientRect()
          return Math.abs(cr.x - (br.x + br.width / 2))
        })
        if (diff === null || diff > 1) row.problems.push(`bar center mismatch: ${diff}`)
      }
    } else {
      await page.$eval('#qa-time-series [data-chart-point="0"]', (point) => point.focus())
      const shown = await page.$eval('#qa-time-series [data-part="html-tooltip"]', (el) => ({ hidden: el.hidden, font: getComputedStyle(el).fontSize, legend: getComputedStyle(document.querySelector('.lui-time-series-chart__legend-item')).fontSize }))
      if (shown.hidden || shown.font !== shown.legend) row.problems.push(`tooltip hidden or font differs from page UI: ${JSON.stringify(shown)}`)
    }
    const tooltipBounds = await page.$eval('#qa-time-series', (root) => {
      const svg = root.querySelector('svg').getBoundingClientRect()
      const tooltip = root.querySelector('[data-part="html-tooltip"]').getBoundingClientRect()
      return { inside: tooltip.left >= svg.left - 1 && tooltip.right <= svg.right + 1 && tooltip.top >= svg.top - 1 && tooltip.bottom <= svg.bottom + 1 }
    })
    if (!tooltipBounds.inside) row.problems.push('tooltip not clamped to chart')
    await page.screenshot({ path: `${shots}/${width}-${theme}-${type}.png`, fullPage: true })
  } catch (error) {
    row.problems.push(error.message.split('\n')[0])
  }
  results.push(row)
  await page.close()
}
await browser.close()
fs.writeFileSync(`${shots}/matrix.json`, JSON.stringify(results, null, 2))
const failed = results.filter((row) => row.problems.length)
for (const row of failed) console.error(`${row.width}/${row.theme}/${row.type}: ${row.problems.join('; ')}`)
console.log(`${results.length} chart cases, ${failed.length} failing`)
process.exitCode = failed.length ? 1 : 0
