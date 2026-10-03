// LanternUI Accordion on Zag — client state machine + LiveView bridge.
//
// Follows the merged select prototype (`zag/select.js`): the hook root IS
// the Zag root (`data-scope="accordion"` + `data-part="root"`), items carry
// Zag anatomy, and the machine owns expanded state, single/multiple-open
// enforcement, and arrow-key navigation. Styling stays `lui-*` tokens.
//
// Item identity is the stable server-rendered item id (trigger
// `<id>-trigger`, panel `<id>-panel` keep working, so ARIA idrefs survive
// patches). Nested accordions stay isolated: item props apply only to items
// owned by this root. Panels remain in the DOM and use `hidden` when
// collapsed, as before.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns the value from `data-default-value`
//     (JSON list of expanded item ids, `[]` when none).
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; toggles flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/accordion"
import {
  Component,
  VanillaMachine,
  canPushEvent,
  createZagLiveHook,
  getBoolean,
  getDir,
  getString,
  idMatches,
  isZagValueControlled,
  notifyChange,
  parseDatasetValueList,
  readPayloadId,
  readStringListControlledZagProps,
  readUpdatedServerStringList,
} from "./bridge.js"

const SCOPE = "accordion"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternAccordion extends Component {
  constructor(el, props) {
    super(el, props)
    this._guardClick = null
  }

  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  /** Items owned by THIS root (nearest data-zag ancestor is this element). */
  ownedItems() {
    return [...this.el.querySelectorAll(part("item"))].filter(
      (item) => item.closest("[data-zag]") === this.el
    )
  }

  applyItemProps() {
    for (const itemEl of this.ownedItems()) {
      const value = itemEl.dataset.value
      if (!value) continue
      const disabled =
        itemEl.hasAttribute("data-disabled-item") ||
        itemEl.querySelector(part("item-trigger"))?.disabled === true

      this.spreadProps(itemEl, this.api.getItemProps({ value, disabled }))

      const trigger = itemEl.querySelector(part("item-trigger"))
      if (trigger && trigger.closest("[data-zag]") === this.el) {
        this.spreadProps(trigger, this.api.getItemTriggerProps({ value, disabled }))
      }

      const content = itemEl.querySelector(part("item-content"))
      if (content && content.closest("[data-zag]") === this.el) {
        this.spreadProps(content, this.api.getItemContentProps({ value }))
      }
    }
  }

  render() {
    const root = this.el
    this.spreadProps(root, this.api.getRootProps())
    this.applyItemProps()
    this.syncOperability()
  }

  /**
   * Legacy parity (`prevent_all_closed`): the lone expanded trigger is
   * marked inoperable so assistive tech announces it cannot be closed.
   * Zag blocks the collapse itself via `collapsible: false`; the marker
   * is ours to maintain.
   */
  syncOperability() {
    const triggers = this.ownedItems().map((item) =>
      item.querySelector(part("item-trigger"))
    )
    const openValues = new Set(this.api.value ?? [])
    const open = triggers.filter((trigger) => {
      const item = trigger?.closest(part("item"))
      return item && openValues.has(item.dataset.value)
    })
    const inoperable =
      getBoolean(this.el, "preventAllClosed") && open.length === 1 ? open[0] : null
    for (const trigger of triggers) {
      if (!trigger) continue
      if (trigger === inoperable) trigger.setAttribute("aria-disabled", "true")
      else trigger.removeAttribute("aria-disabled")
    }
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverValueKey(el) {
  return JSON.stringify(parseDatasetValueList(el.dataset.value).map(String).sort())
}

/**
 * Client initial when the server names no explicit default: read the
 * `expanded` flags the server rendered (`data-state="open"` items). The
 * parent component cannot see children's flags, so the DOM is the source.
 */
function domExpandedValues(el) {
  return [...el.querySelectorAll(part("item"))]
    .filter(
      (item) =>
        item.closest("[data-zag]") === el && item.dataset.state === "open" && item.dataset.value
    )
    .map((item) => String(item.dataset.value))
}

function initialBinding(el) {
  if (!isZagValueControlled(el) && el.dataset.defaultValue === undefined) {
    // No explicit default: inherit the server-rendered `expanded` flags.
    return { defaultValue: domExpandedValues(el) }
  }
  return readStringListControlledZagProps(el)
}

function accordionLayoutProps(el) {
  return {
    id: el.id,
    multiple: getBoolean(el, "multiple"),
    collapsible: !getBoolean(el, "preventAllClosed"),
    disabled: getBoolean(el, "disabled"),
    dir: getDir(el),
    ids: {
      // The hook root id and the server-rendered item/trigger/panel ids
      // are stable across patches — keep them so ARIA idrefs survive.
      root: el.id,
      item: (value) => value,
      itemTrigger: (value) => `${value}-trigger`,
      itemContent: (value) => `${value}-panel`,
    },
  }
}

function createOnValueChange(getEl, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const value = (details.value ?? []).map(String)

    // Controlled mode: a change that already matches the server value is an
    // echo of our own patch — do not re-notify.
    if (getBoolean(el, "controlled")) {
      const echo = JSON.stringify([...value].sort()) === serverValueKey(el)
      if (echo) return
    }

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

export const LanternZagAccordion = createZagLiveHook({
  key: "accordion",
  controlledKeys: ["value"],

  destroy(hook, accordion) {
    if (accordion?._guardClick) hook.el.removeEventListener("click", accordion._guardClick, true)
  },

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    const component = new LanternAccordion(el, {
      ...accordionLayoutProps(el),
      onValueChange: createOnValueChange(() => hook.el, pushEvent, canPush),
      ...initialBinding(el),
    })
    el.__lanternAccordion = component

    // Legacy parity (`prevent_all_closed` in multiple mode): Zag's
    // `collapsible: false` yields to `multiple`, so the lone expanded
    // trigger (marked inoperable by render) is stopped at capture before
    // the machine sees the click. Keyboard activation funnels through the
    // same native click.
    const guardClick = (event) => {
      const trigger = event.target?.closest?.(part("item-trigger"))
      if (!trigger || !el.contains(trigger)) return
      if (trigger.getAttribute("aria-disabled") === "true") {
        event.preventDefault()
        event.stopPropagation()
      }
    }
    el.addEventListener("click", guardClick, true)
    component._guardClick = guardClick

    // Controlled machines ignore api.setValue (the prop is truth).
    const applyValue = (value) => {
      if (getBoolean(el, "controlled")) {
        component.updateProps({ ...accordionLayoutProps(el), value })
      } else {
        component.api.setValue(value)
      }
    }

    dom.add("lantern:accordion:set-value", (event) => {
      if (Array.isArray(event.detail?.value)) {
        applyValue(event.detail.value.map(String))
      }
    })

    server.add("lantern:accordion:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (Array.isArray(payload?.value)) applyValue(payload.value.map(String))
    })

    return component
  },

  update(hook, accordion) {
    const valuePatch = readUpdatedServerStringList(hook.el, hook.beforeAttrs)

    accordion.updateProps({
      ...accordionLayoutProps(hook.el),
      ...(valuePatch.value !== undefined ? { value: valuePatch.value } : {}),
    })

    // Always re-render: a morph may have reset Zag-written attributes while
    // the machine holds newer client state.
    accordion.render()
    hook.el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag accordion against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternAccordion` for
 * roots carrying `data-zag`.
 */
export function mountZagAccordion(hook) {
  const context = Object.create(LanternZagAccordion)
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
