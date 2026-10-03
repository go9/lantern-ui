// Behavioural tests for the Zag-driven switch (`assets/js/zag/switch.js`).
//
// Fixtures mirror the `switch` HEEx output: `data-zag` root, Zag anatomy
// (`data-scope="switch"` + `data-part`), and the native form contract —
// the always-present hidden input submits `unchecked_value` when off, the
// named checkbox submits `checked_value` when on.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep } from "./helpers/zag_mount.mjs"

const { LanternZagSwitch } = await import("../../assets/js/zag/switch.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({
  hookId = "s1-switch",
  inputId = "s1",
  name = "notify",
  mode = "client",
  checked = true,
  extraRoot = "",
} = {}) {
  const binding =
    mode === "controlled" ? `data-controlled data-value="${checked}"` : `data-default-value="${checked}"`
  return `
  <div id="${hookId}" data-zag ${binding}
    data-input-id="${inputId}" ${extraRoot}>
    <div class="lui-switch-row">
      <label class="lui-switch" data-scope="switch" data-part="root" data-size="md" data-color="accent">
        <input type="hidden" name="${name}" value="false" />
        <input type="checkbox" id="${inputId}" name="${name}" value="true"${
          checked ? " checked" : ""
        } class="lui-switch-input" />
        <span class="lui-switch-track" data-scope="switch" data-part="control" aria-hidden="true">
          <span class="lui-switch-thumb" data-scope="switch" data-part="thumb"></span>
        </span>
      </label>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagSwitch, html, {
    rootId: "s1-switch",
    componentKey: "__lanternSwitch",
    clientEvent: "switch-toggled",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const checkbox = (el) => el.querySelector('input[type="checkbox"][name]')
const hiddenInput = (el) => el.querySelector('input[type="hidden"][name]')

test("client mode: clicking the checkbox toggles machine and native state together", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.checked, true)

  const changes = []
  checkbox(el).addEventListener("change", () => changes.push(checkbox(el).checked))

  checkbox(el).click()
  await sleep()

  assert.equal(component().api.checked, false)
  assert.equal(checkbox(el).checked, false)
  // The browser's own change fires once; the machine sync finds nothing to
  // do and dispatches no second change.
  assert.deepEqual(changes, [false])

  checkbox(el).click()
  await sleep()
  assert.equal(component().api.checked, true)
})

test("native form contract: the hidden unchecked input always submits, the checkbox only when on", async () => {
  const { el } = mount(fixture())
  await sleep()

  assert.equal(hiddenInput(el).value, "false")
  assert.equal(hiddenInput(el).type, "hidden")

  checkbox(el).click()
  await sleep()

  // Off: the checkbox contributes nothing, the hidden input still does.
  assert.equal(checkbox(el).checked, false)
  assert.equal(hiddenInput(el).value, "false")
  assert.equal(hiddenInput(el).disabled, false)
})

test("client mode: toggle pushes a server event and dispatches a client event, exactly once", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="notify_changed" data-on-change-client="switch-toggled"` })
  )
  await sleep()

  checkbox(el).click()
  await sleep()

  assert.deepEqual(pushEvent, [
    { event: "notify_changed", payload: { id: "s1-switch", checked: false, value: false } },
  ])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "s1-switch", checked: false, value: false })
})

test("client mode: an unrelated server patch does not reset the toggle", async () => {
  const ctx = mount(fixture())
  const { el, component } = ctx
  await sleep()

  checkbox(el).click()
  await sleep()
  assert.equal(component().api.checked, false)

  // A validation-error patch while the server copy is stale: machine wins.
  ctx.patch((root) => root.setAttribute("data-invalid", "true"))
  await sleep()

  assert.equal(component().api.checked, false)
  assert.equal(checkbox(el).checked, false)
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(
    fixture({ mode: "controlled", checked: true, extraRoot: `data-on-change="notify_changed"` })
  )
  const { el, component, pushEvent } = ctx
  await sleep(50)

  assert.equal(component().api.checked, true)

  ctx.patch((root) => root.setAttribute("data-value", "false"))
  await sleep()

  assert.equal(component().api.checked, false)
  assert.equal(checkbox(el).checked, false)
  // The patch echo must not re-notify.
  assert.deepEqual(pushEvent, [])
})

test("server and DOM set-checked events drive the machine and the native input", async () => {
  const { el, component, serverPush } = mount(fixture({ checked: false }))
  await sleep()

  const changes = []
  checkbox(el).addEventListener("change", () => changes.push(checkbox(el).checked))

  serverPush("lantern:switch:set-checked", { id: "s1-switch", checked: true })
  await sleep()
  assert.equal(component().api.checked, true)
  assert.equal(checkbox(el).checked, true)
  assert.deepEqual(changes, [true])

  el.dispatchEvent(
    new el.ownerDocument.defaultView.CustomEvent("lantern:switch:set-checked", {
      bubbles: true,
      detail: { checked: false },
    })
  )
  await sleep()
  assert.equal(component().api.checked, false)

  serverPush("lantern:switch:set-checked", { id: "other", checked: true })
  await sleep()
  assert.equal(component().api.checked, false)
})
