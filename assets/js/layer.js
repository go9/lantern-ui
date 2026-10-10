// Floating-layer runtime shared by every floating panel (Zag and legacy).
//
// One rule for where a panel lives: in the browser's top layer (Popover API,
// `popover="manual"`), positioned `fixed` against the viewport. The top layer
// ignores ancestor `overflow`, `transform`, `contain` and z-index, so a select,
// menu, popover, tooltip, date picker or autocomplete opens identically inside a
// clipped card, a table, a sheet, a dialog or a sticky bar. A panel that opens
// later stacks above whatever opened earlier (a menu inside a dialog is above
// the dialog); toasts are re-raised so they stay on top of everything.
//
// Where the Popover API is missing the panel simply stays `position: fixed`
// with the CSS z-index ladder (`--lantern-z-*`), which is still correct except
// inside transformed ancestors.
//
// The server renders `popover="manual"` on the panel/positioner so a LiveView
// patch never strips it; this module only shows/hides it.

const supported = () => {
  const El = (typeof window !== "undefined" && window.HTMLElement) || globalThis.HTMLElement
  return typeof El?.prototype?.showPopover === "function"
}

// Zag popper options every floating component shares: `fixed` strategy against
// the viewport, flip + shift with a gutter, and `--available-height/width`
// exposed so the panel can scroll inside instead of overflowing the screen.
export const FLOATING = {
  strategy: "fixed",
  gutter: 6,
  flip: true,
  slide: true,
  overflowPadding: 8,
  fitViewport: true,
}

export function floating(options = {}) {
  return { ...FLOATING, ...options }
}

const isOpen = (el) => {
  try {
    return el.matches(":popover-open")
  } catch (_) {
    return false
  }
}

// Re-stack toasts above a layer that just opened.
function raiseToasts() {
  for (const t of document.querySelectorAll(".lui-toasts[popover]")) {
    if (!isOpen(t) || !t.querySelector(".lui-toast")) continue
    try {
      t.hidePopover()
      t.showPopover()
    } catch (_) {}
  }
}

export function enterLayer(el) {
  if (!el || !supported() || !el.isConnected) return
  if (!el.hasAttribute("popover")) el.setAttribute("popover", "manual")
  if (!isOpen(el)) {
    try {
      el.showPopover()
    } catch (_) {
      return
    }
    raiseToasts()
  }
}

// Zag's popper computes its first position asynchronously. Keep the content
// hidden while it does so; the positioner itself must remain measurable.
export function markLayerPositioned(el, { placed = true } = {}) {
  if (!el || !placed) return
  el.__lanternHasPositioned = true
  const rect = el.closest("[data-zag]")?.querySelector('[data-part="trigger"]')?.getBoundingClientRect()
  if (rect) el.__lanternLastAnchorRect = { x: rect.x, y: rect.y, width: rect.width, height: rect.height }
  if (!el.__lanternLayerOpen) return
  releasePositioning(el)
}

function releasePositioning(el) {
  el.__lanternPositionObserver?.disconnect()
  el.__lanternPositionObserver = null
  el.removeAttribute("data-lantern-positioning")
}

function waitForPosition(el) {
  const win = el.ownerDocument?.defaultView || globalThis
  const Observer = win.MutationObserver || globalThis.MutationObserver
  const previous = [el.style.getPropertyValue("--x"), el.style.getPropertyValue("--y")]
  el.__lanternPositionObserver?.disconnect()
  if (Observer) {
    el.__lanternPositionObserver = new Observer(() => {
      const current = [el.style.getPropertyValue("--x"), el.style.getPropertyValue("--y")]
      if (current.every(Boolean) && current.some((value, index) => value !== previous[index])) {
        markLayerPositioned(el)
      }
    })
    el.__lanternPositionObserver.observe(el, { attributes: true, attributeFilter: ["style"] })
  }
  if (!Observer) {
    win.requestAnimationFrame(() => win.requestAnimationFrame(() => markLayerPositioned(el)))
  }
}

export function prepareLayerPositioning(el) {
  if (!el) return
  const rect = el.closest("[data-zag]")?.querySelector('[data-part="trigger"]')?.getBoundingClientRect()
  const previous = el.__lanternLastAnchorRect
  const unchanged = rect && previous && ["x", "y", "width", "height"].every((key) => rect[key] === previous[key])
  if (unchanged && el.style.getPropertyValue("--x") && el.style.getPropertyValue("--y")) {
    el.__lanternHasPositioned = true
    return
  }
  el.__lanternPositionPending = true
  el.setAttribute("data-lantern-positioning", "")
  waitForPosition(el)
}

export function leaveLayer(el) {
  if (!el || !supported() || !isOpen(el)) return
  try {
    el.hidePopover()
  } catch (_) {}
}

// Mirror an open/closed state onto the top layer (idempotent).
export function syncLayer(el, open, { positionBeforeReveal = false } = {}) {
  if (!el) return
  if (!positionBeforeReveal) {
    if (open) enterLayer(el)
    else {
      el.__lanternLayerOpen = false
      el.__lanternHasPositioned = false
      el.__lanternPositionPending = false
      releasePositioning(el)
      leaveLayer(el)
    }
    return
  }

  if (open) {
    if (!el.__lanternLayerOpen) {
      el.__lanternLayerOpen = true
      if (el.__lanternHasPositioned) releasePositioning(el)
      else if (!el.__lanternPositionPending) {
        const hasPosition = el.style.getPropertyValue("--x") && el.style.getPropertyValue("--y")
        if (!hasPosition) el.setAttribute("data-lantern-positioning", "")
        else releasePositioning(el)
      }
    } else {
      el.__lanternLayerOpen = true
    }
    el.__lanternPositionPending = false
    enterLayer(el)
    if (positionBeforeReveal && el.hasAttribute("data-lantern-positioning") && !el.__lanternPositionObserver) waitForPosition(el)
  } else {
    el.__lanternLayerOpen = false
    el.__lanternHasPositioned = false
    el.__lanternPositionPending = false
    releasePositioning(el)
    leaveLayer(el)
  }
}
