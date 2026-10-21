// MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs
// BASE=http://127.0.0.1:4013 CHROME_PATH=/path/to/chrome node test/qa/funnel.mjs
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import puppeteer from 'puppeteer-core'

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH || '/usr/bin/chromium',
  headless: true,
  args: process.env.CHROME_NO_SANDBOX ? ['--no-sandbox'] : [],
})
const page = await browser.newPage()
const base = process.env.BASE || 'http://127.0.0.1:4013'
const shots = process.env.QA_SHOTS || 'test/qa/screenshots/funnel'
const stage = value => `#reports button[value="${value}"]`
const selected = value => `${stage(value)}[aria-pressed="true"]`
const errors = []
page.on('pageerror', error => errors.push(error.message))
await fs.mkdir(shots, {recursive: true})

try {
  await page.emulateMediaFeatures([{name: 'prefers-color-scheme', value: 'light'}])
  await page.setViewport({width: 1000, height: 320})
  await page.goto(`${base}/funnel`)
  await page.waitForSelector('.phx-connected')
  await page.waitForSelector(selected('needs'))
  assert.equal(await page.$(stage('held')), null)
  assert.equal(await page.$eval(stage('told'), el => el.textContent.trim()), 'Told 0')
  await page.screenshot({path: `${shots}/light.jpg`})

  // Tab traverses ordinary native buttons; Space and Enter push the server event.
  await page.focus(stage('needs'))
  await page.keyboard.press('Tab')
  assert.equal(await page.$eval(stage('work'), el => el === document.activeElement), true)
  assert.equal(await page.$eval(stage('work'), el => getComputedStyle(el).outlineStyle), 'solid')
  await page.keyboard.press('Space')
  await page.waitForSelector(selected('work'))
  assert.equal(await page.$eval('#filtered', el => el.textContent), 'Showing: work')
  assert.equal(await page.$eval(stage('work'), el => el === document.activeElement), true)
  await page.keyboard.press('Tab')
  await page.keyboard.press('Enter')
  await page.waitForSelector(selected('shipped'))
  assert.equal(await page.$eval('#filtered', el => el.textContent), 'Showing: shipped')
  assert.equal(await page.$eval(stage('shipped'), el => el === document.activeElement), true)

  await page.click(stage('snoozed'))
  await page.waitForSelector(selected('snoozed'))
  await page.click('#empty-snoozed')
  await page.waitForFunction(selector => document.querySelector(selector)?.textContent.trim() === 'Snoozed 0', {}, stage('snoozed'))
  await page.waitForSelector(selected('snoozed'))
  await page.click(stage('needs'))
  await page.waitForSelector(selected('needs'))
  await page.waitForFunction(selector => !document.querySelector(selector), {}, stage('snoozed'))

  await page.emulateMediaFeatures([{name: 'prefers-color-scheme', value: 'dark'}])
  await page.goto(`${base}/funnel`)
  await page.waitForSelector('.phx-connected')
  await page.screenshot({path: `${shots}/dark.jpg`})

  await page.setViewport({width: 390, height: 360})
  await page.emulateMediaFeatures([
    {name: 'prefers-color-scheme', value: 'light'},
    {name: 'prefers-reduced-motion', value: 'reduce'},
  ])
  await page.goto(`${base}/funnel`)
  await page.waitForSelector('.phx-connected')
  const sizing = await page.$eval('#reports', el => ({
    scrolls: el.scrollWidth > el.clientWidth,
    pageFits: document.documentElement.scrollWidth <= innerWidth,
  }))
  assert.deepEqual(sizing, {scrolls: true, pageFits: true})
  await page.focus(stage('needs'))
  for (let i = 0; i < 4; i++) await page.keyboard.press('Tab')
  assert.equal(await page.$eval(stage('snoozed'), el => el === document.activeElement), true)
  assert.equal(await page.$eval('#reports', el => el.scrollLeft > 0), true)
  const visible = await page.$eval(stage('snoozed'), el => {
    const item = el.getBoundingClientRect()
    const line = el.closest('#reports').getBoundingClientRect()
    return item.left >= line.left && item.right <= line.right
  })
  assert.equal(visible, true)
  assert.equal(await page.$eval(stage('snoozed'), el => getComputedStyle(el).transitionDuration), '0s')
  assert.equal(await page.$eval('#reports', el => getComputedStyle(el).scrollBehavior), 'auto')
  await page.screenshot({path: `${shots}/mobile-focus.jpg`})
  await page.keyboard.press('Enter')
  await page.waitForSelector(selected('snoozed'))
  assert.equal(await page.$eval('#filtered', el => el.textContent), 'Showing: snoozed')
  assert.deepEqual(errors, [])
  console.log('Funnel: native keyboard, server state and focus, empty overflow, dark, mobile scroll, reduced motion passed')
} finally {
  await browser.close()
}
