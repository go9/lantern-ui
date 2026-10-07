// Behavioural tests for the Zag-driven select (`assets/js/zag/select.js`).
//
// The shared `helpers/dom.mjs` harness loads the committed *bundle* through a
// data: URL, where the Zag chunk's dynamic `import()` cannot resolve — so
// these tests import the Zag source module directly (bare `@zag-js/*`
// specifiers resolve from `node_modules`) and mount `LanternZagSelect`
// against jsdom fixtures shaped like the `zag_select` HEEx path.
//
// Globals Zag needs off `globalThis` (requestAnimationFrame, Element, a
// no-op ResizeObserver for floating-ui's autoUpdate) are installed per
// mount; jsdom provides the rest.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"
import { JSDOM } from "jsdom"

const { LanternZagSelect } = await import("../../assets/js/zag/select.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({
  id = "status",
  hookId = "status-select",
  options = [
    ["Active", "active"],
    ["Archived", "archived"],
  ],
  value = ["active"],
  mode = "client",
  extraRoot = "",
} = {}) {
  const items = options.map(([label, v]) => ({ value: String(v), label }))
  const selected = new Set(value.map(String))
  const binding =
    mode === "controlled"
      ? `data-controlled data-value='${JSON.stringify(value)}'`
      : `data-default-value='${JSON.stringify(value)}'`
  const itemButtons = items
    .map(
      ({ value: v, label }) => `
      <button type="button" id="select:${hookId}:option:${v}" data-scope="select" data-part="item"
        data-value="${v}" role="option" aria-selected="${selected.has(v)}" tabindex="-1">
        <span data-scope="select" data-part="item-text">${label}</span>
        <span data-scope="select" data-part="item-indicator">✓</span>
      </button>`
    )
    .join("")
  const hiddenOptions =
    `<option value="">Select…</option>` +
    items
      .map(
        ({ value: v, label }) =>
          `<option value="${v}"${selected.has(v) ? " selected" : ""}>${label}</option>`
      )
      .join("")
  const label = value.length === 0 ? "Select…" : (items.find((i) => selected.has(i.value))?.label ?? "Select…")
  return `
  <div id="${hookId}" data-zag
    data-items='${JSON.stringify(items)}'
    ${binding}
    data-trigger-id="${id}" data-placeholder="Select…" data-name="${id}" ${extraRoot}>
    <div data-scope="select" data-part="root">
      <select data-scope="select" data-part="hidden-select" name="${id}">${hiddenOptions}</select>
      <div data-scope="select" data-part="control">
        <button type="button" id="${id}" data-scope="select" data-part="trigger"
          aria-haspopup="listbox" aria-expanded="false">
          <span data-scope="select" data-part="item-text" data-placeholder="Select…"${
            value.length === 0 ? " data-empty" : ""
          }>${label}</span>
        </button>
      </div>
      <div data-scope="select" data-part="positioner">
        <div data-scope="select" data-part="content" role="listbox" hidden tabindex="-1">
          <div>${itemButtons}</div>
        </div>
      </div>
    </div>
  </div>`
}

function mount(html, { rootId } = {}) {
  const dom = new JSDOM(`<!doctype html><html><body>${html}</body></html>`, {
    pretendToBeVisual: true,
    url: "https://lantern.test/",
  })
  const { window } = dom
  const previous = {}
  for (const key of [
    "document",
    "window",
    "Element",
    "HTMLElement",
    "Node",
    "Event",
    "CustomEvent",
    "KeyboardEvent",
    "CSS",
    "getComputedStyle",
  ]) {
    previous[key] = globalThis[key]
    if (window[key] !== undefined) globalThis[key] = window[key]
  }
  globalThis.requestAnimationFrame = window.requestAnimationFrame.bind(window)
  globalThis.cancelAnimationFrame = window.cancelAnimationFrame.bind(window)
  globalThis.MutationObserver = window.MutationObserver
  // jsdom implements neither; Zag calls both during open/select.
  window.HTMLElement.prototype.scrollIntoView = function scrollIntoView() {}
  window.Element.prototype.scrollTo = function scrollTo() {}
  if (globalThis.ResizeObserver === undefined) {
    globalThis.ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    }
  }

  const el = rootId ? window.document.getElementById(rootId) : window.document.body.firstElementChild
  const pushEvent = []
  const serverEvents = new Map()
  const clientEvents = []
  el.addEventListener("select-picked", (e) => clientEvents.push(e))

  const hook = Object.create(LanternZagSelect)
  Object.assign(hook, {
    el,
    pushEvent: (event, payload) => pushEvent.push({ event, payload }),
    handleEvent: (event, callback) => serverEvents.set(event, callback),
  })
  hook.mounted()

  const context = {
    hook,
    window,
    document: window.document,
    el,
    pushEvent,
    clientEvents,
    component: () => el.__lanternSelect,
    serverPush: (event, payload) => serverEvents.get(event)?.(payload),
    /** Simulate a LiveView patch touching root attrs, then run the callback. */
    patch(patchFn) {
      hook.beforeUpdate()
      patchFn(el)
      hook.updated()
    },
    unmount() {
      hook.destroyed?.()
      for (const key of Object.keys(previous)) globalThis[key] = previous[key]
      delete globalThis.requestAnimationFrame
      delete globalThis.cancelAnimationFrame
      delete globalThis.MutationObserver
      window.close()
    },
  }
  mounts.push(context)
  return context
}

const sleep = (ms = 20) => new Promise((resolve) => setTimeout(resolve, ms))
const triggerText = (el) =>
  el.querySelector('[data-part="trigger"] [data-part="item-text"]').textContent
const hiddenSelect = (el) => el.querySelector('[data-part="hidden-select"]')

test("client mode: clicking an option updates the machine, trigger, and hidden form control", async () => {
  const { el, component } = mount(fixture(), { rootId: "status-select" })
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["active"])

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  assert.equal(el.querySelector('[data-part="content"]').hidden, false)

  const changes = []
  hiddenSelect(el).addEventListener("change", () => changes.push(hiddenSelect(el).value))

  el.querySelector('[data-part="item"][data-value="archived"]').click()
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["archived"])
  assert.equal(triggerText(el), "Archived")
  assert.equal(hiddenSelect(el).value, "archived")
  assert.deepEqual(changes, ["archived"])
})

test("select changes bubble through a form inside an overlay and clear to empty", async () => {
  const ctx = mount(
    `<form id="filters" phx-change="update-filter"><input type="number" name="min_price"></form><div id="panel" class="lui-popover-panel">${fixture({ extraRoot: 'data-form="filters"' })}</div>`,
    { rootId: "status-select" }
  )
  const { el, window } = ctx
  const form = window.document.querySelector("form")
  const changes = []
  form.addEventListener("change", (event) => {
    changes.push({ target: event.target.tagName, data: new window.FormData(form).get("status") })
  })
  await sleep()
  assert.equal(hiddenSelect(el).form, form)

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  assert.equal(el.querySelector('[data-part="content"]').hidden, false)
  el.querySelector('[data-part="item"][data-value="archived"]').click()
  await sleep()

  assert.deepEqual(el.__lanternSelect.api.value.map(String), ["archived"])
  assert.equal(hiddenSelect(el).value, "archived")
  assert.deepEqual(changes, [{ target: "FORM", data: "archived" }])

  // Exercise clear through Zag's API, as the clear button is only rendered
  // when there is a selected value in the server markup.
  el.__lanternSelect.api.setValue([])
  await sleep()
  assert.equal(hiddenSelect(el).value, "")
  assert.equal(changes.at(-1).data, "")
})

test("client mode: on-change pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="status_changed" data-on-change-client="select-picked"` }),
    { rootId: "status-select" }
  )
  await sleep()

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  el.querySelector('[data-part="item"][data-value="archived"]').click()
  await sleep()

  assert.deepEqual(pushEvent, [
    { event: "status_changed", payload: { id: "status-select", value: ["archived"] } },
  ])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "status-select", value: ["archived"] })
})

test("client mode: an unrelated server patch does not reset client-picked state", async () => {
  const ctx = mount(fixture(), { rootId: "status-select" })
  const { el, component } = ctx
  await sleep()

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  el.querySelector('[data-part="item"][data-value="archived"]').click()
  await sleep()
  assert.equal(triggerText(el), "Archived")

  // A patch that re-renders chrome (error flag) while the server value is
  // stale: the machine must win.
  el.querySelector('[data-part="trigger"] [data-part="item-text"]').textContent = "Active"
  ctx.patch((root) => root.setAttribute("data-invalid", ""))
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["archived"])
  assert.equal(triggerText(el), "Archived")
  assert.equal(hiddenSelect(el).value, "archived")
})

test("controlled mode: a changed server value flows into the machine", async () => {
  const { el, component } = mount(fixture({ mode: "controlled" }), { rootId: "status-select" })
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["active"])

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  el.querySelector('[data-part="item"][data-value="archived"]').click()
  await sleep()
  // Client pick flows out; server now echoes it back as the new truth.
  const ctx = mounts.at(-1)
  ctx.patch((root) => root.setAttribute("data-value", JSON.stringify(["archived"])))
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["archived"])
  assert.equal(triggerText(el), "Archived")
})

test("controlled mode: a patch that leaves the value alone keeps client state", async () => {
  const { el, component } = mount(
    fixture({ mode: "controlled", extraRoot: `data-on-change="status_changed"` }),
    { rootId: "status-select" }
  )
  await sleep()
  const ctx = mounts.at(-1)

  // Server re-renders with the same value: no machine push, no echo storm.
  const pushesBefore = ctx.pushEvent.length
  ctx.patch((root) => root.setAttribute("data-invalid", ""))
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["active"])
  assert.equal(ctx.pushEvent.length, pushesBefore)
})

test("multiple with max: picks past the cap are reverted", async () => {
  const { el, component } = mount(
    fixture({
      id: "tags",
      hookId: "tags-select",
      options: [
        ["A", "a"],
        ["B", "b"],
      ],
      value: [],
      extraRoot: `data-multiple data-max="1"`,
    }),
    { rootId: "tags-select" }
  )
  await sleep()

  el.querySelector('[data-part="trigger"]').click()
  await sleep()
  el.querySelector('[data-part="item"][data-value="a"]').click()
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["a"])
  assert.equal(triggerText(el), "A")

  el.querySelector('[data-part="item"][data-value="b"]').click()
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["a"])
  assert.equal(triggerText(el), "A")
})

test("listbox is named by the trigger, not zag's absent label part", async () => {
  const { el, component } = mount(fixture({ extraRoot: `data-labelled-by="status"` }), {
    rootId: "status-select",
  })
  await sleep()

  // Zag's content props point aria-labelledby at a label part lantern does
  // not render; render() re-points it at the trigger instead.
  assert.equal(el.querySelector('[data-part="content"]').getAttribute("aria-labelledby"), "status")
  assert.ok(component())
})

test("server push lantern:select:set-value drives the machine", async () => {
  const { el, component, serverPush } = mount(fixture(), { rootId: "status-select" })
  await sleep()

  serverPush("lantern:select:set-value", { id: "status-select", value: ["archived"] })
  await sleep()

  assert.deepEqual(component().api.value.map(String), ["archived"])
  assert.equal(triggerText(el), "Archived")

  // A push for another id is ignored.
  serverPush("lantern:select:set-value", { id: "other-select", value: ["active"] })
  await sleep()
  assert.deepEqual(component().api.value.map(String), ["archived"])
  assert.equal(el.id, "status-select")
})
