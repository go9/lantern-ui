// Behavioural tests for the Zag-driven menus (`assets/js/zag/menu.js`),
// serving `dropdown/1` (`LanternDropdown`) and `menu/1` (`LanternMenu`).
//
// Fixtures mirror the HEEx output: `data-zag` roots, Zag anatomy
// (`data-scope="menu"` + `data-part`), `role="menu"`, `lui-*` styling
// untouched. Covers: click toggle, item-click close, arrow-key nav,
// controlled mode, patch-does-not-reset, set-open events, and the menu
// component's stable trigger/content ids.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagDropdown, LanternZagMenu } = await import("../../assets/js/zag/menu.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function dropdownFixture({ id = "row-actions", mode = "client", open = false, extraRoot = "" } = {}) {
  const binding =
    mode === "controlled" ? `data-controlled data-value="${open}"` : `data-default-value="${open}"`
  return `
  <div id="${id}" data-zag ${binding}
    data-placement="bottom-end" ${extraRoot}>
    <div data-scope="menu" data-part="trigger" class="lui-dropdown-trigger">
      <button type="button" aria-haspopup="menu" aria-expanded="false">Actions</button>
    </div>
    <div data-scope="menu" data-part="positioner">
      <div data-scope="menu" data-part="content" class="lui-dropdown-menu" role="menu" hidden>
        <button type="button" role="menuitem" tabindex="-1">Download</button>
        <a role="menuitem" tabindex="-1" href="/preview">Preview</a>
        <div role="separator"></div>
        <button type="button" role="menuitem" tabindex="-1" data-disabled>Delete</button>
      </div>
    </div>
  </div>`
}

function mountDropdown(html, opts = {}) {
  const ctx = mountZag(LanternZagDropdown, html, {
    rootId: "row-actions",
    componentKey: "__lanternDropdown",
    clientEvent: "menu-toggled",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const content = (el) => el.querySelector('[data-part="content"]')
const openMenu = (el) => el.querySelector('[data-part="trigger"] button, [data-part="trigger"]').click()

test("dropdown: clicking the trigger toggles; item click closes", async () => {
  const { el, component } = mountDropdown(dropdownFixture())
  await sleep()

  assert.equal(component().api.open, false)

  openMenu(el)
  await waitFor(() => component().api.open === true)
  assert.equal(content(el).hidden, false)
  assert.equal(content(el).getAttribute("role"), "menu")

  el.querySelector('[role="menuitem"]').click()
  await waitFor(() => component().api.open === false)
  assert.equal(content(el).hidden, true)
})

test("dropdown: ArrowDown on the focused trigger opens on the first item", async () => {
  const { el, component, window } = mountDropdown(dropdownFixture())
  await sleep()

  // Real browsers focus before keys: focus moves idle -> closed, where
  // ARROW_DOWN opens.
  el.querySelector('[data-part="trigger"] button').focus()
  const trigger = el.querySelector('[data-part="trigger"]')
  trigger.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  await waitFor(() => component().api.open === true)
  assert.equal(content(el).hidden, false)
})

test("dropdown: arrows move highlight across enabled items only", async () => {
  const { el, component, window } = mountDropdown(dropdownFixture())
  await sleep()

  openMenu(el)
  await waitFor(() => component().api.open === true)

  const menu = content(el)
  menu.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  await sleep()
  menu.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  await sleep()

  // Download -> Preview; the disabled Delete is skipped by Zag's DOM query.
  const highlighted = menu.querySelector('[data-highlighted]')
  assert.ok(highlighted, "an item is highlighted")
  assert.equal(highlighted.textContent, "Preview")
  void component
})

test("dropdown: open change pushes and dispatches, exactly once per toggle", async () => {
  const { el, pushEvent, clientEvents } = mountDropdown(
    dropdownFixture({ extraRoot: `data-on-change="menu_changed" data-on-change-client="menu-toggled"` })
  )
  await sleep()

  openMenu(el)
  await waitFor(() => pushEvent.length === 1)
  assert.deepEqual(pushEvent, [{ event: "menu_changed", payload: { id: "row-actions", open: true } }])
  assert.equal(clientEvents.length, 1)
})

test("dropdown: an unrelated patch does not reset open state", async () => {
  const ctx = mountDropdown(dropdownFixture())
  const { el, component } = ctx
  await sleep()

  openMenu(el)
  await waitFor(() => component().api.open === true)

  ctx.patch((root) => root.setAttribute("data-placement", "top-start"))
  await sleep()

  assert.equal(component().api.open, true)
  assert.equal(content(el).hidden, false)
})

test("dropdown: controlled mode is strict truth via patches", async () => {
  const ctx = mountDropdown(dropdownFixture({ mode: "controlled", open: true }))
  const { el, component, pushEvent } = ctx
  await sleep(50)

  assert.equal(component().api.open, true)

  ctx.patch((root) => root.setAttribute("data-value", "false"))
  await sleep()
  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)
  // The patch echo must not re-notify.
  assert.deepEqual(pushEvent, [])
})

test("dropdown: server set-open is id-scoped", async () => {
  const { component, serverPush } = mountDropdown(dropdownFixture())
  await sleep()

  serverPush("lantern:menu:set-open", { id: "nope", open: true })
  await sleep(30)
  assert.equal(component().api.open, false)

  serverPush("lantern:menu:set-open", { id: "row-actions", open: true })
  await waitFor(() => component().api.open === true)

  // In client mode a server close applies (no strict truth to defend).
  serverPush("lantern:menu:set-open", { id: "row-actions", open: false })
  await waitFor(() => component().api.open === false)
})

test("menu: component-owned trigger keeps stable ids and toggles", async () => {
  const html = `
  <div id="file-actions" data-zag data-default-value="false"
    data-placement="bottom-start" data-trigger-id="file-actions-trigger" data-content-id="file-actions-menu">
    <span data-scope="menu" data-part="trigger" id="file-actions-trigger"
      aria-haspopup="menu" aria-expanded="false" aria-controls="file-actions-menu">
      <button type="button" aria-haspopup="menu" aria-expanded="false" aria-controls="file-actions-menu">File</button>
    </span>
    <div data-scope="menu" data-part="positioner">
      <div id="file-actions-menu" data-scope="menu" data-part="content"
        hidden role="menu" aria-labelledby="file-actions-trigger" class="lui-menu-panel">
        <button type="button" role="menuitem" tabindex="-1">New</button>
        <button type="button" role="menuitem" tabindex="-1">Open</button>
      </div>
    </div>
  </div>`
  const ctx = mountZag(LanternZagMenu, html, {
    rootId: "file-actions",
    componentKey: "__lanternMenu",
  })
  mounts.push(ctx)
  const { el, component } = ctx
  await sleep()

  el.querySelector("#file-actions-trigger").click()
  await waitFor(() => component().api.open === true)

  // Stable ids survive the machine spread (aria wiring intact).
  assert.equal(el.querySelector('[data-part="trigger"]').id, "file-actions-trigger")
  assert.equal(el.querySelector('[data-part="content"]').id, "file-actions-menu")
  assert.equal(
    el.querySelector('[data-part="content"]').getAttribute("aria-labelledby"),
    "file-actions-trigger"
  )
})
