import assert from "node:assert/strict"
import test from "node:test"

import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

function mountChrome({ expanded = false, url = "https://lantern.test/records?sort=name&view=cards" } = {}) {
  const m = mountHook(
    hooks.LanternTableChrome,
    `<div id="chrome" data-path="/records" data-table-id="records" data-expandable="true" data-expanded="${expanded}"></div>`,
    { rootId: "chrome" }
  )
  m.window.history.replaceState({}, "", url)
  const patches = []
  m.document.addEventListener("click", (event) => {
    if (event.target.matches("a[data-phx-link]")) {
      event.preventDefault()
      patches.push(new URL(event.target.href))
    }
  })
  return { ...m, patches }
}

test("Shift+E toggles expand while preserving the query and Escape exits", () => {
  const m = mountChrome()
  const expanded = keydown(m.document.body, "E", { shiftKey: true })
  assert.equal(expanded.defaultPrevented, true)
  assert.equal(m.patches[0].searchParams.get("expand"), "1")
  assert.equal(m.patches[0].searchParams.get("sort"), "name")
  assert.equal(m.patches[0].searchParams.get("view"), "cards")

  m.hook.expanded = true
  const exited = keydown(m.document.body, "Escape")
  assert.equal(exited.defaultPrevented, true)
  assert.equal(m.patches[1].searchParams.has("expand"), false)
  assert.equal(m.patches[1].searchParams.get("sort"), "name")
  m.unmount()
})

test("Shift+E is ignored in editable targets", () => {
  const m = mountChrome()
  const input = m.document.createElement("input")
  m.el.append(input)
  const event = keydown(input, "E", { shiftKey: true })
  assert.equal(event.defaultPrevented, false)
  assert.equal(m.patches.length, 0)
  m.unmount()
})

test("Escape in an inner input or open overlay does not exit expanded mode", () => {
  const m = mountChrome({ expanded: true })
  const input = m.document.createElement("input")
  m.el.append(input)
  const inInput = keydown(input, "Escape")
  assert.equal(inInput.defaultPrevented, false)
  assert.equal(m.patches.length, 0)

  const dialog = m.document.createElement("div")
  dialog.dataset.part = "content"
  dialog.setAttribute("role", "dialog")
  const button = m.document.createElement("button")
  dialog.append(button)
  m.el.append(dialog)
  const inDialog = keydown(button, "Escape")
  assert.equal(inDialog.defaultPrevented, false)
  assert.equal(m.patches.length, 0)
  m.unmount()
})

test("sidebar transient collapse never writes localStorage and restores its prior state", () => {
  const m = mountHook(hooks.LanternSidebar, '<div id="shell"><div data-expandable="true" data-table-id="records"></div><button data-part="sidebar-collapse"></button></div>', {
    rootId: "shell",
  })
  m.document.getElementById("shell").dispatchEvent(
    new m.window.CustomEvent("lantern:table-expand", { bubbles: true, detail: { tableId: "records", expanded: true } })
  )
  m.document.querySelector("[data-table-id=records]").dataset.expanded = "true"
  assert.equal(m.el.hasAttribute("data-collapsed"), true)
  assert.equal(m.el.hasAttribute("data-table-expand"), true)
  assert.equal(m.window.localStorage.getItem("lui-sidebar:shell"), null)
  m.hook.updated()
  assert.equal(m.el.hasAttribute("data-collapsed"), true)

  m.el.dispatchEvent(
    new m.window.CustomEvent("lantern:table-expand", { bubbles: true, detail: { tableId: "records", expanded: false } })
  )
  m.document.querySelector("[data-table-id=records]").dataset.expanded = "false"
  assert.equal(m.el.hasAttribute("data-collapsed"), false)
  assert.equal(m.el.hasAttribute("data-table-expand"), false)
  assert.equal(m.window.localStorage.getItem("lui-sidebar:shell"), null)
  m.unmount()
})

test("manual sidebar toggle during expansion is session-only and survives patches", () => {
  const m = mountHook(hooks.LanternSidebar, '<div id="shell"><div data-expandable="true" data-expanded="true" data-table-id="records"></div><button data-part="sidebar-collapse"></button></div>', {
    rootId: "shell",
  })
  m.window.localStorage.setItem("lui-sidebar:shell", "true")
  m.hook.syncCollapsed()
  m.hook.syncTablesFromDOM()
  assert.equal(m.el.hasAttribute("data-collapsed"), true)

  m.el.dispatchEvent(
    new m.window.CustomEvent("lantern:table-expand", { bubbles: true, detail: { tableId: "records", expanded: true } })
  )
  m.document.querySelector("[data-part=sidebar-collapse]").dispatchEvent(
    new m.window.MouseEvent("click", { bubbles: true })
  )
  assert.equal(m.el.hasAttribute("data-collapsed"), false)
  assert.equal(m.window.localStorage.getItem("lui-sidebar:shell"), "true")
  m.hook.updated()
  assert.equal(m.el.hasAttribute("data-collapsed"), false)

  m.document.querySelector("[data-table-id=records]").dataset.expanded = "false"
  m.el.dispatchEvent(
    new m.window.CustomEvent("lantern:table-expand", { bubbles: true, detail: { tableId: "records", expanded: false } })
  )
  m.hook.updated()
  assert.equal(m.el.hasAttribute("data-collapsed"), false)
  assert.equal(m.window.localStorage.getItem("lui-sidebar:shell"), "true")
  m.unmount()
})
