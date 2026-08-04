import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { afterEach, test } from "node:test"

const source = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")
const module = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)
const { LanternMessageScroller } = module

class Element {
  constructor(document, tag = "div") {
    this.ownerDocument = document
    this.tagName = tag.toUpperCase()
    this.nodeType = 1
    this.children = []
    this.parentElement = null
    this.attributes = new Map()
    this.dataset = {}
    this.listeners = new Map()
    this.scrollTop = 0
    this.scrollHeight = 0
    this.clientHeight = 100
    this.offsetTop = 0
  }

  append(...children) {
    for (const child of children) {
      child.parentElement = this
      this.children.push(child)
    }
  }

  setAttribute(name, value) {
    const stringValue = String(value)
    this.attributes.set(name, stringValue)
    if (name.startsWith("data-")) {
      const key = name.slice(5).replace(/-([a-z])/g, (_m, c) => c.toUpperCase())
      this.dataset[key] = stringValue
    }
  }

  getAttribute(name) { return this.attributes.get(name) ?? null }
  hasAttribute(name) { return this.attributes.has(name) }
  removeAttribute(name) { this.attributes.delete(name) }

  matches(selector) {
    const match = /^\[([^=]+)="([^"]+)"\]$/.exec(selector)
    return Boolean(match && this.getAttribute(match[1]) === match[2])
  }

  closest(selector) {
    let current = this
    while (current) {
      if (current.matches(selector)) return current
      current = current.parentElement
    }
    return null
  }

  querySelectorAll(selector) {
    const found = []
    const visit = (element) => {
      for (const child of element.children) {
        if (child.matches(selector)) found.push(child)
        visit(child)
      }
    }
    visit(this)
    return found
  }

  querySelector(selector) { return this.querySelectorAll(selector)[0] ?? null }

  addEventListener(type, listener) {
    this.listeners.set(type, [...(this.listeners.get(type) ?? []), listener])
  }

  removeEventListener(type, listener) {
    this.listeners.set(type, (this.listeners.get(type) ?? []).filter((item) => item !== listener))
  }

  dispatchEvent(event) {
    if (!event.target) event.target = this
    let current = this
    do {
      event.currentTarget = current
      for (const listener of [...(current.listeners.get(event.type) ?? [])]) listener(event)
      current = event.bubbles ? current.parentElement : null
    } while (current)
  }

  click() { this.dispatchEvent({ type: "click", bubbles: true, target: null }) }
}

class Document {
  constructor() { this.body = new Element(this, "body") }
  createElement(tag) { return new Element(this, tag) }
}

let observerCallback
class Observer {
  constructor(callback) { observerCallback = callback }
  observe() {}
  disconnect() {}
}

function setup({ follow = true, peek = 40 } = {}) {
  const document = new Document()
  const root = new Element(document)
  root.setAttribute("phx-hook", "LanternMessageScroller")
  root.setAttribute("data-follow", String(follow))
  root.setAttribute("data-peek", String(peek))
  const viewport = new Element(document)
  viewport.setAttribute("data-part", "viewport")
  const content = new Element(document)
  content.setAttribute("data-part", "content")
  const button = new Element(document, "button")
  button.setAttribute("data-part", "jump-latest")
  root.append(viewport, button)
  viewport.append(content)
  globalThis.document = document
  globalThis.window = { addEventListener() {}, removeEventListener() {} }
  globalThis.MutationObserver = Observer
  globalThis.requestAnimationFrame = (callback) => callback()
  const hook = Object.create(LanternMessageScroller)
  hook.el = root
  hook.mounted()
  return { hook, root, viewport, content, button, document }
}

afterEach(() => {
  delete globalThis.document
  delete globalThis.window
  delete globalThis.MutationObserver
  delete globalThis.requestAnimationFrame
  observerCallback = null
})

test("follow mode scrolls to the bottom on mount", () => {
  const { viewport } = setup()
  viewport.scrollHeight = 800
  // The mount callback runs immediately in this harness; changing dimensions
  // and invoking the observer models the first server-rendered content batch.
  observerCallback([{ addedNodes: [] }])
  assert.equal(viewport.scrollTop, 800)
})

test("content growth while following stays pinned to the bottom", () => {
  const { hook, viewport, content } = setup()
  viewport.scrollHeight = 500
  hook.scrollToBottom()
  viewport.scrollHeight = 900
  observerCallback([{ addedNodes: [content.ownerDocument.createElement("div")] }])
  assert.equal(viewport.scrollTop, 900)
})

test("scrolling away disables following and marks the jump button active", () => {
  const { hook, viewport, button, root } = setup()
  viewport.scrollHeight = 900
  hook.scrollToBottom()
  viewport.scrollTop = 200
  viewport.dispatchEvent({ type: "scroll", bubbles: false, target: null })
  assert.equal(root.dataset.scrollable, "true")
  assert.equal(hook.following, false)
  assert.equal(button.dataset.active, "true")
})

test("jump button re-follows and scrolls to the bottom", () => {
  const { hook, viewport, button } = setup({ follow: false })
  viewport.scrollHeight = 700
  button.click()
  assert.equal(hook.following, true)
  assert.equal(viewport.scrollTop, 700)
})

test("a new scroll anchor lands near the top using the peek offset", () => {
  const { hook, viewport, content, document } = setup({ peek: 60 })
  viewport.scrollHeight = 800
  hook.scrollToBottom()
  const anchor = new Element(document)
  anchor.setAttribute("data-scroll-anchor", "true")
  anchor.offsetTop = 420
  content.append(anchor)
  observerCallback([{ addedNodes: [anchor] }])
  assert.equal(viewport.scrollTop, 360)
})
