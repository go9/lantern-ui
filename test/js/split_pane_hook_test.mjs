import assert from "node:assert/strict"
import { test } from "node:test"
import { hooks, keydown, mountHook } from "./helpers/dom.mjs"
const html = `<div id="split" data-size="35" data-min="20" data-max="80" data-storage-key="project">
<div data-part="primary"></div><div data-part="separator" role="separator" tabindex="0"></div><div data-part="secondary"><input></div></div>`
const setup = () => mountHook(hooks.LanternSplitPane, html)

test("keyboard clamps, persists and respects RTL; child keys are left alone", () => {
  const h = setup()
  try {
    const edge = h.el.querySelector('[role="separator"]')
    keydown(edge, "ArrowRight")
    assert.equal(edge.getAttribute("aria-valuenow"), "36")
    keydown(edge, "ArrowRight", { shiftKey: true })
    assert.equal(edge.getAttribute("aria-valuenow"), "46")
    keydown(edge, "End")
    keydown(edge, "ArrowRight")
    assert.equal(edge.getAttribute("aria-valuenow"), "80")
    assert.equal(h.window.localStorage.getItem("lui-split-pane:project"), "80")
    keydown(edge, "Home")
    h.el.style.direction = "rtl"
    keydown(edge, "ArrowLeft")
    assert.equal(edge.getAttribute("aria-valuenow"), "21")
    keydown(h.el.querySelector("input"), "End")
    assert.equal(edge.getAttribute("aria-valuenow"), "21")
  } finally { h.unmount() }
})

test("restores valid widths, ignores bad or blocked storage, resets on scope changes", () => {
  const h = setup()
  try {
    h.window.localStorage.setItem("lui-split-pane:other", "99")
    h.el.dataset.storageKey = "other"
    h.hook.updated()
    assert.equal(h.hook.value, 80)
    h.el.dataset.storageKey = "new-user"
    h.hook.updated()
    assert.equal(h.hook.value, 35)
    h.window.localStorage.setItem("lui-split-pane:bad", "NaN")
    h.el.dataset.storageKey = "bad"
    h.hook.updated()
    assert.equal(h.hook.value, 35)
    Object.defineProperty(h.window, "localStorage", { get() { throw new Error("blocked") } })
    h.hook.loadWidth()
    keydown(h.hook.separator(), "ArrowRight")
    assert.equal(h.hook.value, 36)
  } finally { h.unmount() }
})

function pointer(h, node, type, x, id = 1) {
  const event = new h.window.MouseEvent(type, { bubbles: true, cancelable: true, button: 0, clientX: x })
  Object.defineProperty(event, "pointerId", { value: id })
  node.dispatchEvent(event)
}

test("pointer drag clamps, saves on release and releases listeners on patch/destroy", () => {
  const h = setup()
  try {
    const edge = h.hook.separator()
    h.el.getBoundingClientRect = () => ({ left: 0, right: 1008, width: 1008 })
    edge.getBoundingClientRect = () => ({ width: 8 })
    pointer(h, edge, "pointerdown", 350)
    pointer(h, edge, "pointermove", 600, 2)
    assert.equal(h.hook.value, 35)
    pointer(h, edge, "pointermove", 600)
    assert.equal(h.hook.value, 60)
    pointer(h, edge, "pointerup", 600)
    assert.equal(h.window.localStorage.getItem("lui-split-pane:project"), "60")
    pointer(h, edge, "pointermove", 700)
    assert.equal(h.hook.value, 60)
    pointer(h, edge, "pointerdown", 600)
    h.hook.beforeUpdate()
    h.el.querySelector('[data-part="primary"]').removeAttribute("style")
    h.hook.updated()
    assert.equal(h.el.querySelector('[data-part="primary"]').style.getPropertyValue("--lantern-split-size"), "0.6")
    pointer(h, edge, "pointermove", 700)
    assert.equal(h.hook.value, 60)
    h.hook.destroyed()
    keydown(edge, "Home")
    assert.equal(h.hook.value, 60)
    hooks.LanternSplitPane.destroyed.call(Object.assign(Object.create(hooks.LanternSplitPane), { el: h.el }))
  } finally { h.unmount() }
})
