// Floating panels live in the browser top layer, `fixed`, with flip + shift
// (flicker #3480). jsdom has no Popover API, so each test installs a small stub
// on the document's HTMLElement prototype and asserts what the layer helper
// does with it.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"
import { mountZag, sleep } from "./helpers/zag_mount.mjs"

const { FLOATING, floating, enterLayer, leaveLayer, syncLayer } = await import(
  "../../assets/js/layer.js"
)
const { LanternZagPopover } = await import("../../assets/js/zag/popover.js")

// Minimal Popover API: tracks open state and records calls.
function installPopoverApi(window) {
  const log = []
  const open = new WeakSet()
  const proto = window.HTMLElement.prototype
  proto.showPopover = function () {
    if (open.has(this)) throw new window.DOMException("already open", "InvalidStateError")
    open.add(this)
    log.push(["show", this.id || this.dataset?.part])
  }
  proto.hidePopover = function () {
    open.delete(this)
    log.push(["hide", this.id || this.dataset?.part])
  }
  const matches = proto.matches
  proto.matches = function (sel) {
    return sel === ":popover-open" ? open.has(this) : matches.call(this, sel)
  }
  return log
}

const mounts = []
afterEach(() => mounts.splice(0).forEach((m) => m.unmount()))

test("floating() defaults: fixed strategy, flip + shift, gutter, viewport padding, fit to viewport", () => {
  assert.equal(FLOATING.strategy, "fixed")
  assert.equal(FLOATING.flip, true)
  assert.equal(FLOATING.slide, true)
  assert.equal(FLOATING.fitViewport, true)
  assert.ok(FLOATING.gutter > 0 && FLOATING.overflowPadding >= 8)
  const opts = floating({ placement: "top", sameWidth: true })
  assert.deepEqual(
    { placement: opts.placement, sameWidth: opts.sameWidth, strategy: opts.strategy },
    { placement: "top", sameWidth: true, strategy: "fixed" }
  )
})

test("enterLayer/leaveLayer show and hide the element in the top layer, idempotently", () => {
  const h = mountHook(hooks.LanternOverlay, `<div id="x"><button data-part="trigger"></button><div id="p" data-part="panel" hidden></div></div>`)
  mounts.push(h)
  const log = installPopoverApi(h.window)
  const panel = h.document.getElementById("p")

  enterLayer(panel)
  enterLayer(panel)
  assert.equal(panel.getAttribute("popover"), "manual")
  assert.deepEqual(log, [["show", "p"]])

  leaveLayer(panel)
  leaveLayer(panel)
  assert.deepEqual(log, [["show", "p"], ["hide", "p"]])
})

test("layer helpers are no-ops without the Popover API", () => {
  const h = mountHook(hooks.LanternOverlay, `<div id="x"><button data-part="trigger"></button><div id="p" data-part="panel" hidden></div></div>`)
  mounts.push(h)
  const panel = h.document.getElementById("p")
  assert.doesNotThrow(() => syncLayer(panel, true))
  assert.equal(panel.hasAttribute("popover"), false)
})

test("opening a toast-covered layer re-raises the toast stack above it", () => {
  const h = mountHook(
    hooks.LanternOverlay,
    `<div id="x"><button data-part="trigger"></button><div id="p" data-part="panel" hidden></div>
     <div class="lui-toasts" id="t" popover="manual"><div class="lui-toast">hi</div></div></div>`
  )
  mounts.push(h)
  const log = installPopoverApi(h.window)
  const toasts = h.document.getElementById("t")
  enterLayer(toasts) // already showing, as the toast hook does on mount
  log.length = 0
  enterLayer(h.document.getElementById("p"))
  assert.deepEqual(log, [["show", "p"], ["hide", "t"], ["show", "t"]])
})

test("legacy overlay panel (trackPosition) enters the top layer on open and leaves on close", async () => {
  const h = mountHook(
    hooks.LanternOverlay,
    `<div id="ov" data-placement="bottom-start">
       <button data-part="trigger">Open</button>
       <div id="panel" data-part="panel" popover="manual" hidden><button>in</button></div>
     </div>`,
    { rootId: "ov" }
  )
  mounts.push(h)
  const log = installPopoverApi(h.window)
  // floating-ui's autoUpdate needs the DOM globals and observers jsdom lacks.
  for (const k of ["Element", "HTMLElement", "Node", "getComputedStyle"]) globalThis[k] ??= h.window[k]
  globalThis.ResizeObserver ??= class { observe() {} unobserve() {} disconnect() {} }
  globalThis.IntersectionObserver ??= class { observe() {} unobserve() {} disconnect() {} }

  h.hook.show()
  assert.deepEqual(log.at(-1), ["show", "panel"])
  assert.equal(h.document.getElementById("panel").style.position, "fixed")

  h.hook.hide()
  assert.deepEqual(log.at(-1), ["hide", "panel"])
  await sleep(50) // let the in-flight computePosition settle before teardown
})

test("Zag popover: positioner is fixed and joins the top layer only while open", async () => {
  const ctx = mountZag(
    LanternZagPopover,
    `<div id="pop1" data-zag data-default-value="false" data-placement="bottom-start">
       <div data-scope="popover" data-part="trigger"><button>Filters</button></div>
       <div data-scope="popover" data-part="positioner" popover="manual">
         <div data-scope="popover" data-part="content" role="dialog" hidden><p>Body</p></div>
       </div>
     </div>`,
    { rootId: "pop1", componentKey: "__lanternPopover", clientEvent: "pop-toggled" }
  )
  mounts.push(ctx)
  const log = installPopoverApi(ctx.el.ownerDocument.defaultView)
  const positioner = ctx.el.querySelector('[data-part="positioner"]')
  await sleep()

  ctx.el.querySelector("button").click()
  await sleep()
  assert.equal(positioner.style.position, "fixed", "Zag positions against the viewport, not the offset parent")
  assert.ok(log.some(([op]) => op === "show"), "opened into the top layer")

  ctx.el.querySelector("button").click()
  await sleep()
  assert.equal(log.at(-1)[0], "hide", "closed out of the top layer")
})
