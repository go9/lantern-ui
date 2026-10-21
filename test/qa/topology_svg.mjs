// Start the QA host, then: node test/qa/topology_svg.mjs
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import puppeteer from 'puppeteer-core';

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH || '/usr/bin/chromium',
  args: ['--no-sandbox'], headless: true,
});
const shots = process.env.QA_SHOTS || '/tmp/lantern-topology-svg';
await fs.mkdir(shots, { recursive: true });
try {
  for (const theme of ['light', 'dark']) {
    for (const width of [960, 390]) {
      const page = await browser.newPage();
      await page.setViewport({width, height: 420, deviceScaleFactor: 1});
      await page.emulateMediaFeatures([
        { name: 'prefers-color-scheme', value: theme },
        { name: 'prefers-reduced-motion', value: 'reduce' },
      ]);
      await page.goto(`${process.env.BASE || 'http://127.0.0.1:4013'}/topology_svg`);
      await page.waitForSelector('.phx-connected');
      await page.keyboard.press('Tab');
      assert.equal(await page.evaluate(() => document.activeElement.id), 'topology');
      await page.keyboard.press('Tab');
      assert.equal(await page.evaluate(() => document.activeElement.dataset.node), 'web');
      await page.keyboard.press('Tab');
      await page.keyboard.press('Enter');
      await page.waitForFunction(() => document.querySelector('#picked').textContent === 'worker');
      assert.equal(await page.$eval('[data-node=worker]', (el) => el.getAttribute('aria-pressed')), 'true');
      await page.screenshot({ path: `${shots}/${width}-${theme}.png` });
      await page.close();
    }
  }
} finally {
  await browser.close();
}
