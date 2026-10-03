// Behavioural tests for the Zag-driven dialog (`assets/js/zag/dialog.js`),
// serving `modal/1` (and `alert_dialog/1`, which composes it).
//
// Fixtures mirror the `modal` HEEx output: `data-zag` root, Zag anatomy
// (`data-scope="dialog"` + `data-part`), `lui-*` styling untouched. The
// `LanternUI.open_dialog/close_dialog` contracts (DOM `lantern:dialog:*`
// dispatches + server push_events) and server `data-open` ownership are
// covered here.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { dismissOutside, mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagDialog } = await import("../../assets/js/zag/dialog.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({
  id = "confirm",
  role = "dialog",
  mode = "client",
  open = false,
  esc = true,
  outside = true,
  extraRoot = "",
} = {}) {
  const binding =
    mode === "controlled" ? `data-controlled data-value="${open}"` : `data-default-value="${open}"`
  // `data-open` mirrors the server render (`data-open={@open || nil}`):
  // present only when the server asserts open.
  const serverOpen = open && mode !== "controlled" ? `data-open=""` : ""
  return `
  <div id="${id}" data-zag ${binding}
    data-role="${role}" ${serverOpen}
    data-close-on-esc="${esc}" data-close-on-outside="${outside}" ${extraRoot}>
    <div data-scope="dialog" data-part="backdrop" class="lui-modal-backdrop"></div>
    <div data-scope="dialog" data-part="positioner">
      <div data-scope="dialog" data-part="content" class="lui-modal-panel" role="${role}" aria-modal="true" hidden>
        <button type="button" data-scope="dialog" data-part="close-trigger" class="lui-modal-close" aria-label="Close">x</button>
        <h2>Delete 3 objects?</h2>
        <button type="button" class="confirm">Delete</button>
      </div>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const execJS = []
  const ctx = mountZag(LanternZagDialog, html, {
    rootId: "confirm",
    componentKey: "__lanternDialog",
    clientEvent: "dialog-toggled",
    liveSocket: { execJS: (el, cmd) => execJS.push(cmd) },
    ...opts,
  })
  mounts.push(ctx)
  return { ...ctx, execJS }
}

const content = (el) => el.querySelector('[data-part="content"]')
const openDialog = (el) =>
  el.dispatchEvent(new el.ownerDocument.defaultView.CustomEvent("lantern:dialog:open", { bubbles: true }))
const closeDialog = (el) =>
  el.dispatchEvent(new el.ownerDocument.defaultView.CustomEvent("lantern:dialog:close", { bubbles: true }))

test("lantern:dialog:open/close DOM events drive the machine (open_dialog/close_dialog contract)", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)

  openDialog(el)
  await waitFor(() => component().api.open === true)
  assert.equal(content(el).hidden, false)

  el.querySelector('[data-part="close-trigger"]').click()
  await waitFor(() => component().api.open === false)
  assert.equal(content(el).hidden, true)

  // Closing twice is a no-op, never an error.
  closeDialog(el)
  await sleep()
  assert.equal(component().api.open, false)
})

test("server push open/close honors the id (LanternUI.open_dialog(socket, id) contract)", async () => {
  const { el, component, serverPush } = mount(fixture())
  await sleep()

  serverPush("lantern:dialog:open", { id: "other" })
  await sleep()
  assert.equal(component().api.open, false)

  serverPush("lantern:dialog:open", { id: "confirm" })
  await waitFor(() => component().api.open === true)

  serverPush("lantern:dialog:close", { id: "confirm" })
  await waitFor(() => component().api.open === false)
  assert.equal(content(el).hidden, true)
})

test("Escape closes when close-on-esc, never when prevented", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  openDialog(el)
  await waitFor(() => component().api.open === true)

  document.dispatchEvent(new document.defaultView.KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
  await waitFor(() => component().api.open === false)
})

test("prevent_closing blocks Escape", async () => {  const { el, component, document } = mount(
    fixture({ esc: false, outside: false, extraRoot: `data-prevent-closing` })
  )
  await sleep()

  openDialog(el)
  await waitFor(() => component().api.open === true)

  document.dispatchEvent(new document.defaultView.KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
  await sleep(50)
  assert.equal(component().api.open, true)
})

test("server data-open patch re-opens; withdrawing it closes silently (no on_close, no push)", async () => {
  const ctx = mount(
    fixture({ extraRoot: `data-on-change="dlg_changed" data-on-close="[[&quot;hide&quot;,{}]]"` })
  )
  const { el, component, pushEvent, execJS } = ctx
  await sleep()

  // Server asserts open: re-opens.
  ctx.patch((root) => root.setAttribute("data-open", ""))
  await waitFor(() => component().api.open === true)

  // Server withdraws open: closes, silently — the server already knows.
  ctx.patch((root) => root.removeAttribute("data-open"))
  await waitFor(() => component().api.open === false)
  assert.deepEqual(pushEvent, [])
  assert.deepEqual(execJS, [])
})

test("client close runs on_close and pushes; client open runs on_open", async () => {
  const { el, pushEvent, execJS } = mount(
    fixture({
      extraRoot: `data-on-change="dlg_changed" data-on-change-client="dialog-toggled" data-on-open="OPEN-CMD" data-on-close="CLOSE-CMD"`,
    })
  )
  await sleep()

  openDialog(el)
  await sleep(50)
  assert.deepEqual(execJS, ["OPEN-CMD"])

  closeDialog(el)
  await sleep(50)
  assert.deepEqual(execJS, ["OPEN-CMD", "CLOSE-CMD"])
  assert.deepEqual(pushEvent, [
    { event: "dlg_changed", payload: { id: "confirm", open: true } },
    { event: "dlg_changed", payload: { id: "confirm", open: false } },
  ])
})

test("outside pointerdown dismisses a dismissible modal", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  openDialog(el)
  await waitFor(() => component().api.open === true)

  await dismissOutside(document, () => component().api.open)
  assert.equal(content(el).hidden, true)
})

test("controlled mode: the server value is strict truth", async () => {
  const ctx = mount(fixture({ mode: "controlled", open: true }))
  const { el, component, serverPush } = ctx
  await sleep(50)

  assert.equal(component().api.open, true)

  ctx.patch((root) => root.setAttribute("data-value", "false"))
  await sleep()
  assert.equal(component().api.open, false)
  assert.equal(content(el).hidden, true)

  // open_dialog still works in controlled mode (routed through updateProps,
  // which a controlled machine honors unlike api.setOpen).
  serverPush("lantern:dialog:open", { id: "confirm" })
  await waitFor(() => component().api.open === true)
})

test("initial-focus selector resolves to the machine's focus target", async () => {
  // jsdom reports nothing tabbable, so Zag's focus trap cannot move
  // `activeElement` here — assert the wiring instead: the selector maps to
  // the machine's `initialFocusEl`. (Real-browser focusing is Zag core.)
  const { dialogLayoutProps } = await import("../../assets/js/zag/dialog.js")
  const { el } = mount(fixture({ extraRoot: `data-initial-focus=".confirm"` }))
  await sleep()

  const target = dialogLayoutProps(el, {}).initialFocusEl()
  assert.equal(target, el.querySelector(".confirm"))
})
