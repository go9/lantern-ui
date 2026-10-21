import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import puppeteer from 'puppeteer-core'

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH || '/usr/bin/chromium',
  headless: true,
  args: process.env.CI ? ['--no-sandbox'] : [],
})
const page = await browser.newPage()
const base = process.env.BASE || 'http://127.0.0.1:4013'
const shots = 'test/qa/screenshots/provenance'
await fs.mkdir(shots, {recursive: true})
try {
  for (const theme of ['light', 'dark']) {
    for (const width of [1200, 390]) {
      await page.setViewport({width, height: 720})
      await page.emulateMediaFeatures([
        {name: 'prefers-color-scheme', value: theme},
        {name: 'prefers-reduced-motion', value: 'reduce'},
      ])
      await page.goto(`${base}/provenance`)
      await page.waitForSelector('.phx-connected')
      assert.deepEqual(await page.$$eval('.lui-provenance-badge', els => els.map(e => e.dataset.state)),
        ['override', 'own', 'inherited', 'current', 'historical', 'unknown'])
      assert.equal(await page.$eval('html', e => e.scrollWidth <= innerWidth), true)
      assert.equal(await page.$eval('#revert-api', e => e.getAttribute('aria-label')), 'Revert API branch to Production')
      assert.equal(await page.$$eval('.lui-provenance-badge', els => els.every(e => getComputedStyle(e).animationName === 'none')), true)
      await page.keyboard.press('Tab')
      assert.equal(await page.$eval('#revert-api', e => e === document.activeElement), true)
      await page.screenshot({path: `${shots}/${width}-${theme}.png`, fullPage: true})
      await page.keyboard.press(theme === 'light' ? 'Enter' : 'Space')
      await page.waitForSelector('#api-origin[data-state="inherited"]')
      assert.equal(await page.$('#revert-api'), null)
      assert.equal(await page.$eval('#api-origin', e => e.textContent.trim()), 'Inherited from Production')
    }
  }
  console.log('Provenance: light/dark × desktop/mobile, reduced motion, Tab/Enter/Space and LiveView revert passed')
} finally {
  await browser.close()
}
