// Shared mount harness for the Zag widget tests (flicker #3416, step 2).
//
// Same approach as `zag_select_hook_test.mjs`: import the Zag source module
// directly (bare `@zag-js/*` specifiers resolve from `node_modules`) and
// mount the `createZagLiveHook` delegate against jsdom fixtures shaped like
// the component's HEEx output. Globals Zag needs are installed per mount.

import { JSDOM } from "jsdom"

// Static deep import: the package root does not export the singleton, and
// the relative file URL resolves to the same module instance the machines
// use. Pinned via package-lock; if Zag restructures, every Zag test fails
// to load — loudly.
import { layerStack } from "../../../node_modules/@zag-js/dismissable/dist/layer-stack.mjs"

// Zag's dismissable layerStack is a module-level singleton. Each mount here
// owns a fresh JSDOM document, so two pieces of its state must be pruned at
// mount — in production there is a single document and both are correct, so
// this is test-only:
//
// 1. `layers` left behind by mounts that unmounted while open (whose
//    documents are closed): only the topmost layer dismisses, so a dead
//    layer on top would suppress outside dismissal in later tests.
// 2. `recentlyRemoved`: `layerStack.remove()` defers its cleanup to a
//    double-rAF, and `window.close()` in unmount can strand a pending
//    cleanup so the set stays non-empty forever. `isInNestedLayer()` treats
//    a non-empty set as "everything is nested" and vetoes every future
//    outside-dismiss in the process.
function pruneStaleLayers(document) {
  for (const layer of [...layerStack.layers]) {
    if (layer?.node?.ownerDocument !== document) layerStack.remove(layer.node)
  }
  for (const branch of [...layerStack.branches]) {
    if (branch?.ownerDocument !== document) layerStack.removeBranch(branch)
  }
  layerStack.recentlyRemoved.clear()
}

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
export function mountZag(Hook, html, { rootId, componentKey, clientEvent, liveSocket } = {}) {
  const dom = new JSDOM(`<!doctype html><html><body>${html}</body></html>`, {
    pretendToBeVisual: true,
    url: "https://lantern.test/",
  })
  const { window } = dom
  pruneStaleLayers(window.document)
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
    liveSocket,
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

/**
 * Dismiss an open overlay with an outside pointerdown, retrying until it
 * closes. The dismissable listener attaches on a raf after open, so a
 * single dispatch can land before it (a deterministic miss when dispatched
 * synchronously after open) — retry instead of sleeping a magic duration.
 *
 * Far-away coordinates: jsdom reports every rect as zeros, so (0,0) reads
 * as "within" the overlay and interact-outside ignores it.
 */
export async function dismissOutside(document, isOpen, { timeout = 2000 } = {}) {
  const view = document.defaultView
  const EventCtor = view.PointerEvent ?? view.MouseEvent
  await waitFor(async () => {
    const outside = document.createElement("div")
    document.body.append(outside)
    outside.dispatchEvent(
      new EventCtor("pointerdown", {
        bubbles: true,
        cancelable: true,
        button: 0,
        clientX: 9999,
        clientY: 9999,
      })
    )
    await sleep(30)
    const done = !isOpen()
    outside.remove()
    return done
  }, { timeout })
}
