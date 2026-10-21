// Run with the QA host on PORT=4027; writes light/dark/mobile evidence.
import puppeteer from 'puppeteer-core';
import assert from 'node:assert/strict';
const browser = await puppeteer.launch({executablePath:process.env.CHROME_PATH || '/usr/bin/chromium',args:['--no-sandbox']});
try {
const page = await browser.newPage();
const errors=[];
page.on('pageerror', e=>errors.push(e.message));
for (const [theme,width] of [['light',960],['dark',960],['light',390]]) {
 await page.setViewport({width,height:600,deviceScaleFactor:2});
 await page.emulateMediaFeatures([{name:'prefers-color-scheme',value:theme},{name:'prefers-reduced-motion',value:'reduce'}]);
 await page.goto(`${process.env.BASE || 'http://127.0.0.1:4027'}/stage_strip`);
 await page.waitForSelector('.lui-stage-strip-pip');
 assert.equal(await page.$$eval('#suggestion-19 .lui-stage-strip-pip', els=>els.length),6);
 const styles=await page.$$eval('.lui-stage-strip-pip',els=>els.map(el=>{const s=getComputedStyle(el);return {width:el.getBoundingClientRect().width,height:el.getBoundingClientRect().height,animation:s.animationName,transition:s.transitionDuration,border:s.borderStyle,borderWidth:s.borderTopWidth,state:el.dataset.state}}));
 assert(styles.every(s=>s.width>0 && s.height>0 && s.animation==='none' && s.transition==='0s'));
 assert(styles.some(s=>s.state==='skipped' && s.border==='dashed'));
 assert(styles.some(s=>s.state==='failed' && s.border==='solid' && parseFloat(s.borderWidth)>0));
 assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 await page.keyboard.press('Tab');
 assert.equal(await page.evaluate(()=>document.activeElement.id),'suggestion-19');
 await page.screenshot({path:`docs/qa-stage-strip/${theme}-${width}.png`,fullPage:true});
}
assert.deepEqual(errors,[]);
console.log('PASS: light/dark/mobile, ordered pips, borders, reduced motion, keyboard link, no overflow or browser errors');
} finally {await browser.close()}
