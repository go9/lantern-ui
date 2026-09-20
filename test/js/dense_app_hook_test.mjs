import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

const { LanternSidePanel, LanternSegmented } = hooks

let harness = null
afterEach(() => {
  harness?.unmount()
  harness = null
})

function remountPanel({ pressed, key = "tickets", persistEvent = "side_panel" }) {
  return mountHook(
    LanternSidePanel,
    `<button id="toggle" type="button" aria-pressed="${pressed}" data-panel-key="${key}" data-event="set_panel" data-persist-event="${persistEvent}"></button>`,
    { rootId: "toggle" }
  )
}

test("LanternSidePanel restores a stored preference that disagrees with aria-pressed", () => {
  harness = remountPanel({ pressed: "false" })
  harness.window.localStorage.setItem("lui-side-panel:tickets", "open")
  harness.pushEvent.length = 0
  harness.hook.mounted()
  assert.deepEqual(harness.pushEvent, [{ event: "set_panel", payload: { open: true } }])
})

test("LanternSidePanel defaults open at 1280px when nothing is stored", () => {
  harness = remountPanel({ pressed: "false", key: "wide" })
  harness.window.localStorage.clear()
  Object.defineProperty(harness.window, "innerWidth", { configurable: true, value: 1440 })
  harness.pushEvent.length = 0
  harness.hook.mounted()
  assert.equal(harness.pushEvent[0].event, "set_panel")
  assert.equal(harness.pushEvent[0].payload.open, true)
})

test("LanternSidePanel defaults closed below 1280px when nothing is stored", () => {
  harness = remountPanel({ pressed: "true", key: "narrow" })
  harness.window.localStorage.clear()
  Object.defineProperty(harness.window, "innerWidth", { configurable: true, value: 800 })
  harness.pushEvent.length = 0
  harness.hook.mounted()
  assert.equal(harness.pushEvent[0].payload.open, false)
})

test("LanternSidePanel persists on updated() and on the server event", () => {
  harness = remountPanel({ pressed: "true", key: "p" })
  harness.el.setAttribute("aria-pressed", "false")
  harness.hook.updated()
  assert.equal(harness.window.localStorage.getItem("lui-side-panel:p"), "closed")

  harness.serverPush("side_panel", { open: true })
  assert.equal(harness.window.localStorage.getItem("lui-side-panel:p"), "open")
})

test("LanternSegmented arrow keys move and click the next segment", () => {
  harness = mountHook(
    LanternSegmented,
    `<div id="scope" role="radiogroup">
      <button type="button" data-part="segment" data-value="all">All</button>
      <button type="button" data-part="segment" data-value="active">Active</button>
      <button type="button" data-part="segment" data-value="backlog">Backlog</button>
    </div>`,
    { rootId: "scope" }
  )

  const clicks = []
  const segs = [...harness.el.querySelectorAll("[data-part=segment]")]
  segs.forEach((el) => el.addEventListener("click", () => clicks.push(el.dataset.value)))
  segs[0].focus()
  keydown(segs[0], "ArrowRight")

  assert.equal(harness.document.activeElement, segs[1])
  assert.deepEqual(clicks, ["active"])

  keydown(segs[1], "End")
  assert.equal(harness.document.activeElement, segs[2])
  assert.deepEqual(clicks, ["active", "backlog"])
})

test("LanternTabs is the same hook as LanternSegmented and also reads data-part=tab", () => {
  assert.equal(hooks.LanternTabs, LanternSegmented)
})
