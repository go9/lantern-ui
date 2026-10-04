// Open-state ownership for modal / alert_dialog / sheet (flicker #3453):
// a server patch must never close a dialog the client opened, focus leaving
// the panel (LiveView blurs the field on phx-submit) is not dismissal, and a
// click on a button inside the panel after a patch is an inside click.

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { dismissOutside, mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagDialog } = await import("../../assets/js/zag/dialog.js")
const { LanternZagSheet } = await import("../../assets/js/zag/sheet.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

const FAMILIES = [
  { name: "modal", Hook: LanternZagDialog, key: "__lanternDialog", outside: true },
  { name: "alert_dialog", Hook: LanternZagDialog, key: "__lanternDialog", outside: false, role: "alertdialog" },
  { name: "sheet", Hook: LanternZagSheet, key: "__lanternSheet", outside: true },
]

const fixture = ({ role = "dialog", outside, controlled }) => `
  <div id="dlg" data-zag ${controlled ? 'data-controlled data-value="false"' : 'data-default-value="false"'}
    data-role="${role}" data-close-on-esc="true" data-close-on-outside="${outside}"
    data-on-change="dlg_changed" data-on-close="CLOSE-CMD" hidden>
    <div id="dialog:dlg:backdrop" data-scope="dialog" data-part="backdrop"></div>
    <div id="dialog:dlg:positioner" data-scope="dialog" data-part="positioner">
      <div id="dialog:dlg:content" data-scope="dialog" data-part="content" role="${role}" aria-modal="true">
        <form id="f"><input id="field" name="name" /><button id="bump" type="button">Bump</button></form>
      </div>
    </div>
  </div>
  <input id="elsewhere" />`

function mount(family, { controlled = false } = {}) {
  const execJS = []
  const ctx = mountZag(family.Hook, fixture({ ...family, controlled }), {
    rootId: "dlg",
    componentKey: family.key,
    liveSocket: { execJS: (el, cmd) => execJS.push(cmd) },
  })
  mounts.push(ctx)
  return { ...ctx, execJS }
}

const open = async (ctx) => {
  ctx.serverPush("lantern:dialog:open", { id: "dlg" })
  await waitFor(() => ctx.component().api.open === true)
  // The dismissable listeners attach on a raf after open.
  await sleep(60)
}

// What a LiveView patch of the dialog's slot content looks like to the hook:
// the server re-renders the same markup, no `data-open`/`data-value` change.
const rerender = (ctx) => ctx.patch((root) => root.querySelector("#field").setAttribute("value", "a"))
const closes = (ctx) => ctx.pushEvent.filter((e) => e.payload.open === false)

for (const family of FAMILIES) {
  test(`${family.name}: a patch does not close a client-opened dialog or notify the server`, async () => {
    const ctx = mount(family)
    await sleep()
    await open(ctx)
    const before = ctx.pushEvent.length

    rerender(ctx)
    rerender(ctx)
    await sleep(80)

    assert.equal(ctx.component().api.open, true)
    assert.equal(ctx.el.hidden, false)
    assert.deepEqual(ctx.pushEvent.slice(before), [])
    assert.deepEqual(ctx.execJS, [])
  })

  test(`${family.name}: a patch inside a controlled dialog keeps it open and emits no on_change(open=false)`, async () => {
    const ctx = mount(family, { controlled: true })
    await sleep()
    await open(ctx)
    const before = ctx.pushEvent.length

    rerender(ctx)
    await sleep(80)

    assert.equal(ctx.component().api.open, true)
    assert.deepEqual(closes(ctx), [])
    assert.equal(ctx.pushEvent.length, before)

    // The server asserting a new value still wins.
    ctx.patch((root) => root.setAttribute("data-value", "true"))
    ctx.patch((root) => root.setAttribute("data-value", "false"))
    await waitFor(() => ctx.component().api.open === false)
  })

  test(`${family.name}: focus leaving the panel (phx-submit blur) does not dismiss`, async () => {
    const ctx = mount(family)
    await sleep()
    await open(ctx)

    const field = ctx.document.getElementById("field")
    field.focus()
    rerender(ctx)
    field.blur()
    ctx.document.getElementById("elsewhere").focus()
    await sleep(120)

    assert.equal(ctx.component().api.open, true)
    assert.deepEqual(closes(ctx), [])
  })

  test(`${family.name}: a click on a button inside the panel after a patch is not outside`, async () => {
    const ctx = mount(family)
    await sleep()
    await open(ctx)
    rerender(ctx)

    const bump = ctx.document.getElementById("bump")
    const Ctor = ctx.window.PointerEvent ?? ctx.window.MouseEvent
    bump.dispatchEvent(new Ctor("pointerdown", { bubbles: true, cancelable: true, button: 0 }))
    bump.click()
    await sleep(120)

    assert.equal(ctx.component().api.open, true)
    assert.deepEqual(closes(ctx), [])
  })

  test(`${family.name}: user intent still closes (outside pointerdown only where allowed, Escape always)`, async () => {
    const ctx = mount(family)
    await sleep()
    await open(ctx)
    rerender(ctx)

    if (family.outside) {
      await dismissOutside(ctx.document, () => ctx.component().api.open)
      assert.equal(closes(ctx).length, 1)
    } else {
      const Ctor = ctx.window.PointerEvent ?? ctx.window.MouseEvent
      ctx.document.body.dispatchEvent(
        new Ctor("pointerdown", { bubbles: true, cancelable: true, button: 0, clientX: 9999, clientY: 9999 })
      )
      await sleep(80)
      assert.equal(ctx.component().api.open, true)
      ctx.document.dispatchEvent(
        new ctx.window.KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true })
      )
      await waitFor(() => ctx.component().api.open === false)
    }
  })
}

test("client mode: a server data-open change still wins, an unchanged one is ignored", async () => {
  const ctx = mount(FAMILIES[0])
  await sleep()

  ctx.patch((root) => root.setAttribute("data-open", ""))
  await waitFor(() => ctx.component().api.open === true)
  await sleep(60)

  // Client closes; the server's stale `data-open` must not re-open it.
  ctx.serverPush("lantern:dialog:close", { id: "dlg" })
  await waitFor(() => ctx.component().api.open === false)
  rerender(ctx)
  await sleep(80)
  assert.equal(ctx.component().api.open, false)
})
