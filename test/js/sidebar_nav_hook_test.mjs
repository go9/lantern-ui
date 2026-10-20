// LanternSidebar: keyed disclosure persistence, row actions (pin) and the
// mobile drawer as a modal sheet. Real hook code against jsdom (see
// helpers/dom.mjs); matchMedia is the harness stub, i.e. a narrow screen.
import assert from "node:assert/strict"
import { test } from "node:test"

import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

const SHELL = `
<div id="shell">
  <header class="lui-appbar">
    <button data-part="sidebar-toggle" aria-expanded="false">menu</button>
    <div class="lui-appbar-brand"><a href="/">Brand</a></div>
    <div class="lui-appbar-actions"><button id="account">Account</button></div>
  </header>
  <div class="lui-app-body">
    <div data-part="sidebar-scrim"></div>
    <aside data-part="sidebar" aria-label="Navigation">
      <button data-part="sidebar-close" aria-label="Close navigation">x</button>
      <div class="lui-app-sidebar-header">
        <button id="org" aria-expanded="false">Org</button>
      </div>
      <div class="lui-app-nav">
        <div class="lui-nav-group" id="pinned">
          <div class="lui-nav-sub" id="p-acme">
            <div class="lui-nav-row" data-part="nav-row">
              <a class="lui-nav-item" href="/acme" id="acme-link">Acme</a>
              <button data-part="nav-disclosure" aria-expanded="false" aria-controls="p-acme-subnav"
                data-storage-key="u1:o1:p-acme" id="acme-disclosure">v</button>
              <button data-part="nav-action" aria-pressed="true" id="acme-pin">pin</button>
            </div>
            <div id="p-acme-subnav" data-part="nav-subpanel"><a class="lui-nav-item" href="/acme/runs">Runs</a></div>
          </div>
          <div class="lui-nav-row" data-part="nav-row" id="p-beta">
            <a class="lui-nav-item" href="/beta">Beta</a>
            <button data-part="nav-action" aria-pressed="true" id="beta-pin">pin</button>
          </div>
          <div class="lui-nav-row" data-part="nav-row" id="p-gamma">
            <a class="lui-nav-item" href="/gamma">Gamma</a>
            <button data-part="nav-action" aria-pressed="true" id="gamma-pin">pin</button>
          </div>
        </div>
      </div>
    </aside>
    <main class="lui-app-main"><button id="page-button">Page</button></main>
  </div>
</div>`

const mount = () => mountHook(hooks.LanternSidebar, SHELL, { rootId: "shell" })

const $ = (m, sel) => m.document.querySelector(sel)
const click = (el) => el.dispatchEvent(new el.ownerDocument.defaultView.MouseEvent("click", { bubbles: true }))
const open = (m) => click($(m, "[data-part=sidebar-toggle]"))

// mountHook keeps a localStorage already on globalThis, so a test can hand the
// hook a store that is pre-filled, or one that throws (private mode, policy).
function withStorage(storage, fn) {
  const saved = globalThis.localStorage
  globalThis.localStorage = storage
  try {
    return fn()
  } finally {
    globalThis.localStorage = saved
  }
}

const memoryStorage = (entries = {}) => {
  const map = new Map(Object.entries(entries))
  return {
    getItem: (k) => (map.has(k) ? map.get(k) : null),
    setItem: (k, v) => map.set(k, String(v)),
    removeItem: (k) => map.delete(k),
    map,
  }
}

test("stored disclosure state is applied on mount; malformed values are ignored", () => {
  withStorage(memoryStorage({ "lui-nav:u1:o1:p-acme": "true" }), () => {
    const m = mount()
    assert.equal($(m, "#acme-disclosure").getAttribute("aria-expanded"), "true")
    assert.equal($(m, "#acme-disclosure").hasAttribute("data-expanded"), true)
    m.unmount()
  })
  withStorage(memoryStorage({ "lui-nav:u1:o1:p-acme": "{\"open\":1}" }), () => {
    const m = mount()
    assert.equal($(m, "#acme-disclosure").getAttribute("aria-expanded"), "false")
    assert.equal($(m, "#acme-disclosure").hasAttribute("data-expanded"), false)
    m.unmount()
  })
})

test("a stored open state survives a remount under the same key only", () => {
  const m = mount()
  const btn = $(m, "#acme-disclosure")
  click(btn)
  assert.equal(m.window.localStorage.getItem("lui-nav:u1:o1:p-acme"), "true", "click persists the next state")

  // Same storage, a fresh row rendered closed by the server: the stored choice wins.
  const fresh = btn.cloneNode(true)
  fresh.setAttribute("aria-expanded", "false")
  fresh.removeAttribute("data-expanded")
  btn.replaceWith(fresh)
  m.hook.updated()
  assert.equal(fresh.getAttribute("aria-expanded"), "true")
  assert.equal(fresh.hasAttribute("data-expanded"), true)

  // Another account/org composes another key: nothing leaks across.
  const other = fresh.cloneNode(true)
  other.setAttribute("data-storage-key", "u2:o1:p-acme")
  other.setAttribute("aria-expanded", "false")
  other.removeAttribute("data-expanded")
  fresh.replaceWith(other)
  m.hook.updated()
  assert.equal(other.getAttribute("aria-expanded"), "false")

  // Malformed stored value: ignored, server default stands.
  m.window.localStorage.setItem("lui-nav:u3:o1:p-acme", "yes")
  other.setAttribute("data-storage-key", "u3:o1:p-acme")
  m.hook.updated()
  assert.equal(other.getAttribute("aria-expanded"), "false")
  m.unmount()
})

test("closing a disclosure persists false, and the click leaves the drawer open", () => {
  const m = mountHook(hooks.LanternSidebar, SHELL.replace('aria-expanded="false" aria-controls', 'aria-expanded="true" data-expanded aria-controls'), { rootId: "shell" })
  open(m)
  click($(m, "#acme-disclosure"))
  assert.equal(m.window.localStorage.getItem("lui-nav:u1:o1:p-acme"), "false")
  assert.equal(m.el.hasAttribute("data-nav-open"), true, "a disclosure is not a destination")
  m.unmount()
})

test("blocked storage never breaks the hook", () => {
  const blocked = {
    getItem() {
      throw new Error("SecurityError")
    },
    setItem() {
      throw new Error("SecurityError")
    },
  }
  withStorage(blocked, () => {
    const m = mount()
    click($(m, "#acme-disclosure"))
    open(m)
    assert.equal(m.el.hasAttribute("data-nav-open"), true, "the drawer still works")
    m.unmount()
  })
})

test("open drawer is a labelled modal: role, inert background, focus inside", () => {
  const m = mount()
  const toggle = $(m, "[data-part=sidebar-toggle]")
  toggle.focus()
  open(m)
  const aside = $(m, "aside")
  assert.equal(aside.getAttribute("role"), "dialog")
  assert.equal(aside.getAttribute("aria-modal"), "true")
  assert.equal(aside.getAttribute("aria-label"), "Navigation")
  assert.equal($(m, "main").hasAttribute("inert"), true)
  assert.equal($(m, ".lui-appbar-brand").hasAttribute("inert"), true)
  assert.equal($(m, ".lui-appbar-actions").hasAttribute("inert"), true)
  assert.equal(toggle.hasAttribute("inert"), false, "the hamburger still closes it on tap")
  assert.equal(toggle.getAttribute("aria-expanded"), "true")
  assert.equal(m.document.activeElement, $(m, "[data-part=sidebar-close]"), "focus enters")

  // A patch re-renders the root and strips hook attributes: they come back.
  aside.removeAttribute("role")
  $(m, "main").removeAttribute("inert")
  m.hook.updated()
  assert.equal(aside.getAttribute("role"), "dialog")
  assert.equal($(m, "main").hasAttribute("inert"), true)
  m.unmount()
})

test("Tab wraps inside the drawer", () => {
  const m = mount()
  open(m)
  const items = [...$(m, "aside").querySelectorAll("a[href], button")]
  const last = items[items.length - 1]
  last.focus()
  const ev = keydown(last, "Tab")
  assert.equal(ev.defaultPrevented, true)
  assert.equal(m.document.activeElement, items[0])
  const back = keydown(items[0], "Tab", { shiftKey: true })
  assert.equal(back.defaultPrevented, true)
  assert.equal(m.document.activeElement, last)
  m.unmount()
})

test("close button, Escape and scrim close it, restore focus and release the background", () => {
  for (const close of [
    (m) => click($(m, "[data-part=sidebar-close]")),
    (m) => keydown($(m, "#acme-link"), "Escape"),
    (m) => click($(m, "[data-part=sidebar-scrim]")),
  ]) {
    const m = mount()
    const toggle = $(m, "[data-part=sidebar-toggle]")
    toggle.focus()
    open(m)
    close(m)
    assert.equal(m.el.hasAttribute("data-nav-open"), false)
    assert.equal($(m, "aside").hasAttribute("role"), false)
    assert.equal($(m, "aside").hasAttribute("aria-modal"), false)
    assert.equal($(m, "main").hasAttribute("inert"), false)
    assert.equal($(m, ".lui-appbar-brand").hasAttribute("inert"), false)
    assert.equal(m.document.activeElement, toggle, "focus restored to the hamburger")
    m.unmount()
  }
})

test("a destination link closes the drawer; a pin action keeps it open", () => {
  const m = mount()
  open(m)
  click($(m, "#beta-pin"))
  assert.equal(m.el.hasAttribute("data-nav-open"), true)
  click($(m, "#acme-link"))
  assert.equal(m.el.hasAttribute("data-nav-open"), false)
  m.unmount()
})

test("Escape belongs to a menu open inside the drawer", () => {
  const m = mount()
  open(m)
  $(m, "#org").setAttribute("aria-expanded", "true")
  keydown($(m, "#org"), "Escape")
  assert.equal(m.el.hasAttribute("data-nav-open"), true, "the menu closes first")
  $(m, "#org").setAttribute("aria-expanded", "false")
  keydown($(m, "#org"), "Escape")
  assert.equal(m.el.hasAttribute("data-nav-open"), false)
  m.unmount()
})

test("an existing host inert is left alone on close", () => {
  const m = mount()
  $(m, ".lui-appbar-actions").setAttribute("inert", "")
  open(m)
  click($(m, "[data-part=sidebar-close]"))
  assert.equal($(m, ".lui-appbar-actions").hasAttribute("inert"), true)
  m.unmount()
})

test("destroy while open releases the background and leaves no Escape listener", () => {
  const m = mount()
  open(m)
  const main = $(m, "main")
  const aside = $(m, "aside")
  const doc = m.document
  m.hook.destroyed()
  assert.equal(main.hasAttribute("inert"), false)
  assert.equal(aside.hasAttribute("role"), false)
  // The destroyed hook no longer answers Escape.
  m.hook.navOpen = true
  m.el.setAttribute("data-nav-open", "")
  keydown(doc.body, "Escape")
  assert.equal(m.el.hasAttribute("data-nav-open"), true, "Escape listener was removed")
  m.el.removeAttribute("data-nav-open")
  m.hook.navOpen = false
  // A second mount on the same element (reconnect) works normally.
  m.hook.mounted()
  open(m)
  keydown(doc.body, "Escape")
  assert.equal(m.el.hasAttribute("data-nav-open"), false)
  m.hook.navOpen = false
  m.unmount()
})

test("unpinning a row moves focus to the pin now in its place", () => {
  const m = mount()
  const pin = $(m, "#beta-pin")
  pin.focus()
  click(pin)
  $(m, "#p-beta").remove() // the server patch drops the unpinned row
  assert.equal(m.document.activeElement, m.document.body)
  m.hook.updated()
  assert.equal(m.document.activeElement, $(m, "#gamma-pin"))
  m.unmount()
})

test("unpinning the last row falls back to the previous pin, then the group's first link", () => {
  const m = mount()
  const pin = $(m, "#gamma-pin")
  pin.focus()
  click(pin)
  $(m, "#p-gamma").remove()
  m.hook.updated()
  assert.equal(m.document.activeElement, $(m, "#beta-pin"))

  for (const id of ["#acme-pin", "#beta-pin"]) {
    const p = $(m, id)
    p.focus()
    click(p)
    p.closest(".lui-nav-row").querySelector("button[data-part=nav-action]").remove()
    m.hook.updated()
  }
  assert.equal(m.document.activeElement, $(m, "#acme-link"))
  m.unmount()
})

test("unpinning a row that stays (the current project) keeps focus on its button", () => {
  const m = mount()
  const pin = $(m, "#acme-pin")
  pin.focus()
  click(pin)
  pin.setAttribute("aria-pressed", "false")
  m.hook.updated()
  assert.equal(m.document.activeElement, pin)
  m.unmount()
})

test("focus recovery never steals focus the user already moved", () => {
  const m = mount()
  const pin = $(m, "#beta-pin")
  pin.focus()
  click(pin)
  $(m, "#page-button").focus()
  $(m, "#p-beta").remove()
  m.hook.updated()
  assert.equal(m.document.activeElement, $(m, "#page-button"))
  m.unmount()
})

test("a row the action only moved (reorder) gets its focus back", () => {
  const m = mount()
  const pin = $(m, "#acme-pin")
  pin.focus()
  click(pin)
  // A reorder detaches and re-inserts the node, which blurs it.
  const row = $(m, "#p-acme")
  row.parentElement.append(row)
  assert.equal(m.document.activeElement, m.document.body)
  m.hook.updated()
  assert.equal(m.document.activeElement, pin)
  m.unmount()
})
