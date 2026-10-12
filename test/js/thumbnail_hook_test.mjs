// `LanternThumbnail` — an image that fails to load shows the same placeholder
// as a row with no image, so rows keep one look (#3716 1.5).

import assert from "node:assert/strict"
import test from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"

const html = (src) =>
  `<button id="th" class="lui-thumbnail" data-preview-src="${src}" data-preview-alt="Ada"><img src="${src}" alt=""></button>`

test("a failed image load marks the thumbnail broken and suppresses the preview", () => {
  const m = mountHook(hooks.LanternThumbnail, html("https://x.test/a.png"), { rootId: "th" })
  const img = m.el.querySelector("img")
  img.dispatchEvent(new m.window.Event("error"))
  assert.equal(m.el.hasAttribute("data-broken"), true)
  m.el.dispatchEvent(new m.window.Event("mouseenter"))
  assert.equal(m.document.querySelector(".lui-thumbnail-preview"), null)
  m.unmount()
})

test("the broken mark survives a server patch of the same source and clears on a new one", () => {
  const m = mountHook(hooks.LanternThumbnail, html("https://x.test/a.png"), { rootId: "th" })
  m.el.querySelector("img").dispatchEvent(new m.window.Event("error"))
  m.el.removeAttribute("data-broken") // LiveView patch drops client-only attributes
  m.hook.updated()
  assert.equal(m.el.hasAttribute("data-broken"), true)
  m.el.dataset.previewSrc = "https://x.test/b.png"
  m.hook.updated()
  assert.equal(m.el.hasAttribute("data-broken"), false)
  m.unmount()
})

test("an image swapped in by a patch is still watched", () => {
  const m = mountHook(hooks.LanternThumbnail, html("https://x.test/a.png"), { rootId: "th" })
  m.el.dataset.previewSrc = "https://x.test/b.png"
  m.el.innerHTML = '<img src="https://x.test/b.png" alt="">'
  m.hook.updated()
  m.el.querySelector("img").dispatchEvent(new m.window.Event("error"))
  assert.equal(m.el.hasAttribute("data-broken"), true)
  m.unmount()
})
