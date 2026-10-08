import assert from "node:assert/strict"
import test from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"

test("LanternActionBar reports CSS-pixel promotion tiers after resize", () => {
  const mounted = mountHook(
    hooks.LanternActionBar,
    '<div id="bar" data-action-bar><div data-part="inline-actions"></div></div>',
    { rootId: "bar" }
  )

  let width = 1440
  mounted.el.getBoundingClientRect = () => ({ width })
  mounted.hook.updated()
  assert.equal(mounted.el.dataset.promoted, "3")

  for (const [nextWidth, promoted] of [
    [1100, "2"],
    [768, "2"],
    [390, "1"],
  ]) {
    width = nextWidth
    mounted.window.dispatchEvent(new mounted.window.Event("resize"))
    assert.equal(mounted.el.dataset.promoted, promoted)
  }

  mounted.unmount()
})

test("LanternActionBar observes the bar with ResizeObserver and updates promotion", () => {
  const previousObserver = globalThis.ResizeObserver
  let observed
  let callback
  let disconnected = false
  globalThis.ResizeObserver = class ResizeObserver {
    constructor(onResize) {
      callback = onResize
    }

    observe(el) {
      observed = el
    }

    disconnect() {
      disconnected = true
    }
  }

  let mounted
  try {
    mounted = mountHook(
      hooks.LanternActionBar,
      '<div id="bar" data-action-bar><div data-part="inline-actions"></div></div>',
      { rootId: "bar" },
    )

    let width = 1440
    mounted.el.getBoundingClientRect = () => ({ width })
    callback()
    assert.equal(observed, mounted.el)
    assert.equal(mounted.el.dataset.promoted, "3")

    width = 1100
    callback()
    assert.equal(mounted.el.dataset.promoted, "2")
    width = 739
    callback()
    assert.equal(mounted.el.dataset.promoted, "1")
  } finally {
    mounted?.unmount()
    if (previousObserver === undefined) delete globalThis.ResizeObserver
    else globalThis.ResizeObserver = previousObserver
  }

  assert.equal(disconnected, true)
})

test("fallback notice dismissal persists and is reapplied after LiveView updates", () => {
  const storage = new Map()
  const previousStorage = globalThis.localStorage
  globalThis.localStorage = {
    getItem: (key) => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value),
  }

  let mounted
  try {
    mounted = mountHook(
      hooks.LanternActionBar,
      '<div id="bar" data-action-bar><div data-action-bar-notice data-dismissal-key="items:sync-2" data-server-dismissed="false"><button data-part="dismiss">Dismiss</button></div></div>',
      { rootId: "bar" }
    )

    const notice = mounted.el.querySelector("[data-action-bar-notice]")
    assert.equal(notice.hidden, false)

    notice.querySelector("[data-part='dismiss']").click()
    assert.equal(notice.hidden, true)
    assert.equal(storage.get("lantern:notice:items:sync-2"), "dismissed")

    notice.hidden = false
    mounted.hook.updated()
    assert.equal(notice.hidden, true)
  } finally {
    mounted?.unmount()
    if (previousStorage === undefined) delete globalThis.localStorage
    else globalThis.localStorage = previousStorage
  }
})

test("server-owned dismissal is not replaced by local hook state", () => {
  const storage = new Map()
  const previousStorage = globalThis.localStorage
  globalThis.localStorage = {
    getItem: (key) => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value),
  }

  let mounted
  try {
    mounted = mountHook(
      hooks.LanternActionBar,
      '<div id="bar" data-action-bar data-dismissal-event="dismiss_notice"><div data-action-bar-notice data-dismissal-key="items:sync-2" data-server-dismissed="false"><button data-part="dismiss">Dismiss</button></div></div>',
      { rootId: "bar" }
    )

    const notice = mounted.el.querySelector("[data-action-bar-notice]")
    notice.querySelector("[data-part='dismiss']").click()

    assert.equal(notice.hidden, false)
    assert.equal(storage.size, 0)
  } finally {
    mounted?.unmount()
    if (previousStorage === undefined) delete globalThis.localStorage
    else globalThis.localStorage = previousStorage
  }
})
