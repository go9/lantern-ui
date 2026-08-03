// Shared jsdom harness for exercising the hooks in
// `priv/static/lantern_ui_hooks.js` as real code against a real DOM.
//
// Why this exists: every other test in this repo renders HEEx and inspects the
// resulting string, which cannot execute a single line of hook behaviour. Two
// user-visible `command` bugs shipped past that suite because both lived
// entirely in the hook. A test that asserts on the hook's *source text* catches
// a regression of a bug you already know about; it proves nothing about
// behaviour. This harness lets a test mount a hook, drive it, and assert on
// what the user would actually see.
//
// jsdom is a devDependency of the repo's private `package.json`. It is not part
// of the Hex package (see the `files:` whitelist in `mix.exs`), so consumers of
// `:lantern_ui` never see a JS toolchain.

import { readFile } from "node:fs/promises"
import { JSDOM } from "jsdom"

// The bundle is an ES module authored for the browser. Loading it through a
// data: URL keeps the on-disk file the single source of truth — no build step,
// no copy that can drift from what ships in `priv/static`.
const source = await readFile(new URL("../../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")

export const hooks = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)

// jsdom has no layout engine, so two things the hooks legitimately rely on are
// missing. Shimming them here — rather than weakening the hooks — keeps the
// production code honest about what a browser provides.
function patchLayoutGaps(window) {
  // `offsetParent` is always null in jsdom. `trapFocus` filters candidates on
  // `offsetParent !== null` to skip elements hidden by CSS, so without this
  // every element looks invisible and focus management silently does nothing.
  // Approximate it the only way jsdom can: an element is "laid out" unless it
  // or an ancestor is `hidden` or `display: none`.
  Object.defineProperty(window.HTMLElement.prototype, "offsetParent", {
    configurable: true,
    get() {
      for (let node = this; node && node !== window.document.body; node = node.parentElement) {
        if (node.hidden || node.style?.display === "none") return null
      }
      return this === window.document.body ? null : this.parentElement
    },
  })

  // Not implemented by jsdom at all; `setActive` calls it on every highlight
  // move and would throw.
  window.HTMLElement.prototype.scrollIntoView = function scrollIntoView() {}
}

/**
 * Mount a hook against an HTML fixture and return everything a test needs to
 * drive it.
 *
 * The returned object exposes the two push spies separately on purpose: which
 * one a hook reaches for is a behavioural contract (a palette rendered inside a
 * LiveComponent MUST use `pushEventTo`), not an implementation detail.
 */
export function mountHook(hook, html, { rootId } = {}) {
  const dom = new JSDOM(`<!doctype html><html><body>${html}</body></html>`, { pretendToBeVisual: true })
  const { window } = dom
  patchLayoutGaps(window)

  // The hooks reference bare `document` / `window`, which resolve against
  // globalThis at call time. Node's test runner gives each file its own
  // process, so installing them globally is safe within a file.
  const previous = { document: globalThis.document, window: globalThis.window }
  globalThis.document = window.document
  globalThis.window = window

  const el = rootId ? window.document.getElementById(rootId) : window.document.body.firstElementChild
  if (!el) throw new Error("mountHook: fixture has no root element")

  const pushEvent = []
  const pushEventTo = []
  const serverEvents = new Map()

  const context = Object.create(hook)
  Object.assign(context, {
    el,
    pushEvent: (event, payload) => pushEvent.push({ event, payload }),
    pushEventTo: (target, event, payload) => pushEventTo.push({ target, event, payload }),
    handleEvent: (event, callback) => serverEvents.set(event, callback),
  })

  context.mounted()

  return {
    hook: context,
    window,
    document: window.document,
    el,
    pushEvent,
    pushEventTo,
    /** Fire a server-pushed event the way `LanternUI.open_dialog/2` would. */
    serverPush: (event, payload) => serverEvents.get(event)?.(payload),
    /** Run `destroyed()` and restore the globals this mount replaced. */
    unmount() {
      context.destroyed?.()
      globalThis.document = previous.document
      globalThis.window = previous.window
      window.close()
    },
  }
}

/** Dispatch a real, bubbling keydown so delegated listeners see it. */
export function keydown(target, key, init = {}) {
  const window = target.ownerDocument.defaultView
  const event = new window.KeyboardEvent("keydown", { key, bubbles: true, cancelable: true, ...init })
  target.dispatchEvent(event)
  return event
}

/** Type into an input the way a user does: set the value, then fire `input`. */
export function type(input, value) {
  const window = input.ownerDocument.defaultView
  input.value = value
  input.dispatchEvent(new window.Event("input", { bubbles: true }))
}

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
