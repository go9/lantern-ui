// Behavioural tests for the Zag-driven alert dialog (`assets/js/zag/dialog.js`
// serving `alert_dialog/1` through `Modal.modal`).
//
// Alert specifics over the shared dialog wiring: `role="alertdialog"`,
// outside clicks NEVER dismiss, the real title/description ids label the
// content (no dangling generated refs), and initial focus lands in the
// cancel region.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagDialog, dialogLayoutProps } = await import("../../assets/js/zag/dialog.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({ id = "delete-project", open = false } = {}) {
  return `
  <div id="${id}" data-zag data-default-value="${open}"
    ${open ? `data-open=""` : ""} data-role="alertdialog"
    data-close-on-esc="true" data-close-on-outside="false"
    data-title-id="${id}-title" data-description-id="${id}-description"
    data-initial-focus="[data-part='alert-dialog-cancel'] button">
    <div data-scope="dialog" data-part="backdrop" class="lui-modal-backdrop"></div>
    <div data-scope="dialog" data-part="positioner">
      <div data-scope="dialog" data-part="content" class="lui-modal-panel lui-alert-dialog"
        role="alertdialog" aria-modal="true" aria-labelledby="${id}-title" aria-describedby="${id}-description" hidden>
        <h2 id="${id}-title" class="lui-alert-dialog-title">Delete this project?</h2>
        <div id="${id}-description" class="lui-alert-dialog-description">This cannot be undone.</div>
        <div class="lui-alert-dialog-actions">
          <div class="lui-alert-dialog-cancel" data-part="alert-dialog-cancel">
            <button type="button" class="cancel">Cancel</button>
          </div>
          <div class="lui-alert-dialog-action"><button type="button" class="confirm">Delete project</button></div>
        </div>
      </div>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagDialog, html, {
    rootId: "delete-project",
    componentKey: "__lanternDialog",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

const content = (el) => el.querySelector('[data-part="content"]')
const openDialog = (el) =>
  el.dispatchEvent(new el.ownerDocument.defaultView.CustomEvent("lantern:dialog:open", { bubbles: true }))

function pointerdown(doc, target) {
  const view = doc.defaultView
  const EventCtor = view.PointerEvent ?? view.MouseEvent
  // Far-away point: jsdom reports every rect as zeros, so (0,0) reads as
  // "within" the dialog and interact-outside ignores it.
  const event = new EventCtor("pointerdown", {
    bubbles: true,
    cancelable: true,
    button: 0,
    clientX: 9999,
    clientY: 9999,
  })
  // Dispatch on the document with the outside node as target: interact-outside
  // listens up the tree, so dispatching directly on the target is faithful.
  target.dispatchEvent(event)
  return event
}

test("alertdialog keeps its role and real title/description labelling", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  openDialog(el)
  await waitFor(() => component().api.open === true)

  assert.equal(content(el).getAttribute("role"), "alertdialog")
  assert.equal(content(el).getAttribute("aria-labelledby"), "delete-project-title")
  assert.equal(content(el).getAttribute("aria-describedby"), "delete-project-description")
  // The machine ids override points Zag at the real nodes (no generated
  // `dialog:*` refs that dangle).
  assert.ok(el.querySelector("#delete-project-title"), "title node exists")
})

test("initial focus resolves into the cancel region", async () => {
  const { el } = mount(fixture())
  await sleep()

  const target = dialogLayoutProps(el, {}).initialFocusEl()
  assert.equal(target, el.querySelector("[data-part='alert-dialog-cancel'] button"))
})

test("outside pointerdown never dismisses an alert dialog; Escape does", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  openDialog(el)
  await waitFor(() => component().api.open === true)

  const outside = document.createElement("div")
  document.body.append(outside)
  pointerdown(document, outside)
  await sleep(50)
  assert.equal(component().api.open, true)
  assert.equal(content(el).hidden, false)

  document.dispatchEvent(
    new document.defaultView.KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true })
  )
  await waitFor(() => component().api.open === false)
})
