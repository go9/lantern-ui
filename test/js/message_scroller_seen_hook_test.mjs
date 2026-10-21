// LanternMessageScroller `on_seen`: the host is told the newest message the
// reader has actually seen, never one appended while they read history.
import assert from "node:assert/strict"
import { test } from "node:test"
import { JSDOM } from "jsdom"

import { hooks, mountHook } from "./helpers/dom.mjs"

// The hook uses bare MutationObserver/requestAnimationFrame at mount.
const realm = new JSDOM("").window
globalThis.MutationObserver = realm.MutationObserver
globalThis.requestAnimationFrame = (cb) => cb()

const html = (onSeen = ' data-on-seen="seen"') => `
<div id="chat" data-part="scroller" data-follow="true" data-peek="40"${onSeen}>
  <div data-part="viewport">
    <div data-part="content">
      <div data-part="item" data-message-id="m1">one</div>
      <div data-part="item" data-message-id="m2">two</div>
    </div>
  </div>
  <button data-part="jump-latest" aria-hidden="true" tabindex="-1">Jump</button>
</div>`

// jsdom has no layout: give the viewport a scrollable geometry.
function geometry(m) {
  const viewport = m.document.querySelector("[data-part=viewport]")
  let top = 0
  Object.defineProperty(viewport, "scrollHeight", { configurable: true, get: () => 1000 })
  Object.defineProperty(viewport, "clientHeight", { configurable: true, get: () => 200 })
  Object.defineProperty(viewport, "scrollTop", {
    configurable: true,
    get: () => top,
    set: (v) => (top = Math.max(0, Math.min(800, v))),
  })
  return viewport
}

// jsdom has no layout either: treat an element as rendered unless it or an
// ancestor is hidden/display:none/visibility:hidden, and lay every rendered
// box inside the window (a test moves one off screen by overriding it).
function layout(m) {
  const { window } = m
  const rendered = (el) => {
    for (let node = el; node; node = node.parentElement) {
      if (node.hidden || node.style?.display === "none" || node.style?.visibility === "hidden") return false
    }
    return true
  }
  window.HTMLElement.prototype.getClientRects = function () {
    return rendered(this) ? [this.getBoundingClientRect()] : []
  }
  window.HTMLElement.prototype.getBoundingClientRect = function () {
    return rendered(this)
      ? { top: 0, bottom: 20, left: 0, right: 100, width: 100, height: 20 }
      : { top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0 }
  }
}
// Lay out the fixture's realm before the hook's first report.
const mount = (markup = html()) =>
  mountHook(
    {
      ...hooks.LanternMessageScroller,
      mounted() {
        layout({ window: this.el.ownerDocument.defaultView })
        hooks.LanternMessageScroller.mounted.call(this)
      },
    },
    markup,
    { rootId: "chat" },
  )

const append = (m, id) => {
  const item = m.document.createElement("div")
  item.dataset.part = "item"
  item.dataset.messageId = id
  m.document.querySelector("[data-part=content]").append(item)
}
const flush = () => new Promise((r) => setTimeout(r, 0))
const seen = (m) => m.pushEvent.filter((e) => e.event === "seen").map((e) => e.payload.message_id)

test("reports the last message once it is in view, once per id", async () => {
  const m = mount()
  // jsdom geometry is all zeros at mount: the viewport is "at the bottom".
  assert.deepEqual(seen(m), ["m2"])
  m.hook.updateState()
  assert.deepEqual(seen(m), ["m2"], "no duplicate for the same id")
  m.unmount()
})

test("a message appended while reading history stays unseen until the reader reaches it", async () => {
  const m = mount()
  const viewport = geometry(m)
  viewport.scrollTop = 100
  viewport.dispatchEvent(new m.window.Event("scroll"))
  append(m, "m3")
  await flush()
  assert.deepEqual(seen(m), ["m2"], "paused above the bottom: m3 not reported")

  m.document.querySelector("[data-part=jump-latest]").click()
  assert.deepEqual(seen(m), ["m2", "m3"], "Jump to latest reports it")
  m.unmount()
})

test("following at the bottom reports appended messages", async () => {
  const m = mount()
  geometry(m).scrollTop = 800
  append(m, "m3")
  await flush()
  assert.deepEqual(seen(m), ["m2", "m3"])
  m.unmount()
})

test("a hidden tab reports nothing until it is visible again", async () => {
  const m = mount()
  geometry(m).scrollTop = 800
  let state = "hidden"
  Object.defineProperty(m.document, "visibilityState", { configurable: true, get: () => state })
  append(m, "m3")
  await flush()
  assert.deepEqual(seen(m), ["m2"])
  state = "visible"
  m.document.dispatchEvent(new m.window.Event("visibilitychange"))
  assert.deepEqual(seen(m), ["m2", "m3"])
  m.unmount()
})

test("without on_seen nothing is pushed", async () => {
  const m = mount(html(""))
  append(m, "m3")
  await flush()
  assert.deepEqual(m.pushEvent, [])
  m.unmount()
})

test("a hidden transcript acknowledges nothing until it is shown", async () => {
  const m = mount()
  const viewport = geometry(m)
  viewport.scrollTop = 800
  for (const hide of [
    (el) => (el.style.display = "none"),
    (el) => (el.style.visibility = "hidden"),
    (el) => (el.hidden = true),
  ]) {
    hide(m.el)
    const id = `m-hidden-${m.pushEvent.length}-${Math.random()}`
    append(m, id)
    await flush()
    assert.ok(!seen(m).includes(id), "at the bottom of a hidden transcript: not seen")
    m.el.removeAttribute("style")
    m.el.hidden = false
    viewport.dispatchEvent(new m.window.Event("scroll"))
    assert.equal(seen(m).at(-1), id, "shown again: reported")
  }
  m.unmount()
})

test("a last message outside the window is not acknowledged", async () => {
  const m = mount()
  geometry(m).scrollTop = 800
  append(m, "m-offscreen")
  const item = m.document.querySelector('[data-message-id="m-offscreen"]')
  item.getBoundingClientRect = () => ({ top: 2000, bottom: 2020, left: 0, right: 100, width: 100, height: 20 })
  await flush()
  assert.deepEqual(seen(m), ["m2"])
  m.unmount()
})

test("a rejected push is not cached: the same message is reported after reconnect", async () => {
  const m = mount()
  const viewport = geometry(m)
  viewport.scrollTop = 800
  const attempts = []
  let connected = false
  m.hook.pushEvent = (event, payload) => {
    attempts.push(payload.message_id)
    return connected ? Promise.resolve({}) : Promise.reject(new Error("LiveView not connected"))
  }
  append(m, "m12")
  await flush()
  assert.deepEqual(attempts, ["m12"])

  connected = true
  m.hook.reconnected()
  await flush()
  assert.deepEqual(attempts, ["m12", "m12"], "retried on reconnect")
  m.hook.reconnected()
  await flush()
  assert.deepEqual(attempts, ["m12", "m12"], "delivered once: no further retries")
  m.unmount()
})

test("a push still in flight is not sent twice", async () => {
  const m = mount()
  geometry(m).scrollTop = 800
  const attempts = []
  let resolve
  m.hook.pushEvent = (event, payload) => {
    attempts.push(payload.message_id)
    return new Promise((r) => (resolve = r))
  }
  append(m, "m3")
  await flush()
  m.hook.updateState()
  assert.deepEqual(attempts, ["m3"])
  resolve({})
  await flush()
  m.hook.updateState()
  assert.deepEqual(attempts, ["m3"])
  m.unmount()
})
