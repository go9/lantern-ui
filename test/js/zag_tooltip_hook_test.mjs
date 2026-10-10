// Behavioural tests for the Zag-driven tooltip (`assets/js/zag/tooltip.js`).
//
// Fixtures mirror the `tooltip` HEEx output: `data-zag` root, Zag anatomy
// (`data-scope="tooltip"` + `data-part`), `lui-*` styling untouched.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagTooltip } = await import("../../assets/js/zag/tooltip.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({ id = "tip1", mode = "client", open = false, extraRoot = "" } = {}) {
  const binding =
    mode === "controlled"
      ? `data-controlled data-value="${open}"`
      : `data-default-value="${open}"`
  return `
  <span id="${id}" data-zag ${binding}
    data-placement="top" data-delay="0" ${extraRoot}>
    <span data-scope="tooltip" data-part="trigger" tabindex="0"><button>Hover me</button></span>
    <span data-scope="tooltip" data-part="positioner">
      <span data-scope="tooltip" data-part="content" class="lui-tooltip" role="tooltip" hidden>Tip text<span data-scope="tooltip" data-part="arrow" class="lui-tooltip-arrow"></span></span>
    </span>
  </span>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagTooltip, html, {
    rootId: "tip1",
    componentKey: "__lanternTooltip",
    clientEvent: "tip-toggled",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const content = (el) => el.querySelector('[data-part="content"]')
// Zag opens on pointermove/pointerover (never pointerenter) and closes on
// pointerleave — see tooltip.connect.mjs.
const openTooltip = (el) => {
  el.querySelector('[data-part="trigger"]').dispatchEvent(
    new el.ownerDocument.defaultView.Event("pointerover", { bubbles: true })
  )
}
const closeTooltip = (el) => {
  el.querySelector('[data-part="trigger"]').dispatchEvent(
    new el.ownerDocument.defaultView.Event("pointerleave", { bubbles: true })
  )
}

test("client mode: hover opens the tip, leaving closes it", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)

  openTooltip(el)
  await waitFor(() => component().api.open === true)
  assert.equal(content(el).hidden, false)

  closeTooltip(el)
  await waitFor(() => component().api.open === false)
  assert.equal(content(el).hidden, true)
})

test("client mode: open change pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents, component } = mount(
    fixture({ extraRoot: `data-on-change="tip_changed" data-on-change-client="tip-toggled"` })
  )
  await sleep()

  openTooltip(el)
  await waitFor(() => component().api.open === true)

  assert.deepEqual(pushEvent, [{ event: "tip_changed", payload: { id: "tip1", open: true } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "tip1", open: true })
})

test("client mode: an unrelated server patch does not reset open state", async () => {
  const ctx = mount(fixture())
  const { el, component } = ctx
  await sleep()

  openTooltip(el)
  await waitFor(() => component().api.open === true)
  assert.equal(content(el).hidden, false)

  // A patch that re-renders chrome (delay) while open: the machine wins.
  ctx.patch((root) => root.setAttribute("data-delay", "500"))
  await sleep()

  assert.equal(component().api.open, true)
  assert.equal(content(el).hidden, false)
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(fixture({ mode: "controlled", open: true }))
  const { el, component } = ctx
  await sleep(50)

  assert.equal(component().api.open, true)

  // Server closes: patch flows into the machine.
  ctx.patch((root) => root.setAttribute("data-value", "false"))
  await sleep()
  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)
})

test("controlled mode: a client open that matches the server value does not re-notify", async () => {
  const { el, pushEvent } = mount(
    fixture({ mode: "controlled", open: true, extraRoot: `data-on-change="tip_changed"` })
  )
  await sleep(50)

  // Already open per the server; hovering is an echo, not a change.
  closeTooltip(el)
  await sleep()
  openTooltip(el)
  await sleep()

  const opens = pushEvent.filter((p) => p.payload.open === true)
  assert.equal(opens.length, 0)
})

test("server and DOM set-open events drive the machine", async () => {
  const { el, component, serverPush } = mount(fixture())
  await sleep()

  serverPush("lantern:tooltip:set-open", { id: "tip1", open: true })
  await sleep()
  assert.equal(component().api.open, true)

  el.dispatchEvent(
    new el.ownerDocument.defaultView.CustomEvent("lantern:tooltip:set-open", {
      bubbles: true,
      detail: { open: false },
    })
  )
  await sleep()
  assert.equal(component().api.open, false)

  // Wrong id: ignored.
  serverPush("lantern:tooltip:set-open", { id: "other", open: true })
  await sleep()
  assert.equal(component().api.open, false)
})
