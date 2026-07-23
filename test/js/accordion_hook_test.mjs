import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { afterEach, test } from "node:test"
import { Window } from "happy-dom"

import { LanternAccordion } from "../../priv/static/lantern_ui_hooks.js"

let window

afterEach(() => {
  if (window) window.close()
  window = null
  delete globalThis.document
})

function item(id, { expanded = false, content = "Panel", nested = "" } = {}) {
  return `
    <div id="${id}" data-part="item" data-state="${expanded ? "open" : "closed"}">
      <div role="heading" aria-level="3">
        <button id="${id}-trigger" data-part="trigger" aria-expanded="${expanded}" aria-controls="${id}-panel">
          ${id}
        </button>
      </div>
      <div id="${id}-panel" data-part="panel" role="region" aria-labelledby="${id}-trigger" ${expanded ? "" : "hidden"}>
        ${content}${nested}
      </div>
    </div>
  `
}

function accordion(
  id,
  items,
  { multiple = false, preventAllClosed = false, animationDuration = 300 } = {}
) {
  return `
    <div
      id="${id}"
      phx-hook="LanternAccordion"
      data-multiple="${multiple}"
      data-prevent-all-closed="${preventAllClosed}"
      data-animation-duration="${animationDuration}"
    >
      ${items.join("")}
    </div>
  `
}

function setup(markup, rootId) {
  window = new Window({ url: "http://localhost" })
  globalThis.document = window.document
  document.body.innerHTML = markup
  const root = document.getElementById(rootId)
  const hook = Object.create(LanternAccordion)
  hook.el = root
  hook.mounted()
  return { hook, root }
}

function triggers(root) {
  return Array.from(root.querySelectorAll('[data-part="trigger"]')).filter(
    (trigger) => trigger.closest('[phx-hook="LanternAccordion"]') === root
  )
}

function openStates(root) {
  return triggers(root).map((trigger) => trigger.getAttribute("aria-expanded"))
}

function activateWithKeyboard(trigger, key) {
  trigger.dispatchEvent(new window.KeyboardEvent("keydown", { key, bubbles: true }))
  if (key === " ") trigger.dispatchEvent(new window.KeyboardEvent("keyup", { key, bubbles: true }))
  // Browsers synthesize a click for Enter/Space activation of a native button.
  trigger.click()
}

test("the stylesheet disables accordion transitions for reduced motion", async () => {
  const css = await readFile(new URL("../../priv/static/lantern_ui.css", import.meta.url), "utf8")
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/)
  assert.match(css, /\.lui-accordion-trigger,\s*\.lui-accordion-icon \{ transition: none; \}/)
})

test("click, Enter, and Space activation enforce single-open state", () => {
  const { root } = setup(accordion("single", [item("one"), item("two")]), "single")
  const [one, two] = triggers(root)

  one.click()
  assert.deepEqual(openStates(root), ["true", "false"])
  assert.equal(document.getElementById("one-panel").hidden, false)

  activateWithKeyboard(two, "Enter")
  assert.deepEqual(openStates(root), ["false", "true"])

  activateWithKeyboard(two, " ")
  assert.deepEqual(openStates(root), ["false", "false"])
  assert.equal(document.getElementById("two-panel").hidden, true)
})

test("ArrowUp/ArrowDown/Home/End wrap focus among owned headers", () => {
  const { root } = setup(accordion("focus", [item("one"), item("two"), item("three")]), "focus")
  const [one, two, three] = triggers(root)

  one.focus()
  one.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowUp", bubbles: true }))
  assert.equal(document.activeElement, three)

  three.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, one)

  one.dispatchEvent(new window.KeyboardEvent("keydown", { key: "End", bubbles: true }))
  assert.equal(document.activeElement, three)

  three.dispatchEvent(new window.KeyboardEvent("keydown", { key: "Home", bubbles: true }))
  assert.equal(document.activeElement, one)

  two.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, three)
})

test("multiple mode and prevent-all-closed update aria-disabled with operability", () => {
  const markup = accordion("multiple", [item("one"), item("two")], {
    multiple: true,
    preventAllClosed: true,
  })
  const { root } = setup(markup, "multiple")
  const [one, two] = triggers(root)

  assert.deepEqual(openStates(root), ["true", "false"])
  assert.equal(one.getAttribute("aria-disabled"), "true")
  one.click()
  assert.deepEqual(openStates(root), ["true", "false"])

  two.click()
  assert.deepEqual(openStates(root), ["true", "true"])
  assert.equal(one.hasAttribute("aria-disabled"), false)
  assert.equal(two.hasAttribute("aria-disabled"), false)

  one.click()
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(two.getAttribute("aria-disabled"), "true")
})

test("nested accordions isolate events, state, panels, and focus", () => {
  const nested = accordion("inner", [item("inner-one"), item("inner-two")], { multiple: true })
  const markup = accordion("outer", [item("outer-one", { nested }), item("outer-two")])
  const { hook: outerHook, root: outer } = setup(markup, "outer")
  const inner = document.getElementById("inner")
  const innerHook = Object.create(LanternAccordion)
  innerHook.el = inner
  innerHook.mounted()

  const [outerOne, outerTwo] = triggers(outer)
  const [innerOne, innerTwo] = triggers(inner)

  innerOne.click()
  assert.deepEqual(openStates(inner), ["true", "false"])
  assert.deepEqual(openStates(outer), ["false", "false"])

  innerTwo.focus()
  innerTwo.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }))
  assert.equal(document.activeElement, innerOne)

  outerTwo.click()
  assert.deepEqual(openStates(outer), ["false", "true"])
  assert.deepEqual(openStates(inner), ["true", "false"])
  assert.equal(document.getElementById("outer-one-panel").hidden, true)

  innerHook.destroyed()
  outerHook.destroyed()
})

test("generated root/item id changes restore state and focus by owned item position", () => {
  const markup = accordion("accordion-1", [item("accordion-item-2"), item("accordion-item-3")])
  const { hook, root } = setup(markup, "accordion-1")
  const [, second] = triggers(root)

  second.click()
  second.focus()
  assert.deepEqual(openStates(root), ["false", "true"])
  hook.beforeUpdate()

  root.id = "accordion-20"
  root.innerHTML = [item("accordion-item-21", { expanded: true }), item("accordion-item-22")].join("")
  hook.updated()

  const [newFirst, newSecond] = triggers(root)
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(document.getElementById("accordion-item-21-panel").hidden, true)
  assert.equal(document.getElementById("accordion-item-22-panel").hidden, false)
  assert.equal(document.activeElement, newSecond)
  assert.equal(newFirst.getAttribute("aria-controls"), "accordion-item-21-panel")
})

test("disconnect/reconnect survives regenerated ids and restores focused header", () => {
  const { hook, root } = setup(
    accordion("accordion-30", [item("accordion-item-31"), item("accordion-item-32")]),
    "accordion-30"
  )
  const [, second] = triggers(root)
  second.click()
  second.focus()
  hook.disconnected()

  root.id = "accordion-40"
  root.innerHTML = [item("accordion-item-41", { expanded: true }), item("accordion-item-42")].join(
    ""
  )
  document.body.focus()

  hook.reconnected()
  const [, secondAfterServer] = triggers(root)
  assert.deepEqual(openStates(root), ["false", "true"])
  assert.equal(document.activeElement, secondAfterServer)
})
