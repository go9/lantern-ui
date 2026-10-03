// LanternUI Tooltip on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root
// carries `data-zag`, Zag anatomy (`data-scope="tooltip"` + `data-part`)
// lives under it, and the machine owns open state, hover/focus timing, and
// positioning (Zag's internal popper — the legacy `LanternTooltip`
// floating-ui `place()` is only the non-Zag fallback).
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns open state from `data-default-value`;
//     hover/focus timing is the machine's `openDelay` (`delay` attr).
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; opens flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/tooltip"
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

const SCOPE = "tooltip"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternTooltip extends Component {
  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  render() {
    const trigger = this.el.querySelector(part("trigger"))
    if (trigger) this.spreadProps(trigger, this.api.getTriggerProps())

    const positioner = this.el.querySelector(part("positioner"))
    if (positioner) this.spreadProps(positioner, this.api.getPositionerProps())

    const content = this.el.querySelector(part("content"))
    if (content) this.spreadProps(content, this.api.getContentProps())

    const arrow = this.el.querySelector(part("arrow"))
    if (arrow) this.spreadProps(arrow, this.api.getArrowProps())
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverOpenKey(el) {
  return String(parseDatasetBoolean(el.dataset.value) ?? false)
}

function tooltipLayoutProps(el) {
  return {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    openDelay: Number.parseInt(el.dataset.delay || "200", 10) || 0,
    closeDelay: 0,
    dir: getDir(el),
    positioning: { placement: getString(el, "placement") || "top" },
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

export const LanternZagTooltip = createZagLiveHook({
  key: "tooltip",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const component = new LanternTooltip(el, {
      ...tooltipLayoutProps(el),
      onOpenChange: createOnOpenChange(() => hook.el, pushEvent, canPush),
      ...readBooleanControlledZagProps(el, "open", "defaultOpen"),
    })
    el.__lanternTooltip = component

    dom.add("lantern:tooltip:set-open", (event) => {
      if (typeof event.detail?.open === "boolean") component.api.setOpen(event.detail.open)
    })

    server.add("lantern:tooltip:set-open", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (typeof payload?.open === "boolean") component.api.setOpen(payload.open)
    })

    return component
  },

  update(hook, tooltip) {
    const openPatch = readUpdatedServerBoolean(hook.el, hook.beforeAttrs, "open")

    tooltip.updateProps({
      ...tooltipLayoutProps(hook.el),
      ...(openPatch.open !== undefined ? { open: openPatch.open } : {}),
    })

    // Always re-render: a morph may have reset Zag-written attributes while
    // the machine holds newer client state.
    tooltip.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag tooltip against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternTooltip` for roots
 * carrying `data-zag`.
 */
export function mountZagTooltip(hook) {
  const context = Object.create(LanternZagTooltip)
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
