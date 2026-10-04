// eval/shot.mjs — screenshot + axe a11y smoke for one eval combo.
// Usage: node eval/shot.mjs <url> <screenshot-png> <axe-json>
// Uses puppeteer-core (ESM) against system Chrome (executablePath per eval contract).
import puppeteer from "puppeteer-core";
import axe from "axe-core";
import fs from "node:fs";

const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const [url, shotPath, axePath] = process.argv.slice(2);
const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: "new",
  args: ["--no-sandbox", "--disable-gpu", "--window-size=1280,900"],
});
try {
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });
  await page.goto(url, { waitUntil: "networkidle0", timeout: 30000 });
  // Let LiveView connect + charts render.
  await new Promise((r) => setTimeout(r, 2500));
  await page.screenshot({ path: shotPath });
  await page.evaluate(axe.source);
  const results = await page.evaluate(() => axe.run(document));
  const violations = results.violations.map((v) => ({
    id: v.id,
    impact: v.impact,
    nodes: v.nodes.length,
    help: v.help,
  }));
  fs.writeFileSync(axePath, JSON.stringify({ violations }, null, 2));
  console.log(`shot ok, axe violations: ${violations.length}`);
} finally {
  await browser.close();
}
