// Real-browser regression for flicker #3880: project nav rows (link /
// disclosure / pin), keyed disclosure persistence, and the mobile drawer as a
// modal sheet. Real keyboard/mouse input only.
//
//   MIX_ENV=test PORT=4013 mix run --no-halt test/qa/server.exs
//   BASE=http://127.0.0.1:4013 PUPPETEER_CORE=/tmp/lantern-chart-qa/node_modules/puppeteer-core \
//     CHROME_PATH="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
//     node test/qa/project_nav.mjs
//
// Screenshots go to $QA_SHOTS (default /tmp/lantern-qa/project-nav).
// axe-core is resolved next to puppeteer-core (or set AXE_CORE to axe.min.js).
import { createRequire } from "node:module"
import { mkdirSync } from "node:fs"
import { createHash } from "node:crypto"

const require = createRequire(import.meta.url)
const puppeteer = require(process.env.PUPPETEER_CORE || "puppeteer-core")
const AXE =
  process.env.AXE_CORE ||
  require.resolve("axe-core/axe.min.js", { paths: [process.env.PUPPETEER_CORE || process.cwd()].map((p) => p.replace(/node_modules.*$/, "")) })
const BASE = process.env.BASE || "http://127.0.0.1:4013"
const SHOTS = process.env.QA_SHOTS || "/tmp/lantern-qa/project-nav"
const CHROME = process.env.CHROME_PATH || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
mkdirSync(SHOTS, { recursive: true })

let failed = 0
const check = (label, pass, note = "") => {
  if (!pass) failed++
  console.log(`${pass ? "PASS" : "FAIL"}  ${label}${note ? "  — " + note : ""}`)
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new", args: ["--no-sandbox"] })
const p = await browser.newPage()
const errors = []
p.on("pageerror", (e) => errors.push(e.message))
p.on("console", (m) => m.type() === "error" && !/favicon/.test(m.location()?.url || "") && errors.push(m.text()))

const load = async (query = "", { clear = false } = {}) => {
  await p.goto(`${BASE}/project_nav${query}`, { waitUntil: "networkidle2" })
  if (clear) await p.evaluate(() => localStorage.clear())
  if (clear) await p.goto(`${BASE}/project_nav${query}`, { waitUntil: "networkidle2" })
  await p.waitForSelector("[data-phx-main].phx-connected")
  await sleep(300)
}
const active = () =>
  p.evaluate(() => {
    const el = document.activeElement
    return el ? el.getAttribute("aria-label") || el.id || el.textContent.trim().slice(0, 30) : null
  })
const attr = (sel, name) => p.$eval(sel, (el, n) => el.getAttribute(n), name).catch(() => null)
const focus = (sel) => p.$eval(sel, (el) => el.focus())
const tab = async (shift = false) => {
  if (shift) await p.keyboard.down("Shift")
  await p.keyboard.press("Tab")
  if (shift) await p.keyboard.up("Shift")
}

// Force a theme regardless of the machine's own preference: the theme CSS
// follows system dark unless the root says `.light`, so a descendant `.dark`
// class alone cannot produce a light shot on a dark-mode host.
const setTheme = async (theme) => {
  await p.emulateMediaFeatures([{ name: "prefers-color-scheme", value: theme }])
  await p.evaluate((t) => {
    for (const el of [document.documentElement, document.querySelector("#qa-project-nav-theme")]) {
      el.classList.toggle("dark", t === "dark")
      el.classList.toggle("light", t === "light")
    }
  }, theme)
  await sleep(250)
}
const sidebarColors = () =>
  p.$eval("#qa-project-nav-sidebar", (el) => {
    const s = getComputedStyle(el)
    return { bg: s.backgroundColor, fg: getComputedStyle(el.querySelector(".lui-nav-item")).color }
  })
const luminance = (rgb) => {
  const [r, g, b] = rgb.match(/[\d.]+/g).map(Number)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
// axe (WCAG 2 A/AA): no serious or critical violation in the current state.
// KNOWN lists pre-existing defects awaiting an owner decision; each is printed
// on every run and the check fails once one disappears (then delete it here).
const KNOWN = {
  // Active nav item: brand accent on its 12% soft tint, ~3.3:1 in light.
  "color-contrast .lui-nav-item-active > .lui-nav-item-label": "#3880 owner decision pending",
}
const knownSeen = new Set()
const axe = async (label) => {
  if (!(await p.evaluate(() => !!window.axe))) await p.addScriptTag({ path: AXE })
  const { violations } = await p.evaluate(() =>
    window.axe.run(document, { runOnly: { type: "tag", values: ["wcag2a", "wcag2aa"] } }),
  )
  const found = violations
    .filter((v) => v.impact === "serious" || v.impact === "critical")
    .flatMap((v) => v.nodes.map((n) => ({ key: `${v.id} ${n.target.join(" ")}`, impact: v.impact })))
  const bad = found.filter((f) => !KNOWN[f.key])
  for (const f of found.filter((f) => KNOWN[f.key])) knownSeen.add(f.key)
  for (const f of found.filter((f) => KNOWN[f.key])) console.log(`KNOWN ${label}: ${f.impact} ${f.key} (${KNOWN[f.key]})`)
  check(`${label}: axe has no serious/critical violations`, bad.length === 0, bad.map((f) => `${f.impact} ${f.key}`).join("; "))
  return found
}

// Shoot both themes and prove they are really different.
const shootThemes = async (name) => {
  const shot = {}
  for (const theme of ["light", "dark"]) {
    await setTheme(theme)
    shot[theme] = { colors: await sidebarColors(), png: await p.screenshot({ path: `${SHOTS}/${name}-${theme}.png` }) }
    await axe(`${name} ${theme}`)
  }
  const { light, dark } = shot
  check(
    `${name}: light and dark differ in computed colours`,
    light.colors.bg !== dark.colors.bg && light.colors.fg !== dark.colors.fg &&
      luminance(light.colors.bg) > luminance(dark.colors.bg) && luminance(light.colors.fg) < luminance(dark.colors.fg),
    JSON.stringify({ light: light.colors, dark: dark.colors }),
  )
  const sha = (buf) => createHash("sha1").update(buf).digest("hex")
  check(`${name}: light and dark screenshots differ`, sha(light.png) !== sha(dark.png))
  await setTheme("light")
}

// ---------- Desktop 1280x800 ----------
await p.setViewport({ width: 1280, height: 800 })
await load("", { clear: true })
await shootThemes("desktop")

// B3: link, disclosure and pin are three separate tab stops in that order.
await focus("#qa-project-beacon a.lui-nav-item")
await tab()
check("Tab: link -> disclosure", (await active()) === "Toggle Beacon", await active())
check("disclosure names its panel", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-controls")) === "qa-project-beacon-subnav")
check("closed disclosure aria-expanded=false", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-expanded")) === "false")
await tab()
check("Tab: disclosure -> pin", (await active()) === "Unpin Beacon", await active())
check("pin is aria-pressed", (await attr("#qa-project-beacon [data-part=nav-action]", "aria-pressed")) === "true")
const pinOpacity = await p.$eval("#qa-project-beacon [data-part=nav-action]", (el) => getComputedStyle(el).opacity)
check("focused pin is visible", pinOpacity === "1", pinOpacity)
await tab()
const afterPin = await active()
check("closed panel is skipped by Tab", afterPin === "qa-all-atlas" || /Atlas/.test(afterPin), afterPin)

// Expand with the keyboard; the hidden child becomes reachable.
await focus("#qa-project-beacon [data-part=nav-disclosure]")
await p.keyboard.press("Enter")
await sleep(250)
check("Enter opens the disclosure", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-expanded")) === "true")
await tab()
await tab()
check("open panel children are tabbable", /Overview/.test(await active()), await active())

// Keyed persistence: reload keeps it; another user/org does not see it.
const stored = await p.evaluate(() => localStorage.getItem("lui-nav:u1:oacme:project-beacon"))
check("state stored under the trusted user/org/group key", stored === "true", stored)
await load("")
check("reload keeps the open disclosure", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-expanded")) === "true")
await load("?user=2")
check("another user starts from the server default", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-expanded")) === "false")
await load("?org=globex")
check("another org starts from the server default", (await attr("#qa-project-beacon [data-part=nav-disclosure]", "aria-expanded")) === "false")

// Collapse the active project's group: focus stays on the disclosure.
await load("")
await focus("#qa-project-atlas [data-part=nav-disclosure]")
await p.keyboard.press("Enter")
await sleep(250)
check("active group collapses", (await attr("#qa-project-atlas [data-part=nav-disclosure]", "aria-expanded")) === "false")
check("focus stays on the collapsed disclosure", (await active()) === "Toggle Atlas", await active())
await p.click("#qa-project-atlas [data-part=nav-disclosure]")
await sleep(200)

// Pin from All projects with Space; unpin a non-current pinned row: focus recovers.
await focus("#qa-all-comet [data-part=nav-action]")
await p.keyboard.press("Space")
await p.waitForSelector("#qa-project-comet", { timeout: 3000 }).catch(() => {})
check("pin adds the row to Pinned", !!(await p.$("#qa-project-comet")))
check("pin toggles aria-pressed", (await attr("#qa-all-comet [data-part=nav-action]", "aria-pressed")) === "true")
await focus("#qa-project-beacon [data-part=nav-action]")
await p.keyboard.press("Space")
await p.waitForFunction(() => !document.querySelector("#qa-project-beacon"), { timeout: 3000 }).catch(() => {})
await sleep(100)
const recovered = await active()
check("unpinned row removed", !(await p.$("#qa-project-beacon")))
check("focus recovers to the pin in its place (not <body>)", recovered === "Unpin Comet", recovered)
// Unpinning the current project leaves it as current context with focus kept.
await focus("#qa-project-atlas [data-part=nav-action]")
await p.keyboard.press("Space")
await sleep(300)
check("current project stays after unpin", !!(await p.$("#qa-project-atlas")))
check("its pin flips to Pin + not pressed", (await attr("#qa-project-atlas [data-part=nav-action]", "aria-pressed")) === "false")
check("focus kept on the current project's pin", (await active()) === "Pin Atlas", await active())

// Touch: no hover, so row actions always show.
// (puppeteer has no `hover` media feature; CDP touch emulation flips it.)
const cdp = await p.createCDPSession()
await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 1 })
await load("")
const noHover = await p.evaluate(() => matchMedia("(hover: none)").matches)
const touchOpacity = await p.$eval("#qa-all-delta [data-part=nav-action]", (el) => getComputedStyle(el).opacity)
check("touch: pin always visible", noHover && touchOpacity === "1", `hover:none=${noHover} opacity=${touchOpacity}`)
await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: false })
await load("")
const idleOpacity = await p.$eval("#qa-all-delta [data-part=nav-action]", (el) => getComputedStyle(el).opacity)
check("pointer: idle pin hidden until hover/focus", idleOpacity === "0", idleOpacity)

// Chat kit: on_seen reports only what is in view.
await load("", { clear: true })
const seen = () => p.$eval("#qa-seen", (el) => el.dataset.seen)
check("on_seen reports the last message at mount", (await seen()) === "m12", await seen())
await p.$eval("#qa-thread [data-part=viewport]", (el) => el.scrollTo(0, 0))
await sleep(200)
await p.click("[data-page-actions] button")
await sleep(400)
check("message appended while scrolled up is not seen", (await seen()) === "m12", await seen())
await p.click("#qa-thread [data-part=jump-latest]")
await sleep(400)
check("Jump to latest reports it", (await seen()) === "m13", await seen())

// ---------- Mobile sheet ----------
for (const width of [375, 768]) {
  await p.setViewport({ width, height: 812, hasTouch: true, isMobile: width < 400 })
  await load("", { clear: true })
  const toggle = "[data-part=sidebar-toggle]"
  const isOpen = () => p.$eval("#qa-project-nav", (el) => el.hasAttribute("data-nav-open"))
  const htmlOverflow = () => p.evaluate(() => getComputedStyle(document.documentElement).overflow)

  await p.click(toggle)
  await sleep(300)
  check(`${width}: drawer opens`, await isOpen())
  check(`${width}: labelled modal dialog`, (await attr("#qa-project-nav-sidebar", "role")) === "dialog" && (await attr("#qa-project-nav-sidebar", "aria-modal")) === "true" && (await attr("#qa-project-nav-sidebar", "aria-label")) === "Project navigation")
  check(`${width}: focus enters`, (await active()) === "Close navigation", await active())
  check(`${width}: main is inert`, await p.$eval(".lui-app-main", (el) => el.inert))
  check(`${width}: page scroll locked`, (await htmlOverflow()) === "hidden", await htmlOverflow())
  if (width === 375) await shootThemes(`mobile-${width}-open`)

  // Trap: Shift+Tab from the first stop wraps to the last, Tab wraps back.
  await tab(true)
  const last = await active()
  const inside = await p.evaluate(() => document.querySelector("#qa-project-nav-sidebar").contains(document.activeElement))
  check(`${width}: Shift+Tab wraps inside`, inside, last)
  await tab()
  check(`${width}: Tab wraps to first`, (await active()) === "Close navigation", await active())

  // Disclosure and pin keep it open.
  await p.click("#qa-project-beacon [data-part=nav-disclosure]")
  await sleep(200)
  check(`${width}: disclosure keeps it open`, await isOpen())
  await p.click("#qa-all-delta [data-part=nav-action]")
  await sleep(300)
  check(`${width}: pin keeps it open`, await isOpen())

  // Org dropdown inside the drawer: Escape closes the menu first.
  await p.click("#qa-org-menu [data-part=trigger]")
  await sleep(300)
  await p.keyboard.press("Escape")
  await sleep(300)
  check(`${width}: Escape closes nested menu, not the drawer`, await isOpen())
  await p.keyboard.press("Escape")
  await sleep(300)
  check(`${width}: second Escape closes the drawer`, !(await isOpen()))
  check(`${width}: focus restored to hamburger`, (await active()) === "Open navigation", await active())
  check(`${width}: background released`, !(await p.$eval(".lui-app-main", (el) => el.inert)))
  check(`${width}: scroll lock released`, (await htmlOverflow()) !== "hidden", await htmlOverflow())

  // Scrim and close button.
  await p.click(toggle)
  await sleep(300)
  await p.mouse.click(width - 10, 400)
  await sleep(300)
  check(`${width}: scrim closes`, !(await isOpen()))
  await p.click(toggle)
  await sleep(300)
  await p.click("[data-part=sidebar-close]")
  await sleep(300)
  check(`${width}: close button closes`, !(await isOpen()))

  // A destination link closes it and navigates.
  await p.click(toggle)
  await sleep(300)
  await p.click("#qa-all-comet a.lui-nav-item")
  await sleep(500)
  check(`${width}: link closes the drawer`, !(await isOpen()))
  check(`${width}: link navigated`, p.url().includes("project=comet"), p.url())

  // Reconnect while open: no duplicate listeners, one Escape still closes.
  await p.click(toggle)
  await sleep(300)
  await p.evaluate(() => { window.liveSocket.disconnect(); window.liveSocket.connect() })
  await p.waitForSelector("[data-phx-main].phx-connected")
  await sleep(500)
  check(`${width}: still a modal after reconnect`, (await attr("#qa-project-nav-sidebar", "role")) === "dialog")
  await p.keyboard.press("Escape")
  await sleep(300)
  check(`${width}: Escape closes after reconnect`, !(await isOpen()))
  check(`${width}: no leaked lock after reconnect`, (await htmlOverflow()) !== "hidden")

  // Resize to desktop while open: the drawer state and modal semantics drop.
  await p.click(toggle)
  await sleep(300)
  await p.setViewport({ width: 1280, height: 800 })
  await sleep(400)
  check(`${width}->1280: drawer closed on resize`, !(await isOpen()))
  check(`${width}->1280: no dialog role on desktop`, (await attr("#qa-project-nav-sidebar", "role")) === null)
  check(`${width}->1280: main not inert`, !(await p.$eval(".lui-app-main", (el) => el.inert)))
  check(`${width}->1280: one nav, no hidden duplicate`, (await p.$$eval("a.lui-nav-item[href*='project=atlas&page=runs']", (els) => els.length)) === 1)
}

check("no page/console errors", errors.length === 0, errors.slice(0, 3).join(" | "))
await browser.close()
for (const key of Object.keys(KNOWN)) check(`known axe issue still present (else delete it from KNOWN): ${key}`, knownSeen.has(key))
console.log(`\n${failed ? `${failed} FAILED` : "all passed"} — screenshots in ${SHOTS}`)
process.exit(failed ? 1 : 0)
