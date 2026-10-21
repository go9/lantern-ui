// Run against MIX_ENV=test PORT=4027 mix run --no-halt test/qa/server.exs
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import puppeteer from 'puppeteer-core'
const browser = await puppeteer.launch({executablePath: process.env.CHROME_PATH || '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser', headless: true})
const page = await browser.newPage()
const base = process.env.BASE || 'http://127.0.0.1:4027'
const shots = 'test/qa/screenshots/index-primitives'
await fs.mkdir(shots, {recursive:true})
try {
  await page.setViewport({width:1000,height:600})
  await page.goto(`${base}/index_primitives`)
  await page.waitForSelector('.phx-connected')
  await page.screenshot({path:`${shots}/glyphs-toggle.png`})
  assert.equal(await page.$eval('#pin-acme svg', e => getComputedStyle(e).fill), await page.$eval('#pin-acme', e => getComputedStyle(e).color))
  await page.click('#pin-acme')
  await page.waitForSelector('#pin-acme[aria-pressed="false"]')
  await page.mouse.move(950,550)
  await page.evaluate(() => document.activeElement.blur())
  await page.waitForFunction(() => getComputedStyle(document.querySelector('#pin-acme')).opacity === '0')
  await page.focus('#pin-acme')
  await page.waitForFunction(() => getComputedStyle(document.querySelector('#pin-acme')).opacity === '1')
  await page.emulateMediaFeatures([{name:'prefers-color-scheme',value:'dark'}])
  await page.screenshot({path:`${shots}/glyphs-toggle-dark.png`})
  await page.emulate({viewport:{width:390,height:700,isMobile:true,hasTouch:true},userAgent:'QA touch'})
  await page.goto(`${base}/index_primitives`)
  await page.waitForSelector('.phx-connected')
  await page.click('#pin-acme')
  await page.waitForSelector('#pin-acme[aria-pressed="false"]')
  assert.equal(await page.$eval('#pin-acme', e => getComputedStyle(e).opacity), '1')
  console.log('Toggle fill, server state, focus reveal, and touch visibility passed')
} finally { await browser.close() }
