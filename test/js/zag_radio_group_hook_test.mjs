// Behavioural tests for the Zag-driven radio group
// (`assets/js/zag/radio_group.js`).
//
// Fixtures mirror the `radio` HEEx output: `data-zag` fieldset root, Zag
// anatomy (`data-scope="radio-group"` + `data-part`), and one native radio
// input per option sharing the group name (the form surface).

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep } from "./helpers/zag_mount.mjs"

const { LanternZagRadioGroup } = await import("../../assets/js/zag/radio_group.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({
  id = "plan",
  name = "plan",
  mode = "client",
  value = "pro",
  extraRoot = "",
} = {}) {
  const binding =
    mode === "controlled" ? `data-controlled data-value="${value}"` : `data-default-value="${value}"`
  const option = (v, label, index) => `
      <label class="lui-radio" data-scope="radio-group" data-part="item" data-value="${v}">
        <input type="radio" id="${id}-${index}" name="${name}" value="${v}"${
          v === value ? " checked" : ""
        } class="lui-radio-input" />
        <span class="lui-radio-dot" data-scope="radio-group" data-part="item-control" aria-hidden="true"></span>
        <span class="lui-radio-texts"><span class="lui-radio-label">${label}</span></span>
      </label>`
  return `
  <fieldset id="${id}" data-zag ${binding}
    data-scope="radio-group" data-part="root" data-name="${name}" ${extraRoot}>
    <legend class="lui-radio-legend">Plan</legend>
    ${option("basic", "Basic", 0)}
    ${option("pro", "Pro", 1)}
  </fieldset>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagRadioGroup, html, {
    rootId: "plan",
    componentKey: "__lanternRadioGroup",
    clientEvent: "plan-picked",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const checkedValue = (el) => el.querySelector('input[type="radio"][name]:checked')?.value

test("client mode: picking an option updates the machine and the native inputs", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.value, "pro")

  const changes = []
  el.addEventListener("change", (e) => changes.push(e.target.value))

  el.querySelector('input[value="basic"]').click()
  await sleep()

  assert.equal(component().api.value, "basic")
  assert.equal(checkedValue(el), "basic")
  // The browser's own change fires once; the machine sync dispatches no second.
  assert.deepEqual(changes, ["basic"])
})

test("client mode: the item label points at the real native input", async () => {
  const { el } = mount(fixture())
  await sleep()

  // Zag spreads `for` onto each item label; it must resolve to the wrapped
  // native input or label-text clicks stop toggling in a real browser.
  for (const item of el.querySelectorAll('[data-part="item"]')) {
    const htmlFor = item.getAttribute("for")
    const input = item.querySelector('input[type="radio"][name]')
    assert.ok(htmlFor, "item label has a for attribute")
    assert.equal(htmlFor, input.id)
    assert.equal(el.ownerDocument.getElementById(htmlFor), input)
  }
})

test("client mode: pick pushes a server event and dispatches a client event, exactly once", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="plan_changed" data-on-change-client="plan-picked"` })
  )
  await sleep()

  el.querySelector('input[value="basic"]').click()
  await sleep()

  assert.deepEqual(pushEvent, [{ event: "plan_changed", payload: { id: "plan", value: "basic" } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "plan", value: "basic" })
})

test("client mode: an unrelated server patch does not reset the pick", async () => {
  const ctx = mount(fixture())
  const { el, component } = ctx
  await sleep()

  el.querySelector('input[value="basic"]').click()
  await sleep()
  assert.equal(component().api.value, "basic")

  // A validation-error patch while the server copy is stale: machine wins.
  ctx.patch((root) => root.setAttribute("data-invalid", "true"))
  await sleep()

  assert.equal(component().api.value, "basic")
  assert.equal(checkedValue(el), "basic")
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(
    fixture({ mode: "controlled", value: "pro", extraRoot: `data-on-change="plan_changed"` })
  )
  const { el, component, pushEvent } = ctx
  await sleep(50)

  assert.equal(component().api.value, "pro")

  ctx.patch((root) => root.setAttribute("data-value", "basic"))
  await sleep()

  assert.equal(component().api.value, "basic")
  assert.equal(checkedValue(el), "basic")
  // The patch echo must not re-notify.
  assert.deepEqual(pushEvent, [])
})

test("server and DOM set-value events drive the machine and the native inputs", async () => {
  const { el, component, serverPush } = mount(fixture({ value: "basic" }))
  await sleep()

  const changes = []
  el.addEventListener("change", (e) => changes.push(e.target.value))

  serverPush("lantern:radio:set-value", { id: "plan", value: "pro" })
  await sleep()
  assert.equal(component().api.value, "pro")
  assert.equal(checkedValue(el), "pro")
  assert.deepEqual(changes, ["pro"])

  el.dispatchEvent(
    new el.ownerDocument.defaultView.CustomEvent("lantern:radio:set-value", {
      bubbles: true,
      detail: { value: "basic" },
    })
  )
  await sleep()
  assert.equal(component().api.value, "basic")

  serverPush("lantern:radio:set-value", { id: "other", value: "pro" })
  await sleep()
  assert.equal(component().api.value, "basic")
})
