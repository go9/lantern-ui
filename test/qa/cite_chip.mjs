// Start the QA host, then: node test/qa/cite_chip.mjs
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import puppeteer from 'puppeteer-core';

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH || '/usr/bin/chromium',
  args: ['--no-sandbox'], headless: true,
});
const shots = process.env.QA_SHOTS || '/tmp/lantern-cite-chip';
await fs.mkdir(shots, { recursive: true });
try {
  for (const theme of ['light', 'dark']) {
    for (const width of [960, 390]) {
      const page = await browser.newPage();
      await page.setViewport({width, height: 620, deviceScaleFactor: 1});
      await page.emulateMediaFeatures([
        { name: 'prefers-color-scheme', value: theme },
        { name: 'prefers-reduced-motion', value: 'reduce' },
      ]);
      await page.goto(`${process.env.BASE || 'http://127.0.0.1:4013'}/cite_chip`);
      await page.waitForSelector('.phx-connected');
      await page.keyboard.press('Tab');
      assert.equal(await page.evaluate(() => document.activeElement.id), 'cite-file');
      await page.keyboard.press('Enter');
      await page.waitForSelector('#cite-file[aria-pressed="true"]');
      assert.match(await page.$eval('#source-preview', el => el.textContent), /lib\/search.ex:12–18/);
      await page.keyboard.press('Tab');
      assert.equal(await page.evaluate(() => document.activeElement.id), 'cite-ticket');
      await page.keyboard.press('Space');
      await page.waitForSelector('#cite-ticket[aria-pressed="true"]');
      assert.equal(await page.$eval('#cite-file', el => el.getAttribute('aria-pressed')), 'false');
      assert.equal(await page.evaluate(() => document.activeElement.id), 'cite-ticket');
      await page.keyboard.press('Tab');
      await page.keyboard.press('Enter');
      await page.waitForSelector('#cite-memory[aria-pressed="true"]');
      assert.match(await page.$eval('#source-preview', el => el.textContent), /Memory 167/);
      assert.equal(await page.$eval('#cite-memory', el => getComputedStyle(el).transitionDuration), '0s');
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      await page.screenshot({path: `${shots}/${width}-${theme}.png`});
      console.log(`PASS ${width} ${theme}: Tab, Enter, Space, preview, focus retention, reduced motion, no overflow`);
      await page.close();
    }
  }
} finally {
  await browser.close();
}
