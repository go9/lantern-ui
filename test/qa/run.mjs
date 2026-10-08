// Real-browser floating-panel matrix (flicker #3480). Opens every floating
// component inside every hostile layout context at 1440 and 390 wide, with
// real mouse/keyboard events, and asserts the open panel is
//   - anchored to its trigger (flipped/shifted, not stranded), and
//   - not clipped or covered (elementFromPoint at the panel's corners/edges).
//
//   MIX_ENV=test PORT=4013 mix run test/qa/server.exs &
//   BASE=http://127.0.0.1:4013 PUPPETEER_CORE=/path/to/node_modules/puppeteer-core \
//     node test/qa/run.mjs [--ctx=card,modal] [--cmp=select] [--vw=390]
//
// QA_SHOTS=dir  screenshot directory for failures (default /tmp/lantern-qa)
// QA_REPORT_ONLY=1  print the matrix, exit 0 even with failures
// --page-shell-wide-table  run only the page_shell horizontal reachability check
import { createRequire } from "node:module"
import fs from "node:fs"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const BASE = process.env.BASE || "http://127.0.0.1:4013"
const SHOTS = process.env.QA_SHOTS || "/tmp/lantern-qa"
const CHROME = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const arg = (n) => process.argv.find((a) => a.startsWith(`--${n}=`))?.split("=")[1]?.split(",")

const CTXS = arg("ctx") || "plain card card_transform scroll table modal sheet side_panel scroll_area data_table edge_br edge_bl sticky tall patch nested".split(" ")
const CMPS = arg("cmp") || "select select_search dropdown menu popover tooltip autocomplete date_picker command user_menu".split(" ")
const VWS = (arg("vw") || ["1440", "390"]).map(Number)
const WIDE_TABLE_ONLY = process.argv.includes("--page-shell-wide-table")

// trigger: where the real click/hover lands. panel: the floating surface.
const SPEC = {
  select: { trigger: "#qa-sub", panel: '[data-scope="select"][data-part="content"]' },
  select_search: { trigger: "#qa-sub", panel: ".lui-select-listbox" },
  dropdown: { trigger: "#qa-sub button", panel: "#qa-sub .lui-dropdown-menu" },
  menu: { trigger: '#qa-sub [data-part="trigger"]', panel: '#qa-sub [data-part="content"]' },
  user_menu: { trigger: '#qa-sub [data-part="trigger"]', panel: '#qa-sub [data-part="content"]' },
  popover: { trigger: '#qa-sub [data-part="trigger"] button', panel: '#qa-sub [data-part="content"]' },
  tooltip: { trigger: "#qa-sub button", panel: '#qa-sub [data-part="content"]', hover: true },
  autocomplete: { trigger: "#qa-sub", panel: "#qa-sub-listbox", type: "a" },
  date_picker: { trigger: ".lui-picker-toggle", panel: ".lui-picker-panel" },
  command: { trigger: "#qa-sub-trigger", panel: "#qa-sub .lui-command-panel", viewportAnchored: true },
}

const visible = `(el) => { const r = el.getBoundingClientRect(); const s = getComputedStyle(el);
  return r.width > 0 && r.height > 0 && s.visibility !== "hidden" && s.display !== "none" && !el.closest("[hidden]") }`

// Measure the open panel against its trigger. Returns {open, problems[], rects}.
async function measure(page, spec) {
  return page.evaluate(
    (spec, visibleSrc) => {
      const isVisible = eval(visibleSrc)
      const panel = [...document.querySelectorAll(spec.panel)].find(isVisible)
      const trig = document.querySelector(spec.trigger)
      if (!panel) return { open: false, problems: ["closed"] }
      const vw = innerWidth, vh = innerHeight
      const pr = panel.getBoundingClientRect(), tr = trig ? trig.getBoundingClientRect() : null
      const problems = []

      // Clipped / covered: sample a grid inside the visible part of the panel.
      const x0 = Math.max(pr.left, 0) + 8, x1 = Math.min(pr.right, vw) - 8
      const y0 = Math.max(pr.top, 0) + 8, y1 = Math.min(pr.bottom, vh) - 8
      let bad = 0, total = 0
      // Tooltips are pointer-events:none by design; probe with them on.
      const prevPE = panel.style.pointerEvents
      panel.style.pointerEvents = "auto"
      if (x1 > x0 && y1 > y0) {
        for (const fx of [0, 0.5, 1]) for (const fy of [0, 0.5, 1]) {
          const el = document.elementFromPoint(x0 + (x1 - x0) * fx, y0 + (y1 - y0) * fy)
          total++
          if (!el || !(panel.contains(el) || el.contains(panel) && el === panel)) bad++
        }
      } else problems.push("offscreen")
      panel.style.pointerEvents = prevPE
      if (bad) problems.push(`clipped ${bad}/${total}`)

      // Escaped the viewport (shift/flip/max-height missing).
      const out = Math.max(-pr.left, -pr.top, pr.right - vw, pr.bottom - vh)
      if (out > 2) problems.push(`outside viewport by ${Math.round(out)}px`)

      // Anchored to the trigger: nearest edge-to-edge gap.
      if (tr && !spec.viewportAnchored) {
        const dx = Math.max(tr.left - pr.right, pr.left - tr.right, 0)
        const dy = Math.max(tr.top - pr.bottom, pr.top - tr.bottom, 0)
        const gap = Math.hypot(dx, dy)
        // overlap on one axis is fine (below/above/side), the other must be near
        if (gap > 24) problems.push(`detached from trigger by ${Math.round(gap)}px`)
      }
      const r = (x) => x && { x: Math.round(x.left), y: Math.round(x.top), w: Math.round(x.width), h: Math.round(x.height) }
      return { open: true, problems, panel: r(pr), trigger: r(tr) }
    },
    spec,
    visible,
  )
}

async function open(page, spec) {
  await page.waitForSelector(spec.trigger, { visible: true, timeout: 4000 })
  const h = await page.$(spec.trigger)
  await h.evaluate((el) => el.scrollIntoView({ block: "center", inline: "nearest" }))
  await sleep(100)
  const box = await h.boundingBox()
  const x = box.x + box.width / 2, y = box.y + box.height / 2
  if (spec.hover) {
    await page.mouse.move(x - 30, y)
    await page.mouse.move(x, y, { steps: 4 })
    await sleep(600)
  } else {
    await page.mouse.click(x, y)
    if (spec.type) await page.keyboard.type(spec.type, { delay: 30 })
    await sleep(500)
  }
}

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: "new",
  args: ["--no-sandbox"],
})
fs.mkdirSync(SHOTS, { recursive: true })
const rows = []

for (const vw of VWS) {
  if (WIDE_TABLE_ONLY) continue
  const page = await browser.newPage()
  const h = vw < 600 ? 844 : 900
  await page.setViewport({ width: vw, height: h })
  const errors = []
  page.on("pageerror", (e) => errors.push(e.message))
  for (const ctx of CTXS) {
    for (const cmp of CMPS) {
      const spec = SPEC[cmp]
      const row = { vw, ctx, cmp, problems: [] }
      try {
        await page.setViewport({ width: vw, height: h })
        await page.goto(`${BASE}/qa?ctx=${ctx}&cmp=${cmp}`, { waitUntil: "networkidle2" })
        await page.waitForSelector(".phx-connected", { timeout: 8000 })
        await sleep(500)
        if (ctx === "sticky") {
          await page.evaluate(() => scrollTo(0, 300))
          await sleep(150)
        }
        errors.length = 0
        // The dialog hosting the component must itself cover the viewport.
        const dlg = await page.evaluate(() => {
          const c = document.querySelector('#qa-modal [data-part="content"], #qa-sheet [data-part="content"]')
          if (!c) return null
          const r = c.getBoundingClientRect()
          const el = document.elementFromPoint(r.left + r.width / 2, r.top + Math.min(r.height / 2, 40))
          return { covered: !!el && c.contains(el), w: r.width, h: r.height, inView: r.left >= -1 && r.top >= -1 && r.right <= innerWidth + 1 && r.bottom <= innerHeight + 1 }
        })
        if (dlg && (!dlg.covered || !dlg.inView)) row.problems.push("dialog clipped by an ancestor")
        await open(page, spec)
        const steps = [["open", await measure(page, spec)]]
        if (steps[0][1].open) {
          if (ctx === "tall") {
            await page.mouse.wheel({ deltaY: 220 })
            await sleep(400)
            steps.push(["scrolled", await measure(page, spec)])
            await page.setViewport({ width: Math.max(vw - 80, 320), height: h - 120 })
            await sleep(500)
            steps.push(["resized", await measure(page, spec)])
          } else if (ctx === "scroll") {
            const s = await (await page.$("#qa-scroller")).boundingBox()
            await page.mouse.move(s.x + 4, s.y + 4)
            await page.mouse.wheel({ deltaY: 40 })
            await sleep(400)
            steps.push(["scroller scrolled", await measure(page, spec)])
          } else if (ctx === "patch") {
            await page.evaluate(() => window.liveSocket.execJS(document.querySelector("#qa-root"), '[["push",{"event":"bump"}]]'))
            await sleep(600)
            steps.push(["patched", await measure(page, spec)])
          }
        }
        for (const [name, m] of steps) {
          // Tooltips legitimately dismiss on scroll/resize.
          if (cmp === "tooltip" && !m.open && name !== "open") continue
          if (m.problems.length) row.problems.push(...m.problems.map((p) => (steps.length > 1 ? `${name}: ${p}` : p)))
        }
        row.rects = steps.at(-1)[1].panel && { panel: steps.at(-1)[1].panel, trigger: steps.at(-1)[1].trigger }
        if (errors.length) row.problems.push(`pageerror: ${errors[0]}`)
        if (row.problems.length) {
          await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}-${cmp}.png` })
        }
      } catch (e) {
        row.problems.push(`error: ${e.message.split("\n")[0]}`)
        await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}-${cmp}.png` }).catch(() => {})
      }
      row.status = row.problems.length ? "FAIL" : "ok"
      rows.push(row)
      if (row.problems.length) console.log(`FAIL ${vw} ${ctx}/${cmp}: ${row.problems.join("; ")}`)
    }
  }
  await page.close()
}

// A page shell must keep wide non-fill table columns reachable without making
// the document itself horizontally scroll. The table wrapper owns the scroll.
if (VWS.includes(390)) {
  const page = await browser.newPage()
  await page.setViewport({ width: 390, height: 844 })
  const row = { vw: 390, ctx: "page_shell", cmp: "wide-table-scroll", problems: [] }

  try {
    await page.goto(`${BASE}/qa?ctx=page_shell`, { waitUntil: "networkidle2" })
    await page.waitForSelector(".phx-connected", { timeout: 8000 })
    await page.waitForSelector("#qa-shell-table .lui-table-wrap", { timeout: 4000 })
    const result = await page.evaluate(() => {
      const wrapper = document.querySelector("#qa-shell-table .lui-table-wrap")
      const headers = [...wrapper.querySelectorAll("thead th")]
      const last = headers.at(-1)
      const overflows = wrapper.scrollWidth > wrapper.clientWidth + 1
      const documentOverflows = document.documentElement.scrollWidth > innerWidth + 1

      wrapper.scrollLeft = wrapper.scrollWidth
      const wrapperRect = wrapper.getBoundingClientRect()
      const lastRect = last.getBoundingClientRect()

      return {
        columns: headers.length,
        overflows,
        documentOverflows,
        scrollLeft: wrapper.scrollLeft,
        lastColumnVisible:
          lastRect.left >= wrapperRect.left - 1 && lastRect.right <= wrapperRect.right + 1,
      }
    })

    if (result.columns !== 9) row.problems.push(`expected 9 columns, found ${result.columns}`)
    if (!result.overflows) row.problems.push("wide table has no horizontal scroll range")
    if (result.documentOverflows) row.problems.push("document overflows horizontally")
    if (result.scrollLeft <= 0) row.problems.push("table wrapper did not scroll horizontally")
    if (!result.lastColumnVisible) row.problems.push("last table column is not reachable after scrolling")
    row.scroll = result
    if (row.problems.length) await page.screenshot({ path: `${SHOTS}/390-page-shell-wide-table.png` })
  } catch (e) {
    row.problems.push(`error: ${e.message.split("\n")[0]}`)
    await page.screenshot({ path: `${SHOTS}/390-page-shell-wide-table.png` }).catch(() => {})
  }

  row.status = row.problems.length ? "FAIL" : "ok"
  rows.push(row)
  if (row.problems.length) console.log(`FAIL 390 page_shell/wide-table-scroll: ${row.problems.join("; ")}`)
  await page.close()
}

await browser.close()

const bucket = (re) => rows.filter((r) => r.problems.some((p) => re.test(p))).length
const failed = rows.filter((r) => r.problems.length)
console.log(
  `\n${rows.length} cases, ${failed.length} failing — clipped/covered: ${bucket(/^(.*: )?(clipped|offscreen)/)}, ` +
    `misplaced (detached/outside viewport): ${bucket(/detached|outside viewport/)}, closed: ${bucket(/closed/)}, errors: ${bucket(/error/)}`,
)
fs.writeFileSync(`${SHOTS}/matrix.json`, JSON.stringify(rows, null, 1))
process.exit(failed.length && !process.env.QA_REPORT_ONLY ? 1 : 0)
