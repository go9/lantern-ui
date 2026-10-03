// LanternUI Switch on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root
// carries `data-zag`, Zag anatomy (`data-scope="switch"` + `data-part`)
// lives under it, and the machine owns checked state, keyboard, and ARIA
// while NATIVE inputs stay the form surface: the always-present hidden
// input submits `unchecked_value` when off, and the named checkbox submits
// `checked_value` when on — form semantics identical to the pre-Zag
// markup, so an existing `phx-change` keeps working with no server round
// trip. Machine ↔ native sync both ways with an echo guard so neither
// side double-fires.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns the value from `data-default-value`.
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; toggles flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/switch"
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

const SCOPE = "switch"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternSwitch extends Component {
  constructor(el, props) {
    super(el, props)
    this._syncing = false
  }

  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  /** The named native checkbox — the only form control that submits "on". */
  nativeInput() {
    return this.el.querySelector('input[type="checkbox"][name]')
  }

  /**
   * Set the native checkbox to `checked` without firing form events.
   * Returns true when it actually changed.
   */
  syncNative(checked) {
    const input = this.nativeInput()
    if (!input || input.checked === checked) return false
    this._syncing = true
    try {
      input.checked = checked
    } finally {
      this._syncing = false
    }
    return true
  }

  get syncing() {
    return this._syncing
  }

  /**
   * Fire form events for a programmatic change (server patch, set-checked
   * event). Flagged so the native → machine listener below ignores them
   * and the loop terminates.
   */
  dispatchNativeChange(input) {
    this._syncing = true
    try {
      input.dispatchEvent(new Event("input", { bubbles: true }))
      input.dispatchEvent(new Event("change", { bubbles: true }))
    } finally {
      this._syncing = false
    }
  }

  render() {
    const root = this.el.querySelector(part("root"))
    if (root) this.spreadProps(root, this.api.getRootProps())

    const control = this.el.querySelector(part("control"))
    if (control) this.spreadProps(control, this.api.getControlProps())

    const thumb = this.el.querySelector(part("thumb"))
    if (thumb) this.spreadProps(thumb, this.api.getThumbProps())

    // Re-assert machine truth over morphs; silent — form events fire only
    // from the onCheckedChange path below.
    this.syncNative(!!this.api.checked)
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverCheckedKey(el) {
  return String(parseDatasetBoolean(el.dataset.value) ?? false)
}

function switchLayoutProps(el) {
  const props = {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    invalid: getBoolean(el, "invalid"),
    dir: getDir(el),
  }
  const inputId = getString(el, "inputId")
  if (inputId) props.ids = { hiddenInput: inputId }
  return props
}

function createOnCheckedChange(getEl, getComponent, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const checked = !!details.checked

    // Machine → native (silent when already in sync, e.g. the user's own
    // click already toggled the checkbox). Programmatic changes — server
    // patches, set-checked events — fire input/change so phx-change forms
    // see them, exactly like the select's hidden-select sync.
    const component = getComponent()
    if (component?.syncNative(checked)) {
      const input = component.nativeInput()
      if (input) component.dispatchNativeChange(input)
    }

    // Controlled mode: a change that already matches the server value is an
    // echo of our own patch — do not re-notify.
    if (getBoolean(el, "controlled") && String(checked) === serverCheckedKey(el)) return

    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, checked, value: checked },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient"),
    })
  }
}

export const LanternZagSwitch = createZagLiveHook({
  key: "switch",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const component = new LanternSwitch(el, {
      ...switchLayoutProps(el),
      onCheckedChange: createOnCheckedChange(
        () => hook.el,
        () => hook.el.__lanternSwitch,
        pushEvent,
        canPush
      ),
      ...readBooleanControlledZagProps(el, "checked", "defaultChecked"),
    })
    el.__lanternSwitch = component

    // Controlled machines ignore api.setChecked (the prop is truth).
    const applyChecked = (checked) => {
      if (getBoolean(el, "controlled")) {
        component.updateProps({ ...switchLayoutProps(el), checked })
      } else {
        component.api.setChecked(checked)
      }
    }

    // Native → machine: the user's own clicks/keyboard on the checkbox.
    // Events we dispatch ourselves (machine → native sync above) are
    // flagged and ignored here so the loop terminates.
    dom.add("change", (event) => {
      if (component.syncing) return
      const input = event.target?.closest?.('input[type="checkbox"][name]')
      if (!input || !el.contains(input)) return
      component.api.setChecked(input.checked)
    })

    dom.add("lantern:switch:set-checked", (event) => {
      if (typeof event.detail?.checked === "boolean") applyChecked(event.detail.checked)
    })

    server.add("lantern:switch:set-checked", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (typeof payload?.checked === "boolean") applyChecked(payload.checked)
    })

    return component
  },

  update(hook, sw) {
    const checkedPatch = readUpdatedServerBoolean(hook.el, hook.beforeAttrs, "checked")

    sw.updateProps({
      ...switchLayoutProps(hook.el),
      ...(checkedPatch.checked !== undefined ? { checked: checkedPatch.checked } : {}),
    })

    // Always re-render: a morph may have reset Zag-written attributes or
    // the native checked state to stale assigns while the machine holds
    // newer client state. render() re-asserts machine truth without
    // dispatching form events.
    sw.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag switch against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternSwitch` for roots
 * carrying `data-zag`.
 */
export function mountZagSwitch(hook) {
  const context = Object.create(LanternZagSwitch)
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
