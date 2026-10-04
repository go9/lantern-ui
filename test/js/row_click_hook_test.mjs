// `LanternRowClick` — data_table's `row_click`: the whole row runs a JS command,
// but a click on something interactive inside the row belongs to that thing.

import assert from "node:assert/strict"
import test from "node:test"

import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

const CMD = '[["push",{"event":"open"}]]'

function mountRows() {
  const mount = mountHook(
    hooks.LanternRowClick,
    `<table id="t"><tbody>
      <tr id="row" data-row-click='${CMD}' tabindex="0">
        <td><input id="check" type="checkbox"></td>
        <td id="plain">Ada</td>
        <td><a id="link" href="/x">x</a></td>
        <td><button id="menu" type="button"><span id="icon">⋯</span></button></td>
        <td><span id="ignored" data-row-ignore>i</span></td>
      </tr>
      <tr id="inert"><td id="inert-cell">no command</td></tr>
    </tbody></table>`,
    { rootId: "t" }
  )
  const ran = []
  mount.hook.liveSocket = { execJS: (el, code) => ran.push({ id: el.id, code }) }
  return { ...mount, ran }
}

function click(el, init = {}) {
  const win = el.ownerDocument.defaultView
  el.dispatchEvent(new win.MouseEvent("click", { bubbles: true, cancelable: true, button: 0, ...init }))
}

test("clicking the row body runs its command", () => {
  const m = mountRows()
  click(m.document.getElementById("plain"))
  assert.deepEqual(m.ran, [{ id: "row", code: CMD }])
  m.unmount()
})

test("clicks on checkboxes, links, buttons (and their children) and data-row-ignore are ignored", () => {
  const m = mountRows()
  for (const id of ["check", "link", "menu", "icon", "ignored"]) click(m.document.getElementById(id))
  assert.deepEqual(m.ran, [])
  m.unmount()
})

test("rows without a command and non-primary clicks do nothing", () => {
  const m = mountRows()
  click(m.document.getElementById("inert-cell"))
  click(m.document.getElementById("plain"), { button: 1 })
  assert.deepEqual(m.ran, [])
  m.unmount()
})

test("Enter on the focused row runs the command; Enter inside a child does not", () => {
  const m = mountRows()
  keydown(m.document.getElementById("check"), "Enter")
  assert.deepEqual(m.ran, [])
  keydown(m.document.getElementById("row"), "Enter")
  assert.deepEqual(m.ran, [{ id: "row", code: CMD }])
  m.unmount()
})

test("destroyed removes the listeners", () => {
  const m = mountRows()
  const plain = m.document.getElementById("plain")
  m.hook.destroyed()
  click(plain)
  assert.deepEqual(m.ran, [])
  m.unmount()
})
