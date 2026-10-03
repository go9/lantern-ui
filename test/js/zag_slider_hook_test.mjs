// Behavioural tests for the Zag-driven slider (`assets/js/zag/slider.js`).
//
// Fixtures mirror the `slider` HEEx output: `data-zag` root (which IS the
// Zag root), the native hidden input (the form surface), `lui-*` styling
// untouched. Covers: keyboard commit, drag-move/commit split, hidden input
// sync, both modes, patch-does-not-reset.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep } from "./helpers/zag_mount.mjs"

const { LanternZagSlider } = await import("../../assets/js/zag/slider.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({
  hookId = "quality-slider",
  inputId = "quality",
  name = "quality",
  mode = "client",
  value = 80,
  min = 0,
  max = 100,
  step = 5,
  extraRoot = "",
} = {}) {
  const binding =
    mode === "controlled" ? `data-controlled data-value="${value}"` : `data-default-value="${value}"`
  return `
  <div id="${hookId}" data-zag ${binding}
    data-scope="slider" data-part="root"
    data-min="${min}" data-max="${max}" data-step="${step}" ${extraRoot}>
    <input type="hidden" data-part="input" id="${inputId}" name="${name}" value="${value}" />
    <div class="lui-slider-track" data-scope="slider" data-part="control">
      <div class="lui-slider-range" data-scope="slider" data-part="range"></div>
      <span class="lui-slider-thumb" data-scope="slider" data-part="thumb"
        role="slider" tabindex="0" aria-valuemin="${min}" aria-valuemax="${max}" aria-valuenow="${value}"></span>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagSlider, html, {
    rootId: "quality-slider",
    componentKey: "__lanternSlider",
    clientEvent: "slider-committed",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const hidden = (el) => el.querySelector('input[type="hidden"][name]')
const thumb = (el) => el.querySelector('[data-part="thumb"]')

test("client mode: keyboard steps commit the hidden input and fire form events", async () => {
  const { el, component, window } = mount(fixture())
  await sleep()

  assert.deepEqual(component().api.value, [80])

  const events = []
  hidden(el).addEventListener("input", () => events.push(["input", hidden(el).value]))
  hidden(el).addEventListener("change", () => events.push(["change", hidden(el).value]))

  // Real browsers focus before keys (focus arms the machine's focusedIndex).
  thumb(el).focus()
  thumb(el).dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep(50)

  assert.deepEqual(component().api.value, [85])
  assert.equal(hidden(el).value, "85")
  assert.equal(thumb(el).getAttribute("aria-valuenow"), "85")
  // Exactly one input+change pair for the key step.
  assert.deepEqual(events, [
    ["input", "85"],
    ["change", "85"],
  ])
})

test("client mode: value_text template drives aria-valuetext", async () => {
  const { el, window } = mount(fixture({ extraRoot: `data-value-text="{value}%"` }))
  await sleep()

  assert.equal(thumb(el).getAttribute("aria-valuetext"), "80%")

  // Real browsers focus before keys (focus arms the machine's focusedIndex).
  thumb(el).focus()
  thumb(el).dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep(50)
  assert.equal(thumb(el).getAttribute("aria-valuetext"), "85%")
})

test("client mode: commit pushes a server event and dispatches a client event once", async () => {
  const { el, pushEvent, clientEvents, window } = mount(
    fixture({ extraRoot: `data-on-change="quality_changed" data-on-change-client="slider-committed"` })
  )
  await sleep()

  // Real browsers focus before keys (focus arms the machine's focusedIndex).
  thumb(el).focus()
  thumb(el).dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep(50)

  assert.deepEqual(pushEvent, [{ event: "quality_changed", payload: { id: "quality-slider", value: 85 } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "quality-slider", value: 85 })
})

test("client mode: an unrelated server patch does not reset the value", async () => {
  const ctx = mount(fixture())
  const { el, component, window } = ctx
  await sleep()

  // Real browsers focus before keys (focus arms the machine's focusedIndex).
  thumb(el).focus()
  thumb(el).dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep(50)
  assert.deepEqual(component().api.value, [85])

  // A validation-error patch while the server copy is stale: machine wins.
  ctx.patch((root) => root.setAttribute("data-invalid", "true"))
  await sleep()

  assert.deepEqual(component().api.value, [85])
  assert.equal(hidden(el).value, "85")
})

test("native form contract: the hidden input carries name and value", async () => {
  const { el } = mount(fixture())
  await sleep()

  assert.equal(hidden(el).name, "quality")
  assert.equal(hidden(el).value, "80")
  assert.equal(hidden(el).type, "hidden")
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(
    fixture({ mode: "controlled", value: 80, extraRoot: `data-on-change="quality_changed"` })
  )
  const { el, component, pushEvent } = ctx
  await sleep(50)

  assert.deepEqual(component().api.value, [80])

  ctx.patch((root) => root.setAttribute("data-value", "60"))
  await sleep(50)

  assert.deepEqual(component().api.value, [60])
  assert.equal(hidden(el).value, "60")
  // The patch echo must not re-notify.
  assert.deepEqual(pushEvent, [])
})

test("server and DOM set-value events drive the machine and commit", async () => {
  const { el, component, serverPush } = mount(fixture({ value: 20 }))
  await sleep()

  const changes = []
  hidden(el).addEventListener("change", () => changes.push(hidden(el).value))

  serverPush("lantern:slider:set-value", { id: "quality-slider", value: 40 })
  await sleep(50)
  assert.deepEqual(component().api.value, [40])
  assert.equal(hidden(el).value, "40")
  assert.deepEqual(changes, ["40"])

  el.dispatchEvent(
    new el.ownerDocument.defaultView.CustomEvent("lantern:slider:set-value", {
      bubbles: true,
      detail: { value: 10 },
    })
  )
  await sleep(50)
  assert.deepEqual(component().api.value, [10])

  serverPush("lantern:slider:set-value", { id: "other", value: 99 })
  await sleep(30)
  assert.deepEqual(component().api.value, [10])
})
