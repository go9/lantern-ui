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

  const mount = mountHook(
    definition,
    `<div id="chrome" ${attrs}><div class="lui-dt-filterpanel-inner">${html}` +
      `<button type="button" data-part="apply-filters">Apply</button></div></div>`,
    { rootId: "chrome" }
  )
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

function apply(mount) {
  mount.el.querySelector('[data-part="apply-filters"]').click()
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
  assert.equal(mount.patched.length, 0, "panel changes are staged")
  apply(mount)

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
  apply(mount)

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
  apply(mount)

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
  apply(mount)

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
  assert.equal(mount.patched.length, 0)

  // The clear button each rich filter owns resets its own label and aria state;
  // the hook clicks it rather than reaching past it. That fires a change per
  // filter, which must not each become a patch of its own.
  mount.el.querySelector('[data-part="clear"]').addEventListener("click", () => {
    native.value = ""
    change(native)
  })

  mount.el.querySelector('[data-part="clear-filters"]').click()

  assert.equal(mount.patched.length, 1)
  assert.deepEqual(query(mount.last()), [])
  mount.unmount()
})

const search = `<input data-part="search" data-field="title" data-op="ilike" value="" />`
const statusSelect = `<select data-part="filter" data-field="status" data-op="==">
  <option value="">All</option><option value="todo">To do</option></select>`

async function typeSearch(mount, value) {
  const input = mount.el.querySelector('[data-part="search"]')
  input.value = value
  input.dispatchEvent(new input.ownerDocument.defaultView.Event("input", { bubbles: true }))
  await new Promise((resolve) => setTimeout(resolve, 350))
}

test("typing a search keeps the status chip, even when its panel select cannot show it", async () => {
  // The chip set status=in_progress, but the panel select has no such option, so
  // it reads "" — the filter would be silently dropped if the select were trusted.
  const mount = mountChrome(search + statusSelect, {
    keepFilters: [{ field: "status", op: null, value: "in_progress", owned: true }],
  })

  await typeSearch(mount, "abc")

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "status"],
    ["filters[0][value]", "in_progress"],
    ["filters[1][field]", "title"],
    ["filters[1][op]", "ilike"],
    ["filters[1][value]", "abc"],
  ])
  mount.unmount()
})

test("a panel control that has a value overrides the kept filter for its field", async () => {
  const mount = mountChrome(search + statusSelect, {
    keepFilters: [{ field: "status", op: null, value: "in_progress", owned: true }],
  })
  const select = mount.el.querySelector("select")

  select.value = "todo"
  change(select)
  apply(mount)

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "status"],
    ["filters[0][value]", "todo"],
  ])
  mount.unmount()
})

test("clearing the panel select drops its own filter but keeps unowned chips", () => {
  const mount = mountChrome(search + statusSelect, {
    keepFilters: [
      { field: "status", op: null, value: "todo", owned: true },
      { field: "kind", op: null, value: "bug", owned: false },
    ],
  })
  const select = mount.el.querySelector("select")

  select.value = ""
  change(select)
  apply(mount)

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "kind"],
    ["filters[0][value]", "bug"],
  ])
  mount.unmount()
})

test("clear-filters drops owned filters and keeps unowned ones", () => {
  const mount = mountChrome(
    search + statusSelect + `<button type="button" data-part="clear-filters">Clear</button>`,
    {
      keepFilters: [
        { field: "status", op: null, value: "in_progress", owned: true },
        { field: "kind", op: null, value: "bug", owned: false },
      ],
    }
  )

  mount.el.querySelector('[data-part="clear-filters"]').click()

  assert.deepEqual(query(mount.last()), [
    ["filters[0][field]", "kind"],
    ["filters[0][value]", "bug"],
  ])
  mount.unmount()
})

test("display changes hide columns and persist density with reset", () => {
  const mount = mountHook(definition,
    `<div id="chrome" data-path="/items" data-table-id="items" data-params="{}" data-hidden-columns="[]">
      <table><thead><tr><th data-column-key="name">Name</th><th data-column-key="status">Status</th></tr></thead></table>
      <input type="checkbox" data-part="column-toggle" data-column-key="status" checked>
      <button type="button" role="radio" data-part="density" data-density="compact">Compact</button>
      <button type="button" role="radio" data-part="density" data-density="comfortable">Comfortable</button>
      <button type="button" data-part="reset-display">Reset</button>
    </div>`, { rootId: "chrome" })
  const checkbox = mount.el.querySelector('[data-column-key="status"][data-part]')
  checkbox.checked = false
  change(checkbox)
  assert.equal(mount.el.querySelector('th[data-column-key="status"]').hidden, true)
  assert.deepEqual(JSON.parse(localStorage.getItem("lui-dt-display:items")), { hidden: ["status"], density: "comfortable" })
  mount.el.querySelector('[data-density="compact"]').click()
  assert.equal(mount.el.dataset.density, "compact")
  mount.el.querySelector('[data-part="reset-display"]').click()
  assert.equal(mount.el.querySelector('th[data-column-key="status"]').hidden, false)
  assert.equal(mount.el.dataset.density, "comfortable")
  mount.unmount()
})

test("Add filter reveals the chosen editor and search filters the field list", () => {
  const mount = mountHook(definition,
    `<div id="chrome" data-path="/items" data-params="{}">
      <input data-part="filter-search">
      <button data-part="add-filter" data-field="status" data-filter-option>Status</button>
      <button data-part="add-filter" data-field="owner" data-filter-option>Owner</button>
      <div data-filter-editor="status" hidden><input data-part="filter" data-field="status"></div>
      <div data-filter-editor="owner" hidden><input data-part="filter" data-field="owner"></div>
    </div>`, { rootId: "chrome" })
  const search = mount.el.querySelector('[data-part="filter-search"]')
  search.value = "own"
  search.dispatchEvent(new window.Event("input", { bubbles: true }))
  assert.equal(mount.el.querySelector('[data-field="status"][data-filter-option]').hidden, true)
  mount.el.querySelector('[data-field="owner"][data-filter-option]').click()
  assert.equal(mount.el.querySelector('[data-filter-editor="owner"]').hidden, false)
  assert.equal(mount.el.querySelector('[data-filter-editor="status"]').hidden, true)
  mount.unmount()
})


test("Views menu opens the save dialog and submits the typed name", () => {
  const mount = mountHook(definition,
    `<div id="chrome" data-path="/items" data-table-id="items" data-params="{}">
      <button type="button" class="lui-dt-save-view-open">Save current view…</button>
      <dialog data-part="save-view-dialog"><input data-part="view-name"><button data-part="save-view-confirm">Save</button><button data-part="save-view-cancel">Cancel</button></dialog>
    </div>`, { rootId: "chrome" })
  const dialog = mount.el.querySelector('dialog')
  dialog.showModal = () => { dialog.open = true }
  dialog.close = () => { dialog.open = false }
  mount.el.querySelector('.lui-dt-save-view-open').click()
  assert.equal(dialog.open, true)
  mount.el.querySelector('[data-part="view-name"]').value = "My view"
  mount.el.querySelector('[data-part="save-view-confirm"]').click()
  assert.equal(mount.el.querySelector('[data-part="save-view-confirm"]').getAttribute('phx-value-name'), "My view")
  mount.unmount()
})


test("density segmented control supports arrow-key selection", () => {
  const mount = mountHook(definition,
    `<div id="chrome" data-path="/items" data-table-id="items" data-params="{}">
      <div role="radiogroup"><button type="button" role="radio" aria-checked="true" data-part="density" data-density="compact">Compact</button><button type="button" role="radio" aria-checked="false" data-part="density" data-density="comfortable">Comfortable</button></div>
    </div>`, { rootId: "chrome" })
  const compact = mount.el.querySelector('[data-density="compact"]')
  compact.focus()
  compact.dispatchEvent(new window.KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
  assert.equal(mount.el.dataset.density, "comfortable")
  assert.equal(mount.el.querySelector('[data-density="comfortable"]').getAttribute("aria-checked"), "true")
  mount.unmount()
})
