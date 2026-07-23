import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

const source = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")
const hooks = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`)
const definition = hooks.LanternAutocomplete

function hook({ query = "ab", threshold = "2", event = "search", disabled = false } = {}) {
  const instance = Object.create(definition)
  instance.input = { value: query, disabled }
  instance.el = { dataset: { searchThreshold: threshold, serverSearch: event, debounce: "5", searchMode: "contains" } }
  instance.loadingStates = []
  instance.events = []
  instance.setLoading = (value) => instance.loadingStates.push(value)
  instance.updateResults = () => (instance.updatedResults = true)
  instance.pushEvent = (name, payload) => instance.events.push([name, payload])
  return instance
}

const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds))

test("server search debounces one event with the public query payload", async () => {
  const instance = hook()
  instance.search()
  assert.deepEqual(instance.events, [])
  assert.deepEqual(instance.loadingStates, [true])
  await wait(15)
  assert.deepEqual(instance.events, [["search", { query: "ab" }]])
})

test("below-threshold and disabled inputs push no server event", async () => {
  const below = hook({ query: "a", threshold: "2" })
  below.search()
  const disabled = hook({ disabled: true })
  disabled.search()
  await wait(15)
  assert.deepEqual(below.events, [])
  assert.equal(below.updatedResults, true)
  assert.deepEqual(disabled.events, [])
})

test("all three static search modes have distinct matching behavior", () => {
  const instance = hook({ event: "" })
  instance.el.dataset.searchMode = "contains"
  assert.equal(instance.matches("Alpha Beta", "beta"), true)
  instance.el.dataset.searchMode = "starts-with"
  assert.equal(instance.matches("Alpha Beta", "beta"), false)
  assert.equal(instance.matches("Alpha Beta", "alpha"), true)
  instance.el.dataset.searchMode = "exact"
  assert.equal(instance.matches("Alpha Beta", "alpha"), false)
  assert.equal(instance.matches("Alpha Beta", "alpha beta"), true)
})

test("active option is exposed on the focused combobox without moving DOM focus", () => {
  const attrs = new Map()
  const input = {
    setAttribute: (key, value) => attrs.set(key, value),
    removeAttribute: (key) => attrs.delete(key),
  }
  const options = [
    { id: "ac-option-0", toggleAttribute() {}, scrollIntoView() {} },
    { id: "ac-option-1", toggleAttribute() {}, scrollIntoView() {} },
  ]
  const instance = Object.create(definition)
  instance.input = input
  instance.options = () => options
  instance.setActive(1)
  assert.equal(attrs.get("aria-activedescendant"), "ac-option-1")
  instance.setActive(-1)
  assert.equal(attrs.has("aria-activedescendant"), false)
})
