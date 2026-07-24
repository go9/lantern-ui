import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { afterEach, test } from "node:test"

const hookSource = await readFile(
  new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url),
  "utf8"
)
const encodedHookSource = Buffer.from(hookSource).toString("base64")
const hookModule = await import(`data:text/javascript;base64,${encodedHookSource}`)
const { LanternAccordion } = hookModule

class FakeEvent {
  constructor(type, { bubbles = false, key = null } = {}) {
    this.type = type
    this.bubbles = bubbles
    this.key = key
    this.target = null
    this.currentTarget = null
    this.defaultPrevented = false
  }

  preventDefault() {
    this.defaultPrevented = true
  }
}

class FakeElement {
  constructor(ownerDocument, tagName) {
    this.ownerDocument = ownerDocument
    this.tagName = tagName.toUpperCase()
    this.parentElement = null
    this.children = []
    this.dataset = {}
    this.disabled = false
    this.hidden = false
    this.listeners = new Map()
    this.attributes = new Map()
    this._id = ""
  }

  get id() {
    return this._id
  }

  set id(value) {
    this._id = String(value)
    this.attributes.set("id", this._id)
  }

  append(...children) {
    children.forEach((child) => {
      child.parentElement = this
      this.children.push(child)
    })
  }

  replaceChildren(...children) {
    this.children.forEach((child) => {
      child.parentElement = null
    })
    this.children = []
    this.append(...children)
  }

  setAttribute(name, value) {
    const stringValue = String(value)
    this.attributes.set(name, stringValue)
    if (name === "id") this._id = stringValue
    if (name === "disabled") this.disabled = true
    if (name === "hidden") this.hidden = true
    if (name.startsWith("data-")) {
      const key = name
        .slice(5)
        .replace(/-([a-z])/g, (_match, character) => character.toUpperCase())
      this.dataset[key] = stringValue
    }
  }

  getAttribute(name) {
    return this.attributes.has(name) ? this.attributes.get(name) : null
  }

  hasAttribute(name) {
    return this.attributes.has(name)
  }

  removeAttribute(name) {
    this.attributes.delete(name)
    if (name === "disabled") this.disabled = false
    if (name === "hidden") this.hidden = false
  }

  matches(selector) {
    const match = /^\[([^=]+)="([^"]+)"\]$/.exec(selector)
    return Boolean(match && this.getAttribute(match[1]) === match[2])
  }

  closest(selector) {
    let element = this
    while (element) {
      if (element.matches(selector)) return element
      element = element.parentElement
    }
    return null
  }

  querySelectorAll(selector) {
    const matches = []
    const visit = (element) => {
      element.children.forEach((child) => {
        if (child.matches(selector)) matches.push(child)
        visit(child)
      })
    }
    visit(this)
    return matches
  }

  querySelector(selector) {
    return this.querySelectorAll(selector)[0] || null
  }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) || []
    listeners.push(listener)
    this.listeners.set(type, listeners)
  }

  removeEventListener(type, listener) {
    const listeners = this.listeners.get(type) || []
    this.listeners.set(
      type,
      listeners.filter((candidate) => candidate !== listener)
    )
  }

  dispatchEvent(event) {
    if (!event.target) event.target = this
    let element = this
    do {
      event.currentTarget = element
      const listeners = element.listeners.get(event.type) || []
      listeners.slice().forEach((listener) => listener(event))
      element = event.bubbles ? element.parentElement : null
    } while (element)
    return !event.defaultPrevented
  }

  click() {
    this.dispatchEvent(new FakeEvent("click", { bubbles: true }))
  }

  focus() {
    this.ownerDocument.activeElement = this
  }
}

class FakeDocument {
  constructor() {
    this.body = new FakeElement(this, "body")
    this.activeElement = this.body
  }

  createElement(tagName) {
    return new FakeElement(this, tagName)
  }

  getElementById(id) {
    if (this.body.id === id) return this.body
    return this.findById(id)
  }

  findById(id) {
    const visit = (element) => {
      for (const child of element.children) {
        if (child.id === id) return child
        const nested = visit(child)
        if (nested) return nested
      }
      return null
    }
    return visit(this.body)
  }
}

let currentDocument

afterEach(() => {
  currentDocument = null
  delete globalThis.document
})

function createElement(document, tagName, attributes = {}) {
  const element = document.createElement(tagName)
  Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value))
  return element
}

function item(document, id, { expanded = false, nested = null } = {}) {
  const itemRoot = createElement(document, "div", {
    id,
    "data-part": "item",
    "data-state": expanded ? "open" : "closed",
  })
  const heading = createElement(document, "div", { role: "heading", "aria-level": "3" })
  const trigger = createElement(document, "button", {
    id: `${id}-trigger`,
    "data-part": "trigger",
    "aria-expanded": String(expanded),
    "aria-controls": `${id}-panel`,
  })
  const panel = createElement(document, "div", {
    id: `${id}-panel`,
    "data-part": "panel",
    role: "region",
    "aria-labelledby": `${id}-trigger`,
  })
  panel.hidden = !expanded
  heading.append(trigger)
  if (nested) panel.append(nested)
  itemRoot.append(heading, panel)
  return itemRoot
}

function accordion(
  document,
  id,
  items,
  { multiple = false, preventAllClosed = false, animationDuration = 300 } = {}
) {
  const root = createElement(document, "div", {
    id,
    "phx-hook": "LanternAccordion",
    "data-multiple": String(multiple),
    "data-prevent-all-closed": String(preventAllClosed),
    "data-animation-duration": String(animationDuration),
  })
  root.append(...items)
  return root
}

function setup(root) {
  currentDocument = root.ownerDocument
  globalThis.document = currentDocument
  currentDocument.body.append(root)
  const hook = Object.create(LanternAccordion)
  hook.el = root
  hook.mounted()
  return { hook, root }
}

function testDocument() {
  return new FakeDocument()
}

function triggers(root) {
  return Array.from(root.querySelectorAll('[data-part="trigger"]')).filter(
    (trigger) => trigger.closest('[phx-hook="LanternAccordion"]') === root
  )
}

function openStates(root) {
  return triggers(root).map((trigger) => trigger.getAttribute("aria-expanded"))
}

function activateWithKeyboard(trigger, key) {
  trigger.dispatchEvent(new FakeEvent("keydown", { key, bubbles: true }))
  if (key === " ") trigger.dispatchEvent(new FakeEvent("keyup", { key, bubbles: true }))
  // Browsers synthesize a click for Enter/Space activation of a native button.
  trigger.click()
}

test("the stylesheet disables accordion transitions for reduced motion", async () => {
  const css = await readFile(new URL("../../priv/static/lantern_ui.css", import.meta.url), "utf8")
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/)
  assert.match(css, /\.lui-accordion-trigger,\s*\.lui-accordion-icon \{ transition: none; \}/)
})

test("click, Enter, and Space activation enforce single-open state", () => {
  const document = testDocument()
  const root = accordion(document, "single", [item(document, "one"), item(document, "two")])
  setup(root)
  const [one, two] = triggers(root)

  one.click()
  assert.deepEqual(openStates(root), ["true", "false"])
  assert.equal(document.getElementById("one-panel").hidden, false)

  activateWithKeyboard(two, "Enter")
  assert.deepEqual(openStates(root), ["false", "true"])

  activateWithKeyboard(two, " ")
  assert.deepEqual(openStates(root), ["false", "false"])
  assert.equal(document.getElementById("two-panel").hidden, true)
})

test("ArrowUp/ArrowDown/Home/End wrap focus among owned headers", () => {
  const document = testDocument()
  const root = accordion(document, "focus", [
    item(document, "one"),
    item(document, "two"),
    item(document, "three"),
  ])
  setup(root)
  const [one, two, three] = triggers(root)

  one.focus()
  one.dispatchEvent(new FakeEvent("keydown", { key: "ArrowUp", bubbles: true }))
  assert.equal(document.activeElement, three)

  three.dispatchEvent(new FakeEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, one)

  one.dispatchEvent(new FakeEvent("keydown", { key: "End", bubbles: true }))
  assert.equal(document.activeElement, three)

  three.dispatchEvent(new FakeEvent("keydown", { key: "Home", bubbles: true }))
  assert.equal(document.activeElement, one)

  two.dispatchEvent(new FakeEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, three)
})

test("multiple mode and prevent-all-closed update aria-disabled with operability", () => {
  const document = testDocument()
  const root = accordion(document, "multiple", [item(document, "one"), item(document, "two")], {
    multiple: true,
    preventAllClosed: true,
  })
  setup(root)
  const [one, two] = triggers(root)

  assert.deepEqual(openStates(root), ["true", "false"])
  assert.equal(one.getAttribute("aria-disabled"), "true")
  one.click()
  assert.deepEqual(openStates(root), ["true", "false"])

  two.click()
  assert.deepEqual(openStates(root), ["true", "true"])
  assert.equal(one.hasAttribute("aria-disabled"), false)
  assert.equal(two.hasAttribute("aria-disabled"), false)

  one.click()
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(two.getAttribute("aria-disabled"), "true")
})

test("nested accordions isolate events, state, panels, and focus", () => {
  const document = testDocument()
  const inner = accordion(document, "inner", [item(document, "inner-one"), item(document, "inner-two")], {
    multiple: true,
  })
  const outer = accordion(document, "outer", [
    item(document, "outer-one", { nested: inner }),
    item(document, "outer-two"),
  ])
  const { hook: outerHook } = setup(outer)
  const innerHook = Object.create(LanternAccordion)
  innerHook.el = inner
  innerHook.mounted()

  const [, outerTwo] = triggers(outer)
  const [innerOne, innerTwo] = triggers(inner)

  innerOne.click()
  assert.deepEqual(openStates(inner), ["true", "false"])
  assert.deepEqual(openStates(outer), ["false", "false"])

  innerTwo.focus()
  innerTwo.dispatchEvent(new FakeEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, innerOne)

  outerTwo.click()
  assert.deepEqual(openStates(outer), ["false", "true"])
  assert.deepEqual(openStates(inner), ["true", "false"])
  assert.equal(document.getElementById("outer-one-panel").hidden, true)

  innerHook.destroyed()
  outerHook.destroyed()
})

test("generated root/item id changes restore state and focus by owned item position", () => {
  const document = testDocument()
  const root = accordion(document, "accordion-1", [
    item(document, "accordion-item-2"),
    item(document, "accordion-item-3"),
  ])
  const { hook } = setup(root)
  const [, second] = triggers(root)

  second.click()
  second.focus()
  assert.deepEqual(openStates(root), ["false", "true"])
  hook.beforeUpdate()

  root.id = "accordion-20"
  root.replaceChildren(
    item(document, "accordion-item-21", { expanded: true }),
    item(document, "accordion-item-22")
  )
  hook.updated()

  const [newFirst, newSecond] = triggers(root)
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(document.getElementById("accordion-item-21-panel").hidden, true)
  assert.equal(document.getElementById("accordion-item-22-panel").hidden, false)
  assert.equal(document.activeElement, newSecond)
  assert.equal(newFirst.getAttribute("aria-controls"), "accordion-item-21-panel")
})

test("disconnect/reconnect survives regenerated ids and restores focused header", () => {
  const document = testDocument()
  const root = accordion(document, "accordion-30", [
    item(document, "accordion-item-31"),
    item(document, "accordion-item-32"),
  ])
  const { hook } = setup(root)
  const [, second] = triggers(root)
  second.click()
  second.focus()
  hook.disconnected()

  root.id = "accordion-40"
  root.replaceChildren(
    item(document, "accordion-item-41", { expanded: true }),
    item(document, "accordion-item-42")
  )
  document.body.focus()

  hook.reconnected()
  const [, secondAfterServer] = triggers(root)
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(document.activeElement, secondAfterServer)
})
