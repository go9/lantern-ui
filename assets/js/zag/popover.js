// LanternUI Popover on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root
// carries `data-zag`, Zag anatomy (`data-scope="popover"` + `data-part`)
// lives under it, and the machine owns open state, focus return, and
// Escape/outside-click dismissal (Zag's internal popper positions the
// panel — the legacy `LanternOverlay` behaviour is the non-Zag fallback,
// still used by dropdown until its own migration).
//
// A popover is a *surface*, not a menu: it keeps `role="dialog"` (never
// `role="menu"`) and clicking inside does not close it, so panels holding
// form fields stay usable.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns open state from `data-default-value`.
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; opens flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/popover"
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

import { floating, markLayerPositioned, prepareLayerPositioning, syncLayer } from "../layer.js"
const SCOPE = "popover"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternPopover extends Component {
  constructor(el, props) {
    super(el, props)
    this._closeTimer = undefined
  }

  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  render() {
    const trigger = this.el.querySelector(part("trigger"))
    if (trigger) this.spreadProps(trigger, this.api.getTriggerProps())

    const closing = !this.api.open && this._closeTimer !== undefined

    const positioner = this.el.querySelector(part("positioner"))
    if (positioner) {
      syncLayer(positioner, this.api.open || closing, { positionBeforeReveal: true })
      this.spreadProps(positioner, this.api.getPositionerProps())
    }

    const content = this.el.querySelector(part("content"))
    if (content) {
      // Keep the panel painted through the fade+scale exit (same hidden:false
      // spread trick as sheet — a direct write would poison spreadProps).
      if (closing) {
        this.spreadProps(content, { ...this.api.getContentProps(), hidden: false })
        this.el.setAttribute("data-closing", "")
      } else {
        this.spreadProps(content, this.api.getContentProps())
        if (!this.api.open) this.el.removeAttribute("data-closing")
      }
    }
  }

  destroy = () => {
    clearTimeout(this._closeTimer)
    this._closeTimer = undefined
    this.el.removeAttribute("data-loading")
    this.el.removeAttribute("data-closing")
    this.unsubscribe?.()
    this.unsubscribe = undefined
    this.clearSpreadPropsCleanups()
    this.machine.stop()
  }
}

function popoverCloseMs(el) {
  if (!el || typeof getComputedStyle !== "function") return 150
  const raw = getComputedStyle(el).getPropertyValue("--lantern-duration").trim()
  if (!raw) return 150
  const n = Number.parseFloat(raw)
  if (!Number.isFinite(n)) return 150
  if (raw.endsWith("ms")) return n
  if (raw.endsWith("s")) return n * 1000
  return n
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverOpenKey(el) {
  return String(parseDatasetBoolean(el.dataset.value) ?? false)
}

function popoverLayoutProps(el) {
  return {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    modal: getBoolean(el, "modal"),
    dir: getDir(el),
    positioning: floating({
      placement: getString(el, "placement") || "bottom-start",
      onPositioned: (details) => markLayerPositioned(el.querySelector(part("positioner")), details),
    }),
  }
}

function createOnOpenChange(getEl, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const open = !!details.open

    // Controlled mode: a change that already matches the server value is an
    // echo of our own patch — do not re-notify.
    if (getBoolean(el, "controlled") && String(open) === serverOpenKey(el)) return

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

export const LanternZagPopover = createZagLiveHook({
  key: "popover",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const notifyOpenChange = createOnOpenChange(() => hook.el, pushEvent, canPush)
    const component = new LanternPopover(el, {
      ...popoverLayoutProps(el),
      onOpenChange: (details) => {
        notifyOpenChange(details)
        if (details.open) {
          clearTimeout(component._closeTimer)
          component._closeTimer = undefined
          el.removeAttribute("data-closing")
          return
        }
        // Controlled patches are the server's truth — hide immediately.
        if (getBoolean(el, "controlled")) return
        const reduce =
          typeof window !== "undefined" &&
          window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
        const content = el.querySelector(part("content"))
        const ms = popoverCloseMs(content || el)
        if (!reduce && ms > 0 && content && !content.hidden) {
          clearTimeout(component._closeTimer)
          component._closeTimer = setTimeout(() => {
            component._closeTimer = undefined
            component.render()
          }, ms)
        }
      },
      ...readBooleanControlledZagProps(el, "open", "defaultOpen"),
    })
    el.__lanternPopover = component
    const prepareOpen = (event) => {
      const trigger = event.target?.closest?.(part("trigger"))
      if (trigger && el.contains(trigger) && !component.api.open) {
        prepareLayerPositioning(el.querySelector(part("positioner")))
      }
    }
    dom.add("pointerdown", prepareOpen, true)
    dom.add("keydown", (event) => {
      if (["Enter", " ", "ArrowDown"].includes(event.key)) prepareOpen(event)
    }, true)

    // Controlled machines ignore api.setOpen (the prop is truth).
    const applyOpen = (open) => {
      if (getBoolean(el, "controlled")) {
        component.updateProps({ ...popoverLayoutProps(el), open })
      } else {
        component.api.setOpen(open)
      }
    }

    dom.add("lantern:popover:set-open", (event) => {
      if (typeof event.detail?.open === "boolean") applyOpen(event.detail.open)
    })

    server.add("lantern:popover:set-open", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (typeof payload?.open === "boolean") applyOpen(payload.open)
    })

    return component
  },

  update(hook, popover) {
    const openPatch = readUpdatedServerBoolean(hook.el, hook.beforeAttrs, "open")

    popover.updateProps({
      ...popoverLayoutProps(hook.el),
      ...(openPatch.open !== undefined ? { open: openPatch.open } : {}),
    })

    // Always re-render: a morph may have reset Zag-written attributes while
    // the machine holds newer client state.
    popover.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag popover against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternOverlay` for roots
 * carrying `data-zag` (popover renders them; dropdown does not, until its
 * own migration).
 */
export function mountZagPopover(hook) {
  const context = Object.create(LanternZagPopover)
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
