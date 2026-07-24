import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

class FakeElement {
  constructor(name, { visible = true, focusable = false } = {}) {
    this.name = name
    this.offsetParent = visible ? {} : null
    this.focusable = focusable
    this.children = []
    this.listeners = new Map()
    this.dataset = {}
    this.hidden = false
    this.style = {}
    this.parts = new Map()
  }

  append(...children) {
    this.children.push(...children)
    return this
  }

  addEventListener(type, handler) {
    const handlers = this.listeners.get(type) || []
    handlers.push(handler)
    this.listeners.set(type, handlers)
  }

  removeEventListener(type, handler) {
    this.listeners.set(
      type,
      (this.listeners.get(type) || []).filter((candidate) => candidate !== handler)
    )
  }

  dispatch(type, event = {}) {
    for (const handler of this.listeners.get(type) || []) handler({ type, ...event })
  }

  focus() {
    document.activeElement = this
  }

  matches() {
    return this.focusable
  }

  querySelector(selector) {
    if (this.parts.has(selector)) return this.parts.get(selector)
    return this.querySelectorAll(selector)[0] || null
  }

  querySelectorAll(selector) {
    if (selector === '[data-part="close"]') return []

    return this.children.flatMap((child) => [
      ...(child.focusable ? [child] : []),
      ...child.querySelectorAll(selector),
    ])
  }

  contains(target) {
    return target === this || this.children.some((child) => child.contains(target))
  }
}

function fakeDocument(activeElement) {
  const listeners = new Map()

  return {
    activeElement,
    body: { style: {} },
    addEventListener(type, handler) {
      const handlers = listeners.get(type) || []
      handlers.push(handler)
      listeners.set(type, handlers)
    },
    removeEventListener(type, handler) {
      listeners.set(
        type,
        (listeners.get(type) || []).filter((candidate) => candidate !== handler)
      )
    },
    dispatch(type, event) {
      for (const handler of listeners.get(type) || []) handler(event)
    },
  }
}

const source = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")
const moduleUrl = `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
const { Hooks } = await import(moduleUrl)

test("LanternModal executes alert-dialog focus, trapping, and dismissal policy", () => {
  const trigger = new FakeElement("trigger", { focusable: true })
  globalThis.document = fakeDocument(trigger)

  const hiddenCancel = new FakeElement("hidden-cancel", { visible: false, focusable: true })
  const cancel = new FakeElement("cancel", { focusable: true })
  const action = new FakeElement("action", { focusable: true })
  const cancelRegion = new FakeElement("cancel-region").append(hiddenCancel, cancel)
  const panel = new FakeElement("panel").append(hiddenCancel, cancel, action)
  panel.parts.set("[data-part='alert-dialog-cancel']", cancelRegion)

  const root = new FakeElement("root").append(panel)
  root.hidden = true
  root.dataset = {
    closeOnEsc: "true",
    closeOnOutside: "false",
    initialFocus: "[data-part='alert-dialog-cancel']",
  }
  root.parts.set('[data-part="panel"]', panel)

  const hook = Object.assign(Object.create(Hooks.LanternModal), {
    el: root,
    handleEvent() {},
  })
  hook.mounted()

  root.dispatch("lantern:dialog:open")
  assert.equal(hook.open, true)
  assert.equal(root.hidden, false)
  assert.equal(document.activeElement, cancel, "hidden cancel is skipped; visible cancel is focused")

  action.focus()
  let prevented = false
  panel.dispatch("keydown", { key: "Tab", shiftKey: false, preventDefault: () => (prevented = true) })
  assert.equal(document.activeElement, cancel)
  assert.equal(prevented, true, "Tab wraps from the action to the first visible control")

  cancel.focus()
  panel.dispatch("keydown", { key: "Tab", shiftKey: true, preventDefault() {} })
  assert.equal(document.activeElement, action, "Shift+Tab remains trapped")

  const outside = new FakeElement("outside")
  document.dispatch("pointerdown", { target: outside })
  assert.equal(hook.open, true, "outside pointer does not dismiss an alert dialog")

  document.dispatch("keydown", { key: "Escape" })
  assert.equal(hook.open, false)
  assert.equal(root.hidden, true)
  assert.equal(document.activeElement, trigger, "Escape restores focus to the opener")

  root.dispatch("lantern:dialog:open")
  action.focus()
  root.dispatch("lantern:dialog:close")
  assert.equal(hook.open, false, "consumer-owned cancel/action paths can close through the shared event")
  assert.equal(document.activeElement, trigger)
})
