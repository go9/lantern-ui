import assert from "node:assert/strict"
import test from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"

test("overview collapse keeps aria-expanded synchronized with visibility state", () => {
  const mount = mountHook(
    hooks.LanternCollapse,
    '<section id="overview"><button type="button" data-part="collapse-toggle" aria-controls="overview-body"></button><div id="overview-body" data-part="collapse-body">Summary</div></section>',
    { rootId: "overview" },
  )
  const toggle = mount.el.querySelector('[data-part="collapse-toggle"]')

  assert.equal(toggle.getAttribute("aria-expanded"), "true")
  toggle.click()
  assert.equal(mount.el.hasAttribute("data-collapsed"), true)
  assert.equal(toggle.getAttribute("aria-expanded"), "false")
  toggle.click()
  assert.equal(mount.el.hasAttribute("data-collapsed"), false)
  assert.equal(toggle.getAttribute("aria-expanded"), "true")

  mount.unmount()
})
