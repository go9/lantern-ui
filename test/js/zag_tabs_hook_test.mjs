// Behavioural tests for the Zag-driven tabs (`assets/js/zag/tabs.js`),
// serving hooked `tabs_list/1` (segmented + underline).
//
// Fixtures mirror the `tabs_list` HEEx output: `data-zag` root (which IS
// the Zag root + list), Zag trigger anatomy, `lui-*` styling untouched.
// Patch/navigate/URL stay the source of truth — the machine never
// intercepts activation; keyboard uses the manual model (arrows move
// focus, Enter activates natively).

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagTabs } = await import("../../assets/js/zag/tabs.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function tab(name, label, { link = false, active = false } = {}) {
  const base = `class="lui-tab${active ? " lui-tab-active" : ""}" data-scope="tabs" data-part="trigger" data-value="${name}" role="tab" aria-selected="${active}" tabindex="${active ? "0" : "-1"}"`
  if (link) return `<a href="/tickets?scope=${name}" ${base}>${label}</a>`
  return `<button type="button" ${base}>${label}</button>`
}

function fixture({ id = "scope", activeTab = "all", extraRoot = "" } = {}) {
  const activeAttr = activeTab === null ? "" : `data-active-tab="${activeTab}"`
  return `
  <div id="${id}" data-zag ${activeAttr}
    data-scope="tabs" data-variant="segmented" data-size="sm" role="tablist" ${extraRoot}>
    ${tab("all", "All", { active: activeTab === "all" })}
    ${tab("active", "Active", { active: activeTab === "active" })}
    ${tab("backlog", "Backlog", { active: activeTab === "backlog" })}
  </div>`
}

function linkFixture({ id = "orders", activeTab = "pending" } = {}) {
  return `
  <div id="${id}" data-zag data-active-tab="${activeTab}"
    data-scope="tabs" data-variant="underline" role="tablist">
    ${tab("all", "All", { link: true, active: false })}
    ${tab("pending", "Pending", { link: true, active: true })}
  </div>`
}

function mount(html, rootId, opts = {}) {
  const ctx = mountZag(LanternZagTabs, html, {
    rootId,
    componentKey: "__lanternTabs",
    clientEvent: "tab-picked",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

test("controlled (active_tab): machine follows the server value; arrows move focus without activating", async () => {
  const { el, component, window, document } = mount(fixture(), "scope")
  await sleep()

  assert.equal(component().api.value, "all")

  const triggers = [...el.querySelectorAll('[data-part="trigger"]')]
  triggers[0].focus()
  triggers[0].dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep()

  // Manual model: focus moved, value unchanged (no auto-activation).
  assert.equal(document.activeElement, triggers[1])
  assert.equal(component().api.value, "all")
})

test("controlled: a server active_tab patch re-points the machine", async () => {
  const ctx = mount(fixture({ activeTab: "all" }), "scope")
  const { el, component } = ctx
  await sleep()

  ctx.patch((root) => root.setAttribute("data-active-tab", "backlog"))
  await sleep()

  assert.equal(component().api.value, "backlog")
  void el
})

test("controlled: an unrelated patch does not reset client highlight", async () => {
  const ctx = mount(fixture({ activeTab: "all" }), "scope")
  const { el, component, window } = ctx
  await sleep()

  const triggers = [...el.querySelectorAll('[data-part="trigger"]')]
  triggers[0].focus()
  triggers[0].dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  await sleep()

  ctx.patch((root) => root.setAttribute("data-size", "md"))
  await sleep()

  // No active_tab change: the machine keeps client state.
  assert.equal(component().api.value, "all")
})

test("link tabs keep navigating: machine never preventDefaults activation", async () => {
  const { el, component } = mount(linkFixture(), "orders")
  await sleep()

  const pending = el.querySelector('[data-value="pending"]')
  assert.equal(pending.tagName, "A")

  const clicked = []
  pending.addEventListener("click", (e) => clicked.push(e.defaultPrevented))
  pending.click()
  await sleep()

  assert.deepEqual(clicked, [false])
  assert.equal(component().api.value, "pending")
})

test("selection pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents, component, patch } = mount(
    fixture({ extraRoot: `data-on-change="scope_changed" data-on-change-client="tab-picked"` }),
    "scope"
  )
  await sleep()

  // Button tabs have no native navigation; select through the machine.
  el.__lanternTabs.api.setValue("active")
  await sleep()

  assert.deepEqual(pushEvent, [{ event: "scope_changed", payload: { id: "scope", value: "active" } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "scope", value: "active" })

  // Tabs are server-driven (`data-active-tab`): the machine holds until the
  // server patch flows in — then selection state is DOM truth, not just
  // machine state (#3448 audit).
  patch((root) => root.setAttribute("data-active-tab", "active"))
  await waitFor(() => component().api.value === "active")
  const trigger = (name) => el.querySelector(`[data-part="trigger"][data-value="${name}"]`)
  assert.equal(trigger("active").getAttribute("aria-selected"), "true")
  assert.equal(trigger("active").getAttribute("tabindex"), "0")
  assert.equal(trigger("all").getAttribute("aria-selected"), "false")
  assert.equal(trigger("all").getAttribute("tabindex"), "-1")
})

test("server set-value drives the machine with id scoping", async () => {
  const { component, serverPush } = mount(fixture(), "scope")
  await sleep()

  serverPush("lantern:tabs:set-value", { id: "nope", value: "backlog" })
  await sleep(30)
  assert.equal(component().api.value, "all")

  serverPush("lantern:tabs:set-value", { id: "scope", value: "backlog" })
  await sleep()
  assert.equal(component().api.value, "backlog")
})
