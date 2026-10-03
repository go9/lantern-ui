// LanternUI Tabs on Zag — client state machine + LiveView bridge.
//
// Serves `tabs_list/1` (both `segmented` and `underline` variants) behind
// the unchanged `LanternTabs` hook name. Follows the merged select
// prototype (`zag/select.js`): hooked lists carry `data-zag`, Zag anatomy
// (`data-scope="tabs"` + `data-part`) lives under them, and the machine
// owns the value, roving tabindex, and arrow-key/Home/End navigation.
// Styling stays `lui-*` tokens.
//
// Patch/navigate/URL stay the source of truth: the machine never
// intercepts activation — link tabs navigate and button tabs fire
// `phx-click` natively (Zag sends no preventDefault on trigger click).
// Keyboard uses the manual model: arrows move focus + highlight,
// Enter/Space/click activates natively. (Legacy clicked on arrows; the
// manual model matches APG tabs and keeps every tab operable.)
//
// Panels (`tabs_panel`) render server-side only when active, so content
// props spread only when the panel node exists; a selected trigger whose
// panel is absent drops its dangling `aria-controls`.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default, no `active_tab`) — Zag owns the value from
//     `data-default-value`.
//   * server-driven (`active_tab` present, or `controlled`) — the server
//     value is truth; selections flow out through `on_change`, patches
//     flow in. `role="radiogroup"` lists stay on the legacy keyboard path
//     (Zag's tab machine queries `role=tab`).

import { connect, machine } from "@zag-js/tabs"
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

const SCOPE = "tabs"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternTabsMachine extends Component {
  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  /** The list is the hook root itself (single div, both parts). */
  listEl() {
    return this.el.querySelector(part("list")) ?? this.el
  }

  /** Triggers owned by THIS root (nearest data-zag ancestor is this element). */
  ownedTriggers() {
    return [...this.el.querySelectorAll(`${part("trigger")}[data-value]`)].filter(
      (trigger) => trigger.closest("[data-zag]") === this.el
    )
  }

  applyTriggerProps() {
    for (const trigger of this.ownedTriggers()) {
      const value = trigger.dataset.value ?? ""
      const disabled =
        trigger.disabled === true || trigger.hasAttribute("data-disabled-item")
      this.spreadProps(trigger, this.api.getTriggerProps({ value, disabled }))

      // Panels render server-side only when active: drop the dangling
      // content reference instead of labelling by a missing node.
      const content = [...this.el.querySelectorAll(part("content"))].find(
        (node) => node.dataset.value === value
      )
      if (!content) trigger.removeAttribute("aria-controls")
    }
  }

  applyContentProps() {
    for (const content of this.el.querySelectorAll(`${part("content")}[data-value]`)) {
      const value = content.dataset.value ?? ""
      this.spreadProps(content, this.api.getContentProps({ value }))
    }
  }

  render() {
    // The hook root is both the Zag root and the list (single div): spread
    // both, keeping the stable server id for each role so server pushes
    // (matched on `el.id`) keep working.
    this.spreadProps(this.el, this.api.getRootProps())
    const list = this.el.querySelector(part("list")) ?? this.el
    this.spreadProps(list, this.api.getListProps())
    this.applyTriggerProps()
    this.applyContentProps()
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function tabsLayoutProps(el) {
  return {
    id: el.id,
    activationMode: "manual",
    dir: getDir(el),
    orientation: "horizontal",
    ids: { root: el.id, list: el.id },
  }
}

function serverValue(el) {
  // Server truth: explicit controlled value, else the active_tab assign.
  if (getBoolean(el, "controlled")) return el.dataset.value ?? null
  return el.dataset.activeTab ?? null
}

/** Server-driven when the server names a tab or strict mode is set. */
function isControlled(el) {
  return getBoolean(el, "controlled") || el.dataset.activeTab !== undefined
}

function createOnValueChange(getEl, pushEvent, canPush) {
  return (details) => {
    const el = getEl()
    const value = details.value ?? null

    // A change that already matches the server value is an echo of our own
    // patch — do not re-notify. (Link/button activation itself proceeds
    // natively; this is only the fan-out.)
    if ((serverValue(el) ?? null) === (value ?? null) && serverValue(el) !== null) return

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

export const LanternZagTabs = createZagLiveHook({
  key: "tabs",
  controlledKeys: ["value", "activeTab"],

  mount(hook, { dom, server }) {
    const el = hook.el
    const pushEvent = hook.pushEvent.bind(hook)
    const canPush = () => canPushEvent(hook.liveSocket)

    // Server-driven when the server names a tab (active_tab assign) or the
    // caller opts into strict controlled mode.
    const controlled = isControlled(el)
    const initial = serverValue(el) ?? el.dataset.defaultValue ?? null
    const component = new LanternTabsMachine(el, {
      ...tabsLayoutProps(el),
      onValueChange: createOnValueChange(() => hook.el, pushEvent, canPush),
      ...(controlled
        ? initial === null
          ? {}
          : { value: initial }
        : initial === null
          ? {}
          : { defaultValue: initial }),
    })
    el.__lanternTabs = component

    // Controlled machines ignore api.setValue (the prop is truth), so
    // route programmatic sets through updateProps there.
    const applyValue = (value) => {
      if (isControlled(el)) component.updateProps({ ...tabsLayoutProps(el), value })
      else component.api.setValue(value)
    }

    dom.add("lantern:tabs:set-value", (event) => {
      if (event.detail?.value !== undefined) applyValue(event.detail.value)
    })

    server.add("lantern:tabs:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return
      if (payload?.value !== undefined) applyValue(payload.value)
    })

    return component
  },

  update(hook, tabs) {
    const el = hook.el

    // Server truth flows in when it CHANGES (patch-does-not-reset for
    // client highlight). Watches data-value in strict mode, else the
    // active_tab assign. Flows through the `value` prop: a controlled
    // machine ignores api.setValue (the prop is truth).
    const before = hook.beforeAttrs ?? {}
    const key = getBoolean(el, "controlled") ? "value" : "activeTab"
    const was = before[key]
    const now = getBoolean(el, "controlled") ? el.dataset.value : el.dataset.activeTab
    const patch = {}
    if (now !== undefined && now !== null && now !== "" && (was === undefined ? tabs.api.value == null : now !== was)) {
      patch.value = now
    }
    tabs.updateProps({ ...tabsLayoutProps(el), ...patch })

    // Always re-render: a morph may have reset Zag-written attributes while
    // the machine holds newer client state.
    tabs.render()
    el.removeAttribute("data-loading")
  },
})

/**
 * Mount the Zag tabs against a LiveView hook context and return the
 * delegate the owning hook forwards to. Used by `LanternTabs` for roots
 * carrying `data-zag` (hooked tablists; radiogroup lists stay legacy).
 */
export function mountZagTabs(hook) {
  const context = Object.create(LanternZagTabs)
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
