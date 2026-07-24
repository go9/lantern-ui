import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")
const hooks = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)
const definition = hooks.LanternAutocomplete

class FakeElement {
  constructor({ id = "", part = null, classes = [], value = "", label = "", text = "" } = {}) {
    this.id = id
    this.dataset = {}
    if (part) this.dataset.part = part
    if (label) this.dataset.label = label
    this.classes = new Set(classes)
    this.value = value
    this.textContent = text || label
    this.hidden = false
    this.disabled = false
    this.children = []
    this.parentElement = null
    this.attributes = new Map()
    this.listeners = new Map()
    this.events = []
    this.style = {}
    this.offsetWidth = 240
  }

  append(...children) {
    for (const child of children) {
      if (child.parentElement) child.parentElement.children = child.parentElement.children.filter((item) => item !== child)
      child.parentElement = this
      this.children.push(child)
    }
  }

  replace(oldChild, newChild) {
    const index = this.children.indexOf(oldChild)
    assert.notEqual(index, -1)
    oldChild.parentElement = null
    newChild.parentElement = this
    this.children[index] = newChild
  }

  matches(selector) {
    if (selector === "*") return true
    if (selector.startsWith(".")) return this.classes.has(selector.slice(1))
    const part = /^\[data-part="([^"]+)"\]$/.exec(selector)
    return part ? this.dataset.part === part[1] : false
  }

  closest(selector) {
    for (let node = this; node; node = node.parentElement) if (node.matches(selector)) return node
    return null
  }

  querySelectorAll(selector) {
    const found = []
    const visit = (node) => {
      for (const child of node.children) {
        if (child.matches(selector)) found.push(child)
        visit(child)
      }
    }
    visit(this)
    return found
  }

  querySelector(selector) {
    return this.querySelectorAll(selector)[0] || null
  }

  contains(target) {
    for (let node = target; node; node = node.parentElement) if (node === this) return true
    return false
  }

  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set())
    this.listeners.get(type).add(listener)
  }

  removeEventListener(type, listener) {
    this.listeners.get(type)?.delete(listener)
  }

  emit(type, target = this, extra = {}) {
    const event = {
      type,
      target,
      key: extra.key,
      defaultPrevented: false,
      propagationStopped: false,
      preventDefault() { this.defaultPrevented = true },
      stopPropagation() { this.propagationStopped = true },
    }
    for (let node = target; node; node = node.parentElement) {
      for (const listener of node.listeners.get(type) || []) listener(event)
      if (event.propagationStopped) break
    }
    return event
  }

  dispatchEvent(event) {
    this.events.push(event.type)
    this.emit(event.type, this)
    return true
  }

  setAttribute(name, value) { this.attributes.set(name, String(value)) }
  getAttribute(name) { return this.attributes.get(name) ?? null }
  removeAttribute(name) { this.attributes.delete(name) }
  hasAttribute(name) { return this.attributes.has(name) }
  toggleAttribute(name, force) {
    const enabled = force === undefined ? !this.attributes.has(name) : force
    if (enabled) this.attributes.set(name, "")
    else this.attributes.delete(name)
    return enabled
  }
  focus() { document.activeElement = this }
  scrollIntoView() {}
  getBoundingClientRect() { return { top: 20, bottom: 52, left: 20, right: 260, width: 240, height: 32 } }
}

class FakeDocument {
  constructor() {
    this.activeElement = null
    this.documentElement = { clientWidth: 1200, clientHeight: 800 }
    this.listeners = new Map()
  }
  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set())
    this.listeners.get(type).add(listener)
  }
  removeEventListener(type, listener) { this.listeners.get(type)?.delete(listener) }
  emit(type, target, extra = {}) {
    const event = { target, key: extra.key }
    for (const listener of [...(this.listeners.get(type) || [])]) listener(event)
  }
  count(type) { return this.listeners.get(type)?.size || 0 }
}

globalThis.document = new FakeDocument()

function option(id, label, value, selected = false) {
  const element = new FakeElement({ id, part: "option", label, text: label })
  element.dataset.value = value
  element.dataset.depth = "0"
  element.setAttribute("aria-selected", String(selected))
  return element
}

function chrome({ inputValue = "", hiddenValue = "", options = [], emptyTemplate = "No results for %{query}" } = {}) {
  const control = new FakeElement({ classes: ["lui-autocomplete-control"] })
  const input = new FakeElement({ id: "search", part: "input", value: inputValue })
  input.setAttribute("aria-expanded", "false")
  const clear = new FakeElement({ part: "clear" })
  control.append(input, clear)

  const hidden = new FakeElement({ part: "value", value: hiddenValue })
  const panel = new FakeElement({ id: "search-listbox", part: "panel" })
  panel.hidden = true
  const results = new FakeElement({ part: "options" })
  results.append(...options)
  const loading = new FakeElement({ part: "loading" })
  loading.hidden = true
  const noResults = new FakeElement({ part: "no-results", text: "No results" })
  noResults.dataset.defaultText = "true"
  noResults.hidden = true
  panel.append(results, loading, noResults)
  return { control, input, clear, hidden, panel, results, loading, noResults, emptyTemplate }
}

function fixture({ server = false, debounce = 8, threshold = 0, inputValue = "", hiddenValue = "", options = [] } = {}) {
  document.activeElement = null
  document.listeners.clear()
  const root = new FakeElement({ id: "search-ac" })
  root.dataset.searchThreshold = String(threshold)
  root.dataset.searchMode = "contains"
  root.dataset.openOnFocus = "false"
  root.dataset.debounce = String(debounce)
  root.dataset.emptyTemplate = "No results for %{query}"
  if (server) root.dataset.serverSearch = "search"
  const parts = chrome({ inputValue, hiddenValue, options })
  root.append(parts.hidden, parts.control, parts.panel)
  const pushed = []
  const replies = []
  const hook = Object.assign(Object.create(definition), {
    el: root,
    pushEvent: (name, payload, callback) => {
      pushed.push([name, payload])
      replies.push(callback)
    },
  })
  hook.mounted()
  return { hook, root, pushed, replies, ...parts }
}

function patchChrome(state) {
  const next = chrome({
    inputValue: "server-rendered",
    hiddenValue: state.hook.hidden.value,
    options: [],
  })
  // Simulate an unrelated morph: control/panel/loading are replaced, while the
  // result and empty-state nodes are retained and moved under the new panel.
  next.panel.children = []
  next.panel.append(state.results, next.loading, state.noResults)
  state.root.replace(state.hook.hidden, next.hidden)
  state.root.replace(state.control, next.control)
  state.root.replace(state.panel, next.panel)
  Object.assign(state, next, { results: state.results, noResults: state.noResults })
}

function patchResults(state, options) {
  const nextResults = new FakeElement({ part: "options" })
  nextResults.append(...options)
  const nextEmpty = new FakeElement({ part: "no-results", text: "No results" })
  nextEmpty.dataset.defaultText = "true"
  nextEmpty.hidden = true
  state.panel.replace(state.results, nextResults)
  state.panel.replace(state.noResults, nextEmpty)
  state.results = nextResults
  state.noResults = nextEmpty
}

const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))

test("mounted lifecycle debounces search and ignores unrelated DOM patches", async () => {
  const state = fixture({ server: true, debounce: 12, threshold: 2, inputValue: "ab" })
  state.input.focus()
  state.root.emit("input", state.input)

  assert.equal(state.hook.open, true)
  assert.equal(state.panel.hidden, false)
  assert.equal(state.input.getAttribute("aria-expanded"), "true")
  assert.equal(state.loading.hidden, false)
  assert.equal(document.count("pointerdown"), 1)

  state.hook.beforeUpdate()
  assert.equal(document.count("pointerdown"), 0)
  patchChrome(state)
  state.hook.updated()

  assert.equal(state.hook.pendingSearch.query, "ab")
  assert.equal(state.hook.loading, true)
  assert.equal(state.loading.hidden, false)
  assert.equal(state.input.value, "ab")
  assert.equal(document.activeElement, state.input)
  assert.equal(document.count("pointerdown"), 1)

  await wait(25)
  assert.deepEqual(state.pushed, [["search", { query: "ab" }]])
  assert.equal(state.hook.loading, true)

  const outside = new FakeElement()
  document.emit("pointerdown", outside)
  assert.equal(state.hook.open, false)
  assert.equal(state.panel.hidden, true)
  assert.equal(state.input.getAttribute("aria-expanded"), "false")
})

test("result patch completes only its pending search and renders no-results", async () => {
  const state = fixture({ server: true, debounce: 2, threshold: 1 })
  state.input.value = "zz"
  state.input.focus()
  state.root.emit("input", state.input)
  await wait(10)
  assert.equal(state.hook.inFlightSearches.length, 1)

  state.hook.beforeUpdate()
  patchResults(state, [])
  state.hook.updated()

  assert.equal(state.hook.pendingSearch.query, "zz")
  assert.equal(state.hook.inFlightSearches[0].resultsPatched, true)
  assert.equal(state.hook.loading, true)
  state.replies[0]()
  await wait(5)

  assert.equal(state.hook.pendingSearch, null)
  assert.equal(state.hook.loading, false)
  assert.equal(state.loading.hidden, true)
  assert.equal(state.noResults.hidden, false)
  assert.equal(state.noResults.textContent, "No results for zz")
  assert.equal(state.input.value, "zz")
  assert.equal(document.activeElement, state.input)
})

test("older result patch cannot clear a newer pending query", async () => {
  const state = fixture({ server: true, debounce: 2, threshold: 1 })
  state.input.value = "old"
  state.root.emit("input", state.input)
  await wait(8)
  state.input.value = "new"
  state.root.emit("input", state.input)

  state.hook.beforeUpdate()
  patchResults(state, [option("new-0", "Old result", "old")])
  state.hook.updated()

  assert.equal(state.hook.pendingSearch.query, "new")
  assert.equal(state.hook.loading, true)
  assert.equal(state.input.value, "new")
  state.replies[0]()
  await wait(8)
  assert.equal(state.hook.pendingSearch.query, "new")
  assert.equal(state.hook.loading, true)
  assert.deepEqual(state.pushed, [["search", { query: "old" }], ["search", { query: "new" }]])
})

test("identical result reply completes loading without a DOM signature change", async () => {
  const state = fixture({ server: true, debounce: 2, threshold: 1 })
  state.input.value = "none"
  state.root.emit("input", state.input)
  await wait(8)

  state.hook.beforeUpdate()
  state.hook.updated()
  assert.equal(state.hook.loading, true)
  state.replies[0]()
  await wait(5)

  assert.equal(state.hook.loading, false)
  assert.equal(state.hook.pendingSearch, null)
  assert.equal(state.noResults.hidden, false)
})

test("keyboard select, Escape, active descendant, and clear emit form events", () => {
  const ada = option("search-option-0", "Ada", "1")
  const grace = option("search-option-1", "Grace", "2")
  const state = fixture({ options: [ada, grace] })
  state.input.focus()
  state.input.value = "a"
  state.root.emit("input", state.input)

  state.root.emit("keydown", state.input, { key: "ArrowDown" })
  assert.equal(state.input.getAttribute("aria-activedescendant"), "search-option-0")
  state.root.emit("keydown", state.input, { key: "Enter" })
  assert.equal(state.hidden.value, "1")
  assert.deepEqual(state.hidden.events, ["input", "change"])
  assert.equal(state.input.value, "Ada")
  assert.equal(state.input.getAttribute("aria-expanded"), "false")

  state.hook.show()
  state.input.value = "dangling"
  state.root.emit("keydown", state.input, { key: "Escape" })
  assert.equal(state.input.value, "Ada")
  assert.equal(state.input.hasAttribute("aria-activedescendant"), false)

  state.root.emit("click", state.clear)
  assert.equal(state.hidden.value, "")
  assert.deepEqual(state.hidden.events, ["input", "change", "input", "change"])
  assert.equal(state.input.value, "")
  assert.equal(state.clear.hidden, true)
})

test("removed selected option retains its label across patch and dismissal", () => {
  const selected = option("search-option-0", "Ada", "1", true)
  const state = fixture({ hiddenValue: "1", inputValue: "Ada", options: [selected] })
  state.hook.show()
  state.input.focus()
  state.hook.beforeUpdate()
  patchResults(state, [option("search-option-1", "Grace", "2")])
  state.hook.updated()

  assert.equal(state.hidden.value, "1")
  state.input.value = "other"
  document.emit("pointerdown", new FakeElement())
  assert.equal(state.input.value, "Ada")
  assert.equal(state.panel.hidden, true)
})
