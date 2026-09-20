import assert from "node:assert/strict"
import test from "node:test"
import { JSDOM } from "jsdom"

import { hooks, keydown, patchLayoutGaps, sleep } from "./helpers/dom.mjs"

const { installBehaviours } = hooks

function withDoc(html) {
  const dom = new JSDOM(`<!doctype html><html><body>${html}</body></html>`, {
    pretendToBeVisual: true,
    url: "https://lantern.test/",
  })
  patchLayoutGaps(dom.window)
  const previous = { document: globalThis.document, window: globalThis.window }
  globalThis.document = dom.window.document
  globalThis.window = dom.window
  installBehaviours(dom.window.document)
  return {
    window: dom.window,
    document: dom.window.document,
    unmount() {
      globalThis.document = previous.document
      globalThis.window = previous.window
      dom.window.close()
    },
  }
}

test("list nav: j/k, arrows, Home/End, Enter clicks the row link", async () => {
  const ctx = withDoc(`
    <ul data-lantern-list-nav>
      <li data-lantern-list-item><a href="#one">One</a></li>
      <li data-lantern-list-item><a href="#two">Two</a></li>
      <li data-lantern-list-item><a href="#three">Three</a></li>
    </ul>
  `)
  try {
    const items = [...ctx.document.querySelectorAll("[data-lantern-list-item]")]
    assert.equal(items[0].tabIndex, 0)
    assert.equal(items[1].tabIndex, -1)
    items[0].focus()

    keydown(items[0], "j")
    assert.equal(ctx.document.activeElement, items[1])
    keydown(items[1], "ArrowDown")
    assert.equal(ctx.document.activeElement, items[2])
    keydown(items[2], "k")
    assert.equal(ctx.document.activeElement, items[1])
    keydown(items[1], "Home")
    assert.equal(ctx.document.activeElement, items[0])
    keydown(items[0], "End")
    assert.equal(ctx.document.activeElement, items[2])

    let clicked = null
    items[2].querySelector("a").addEventListener("click", (e) => {
      e.preventDefault()
      clicked = e.currentTarget.getAttribute("href")
    })
    keydown(items[2], "Enter")
    assert.equal(clicked, "#three")
  } finally {
    ctx.unmount()
  }
})

test("persist: details open state round-trips through localStorage", async () => {
  const ctx = withDoc(`<div id="host"></div>`)
  try {
    ctx.document.getElementById("host").innerHTML =
      `<details data-lantern-persist="demo:box"><summary>Box</summary><p>Hi</p></details>`
    await sleep(10)
    const details = ctx.document.querySelector("details")
    assert.equal(details.open, false)
    details.open = true
    details.dispatchEvent(new ctx.window.Event("toggle", { bubbles: true }))
    assert.equal(ctx.window.localStorage.getItem("lantern:persist:demo:box"), "open")

    details.remove()
    ctx.document.getElementById("host").innerHTML =
      `<details data-lantern-persist="demo:box"><summary>Box</summary><p>Hi</p></details>`
    await sleep(10)
    assert.equal(ctx.document.querySelector("details").open, true)
  } finally {
    ctx.unmount()
  }
})

test("persist: toggle button writes closed and restore survives a storage throw", async () => {
  const ctx = withDoc(`
    <div data-lantern-persist="demo:side" data-open="true">
      <button type="button" data-lantern-persist-toggle aria-expanded="true">Toggle</button>
      <div data-lantern-persist-panel>Panel</div>
    </div>
  `)
  try {
    const root = ctx.document.querySelector("[data-lantern-persist]")
    const toggle = ctx.document.querySelector("[data-lantern-persist-toggle]")
    const panel = ctx.document.querySelector("[data-lantern-persist-panel]")
    assert.equal(root.dataset.open, "true")
    toggle.click()
    assert.equal(root.dataset.open, "false")
    assert.equal(toggle.getAttribute("aria-expanded"), "false")
    assert.equal(panel.hidden, true)
    assert.equal(ctx.window.localStorage.getItem("lantern:persist:demo:side"), "closed")

    ctx.window.localStorage.setItem = () => {
      throw new Error("quota")
    }
    toggle.click()
    assert.equal(root.dataset.open, "true")
  } finally {
    ctx.unmount()
  }
})

test("j/k in an input inside the list do not move focus", () => {
  const ctx = withDoc(`
    <div data-lantern-list-nav>
      <div data-lantern-list-item><input value="x" /></div>
      <div data-lantern-list-item>Other</div>
    </div>
  `)
  try {
    const items = [...ctx.document.querySelectorAll("[data-lantern-list-item]")]
    const input = items[0].querySelector("input")
    input.focus()
    keydown(input, "j")
    assert.equal(ctx.document.activeElement, input)
  } finally {
    ctx.unmount()
  }
})

test("hooks bundle inlines floating-ui and keeps the public import surface", async () => {
  const { readFile } = await import("node:fs/promises")
  const bundle = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")
  const source = await readFile(new URL("../../assets/js/lantern_ui_hooks.js", import.meta.url), "utf8")
  assert.match(source, /from "@floating-ui\/dom"/)
  assert.doesNotMatch(bundle, /from "@floating-ui\/dom"/)
  assert.match(bundle, /export \{[\s\S]*\bHooks\b/)
  assert.match(bundle, /export \{[\s\S]*installBehaviours/)
})
