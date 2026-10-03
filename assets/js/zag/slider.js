// LanternUI Slider on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root IS
// the Zag root (`data-scope="slider"` + `data-part`), the machine owns the
// value, pointer drag, and keyboard stepping, while the NATIVE hidden input
// stays the form surface — `phx-change` and form submits see it exactly
// like before. Styling stays `lui-*` tokens (Zag's inline visual styles are
// dropped on the thumb, where they would fight the lui positioning).
//
// Commit semantics match the legacy hook: drag moves update visuals only,
// the release commits (hidden input + bubbling `input`/`change`);
// keyboard steps commit immediately.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns the value from `data-default-value`.
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; commits flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/slider"
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
} from "./bridge.js"

const SCOPE = "slider"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

function parseNumber(raw, fallback) {
  if (raw === undefined || raw === null || raw === "") return fallback
  const parsed = Number(raw)
  return Number.isFinite(parsed) ? parsed : fallback
}

let sliderAutoId = 0

/** The hook root can render without an id (idless, nameless slider). */
function ensureId(el) {
  if (!el.id) el.id = `lui-slider-${++sliderAutoId}`
  return el.id
}

function clamp(v, min, max) {
  return Math.min(max, Math.max(min, v))
}

export class LanternSlider extends Component {
  constructor(el, props) {
    super(el, props)
    this._syncing = false
    this._lastCommitted = null
  }

  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  /** The native hidden input — the only form control. */
  nativeInput() {
    return this.el.querySelector('input[type="hidden"][name]')
  }

  /** Set the hidden input silently; returns true when it changed. */
  syncNative(value) {
    const input = this.nativeInput()
    if (!input) return false
    const next = String(value)
    if (input.value === next) return false
    this._syncing = true
    try {
      input.value = next
    } finally {
      this._syncing = false
    }
    return true
  }

  get syncing() {
    return this._syncing
  }

  /** Commit the current machine value: hidden input + form events. */
  commit() {
    const value = this.api.value?.[0]
    if (value === undefined || value === null) return false
    if (this._lastCommitted === String(value) && !this.syncNative(value)) return false
    this._lastCommitted = String(value)
    this.syncNative(value)
    const input = this.nativeInput()
    if (input) {
      input.dispatchEvent(new Event("input", { bubbles: true }))
      input.dispatchEvent(new Event("change", { bubbles: true }))
    }
    return true
  }

  /** `aria-valuetext` from the `value_text` template (`{value}` slot). */
  applyValueText(value) {
    const tpl = getString(this.el, "valueText")
    const thumb = this.el.querySelector(part("thumb"))
    if (!thumb) return
    if (tpl) thumb.setAttribute("aria-valuetext", tpl.replace("{value}", String(value)))
    else thumb.removeAttribute("aria-valuetext")
  }

  applyFill(value, min, max) {
    const pct = max === min ? 0 : ((value - min) / (max - min)) * 100
    this.el.style.setProperty("--lui-slider-pct", `${pct}%`)
  }

  withoutStyle(props) {
    const { style: _dropped, ...rest } = props
    return rest
  }

  render() {
    const layout = sliderLayout(this.el)

    const root = this.el.querySelector(part("root")) ?? this.el
    this.spreadProps(root, this.api.getRootProps())

    const control = this.el.querySelector(part("control"))
    if (control) this.spreadProps(control, this.api.getControlProps())

    const track = this.el.querySelector(part("track"))
    if (track && track !== control) this.spreadProps(track, this.api.getTrackProps())

    const range = this.el.querySelector(part("range"))
    if (range) this.spreadProps(range, this.api.getRangeProps())

    const thumb = this.el.querySelector(part("thumb"))
    if (thumb) {
      // lui CSS owns thumb visuals (position via --lui-slider-pct); Zag's
      // inline visibility/position would hide it.
      this.spreadProps(thumb, this.withoutStyle(this.api.getThumbProps({ index: 0 })))
    }

    // Re-assert machine truth over morphs; silent — form events fire only
    // from the commit path below.
    const value = this.api.value?.[0] ?? layout.min
    this.syncNative(value)
    this.applyValueText(value)
    this.applyFill(value, layout.min, layout.max)
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function sliderLayout(el) {
  const min = parseNumber(getString(el, "min"), 0)
  const max = Math.max(parseNumber(getString(el, "max"), 100), min)
  const step = Math.abs(parseNumber(getString(el, "step"), 1)) || 1
  return { min, max, step }
}

function sliderValue(el, layout) {
  const raw = el.dataset.value ?? el.dataset.defaultValue
  return [clamp(parseNumber(raw, layout.min), layout.min, layout.max)]
}

function sliderLayoutProps(el) {
  const layout = sliderLayout(el)
  return {
    id: el.id,
    min: layout.min,
    max: layout.max,
    step: layout.step,
    disabled: getBoolean(el, "disabled"),
    invalid: getBoolean(el, "invalid"),
    dir: getDir(el),
    origin: "start",
    // The hook root id is stable (server-rendered or ensured at mount):
    // keep it so server pushes (`lantern:slider:set-value`, matched on
    // `el.id`) keep working.
    ids: { root: el.id },
  }
}

/**
 * Drag moves sync the hidden input silently; the release commits (hidden
 * input + bubbling `input`/`change`) and notifies. Keyboard steps commit
 * immediately — the machine fires `onValueChangeEnd` for those too (via
 * microtask), so a single commit path covers both. Programmatic
 * `setValue` also flows through End: a real change commits + notifies,
 * exactly like the switch/radio set-value events.
 */
function createOnValueChange(getEl, getComponent, pushEvent, canPush) {
  const onChange = () => {
    const component = getComponent()
    if (!component) return
    const value = component.api.value?.[0]
    if (value === undefined || value === null) return
    // Silent: visuals re-render from the subscription; the hidden input
    // tracks so a form submitted mid-drag reads the live value.
    component.syncNative(value)
  }

  const onEnd = (details) => {
    const el = getEl()
    const value = details.value?.[0]
    if (value === undefined || value === null) return

    // Controlled echo: a change matching the server value is our own
    // patch — neither commit events nor notify.
    if (getBoolean(el, "controlled") && String(value) === String(el.dataset.value ?? "")) {
      return
    }

    const component = getComponent()
    if (!component) return
    if (component.commit()) {
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

  return { onChange, onEnd }
}

export const LanternZagSlider = createZagLiveHook({
  key: "slider",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    ensureId(el)
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)
    const layout = sliderLayout(el)

    const { onChange, onEnd } = createOnValueChange(
      () => hook.el,
      () => hook.el.__lanternSlider,
      pushEvent,
      canPush
    )

    const value = sliderValue(el, layout)
    const component = new LanternSlider(el, {
      ...sliderLayoutProps(el),
      ...(getBoolean(el, "controlled") ? { value } : { defaultValue: value }),
      onValueChange: onChange,
      onValueChangeEnd: onEnd,
    })
    component._lastCommitted = String(value[0])
    el.__lanternSlider = component

    // Controlled machines ignore api.setValue (the prop is truth): clamp
    // here, then route through updateProps there.
    const applyValue = (raw) => {
      const next = clamp(parseNumber(raw, layout.min), layout.min, layout.max)
      if (getBoolean(el, "controlled")) {
        component.updateProps({ ...sliderLayoutProps(el), value: [next] })
      } else {
        component.api.setValue([next])
      }
    }

    // Native → machine: external writes to the hidden input (tests,
    // co-located scripts). Self-dispatched commit events are flagged.
    dom.add("input", (event) => {
      if (component.syncing) return
      const input = event.target?.closest?.('input[type="hidden"][name]')
      if (!input || !el.contains(input)) return
      const next = clamp(parseNumber(input.value, layout.min), layout.min, layout.max)
      component.api.setValue([next])
    })

    dom.add("lantern:slider:set-value", (event) => {
      if (event.detail?.value !== undefined) applyValue(event.detail.value)
    })

    server.add("lantern:slider:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (payload?.value !== undefined) applyValue(payload.value)
    })

    return component
  },

  update(hook, slider) {
    const el = hook.el
    const layout = sliderLayout(el)

    // Controlled patches flow through the `value` prop (a controlled
    // machine ignores api.setValue — the prop is truth). Unchanged on
    // client patches, so client drags survive morphs.
    const patch = {}
    if (getBoolean(el, "controlled") && el.dataset.value !== hook.beforeAttrs?.value) {
      patch.value = [
        clamp(parseNumber(el.dataset.value, layout.min), layout.min, layout.max),
      ]
    }

    slider.updateProps({ ...sliderLayoutProps(el), ...patch })

    // Always re-render: a morph may have reset Zag-written attributes or
    // the hidden value to stale assigns while the machine holds newer
    // client state. render() re-asserts machine truth without dispatching
    // form events.
    slider.render()
    el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag slider against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternSlider` for roots
 * carrying `data-zag`.
 */
export function mountZagSlider(hook) {
  const context = Object.create(LanternZagSlider)
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
