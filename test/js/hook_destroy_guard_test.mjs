import assert from "node:assert/strict"
import { test } from "node:test"
import { hooks, mountHook } from "./helpers/dom.mjs"

// A LiveView redirect destroys every hook, including those whose mounted()
// returned early (no trigger/panel) before setting up their cleanup list.
// destroyed() must never throw, or the whole navigation aborts.
for (const name of ["LanternOverlay", "LanternCommand", "LanternMenubar"]) {
  test(`${name}.destroyed does not throw on a root that never fully mounted`, () => {
    const hook = hooks[name]
    if (!hook) return
    const ctx = mountHook(hook, '<div id="root" phx-hook="' + name + '"></div>', { rootId: "root" })
    assert.doesNotThrow(() => ctx.unmount())
  })
}
