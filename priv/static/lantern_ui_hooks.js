// LanternUI LiveView hooks.
//
// Import and merge into your LiveSocket hooks:
//
//   import LanternHooks from "../../deps/lantern_ui/priv/static/lantern_ui_hooks.js"
//   let Hooks = { ...LanternHooks /* , ...yourHooks */ }
//   let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, ... })
//
// `ChartHover` draws a crosshair + tooltip over a server-rendered LanternUI chart.
// All geometry is computed in Elixir; the hook only reads the embedded point list
// (viewBox coordinates) and paints the hover layer. No chart library, no React.

// Escape dynamic text before it enters the SVG via innerHTML. `value_format`
// output is consumer-controlled and may carry user data, so never trust it raw.
const esc = (s) =>
  String(s).replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]
  )

const ChartHover = {
  mounted() {
    this.setup()
  },

  updated() {
    this.setup()
  },

  setup() {
    this.points = JSON.parse(this.el.dataset.points || "[]")
    this.top = parseFloat(this.el.dataset.top)
    this.bottom = parseFloat(this.el.dataset.bottom)

    const svg = this.el.querySelector("svg")
    this.hover = this.el.querySelector(".lantern-hover")
    if (!svg || !this.hover || this.points.length === 0) return

    this.vbWidth = svg.viewBox.baseVal.width

    if (this.svg && this._onMove) {
      this.svg.removeEventListener("mousemove", this._onMove)
      this.svg.removeEventListener("touchmove", this._onMove)
      this.svg.removeEventListener("mouseleave", this._onLeave)
      this.svg.removeEventListener("touchend", this._onLeave)
      this.svg.removeEventListener("touchcancel", this._onLeave)
    }

    this.svg = svg
    this._onMove = (e) => this.onMove(e)
    this._onLeave = () => this.onLeave()
    svg.addEventListener("mousemove", this._onMove)
    svg.addEventListener("touchmove", this._onMove, { passive: false })
    svg.addEventListener("mouseleave", this._onLeave)
    svg.addEventListener("touchend", this._onLeave)
    svg.addEventListener("touchcancel", this._onLeave)
  },

  onMove(e) {
    const touch = e.touches && e.touches[0]
    if (touch) e.preventDefault()
    const clientX = touch ? touch.clientX : e.clientX

    const rect = this.svg.getBoundingClientRect()
    const vx = ((clientX - rect.left) / rect.width) * this.vbWidth

    let idx = 0
    let best = Infinity
    for (let i = 0; i < this.points.length; i++) {
      const dx = Math.abs(this.points[i].x - vx)
      if (dx < best) {
        best = dx
        idx = i
      }
    }

    const pt = this.points[idx]
    const surface = "var(--lantern-surface, var(--background-base, #ffffff))"
    const fg = "var(--lantern-fg, var(--foreground, #111827))"
    const fgMuted = "var(--lantern-fg-muted, var(--foreground-softer, #6b7280))"
    const boxW = 104
    const boxH = 34
    const bx = Math.min(Math.max(pt.x - boxW / 2, 4), this.vbWidth - boxW - 4)
    const by = pt.y - (boxH + 12) < this.top ? pt.y + 12 : pt.y - (boxH + 12)
    const label2 = pt.d == null ? "" : pt.d

    this.hover.innerHTML =
      `<line x1="${pt.x}" x2="${pt.x}" y1="${this.top}" y2="${this.bottom}" ` +
      `stroke="currentColor" stroke-width="1.5" stroke-dasharray="4 3" opacity="0.5"/>` +
      `<circle cx="${pt.x}" cy="${pt.y}" r="6" fill="currentColor" opacity="0.18"/>` +
      `<circle cx="${pt.x}" cy="${pt.y}" r="3.5" fill="currentColor" stroke="${surface}" stroke-width="2"/>` +
      `<rect x="${bx}" y="${by}" width="${boxW}" height="${boxH}" rx="6" ` +
      `fill="${surface}" stroke="currentColor" stroke-opacity="0.25" stroke-width="0.5"/>` +
      `<text x="${bx + 10}" y="${by + 15}" font-size="12.5" font-weight="500" fill="${fg}">${esc(pt.p)}</text>` +
      `<text x="${bx + 10}" y="${by + 28}" font-size="10.5" fill="${fgMuted}">${esc(label2)}</text>`
    this.hover.style.opacity = 1
  },

  onLeave() {
    if (this.hover) this.hover.style.opacity = 0
  },
}

// `LineHover` draws a shared crosshair + multi-series tooltip over a server-rendered
// line_chart. Reads the per-series point lists from data-series; paints a dot on each
// series at the hovered time and a tooltip listing every series' value.
const LineHover = {
  mounted() {
    this.setup()
  },

  updated() {
    this.setup()
  },

  setup() {
    this.series = JSON.parse(this.el.dataset.series || "[]")
    this.top = parseFloat(this.el.dataset.top)
    this.bottom = parseFloat(this.el.dataset.bottom)

    const svg = this.el.querySelector("svg")
    this.hover = this.el.querySelector(".lantern-hover")
    if (!svg || !this.hover || this.series.length === 0) return

    this.vbWidth = svg.viewBox.baseVal.width

    if (this.svg && this._onMove) {
      this.svg.removeEventListener("mousemove", this._onMove)
      this.svg.removeEventListener("touchmove", this._onMove)
      this.svg.removeEventListener("mouseleave", this._onLeave)
      this.svg.removeEventListener("touchend", this._onLeave)
      this.svg.removeEventListener("touchcancel", this._onLeave)
    }

    this.svg = svg
    this._onMove = (e) => this.onMove(e)
    this._onLeave = () => this.onLeave()
    svg.addEventListener("mousemove", this._onMove)
    svg.addEventListener("touchmove", this._onMove, { passive: false })
    svg.addEventListener("mouseleave", this._onLeave)
    svg.addEventListener("touchend", this._onLeave)
    svg.addEventListener("touchcancel", this._onLeave)
  },

  nearest(pts, vx) {
    let idx = 0
    let best = Infinity
    for (let i = 0; i < pts.length; i++) {
      const dx = Math.abs(pts[i].x - vx)
      if (dx < best) {
        best = dx
        idx = i
      }
    }
    return pts[idx]
  },

  onMove(e) {
    const touch = e.touches && e.touches[0]
    if (touch) e.preventDefault()
    const clientX = touch ? touch.clientX : e.clientX
    const rect = this.svg.getBoundingClientRect()
    const vx = ((clientX - rect.left) / rect.width) * this.vbWidth

    const surface = "var(--lantern-surface, var(--background-base, #ffffff))"
    const fg = "var(--lantern-fg, var(--foreground, #111827))"
    const fgMuted = "var(--lantern-fg-muted, var(--foreground-softer, #6b7280))"

    const rows = []
    let crossX = null
    let tLabel = ""
    for (const s of this.series) {
      if (!s.pts || !s.pts.length) continue
      const pt = this.nearest(s.pts, vx)
      if (crossX === null) {
        crossX = pt.x
        tLabel = pt.t
      }
      rows.push({ label: s.label, color: s.color, v: pt.v, x: pt.x, y: pt.y })
    }
    if (crossX === null) return

    let out =
      `<line x1="${crossX}" x2="${crossX}" y1="${this.top}" y2="${this.bottom}" ` +
      `stroke="${fg}" stroke-width="1" stroke-dasharray="4 3" opacity="0.4"/>`
    for (const r of rows) {
      out += `<circle cx="${r.x}" cy="${r.y}" r="3" fill="${r.color}" stroke="${surface}" stroke-width="1.5"/>`
    }

    const rowH = 15
    // Size the box to the longest label + value so long names (e.g. pod names)
    // don't collide with the right-aligned value. Clamp to the chart width.
    const labelW = Math.max(...rows.map((r) => String(r.label).length)) * 6.2
    const valueW = Math.max(...rows.map((r) => String(r.v).length)) * 6.5
    const boxW = Math.min(Math.max(120, 22 + labelW + 16 + valueW + 10), this.vbWidth - 8)
    const boxH = 20 + rows.length * rowH
    const bx = Math.min(Math.max(crossX + 10, 4), this.vbWidth - boxW - 4)
    const by = Math.max(this.top, Math.min(this.bottom - boxH, rows[0].y - boxH / 2))
    out +=
      `<rect x="${bx}" y="${by}" width="${boxW}" height="${boxH}" rx="6" ` +
      `fill="${surface}" stroke="${fg}" stroke-opacity="0.2" stroke-width="0.5"/>`
    out += `<text x="${bx + 10}" y="${by + 14}" font-size="10.5" fill="${fgMuted}">${esc(tLabel)}</text>`
    rows.forEach((r, i) => {
      const ry = by + 14 + (i + 1) * rowH
      out += `<circle cx="${bx + 12}" cy="${ry - 3.5}" r="3.5" fill="${r.color}"/>`
      out += `<text x="${bx + 22}" y="${ry}" font-size="11" fill="${fg}">${esc(r.label)}</text>`
      out +=
        `<text x="${bx + boxW - 10}" y="${ry}" font-size="11" font-weight="500" ` +
        `text-anchor="end" fill="${fg}">${esc(r.v)}</text>`
    })

    this.hover.innerHTML = out
    this.hover.style.opacity = 1
  },

  onLeave() {
    if (this.hover) this.hover.style.opacity = 0
  },
}

// ── Runtime core ──────────────────────────────────────────────────────────
//
// Shared, dependency-free substrate for LanternUI's interactive components
// (popover, dropdown, select, date picker). Three pieces:
//
//   position(anchor, floating, opts) — anchor/flip/shift placement
//   trapFocus(container)             — dialog-style focus containment
//   onDismiss(el, cb)                — Escape / outside-click dismissal
//
// Component hooks compose these; nothing here touches LiveView state. All
// motion respects prefers-reduced-motion via the --lantern-duration token.

// Position `floating` relative to `anchor`. Placement is "bottom-start" |
// "bottom-end" | "top-start" | "top-end"; flips on viewport overflow and
// shifts horizontally to stay on screen. Returns the chosen placement.
function position(anchor, floating, { placement = "bottom-start", gap = 4 } = {}) {
  const a = anchor.getBoundingClientRect()
  const f = floating.getBoundingClientRect()
  const vw = document.documentElement.clientWidth
  const vh = document.documentElement.clientHeight

  let [side, align] = placement.split("-")

  // Flip vertically when the preferred side overflows and the other fits.
  const fitsBelow = a.bottom + gap + f.height <= vh
  const fitsAbove = a.top - gap - f.height >= 0
  if (side === "bottom" && !fitsBelow && fitsAbove) side = "top"
  if (side === "top" && !fitsAbove && fitsBelow) side = "bottom"

  let top = side === "bottom" ? a.bottom + gap : a.top - gap - f.height
  let left = align === "end" ? a.right - f.width : a.left

  // Shift into the viewport (8px margin) rather than clipping.
  left = Math.min(Math.max(left, 8), vw - f.width - 8)
  top = Math.min(Math.max(top, 8), vh - f.height - 8)

  floating.style.position = "fixed"
  floating.style.top = `${top}px`
  floating.style.left = `${left}px`
  return `${side}-${align}`
}

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), ' +
  'textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

// Contain Tab focus inside `container`. Returns a release function that
// restores focus to the previously focused element.
function trapFocus(container) {
  const prev = document.activeElement

  const onKeydown = (e) => {
    if (e.key !== "Tab") return
    const items = [...container.querySelectorAll(FOCUSABLE)].filter(
      (el) => el.offsetParent !== null
    )
    if (items.length === 0) return
    const first = items[0]
    const last = items[items.length - 1]
    if (e.shiftKey && document.activeElement === first) {
      last.focus()
      e.preventDefault()
    } else if (!e.shiftKey && document.activeElement === last) {
      first.focus()
      e.preventDefault()
    }
  }

  container.addEventListener("keydown", onKeydown)
  const target = container.querySelector(FOCUSABLE)
  if (target) target.focus()

  return () => {
    container.removeEventListener("keydown", onKeydown)
    if (prev && prev.focus) prev.focus()
  }
}

// Call `cb` on Escape or on a pointerdown outside `el` (and outside the
// optional `anchor`). Returns a release function.
function onDismiss(el, cb, { anchor = null } = {}) {
  const onKey = (e) => {
    if (e.key === "Escape") cb("escape")
  }
  const onPointer = (e) => {
    if (el.contains(e.target)) return
    if (anchor && anchor.contains(e.target)) return
    cb("outside")
  }
  document.addEventListener("keydown", onKey)
  document.addEventListener("pointerdown", onPointer)
  return () => {
    document.removeEventListener("keydown", onKey)
    document.removeEventListener("pointerdown", onPointer)
  }
}

// Generic overlay hook: a trigger (`data-part="trigger"`) toggles a floating
// panel (`data-part="panel"`), positioned via `position/3`, focus-trapped,
// dismissed by Escape/outside-click. Component hooks (popover, dropdown,
// date picker) extend this shape or use the primitives directly.
const LanternOverlay = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]')
    this.panel = this.el.querySelector('[data-part="panel"]')
    if (!this.trigger || !this.panel) return
    this.open = false
    this.cleanup = []

    this.trigger.addEventListener("click", () => (this.open ? this.hide() : this.show()))
    this.trigger.addEventListener("keydown", (e) => {
      if ((e.key === "ArrowDown" || e.key === "Enter") && !this.open) {
        e.preventDefault()
        this.show()
      }
    })
  },

  show() {
    this.open = true
    this.panel.hidden = false
    position(this.trigger, this.panel, { placement: this.el.dataset.placement })
    this.trigger.setAttribute("aria-expanded", "true")
    this.cleanup.push(trapFocus(this.panel))
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.trigger }))
  },

  hide() {
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
  },
}

export const runtime = { position, trapFocus, onDismiss }
export const Hooks = { ChartHover, LineHover, LanternOverlay }
export { ChartHover, LineHover, LanternOverlay }
export default Hooks
