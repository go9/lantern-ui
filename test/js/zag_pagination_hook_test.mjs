// Behavioural tests for the Zag-driven pagination (`assets/js/zag/pagination.js`).
//
// Fixtures mirror the `pagination` HEEx output: `data-zag` nav root, page
// links with server-rendered patch hrefs, `lui-*` styling untouched. The
// URL stays the source of truth — the machine never intercepts activation;
// it owns keyboard nav + aria-current bookkeeping (always controlled).

import assert from "node:assert/strict"
import { afterEach, test } from "node:test"

import { mountZag, sleep, waitFor } from "./helpers/zag_mount.mjs"

const { LanternZagPagination } = await import("../../assets/js/zag/pagination.js")

const mounts = []
afterEach(() => {
  mounts.splice(0).forEach((m) => m.unmount())
})

function fixture({ id = "orders-pager", page = 3, total = 10, extraRoot = "" } = {}) {
  const pages = [1, 2, 3, 4, 10]
  const links = pages
    .map(
      (p) =>
        `<a href="/orders?page=${p}" class="lui-pg${p === page ? " lui-pg-current" : ""}"${
          p === page ? ' aria-current="page"' : ""
        } data-scope="pagination" data-part="item" data-value="${p}">${p}</a>`
    )
    .join("")
  return `
  <nav id="${id}" data-zag data-value="${page}" data-total-pages="${total}"
    data-total-count="100" data-page-size="10" data-sibling-count="1"
    data-scope="pagination" data-part="root" aria-label="Pagination" ${extraRoot}>
    <div class="lui-pager">
      <a href="/orders?page=${page - 1}" class="lui-pg" aria-label="Previous page"
        data-scope="pagination" data-part="prev-trigger">‹</a>
      ${links}
      <a href="/orders?page=${page + 1}" class="lui-pg" aria-label="Next page"
        data-scope="pagination" data-part="next-trigger">›</a>
    </div>
  </nav>`
}

function mount(html, opts = {}) {
  const ctx = mountZag(LanternZagPagination, html, {
    rootId: "orders-pager",
    componentKey: "__lanternPagination",
    clientEvent: "page-picked",
    ...opts,
  })
  mounts.push(ctx)
  return ctx
}

test("machine tracks the URL page; clicking a link keeps navigating", async () => {
  const { el, component } = mount(fixture())
  await sleep()

  assert.equal(component().api.page, 3)

  const link = el.querySelector('[data-value="5"], [data-value="4"]')
  const clicked = []
  link.addEventListener("click", (e) => clicked.push(e.defaultPrevented))
  link.click()
  await sleep()

  // No preventDefault: patch navigation proceeds; the machine followed.
  assert.deepEqual(clicked, [false])
})

test("prev/next triggers disable at the bounds", async () => {
  const { el } = mount(fixture({ page: 1 }))
  await sleep()

  // First page: previous has no-where-to-go (machine marks it disabled).
  const prev = el.querySelector('[data-part="prev-trigger"]')
  assert.equal(prev.getAttribute("data-disabled"), "")
})

test("a server page patch re-points the machine and aria-current", async () => {
  const ctx = mount(fixture({ page: 3 }))
  const { el, component } = ctx
  await sleep()

  ctx.patch((root) => {
    root.setAttribute("data-value", "4")
    for (const a of root.querySelectorAll('[data-part="item"]')) {
      const current = a.dataset.value === "4"
      a.classList.toggle("lui-pg-current", current)
      if (current) a.setAttribute("aria-current", "page")
      else a.removeAttribute("aria-current")
    }
  })
  await sleep()

  assert.equal(component().api.page, 4)
  assert.equal(el.querySelector('[data-value="4"]').getAttribute("aria-current"), "page")
})

test("selection pushes a server event and dispatches a client event", async () => {
  const { el, pushEvent, clientEvents } = mount(
    fixture({ extraRoot: `data-on-change="page_changed" data-on-change-client="page-picked"` })
  )
  await sleep()

  // Drive through the machine (a keyboard-equivalent selection).
  el.__lanternPagination.api.setPage(5)
  await sleep()

  assert.deepEqual(pushEvent, [{ event: "page_changed", payload: { id: "orders-pager", page: 5 } }])
  assert.equal(clientEvents.length, 1)
  assert.deepEqual(clientEvents[0].detail, { id: "orders-pager", page: 5 })
})

test("server set-page is id-scoped", async () => {
  const { component, serverPush } = mount(fixture())
  await sleep()

  serverPush("lantern:pagination:set-page", { id: "nope", page: 7 })
  await sleep(30)
  assert.equal(component().api.page, 3)

  serverPush("lantern:pagination:set-page", { id: "orders-pager", page: 7 })
  await waitFor(() => component().api.page === 7)
})
