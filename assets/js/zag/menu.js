// LanternUI Menu on Zag — client state machine + LiveView bridge.
//
// Serves `dropdown/1` (`LanternDropdown`) and `menu/1` (`LanternMenu`)
// behind their unchanged hook names. Follows the merged select prototype
// (`zag/select.js`): the hook root carries `data-zag`, Zag anatomy
// (`data-scope="menu"` + `data-part`) lives under it, and the machine owns
// open state, arrow-key/Home/End navigation, typeahead, and positioning
// (Zag's internal popper — the legacy `trackPosition` path is only the
// non-Zag fallback).
//
// Kept contracts: a menu keeps `role="menu"` (a popover is the surface
// sibling that must NOT be a menu); any `[role="menuitem"]` click closes;
// Escape/outside-click dismisses with focus return. Items are found by DOM
// (`[role^="menuitem"]` inside the content — headers, separators, and
// custom blocks are skipped by Zag itself), so heterogeneous item lists
// (links, buttons, custom) need no item JSON.
//
// Two modes, inferred from attrs (public attrs otherwise unchanged):
//   * client (default) — Zag owns open state from `data-default-value`.
//   * server-driven (`controlled`) — the server value (`data-value`) is
//     truth; opens flow out through `on_change`, patches flow in.

import { connect, machine } from "@zag-js/menu"
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

const SCOPE = "menu"

const part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`

export class LanternMenuMachine extends Component {
  initMachine(props) {
    return new VanillaMachine(machine, props)
  }

  initApi() {
    return this.zagConnect(connect)
  }

  /** Value for an item element: explicit dataset value, real id, else index. */
  static itemValue(itemEl, index) {
    if (itemEl.dataset.value) return itemEl.dataset.value
    if (itemEl.id) return itemEl.id
    return `item-${index}`
  }

  static itemDisabled(itemEl) {
    return itemEl.disabled === true || itemEl.hasAttribute("data-disabled")
  }

  applyItemProps(content) {
    const items = [...content.querySelectorAll('[role="menuitem"], [role="menuitemradio"], [role="menuitemcheckbox"]')]
    items.forEach((itemEl, index) => {
      // Skip nested submenus' items: only direct content owns them.
      const owner = itemEl.closest(part("content"))
      if (owner !== content) return
      const value = LanternMenuMachine.itemValue(itemEl, index)
      itemEl.setAttribute("data-value", value)
      this.spreadProps(
        itemEl,
        this.api.getItemProps({ value, disabled: LanternMenuMachine.itemDisabled(itemEl) })
      )
    })
  }

  render() {
    const trigger = this.el.querySelector(part("trigger"))
    if (trigger) {
      this.spreadProps(trigger, this.api.getTriggerProps())
      // The default toggle button carries its own stale `aria-expanded`
      // from the server render; mirror machine truth onto it.
      trigger
        .querySelectorAll("[aria-haspopup]")
        .forEach((inner) => inner.setAttribute("aria-expanded", String(this.api.open)))
    }

    const positioner = this.el.querySelector(part("positioner"))
    if (positioner) this.spreadProps(positioner, this.api.getPositionerProps())

    const content = this.el.querySelector(part("content"))
    if (content) {
      this.spreadProps(content, this.api.getContentProps())
      this.applyItemProps(content)
    }
  }
}

// ---------------------------------------------------------------------------
// Hook wiring
// ---------------------------------------------------------------------------

function serverOpenKey(el) {
  return String(parseDatasetBoolean(el.dataset.value) ?? false)
}

function menuLayoutProps(el) {
  const props = {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    dir: getDir(el),
    positioning: { placement: getString(el, "placement") || "bottom-start" },
  }
  const triggerId = getString(el, "triggerId")
  const contentId = getString(el, "contentId")
  if (triggerId || contentId) {
    props.ids = {}
    if (triggerId) props.ids.trigger = triggerId
    if (contentId) props.ids.content = contentId
  }
  return props
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

function wireMenuHook(key, componentKey, setEvent) {
  return createZagLiveHook({
    key,
    controlledKeys: ["value"],

    mount(hook, { dom, server }) {
      const el = hook.el
      const pushEvent = hook.pushEvent.bind(hook)
      const canPush = () => canPushEvent(hook.liveSocket)

      const component = new LanternMenuMachine(el, {
        ...menuLayoutProps(el),
        onOpenChange: createOnOpenChange(() => hook.el, pushEvent, canPush),
        ...readBooleanControlledZagProps(el, "open", "defaultOpen"),
      })
      el[componentKey] = component

      // Controlled machines ignore api.setOpen (the prop is truth).
      const applyOpen = (open) => {
        if (getBoolean(el, "controlled")) {
          component.updateProps({ ...menuLayoutProps(el), open })
        } else {
          component.api.setOpen(open)
        }
      }

      // Legacy parity: any menuitem click closes (links navigate, buttons
      // fire phx-click — the machine also closes on select; this covers
      // items Zag does not track).
      dom.add("click", (event) => {
        const item = event.target?.closest?.('[role="menuitem"]')
        if (item && el.contains(item) && component.api.open) applyOpen(false)
      })

      dom.add(setEvent, (event) => {
        if (typeof event.detail?.open === "boolean") applyOpen(event.detail.open)
      })

      server.add(setEvent, (payload) => {
        if (!idMatches(el.id, readPayloadId(payload))) return
        if (typeof payload?.open === "boolean") applyOpen(payload.open)
      })

      return component
    },

    update(hook, menu) {
      const openPatch = readUpdatedServerBoolean(hook.el, hook.beforeAttrs, "open")

      menu.updateProps({
        ...menuLayoutProps(hook.el),
        ...(openPatch.open !== undefined ? { open: openPatch.open } : {}),
      })

      // Always re-render: a morph may have reset Zag-written attributes
      // while the machine holds newer client state.
      menu.render()
      hook.el.removeAttribute("data-loading")
    },
  })
}

export const LanternZagDropdown = wireMenuHook("dropdown", "__lanternDropdown", "lantern:menu:set-open")
export const LanternZagMenu = wireMenuHook("menu", "__lanternMenu", "lantern:menu:set-open")

function mountZag(hook, Hook) {
  const context = Object.create(Hook)
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

/**
 * Mount the Zag menu against a LiveView hook context for `LanternDropdown`
 * roots carrying `data-zag`.
 */
export function mountZagDropdown(hook) {
  return mountZag(hook, LanternZagDropdown)
}

/**
 * Mount the Zag menu against a LiveView hook context for `LanternMenu`
 * roots carrying `data-zag`.
 */
export function mountZagMenu(hook) {
  return mountZag(hook, LanternZagMenu)
}
