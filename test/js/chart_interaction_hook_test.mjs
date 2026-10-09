import test from "node:test"
import assert from "node:assert/strict"
import { hooks, mountHook, keydown, sleep } from "./helpers/dom.mjs"

const points = [
  { x: 20, label: "Jan 1", x_value: "2026-01-01", values: ["$10", "$4"], raw_values: [10, 4], coords: [80, 120], positions: [{ x: 20, y: 80 }, { x: 20, y: 120 }] },
  { x: 80, label: "Feb 1", x_value: "2026-02-01", values: ["$12", null], raw_values: [12, null], coords: [60, null], positions: [{ x: 80, y: 60 }, null] },
]

function fixture() {
  return `<div id="chart" data-plot-left="20" data-plot-right="80" data-interaction='${JSON.stringify(points)}' data-series-label='["Collection","Inventory"]' data-series-id='["collection","inventory"]'>
    <svg viewBox="0 0 100 150"><g class="lui-time-series-chart__interaction" hidden>
      <line data-part="crosshair" x1="0" x2="0"></line>
      <circle data-part="series-point" data-series-index="0"></circle>
      <circle data-part="series-point" data-series-index="1"></circle>
    </g><circle data-chart-point="0" tabindex="0"></circle>
    <circle data-chart-point="1" tabindex="-1"></circle></svg>
    <div data-part="html-tooltip" hidden><span data-part="html-tooltip-date"></span>
      <strong data-part="html-tooltip-value"></strong><strong data-part="html-tooltip-value"></strong></div>
    <span data-part="live" aria-live="polite"></span></div>`
}

function pointer(target, name, x, pointerType = "mouse") {
  const event = new target.ownerDocument.defaultView.Event(name, { bubbles: true })
  Object.defineProperties(event, { clientX: { value: x }, pointerType: { value: pointerType } })
  target.dispatchEvent(event)
}

test("ChartInteraction snaps all series to shared x and updates only the rendered overlay", async () => {
  const mounted = mountHook(hooks.ChartInteraction, fixture(), { rootId: "chart" })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })
  const originalChildren = [...svg.children]
  pointer(svg, "pointermove", 76)
  await sleep(30)

  assert.equal(Number(mounted.el.querySelector('[data-part="crosshair"]').getAttribute("x1")), 86)
  assert.equal(mounted.el.querySelector('[data-part="html-tooltip-date"]').textContent, "Feb 1")
  assert.equal(mounted.el.querySelector('[data-part="html-tooltip"]').hidden, false)
  assert.equal(mounted.el.querySelectorAll('[data-part="html-tooltip-value"]')[0].textContent, "$12")
  assert.equal(mounted.el.querySelectorAll('[data-part="html-tooltip-value"]')[1].textContent, "—")
  assert.equal(mounted.el.querySelector('[data-part="series-point"][data-series-index="1"]').hasAttribute("hidden"), true)
  assert.deepEqual([...svg.children], originalChildren)
  mounted.unmount()
})

test("touch, keyboard traversal, announcement, update and destroy are safe", async () => {
  const mounted = mountHook(hooks.ChartInteraction, fixture(), { rootId: "chart" })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })
  pointer(svg, "pointerdown", 19, "touch")
  await sleep(30)
  assert.equal(mounted.el.querySelector('[data-part="html-tooltip-date"]').textContent, "Jan 1")
  assert.equal(mounted.el.querySelector('[data-part="live"]').textContent, "")

  const first = mounted.el.querySelector('[data-chart-point="0"]')
  first.dispatchEvent(new mounted.window.FocusEvent("focusin", { bubbles: true }))
  assert.match(mounted.el.querySelector('[data-part="live"]').textContent, /Jan 1\. Collection: \$10\. Inventory: \$4/)
  const right = keydown(first, "ArrowRight")
  assert.equal(right.defaultPrevented, true)
  assert.equal(mounted.document.activeElement.dataset.chartPoint, "1")
  assert.equal(first.getAttribute("tabindex"), "-1")
  const end = keydown(mounted.document.activeElement, "End")
  assert.equal(end.defaultPrevented, true)
  assert.equal(mounted.document.activeElement.dataset.chartPoint, "1")
  const home = keydown(mounted.document.activeElement, "Home")
  assert.equal(home.defaultPrevented, true)
  assert.equal(mounted.document.activeElement.dataset.chartPoint, "0")
  const escape = keydown(mounted.document.activeElement, "Escape")
  assert.equal(escape.defaultPrevented, true)
  assert.equal(mounted.el.querySelector(".lui-time-series-chart__interaction").hasAttribute("hidden"), true)

  const oldSvg = svg
  const xBeforePatch = oldSvg.querySelector('[data-part="crosshair"]').getAttribute("x1")
  const replacement = mounted.document.createElement("template")
  replacement.innerHTML = fixture()
  mounted.el.innerHTML = replacement.content.firstElementChild.innerHTML
  mounted.hook.updated()
  pointer(oldSvg, "pointermove", 20)
  await sleep(30)
  assert.equal(oldSvg.querySelector('[data-part="crosshair"]')?.getAttribute("x1"), xBeforePatch)
  mounted.unmount()
})

test("select_event pushes raw values for pointer and Enter; unset event is a no-op", () => {
  const html = fixture().replace('<div id="chart"', '<div id="chart" data-select-event="select_date"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  const events = []
  mounted.hook.pushEvent = (name, payload) => events.push({ name, payload })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })

  pointer(svg, "click", 76)
  assert.deepEqual(events, [{
    name: "select_date",
    payload: { chart_id: "chart", x: "2026-02-01", values: { collection: 12, inventory: null } },
  }])

  const second = mounted.el.querySelector('[data-chart-point="1"]')
  const enter = keydown(second, "Enter")
  assert.equal(enter.defaultPrevented, true)
  assert.equal(events.length, 2)
  assert.deepEqual(events[1].payload, events[0].payload)
  const space = keydown(second, " ")
  assert.equal(space.defaultPrevented, true)
  assert.equal(events.length, 3)
  assert.deepEqual(events[2].payload, events[0].payload)
  mounted.unmount()

  const unset = mountHook(hooks.ChartInteraction, fixture(), { rootId: "chart" })
  const unsetEvents = []
  unset.hook.pushEvent = (...args) => unsetEvents.push(args)
  unset.el.querySelector('[data-chart-point="0"]').dispatchEvent(new unset.window.KeyboardEvent("keydown", { key: "Enter", bubbles: true }))
  assert.deepEqual(unsetEvents, [])
  unset.unmount()
})

test("hover_event debounces pointer movement to the latest shared x", async () => {
  const html = fixture().replace('<div id="chart"', '<div id="chart" data-hover-event="hover_date"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  const events = []
  mounted.hook.pushEvent = (name, payload) => events.push({ name, payload })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })

  pointer(svg, "pointermove", 20)
  await sleep(25)
  pointer(svg, "pointermove", 76)
  await sleep(350)
  assert.deepEqual(events, [{
    name: "hover_date",
    payload: { chart_id: "chart", x: "2026-02-01", values: { collection: 12, inventory: null } },
  }])
  mounted.unmount()
})

test("hover_event cancels its pending push when the pointer leaves", async () => {
  const html = fixture().replace('<div id="chart"', '<div id="chart" data-hover-event="hover_date"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  const events = []
  mounted.hook.pushEvent = (name, payload) => events.push({ name, payload })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })

  pointer(svg, "pointermove", 76)
  await sleep(30)
  pointer(svg, "pointerleave", 76)
  await sleep(350)
  assert.deepEqual(events, [])
  mounted.unmount()
})

test("pointercancel clears touch state and cancels a pending hover", async () => {
  const html = fixture().replace('<div id="chart"', '<div id="chart" data-hover-event="hover_date"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  const events = []
  mounted.hook.pushEvent = (name, payload) => events.push({ name, payload })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })

  pointer(svg, "pointerdown", 20, "touch")
  pointer(svg, "pointercancel", 20, "touch")
  await sleep(350)
  assert.equal(mounted.hook.touchActive, false)
  assert.deepEqual(events, [])
  assert.equal(mounted.el.querySelector(".lui-time-series-chart__interaction").hasAttribute("hidden"), true)
  mounted.unmount()
})


test("ChartInteraction fits x geometry to the measured width without scaling glyphs", () => {
  const sizingFixture = fixture().replace('<svg viewBox="0 0 100 150"><g class="lui-time-series-chart__interaction"', '<svg viewBox="0 0 100 150"><g class="lui-time-series-chart__labels"><text class="lui-time-series-chart__x-tick" x="20">Jan</text><text class="lui-time-series-chart__x-tick" x="80">Feb</text></g><g class="lui-time-series-chart__series"><path d="M20,80L80,60"></path></g><g class="lui-time-series-chart__interaction"')
  const mounted = mountHook(hooks.ChartInteraction, sizingFixture, { rootId: "chart" })
  let width = 320
  mounted.el.getBoundingClientRect = () => ({ width })
  mounted.hook.fitWidth()
  const svg = mounted.el.querySelector("svg")
  assert.equal(svg.viewBox.baseVal.width, 320)
  assert.equal(svg.getAttribute("preserveAspectRatio"), "xMinYMin meet")
  assert.equal(Number(svg.querySelector('.lui-time-series-chart__x-tick').getAttribute("x")), 20)
  const path = svg.querySelector('.lui-time-series-chart__series path')
  assert.equal(path.getAttribute("d"), "M 20 80 L 306 60")
  assert.equal(path.hasAttribute("transform"), false)
  width = 500
  mounted.hook.fitWidth()
  assert.equal(svg.viewBox.baseVal.width, 500)
  assert.equal(Number(svg.querySelectorAll('.lui-time-series-chart__x-tick')[1].getAttribute("x")), 486)
  assert.equal(path.getAttribute("d"), "M 20 80 L 486 60")
  mounted.unmount()
})

test("ChartInteraction recalculates curved and stepped path coordinates without SVG transforms", () => {
  const html = fixture().replace('<g class="lui-time-series-chart__interaction"', '<g class="lui-time-series-chart__series"><path d="M20,80 C30,70 70,60 80,60 H20 V90 Z"></path></g><g class="lui-time-series-chart__interaction"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  mounted.el.getBoundingClientRect = () => ({ width: 320 })
  mounted.hook.fitWidth()
  const path = mounted.el.querySelector('.lui-time-series-chart__series path')
  assert.equal(path.getAttribute("d"), "M 20 80 C 67.7 70 258.3 60 306 60 H 20 V 90 Z")
  assert.equal(path.hasAttribute("transform"), false)
  mounted.unmount()
})

test("bar hover snaps to the rendered active bar center", async () => {
  const html = fixture()
    .replace('<div id="chart"', '<div id="chart" data-chart-type="grouped_bar"')
    .replace('<g class="lui-time-series-chart__interaction"', '<g class="lui-time-series-chart__series"><rect class="lui-time-series-chart__bar" data-band-index="1" data-series-index="0" x="68" width="18" y="30" height="30"></rect></g><g class="lui-time-series-chart__interaction"')
  const mounted = mountHook(hooks.ChartInteraction, html, { rootId: "chart" })
  const svg = mounted.el.querySelector("svg")
  svg.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 150 })
  const bar = mounted.el.querySelector('.lui-time-series-chart__bar')
  pointer(bar, "pointermove", 80)
  await sleep(40)
  const center = Number(bar.getAttribute("x")) + Number(bar.getAttribute("width")) / 2
  assert.equal(Number(mounted.el.querySelector('[data-part="crosshair"]').getAttribute("x1")), center)
  assert.equal(bar.hasAttribute('data-active'), true)
  assert.equal(mounted.el.querySelector('[data-part="html-tooltip"]').hidden, false)
  mounted.unmount()
})
