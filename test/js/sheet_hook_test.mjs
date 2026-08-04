import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

class FakeElement {
  constructor(name) {
    this.name = name
    this.children = []
    this.listeners = new Map()
    this.dataset = {}
    this.hidden = false
    this.style = {}
    this.parts = new Map()
    this.offsetParent = {}
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

  click() {
    this.dispatch("click")
  }

  setAttribute(name, value) {
    this[name] = value
  }

  removeAttribute(name) {
    delete this[name]
  }

  querySelector(selector) {
    if (this.parts.has(selector)) return this.parts.get(selector)
    return this.querySelectorAll(selector)[0] || null
  }

  querySelectorAll(selector) {
    if (this.parts.has(selector)) return [this.parts.get(selector)]
    return this.children.flatMap((child) => child.querySelectorAll(selector))
  }

  contains(target) {
    return target === this || this.children.some((child) => child.contains(target))
  }
}

function fakeDocument() {
  const listeners = new Map()

  return {
    body: { style: {} },
    activeElement: null,
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

function mountedSheet() {
  globalThis.document = fakeDocument()
  globalThis.window = {
    matchMedia: () => ({ matches: true }),
  }

  const close = new FakeElement("close")
  const panel = new FakeElement("panel").append(close)
  const backdrop = new FakeElement("backdrop")
  const root = new FakeElement("root").append(backdrop, panel)
  root.id = "sheet"
  root.dataset = {
    open: "true",
    closeOnEsc: "true",
    closeOnOutside: "true",
    onClose: "[[\"push\",{\"event\":\"close_settings\"}]]",
  }
  root.parts.set('[data-part="panel"]', panel)
  root.parts.set('[data-part="close"]', close)

  const commands = []
  const hook = Object.assign(Object.create(Hooks.LanternSheet), {
    el: root,
    liveSocket: { execJS: (...args) => commands.push(args) },
    handleEvent() {},
  })
  hook.mounted()
  return { hook, root, close, commands }
}

test("LanternSheet executes on_close for close button, backdrop, Escape, and programmatic close", () => {
  for (const dismiss of [
    ({ close }) => close.click(),
    () => document.dispatch("pointerdown", { target: new FakeElement("outside") }),
    () => document.dispatch("keydown", { key: "Escape" }),
    ({ root }) => root.dispatch("lantern:dialog:close"),
  ]) {
    const { hook, root, close, commands } = mountedSheet()
    root.dispatch("lantern:dialog:open")
    dismiss({ root, close })
    assert.equal(hook.open, false)
    assert.equal(root.hidden, true)
    assert.equal(commands.length, 1)
    assert.equal(commands[0][0], root)
    assert.equal(commands[0][1], root.dataset.onClose)
  }
})
