// LanternUI Pagination on Zag — client state machine + LiveView bridge.
//
// Serves `pagination/1` behind the new `LanternPagination` hook. Follows
// the merged select prototype (`zag/select.js`): the `<nav>` root carries
// `data-zag`, Zag anatomy (`data-scope="pagination"` + `data-part`) lives
// under it, and the machine owns the page value, arrow-key navigation, and
// `aria-current` bookkeeping. Styling stays `lui-*` tokens.
//
// Patch/navigate/URL stay the source of truth: page links keep their
// server-rendered patch hrefs and the machine never intercepts activation
// (no preventDefault on item click) — it only tracks the value for
// keyboard nav and ARIA. The pager is therefore always server-driven
// (`controlled`): patches flow the URL page into the machine, selections
// flow out through `on_change` (plus the native navigation).

import { connect, machine } from "@zag-js/pagination"
import {
  Component,
  VanillaMachine,
  canPushEvent,
  createZagLiveHook,
  getDir,
  getString,
  idMatches,
  notifyChange,
  readPayloadId,
} from "./bridge.js"

const SCOPE = "pagination"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternPagination extends Component {
  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  applyItemProps() {
    for (const item of this.el.querySelectorAll(`${part("item")}[data-value]`)) {
      const page = Number.parseInt(item.dataset.value ?? "", 10)
      if (!Number.isFinite(page)) continue
      const disabled = item.hasAttribute("data-disabled-item")
      this.spreadProps(item, this.api.getItemProps({ value: page, disabled }))
    }

    const prev = this.el.querySelector(part("prev-trigger"))
    if (prev) this.spreadProps(prev, this.api.getPrevTriggerProps())

    const next = this.el.querySelector(part("next-trigger"))
    if (next) this.spreadProps(next, this.api.getNextTriggerProps())

    for (const gap of this.el.querySelectorAll(part("ellipsis"))) {
      const index = Number.parseInt(gap.dataset.index ?? "0", 10) || 0
      this.spreadProps(gap, this.api.getEllipsisProps({ index }))
    }
  }

  render() {
    const root = this.el.querySelector(part("root")) ?? this.el
    this.spreadProps(root, this.api.getRootProps())
    this.applyItemProps()
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function paginationLayoutProps(el) {
  const page = Number.parseInt(el.dataset.value ?? "1", 10) || 1
  const totalPages = Math.max(Number.parseInt(el.dataset.totalPages ?? "1", 10) || 1, 1)
  const siblingCount = Number.parseInt(el.dataset.siblingCount ?? "1", 10)
  // The machine derives totalPages as ceil(count / pageSize) and ignores a
  // totalPages prop — reconstruct count when the meta lacks a total.
  const pageSize = Number.parseInt(el.dataset.pageSize ?? "25", 10) || 25
  const count =
    Number.parseInt(el.dataset.totalCount ?? "", 10) || totalPages * pageSize
  return {
    id: el.id,
    // `defaultPage`: the URL page is initial truth, not a controlled prop
    // (a `page` prop would make api.setPage a no-op). Patches flow through
    // explicit setPage in update().
    defaultPage: page,
    count,
    pageSize,
    siblingCount: Number.isFinite(siblingCount) ? siblingCount : 1,
    dir: getDir(el),
    // The hook root id is stable (server-rendered): keep it so server
    // pushes (`lantern:pagination:set-page`, matched on `el.id`) work.
    ids: { root: el.id },
  }
}

function createOnPageChange(getEl, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const page = details.page

    // A change matching the URL page is an echo of our own patch — the
    // native navigation already happened; do not re-notify.
    if (String(page) === String(el.dataset.value ?? "")) return

    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, page },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient"),
    })
  }
}

export const LanternZagPagination = createZagLiveHook({
  key: "pagination",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const component = new LanternPagination(el, {
      ...paginationLayoutProps(el),
      onPageChange: createOnPageChange(() => hook.el, pushEvent, canPush),
    })
    el.__lanternPagination = component

    dom.add("lantern:pagination:set-page", (event) => {
      const page = Number.parseInt(event.detail?.page, 10)
      if (Number.isFinite(page)) component.api.setPage(page)
    })

    server.add("lantern:pagination:set-page", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      const page = Number.parseInt(payload?.page, 10)
      if (Number.isFinite(page)) component.api.setPage(page)
    })

    return component
  },

  update(hook, pagination) {
    // URL truth flows in when the server page changes. The machine keeps
    // page as plain context (no controlled prop sync), so an explicit
    // setPage carries the patch; the echo guard skips re-notify.
    // Anything else re-renders machine truth over the morph.
    const el = hook.el
    pagination.updateProps({ ...paginationLayoutProps(el) })

    if (el.dataset.value !== hook.beforeAttrs?.value) {
      const page = Number.parseInt(el.dataset.value ?? "", 10)
      if (Number.isFinite(page)) pagination.api.setPage(page)
    }

    pagination.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag pagination against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternPagination` for
 * roots carrying `data-zag`.
 */
export function mountZagPagination(hook) {
  const context = Object.create(LanternZagPagination)
  Object.assign(context, {
    el: hook.el,
    pushEvent: hook.pushEvent.bind(hook),
    handleEvent: hook.handleEvent.bind(hook),
    removeHandleEvent: hook.removeHandleEvent?.bind(hook),
    liveSocket: hook.liveSocket,
  })
  context.mounted()
  if (hook._zagPendingUpdate) {
    hook._zagPendingUpdate = false
    context.beforeUpdate()
    context.updated()
  }
  return {
    beforeUpdate: () => context.beforeUpdate(),
    updated: () => context.updated(),
    destroyed: () => context.destroyed(),
  }
}
