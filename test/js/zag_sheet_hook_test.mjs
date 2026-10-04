// Behavioural tests for the Zag-driven sheet (`assets/js/zag/sheet.js`).
//
// Fixtures mirror the `sheet` HEEx output: `data-zag` root, Zag anatomy
// (`data-scope="dialog"` + `data-part`), slide `placement`, `lui-*`
// styling untouched. Covers the sheet extras over the shared dialog
// wiring: the `data-closing` slide-out exit and `lantern:dialog:*` parity.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { dismissOutside, mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagSheet } = await import("../../assets/js/zag/sheet.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({ id = "edit-theme", open = false, extraRoot = "" } = {}) {
  // Mirrors `Sheet.sheet` HEEx: `hidden` lives on the ROOT, never on the
  // content — Zag owns both after mount (flicker #3448).
  return `
  <div id="${id}" data-zag data-default-value="${open}"
    ${open ? `data-open=""` : ""} data-placement="right"
    data-close-on-esc="true" data-close-on-outside="true" ${extraRoot}${open ? "" : " hidden"}>
    <div data-scope="dialog" data-part="backdrop" class="lui-sheet-backdrop"></div>
    <div data-scope="dialog" data-part="positioner">
      <div data-scope="dialog" data-part="content" class="lui-sheet-panel" role="dialog" aria-modal="true" aria-label="Edit theme">
        <header class="lui-sheet-header">
          <div class="lui-sheet-heading"><span class="lui-sheet-title">Edit theme</span></div>
          <button type="button" data-scope="dialog" data-part="close-trigger" class="lui-sheet-close" aria-label="Close">x</button>
        </header>
        <div class="lui-sheet-body">Body</div>
      </div>
    </div>
  </div>`
}

function mount(html, opts = {}) {
  const execJS = []
  const ctx = mountZag(LanternZagSheet, html, {
    rootId: "edit-theme",
    componentKey: "__lanternSheet",
    clientEvent: "sheet-toggled",
    liveSocket: { execJS: (el, cmd) => execJS.push(cmd) },
    ...opts,
  })
  mounts.push(ctx)
  return { ...ctx, execJS }
}

const content = (el) => el.querySelector('[data-part="content"]')
// Visibility is the ROOT `hidden` (what the server renders) AND the content
// `hidden` (what Zag spreads): both must agree with machine state (#3448).
// During the slide-out exit the machine is closed but both stay visible.
const assertVisibility = (el, open) => {
  assert.equal(el.hidden, !open, `root hidden should be ${!open}`)
  assert.equal(content(el).hidden, !open, `content hidden should be ${!open}`)
}
const openSheet = (el) =>
  el.dispatchEvent(new el.ownerDocument.defaultView.CustomEvent("lantern:dialog:open", { bubbles: true }))
const closeSheet = (el) =>
  el.dispatchEvent(new el.ownerDocument.defaultView.CustomEvent("lantern:dialog:close", { bubbles: true }))

test("lantern:dialog:open/close drive the machine and the close button", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  openSheet(el)
  await waitFor(() => component().api.open === true)
  assertVisibility(el, true)

  el.querySelector('[data-part="close-trigger"]').click()
  await waitFor(() => component().api.open === false)
})

test("client close plays the slide-out exit before hiding", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  openSheet(el)
  await waitFor(() => component().api.open === true)

  closeSheet(el)
  await waitFor(() => component().api.open === false)
  // Exit keyframe: still visible under data-closing — root AND content…
  assert.equal(el.getAttribute("data-closing"), "")
  assert.equal(el.hidden, false)
  assert.equal(content(el).hidden, false)

  // …then hidden once the slide finishes.
  await waitFor(() => content(el).hidden === true, { timeout: 2000 })
  assert.equal(el.hidden, true)
  assert.equal(el.hasAttribute("data-closing"), false)
})

test("client close runs on_close and pushes; server close stays silent", async () => {
  const ctx = mount(
    fixture({ extraRoot: `data-on-change="sheet_changed" data-on-close="CLOSE-CMD"` })
  )
  const { el, component, pushEvent, execJS } = ctx
  await sleep()

  openSheet(el)
  await waitFor(() => component().api.open === true)

  closeSheet(el)
  await waitFor(() => component().api.open === false)
  assert.deepEqual(execJS, ["CLOSE-CMD"])
  assert.deepEqual(pushEvent, [
    { event: "sheet_changed", payload: { id: "edit-theme", open: true } },
    { event: "sheet_changed", payload: { id: "edit-theme", open: false } },
  ])
})

test("server data-open patch opens and closes without the close command", async () => {
  const ctx = mount(fixture({ extraRoot: `data-on-close="CLOSE-CMD"` }))
  const { el, component, execJS } = ctx
  await sleep()

  ctx.patch((root) => root.setAttribute("data-open", ""))
  await waitFor(() => component().api.open === true)
  assertVisibility(el, true)

  ctx.patch((root) => root.removeAttribute("data-open"))
  await waitFor(() => component().api.open === false)
  assert.deepEqual(execJS, [])
})

test("Escape closes a dismissible sheet", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  openSheet(el)
  await waitFor(() => component().api.open === true)

  document.dispatchEvent(new document.defaultView.KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }))
  await waitFor(() => component().api.open === false)
})

test("outside pointerdown dismisses, playing the slide-out exit", async () => {
  const { el, component, document } = mount(fixture())
  await sleep()

  openSheet(el)
  await waitFor(() => component().api.open === true)

  await dismissOutside(document, () => component().api.open)
  await waitFor(() => content(el).hidden === true, { timeout: 2000 })
  assert.equal(el.hidden, true)
})

test("every placement opens visibly (placement is CSS-only)", async () => {
  // Each mount owns a fresh JSDOM document, so reusing the fixture id is safe.
  for (const placement of ["left", "right", "top", "bottom"]) {
    const ctx = mount(fixture({ extraRoot: `data-placement="${placement}"` }))
    const { el } = ctx
    el.dispatchEvent(new ctx.document.defaultView.CustomEvent("lantern:dialog:open", { bubbles: true }))
    await waitFor(() => ctx.component().api.open === true)
    assertVisibility(el, true)
    ctx.unmount()
    mounts.splice(mounts.indexOf(ctx), 1)
  }
})
