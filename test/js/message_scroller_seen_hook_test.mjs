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

const append = (m, id) => {
  const item = m.document.createElement("div")
  item.dataset.part = "item"
  item.dataset.messageId = id
  m.document.querySelector("[data-part=content]").append(item)
}
const flush = () => new Promise((r) => setTimeout(r, 0))
const seen = (m) => m.pushEvent.filter((e) => e.event === "seen").map((e) => e.payload.message_id)

test("reports the last message once it is in view, once per id", async () => {
  const m = mountHook(hooks.LanternMessageScroller, html(), { rootId: "chat" })
  // jsdom geometry is all zeros at mount: the viewport is "at the bottom".
  assert.deepEqual(seen(m), ["m2"])
  m.hook.updateState()
  assert.deepEqual(seen(m), ["m2"], "no duplicate for the same id")
  m.unmount()
})

test("a message appended while reading history stays unseen until the reader reaches it", async () => {
  const m = mountHook(hooks.LanternMessageScroller, html(), { rootId: "chat" })
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
  const m = mountHook(hooks.LanternMessageScroller, html(), { rootId: "chat" })
  geometry(m).scrollTop = 800
  append(m, "m3")
  await flush()
  assert.deepEqual(seen(m), ["m2", "m3"])
  m.unmount()
})

test("a hidden tab reports nothing until it is visible again", async () => {
  const m = mountHook(hooks.LanternMessageScroller, html(), { rootId: "chat" })
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
  const m = mountHook(hooks.LanternMessageScroller, html(""), { rootId: "chat" })
  append(m, "m3")
  await flush()
  assert.deepEqual(m.pushEvent, [])
  m.unmount()
})
