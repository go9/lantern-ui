// LanternUI Dialog on Zag — client state machine + LiveView bridge.
//
// Serves `modal/1` (and `alert_dialog/1`, which composes it) behind the
// unchanged `LanternModal` hook name. Follows the merged select prototype
// (`zag/select.js`): the hook root carries `data-zag`, Zag anatomy
// (`data-scope="dialog"` + `data-part`) lives under it, and the machine
// owns open state, focus trap + return, scroll lock, Escape/outside
// dismissal, and initial focus.
//
// Kept contracts:
//   * `LanternUI.open_dialog/close_dialog` (JS `lantern:dialog:open/close`
//     dispatches) and the server pushes (`lantern:dialog:open/close`
//     push_events) still work — they call `api.setOpen`.
//   * The server owns `open` via `data-open`: a patch asserting open
//     re-opens; a patch withdrawing it closes WITHOUT running `on_close`
//     (the server already knows — same echo rule as the legacy hook).
//   * `on_open`/`on_close` JS commands run on client-initiated changes via
//     `liveSocket.execJS` (the modal's attrs were previously accepted but
//     never wired; the sheet's `on_close` keeps its exact semantics).
//
// Two modes (public attrs otherwise unchanged):
//   * client (default) — Zag owns open state from `data-default-value`
//     (the `open` attr is the initial value, as before).
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     strict truth; opens flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/dialog"
import {
  Component,
  VanillaMachine,
  canPushEvent,
  createZagLiveHook,
  getBoolean,
  getDir,
  getString,
  idMatches,
  notifyChange,
  parseDatasetBoolean,
  readBooleanControlledZagProps,
  readPayloadId,
  readUpdatedServerBoolean,
} from "./bridge.js"

export const SCOPE = "dialog"

export const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternDialog extends Component {
  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  render() {
    const backdrop = this.el.querySelector(part("backdrop"))
    if (backdrop) this.spreadProps(backdrop, this.api.getBackdropProps())

    const positioner = this.el.querySelector(part("positioner"))
    if (positioner) this.spreadProps(positioner, this.api.getPositionerProps())

    const content = this.el.querySelector(part("content"))
    if (content) {
      this.spreadProps(content, this.api.getContentProps())
      fixLabelling(this.el, content)
    }

    const closeTrigger = this.el.querySelector(part("close-trigger"))
    if (closeTrigger) this.spreadProps(closeTrigger, this.api.getCloseTriggerProps())

    this.afterRender?.()
  }
}

/**
 * Zag always points content at generated title/description ids. When the
 * dialog declares real ones (alert_dialog via `aria_labelledby`), the
 * machine `ids` override (see layout props) already points there. When it
 * declares none, drop the dangling references instead of labelling the
 * dialog by a node that does not exist.
 */
export function fixLabelling(root, content) {
  if (!root.querySelector(part("title")) && !content.hasAttribute("data-keep-labelledby")) {
    if (content.getAttribute("aria-labelledby")?.startsWith("dialog:")) {
      content.removeAttribute("aria-labelledby")
    }
  }
  if (!root.querySelector(part("description"))) {
    if (content.getAttribute("aria-describedby")?.startsWith("dialog:")) {
      content.removeAttribute("aria-describedby")
    }
  }
}

// ---------------------------------------------------------------------------
// Hook wiring (shared by dialog.js and sheet.js)
// ---------------------------------------------------------------------------

export function serverOpenKey(el) {
  return String(parseDatasetBoolean(el.dataset.value) ?? false)
}

export function dialogLayoutProps(el, { role } = {}) {
  const blocked = getBoolean(el, "preventClosing")
  const props = {
    id: el.id,
    role,
    modal: true,
    trapFocus: true,
    restoreFocus: true,
    preventScroll: true,
    closeOnEscape: getBoolean(el, "closeOnEsc") && !blocked,
    closeOnInteractOutside: getBoolean(el, "closeOnOutside") && !blocked,
    dir: getDir(el),
  }
  const titleId = getString(el, "titleId")
  const descriptionId = getString(el, "descriptionId")
  if (titleId || descriptionId) {
    props.ids = {}
    if (titleId) props.ids.title = titleId
    if (descriptionId) props.ids.description = descriptionId
  }
  const initialFocus = getString(el, "initialFocus")
  if (initialFocus) props.initialFocusEl = () => el.querySelector(initialFocus)
  return props
}

export function createOnOpenChange(getEl, getLiveSocket, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const open = !!details.open

    // Controlled echo (change matches the server value): the server already
    // knows — skip everything.
    if (getBoolean(el, "controlled") && String(open) === serverOpenKey(el)) return

    // Non-controlled `update()` drives the machine for server `data-open`
    // patches and marks them; those skip the close command and the
    // fan-out (legacy parity: the server already knows).
    const serverDriven = el.__lanternServerDriven === true
    el.__lanternServerDriven = false

    const liveSocket = getLiveSocket()
    if (open) {
      const onOpen = getString(el, "onOpen")
      if (onOpen && liveSocket?.execJS) liveSocket.execJS(el, onOpen)
    } else if (!serverDriven) {
      const onClose = getString(el, "onClose")
      if (onClose && liveSocket?.execJS) liveSocket.execJS(el, onClose)
    }

    if (serverDriven) return

    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, open },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient"),
    })
  }
}

export function addDialogDomEvents(dom, el, component) {
  // `LanternUI.open_dialog/close_dialog` dispatch these on the root.
  dom.add("lantern:dialog:open", () => component.api.setOpen(true))
  dom.add("lantern:dialog:close", () => component.api.setOpen(false))
}

export function addDialogServerEvents(server, el, component) {
  server.add("lantern:dialog:open", (payload) => {
    if (!idMatches(el.id, readPayloadId(payload))) return
    component.api.setOpen(true)
  })
  server.add("lantern:dialog:close", (payload) => {
    if (!idMatches(el.id, readPayloadId(payload))) return
    component.api.setOpen(false)
  })
}

export const LanternZagDialog = createZagLiveHook({
  key: "dialog",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const role = getString(el, "role") || "dialog"
    const component = new LanternDialog(el, {
      ...dialogLayoutProps(el, { role }),
      onOpenChange: createOnOpenChange(
        () => hook.el,
        () => hook.liveSocket,
        pushEvent,
        canPush
      ),
      ...readBooleanControlledZagProps(el, "open", "defaultOpen"),
      // No `data-value` in client mode: fall back to the legacy `data-open`
      // initial (server-rendered `open` attr).
      ...(!getBoolean(el, "controlled") && el.dataset.open != null ? { defaultOpen: true } : {}),
    })
    el.__lanternDialog = component

    addDialogDomEvents(dom, el, component)
    addDialogServerEvents(server, el, component)

    return component
  },

  update(hook, dialog) {
    const el = hook.el

    if (getBoolean(el, "controlled")) {
      const openPatch = readUpdatedServerBoolean(el, hook.beforeAttrs, "open")
      dialog.updateProps({
        ...dialogLayoutProps(el, { role: getString(el, "role") || "dialog" }),
        ...(openPatch.open !== undefined ? { open: openPatch.open } : {}),
      })
    } else {
      // Legacy parity: the server owns `data-open`. A patch asserting it
      // re-opens; a patch withdrawing it closes. Both are marked so
      // onOpenChange skips the close command and the fan-out.
      const wantOpen = el.dataset.open != null
      if (wantOpen !== dialog.api.open) {
        el.__lanternServerDriven = true
        dialog.api.setOpen(wantOpen)
      }
      dialog.updateProps(dialogLayoutProps(el, { role: getString(el, "role") || "dialog" }))
    }

    // Always re-render: a morph may have reset Zag-written attributes while
    // the machine holds newer client state.
    dialog.render()
    el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag dialog against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternModal` for roots
 * carrying `data-zag`.
 */
export function mountZagDialog(hook) {
  const context = Object.create(LanternZagDialog)
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
