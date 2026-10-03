// LanternUI Sheet on Zag — client state machine + LiveView bridge.
//
// Same `@zag-js/dialog` machine as `modal/1` (shared `dialog.js` wiring),
// behind the unchanged `LanternSheet` hook name. Differences from modal:
// `placement` (the screen edge — CSS only, the machine has no such prop)
// and the slide-out exit: closes play the `data-closing` keyframe for 200ms
// before hiding (reduced-motion users get the instant path, as before).
//
// Kept contracts: `LanternUI.open_dialog/close_dialog` (DOM + server
// events), server `data-open` ownership, `on_close` via `liveSocket.execJS`
// on client closes only. Two modes: client default, server-driven
// `controlled` — see `dialog.js`.

import {
  LanternDialog,
  addDialogDomEvents,
  addDialogServerEvents,
  createOnOpenChange,
  dialogLayoutProps,
  fixLabelling,
  part,
} from "./dialog.js"

import {
  canPushEvent,
  createZagLiveHook,
  getBoolean,
  getString,
  readBooleanControlledZagProps,
  readUpdatedServerBoolean,
} from "./bridge.js"

export class LanternSheet extends LanternDialog {
  constructor(el, props) {
    super(el, props)
    this._closeTimer = undefined
  }

  render() {
    const backdrop = this.el.querySelector(part("backdrop"))
    if (backdrop) this.spreadProps(backdrop, this.api.getBackdropProps())

    const positioner = this.el.querySelector(part("positioner"))
    if (positioner) this.spreadProps(positioner, this.api.getPositionerProps())

    const content = this.el.querySelector(part("content"))
    if (content) {
      // Slide-out exit: the machine is already closed, but spread
      // `hidden: false` (through the diff, not around it — a direct write
      // would poison spreadProps' prev-attrs map and the final `hidden`
      // would be skipped as unchanged) until the keyframe finishes.
      if (!this.api.open && this._closeTimer !== undefined) {
        this.spreadProps(content, { ...this.api.getContentProps(), hidden: false })
        this.el.setAttribute("data-closing", "")
      } else {
        this.spreadProps(content, this.api.getContentProps())
        if (!this.api.open) this.el.removeAttribute("data-closing")
      }
      fixLabelling(this.el, content)
    }

    const closeTrigger = this.el.querySelector(part("close-trigger"))
    if (closeTrigger) this.spreadProps(closeTrigger, this.api.getCloseTriggerProps())

    this.afterRender?.()
  }

  // Base `Component.destroy` is an instance field (not a prototype method),
  // so it cannot be super-called — inline its logic after clearing ours.
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

export const LanternZagSheet = createZagLiveHook({
  key: "sheet",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const onOpenChange = createOnOpenChange(
      () => hook.el,
      () => hook.liveSocket,
      pushEvent,
      canPush
    )

    const component = new LanternSheet(el, {
      ...dialogLayoutProps(el, { role: "dialog" }),
      onOpenChange: (details) => {
        onOpenChange(details)
        // Arm the slide-out when a client close lands on a visible panel.
        if (!details.open && !el.__lanternServerDriven) {
          const reduce =
            typeof window !== "undefined" &&
            window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
          if (!reduce && !el.hidden) {
            clearTimeout(component._closeTimer)
            component._closeTimer = setTimeout(() => {
              component._closeTimer = undefined
              component.render()
            }, 200)
          }
        }
      },
      ...readBooleanControlledZagProps(el, "open", "defaultOpen"),
      ...(!getBoolean(el, "controlled") && el.dataset.open != null ? { defaultOpen: true } : {}),
    })
    el.__lanternSheet = component

    addDialogDomEvents(dom, el, component)
    addDialogServerEvents(server, el, component)

    return component
  },

  update(hook, sheet) {
    const el = hook.el

    if (getBoolean(el, "controlled")) {
      const openPatch = readUpdatedServerBoolean(el, hook.beforeAttrs, "open")
      sheet.updateProps({
        ...dialogLayoutProps(el, { role: "dialog" }),
        ...(openPatch.open !== undefined ? { open: openPatch.open } : {}),
      })
    } else {
      const wantOpen = el.dataset.open != null
      if (wantOpen !== sheet.api.open) {
        // A server open cancels a running slide-out instantly.
        clearTimeout(sheet._closeTimer)
        sheet._closeTimer = undefined
        el.removeAttribute("data-closing")
        el.__lanternServerDriven = true
        sheet.api.setOpen(wantOpen)
      }
      sheet.updateProps(dialogLayoutProps(el, { role: "dialog" }))
    }

    sheet.render()
    el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag sheet against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternSheet` for roots
 * carrying `data-zag`.
 */
export function mountZagSheet(hook) {
  const context = Object.create(LanternZagSheet)
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
