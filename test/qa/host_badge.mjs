// Run against the standalone QA host; PUPPETEER_CORE may point to an external install.
import {createRequire} from 'node:module';
const require = createRequire(import.meta.url);
const puppeteer = require(process.env.PUPPETEER_CORE || 'puppeteer-core');
import {mkdirSync} from 'node:fs';
import assert from 'node:assert/strict';
const out = process.cwd() + '/test/qa/screenshots/host-badge';
mkdirSync(out, {recursive: true});
const browser = await puppeteer.launch({executablePath:process.env.CHROME_PATH || '/usr/bin/chromium',args:['--no-sandbox']});
try {
const page = await browser.newPage();
await page.setViewport({width:800,height:440,deviceScaleFactor:1});
const failures=[];
page.on('pageerror', e=>failures.push(e.message));
for (const theme of ['light','dark']) {
  await page.emulateMediaFeatures([{name:'prefers-color-scheme',value:theme},{name:'prefers-reduced-motion',value:'reduce'}]);
  await page.goto(`${process.env.BASE || 'http://127.0.0.1:4013'}/host_badge`, {waitUntil:'networkidle0'});
  await page.screenshot({path:`${out}/${theme}.png`});
  const badges = await page.$$eval('.lui-host-badge', nodes => nodes.map(n=>({text:n.textContent.trim(),disabled:n.getAttribute('aria-disabled'),tag:n.tagName,tab:n.tabIndex,animation:getComputedStyle(n).animationName,color:getComputedStyle(n).color})));
  assert.equal(badges.length, 5);
  assert.notEqual(badges[0].color, badges[3].color);
  assert.equal(badges.filter(n=>n.disabled==='true').length,2);
  assert.ok(badges.every(n=>n.tag==='SPAN' && n.tab===-1 && n.animation==='none'));
  await page.keyboard.press('Tab');
  assert.equal(await page.evaluate(()=>document.activeElement.value),'flicker');
  await page.keyboard.press('Tab');
  assert.equal(await page.evaluate(()=>document.activeElement.tagName),'BODY');
  await page.click('input[value="fly"]');
  assert.equal(await page.$eval('input:checked',n=>n.value),'flicker');
}
assert.deepEqual(failures,[]);
} finally { await browser.close(); }
console.log('PASS: light/dark reduced-motion rendering, keyboard skips badges and unavailable choices, disabled click preserves selection; no browser errors.');
