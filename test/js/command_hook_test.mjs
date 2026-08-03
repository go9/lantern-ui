// Behavioural tests for the `LanternCommand` hook.
//
// These drive the real hook against a real DOM. The fixture below is a
// faithful copy of what `LanternUI.Components.Command.command/1` renders — the
// Elixir suite owns the "does the component still render every data-part the
// hook queries" guard, so drift between the two surfaces fails there.

import assert from "node:assert/strict"
import { afterEach, describe, test } from "node:test"

import { hooks, keydown, mountHook, sleep, type } from "./helpers/dom.mjs"

const { LanternCommand } = hooks

const DEBOUNCE = 20

function item({ id, value, label, disabled = false, click = null }) {
  return `<button type="button" id="${id}" class="lui-command-item" data-part="item"
    data-value="${value}" role="option" aria-selected="false" tabindex="-1"
    ${disabled ? "disabled aria-disabled=\"true\"" : ""} ${click ? `phx-click="${click}"` : ""}>
    <span class="lui-command-item-body"><span class="lui-command-item-label">${label}</span></span>
  </button>`
}

const DEFAULT_ITEMS = [
  item({ id: "i1", value: "t-1", label: "Fix the proxy" }),
  item({ id: "i2", value: "t-2", label: "Rotate the key" }),
]

function fixture({
  target = null,
  open = false,
  items = DEFAULT_ITEMS,
  onSearch = "command_search",
  onSelect = "command_select",
  searchOnOpen = false,
  closeOnSelect = true,
  hotkey = "k",
} = {}) {
  const attr = (name, value) => (value == null ? "" : `${name}="${value}"`)

  return `
    <button id="trigger" type="button">Search…</button>
    <div id="cmd" class="lui-command" phx-hook="LanternCommand"
      ${open ? "data-open" : ""}
      ${attr("data-hotkey", hotkey)}
      data-debounce="${DEBOUNCE}"
      ${attr("data-target", target)}
      ${attr("data-on-search", onSearch)}
      ${attr("data-on-select", onSelect)}
      data-search-on-open="${searchOnOpen}"
      data-close-on-esc="true"
      data-close-on-outside="true"
      data-close-on-select="${closeOnSelect}"
      ${open ? "" : "hidden"}>
      <div class="lui-command-backdrop" data-part="backdrop"></div>
      <div class="lui-command-panel" data-part="panel" role="dialog" aria-modal="true"
        aria-label="Command palette">
        <div class="lui-command-header">
          <input type="text" id="cmd-input" class="lui-command-input" data-part="input"
            placeholder="Type a command or search…" autocomplete="off" spellcheck="false"
            role="combobox" aria-expanded="true" aria-autocomplete="list" aria-controls="cmd-list">
        </div>
        <div id="cmd-list" class="lui-command-list" data-part="list" role="listbox"
          aria-label="Command palette">${items.join("")}</div>
        <div class="lui-command-empty" data-part="empty" role="status">No results</div>
      </div>
    </div>`
}

let harness = null

function mount(options = {}) {
  harness = mountHook(LanternCommand, fixture(options), { rootId: "cmd" })
  harness.trigger = harness.document.getElementById("trigger")
  harness.input = harness.document.getElementById("cmd-input")
  harness.list = harness.document.getElementById("cmd-list")
  return harness
}

/** Open the palette the way a consumer's `open_dialog/1` does. */
function open(h) {
  h.trigger.focus()
  h.el.dispatchEvent(new h.window.CustomEvent("lantern:dialog:open"))
}

/**
 * Simulate a LiveView patch. morphdom re-applies whatever the server rendered,
 * and the server renders `hidden={!@open}` with `@open` defaulting to false —
 * so a patch triggered by `on_search` re-adds `hidden` and blanks the input's
 * value attribute. This is the exact sequence that made the palette vanish on
 * the first keystroke.
 */
function patch(h, { items = DEFAULT_ITEMS } = {}) {
  h.hook.beforeUpdate()
  h.el.hidden = true
  h.list.innerHTML = items.join("")
  h.input.removeAttribute("value")
  h.hook.updated()
}

const activeValues = (h) =>
  [...h.list.querySelectorAll("[data-active]")].map((el) => el.dataset.value)

afterEach(() => {
  harness?.unmount()
  harness = null
})

describe("visibility across LiveView patches", () => {
  test("mounts hidden and stays hidden", () => {
    const h = mount()
    assert.equal(h.el.hidden, true)
  })

  test("data-open mounts already visible", () => {
    const h = mount({ open: true })
    assert.equal(h.el.hidden, false)
  })

  test("a patch while open must NOT hide the palette", () => {
    const h = mount()
    open(h)
    assert.equal(h.el.hidden, false)

    patch(h)

    // The regression: the server re-asserted `hidden`, so without the hook
    // re-asserting visibility the palette disappears while the hook still
    // believes it is open — and the next hotkey press "closes" something the
    // user can no longer see.
    assert.equal(h.el.hidden, false, "palette must survive a server patch while open")
  })

  test("a patch while closed leaves it hidden", () => {
    const h = mount()
    patch(h)
    assert.equal(h.el.hidden, true)
  })

  test("a patch preserves the typed query and the highlighted item", () => {
    const h = mount()
    open(h)
    type(h.input, "prox")
    keydown(h.input, "ArrowDown")
    keydown(h.input, "ArrowDown")
    assert.deepEqual(activeValues(h), ["t-2"])

    // The server answers the search by re-rendering the list in a new order.
    patch(h, { items: [DEFAULT_ITEMS[1], DEFAULT_ITEMS[0]] })

    assert.equal(h.input.value, "prox", "the in-flight query must survive the patch")
    assert.deepEqual(activeValues(h), ["t-2"], "the highlight follows the item, not its index")
    assert.equal(h.document.activeElement, h.input, "focus must stay in the input")
  })
})

describe("event targeting", () => {
  test("uses pushEventTo when the palette is inside a LiveComponent", async () => {
    const h = mount({ target: "#my-component" })
    open(h)
    type(h.input, "proxy")
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEventTo, [
      { target: "#my-component", event: "command_search", payload: { query: "proxy" } },
    ])
    // Reaching the parent LiveView here is the bug: it would have to define
    // handlers for a palette it does not own.
    assert.deepEqual(h.pushEvent, [])
  })

  test("uses pushEvent when there is no target", async () => {
    const h = mount()
    open(h)
    type(h.input, "proxy")
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEvent, [{ event: "command_search", payload: { query: "proxy" } }])
    assert.deepEqual(h.pushEventTo, [])
  })

  test("selection routes to the target too", () => {
    const h = mount({ target: "#my-component" })
    open(h)
    h.document.getElementById("i1").click()

    assert.deepEqual(h.pushEventTo, [
      { target: "#my-component", event: "command_select", payload: { value: "t-1" } },
    ])
  })

  test("search_on_open pushes the opening query", async () => {
    const h = mount({ searchOnOpen: true })
    open(h)
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEvent, [{ event: "command_search", payload: { query: "" } }])
  })
})

describe("search", () => {
  test("debounces: keystrokes coalesce into one push carrying the last value", async () => {
    const h = mount()
    open(h)

    type(h.input, "p")
    type(h.input, "pr")
    type(h.input, "pro")
    assert.deepEqual(h.pushEvent, [], "nothing may be pushed before the debounce elapses")

    await sleep(DEBOUNCE * 3)
    assert.deepEqual(h.pushEvent, [{ event: "command_search", payload: { query: "pro" } }])
  })

  test("trims the query before it reaches the consumer", async () => {
    const h = mount()
    open(h)
    type(h.input, "  rotate the key  ")
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEvent, [
      { event: "command_search", payload: { query: "rotate the key" } },
    ])
  })

  test("on_search={nil} disables the push entirely", async () => {
    const h = mount({ onSearch: null })
    open(h)
    type(h.input, "proxy")
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEvent, [])
  })

  test("closing cancels an in-flight debounce", async () => {
    const h = mount()
    open(h)
    type(h.input, "proxy")
    keydown(h.input, "Escape")
    await sleep(DEBOUNCE * 3)

    assert.deepEqual(h.pushEvent, [], "a closed palette must not push a stale query")
  })
})

describe("keyboard", () => {
  test("ArrowDown/ArrowUp move the highlight and wrap", () => {
    const h = mount()
    open(h)
    assert.deepEqual(activeValues(h), [], "nothing is highlighted until the user asks")

    keydown(h.input, "ArrowDown")
    assert.deepEqual(activeValues(h), ["t-1"])
    keydown(h.input, "ArrowDown")
    assert.deepEqual(activeValues(h), ["t-2"])
    keydown(h.input, "ArrowDown")
    assert.deepEqual(activeValues(h), ["t-1"], "wraps to the top")
    keydown(h.input, "ArrowUp")
    assert.deepEqual(activeValues(h), ["t-2"], "wraps to the bottom")
  })

  test("the highlight is published to assistive tech", () => {
    const h = mount()
    open(h)
    keydown(h.input, "ArrowDown")

    assert.equal(h.input.getAttribute("aria-activedescendant"), "i1")
    assert.equal(h.document.getElementById("i1").getAttribute("aria-selected"), "true")
    assert.equal(h.document.getElementById("i2").getAttribute("aria-selected"), "false")
  })

  test("arrow keys skip disabled items", () => {
    const h = mount({
      items: [
        item({ id: "i1", value: "t-1", label: "Fix the proxy", disabled: true }),
        item({ id: "i2", value: "t-2", label: "Rotate the key" }),
      ],
    })
    open(h)
    keydown(h.input, "ArrowDown")

    assert.deepEqual(activeValues(h), ["t-2"])
  })

  test("Home and End jump to the ends", () => {
    const h = mount()
    open(h)
    keydown(h.input, "End")
    assert.deepEqual(activeValues(h), ["t-2"])
    keydown(h.input, "Home")
    assert.deepEqual(activeValues(h), ["t-1"])
  })

  test("Enter selects the highlighted item and closes", () => {
    const h = mount()
    open(h)
    keydown(h.input, "ArrowDown")
    keydown(h.input, "ArrowDown")
    keydown(h.input, "Enter")

    assert.deepEqual(h.pushEvent, [{ event: "command_select", payload: { value: "t-2" } }])
    assert.equal(h.el.hidden, true)
  })

  test("Enter with nothing highlighted does nothing", () => {
    const h = mount()
    open(h)
    const event = keydown(h.input, "Enter")

    assert.deepEqual(h.pushEvent, [])
    assert.equal(h.el.hidden, false)
    assert.equal(event.defaultPrevented, false, "let the browser handle an inert Enter")
  })

  test("an item with its own phx-click is not double-fired", () => {
    const h = mount({ items: [item({ id: "i1", value: "t-1", label: "Go", click: "go" })] })
    open(h)
    keydown(h.input, "ArrowDown")
    keydown(h.input, "Enter")

    // LiveView already handles the binding; pushing on_select as well would run
    // the consumer's handler twice.
    assert.deepEqual(h.pushEvent, [])
    assert.equal(h.el.hidden, true, "close_on_select still applies")
  })

  test("Escape closes and returns focus to whatever opened it", () => {
    const h = mount()
    open(h)
    assert.equal(h.document.activeElement, h.input)

    keydown(h.input, "Escape")

    assert.equal(h.el.hidden, true)
    assert.equal(h.document.activeElement, h.trigger)
    assert.equal(h.document.body.style.overflow, "", "scroll lock must be released")
  })

  test("Meta+K toggles the palette from anywhere on the page", () => {
    const h = mount()
    keydown(h.document.body, "k", { metaKey: true })
    assert.equal(h.el.hidden, false)

    keydown(h.document.body, "k", { metaKey: true })
    assert.equal(h.el.hidden, true)
  })

  test("the hotkey needs its modifier", () => {
    const h = mount()
    keydown(h.document.body, "k")
    assert.equal(h.el.hidden, true)
  })
})

describe("empty state", () => {
  test("is hidden while there are results and shown when there are none", () => {
    const h = mount()
    const empty = () => h.el.querySelector('[data-part="empty"]')
    open(h)
    assert.equal(empty().hidden, true)

    patch(h, { items: [] })
    assert.equal(empty().hidden, false)
  })
})
