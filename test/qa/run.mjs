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
const CHARTS_ONLY = process.argv.includes("--charts")
const SHELL_VWS = [1440, 1100, 768, 390]

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

if (CHARTS_ONLY) {
  const types = ["line", "area", "stacked_area", "bar", "stacked_bar", "grouped_bar", "points"]
  for (const vw of VWS) {
    for (const theme of ["light", "dark"]) {
      for (const type of types) {
        const page = await browser.newPage()
        await page.setViewport({ width: vw, height: vw < 600 ? 844 : 900, isMobile: vw < 600, hasTouch: vw < 600 })
        const errors = []
        page.on("pageerror", (error) => errors.push(error.message))
        const row = { vw, theme, type, problems: [] }

        try {
          await page.goto(`${BASE}/charts?type=${type}&theme=${theme}`, { waitUntil: "networkidle2" })
          await page.waitForSelector(".phx-connected", { timeout: 8000 })
          await page.waitForSelector("#qa-time-series svg", { timeout: 4000 })
          await sleep(300)
          const box = await page.$eval("#qa-time-series svg", (svg) => {
            const rect = svg.getBoundingClientRect()
            return { width: rect.width, height: rect.height }
          })
          if (!box.width || !box.height) row.problems.push("chart SVG has no visible dimensions")
          if (type === "line") {
            const initialHidden = await page.$eval('#qa-time-series .lui-time-series-chart__interaction', (overlay) => overlay.hasAttribute("hidden") && getComputedStyle(overlay).display === "none")
            if (!initialHidden) row.problems.push("chart hover overlay is visible before the first interaction")
            const chartShots = `${SHOTS}/charts`
            await page.screenshot({ path: `${chartShots}/${vw}-${theme}-line.png`, fullPage: true })
            await page.evaluate(() => document.querySelector('[data-chart-point="0"]')?.focus())
            await page.keyboard.press("ArrowRight")
            const keyboard = await page.$eval('#qa-time-series [data-part="live"]', (el) => el.textContent)
            if (!keyboard || !keyboard.includes(": ")) row.problems.push("keyboard point focus did not announce series values")
            const chartInfo = await page.$eval("#qa-time-series svg", (svg) => {
              const rect = svg.getBoundingClientRect()
              return {
                rect: { left: rect.left, top: rect.top, width: rect.width, height: rect.height },
                viewBox: { width: svg.viewBox.baseVal.width, height: svg.viewBox.baseVal.height },
                points: JSON.parse(svg.parentElement.dataset.interaction),
                tooltip: (() => {
                  const node = svg.querySelector('[data-part="tooltip"]')
                  return Object.fromEntries(["plotLeft", "plotRight", "plotTop", "plotBottom"].map((key) => [key, Number(node.dataset[key])]))
                })(),
              }
            })
            const shotDir = `${SHOTS}/charts`
            const pointClient = (point) => ({
              x: chartInfo.rect.left + point.x / chartInfo.viewBox.width * chartInfo.rect.width,
              y: chartInfo.rect.top + (point.positions.find((position) => position)?.y || 80) / chartInfo.viewBox.height * chartInfo.rect.height,
            })
            const verifyTooltip = async (label) => {
              await page.waitForFunction((expected) => {
                const crosshair = document.querySelector('#qa-time-series [data-part="crosshair"]')
                const tooltip = document.querySelector('#qa-time-series [data-part="tooltip-date"]')
                return crosshair && !crosshair.closest("g[hidden]") && tooltip?.textContent === expected
              }, { timeout: 2000 }, label)
              const measured = await page.$eval("#qa-time-series svg", (svg) => {
                const rect = svg.getBoundingClientRect()
                const scale = rect.width / svg.viewBox.baseVal.width
                const tooltip = svg.querySelector('[data-part="tooltip"]')
                const tip = tooltip.querySelector("rect").getBoundingClientRect()
                const crosshair = svg.querySelector('[data-part="crosshair"]').getBoundingClientRect()
                return {
                  left: tip.left, right: tip.right,
                  plotLeft: rect.left + Number(tooltip.dataset.plotLeft) * scale,
                  plotRight: rect.left + Number(tooltip.dataset.plotRight) * scale,
                  crosshairX: crosshair.left,
                  visible: !svg.querySelector('[data-part="crosshair"]').closest("g[hidden]") && getComputedStyle(svg.querySelector('[data-part="crosshair"]').closest("g")).display !== "none",
                  label: tooltip.querySelector('[data-part="tooltip-date"]').textContent,
                }
              })
              if (!measured.visible || measured.label !== label) row.problems.push(`${label}: interaction overlay did not select its point (visible=${measured.visible}, label=${JSON.stringify(measured.label)})`)
              if (measured.left < measured.plotLeft - 1 || measured.right > measured.plotRight + 1) row.problems.push(`${label}: tooltip escapes the plot edges`)
              return measured
            }
            const firstPoint = chartInfo.points[0]
            const lastPoint = chartInfo.points.at(-1)
            const firstClient = pointClient(firstPoint)
            const lastClient = pointClient(lastPoint)
            await page.mouse.move(firstClient.x, firstClient.y)
            await sleep(80)
            const mouseFirst = await verifyTooltip(firstPoint.label)
            await page.screenshot({ path: `${shotDir}/${vw}-${theme}-mouse-first.png`, fullPage: true })
            await page.screenshot({ path: `${shotDir}/${vw}-${theme}-interaction.png`, fullPage: true })
            await page.mouse.move(lastClient.x, lastClient.y)
            await sleep(80)
            const mouseLast = await verifyTooltip(lastPoint.label)
            if (Math.abs(mouseFirst.crosshairX - mouseLast.crosshairX) < 20 || Math.abs(mouseFirst.left - mouseLast.left) < 20) row.problems.push("mouse tooltip did not follow the crosshair between chart edges")
            await page.screenshot({ path: `${shotDir}/${vw}-${theme}-mouse-last.png`, fullPage: true })

            const touchMeasurements = []
            for (const [name, point, client] of [["touch-first", firstPoint, firstClient], ["touch-last", lastPoint, lastClient]]) {
              await page.$eval("#qa-time-series svg", (svg, at) => {
                svg.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerType: "touch", clientX: at.x, clientY: at.y }))
              }, client)
              await sleep(80)
              touchMeasurements.push(await verifyTooltip(point.label))
              await page.screenshot({ path: `${shotDir}/${vw}-${theme}-${name}.png`, fullPage: true })
            }
            row.touchTooltipEdges = touchMeasurements.map(({ left, right, crosshairX, label }) => ({ left, right, crosshairX, label }))
            if (Math.abs(touchMeasurements[0].left - touchMeasurements[1].left) < 20) row.problems.push(`touch tooltip did not follow the selected point between chart edges (${touchMeasurements[0].left} -> ${touchMeasurements[1].left})`)

            await page.evaluate(() => document.querySelector('[data-chart-point="0"]')?.focus())
            await page.keyboard.press("Home")
            await sleep(30)
            const keyboardFirst = await verifyTooltip(firstPoint.label)
            await page.screenshot({ path: `${shotDir}/${vw}-${theme}-keyboard-first.png`, fullPage: true })
            await page.keyboard.press("End")
            await sleep(30)
            const keyboardLast = await verifyTooltip(lastPoint.label)
            if (Math.abs(keyboardFirst.left - keyboardLast.left) < 20) row.problems.push("keyboard tooltip did not follow the selected point between chart edges")
            await page.screenshot({ path: `${shotDir}/${vw}-${theme}-keyboard-last.png`, fullPage: true })
            await page.keyboard.press("Escape")
            const keyboardDismissed = await page.$eval('#qa-time-series [data-part="crosshair"]', (el) => !!el.closest("g[hidden]"))
            if (!keyboardDismissed) row.problems.push("Escape did not dismiss the keyboard tooltip")
          }
          if (errors.length) row.problems.push(`pageerror: ${errors[0]}`)
          const dir = `${SHOTS}/charts`
          fs.mkdirSync(dir, { recursive: true })
          if (type !== "line") await page.screenshot({ path: `${dir}/${vw}-${theme}-${type}.png`, fullPage: true })
        } catch (error) {
          row.problems.push(`error: ${error.message.split("\n")[0]}`)
        }

        row.status = row.problems.length ? "FAIL" : "ok"
        rows.push(row)
        if (row.problems.length) console.log(`FAIL chart ${vw}/${theme}/${type}: ${row.problems.join("; ")}`)
        await page.close()
      }
    }
  }

  await browser.close()
  const failed = rows.filter((row) => row.problems.length)
  console.log(`\n${rows.length} chart screenshots, ${failed.length} failing`)
  fs.writeFileSync(`${SHOTS}/charts/matrix.json`, JSON.stringify(rows, null, 1))
  process.exit(failed.length ? 1 : 0)
}

for (const vw of VWS) {
  if (WIDE_TABLE_ONLY) continue
  const page = await browser.newPage()
  const h = vw < 600 ? 844 : 900
  await page.setViewport({ width: vw, height: h })
  const errors = []
  page.on("pageerror", (e) => errors.push(e.message))
  for (const ctx of CTXS) {
    if (ctx === "page_shell" || ctx === "action_bar" || ctx.startsWith("app_page_shell")) continue
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

// The shell contract is tested at each promotion boundary with both the
// default root size and a 62.5% root size. JS and CSS use CSS pixels, so the
// visible inline count must continue to match data-promoted under either size.
if (!WIDE_TABLE_ONLY) {
  for (const vw of SHELL_VWS) {
    for (const ctx of ["page_shell", "action_bar"]) {
      const page = await browser.newPage()
      await page.setViewport({ width: vw, height: 900 })
      const row = { vw, ctx, cmp: "shell-contract", problems: [] }

      try {
        await page.goto(`${BASE}/qa?ctx=${ctx}`, { waitUntil: "networkidle2" })
        await page.waitForSelector(".phx-connected", { timeout: 8000 })
        await page.waitForSelector("[data-action-bar]", { timeout: 4000 })

        if (ctx === "page_shell") {
          await page.screenshot({ path: `${SHOTS}/${vw}-page_shell-contract.png` })
          const shell = await page.evaluate(() => {
            const breadcrumb = document.querySelector("[data-page-breadcrumb]")
            const title = document.querySelector("h1[data-page-title]")
            const actions = document.querySelector("[data-page-actions]")
            const content = document.querySelector("[data-page-content]")
            const tokenHeight = (token, scope) => {
              const probe = document.createElement("div")
              probe.style.cssText = `position:absolute;height:var(${token})`
              scope.append(probe)
              const height = probe.getBoundingClientRect().height
              probe.remove()
              return height
            }
            return {
              breadcrumbCount: document.querySelectorAll("[data-page-breadcrumb]").length,
              titleCount: document.querySelectorAll("h1[data-page-title]").length,
              actionsCount: document.querySelectorAll("[data-page-actions]").length,
              toplineHeight: breadcrumb.getBoundingClientRect().height,
              toplineToken: tokenHeight("--lui-topline-h", breadcrumb.parentElement),
              actionHeight: actions.getBoundingClientRect().height,
              actionToken: tokenHeight("--lui-actionbar-h", actions.parentElement),
              contentInset: content.getBoundingClientRect().top - breadcrumb.getBoundingClientRect().bottom,
              documentOverflows: document.documentElement.scrollWidth > innerWidth + 1,
            }
          })
          if (shell.breadcrumbCount !== 1) row.problems.push("page_shell must render one breadcrumb row")
          if (shell.titleCount !== 1) row.problems.push("page_shell must render one sr-only h1")
          if (shell.actionsCount !== 1) row.problems.push("page_shell must render one actions region")
          if (Math.abs(shell.toplineHeight - shell.toplineToken) > 1) row.problems.push("topline height exceeds its token")
          if (Math.abs(shell.actionHeight - shell.actionToken) > 1) row.problems.push("action row height exceeds its token")
          if (Math.abs(shell.contentInset - shell.actionHeight) > 1) row.problems.push("content inset does not equal the floating row height")
          if (shell.documentOverflows) row.problems.push("page_shell document overflows horizontally")
          row.shell = shell

          const alerts = await page.evaluate(() => {
            const expected = (id) => {
              const alert = document.getElementById(id)
              const ref = alert.cloneNode(false)
              ref.removeAttribute("id")
              ref.style.background = "color-mix(in oklab, var(--lui-alert-c) 14%, var(--lantern-surface-raised))"
              alert.parentElement.append(ref)
              const result = {
                actual: getComputedStyle(alert).backgroundColor,
                expected: getComputedStyle(ref).backgroundColor,
              }
              ref.remove()
              return result
            }
            const root = document.documentElement
            const scoped = document.getElementById("qa-scoped-theme")
            root.classList.remove("dark")
            root.classList.add("light")
            const light = expected("qa-default-info-alert")
            root.classList.remove("light")
            root.classList.add("dark")
            const dark = expected("qa-default-info-alert")
            root.classList.remove("dark")
            root.classList.add("light")
            scoped.classList.add("dark")
            const nested = expected("qa-scoped-info-alert")
            return { light, dark, nested }
          })
          for (const [name, colors] of Object.entries(alerts)) {
            if (colors.actual !== colors.expected) row.problems.push(`${name} default alert background changed: ${colors.actual} != ${colors.expected}`)
          }
          if (alerts.light.actual === alerts.dark.actual) row.problems.push("default and dark themes did not produce distinct alert backgrounds")
          if (alerts.light.actual === alerts.nested.actual) row.problems.push("nested scoped dark theme did not produce a distinct alert background")
          row.alertBackgrounds = alerts
        } else {
          await page.screenshot({ path: `${SHOTS}/${vw}-action_bar-contract.png` })
        }

        for (const rootSize of ["100%", "62.5%"] ) {
          await page.evaluate((size) => { document.documentElement.style.fontSize = size }, rootSize)
          await sleep(80)
          const promotion = await page.evaluate(() => {
            const bar = document.querySelector("[data-action-bar]")
            const width = bar.getBoundingClientRect().width
            const promoted = bar.dataset.promoted
            const visible = [...bar.querySelectorAll("[data-part='inline-actions'] > .lui-action-bar-action")]
              .filter((action) => getComputedStyle(action).display !== "none").length
            const expected = width > 1100 ? "3" : width >= 740 ? "2" : "1"
            return { width, promoted, visible, expected }
          })
          if (promotion.promoted !== promotion.expected) row.problems.push(`${rootSize} promotion tier ${promotion.promoted} != ${promotion.expected} at ${Math.round(promotion.width)}px`)
          if (promotion.visible !== Number(promotion.promoted)) row.problems.push(`${rootSize} visible inline count ${promotion.visible} != data-promoted ${promotion.promoted}`)
          row[`promotion_${rootSize}`] = promotion
        }

        if (ctx === "page_shell") {
          await page.goto(`${BASE}/qa?ctx=page_shell&shell_empty=1`, { waitUntil: "networkidle2" })
          await page.waitForSelector(".phx-connected", { timeout: 8000 })
          const emptyShell = await page.evaluate(() => {
            const shell = document.querySelector("[data-page-shell]")
            const breadcrumb = shell.querySelector("[data-page-breadcrumb]")
            const content = shell.querySelector("[data-page-content]")
            return {
              actions: shell.querySelectorAll("[data-page-actions]").length,
              hooks: shell.querySelectorAll("[phx-hook='LanternActionBar']").length,
              marker: shell.hasAttribute("data-page-has-actions"),
              contentGap: content.getBoundingClientRect().top - breadcrumb.getBoundingClientRect().bottom,
            }
          })
          if (emptyShell.actions || emptyShell.hooks || emptyShell.marker) row.problems.push("empty page_shell rendered an empty action row")
          if (Math.abs(emptyShell.contentGap) > 1) row.problems.push("empty page_shell left a content inset")
          row.emptyShell = emptyShell

          await page.goto(`${BASE}/qa?ctx=page_shell&shell_dismissed_notice=1`, { waitUntil: "networkidle2" })
          await page.waitForSelector(".phx-connected", { timeout: 8000 })
          const dismissedShell = await page.evaluate(() => {
            const shell = document.querySelector("[data-page-shell]")
            return {
              actions: shell.querySelectorAll("[data-page-actions]").length,
              hooks: shell.querySelectorAll("[phx-hook='LanternActionBar']").length,
              marker: shell.hasAttribute("data-page-has-actions"),
              contentGap:
                shell.querySelector("[data-page-content]").getBoundingClientRect().top -
                shell.querySelector("[data-page-breadcrumb]").getBoundingClientRect().bottom,
            }
          })
          if (dismissedShell.actions || dismissedShell.hooks || dismissedShell.marker) {
            row.problems.push("server-dismissed notice without actions rendered an empty action row")
          }
          if (Math.abs(dismissedShell.contentGap) > 1) row.problems.push("dismissed notice left a page-shell content inset")
          row.dismissedShell = dismissedShell
        }

        if (vw < 740) {
          const notice = await page.evaluate(() => {
            const pill = document.querySelector("[data-action-bar-notice]")
            if (!pill) return null
            const title = pill.querySelector(".lui-alert-title")
            const subtitle = pill.querySelector(".lui-alert-subtitle")
            const titleRect = title?.getBoundingClientRect()
            return {
              label: pill.getAttribute("aria-label"),
              title: title?.textContent.trim(),
              titleVisible: !!titleRect && titleRect.width > 0 && titleRect.height > 0,
              titleWhiteSpace: title && getComputedStyle(title).whiteSpace,
              titleOverflow: title && getComputedStyle(title).textOverflow,
              subtitleDisplay: subtitle && getComputedStyle(subtitle).display,
            }
          })
          if (
            notice &&
            (!notice.label?.includes("All items are up to date.") ||
              !notice.titleVisible ||
              notice.titleWhiteSpace !== "nowrap" ||
              notice.titleOverflow !== "ellipsis" ||
              notice.subtitleDisplay !== "none")
          ) {
            row.problems.push("mobile notice must show a one-line title and expose its full message")
          }
          row.mobileNotice = notice
        }
      } catch (e) {
        row.problems.push(`error: ${e.message.split("\n")[0]}`)
        await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}-contract.png` }).catch(() => {})
      }

      row.status = row.problems.length ? "FAIL" : "ok"
      rows.push(row)
      if (row.problems.length) console.log(`FAIL ${vw} ${ctx}/shell-contract: ${row.problems.join("; ")}`)
      await page.close()
    }
  }
}

// The app shell's appbar is fixed. Verify nested page-shell sticky chrome at
// both appbar sizes, including mobile where the document is the scrollport.
for (const vw of [1440, 768, 390]) {
  for (const ctx of ["app_page_shell", "app_page_shell_compact"]) {
    const page = await browser.newPage()
    const h = vw < 600 ? 844 : 900
    await page.setViewport({ width: vw, height: h })
    const row = { vw, ctx, cmp: "app-shell-sticky-offsets", problems: [] }

    try {
      await page.goto(`${BASE}/qa?ctx=${ctx}`, { waitUntil: "networkidle2" })
      await page.waitForSelector(".phx-connected", { timeout: 8000 })
      await page.waitForSelector(".lui-appbar", { timeout: 4000 })
      await page.waitForSelector("#qa-app-shell-table .lui-table-wrap .lui-th", { timeout: 4000 })
      await page.evaluate(async () => {
        const main = document.querySelector(".lui-app-main")
        if (getComputedStyle(main).overflowY === "auto") main.scrollTop = 64
        else window.scrollTo(0, 64)
        const table = document.querySelector("#qa-app-shell-table .lui-table-wrap")
        table.scrollTop = 120
        await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
      })
      await sleep(80)

      const measurements = await page.evaluate(() => {
        const rect = (selector) => {
          const r = document.querySelector(selector).getBoundingClientRect()
          return { top: r.top, bottom: r.bottom, height: r.height }
        }
        const appbar = rect(".lui-appbar")
        const topline = rect("[data-page-breadcrumb]")
        const actions = rect("[data-page-actions]")
        const wrapper = rect("#qa-app-shell-table .lui-table-wrap")
        const header = rect("#qa-app-shell-table .lui-table-wrap .lui-th")
        const main = document.querySelector(".lui-app-main")
        const tableScrollport = document.querySelector("#qa-app-shell-table .lui-table-wrap")
        const notice = document.querySelector("[data-action-bar-notice]")
        return {
          appbar,
          topline,
          actions,
          wrapper,
          header,
          compact: document.querySelector(".lui-app").hasAttribute("data-compact"),
          pageScrollTop: getComputedStyle(main).overflowY === "auto" ? main.scrollTop : window.scrollY,
          tableScrollTop: tableScrollport.scrollTop,
          noticeLabel: notice?.getAttribute("aria-label"),
          documentOverflows: document.documentElement.scrollWidth > innerWidth + 1,
        }
      })

      const separated = (upper, lower) => lower.top >= upper.bottom - 1
      if (!separated(measurements.appbar, measurements.topline)) row.problems.push("topline overlaps the fixed appbar")
      if (!separated(measurements.topline, measurements.actions)) row.problems.push("action row overlaps the topline")
      if (!separated(measurements.actions, measurements.header)) row.problems.push("table header overlaps the action row")
      if (measurements.pageScrollTop <= 0) row.problems.push("app shell page did not scroll")
      if (measurements.tableScrollTop <= 0) row.problems.push("fill table scroll region did not scroll")
      if (Math.abs(measurements.header.top - measurements.wrapper.top - 1) > 2) {
        row.problems.push("fill table header did not remain pinned to its own scroll region")
      }
      if (measurements.compact !== (ctx === "app_page_shell_compact")) row.problems.push("app_shell compact mode does not match the context")
      if (!measurements.noticeLabel) row.problems.push("nested notice is missing its accessible full-message label")
      if (measurements.documentOverflows) row.problems.push("nested page shell document overflows horizontally")
      row.measurements = measurements
      await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}.png` })
    } catch (e) {
      row.problems.push(`error: ${e.message.split("\n")[0]}`)
      await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}.png` }).catch(() => {})
    }

    row.status = row.problems.length ? "FAIL" : "ok"
    rows.push(row)
    if (row.problems.length) console.log(`FAIL ${vw} ${ctx}/app-shell-sticky-offsets: ${row.problems.join("; ")}`)
    await page.close()
  }
}

// Action bar menu and dismissal on /qa?ctx=action_bar (the shell block above
// covers layout and promotion). The More menu must list every action and show the
// disabled reason, the destructive item must be marked, and dismissal must make a
// real server round trip: the notice exists before the click, and afterwards the
// server renders it dismissed (data-server-dismissed="true") and hidden.
const ACTION_IDS = ["create", "import", "export", "archive", "delete", "publish"]
if (!WIDE_TABLE_ONLY) {
  for (const vw of [1440, 390]) {
    const page = await browser.newPage()
    const row = { vw, ctx: "action_bar", cmp: "menu-dismissal", problems: [] }
    try {
      await page.setViewport({ width: vw, height: 900 })
      await page.goto(`${BASE}/qa?ctx=action_bar`, { waitUntil: "networkidle2" })
      await page.waitForSelector(".phx-connected", { timeout: 8000 })
      await page.waitForSelector("[data-action-bar-notice]", { timeout: 4000 })
      const trigger = await page.waitForSelector(".lui-action-bar-more-trigger", { timeout: 4000 })
      await trigger.click()
      // Wait for the menu to be open: its first item has a box.
      await page.waitForFunction(
        () => (document.querySelector(".lui-action-bar-menu [data-action-id]")?.getBoundingClientRect().height ?? 0) > 0,
        { timeout: 4000 },
      )
      const menu = await page.evaluate((expected) => {
        const items = [...document.querySelectorAll(".lui-action-bar-menu [data-action-id]")]
        const ids = items.map((el) => el.dataset.actionId)
        const pub = items.find((el) => el.dataset.actionId === "publish")
        const del = items.find((el) => el.dataset.actionId === "delete")
        return {
          missing: expected.filter((id) => !ids.includes(id)),
          reasonVisible: !!pub && pub.textContent.includes("Connect a channel first") && pub.getBoundingClientRect().height > 0,
          deleteDanger: del?.dataset.tone === "danger",
        }
      }, ACTION_IDS)
      if (menu.missing.length) row.problems.push(`More menu missing ${menu.missing.join(", ")}`)
      if (!menu.reasonVisible) row.problems.push("disabled reason not visible in More menu")
      if (!menu.deleteDanger) row.problems.push("destructive action not marked danger in More menu")
      await page.keyboard.press("Escape")

      const before = await page.evaluate(() => document.querySelector("[data-action-bar-notice]")?.dataset.serverDismissed)
      if (before !== "false") row.problems.push(`notice not visible before dismissal (data-server-dismissed=${before})`)
      const dismiss = await page.waitForSelector("[data-action-bar-notice] [data-part='dismiss']", { timeout: 4000 })
      await dismiss.click()
      // The round trip is complete when the server re-renders the notice dismissed.
      await page.waitForFunction(
        () => document.querySelector("[data-action-bar-notice]")?.dataset.serverDismissed === "true",
        { timeout: 4000 },
      ).catch(() => row.problems.push("dismissal did not reach the server (no data-server-dismissed=\"true\" render)"))
      const hidden = await page.evaluate(() => {
        const n = document.querySelector("[data-action-bar-notice]")
        return !!n && (n.hidden || getComputedStyle(n).display === "none")
      })
      if (!hidden) row.problems.push("server-dismissed notice is still visible")
    } catch (e) {
      row.problems.push(`error: ${e.message.split("\n")[0]}`)
    }
    row.status = row.problems.length ? "FAIL" : "ok"
    rows.push(row)
    if (row.problems.length) console.log(`FAIL ${vw} action_bar/menu-dismissal: ${row.problems.join("; ")}`)
    await page.close()
  }
}


// page_shell layout="strip" inside app_shell (default and compact appbar). After
// scrolling, the strip is pinned under the appbar, sits above (never under) any
// table header that reaches it, and the page keeps one trail, one h1, one actions
// region and the promotion tier its width implies. Desktop scrolls <main>; mobile
// scrolls the document.
if (!WIDE_TABLE_ONLY) {
  for (const vw of SHELL_VWS) {
    for (const ctx of ["page_shell_strip", "page_shell_strip_compact"]) {
      const page = await browser.newPage()
      await page.setViewport({ width: vw, height: vw < 600 ? 844 : 900 })
      const row = { vw, ctx, cmp: "strip-contract", problems: [] }

      try {
        await page.goto(`${BASE}/qa?ctx=${ctx}`, { waitUntil: "networkidle2" })
        await page.waitForSelector(".phx-connected", { timeout: 8000 })
        await page.waitForSelector("#qa-strip-table .lui-th", { timeout: 4000 })
        // Scroll until the fill table's top edge is just under the strip, so its
        // header has to meet the strip. Then the page has moved past the trail.
        await page.evaluate(async () => {
          const main = document.querySelector(".lui-app-main")
          const table = document.querySelector("#qa-strip-table")
          if (getComputedStyle(main).overflowY === "auto") {
            main.scrollTop = table.getBoundingClientRect().top - main.getBoundingClientRect().top + main.scrollTop + 8
          } else {
            window.scrollTo(0, table.getBoundingClientRect().top + scrollY + 8)
          }
          await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
        })
        await sleep(80)

        const m = await page.evaluate(() => {
          const r = (el) => el.getBoundingClientRect()
          const appbar = r(document.querySelector(".lui-appbar"))
          const strip = document.querySelector(".lui-page-strip")
          const sr = r(strip)
          const header = document.querySelector("#qa-strip-table .lui-th")
          const hr = r(header)
          const bar = document.querySelector(".lui-page-strip .lui-action-bar")
          const barWidth = r(bar).width
          const tier = barWidth > 1100 ? 3 : barWidth >= 740 ? 2 : 1
          const inlineVisible = [...bar.querySelectorAll(".lui-action-bar-action:not([data-promoted-index='0'])")]
            .filter((el) => r(el).width > 0).length
          const promotable = [...bar.querySelectorAll(".lui-action-bar-action:not([data-promoted-index='0'])")].length
          const crumbs = [...document.querySelectorAll("[data-page-shell] nav.lui-breadcrumb .lui-breadcrumb-item")]
          const visibleCrumbs = crumbs.filter((el) => r(el).width > 0).length
          // The strip's own middle point must hit the strip, so nothing scrolled
          // beneath it (a table header, for example) can paint over it.
          const hit = document.elementFromPoint((sr.left + sr.right) / 2, (sr.top + sr.bottom) / 2)
          const overlap = hr.top < sr.bottom && hr.bottom > sr.top
          return {
            appbarBottom: appbar.bottom,
            stripTop: sr.top,
            stripBottom: sr.bottom,
            stripHeight: sr.height,
            stripWidth: sr.width,
            tokenHeight: parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--lui-strip-h")) *
              parseFloat(getComputedStyle(document.documentElement).fontSize),
            headerTop: hr.top,
            overlap,
            coveredByStrip: !!hit && !!hit.closest(".lui-page-strip"),
            breadcrumbs: document.querySelectorAll("[data-page-shell] nav.lui-breadcrumb").length,
            titles: document.querySelectorAll("[data-page-shell] h1[data-page-title]").length,
            actionRegions: document.querySelectorAll("[data-page-actions]").length,
            promoted: bar.getAttribute("data-promoted"),
            tier,
            inlineVisible,
            promotable,
            visibleCrumbs,
            foldMenuVisible: !!document.querySelector(".lui-page-strip-more") &&
              r(document.querySelector(".lui-page-strip-more")).width > 0,
            documentOverflows: document.documentElement.scrollWidth > innerWidth + 1,
            mainOverflows: (() => {
              const main = document.querySelector(".lui-app-main")
              return main.scrollWidth > main.clientWidth + 1
            })(),
            pageScrolled: (document.querySelector(".lui-app-main").scrollTop || scrollY) > 100,
            pinned: Math.abs(sr.top - appbar.bottom) <= 1,
          }
        })
        await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}.png` })

        if (!m.pageScrolled) row.problems.push("page did not scroll")
        if (!m.pinned) row.problems.push(`strip not pinned under appbar (top ${m.stripTop}, appbar bottom ${m.appbarBottom})`)
        if (m.stripTop < m.appbarBottom - 1) row.problems.push("strip sits under the app bar")
        if (Math.abs(m.stripHeight - m.tokenHeight) > 1) row.problems.push("strip height does not match --lui-strip-h")
        if (m.overlap && !m.coveredByStrip) row.problems.push("table header paints over the strip")
        if (!m.overlap && m.headerTop < m.stripTop && m.headerTop > m.appbarBottom) row.problems.push("table header is between the appbar and the strip")
        if (m.breadcrumbs !== 1) row.problems.push(`expected one breadcrumb trail, found ${m.breadcrumbs}`)
        if (m.titles !== 1) row.problems.push(`expected one h1, found ${m.titles}`)
        if (m.actionRegions !== 1) row.problems.push(`expected one actions region, found ${m.actionRegions}`)
        if (m.promoted !== String(m.tier)) row.problems.push(`data-promoted ${m.promoted} does not match width tier ${m.tier}`)
        if (m.inlineVisible > m.tier) row.problems.push(`${m.inlineVisible} inline actions visible above tier ${m.tier}`)
        if (m.stripWidth <= 640 && !m.foldMenuVisible) row.problems.push("narrow strip did not fold breadcrumbs")
        if (m.stripWidth <= 640 && m.visibleCrumbs > 2) row.problems.push(`narrow strip shows ${m.visibleCrumbs} crumbs`)
        if (m.documentOverflows || m.mainOverflows) row.problems.push("page overflows horizontally")
        // Print: the trail and actions are hidden, but the h1 stays in the print stream.
        await page.emulateMediaType("print")
        const printed = await page.evaluate(() => {
          const shown = (sel) => !!document.querySelector(sel) && getComputedStyle(document.querySelector(sel)).display !== "none"
          return {
            crumbs: shown("[data-page-shell] nav.lui-breadcrumb"),
            actions: shown("[data-page-shell] .lui-page-strip-actions"),
            title: !!document.querySelector("[data-page-shell] h1[data-page-title]") &&
              getComputedStyle(document.querySelector("[data-page-shell] h1[data-page-title]")).display !== "none",
          }
        })
        await page.emulateMediaType("screen")
        if (printed.crumbs || printed.actions) row.problems.push("print still shows the strip trail or actions")
        if (!printed.title) row.problems.push("print hides the page h1")
        row.strip = m
      } catch (e) {
        row.problems.push(`error: ${e.message.split("\n")[0]}`)
        await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}.png` }).catch(() => {})
      }

      row.status = row.problems.length ? "FAIL" : "ok"
      rows.push(row)
      if (row.problems.length) console.log(`FAIL ${vw} ${ctx}/strip-contract: ${row.problems.join("; ")}`)
      await page.close()
    }
  }

  // The sidebar header stays on the icon rail; its switcher name hides there.
  for (const ctx of ["sidebar_header", "sidebar_header_collapsed"]) {
    for (const vw of [1440, 1100]) {
      const page = await browser.newPage()
      await page.setViewport({ width: vw, height: 900 })
      const row = { vw, ctx, cmp: "sidebar-header", problems: [] }

      try {
        await page.goto(`${BASE}/qa?ctx=${ctx}`, { waitUntil: "networkidle2" })
        await page.waitForSelector(".phx-connected", { timeout: 8000 })
        await page.waitForSelector("#qa-sidebar-switcher", { timeout: 4000 })
        const m = await page.evaluate(() => {
          const r = (el) => el.getBoundingClientRect()
          const aside = document.querySelector(".lui-app-sidebar")
          const header = document.querySelector(".lui-app-sidebar-header")
          const nav = document.querySelector(".lui-app-nav")
          const name = document.querySelector(".qa-switcher-name")
          const collapsed = document.querySelector(".lui-app").hasAttribute("data-collapsed")
          return {
            collapsed,
            headerAboveNav: r(header).bottom <= r(nav).top + 1,
            headerInsideSidebar: r(header).right <= r(aside).right + 1 && r(header).width > 0,
            headerWithinRail: r(header).width <= r(aside).width + 1,
            nameVisible: r(name).width > 0,
            avatarVisible: r(document.querySelector(".qa-avatar")).width > 0,
            headerRect: { w: r(header).width, h: r(header).height },
          }
        })
        await page.screenshot({ path: `${SHOTS}/${vw}-${ctx}.png` })
        if (m.collapsed !== (ctx === "sidebar_header_collapsed")) row.problems.push("collapsed state does not match the context")
        if (!m.headerAboveNav) row.problems.push("sidebar header is not above the nav")
        if (!m.headerInsideSidebar) row.problems.push("sidebar header is outside the sidebar")
        if (!m.avatarVisible) row.problems.push("switcher avatar not visible")
        if (m.collapsed && m.nameVisible) row.problems.push("switcher name still visible on the icon rail")
        if (!m.collapsed && !m.nameVisible) row.problems.push("switcher name hidden when expanded")
        row.sidebar = m
      } catch (e) {
        row.problems.push(`error: ${e.message.split("\n")[0]}`)
      }

      row.status = row.problems.length ? "FAIL" : "ok"
      rows.push(row)
      if (row.problems.length) console.log(`FAIL ${vw} ${ctx}/sidebar-header: ${row.problems.join("; ")}`)
      await page.close()
    }
  }
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
