//! LanternUI Zag bridge — adapts Corex v0.2.2 (MIT, © 2025 Netoum.com).
//! Full attribution: assets/js/zag/NOTICE_COREX.
// Zag ↔ LiveView bridge for LanternUI.
//
// Adapted from Corex v0.2.2 (MIT, © 2025 Netoum.com) — specifically
// `assets/lib/zag-live-hook.ts`, `assets/lib/core.ts`, and the `select`
// subset of `util.ts`, `respond-to.ts`, `read-props.ts`, `dom-events.ts`,
// `hook-handlers.ts`, `controlled-attr-snapshot.ts`, and
// `list-collection.ts`. Rewritten in plain JS to match lantern's untyped
// `assets/js` graph, renamed from `corex:*` to `lantern:*`, and trimmed to
// what the Select prototype needs (single-value string lists, no groups,
// no redirect, no form-array protocol).
//
// The full MIT notice lives in NOTICE_COREX. Do not remove it while any
// file in this directory derives from Corex sources.

import { VanillaMachine, spreadProps, normalizeProps } from "@zag-js/vanilla"

// ---------------------------------------------------------------------------
// Hook listener registries (zag-live-hook.ts)
// ---------------------------------------------------------------------------

const REGISTRIES = Symbol("lantern:zag-hook-registries")

export function createDomEventRegistry(target) {
  const entries = []
  return {
    add(eventName, listener) {
      target.addEventListener(eventName, listener)
      entries.push({ eventName, listener })
    },
    teardown() {
      for (const { eventName, listener } of entries) {
        target.removeEventListener(eventName, listener)
      }
      entries.length = 0
    },
  }
}

export function createHookHandleEventRegistry(hook) {
  const refs = []
  return {
    add(eventName, fn) {
      refs.push(hook.handleEvent(eventName, fn))
    },
    teardown() {
      if (typeof hook.removeHandleEvent !== "function") return
      for (const ref of refs) hook.removeHandleEvent(ref)
      refs.length = 0
    },
  }
}

/**
 * LiveView hook factory for Zag-driven components. `mounted` builds the
 * component and starts its machine; `beforeUpdate` snapshots the
 * `controlledKeys` dataset entries so `updated` can tell a server-changed
 * value apart from an untouched one (a patch that merely re-renders must
 * not reset client-owned machine state).
 */
export function createZagLiveHook(config) {
  const componentOf = (hook) => hook[config.key]

  return {
    mounted() {
      const registries = {
        dom: createDomEventRegistry(this.el),
        server: createHookHandleEventRegistry(this),
      }
      this[REGISTRIES] = registries

      const component = config.mount(this, registries) || undefined
      if (!component) return

      component.init()
      this[config.key] = component
      config.afterInit?.(this, component)
    },

    beforeUpdate() {
      if (config.controlledKeys) this.beforeAttrs = snapshotDataset(this.el, config.controlledKeys)
      config.beforeUpdate?.(this)
    },

    updated() {
      const component = componentOf(this)
      if (!component) return
      try {
        config.update?.(this, component)
      } finally {
        this.beforeAttrs = undefined
      }
    },

    disconnected() {
      const component = componentOf(this)
      if (component) config.disconnected?.(this, component)
    },

    reconnected() {
      const component = componentOf(this)
      if (component) config.reconnected?.(this, component)
    },

    destroyed() {
      this[REGISTRIES]?.dom.teardown()
      this[REGISTRIES]?.server.teardown()
      this[REGISTRIES] = undefined

      const component = componentOf(this)
      if (component) config.destroy?.(this, component)
      component?.destroy()
      this[config.key] = undefined
      this.beforeAttrs = undefined
    },
  }
}

// ---------------------------------------------------------------------------
// Controlled-attribute snapshot (controlled-attr-snapshot.ts)
// ---------------------------------------------------------------------------

export function snapshotDataset(el, keys) {
  const snap = {}
  for (const key of keys) snap[key] = el.dataset[key]
  return snap
}

export function datasetKeyChanged(before, el, key) {
  if (before === undefined) return true
  return before[key] !== el.dataset[key]
}

// ---------------------------------------------------------------------------
// Dataset readers (util.ts subset)
// ---------------------------------------------------------------------------

export function getString(el, attrName, validValues) {
  const value = el.dataset[attrName]
  if (value !== undefined && (!validValues || validValues.includes(value))) return value
  return undefined
}

export function getNumber(el, attrName) {
  const raw = el.dataset[attrName]
  if (raw === undefined) return undefined
  const parsed = Number(raw)
  return Number.isNaN(parsed) ? undefined : parsed
}

/** Presence boolean: the attribute existing (and not "false"/"0") means true. */
export function getBoolean(el, attrName) {
  const dashName = attrName.replace(/([A-Z])/g, "-$1").toLowerCase()
  const key = `data-${dashName}`
  if (!el.hasAttribute(key)) return false
  const raw = el.getAttribute(key)
  if (raw === "false" || raw === "0") return false
  return true
}

export function getDir(el) {
  const fromEl = el.dataset.dir
  if (fromEl === "ltr" || fromEl === "rtl") return fromEl
  const fromDoc = document.documentElement.getAttribute("dir")
  if (fromDoc === "ltr" || fromDoc === "rtl") return fromDoc
  return "ltr"
}

/** Zag api getter for a part, e.g. `clear-trigger` → `getClearTriggerProps`. */
export function partPropsMethod(part) {
  const camel = part
    .split("-")
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join("")
  return `get${camel}Props`
}

export function safeParseJson(raw, fallback) {
  if (raw == null || raw === "") return fallback
  try {
    return JSON.parse(raw)
  } catch (error) {
    console.error("Failed to parse JSON", error)
    return fallback
  }
}

/** LiveSocket may be absent in tests; attempting the push is safe either way. */
export function canPushEvent(liveSocket) {
  try {
    return liveSocket?.getSocket?.()?.isConnected?.() ?? true
  } catch {
    return true
  }
}

export function syncInputFormAssociation(input, hookEl) {
  if (!input) return
  const formId = getString(hookEl, "form")
  if (hookEl.closest("form") !== null) {
    input.removeAttribute("form")
  } else if (formId) {
    input.setAttribute("form", formId)
  }
}

// ---------------------------------------------------------------------------
// Controlled string-list binding (read-props.ts subset)
// ---------------------------------------------------------------------------

/** Parses `data-value`/`data-default-value`: JSON list or comma-separated. */
export function parseDatasetValueList(raw) {
  if (raw === undefined) return []
  const trimmed = raw.trim()
  if (trimmed === "") return []
  if (trimmed.startsWith("[")) {
    const parsed = safeParseJson(trimmed, [])
    if (Array.isArray(parsed) && parsed.every((item) => typeof item === "string")) return parsed
    return []
  }
  return trimmed
    .split(",")
    .map((v) => v.trim())
    .filter((v) => v.length > 0)
}

export function isZagValueControlled(el) {
  return getBoolean(el, "controlled")
}

function mountStringListBinding(el) {
  if (isZagValueControlled(el)) return { value: parseDatasetValueList(el.dataset.value) }
  return { defaultValue: parseDatasetValueList(el.dataset.defaultValue) }
}

/** `{ value }` when controlled, `{ defaultValue }` otherwise (mount). */
export function readStringListControlledZagProps(el) {
  return mountStringListBinding(el)
}

/** `{ value }` only when controlled AND the server changed `data-value`. */
export function readUpdatedServerStringList(el, before) {
  if (!isZagValueControlled(el)) return {}
  if (!datasetKeyChanged(before, el, "value")) return {}
  return { value: parseDatasetValueList(el.dataset.value) }
}

// ---------------------------------------------------------------------------
// Server/client change fan-out (respond-to.ts subset)
// ---------------------------------------------------------------------------

export function idMatches(elId, payloadId, opts) {
  if (payloadId === undefined || payloadId === null || payloadId === "") {
    return opts?.broadcast === true
  }
  return elId === payloadId
}

export function readPayloadId(payload) {
  if (!payload || typeof payload !== "object") return undefined
  let generic
  for (const k of Object.keys(payload)) {
    const v = payload[k]
    if (typeof v !== "string" || v === "") continue
    if (k === "id" || k === "Id") {
      generic = v
    } else if (k.includes("_id") || (k.length > 2 && k.endsWith("Id"))) {
      return v
    }
  }
  return generic
}

/**
 * Fan a machine change out: `pushEvent` to the server when a server event
 * name is configured (and the socket is up), plus a bubbling DOM
 * CustomEvent when a client event name is configured.
 */
export function notifyChange({ el, canPushServer, pushEvent, payload, serverEventName, clientEventName }) {
  if (serverEventName && canPushServer) pushEvent(serverEventName, { ...payload })
  if (clientEventName) {
    el.dispatchEvent(new CustomEvent(clientEventName, { bubbles: true, detail: payload }))
  }
}

// ---------------------------------------------------------------------------
// Component base (core.ts)
// ---------------------------------------------------------------------------

const HEAVY_PROP_KEYS = new Set(["collection"])

function stableValueKey(value) {
  if (value === null) return "null"
  const type = typeof value
  if (type === "string") return JSON.stringify(value)
  if (type === "number" || type === "boolean") return String(value)
  if (type === "undefined") return "undefined"
  if (type === "function" || type === "symbol" || type === "bigint") return ""
  if (typeof value !== "object") return String(value)
  if (Array.isArray(value)) return `[${value.map(stableValueKey).join(",")}]`
  try {
    return JSON.stringify(value, (_key, nested) =>
      typeof nested === "function" ? undefined : nested
    )
  } catch {
    return String(value)
  }
}

function stableUpdatePropsKey(props) {
  const keys = Object.keys(props).sort()
  let out = ""
  for (const key of keys) {
    if (HEAVY_PROP_KEYS.has(key)) continue
    const value = props[key]
    if (typeof value === "function") continue
    out += `${key}:${stableValueKey(value)};`
  }
  return out
}

/**
 * Thin wrapper around a Zag vanilla machine: starts it, re-derives the api
 * and re-renders on every transition, and funnels all DOM writes through
 * `spreadProps` (which returns per-element cleanups so listeners never leak
 * across renders).
 */
export class Component {
  constructor(el, props, beforeInitMachine) {
    if (!el) throw new Error("Root element not found")
    this.el = el
    this.doc = document
    beforeInitMachine?.(this)
    this.machine = this.initMachine(props)
    this.api = this.initApi()
    this.unsubscribe = undefined
    this.lastUpdatePropsKey = undefined
    this.spreadCleanups = new Map()
  }

  initMachine(_props) {
    throw new Error("initMachine must be implemented")
  }

  initApi() {
    throw new Error("initApi must be implemented")
  }

  render() {
    throw new Error("render must be implemented")
  }

  init = () => {
    try {
      this.machine.start()
      this.api = this.initApi()
      this.render()
      this.unsubscribe = this.machine.subscribe(() => {
        this.api = this.initApi()
        this.render()
      })
    } finally {
      this.el.removeAttribute("data-loading")
    }
  }

  clearSpreadPropsCleanups = () => {
    for (const cleanup of this.spreadCleanups.values()) cleanup()
    this.spreadCleanups.clear()
  }

  destroy = () => {
    this.el.removeAttribute("data-loading")
    this.unsubscribe?.()
    this.unsubscribe = undefined
    this.clearSpreadPropsCleanups()
    this.machine.stop()
  }

  spreadProps = (el, props) => {
    const cleanup = spreadProps(el, props, this.machine.scope.id)
    this.spreadCleanups.set(el, cleanup)
  }

  updateProps(props, opts) {
    const key = stableUpdatePropsKey(props)
    if (!opts?.force && key === this.lastUpdatePropsKey) return false
    this.lastUpdatePropsKey = key
    this.machine.updateProps(props)
    return true
  }

  zagConnect(connectFn) {
    return connectFn(this.machine.service, normalizeProps)
  }
}

export { VanillaMachine }
