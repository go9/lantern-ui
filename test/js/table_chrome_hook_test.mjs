// `LanternTableChrome` against a real DOM.
//
// The HEEx tests in `data_table_chrome_test.exs` assert on the markup the
// chrome row renders — the parts, the fields, the `data-keep-filters` payload.
// None of them can run the hook, and the hook is where the URL is actually
// built. A `searchable` filter shipped broken for exactly that reason: it
// renders a `select` component, which keeps its value on a hidden native
// `<select>`, but the hook only ever read `input[data-part="value"]` — the
// shape the datetime and autocomplete controls use. Picking an option silently
// applied nothing. These tests drive the hook and assert on the URL it patches
// to, which is the thing a user is affected by.

import assert from "node:assert/strict"
import test from "node:test"

import { hooks, mountHook } from "./helpers/dom.mjs"

const definition = hooks.LanternTableChrome

/**
 * Mount the chrome row and capture the URLs it patches to instead of letting it
 * click a `data-phx-link` anchor at a LiveSocket that is not there.
 */
function mountChrome(html, { params = {}, keepFilters = [] } = {}) {
  const attrs = [
    `data-path="/settlements"`,
    `data-params='${JSON.stringify(params)}'`,
    `data-keep-filters='${JSON.stringify(keepFilters)}'`,
  ].join(" ")

  const mount = mountHook(definition, `<div id="chrome" ${attrs}>${html}</div>`, { rootId: "chrome" })
  const patched = []
  mount.hook.patch = (url) => patched.push(url)
  return { ...mount, patched, last: () => patched[patched.length - 1] }
}

/** The query string as a list of pairs, so order and repeats stay visible. */
function query(url) {
  return [...new URL(url, "http://test").searchParams.entries()]
}

function change(el) {
  el.dispatchEvent(new el.ownerDocument.defaultView.Event("change", { bubbles: true }))
}

const richSelect = (field, options, { op = "==", multiple = false } = {}) => `
  <div data-part="filter-rich" data-field="${field}" data-op="${op}">
    <select data-part="native" ${multiple ? "multiple" : ""} hidden>
      ${options.map((o) => `<option value="${o}">${o}</option>`).join("")}
    </select>
    <button type="button" data-part="clear">Clear</button>
  </div>`

test("a rich filter applies the value on its native select", () => {
  const mount = mountChrome(richSelect("user_id", ["", "7", "15"]))
  const native = mount.el.querySelector('select[data-part="native"]')

  native.value = "15"
  change(native)

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "user_id"],
    ["filters[0][value]", "15"],
  ])
  mount.unmount()
})

test("a multiple rich filter sends every selected value under op=in", () => {
  const mount = mountChrome(richSelect("status", ["new", "active", "completed"], { op: "in", multiple: true }))
  const native = mount.el.querySelector('select[data-part="native"]')

  native.options[0].selected = true
  native.options[2].selected = true
  change(native)

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "status"],
    ["filters[0][op]", "in"],
    ["filters[0][value][]", "new"],
    ["filters[0][value][]", "completed"],
  ])
  mount.unmount()
})

test("an unset rich filter contributes nothing", () => {
  const mount = mountChrome(
    `<input data-part="search" data-field="search" data-op="ilike" value="" />` +
      richSelect("user_id", ["", "7"])
  )
  const native = mount.el.querySelector('select[data-part="native"]')

  native.value = ""
  change(native)

  assert.deepEqual(query(mount.last()), [])
  mount.unmount()
})

test("filters the row does not own survive a rich filter change", () => {
  const mount = mountChrome(richSelect("user_id", ["", "15"]), {
    params: { "order_by[]": "inserted_at", page: "3" },
    keepFilters: [{ field: "status", op: "==", value: "completed" }],
  })
  const native = mount.el.querySelector('select[data-part="native"]')

  native.value = "15"
  change(native)

  // The tab's filter is kept, the sort is kept, and the page is dropped: a
  // narrower result set has no page 3 to land on.
  assert.deepEqual(query(mount.last()), [
    ["order_by[]", "inserted_at"],
    ["filters[0][field]", "status"],
    ["filters[0][value]", "completed"],
    ["filters[1][field]", "user_id"],
    ["filters[1][value]", "15"],
  ])
  mount.unmount()
})

test("clear-filters resets rich filters through their own control, and patches once", () => {
  const mount = mountChrome(
    richSelect("user_id", ["", "15"]) + `<button type="button" data-part="clear-filters">Clear</button>`
  )
  const native = mount.el.querySelector('select[data-part="native"]')

  native.value = "15"
  change(native)
  assert.equal(mount.patched.length, 1)

  // The clear button each rich filter owns resets its own label and aria state;
  // the hook clicks it rather than reaching past it. That fires a change per
  // filter, which must not each become a patch of its own.
  mount.el.querySelector('[data-part="clear"]').addEventListener("click", () => {
    native.value = ""
    change(native)
  })

  mount.el.querySelector('[data-part="clear-filters"]').click()

  assert.equal(mount.patched.length, 2)
  assert.deepEqual(query(mount.last()), [])
  mount.unmount()
})
