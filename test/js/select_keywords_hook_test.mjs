// Searchable `LanternSelect` (legacy path) with per-option `keywords`: hidden
// search terms such as a printed barcode. A wedge scanner types the code into
// the search box and presses Enter, so the keyword must filter like the label
// and an exact keyword must win over the first visible match.

import assert from "node:assert/strict"
import test from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"

const option = (value, label, keywords = "") =>
  `<button type="button" data-part="option" data-value="${value}" data-keywords="${keywords}" aria-selected="false">` +
  `<span class="lui-select-option-label">${label}</span></button>`

const fixture = `
  <div id="loc-select" class="lui-select">
    <select data-part="native" name="loc">
      <option value=""></option><option value="1">a</option><option value="12">b</option><option value="120">c</option>
    </select>
    <button type="button" id="loc" data-part="toggle"><span data-part="label"></span></button>
    <div data-part="panel" hidden>
      <input type="text" data-part="search-input" />
      <div data-part="options">
        ${option("1", "Garage / Shelf 1", "loc-1")}
        ${option("120", "Garage / Shelf 120", "loc-120")}
        ${option("12", "Attic / Bin 12", "loc-12\nbin-twelve")}
      </div>
      <p data-part="no-results" hidden>No results</p>
    </div>
  </div>`

// Opened by flag, not show(): show() starts async panel positioning that
// outlives the test's DOM.
function mount() {
  const m = mountHook(hooks.LanternSelect, fixture, { rootId: "loc-select" })
  m.hook.open = true
  globalThis.Event = m.window.Event // setNative() fires bare `new Event(...)`
  return m
}

function typeAndEnter(m, text) {
  const { window } = m
  const search = m.el.querySelector('[data-part="search-input"]')
  search.value = text
  search.dispatchEvent(new window.Event("input", { bubbles: true }))
  search.dispatchEvent(new window.KeyboardEvent("keydown", { key: "Enter", bubbles: true }))
}

test("a keyword filters like the label", () => {
  const m = mount()
  const search = m.el.querySelector('[data-part="search-input"]')
  search.value = "BIN-TW"
  search.dispatchEvent(new m.window.Event("input", { bubbles: true }))

  const visible = [...m.el.querySelectorAll('[data-part="option"]')].filter((o) => !o.hidden)
  assert.deepEqual(visible.map((o) => o.dataset.value), ["12"])
  m.unmount()
})

test("Enter on an exact keyword picks that option, not the first match", () => {
  const m = mount()
  typeAndEnter(m, "LOC-12")
  assert.equal(m.el.querySelector('[data-part="native"]').value, "12")
  m.unmount()
})

test("Enter without an exact keyword still picks the first visible option", () => {
  const m = mount()
  typeAndEnter(m, "garage")
  assert.equal(m.el.querySelector('[data-part="native"]').value, "1")
  m.unmount()
})
