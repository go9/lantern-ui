// Shared mount harness for the Zag widget tests (flicker #3416, step 2).
//
// Same approach as `zag_select_hook_test.mjs`: import the Zag source module
// directly (bare `@zag-js/*` specifiers resolve from `node_modules`) and
// mount the `createZagLiveHook` delegate against jsdom fixtures shaped like
// the component's HEEx output. Globals Zag needs are installed per mount.

import { JSDOM } from "jsdom"

const SHIM_KEYS = [
  "document",
  "window",
  "Element",
  "HTMLElement",
  "Node",
  "Event",
  "CustomEvent",
  "KeyboardEvent",
  "CSS",
  "getComputedStyle",
]

/**
 * Mount a Zag hook delegate against `html`.
 *
 * Returns `{ hook, el, pushEvent, clientEvents, component, serverPush,
 * patch, unmount }`. `patch(fn)` simulates a LiveView morph: it snapshots
 * controlled attrs (`beforeUpdate`), applies `fn(el)`, then runs `updated`.
 */
export function mountZag(Hook, html, { rootId, componentKey, clientEvent } = {}) {
  const dom = new JSDOM(`<!doctype html><html><body>${html}</body></html>`, {
    pretendToBeVisual: true,
    url: "https://lantern.test/",
  })
  const { window } = dom
  const previous = {}
  for (const key of SHIM_KEYS) {
    previous[key] = globalThis[key]
    if (window[key] !== undefined) globalThis[key] = window[key]
  }
  globalThis.requestAnimationFrame = window.requestAnimationFrame.bind(window)
  globalThis.cancelAnimationFrame = window.cancelAnimationFrame.bind(window)
  globalThis.MutationObserver = window.MutationObserver
  // jsdom implements neither; Zag calls both during open/select.
  window.HTMLElement.prototype.scrollIntoView = function scrollIntoView() {}
  window.Element.prototype.scrollTo = function scrollTo() {}
  if (globalThis.ResizeObserver === undefined) {
    globalThis.ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    }
  }

  const el = rootId ? window.document.getElementById(rootId) : window.document.body.firstElementChild
  const pushEvent = []
  const serverEvents = new Map()
  const clientEvents = []
  if (clientEvent) el.addEventListener(clientEvent, (e) => clientEvents.push(e))

  const hook = Object.create(Hook)
  Object.assign(hook, {
    el,
    pushEvent: (event, payload) => pushEvent.push({ event, payload }),
    handleEvent: (event, callback) => serverEvents.set(event, callback),
  })
  hook.mounted()

  return {
    hook,
    window,
    document: window.document,
    el,
    pushEvent,
    clientEvents,
    component: () => el[componentKey],
    serverPush: (event, payload) => serverEvents.get(event)?.(payload),
    patch(patchFn) {
      hook.beforeUpdate()
      patchFn(el)
      hook.updated()
    },
    unmount() {
      hook.destroyed?.()
      for (const key of Object.keys(previous)) globalThis[key] = previous[key]
      delete globalThis.requestAnimationFrame
      delete globalThis.cancelAnimationFrame
      delete globalThis.MutationObserver
      window.close()
    },
  }
}

export const sleep = (ms = 20) => new Promise((resolve) => setTimeout(resolve, ms))

/**
 * Poll `check()` until it returns truthy (or `timeout` elapses). Zag opens
 * through async machine effects, so a fixed sleep is flaky — wait for the
 * state instead.
 */
export async function waitFor(check, { timeout = 1000, interval = 10 } = {}) {
  const started = Date.now()
  for (;;) {
    if (await check()) return
    if (Date.now() - started > timeout) throw new Error("waitFor: timed out")
    await sleep(interval)
  }
}
