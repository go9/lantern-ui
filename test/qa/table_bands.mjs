import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import puppeteer from 'puppeteer-core'
const browser = await puppeteer.launch({executablePath: process.env.CHROME_PATH || '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser', headless:true})
const page = await browser.newPage()
const base = process.env.BASE || 'http://127.0.0.1:4027'
const shots = 'test/qa/screenshots/index-primitives'
await fs.mkdir(shots, {recursive:true})
const names = () => page.$$eval('.lui-dt-card-main strong', nodes => nodes.map(e => e.textContent))
try {
  await page.setViewport({width:1200,height:800})
  await page.goto(`${base}/table_bands`)
  await page.waitForSelector('.phx-connected')
  assert.equal(await page.$$eval('tbody[role=rowgroup]', es => es.length), 2)
  assert.equal(await page.$('[data-part=sort]'), null)
  await page.click('a[href*="view=cards"]')
  await page.waitForSelector('[data-view=cards] [data-part=sort]')
  await page.select('[data-part=sort]', 'tickets')
  await page.waitForFunction(() => new URL(location).searchParams.get('order_by[]') === 'tickets')
  assert.deepEqual(await names(), ['Acme', 'Comet', 'Beacon'])
  await page.click('a[aria-label="Sort descending"]')
  await page.waitForFunction(() => new URL(location).searchParams.get('order_directions[]') === 'desc')
  assert.deepEqual(await names(), ['Acme', 'Beacon', 'Comet'])
  const selectHeight = await page.$eval('[data-part=sort]', e => e.getBoundingClientRect().height)
  assert.equal(selectHeight, await page.$eval('[data-part=sort]', e => parseFloat(getComputedStyle(e).getPropertyValue('--lui-control-h-sm')) * parseFloat(getComputedStyle(document.documentElement).fontSize)))
  for (const theme of ['light','dark']) {
    await page.emulateMediaFeatures([{name:'prefers-color-scheme',value:theme}])
    for (const width of [1200,390]) {
      await page.setViewport({width,height:800})
      for (const view of ['cards','table']) {
        await page.goto(`${base}/table_bands?view=${view}&order_by[]=tickets&order_directions[]=desc`)
        await page.waitForSelector('.phx-connected')
        await page.screenshot({path:`${shots}/${width}-${theme}-${view}.png`})
        assert.ok(await page.$eval('body', e => e.scrollWidth <= innerWidth), `${view} overflow at ${width}`)
      }
    }
  }
  await page.setViewport({width:1200,height:800})
  await page.goto(`${base}/table_bands?view=table&order_by[]=tickets&order_directions[]=desc`)
  await page.waitForSelector('.phx-connected')
  assert.equal(await page.$eval('th[aria-sort=descending]', e => e.textContent.trim().startsWith('Tickets')), true)
  await page.hover('tbody:last-child .lui-tr')
  await page.waitForFunction(() => getComputedStyle(document.querySelector('#pin-beacon')).opacity === '1')
  await page.click('#pin-beacon')
  await page.waitForFunction(() => document.querySelector('tbody').textContent.includes('Beacon'))
  await page.click('#pin-acme')
  await page.waitForFunction(() => document.querySelector('#pin-acme').getAttribute('aria-pressed') === 'false')
  await page.click('#pin-beacon')
  await page.waitForFunction(() => document.querySelectorAll('.lui-dt-band').length === 0)
  console.log('Band sorting, reverse, view continuity, compact sizing, reveal, pin transitions, and eight screenshots passed')
} finally { await browser.close() }
