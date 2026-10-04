// LanternUI Select on Zag — client state machine + LiveView form bridge.
//
// Component class adapted from Corex v0.2.2 `assets/components/select.ts`
// (MIT, © 2025 Netoum.com); hook wiring adapted from Corex
// `assets/hooks/select.ts`. See NOTICE_COREX. Lantern differences:
//
// - No groups, no redirect, no update_trigger flag, no value-input part —
//   lantern options are flat `{value, label}` pairs and the single hidden
//   <select> is the only form control.
// - Toggle label keeps lantern's contract: placeholder when empty, the
//   label when one is picked, "N selected" for multi-picks (Zag's
//   `valueAsString` would join labels instead).
// - `max` (multi-select cap) is lantern-only; enforced by reverting picks
//   past the cap.
// - Event namespace is `lantern:*`, matching `LanternUI.open_dialog`.
// - Positioning is fixed to bottom-start + sameWidth (what the legacy
//   `LanternSelect` hook did through floating-ui); no per-instance
//   `data-position-*` attrs in this prototype.

import { connect, machine, collection } from "@zag-js/select"
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
  parseDatasetValueList,
  partPropsMethod,
  readPayloadId,
  readStringListControlledZagProps,
  readUpdatedServerStringList,
  safeParseJson,
  syncInputFormAssociation,
} from "./bridge.js"

import { floating, syncLayer } from "../layer.js"
const SCOPE = "select"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

function readItems(el) {
  const raw = el.getAttribute("data-items") ?? "[]"
  const parsed = safeParseJson(raw, [])
  return Array.isArray(parsed) ? parsed : []
}

function collectionConfig(items) {
  return {
    items,
    itemToValue: (item) => String(item.value ?? ""),
    itemToString: (item) => item.label,
    isItemDisabled: (item) => !!item.disabled,
  }
}

function findItem(options, value) {
  return options.find((item) => String(item.value ?? "") === String(value))
}

export class LanternSelect extends Component {
  constructor(el, props) {
    super(el, props)
    this._options = props.collection?.items ?? []
    this.placeholder = getString(this.el, "placeholder") || ""
  }

  get options() {
    return Array.isArray(this._options) ? this._options : []
  }

  setOptions(options) {
    this._options = Array.isArray(options) ? options : []
  }

  getCollection() {
    return collection(collectionConfig(this.options))
  }

  initMachine(props) {
    const getCollection = this.getCollection.bind(this)
    return new VanillaMachine(machine, {
      ...props,
      get collection() {
        return getCollection()
      },
    })
  }

  initApi() {
    return this.zagConnect(connect)
  }

  applyItemProps() {
    const contentEl = this.el.querySelector(part("content"))
    if (!contentEl) return
    const isOwnedByContent = (el) => el.closest(part("content")) === contentEl

    contentEl.querySelectorAll(part("item")).forEach((itemEl) => {
      if (!isOwnedByContent(itemEl)) return
      const value = itemEl.dataset.value ?? ""
      if (!value) return
      const item = findItem(this.options, value)
      if (!item) return

      this.spreadProps(itemEl, this.api.getItemProps({ item }))

      const textEl = itemEl.querySelector(part("item-text"))
      if (textEl) this.spreadProps(textEl, this.api.getItemTextProps({ item }))

      const indicatorEl = itemEl.querySelector(part("item-indicator"))
      if (indicatorEl) this.spreadProps(indicatorEl, this.api.getItemIndicatorProps({ item }))
    })
  }

  /** Lantern toggle contract: placeholder / single label / "N selected". */
  updateTriggerText() {
    const valueText = this.el.querySelector(`${part("trigger")} ${part("item-text")}`)
    if (!valueText) return
    const values = this.api.value ?? []
    if (values.length === 0) {
      valueText.textContent = this.placeholder
      valueText.setAttribute("data-empty", "")
    } else if (values.length === 1) {
      valueText.textContent = findItem(this.options, values[0])?.label ?? this.placeholder
      valueText.removeAttribute("data-empty")
    } else {
      valueText.textContent = `${values.length} selected`
      valueText.removeAttribute("data-empty")
    }
  }

  syncHiddenSelect() {
    const hiddenSelect = this.el.querySelector(part("hidden-select"))
    if (!hiddenSelect || !hiddenSelect.name) return false
    const valueSet = new Set((this.api.value ?? []).map(String))
    let changed = false
    for (const option of hiddenSelect.options) {
      if (option.value === "") {
        if (option.selected) {
          option.selected = false
          changed = true
        }
        continue
      }
      const selected = valueSet.has(option.value)
      if (option.selected !== selected) {
        option.selected = selected
        changed = true
      }
    }
    if (changed) {
      hiddenSelect.dispatchEvent(new Event("input", { bubbles: true }))
      hiddenSelect.dispatchEvent(new Event("change", { bubbles: true }))
    }
    return changed
  }

  render() {
    const root = this.el.querySelector(part("root")) ?? this.el
    this.spreadProps(root, this.api.getRootProps())

    const hiddenSelect = this.el.querySelector(part("hidden-select"))
    if (hiddenSelect) {
      this.spreadProps(hiddenSelect, this.api.getHiddenSelectProps())
      syncInputFormAssociation(hiddenSelect, this.el)
      const valueSet = new Set((this.api.value ?? []).map(String))
      for (const option of hiddenSelect.options) {
        if (option.value === "") {
          option.selected = false
          continue
        }
        option.selected = valueSet.has(option.value)
      }
      syncInputFormAssociation(hiddenSelect, this.el)
    }

    for (const name of ["control", "trigger", "clear-trigger", "positioner"]) {
      const el = this.el.querySelector(part(name))
      if (!el) continue
      this.spreadProps(el, this.api[partPropsMethod(name)]())
      if (name === "positioner") syncLayer(el, this.api.open)
    }

    const contentEl = this.el.querySelector(part("content"))
    if (contentEl) {
      this.spreadProps(contentEl, this.api.getContentProps())
      // Zag points the listbox at a `label` part we do not render (lantern
      // labels with a plain `<label for>`). Name it by the trigger instead —
      // always present under a stable id — and re-assert after every spread.
      const labelledBy = getString(this.el, "labelledBy")
      if (labelledBy) contentEl.setAttribute("aria-labelledby", labelledBy)
      this.applyItemProps()
    }

    this.placeholder = getString(this.el, "placeholder") || ""
    this.updateTriggerText()
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverValueKey(el) {
  return JSON.stringify(parseDatasetValueList(el.dataset.value).map(String).sort())
}

function selectLayoutProps(el) {
  const props = {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    multiple: getBoolean(el, "multiple"),
    invalid: getBoolean(el, "invalid"),
    dir: getDir(el),
    name: getString(el, "name"),
    form: getString(el, "form"),
    positioning: floating({ placement: "bottom-start", sameWidth: true }),
  }
  const triggerId = getString(el, "triggerId")
  if (triggerId) props.ids = { trigger: triggerId }
  return props
}

function createOnValueChange(getEl, pushEvent, canPush, getLastValue, setLastValue) {
  return (details) => {
    const el = getEl()
    const next = (details.value ?? []).map(String)

    // Lantern-only multi cap: revert picks past `max`, keep the rest.
    const max = Number.parseInt(el.dataset.max || "", 10)
    if (el.hasAttribute("data-multiple") && Number.isFinite(max) && max > 0 && next.length > max) {
      const component = getEl().__lanternSelect
      component?.api.setValue(getLastValue())
      return
    }
    setLastValue(next)

    // Controlled mode: a change that already matches the server value is an
    // echo of our own patch — do not re-sync or re-notify.
    if (getBoolean(el, "controlled")) {
      const echo = JSON.stringify([...next].sort()) === serverValueKey(el)
      if (echo) return
    }

    const component = getEl().__lanternSelect
    component?.syncHiddenSelect()

    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, value: next },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient"),
    })
  }
}

export const LanternZagSelect = createZagLiveHook({
  key: "select",
  controlledKeys: ["value"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    let lastValue = null
    const onValueChange = createOnValueChange(
      () => hook.el,
      pushEvent,
      canPush,
      () => lastValue ?? [],
      (next) => {
        lastValue = next
      }
    )

    const items = readItems(el)
    const component = new LanternSelect(el, {
      ...selectLayoutProps(el),
      collection: collection(collectionConfig(items)),
      onValueChange,
      ...readStringListControlledZagProps(el),
    })
    component.setOptions(items)
    lastValue = [...(component.api.value ?? [])].map(String)
    el.__lanternSelect = component
    hook.lastItemsJson = el.getAttribute("data-items") ?? "[]"

    dom.add("lantern:select:set-value", (event) => {
      const value = event.detail?.value
      if (value !== undefined) component.api.setValue(value.map(String))
    })

    dom.add("lantern:select:set-open", (event) => {
      if (typeof event.detail?.open === "boolean") component.api.setOpen(event.detail.open)
    })

    server.add("lantern:select:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      const value = payload?.value
      if (Array.isArray(value)) component.api.setValue(value.map(String))
    })

    server.add("lantern:select:set-open", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (typeof payload?.open === "boolean") component.api.setOpen(payload.open)
    })

    return component
  },

  update(hook, select) {
    // Options replaced server-side (e.g. new choices): refresh the collection.
    const json = hook.el.getAttribute("data-items") ?? "[]"
    let itemsChanged = false
    if (json !== hook.lastItemsJson) {
      hook.lastItemsJson = json
      select.setOptions(readItems(hook.el))
      itemsChanged = true
    }

    const valuePatch = readUpdatedServerStringList(hook.el, hook.beforeAttrs)

    // Drop client selections whose options disappeared server-side.
    if (itemsChanged && valuePatch.value === undefined) {
      const available = new Set(select.options.map((item) => String(item.value ?? "")))
      const current = (select.api.value ?? []).map(String)
      const next = current.filter((v) => available.has(v))
      if (next.length !== current.length) select.api.setValue(next)
    }

    select.updateProps(
      {
        ...selectLayoutProps(hook.el),
        collection: select.getCollection(),
        ...(valuePatch.value !== undefined ? { value: valuePatch.value } : {}),
      },
      { force: itemsChanged }
    )

    // Always re-render: a morph may have reset server-rendered text (the
    // trigger label) or option selectedness to stale assigns while the
    // machine holds newer client state. render() re-asserts machine truth
    // without dispatching form events.
    select.render()

    hook.el.removeAttribute("data-loading")
    if (getBoolean(hook.el, "disabled")) return
    const trigger = hook.el.querySelector(part("trigger"))
    if (trigger && !trigger.hasAttribute("disabled")) {
      trigger.disabled = false
      trigger.removeAttribute("disabled")
    }
  },
})

/**
 * Mount the Zag select against a LiveView hook context and return the
 * delegate (`beforeUpdate`/`updated`/`destroyed`) the owning hook forwards
 * to. Used by `LanternSelect` for roots carrying `data-zag`.
 */
export function mountZagSelect(hook) {
  const context = Object.create(LanternZagSelect)
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
