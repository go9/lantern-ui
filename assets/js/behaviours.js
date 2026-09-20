// Library behaviours consumers opt into with data attributes — no page-local
// hook. `installBehaviours(document)` is idempotent per document.

const PERSIST_PREFIX = "lantern:persist:"

function typingTarget(el) {
  if (!el || el === document.body) return false
  const tag = el.tagName
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true
  return Boolean(el.isContentEditable)
}

function listItems(list) {
  return [...list.querySelectorAll("[data-lantern-list-item]")].filter(
    (el) => !el.hidden && el.offsetParent !== null,
  )
}

function roveList(list, target) {
  const items = listItems(list)
  if (items.length === 0) return
  for (const item of items) item.tabIndex = item === target ? 0 : -1
  target?.focus()
}

function openListItem(item) {
  const link = item.matches("a[href]") ? item : item.querySelector("a[href]")
  if (link) {
    link.click()
    return
  }
  item.click()
}

function onListNavKey(e) {
  if (e.defaultPrevented || e.metaKey || e.ctrlKey || e.altKey) return
  if (typingTarget(e.target)) return
  const list = e.target.closest?.("[data-lantern-list-nav]")
  if (!list) return

  const items = listItems(list)
  if (items.length === 0) return
  const current = items.find((item) => item === e.target || item.contains(e.target)) || items[0]
  const idx = items.indexOf(current)
  let next = null

  if (e.key === "j" || e.key === "ArrowDown") next = items[Math.min(idx + 1, items.length - 1)]
  else if (e.key === "k" || e.key === "ArrowUp") next = items[Math.max(idx - 1, 0)]
  else if (e.key === "Home") next = items[0]
  else if (e.key === "End") next = items[items.length - 1]
  else if (e.key === "Enter") {
    e.preventDefault()
    openListItem(current)
    return
  } else return

  if (next && next !== current) {
    e.preventDefault()
    roveList(list, next)
  }
}

function initList(list) {
  const items = listItems(list)
  const current = items.find((item) => item.tabIndex === 0) || items[0]
  for (const item of items) item.tabIndex = item === current ? 0 : -1
}

function storage(root) {
  try {
    const view = root?.ownerDocument?.defaultView || (typeof window !== "undefined" ? window : null)
    return view?.localStorage ?? null
  } catch {
    return null
  }
}

function readPersist(root, key) {
  try {
    return storage(root)?.getItem(PERSIST_PREFIX + key) ?? null
  } catch {
    return null
  }
}

function writePersist(root, key, value) {
  try {
    storage(root)?.setItem(PERSIST_PREFIX + key, value)
  } catch {
    /* quota / private mode */
  }
}

function persistRoot(el) {
  return el.closest("[data-lantern-persist]") || el
}

function isPersistedOpen(root) {
  if (root.tagName === "DETAILS") return root.open
  if (root.getAttribute("aria-expanded") === "true") return true
  const toggle = root.querySelector("[data-lantern-persist-toggle], [aria-expanded]")
  if (toggle?.getAttribute("aria-expanded") === "true") return true
  return root.dataset.open === "true" || root.hasAttribute("open")
}

function setPersistedOpen(root, open) {
  if (root.tagName === "DETAILS") {
    root.open = open
    return
  }
  const toggle =
    root.matches("[data-lantern-persist-toggle]")
      ? root
      : root.querySelector("[data-lantern-persist-toggle], [aria-expanded]")
  const panel = root.querySelector("[data-lantern-persist-panel]")
  root.dataset.open = open ? "true" : "false"
  if (open) root.setAttribute("open", "")
  else root.removeAttribute("open")
  if (toggle) toggle.setAttribute("aria-expanded", String(open))
  if (panel) panel.hidden = !open
}

function restorePersist(root) {
  const key = root.getAttribute("data-lantern-persist")
  if (!key) return
  const stored = readPersist(root, key)
  if (stored === "open") setPersistedOpen(root, true)
  if (stored === "closed") setPersistedOpen(root, false)
}

let applying = false

function restoreAll(doc) {
  if (applying || !doc) return
  applying = true
  try {
    doc.querySelectorAll("[data-lantern-persist]").forEach(restorePersist)
    doc.querySelectorAll("[data-lantern-list-nav]").forEach(initList)
  } finally {
    applying = false
  }
}

export function installBehaviours(doc = typeof document === "undefined" ? null : document) {
  if (!doc?.documentElement) return
  if (doc.documentElement.dataset.lanternBehaviours === "1") {
    restoreAll(doc)
    return
  }
  doc.documentElement.dataset.lanternBehaviours = "1"
  doc.addEventListener("keydown", onListNavKey, true)
  doc.addEventListener("click", onPersistClick)
  doc.addEventListener("toggle", onPersistToggle, true)
  restoreAll(doc)
  const Observer = doc.defaultView?.MutationObserver
  if (!Observer) return
  let timer = 0
  const mo = new Observer(() => {
    clearTimeout(timer)
    timer = setTimeout(() => restoreAll(doc), 0)
  })
  mo.observe(doc.documentElement, { childList: true, subtree: true })
}

function onPersistClick(e) {
  const toggle = e.target.closest("[data-lantern-persist-toggle]")
  if (!toggle) return
  const root = persistRoot(toggle)
  const key = root.getAttribute("data-lantern-persist")
  if (!key) return
  const next = !isPersistedOpen(root)
  setPersistedOpen(root, next)
  writePersist(root, key, next ? "open" : "closed")
}

function onPersistToggle(e) {
  const root = e.target
  if (!root.matches?.("details[data-lantern-persist]")) return
  const key = root.getAttribute("data-lantern-persist")
  if (!key) return
  writePersist(root, key, root.open ? "open" : "closed")
}
