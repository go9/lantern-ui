// Behavioural tests for the Zag-driven popover (`assets/js/zag/popover.js`).
//
// Fixtures mirror the `popover` HEEx output: `data-zag` root, Zag anatomy
// (`data-scope="popover"` + `data-part`), `role="dialog"` (a surface, never
// a menu), `lui-*` styling untouched.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { dismissOutside, mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagPopover } = await import("../../assets/js/zag/popover.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({ id = "pop1", mode = "client", open = false, extraRoot = "" } = {}) {
  const binding =
    mode === "controlled"
      ? `data-controlled data-value="${open}"`
      : `data-default-value="${open}"`
  return `
  <div id="${id}" data-zag ${binding}
    data-placement="bottom-start" ${extraRoot}>
    <div data-scope="popover" data-part="trigger" class="lui-popover-trigger"><button>Filters</button></div>
    <div data-scope="popover" data-part="positioner">
      <div data-scope="popover" data-part="content" class="lui-popover-panel" role="dialog" hidden>
        <div id="panel-body">Body</div>
      </div>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagPopover, html, {
    rootId: "pop1",
    componentKey: "__lanternPopover",
    clientEvent: "pop-toggled",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const content = (el) => el.querySelector('[data-part="content"]')

test("client mode: clicking the trigger toggles the panel", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)

  el.querySelector('[data-part="trigger"] button').click()
  await sleep()
  assert.equal(component().api.open, true)
  assert.equal(content(el).hidden, false)
  assert.equal(content(el).getAttribute("role"), "dialog")

  el.querySelector('[data-part="trigger"] button').click()
  await sleep()
  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)
})

test("client mode: clicking inside the panel does not close it (surface, not menu)", async () => {  const { el, component } = mount(fixture())
  await sleep()

  el.querySelector('[data-part="trigger"] button').click()
  await sleep()
  assert.equal(component().api.open, true)

  el.querySelector("#panel-body").dispatchEvent(
    new el.ownerDocument.defaultView.MouseEvent("click", { bubbles: true })
  )
  await sleep()
  assert.equal(component().api.open, true)
})

test("client mode: outside pointerdown dismisses the panel", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  el.querySelector('[data-part="trigger"] button').click()
  await waitFor(() => component().api.open === true)

  await dismissOutside(document, () => component().api.open)
  assert.equal(content(el).hidden, true)
})

test("client mode: open change pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="pop_changed" data-on-change-client="pop-toggled"` })
  )
  await sleep()

  el.querySelector('[data-part="trigger"] button').click()
  await sleep()

  assert.deepEqual(pushEvent, [{ event: "pop_changed", payload: { id: "pop1", open: true } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "pop1", open: true })
})

test("client mode: an unrelated server patch does not reset open state", async () => {
  const ctx = mount(fixture())
  const { el, component } = ctx
  await sleep()

  el.querySelector('[data-part="trigger"] button').click()
  await sleep()
  assert.equal(content(el).hidden, false)

  ctx.patch((root) => root.setAttribute("data-placement", "top-start"))
  await sleep()

  assert.equal(component().api.open, true)
  assert.equal(content(el).hidden, false)
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(fixture({ mode: "controlled", open: true }))
  const { el, component } = ctx
  await sleep(50)

  assert.equal(component().api.open, true)

  ctx.patch((root) => root.setAttribute("data-value", "false"))
  await sleep()
  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)
})

test("server and DOM set-open events drive the machine", async () => {
  const { el, component, serverPush } = mount(fixture())
  await sleep()

  serverPush("lantern:popover:set-open", { id: "pop1", open: true })
  await sleep()
  assert.equal(component().api.open, true)

  el.dispatchEvent(
    new el.ownerDocument.defaultView.CustomEvent("lantern:popover:set-open", {
      bubbles: true,
      detail: { open: false },
    })
  )
  await sleep()
  assert.equal(component().api.open, false)

  serverPush("lantern:popover:set-open", { id: "other", open: true })
  await sleep()
  assert.equal(component().api.open, false)
})
