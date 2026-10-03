// LanternUI Radio group on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root
// (the `<fieldset>`) carries `data-zag`, Zag anatomy
// (`data-scope="radio-group"` + `data-part`) lives under it, and the
// machine owns the value, arrow-key navigation, and roving tabindex while
// NATIVE radio inputs stay the form surface — one real input per option
// sharing the group name, so form semantics (params, required, field
// errors) are identical to the pre-Zag markup and an existing `phx-change`
// keeps working with no server round trip. Machine ↔ native sync both ways
// with an echo guard so neither side double-fires.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns the value from `data-default-value`.
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; picks flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/radio-group"
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
  readPayloadId,
  readSingleStringControlledZagProps,
  readUpdatedServerString,
} from "./bridge.js"

const SCOPE = "radio-group"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternRadioGroup extends Component {
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

  /** All native option inputs in group order. */
  nativeInputs() {
    return [...this.el.querySelectorAll('input[type="radio"][name]')]
  }

  /**
   * Check the native input matching `value`, uncheck the rest — silently.
   * Returns the newly-checked input when something actually changed.
   */
  syncNative(value) {
    const wanted = value == null || value === "" ? null : String(value)
    let changed = null
    this._syncing = true
    try {
      for (const input of this.nativeInputs()) {
        const should = wanted !== null && input.value === wanted
        if (input.checked !== should) {
          input.checked = should
          if (should) changed = input
        }
      }
    } finally {
      this._syncing = false
    }
    return changed
  }

  get syncing() {
    return this._syncing
  }

  /**
   * Fire form events for a programmatic change (server patch, set-value
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

  applyItemProps() {
    this.el.querySelectorAll(`${part("item")}[data-value]`).forEach((itemEl) => {
      const value = itemEl.dataset.value ?? ""
      const disabled = itemEl.hasAttribute("data-disabled-item")
      this.spreadProps(itemEl, this.api.getItemProps({ value, disabled }))

      const control = itemEl.querySelector(part("item-control"))
      if (control) this.spreadProps(control, this.api.getItemControlProps({ value, disabled }))
    })
  }

  render() {
    const root = this.el.querySelector(part("root")) ?? this.el
    this.spreadProps(root, this.api.getRootProps())
    this.applyItemProps()

    // Re-assert machine truth over morphs; silent — form events fire only
    // from the onValueChange path below.
    this.syncNative(this.api.value)
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function radioLayoutProps(el) {
  return {
    id: el.id,
    name: getString(el, "name"),
    disabled: getBoolean(el, "disabled"),
    invalid: getBoolean(el, "invalid"),
    dir: getDir(el),
    ids: {
      // The fieldset IS the root: keep its id stable so server pushes
      // (`lantern:radio:set-value`, matched on `el.id`) keep working.
      root: el.id,
      // Labels wrap their native inputs, so the item `for` must resolve to
      // the real input id — otherwise clicks on the label text stop
      // toggling the option in a real browser.
      itemHiddenInput: (value) => nativeInputForValue(el, value)?.id,
    },
  }
}

/** The native option input for `value` (scan, never a value-interpolated selector). */
function nativeInputForValue(el, value) {
  return [...el.querySelectorAll('input[type="radio"][name]')].find(
    (input) => input.value === String(value)
  )
}

function createOnValueChange(getEl, getComponent, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const value = details.value ?? null

    // Machine → native: programmatic changes (server patches, set-value
    // events) fire input/change on the newly-checked input so phx-change
    // forms see them. The user's own clicks already toggled the native
    // input, so syncNative finds nothing to do and no event double-fires.
    const component = getComponent()
    const changedInput = component?.syncNative(value)
    if (changedInput) component.dispatchNativeChange(changedInput)

    // Controlled mode: a change that already matches the server value is an
    // echo of our own patch — do not re-notify.
    if (getBoolean(el, "controlled") && (el.dataset.value ?? null) === (value ?? null)) return

    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, value },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient"),
    })
  }
}

export const LanternZagRadioGroup = createZagLiveHook({
  key: "radio-group",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const component = new LanternRadioGroup(el, {
      ...radioLayoutProps(el),
      onValueChange: createOnValueChange(
        () => hook.el,
        () => hook.el.__lanternRadioGroup,
        pushEvent,
        canPush
      ),
      ...readSingleStringControlledZagProps(el),
    })
    el.__lanternRadioGroup = component

    // Native → machine: the user's own clicks/keyboard on the inputs.
    // Self-dispatched sync events are flagged and ignored so the loop
    // terminates.
    dom.add("change", (event) => {
      if (component.syncing) return
      const input = event.target?.closest?.('input[type="radio"][name]')
      if (!input || !el.contains(input)) return
      component.api.setValue(input.value)
    })

    dom.add("lantern:radio:set-value", (event) => {
      if (event.detail?.value !== undefined) component.api.setValue(event.detail.value)
    })

    server.add("lantern:radio:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (payload?.value !== undefined) component.api.setValue(payload.value)
    })

    return component
  },

  update(hook, group) {
    const valuePatch = readUpdatedServerString(hook.el, hook.beforeAttrs)

    group.updateProps({
      ...radioLayoutProps(hook.el),
      ...(valuePatch.value !== undefined ? { value: valuePatch.value } : {}),
    })

    // Always re-render: a morph may have reset Zag-written attributes or
    // native checked state to stale assigns while the machine holds newer
    // client state. render() re-asserts machine truth without dispatching
    // form events.
    group.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag radio group against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternRadio` for roots
 * carrying `data-zag`.
 */
export function mountZagRadioGroup(hook) {
  const context = Object.create(LanternZagRadioGroup)
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
