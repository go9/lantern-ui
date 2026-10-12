import assert from "node:assert/strict"
import { test } from "node:test"
import { hooks, mountHook } from "./helpers/dom.mjs"

const fixture = `
  <div id="a" phx-hook="LanternSortable" data-key="1" data-group="board" data-event="drop" data-reorder>
    <div data-part="drop-zone">Drop here</div>
    <div data-part="item" data-id="10" draggable="true">ten</div>
    <div data-part="item" data-id="11" draggable="true" data-selected>eleven</div>
    <div data-part="item" data-id="12" draggable="true" data-selected>twelve</div>
  </div>
  <div id="b" phx-hook="LanternSortable" data-key="2" data-group="board" data-event="drop">
    <div data-part="drop-zone">Drop here</div>
  </div>`

function fire(ctx, target, type, clientY = 0) {
  const ev = new ctx.window.Event(type, { bubbles: true, cancelable: true })
  ev.clientY = clientY
  target.dispatchEvent(ev)
  return ev
}

test("dragging a selected row carries every selected row; landing zone appends", () => {
  const a = mountHook(hooks.LanternSortable, fixture, { rootId: "a" })
  const b = Object.create(hooks.LanternSortable)
  const pushed = []
  Object.assign(b, { el: a.document.getElementById("b"), pushEvent: (e, p) => pushed.push({ e, p }) })
  b.mounted()

  fire(a, a.document.querySelector('[data-id="12"]'), "dragstart")
  const zone = a.document.querySelector('#b [data-part="drop-zone"]')
  assert.equal(fire(a, zone, "dragover").defaultPrevented, true)
  assert.ok(b.el.hasAttribute("data-drop-active"))
  fire(a, zone, "drop")

  assert.deepEqual(pushed, [{ e: "drop", p: { ids: ["11", "12"], from: "1", to: "2", before_id: null } }])
  a.unmount()
})

test("dropping in the top half of a row inserts before it; dragged rows are skipped", () => {
  const a = mountHook(hooks.LanternSortable, fixture, { rootId: "a" })
  const ten = a.document.querySelector('[data-id="10"]')
  ten.getBoundingClientRect = () => ({ top: 0, height: 20 })
  const eleven = a.document.querySelector('[data-id="11"]')
  eleven.getBoundingClientRect = () => ({ top: 20, height: 20 })

  fire(a, ten, "dragstart")
  fire(a, eleven, "dragover", 25)
  assert.equal(eleven.getAttribute("data-drop"), "before")
  fire(a, eleven, "drop", 25)
  assert.deepEqual(a.pushEvent.at(-1).payload, { ids: ["10"], from: "1", to: "1", before_id: "11" })

  // Bottom half of the dragged row itself → before the next row that stays.
  fire(a, ten, "dragstart")
  fire(a, ten, "drop", 15)
  assert.equal(a.pushEvent.at(-1).payload.before_id, "11")
  a.unmount()
})

test("a list without reorder treats a row as the landing zone", () => {
  const html = fixture.replace(" data-reorder", "")
  const a = mountHook(hooks.LanternSortable, html, { rootId: "a" })
  const ten = a.document.querySelector('[data-id="10"]')
  fire(a, ten, "dragstart")
  fire(a, a.document.querySelector('[data-id="11"]'), "drop", 25)
  assert.equal(a.pushEvent.at(-1).payload.before_id, null)
  a.unmount()
})

test("drags from another group are refused", () => {
  const html = fixture.replace('id="b" phx-hook="LanternSortable" data-key="2" data-group="board"', 'id="b" phx-hook="LanternSortable" data-key="2" data-group="other"')
  const a = mountHook(hooks.LanternSortable, html, { rootId: "a" })
  const b = Object.create(hooks.LanternSortable)
  Object.assign(b, { el: a.document.getElementById("b"), pushEvent: () => assert.fail("pushed") })
  b.mounted()
  fire(a, a.document.querySelector('[data-id="10"]'), "dragstart")
  assert.equal(fire(a, b.el, "dragover").defaultPrevented, false)
  fire(a, b.el, "drop")
  a.unmount()
})
