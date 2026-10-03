// Behavioural tests for the Zag-driven accordion (`assets/js/zag/accordion.js`).
//
// Fixtures mirror the `accordion` HEEx output: `data-zag` root (which IS
// the Zag root), stable item ids, Zag anatomy, `lui-*` styling untouched.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { readFile } from "node:fs/promises"
import { mountZag, sleep } from "./helpers/zag_mount.mjs"

const { LanternZagAccordion } = await import("../../assets/js/zag/accordion.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

test("the stylesheet disables accordion transitions for reduced motion", async () => {
  const css = await readFile(new URL("../../priv/static/lantern_ui.css", import.meta.url), "utf8")
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/)
  assert.match(css, /\.lui-accordion-trigger,\s*\.lui-accordion-icon \{ transition: none; \}/)
})

function item(id, label, body, open = false) {
  return `
      <div id="${id}" class="lui-accordion-item" data-scope="accordion" data-part="item"
        data-value="${id}" data-state="${open ? "open" : "closed"}">
        <div class="lui-accordion-header" role="heading" aria-level="3">
          <button type="button" id="${id}-trigger" class="lui-accordion-trigger"
            data-scope="accordion" data-part="item-trigger"
            aria-expanded="${open}" aria-controls="${id}-panel">${label}</button>
        </div>
        <div id="${id}-panel" class="lui-accordion-panel" data-scope="accordion" data-part="item-content"
          role="region" aria-labelledby="${id}-trigger"${open ? "" : " hidden"}>${body}</div>
      </div>`
}

function fixture({ id = "faq", mode = "client", multiple = false, preventAllClosed = false, extraRoot = "", items = null } = {}) {
  // Client mode with no explicit default: the machine inherits the
  // server-rendered `expanded` flags via DOM scan (like the HEEx, which
  // omits data-default-value unless `value` is given).
  const binding = mode === "controlled" ? `data-controlled data-value='["ship"]'` : ``
  const list =
    items ??
    item("ship", "Shipping", "Worldwide.", true) + item("ret", "Returns", "Thirty days.", false)
  return `
  <div id="${id}" data-zag ${binding}
    data-scope="accordion" data-part="root"
    data-multiple="${multiple}" data-prevent-all-closed="${preventAllClosed}" data-animation-duration="300" ${extraRoot}>
    ${list}
  </div>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagAccordion, html, {
    rootId: "faq",
    componentKey: "__lanternAccordion",
    clientEvent: "accordion-toggled",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const panel = (el, id) => el.querySelector(`#${id}-panel`)

test("client mode: expanded flags are the initial value; clicking toggles", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  // The server-rendered expanded flag survives mount (no data-default-value
  // in this fixture shape → DOM scan).
  assert.deepEqual(component().api.value.map(String), ["ship"])
  assert.equal(panel(el, "ship").hidden, false)

  el.querySelector("#ret-trigger").focus()
  el.querySelector("#ret-trigger").click()
  await sleep()

  // Single mode: opening returns closes shipping.
  assert.deepEqual(component().api.value.map(String), ["ret"])
  assert.equal(panel(el, "ret").hidden, false)
  assert.equal(panel(el, "ship").hidden, true)
})

test("client mode: toggle pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="faq_changed" data-on-change-client="accordion-toggled"` })
  )
  await sleep()

  el.querySelector("#ret-trigger").focus()
  el.querySelector("#ret-trigger").click()
  await sleep()

  assert.deepEqual(pushEvent, [{ event: "faq_changed", payload: { id: "faq", value: ["ret"] } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "faq", value: ["ret"] })
})

test("client mode: an unrelated server patch does not reset open state", async () => {
  const ctx = mount(fixture())
  const { el, component } = ctx
  await sleep()

  el.querySelector("#ret-trigger").focus()
  el.querySelector("#ret-trigger").click()
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["ret"])

  ctx.patch((root) => root.setAttribute("data-animation-duration", "500"))
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["ret"])
  assert.equal(panel(el, "ret").hidden, false)
})

test("ArrowUp/ArrowDown/Home/End move focus; Enter/Space activate", async () => {
  const { el, component, window, document } = mount(
    fixture({
      items:
        item("a", "A", "a.", false) + item("b", "B", "b.", false) + item("c", "C", "c.", false),
    })
  )
  await sleep()

  const triggers = ["a", "b", "c"].map((id) => el.querySelector(`#${id}-trigger`))
  const key = (target, k) =>
    target.dispatchEvent(new window.KeyboardEvent("keydown", { key: k, bubbles: true }))

  triggers[0].focus()
  key(triggers[0], "ArrowDown")
  await sleep()
  assert.equal(document.activeElement, triggers[1])

  key(triggers[1], "ArrowDown")
  await sleep()
  assert.equal(document.activeElement, triggers[2])

  // Wrap around the ends.
  key(triggers[2], "ArrowDown")
  await sleep()
  assert.equal(document.activeElement, triggers[0])

  key(triggers[0], "Home")
  await sleep()
  assert.equal(document.activeElement, triggers[0])

  key(triggers[0], "End")
  await sleep()
  assert.equal(document.activeElement, triggers[2])

  // Enter activates the focused header (native button activation).
  triggers[2].focus()
  key(triggers[2], "Enter")
  await sleep()
  triggers[2].click()
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["c"])
})

test("prevent_all_closed keeps the last open item expanded and inoperable", async () => {
  const { el, component } = mount(
    fixture({
      multiple: true,
      preventAllClosed: true,
      items: item("a", "A", "a.", true) + item("b", "B", "b.", false),
    })
  )
  await sleep()

  // The lone open trigger is marked inoperable...
  assert.equal(el.querySelector("#a-trigger").getAttribute("aria-disabled"), "true")

  // ...and cannot be closed.
  el.querySelector("#a-trigger").focus()
  el.querySelector("#a-trigger").click()
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["a"])

  // Opening another frees it.
  el.querySelector("#b-trigger").focus()
  el.querySelector("#b-trigger").click()
  await sleep()
  assert.deepEqual(component().api.value.map(String).sort(), ["a", "b"])
  assert.equal(el.querySelector("#a-trigger").hasAttribute("aria-disabled"), false)
})

test("multiple mode keeps several items open", async () => {  const { el, component } = mount(
    fixture({
      multiple: true,
      items: item("a", "A", "a.", true) + item("b", "B", "b.", false),
    })
  )
  await sleep()

  el.querySelector("#b-trigger").focus()
  el.querySelector("#b-trigger").click()
  await sleep()

  assert.deepEqual(component().api.value.map(String).sort(), ["a", "b"])
})

test("controlled mode: the server value is truth on mount and on patch", async () => {
  const ctx = mount(fixture({ mode: "controlled", extraRoot: `data-on-change="faq_changed"` }))
  const { el, component, pushEvent } = ctx
  await sleep(50)

  assert.deepEqual(component().api.value.map(String), ["ship"])

  ctx.patch((root) => root.setAttribute("data-value", '["ret"]'))
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["ret"])
  assert.equal(panel(el, "ret").hidden, false)
  // The patch echo must not re-notify.
  assert.deepEqual(pushEvent, [])
})

test("nested accordions stay isolated", async () => {
  const { el, component } = mount(
    fixture({
      items:
        item("outer", "Outer", "outer.", true).replace(
          "outer.",
          `outer.<div id="inner" data-zag data-default-value='[]' data-scope="accordion" data-part="root" data-multiple="false" data-prevent-all-closed="false">${item(
            "in1",
            "Inner",
            "inner.",
            false
          )}</div>`
        ),
    })
  )
  await sleep()

  // Mount the inner machine against the LIVE inner root (same document).
  const innerHook = Object.create(LanternZagAccordion)
  Object.assign(innerHook, {
    el: el.querySelector("#inner"),
    pushEvent() {},
    handleEvent() {},
  })
  innerHook.mounted()
  mounts.push({ unmount: () => innerHook.destroyed?.() })
  await sleep()

  innerHook.el.querySelector("#in1-trigger").focus()
  innerHook.el.querySelector("#in1-trigger").click()
  await sleep()

  assert.deepEqual(innerHook.el.__lanternAccordion.api.value.map(String), ["in1"])
  // The outer machine never adopted the inner item.
  assert.deepEqual(component().api.value.map(String), ["outer"])
  assert.equal(panel(el, "outer").hidden, false)
})
