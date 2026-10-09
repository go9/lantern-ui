import test from "node:test"
import assert from "node:assert/strict"
import { hooks, mountHook, keydown, sleep } from "./helpers/dom.mjs"

const points = [
  { x: 20, label: "Jan 1", values: ["$10", "$4"], coords: [80, 120], positions: [{ x: 20, y: 80 }, { x: 20, y: 120 }] },
  { x: 80, label: "Feb 1", values: ["$12", null], coords: [60, null], positions: [{ x: 80, y: 60 }, null] },
]

function fixture() {
  return `<div id="chart" data-interaction='${JSON.stringify(points)}' data-series-label='["Collection","Inventory"]'>
    <svg viewBox="0 0 100 150"><g class="lui-time-series-chart__interaction" hidden>
      <line data-part="crosshair" x1="0" x2="0"></line>
      <circle data-part="series-point" data-series-index="0"></circle>
      <circle data-part="series-point" data-series-index="1"></circle>
      <g data-part="tooltip" data-base-x="8" data-base-y="8" data-plot-left="4" data-plot-right="96" data-plot-top="4" data-plot-bottom="146" data-tooltip-width="40" data-tooltip-height="30"><rect width="40" height="30"></rect><text data-part="tooltip-date"></text>
        <text data-part="tooltip-row" data-series-index="0"></text>
        <text data-part="tooltip-row" data-series-index="1"></text></g>
    </g><circle data-chart-point="0" tabindex="0"></circle>
    <circle data-chart-point="1" tabindex="-1"></circle></svg>
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

  assert.equal(mounted.el.querySelector('[data-part="crosshair"]').getAttribute("x1"), "80")
  assert.equal(mounted.el.querySelector('[data-part="tooltip-date"]').textContent, "Feb 1")
  assert.match(mounted.el.querySelector('[data-part="tooltip"]').getAttribute("transform"), /translate\(.*\)/)
  assert.equal(mounted.el.querySelectorAll('[data-part="tooltip-row"]')[0].textContent, "Collection: $12")
  assert.equal(mounted.el.querySelectorAll('[data-part="tooltip-row"]')[1].textContent, "Inventory: —")
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
  assert.equal(mounted.el.querySelector('[data-part="tooltip-date"]').textContent, "Jan 1")
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
