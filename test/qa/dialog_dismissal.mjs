// Real-browser repro for flicker #3453 (dialog dismissal + select width).
// Real mouse/keyboard events only — no synthetic dispatch.
//
//   BASE=http://localhost:4013 PUPPETEER_CORE=/path/to/node_modules/puppeteer-core \
//     node test/qa/dialog_dismissal.mjs
//
// Needs an app serving /repro: a LiveView with modals m1 (client), m2
// (controlled, on_change="ctl"), alert dialog a1 and sheet s1, each holding
// a phx-change + phx-submit form (#<id>-form, #<id>-name, #<id>-err) and a
// phx-click button (#<id>-bump), plus a controlled select #st (256px wide).
import { createRequire } from "node:module"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const BASE = process.env.BASE || "http://localhost:4013"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
let failed = 0
const check = (label, pass, note = "") => {
  if (!pass) failed++
  console.log(`${pass ? "PASS" : "FAIL"}  ${label}${note ? "  — " + note : ""}`)
}

const browser = await puppeteer.launch({
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  headless: "new",
  args: ["--no-sandbox"],
})
const p = await browser.newPage()
await p.setViewport({ width: 1280, height: 800 })
const errors = []
p.on("pageerror", (e) => errors.push(e.message))

// A click on a node that is gone/hidden is a recorded failure, not a crash.
const click = (sel) => p.click(sel).catch((e) => void check(`click ${sel}`, false, e.message))
const isOpen = (id) => p.$eval("#" + id, (e) => !e.hidden && getComputedStyle(e).display !== "none")
const text = (sel) => p.$eval(sel, (e) => e.textContent.trim()).catch(() => null)
const load = async () => {
  await p.goto(BASE + "/repro", { waitUntil: "networkidle2" })
  await p.waitForSelector(".phx-connected")
  await sleep(600)
}

const dialogs = [
  { id: "m1", opener: "#open-modal", name: "modal" },
  { id: "m2", opener: "#open-ctl", name: "controlled modal" },
  { id: "a1", opener: "#open-alert", name: "alert dialog", outside: false },
  { id: "s1", opener: "#open-sheet", name: "sheet" },
]

for (const d of dialogs) {
  const { id, name } = d
  await load()
  await click(d.opener)
  await sleep(500)
  check(`${name}: opens on real click`, await isOpen(id))

  // (1) server patch must not close a client-opened dialog
  await click(`#${id}-name`)
  await p.keyboard.type("a", { delay: 50 })
  await sleep(700)
  check(`${name}: stays open after phx-change patch`, await isOpen(id))

  // (2) phx-submit with a validation error keeps the dialog open
  await p.keyboard.press("Enter")
  await sleep(700)
  check(`${name}: stays open after phx-submit`, await isOpen(id))
  check(`${name}: inline validation error shows`, (await text(`#${id}-err`)) === "Too short")

  // (3) next real click on a button after a patch hits its phx-click
  const before = await text("#saved")
  for (let i = 0; i < 3; i++) {
    await click(`#${id}-bump`)
    await sleep(500)
  }
  const after = await text("#saved")
  check(`${name}: stays open after button clicks following a patch`, await isOpen(id))
  check(`${name}: phx-click button ran each time`, /clicks=3/.test(after), `${before} -> ${after}`)
  check(`${name}: no on_change(open=false) from patches`, !/open=false/.test(after), after)

  // submit via the real button (LiveView blurs the focused control)
  await click(`#${id}-submit`)
  await sleep(600)
  check(`${name}: stays open after clicking the submit button`, await isOpen(id))
  check(`${name}: validation error still shown`, (await text(`#${id}-err`)) === "Too short")

  // user intent still closes
  await p.keyboard.press("Escape")
  await sleep(600)
  check(`${name}: Escape closes`, !(await isOpen(id)))
  await click(d.opener)
  await sleep(500)
  check(`${name}: reopens`, await isOpen(id))
  if (d.outside !== false) {
    await p.mouse.click(6, 6)
    await sleep(600)
    check(`${name}: backdrop pointerdown closes`, !(await isOpen(id)))
  } else {
    await p.mouse.click(6, 6)
    await sleep(600)
    check(`${name}: backdrop does not close (by design)`, await isOpen(id))
  }
}

// (4) select listbox matches the trigger width and aligns to its start edge
await load()
await click("#st-select [data-part='trigger']")
await sleep(500)
const geo = await p.evaluate(() => {
  const t = document.querySelector("#st-select [data-part='trigger']").getBoundingClientRect()
  const l = document.querySelector("#st-select [data-part='content']").getBoundingClientRect()
  return { tw: t.width, lw: l.width, tl: t.left, ll: l.left }
})
check("select: listbox width equals trigger width", Math.abs(geo.tw - geo.lw) < 1.5, JSON.stringify(geo))
check("select: listbox aligned to trigger start", Math.abs(geo.tl - geo.ll) < 1.5, JSON.stringify(geo))

if (process.env.SHOT) await p.screenshot({ path: process.env.SHOT })
check("no page errors", errors.length === 0, errors.join(" | "))
await browser.close()
process.exit(failed ? 1 : 0)
