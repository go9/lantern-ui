// `LanternMediaTile` — selectable media tile interactions and keyboard triggers

import assert from "node:assert/strict"
import test from "node:test"

import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

function mountTile(html, options = {}) {
  const mount = mountHook(
    hooks.LanternMediaTile,
    html,
    { rootId: "tile-1", ...options }
  )
  const pushed = []
  mount.hook.pushEvent = (event, payload) => pushed.push({ event, payload })
  return { ...mount, pushed }
}

function click(el, init = {}) {
  const win = el.ownerDocument.defaultView
  el.dispatchEvent(new win.MouseEvent("click", { bubbles: true, cancelable: true, button: 0, ...init }))
}

test("clicking a selectable tile pushes the select event", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile lui-media-tile-selectable" data-selectable="true" data-selected="false" data-tile-select="toggle_item" phx-hook="LanternMediaTile">
      <div class="lui-media-tile-well">
        <div class="lui-media-tile-selection" data-part="selection">
          <button type="button" class="lui-media-tile-checkbox" role="checkbox" tabindex="0" aria-checked="false"></button>
        </div>
        <img class="lui-media-tile-image" src="/img.jpg" alt="Test image" />
      </div>
      <div class="lui-media-tile-caption">
        <span id="title">Sample Title</span>
      </div>
    </article>
  `)

  click(m.document.getElementById("title"))
  assert.deepEqual(m.pushed, [{ event: "toggle_item", payload: { id: "tile-1", selected: true } }])
  m.unmount()
})

test("clicks on interactive buttons, links, or ignored elements do not toggle selection", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile" data-selectable="true" data-selected="false" data-tile-select="toggle_item">
      <div class="lui-media-tile-well">
        <button id="favorite-btn" type="button">Fav</button>
      </div>
      <div class="lui-media-tile-caption">
        <a id="detail-link" href="/item">Details</a>
        <span id="ignore-elem" data-tile-ignore>Tag</span>
      </div>
    </article>
  `)

  for (const id of ["favorite-btn", "detail-link", "ignore-elem"]) {
    click(m.document.getElementById(id))
  }

  assert.deepEqual(m.pushed, [])
  m.unmount()
})

test("Space and Enter on the focused checkbox toggle selection", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile lui-media-tile-selectable" data-selectable="true" data-selected="false" data-tile-select="toggle_item" phx-hook="LanternMediaTile">
      <div class="lui-media-tile-well">
        <div class="lui-media-tile-selection" data-part="selection">
          <button type="button" class="lui-media-tile-checkbox" role="checkbox" tabindex="0" aria-checked="false"></button>
        </div>
      </div>
    </article>
  `)

  const checkbox = m.document.querySelector('[role="checkbox"]')
  keydown(checkbox, " ")
  assert.deepEqual(m.pushed, [{ event: "toggle_item", payload: { id: "tile-1", selected: true } }])

  // With tile selected, next press should send selected: false
  m.document.getElementById("tile-1").dataset.selected = "true"
  keydown(checkbox, "Enter")
  assert.deepEqual(m.pushed, [
    { event: "toggle_item", payload: { id: "tile-1", selected: true } },
    { event: "toggle_item", payload: { id: "tile-1", selected: false } }
  ])

  m.unmount()
})

test("non-selectable tiles ignore clicks and keys", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile" data-selectable="false" data-selected="false">
      <div class="lui-media-tile-caption"><span id="title">Item</span></div>
    </article>
  `)

  click(m.document.getElementById("title"))
  keydown(m.document.getElementById("tile-1"), "Enter")
  assert.deepEqual(m.pushed, [])
  m.unmount()
})

test("a failed image reveals the already-rendered empty state", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile lui-media-tile-selectable" data-selectable="true" data-selected="false" phx-hook="LanternMediaTile">
      <div class="lui-media-tile-well">
        <div class="lui-media-tile-empty" data-part="empty" hidden>No image</div>
        <img data-part="image" src="/missing.jpg" alt="Missing" />
      </div>
    </article>
  `)
  const image = m.document.querySelector('[data-part="image"]')
  image.dispatchEvent(new m.window.Event("error", { bubbles: false }))
  assert.equal(image.hidden, true)
  assert.equal(m.document.querySelector('[data-part="empty"]').hidden, false)
  assert.equal(m.document.getElementById("tile-1").dataset.empty, "true")
  m.unmount()
})

test("destroyed cleanly unhooks event listeners", () => {
  const m = mountTile(`
    <article id="tile-1" class="lui-media-tile" data-selectable="true" data-selected="false" data-tile-select="toggle_item">
      <div class="lui-media-tile-caption"><span id="title">Item</span></div>
    </article>
  `)

  m.hook.destroyed()
  click(m.document.getElementById("title"))
  assert.deepEqual(m.pushed, [])
  m.unmount()
})
