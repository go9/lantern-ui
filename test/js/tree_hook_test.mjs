import assert from "node:assert/strict"
import { afterEach, test } from "node:test"
import { hooks, keydown, mountHook } from "./helpers/dom.mjs"

const TREE = `
<ul id="tree" class="lui-tree" role="tree" aria-label="Environments" phx-hook="LanternTree"
    data-on-select="tree_select" data-on-toggle="tree_toggle">
  <li role="treeitem" id="prod" class="lui-tree-item" data-part="item" data-id="prod" data-label="Production"
      aria-expanded="true" aria-selected="false" tabindex="-1">
    <span class="lui-tree-row" data-part="row">
      <span class="lui-tree-expander" data-part="expander" aria-hidden="true">▸</span>
      <span data-part="label">Production</span>
    </span>
    <ul role="group" class="lui-tree-group" data-part="group">
      <li role="treeitem" id="prod-api" class="lui-tree-item" data-part="item" data-id="prod-api" data-label="api"
          aria-selected="true" aria-current="true" tabindex="0">
        <span class="lui-tree-row" data-part="row">
          <span class="lui-tree-expander-spacer" aria-hidden="true"></span>
          <span data-part="label">api</span>
        </span>
      </li>
      <li role="treeitem" id="prod-web" class="lui-tree-item" data-part="item" data-id="prod-web" data-label="web"
          aria-selected="false" tabindex="-1">
        <span class="lui-tree-row" data-part="row">
          <span class="lui-tree-expander-spacer" aria-hidden="true"></span>
          <span data-part="label">web</span>
        </span>
      </li>
    </ul>
  </li>
  <li role="treeitem" id="staging" class="lui-tree-item" data-part="item" data-id="staging" data-label="Staging"
      aria-expanded="false" aria-selected="false" tabindex="-1">
    <span class="lui-tree-row" data-part="row">
      <span class="lui-tree-expander" data-part="expander" aria-hidden="true">▸</span>
      <span data-part="label">Staging</span>
    </span>
    <ul role="group" class="lui-tree-group" data-part="group" hidden>
      <li role="treeitem" id="staging-api" class="lui-tree-item" data-part="item" data-id="staging-api" data-label="api"
          aria-selected="false" tabindex="-1">
        <span class="lui-tree-row" data-part="row">
          <span class="lui-tree-expander-spacer" aria-hidden="true"></span>
          <span data-part="label">api</span>
        </span>
      </li>
    </ul>
  </li>
  <li role="treeitem" id="dev" class="lui-tree-item" data-part="item" data-id="dev" data-label="Development"
      aria-selected="false" tabindex="-1">
    <span class="lui-tree-row" data-part="row">
      <span class="lui-tree-expander-spacer" aria-hidden="true"></span>
      <span data-part="label">Development</span>
    </span>
  </li>
</ul>`

const mounts = []
const mount = (html = TREE) => {
  const ctx = mountHook(hooks.LanternTree, html, { rootId: "tree" })
  mounts.push(ctx)
  return ctx
}
const $ = (m, sel) => m.document.querySelector(sel)
const click = (el) => el.dispatchEvent(new el.ownerDocument.defaultView.MouseEvent("click", { bubbles: true }))

afterEach(() => {
  mounts.splice(0).forEach((ctx) => ctx.unmount())
})

test("mount focuses the current item and hides collapsed descendants from the tab order", () => {
  const m = mount()
  assert.equal($ (m, "#prod-api").tabIndex, 0)
  assert.equal($ (m, "#prod-api").getAttribute("aria-selected"), "true")
  assert.equal($ (m, "#staging-api").hidden || $ (m, "#staging [data-part=group]").hidden, true)
  $ (m, "#prod-api").focus()
  keydown($ (m, "#prod-api"), "ArrowDown")
  assert.equal(m.document.activeElement.id, "prod-web")
  keydown($ (m, "#prod-web"), "ArrowDown")
  assert.equal(m.document.activeElement.id, "staging")
  keydown($ (m, "#staging"), "ArrowDown")
  assert.equal(m.document.activeElement.id, "dev")
  assert.notEqual(m.document.activeElement.id, "staging-api")
})

test("arrows, Home, and End move roving focus without pushing select", () => {
  const m = mount()
  $ (m, "#prod-api").focus()
  keydown($ (m, "#prod-api"), "End")
  assert.equal(m.document.activeElement.id, "dev")
  keydown($ (m, "#dev"), "Home")
  assert.equal(m.document.activeElement.id, "prod")
  assert.equal(m.pushEvent.length, 0)
})

test("Right expands a collapsed parent and Left collapses or moves to the parent", () => {
  const m = mount()
  $ (m, "#staging").focus()
  keydown($ (m, "#staging"), "ArrowRight")
  assert.deepEqual(m.pushEvent, [{ event: "tree_toggle", payload: { id: "staging", expanded: true } }])
  assert.equal($ (m, "#staging").getAttribute("aria-expanded"), "false")

  m.pushEvent.length = 0
  $ (m, "#prod").focus()
  keydown($ (m, "#prod"), "ArrowRight")
  assert.equal(m.document.activeElement.id, "prod-api")
  assert.equal(m.pushEvent.length, 0)

  $ (m, "#prod-web").focus()
  keydown($ (m, "#prod-web"), "ArrowLeft")
  assert.equal(m.document.activeElement.id, "prod")
  keydown($ (m, "#prod"), "ArrowLeft")
  assert.deepEqual(m.pushEvent.at(-1), { event: "tree_toggle", payload: { id: "prod", expanded: false } })
})

test("Enter and Space activate; expander click toggles without selecting", () => {
  const m = mount()
  $ (m, "#prod-web").focus()
  keydown($ (m, "#prod-web"), "Enter")
  assert.deepEqual(m.pushEvent, [{ event: "tree_select", payload: { id: "prod-web" } }])

  m.pushEvent.length = 0
  keydown($ (m, "#prod-web"), " ")
  assert.deepEqual(m.pushEvent, [{ event: "tree_select", payload: { id: "prod-web" } }])

  m.pushEvent.length = 0
  click($ (m, "#staging [data-part=expander]"))
  assert.deepEqual(m.pushEvent, [{ event: "tree_toggle", payload: { id: "staging", expanded: true } }])

  m.pushEvent.length = 0
  click($ (m, "#dev [data-part=row]"))
  assert.deepEqual(m.pushEvent, [{ event: "tree_select", payload: { id: "dev" } }])
})

test("typeahead moves to the next visible prefix match", () => {
  const m = mount()
  $ (m, "#prod").focus()
  keydown($ (m, "#prod"), "s")
  assert.equal(m.document.activeElement.id, "staging")
  m.hook.search = ""
  keydown($ (m, "#staging"), "d")
  assert.equal(m.document.activeElement.id, "dev")
})

test("updated() restores focus after a patch that keeps the node", () => {
  const m = mount()
  $ (m, "#prod-web").focus()
  m.hook.updated()
  assert.equal(m.document.activeElement.id, "prod-web")
  assert.equal($ (m, "#prod-web").tabIndex, 0)
  assert.equal($ (m, "#prod-api").tabIndex, -1)
})

test("destroyed() does not throw on a root that never fully mounted", () => {
  const ctx = mountHook(hooks.LanternTree, '<ul id="tree" phx-hook="LanternTree"></ul>', { rootId: "tree" })
  assert.doesNotThrow(() => ctx.unmount())
})

test("keys are ignored on typing targets", () => {
  const html = TREE.replace(
    `<span data-part="label">Development</span>`,
    `<span data-part="label">Development</span><input id="filter" />`,
  )
  const m = mount(html)
  const input = $ (m, "#filter")
  input.focus()
  keydown(input, "ArrowDown")
  assert.equal(m.document.activeElement.id, "filter")
  assert.equal(m.pushEvent.length, 0)
})
