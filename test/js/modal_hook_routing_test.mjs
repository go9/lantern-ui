// Bundle-level routing for `LanternModal` (flicker #3416, step 2, PR B).
//
// Roots carrying `data-zag` (every `<.modal>` / `<.alert_dialog>`) upgrade
// to the Zag dialog chunk; everything else — notably hand-rolled dialog
// markup such as enventory_new's dismantle-modal — stays on the legacy
// hook, so `LanternUI.open_dialog/close_dialog` keep working there.
//
// Mounts the built bundle hooks through the shared Zag mount harness (full
// jsdom globals); the Zag chunk resolves on disk exactly as for consumers.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { hooks } from "./helpers/dom.mjs"
import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function mountLegacy() {
  const ctx = mountZag(hooks.LanternModal, `
  <div id="dismantle-modal">
    <div data-part="panel" role="dialog" aria-modal="true">
      <h3>Dismantle this bundle?</h3>
      <button type="button" data-part="close">Cancel</button>
    </div>
  </div>`, { rootId: "dismantle-modal", componentKey: "__lanternDialog" })
  mounts.push(ctx)
  return ctx
}

test("legacy roots without data-zag open and close on lantern:dialog:* events", async () => {
  const { el, window } = mountLegacy()
  await sleep()

  el.dispatchEvent(new window.CustomEvent("lantern:dialog:open", { bubbles: true }))
  await sleep()
  assert.equal(el.hidden, false)

  el.querySelector('[data-part="close"]').click()
  await sleep()
  assert.equal(el.hidden, true)
})

test("legacy roots follow server data-open patches", async () => {
  const { hook, el } = mountLegacy()
  await sleep()

  el.setAttribute("data-open", "")
  el.hidden = false
  hook.updated()
  await sleep()
  assert.equal(el.hidden, false)
})

test("data-zag roots upgrade to the Zag dialog delegate", async () => {
  const ctx = mountZag(hooks.LanternModal, `
  <div id="m1" data-zag data-default-value="false" data-role="dialog"
    data-close-on-esc="true" data-close-on-outside="true">
    <div data-scope="dialog" data-part="backdrop"></div>
    <div data-scope="dialog" data-part="positioner">
      <div data-scope="dialog" data-part="content" role="dialog" aria-modal="true" hidden>
        <button type="button" data-scope="dialog" data-part="close-trigger">x</button>
      </div>
    </div>
  </div>`, { rootId: "m1", componentKey: "__lanternDialog" })
  mounts.push(ctx)
  const { el, window, hook } = ctx
  await waitFor(() => hook._zagDelegate !== undefined, { timeout: 2000 })
  const component = () => hook._zagDelegate && el.__lanternDialog

  el.dispatchEvent(new window.CustomEvent("lantern:dialog:open", { bubbles: true }))
  await waitFor(() => component().api.open === true)
  assert.equal(el.querySelector('[data-part="content"]').hidden, false)

  // Close before unmount: open dialogs hold pending raf work that would
  // otherwise fire after the harness deletes the globals.
  el.dispatchEvent(new window.CustomEvent("lantern:dialog:close", { bubbles: true }))
  await waitFor(() => component().api.open === false)
})
