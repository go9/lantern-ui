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
function trapFocus(container, initialFocusSelector = null) {
  const prev = document.activeElement

  const visibleFocusable = (root) =>
    [...root.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent !== null)

  const onKeydown = (e) => {
    if (e.key !== "Tab") return
    const items = visibleFocusable(container)
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
  const initial = initialFocusSelector && container.querySelector(initialFocusSelector)
  const initialTarget =
    initial?.matches(FOCUSABLE) && initial.offsetParent !== null
      ? initial
      : initial && visibleFocusable(initial)[0]
  const target = initialTarget || visibleFocusable(container)[0]
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
    const reposition = () => position(this.trigger, this.panel, { placement: this.el.dataset.placement })
    reposition()
    window.addEventListener("scroll", reposition, true)
    window.addEventListener("resize", reposition)
    this.cleanup.push(() => {
      window.removeEventListener("scroll", reposition, true)
      window.removeEventListener("resize", reposition)
    })
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

// ── Calendar ──────────────────────────────────────────────────────────────
//
// Client-side driver for `LanternUI.Components.Calendar`. The server renders
// the initial grid; this hook re-renders month grids on navigation and runs
// the WAI-ARIA grid keyboard model — all DOM-local, no LiveView round-trips
// (works in dead views and embedded hosts).
//
// Selecting a day sets `data-value` (ISO date) on the root and dispatches a
// bubbling `lantern:change` CustomEvent {detail: {value}} — pickers listen.

const CAL_KEYS = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 }

const MONTHS = ["January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December"]

const LanternCalendar = {
  mounted() {
    this.month = this.el.dataset.month // ISO first-of-month
    this.weekStart = parseInt(this.el.dataset.weekStart || "0", 10)
    this.grid = this.el.querySelector('[data-part="grid"]')
    this.title = this.el.querySelector('[data-part="title"]')

    this.el.querySelector('[data-part="prev"]').addEventListener("click", () => this.nav(-1))
    this.el.querySelector('[data-part="next"]').addEventListener("click", () => this.nav(1))

    this.grid.addEventListener("click", (e) => {
      const day = e.target.closest(".lui-cal-day")
      if (day && !day.disabled) this.select(day.dataset.date)
    })

    this.grid.addEventListener("keydown", (e) => this.onKey(e))

    // Composition surface: sync selection (and shown month) from outside —
    // the picker dispatches this when its field value changes.
    this.el.addEventListener("lantern:set-value", (e) => {
      const iso = e.detail.value
      if (iso) {
        this.el.dataset.value = iso
        this.month = iso.slice(0, 8) + "01"
      } else {
        delete this.el.dataset.value
      }
      this.render()
    })
  },

  nav(delta) {
    const [y, m] = this.month.split("-").map(Number)
    const d = new Date(Date.UTC(y, m - 1 + delta, 1))
    this.month = d.toISOString().slice(0, 10)
    this.render()
  },

  select(iso) {
    this.el.dataset.value = iso
    this.render()
    this.el.dispatchEvent(
      new CustomEvent("lantern:change", { bubbles: true, detail: { value: iso } })
    )
  },

  onKey(e) {
    const day = e.target.closest(".lui-cal-day")
    if (!day) return

    let target = null
    if (e.key in CAL_KEYS) {
      target = this.addDays(day.dataset.date, CAL_KEYS[e.key])
    } else if (e.key === "PageUp" || e.key === "PageDown") {
      const sign = e.key === "PageUp" ? -1 : 1
      target = this.addMonths(day.dataset.date, e.shiftKey ? sign * 12 : sign)
    } else if (e.key === "Home" || e.key === "End") {
      const dow = this.dayOffset(day.dataset.date)
      target = this.addDays(day.dataset.date, e.key === "Home" ? -dow : 6 - dow)
    } else if (e.key === "t") {
      target = new Date().toISOString().slice(0, 10)
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      if (!day.disabled) this.select(day.dataset.date)
      return
    } else {
      return
    }
    e.preventDefault()
    this.focusDate(target)
  },

  focusDate(iso) {
    if (iso.slice(0, 7) !== this.month.slice(0, 7)) {
      this.month = iso.slice(0, 8) + "01"
      this.render()
    }
    const btn = this.grid.querySelector(`[data-date="${iso}"]`)
    if (btn) {
      this.grid.querySelectorAll(".lui-cal-day").forEach((b) => (b.tabIndex = -1))
      btn.tabIndex = 0
      btn.focus()
    }
  },

  addDays(iso, n) {
    const d = new Date(iso + "T00:00:00Z")
    d.setUTCDate(d.getUTCDate() + n)
    return d.toISOString().slice(0, 10)
  },

  addMonths(iso, n) {
    const d = new Date(iso + "T00:00:00Z")
    const day = d.getUTCDate()
    d.setUTCDate(1)
    d.setUTCMonth(d.getUTCMonth() + n)
    const last = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate()
    d.setUTCDate(Math.min(day, last))
    return d.toISOString().slice(0, 10)
  },

  dayOffset(iso) {
    // 0..6 offset of `iso` from the calendar's configured week start.
    const dow = new Date(iso + "T00:00:00Z").getUTCDay()
    return (dow - this.weekStart + 7) % 7
  },

  render() {
    const [y, m] = this.month.split("-").map(Number)
    const first = new Date(Date.UTC(y, m - 1, 1))
    const back = (first.getUTCDay() - this.weekStart + 7) % 7
    const start = new Date(first)
    start.setUTCDate(start.getUTCDate() - back)

    const today = new Date().toISOString().slice(0, 10)
    const selected = this.el.dataset.value
    const min = this.el.dataset.min
    const max = this.el.dataset.max

    this.title.textContent = `${MONTHS[m - 1]} ${y}`

    let focusTarget = null
    const rows = [...this.grid.querySelectorAll('[role="row"]')].slice(1)
    rows.forEach((row, w) => {
      ;[...row.children].forEach((btn, i) => {
        const d = new Date(start)
        d.setUTCDate(d.getUTCDate() + w * 7 + i)
        const iso = d.toISOString().slice(0, 10)
        btn.dataset.date = iso
        btn.textContent = d.getUTCDate()
        btn.toggleAttribute("data-outside", d.getUTCMonth() !== m - 1)
        btn.toggleAttribute("data-today", iso === today)
        if (iso === selected) btn.setAttribute("aria-selected", "true")
        else btn.removeAttribute("aria-selected")
        btn.disabled = !!((min && iso < min) || (max && iso > max))
        btn.setAttribute("aria-label", `${MONTHS[m - 1]} ${d.getUTCDate()}, ${y}`)
        btn.tabIndex = -1
        const inMonth = !btn.hasAttribute("data-outside")
        if ((iso === selected && inMonth) || (!focusTarget && d.getUTCDate() === 1 && inMonth))
          focusTarget = btn
      })
    })
    if (focusTarget) focusTarget.tabIndex = 0
  },
}

// ── Segmented date/time field ─────────────────────────────────────────────
//
// Driver for `LanternUI.Components.DatetimeField`. Each segment is directly
// editable: type digits (auto-advances when unambiguous), ↑/↓ steps with
// wrap, ←/→ moves, Backspace clears, a/p sets the meridiem, Cmd/Ctrl+
// Backspace (or the ∅ button) clears the whole value to null.
//
// The hidden input carries the canonical value (date YYYY-MM-DD, time
// HH:MM:SS.mmm 24h, datetime YYYY-MM-DDTHH:MM:SS.mmm); segments are display
// sugar. Every commit dispatches a bubbling `lantern:change` CustomEvent.

const SEG_MAX = { month: 12, day: 31, year: 9999, hour: 12, minute: 59, second: 59, millisecond: 999 }
const SEG_MIN = { month: 1, day: 1, year: 1, hour: 1, minute: 0, second: 0, millisecond: 0 }
const SEG_PAD = { month: 2, day: 2, year: 4, hour: 2, minute: 2, second: 2, millisecond: 3 }

const LanternDatetimeField = {
  mounted() {
    this.mode = this.el.dataset.mode
    this.hidden = this.el.querySelector('[data-part="value"]')
    this.segs = [...this.el.querySelectorAll(".lui-dtf-seg")]
    this.buf = "" // typed-digit buffer for the focused segment

    // Initial segment state from the server-rendered text.
    this.values = {}
    for (const seg of this.segs) {
      const key = seg.dataset.seg
      if (seg.dataset.set) {
        this.values[key] = key === "meridiem" ? seg.textContent.trim() : parseInt(seg.textContent, 10)
      }
    }

    if (this.el.dataset.disabled) return

    this.el.addEventListener("keydown", (e) => this.onKey(e))
    this.el.addEventListener("focusin", () => (this.buf = ""))
    this.el.querySelector('[data-part="clear"]')?.addEventListener("click", () => this.clearAll())
    this.segs.forEach((s) => s.addEventListener("mousedown", () => (this.buf = "")))

    // Composition surface for the picker hook (and any host): set the date
    // part from an ISO date, set the whole value to now, or clear to null.
    this.el.addEventListener("lantern:set-date", (e) => {
      const [y, m, d] = e.detail.value.split("-").map(Number)
      Object.assign(this.values, { year: y, month: m, day: d })
      // A date chosen with no time yet: default the time so the value commits.
      if (this.mode === "datetime" && this.values.hour == null) {
        Object.assign(this.values, { hour: 12, minute: 0, meridiem: "AM" })
      }
      this.renderAndCommit()
    })

    this.el.addEventListener("lantern:set-now", () => {
      const now = new Date()
      const h = now.getHours()
      Object.assign(this.values, {
        year: now.getFullYear(),
        month: now.getMonth() + 1,
        day: now.getDate(),
        hour: h % 12 === 0 ? 12 : h % 12,
        minute: now.getMinutes(),
        second: now.getSeconds(),
        millisecond: now.getMilliseconds(),
        meridiem: h < 12 ? "AM" : "PM",
      })
      this.renderAndCommit()
    })

    // Set the time part from a canonical `HH:MM:SS.mmm` (24h) string — the
    // picker's panel time pane speaks this. renderAndCommit's no-change guard
    // makes the two-way trigger<->panel sync converge instead of looping.
    this.el.addEventListener("lantern:set-time", (e) => {
      const m = /^(\d{2}):(\d{2}):(\d{2})\.(\d{3})$/.exec(e.detail.value || "")
      if (!m) return
      const h24 = parseInt(m[1], 10)
      Object.assign(this.values, {
        hour: h24 % 12 === 0 ? 12 : h24 % 12,
        minute: parseInt(m[2], 10),
        second: parseInt(m[3], 10),
        millisecond: parseInt(m[4], 10),
        meridiem: h24 < 12 ? "AM" : "PM",
      })
      // A time chosen with no date yet: default the date to today so the
      // value commits (mirror of set-date defaulting the time).
      if (this.mode === "datetime" && this.values.year == null) {
        const now = new Date()
        Object.assign(this.values, {
          year: now.getFullYear(),
          month: now.getMonth() + 1,
          day: now.getDate(),
        })
      }
      this.renderAndCommit()
    })

    this.el.addEventListener("lantern:clear", () => this.clearAll())
  },

  onKey(e) {
    const seg = e.target.closest(".lui-dtf-seg")
    if (!seg) {
      if (e.key === "Backspace" && (e.metaKey || e.ctrlKey)) this.clearAll()
      return
    }
    const key = seg.dataset.seg

    if (e.key === "Backspace" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault()
      return this.clearAll()
    }

    if (/^[0-9]$/.test(e.key) && key !== "meridiem") {
      e.preventDefault()
      return this.type(seg, key, e.key)
    }

    switch (e.key) {
      case "ArrowUp":
      case "ArrowDown": {
        e.preventDefault()
        this.buf = ""
        this.step(key, e.key === "ArrowUp" ? 1 : -1)
        return this.renderAndCommit()
      }
      case "ArrowLeft":
      case "ArrowRight":
        e.preventDefault()
        return this.move(seg, e.key === "ArrowRight" ? 1 : -1)
      case "Backspace":
      case "Delete":
        e.preventDefault()
        this.buf = ""
        delete this.values[key]
        return this.renderAndCommit()
      case "a":
      case "A":
      case "p":
      case "P":
        if (key === "meridiem" || this.mode !== "date") {
          e.preventDefault()
          this.values.meridiem = /a/i.test(e.key) ? "AM" : "PM"
          return this.renderAndCommit()
        }
        return
      default:
        return
    }
  },

  type(seg, key, digit) {
    this.buf += digit
    let n = parseInt(this.buf, 10)
    const max = SEG_MAX[key]

    if (n > max) {
      // Restart the buffer with this digit (e.g. month "13" -> "3").
      this.buf = digit
      n = parseInt(digit, 10)
    }
    this.values[key] = key === "year" ? n : Math.max(n, 0)
    this.renderAndCommit()

    // Auto-advance when another digit could no longer fit.
    const full = this.buf.length >= SEG_PAD[key]
    const ambiguous = parseInt(this.buf + "0", 10) <= max
    if (full || !ambiguous) {
      this.buf = ""
      if (SEG_MIN[key] === 1 && this.values[key] === 0) this.values[key] = SEG_MIN[key]
      this.move(seg, 1)
    }
  },

  step(key, dir) {
    if (key === "meridiem") {
      this.values.meridiem = this.values.meridiem === "AM" ? "PM" : "AM"
      return
    }
    const min = SEG_MIN[key]
    const max = SEG_MAX[key]
    const cur = this.values[key]
    if (cur == null) {
      this.values[key] = dir > 0 ? min : max
    } else if (key === "year") {
      this.values.year = Math.min(Math.max(cur + dir, 1), 9999)
    } else {
      const span = max - min + 1
      this.values[key] = ((cur - min + dir + span) % span) + min
    }
  },

  move(fromSeg, dir) {
    const i = this.segs.indexOf(fromSeg)
    const next = this.segs[i + dir]
    if (next) {
      this.buf = ""
      next.focus()
    }
  },

  clearAll() {
    this.values = {}
    this.buf = ""
    this.renderAndCommit()
    this.segs[0]?.focus()
  },

  renderAndCommit() {
    for (const seg of this.segs) {
      const key = seg.dataset.seg
      const v = this.values[key]
      if (v == null) {
        seg.textContent = seg.dataset.placeholder
        seg.removeAttribute("data-set")
      } else {
        seg.textContent = key === "meridiem" ? v : String(v).padStart(SEG_PAD[key], "0")
        seg.setAttribute("data-set", "true")
      }
      if (key !== "meridiem") seg.setAttribute("aria-valuenow", v == null ? "" : v)
    }

    const prev = this.hidden.value
    this.hidden.value = this.canonical()
    if (this.hidden.value !== prev) {
      this.el.dispatchEvent(
        new CustomEvent("lantern:change", { bubbles: true, detail: { value: this.hidden.value || null } })
      )
    }
  },

  canonical() {
    const v = this.values
    const pad = (n, w = 2) => String(n).padStart(w, "0")

    const dateOk = v.year != null && v.month != null && v.day != null
    const timeOk = v.hour != null && v.minute != null && v.meridiem != null
    const date = dateOk ? `${pad(v.year, 4)}-${pad(v.month)}-${pad(v.day)}` : null

    let time = null
    if (timeOk) {
      let h = v.hour % 12
      if (v.meridiem === "PM") h += 12
      time = `${pad(h)}:${pad(v.minute)}:${pad(v.second ?? 0)}.${pad(v.millisecond ?? 0, 3)}`
    }

    if (this.mode === "date") return date || ""
    if (this.mode === "time") return time || ""
    return date && time ? `${date}T${time}` : ""
  },
}

// ── Picker ────────────────────────────────────────────────────────────────
//
// Composes the segmented field, the calendar, and the overlay runtime into
// the date / datetime pickers. Everything is event-wired (lantern:change /
// lantern:set-*) — no direct hook-to-hook coupling.

const LanternPicker = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]')
    this.toggle = this.el.querySelector('[data-part="toggle"]')
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.calendar = this.panel?.querySelector(".lui-cal")
    this.panelTime = this.panel?.querySelector('[data-part="panel-time"]')
    this.open = false
    this.cleanup = []

    // Panel interaction → push into the trigger field's segments: a calendar
    // day sets the date part; the time pane sets the time part.
    this.panel?.addEventListener("lantern:change", (e) => {
      if (e.target.closest(".lui-cal")) {
        e.stopPropagation()
        this.trigger.dispatchEvent(
          new CustomEvent("lantern:set-date", { detail: { value: e.detail.value } })
        )
      } else if (this.panelTime && e.target.closest('[data-part="panel-time"]')) {
        e.stopPropagation()
        this.trigger.dispatchEvent(
          new CustomEvent("lantern:set-time", { detail: { value: e.detail.value } })
        )
      }
    })

    // Field value changed (typed or via set-*) → keep the calendar and the
    // panel's time pane in sync. Both converge (no-change guards), no loops.
    this.trigger.addEventListener("lantern:change", (e) => {
      const v = e.detail.value
      this.calendar?.dispatchEvent(
        new CustomEvent("lantern:set-value", { detail: { value: v ? v.slice(0, 10) : null } })
      )
      if (this.panelTime && v && v.length >= 23) {
        this.panelTime.dispatchEvent(
          new CustomEvent("lantern:set-time", { detail: { value: v.slice(11) } })
        )
      }
    })

    this.toggle?.addEventListener("click", () => (this.open ? this.hide() : this.show()))

    this.panel?.querySelector('[data-part="today"]')?.addEventListener("click", () => {
      const now = new Date()
      const iso = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
      if (this.el.dataset.mode === "datetime") {
        this.trigger.dispatchEvent(new CustomEvent("lantern:set-now"))
      } else {
        this.trigger.dispatchEvent(new CustomEvent("lantern:set-date", { detail: { value: iso } }))
      }
    })

    this.panel?.querySelector('[data-part="clear-panel"]')?.addEventListener("click", () => {
      this.trigger.dispatchEvent(new CustomEvent("lantern:clear"))
    })

    this.panel?.querySelector('[data-part="done"]')?.addEventListener("click", () => this.hide())
  },

  show() {
    this.open = true
    this.panel.hidden = false
    const reposition = () => position(this.toggle, this.panel, { placement: "bottom-end", gap: 6 })
    reposition()
    // position() pins the panel to the viewport (fixed); follow the anchor
    // while any ancestor scrolls or the window resizes.
    window.addEventListener("scroll", reposition, true)
    window.addEventListener("resize", reposition)
    this.cleanup.push(() => {
      window.removeEventListener("scroll", reposition, true)
      window.removeEventListener("resize", reposition)
    })
    this.toggle.setAttribute("aria-expanded", "true")
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.el }))
    // Focus the calendar's roving-tabindex day for immediate keyboard nav.
    this.panel.querySelector('.lui-cal-day[tabindex="0"]')?.focus()
  },

  hide() {
    if (!this.open) return
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.toggle.setAttribute("aria-expanded", "false")
    this.toggle.focus()
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
  },
}

// App-shell sidebar: collapse/expand to an icon rail, persisted per element id
// in localStorage. Triggered by the sidebar's own collapse control
// ([data-part="sidebar-collapse"]) — deliberately NOT the generic
// [data-part="toggle"], which other components (date picker, dropdown) use
// inside the shell.
const LanternSidebar = {
  key() {
    return `lui-sidebar:${this.el.id}`
  },

  mounted() {
    const stored = localStorage.getItem(this.key())
    if (stored === "true") this.el.setAttribute("data-collapsed", "")
    if (stored === "false") this.el.removeAttribute("data-collapsed")

    this.onToggle = (e) => {
      if (!e.target.closest('[data-part="sidebar-collapse"]')) return
      const collapsed = this.el.toggleAttribute("data-collapsed")
      try {
        localStorage.setItem(this.key(), String(collapsed))
      } catch (_) {}
    }
    this.el.addEventListener("click", this.onToggle)
  },

  updated() {
    const stored = localStorage.getItem(this.key())
    if (stored === "true") this.el.setAttribute("data-collapsed", "")
    if (stored === "false") this.el.removeAttribute("data-collapsed")
  },

  destroyed() {
    this.el.removeEventListener("click", this.onToggle)
  },
}

// Select listbox: toggle opens a positioned listbox; ↑/↓/Home/End move,
// Enter/click selects, Esc/outside closes, printable keys type-ahead. With
// data-multiple, options toggle without closing and one hidden name[] input
// is maintained per selection; with a search input, options filter as you
// type and navigation skips hidden options.
const LanternSelect = {
  mounted() {
    this.toggle = this.el.querySelector('[data-part="toggle"]')
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.native = this.el.querySelector('[data-part="native"]')
    this.label = this.el.querySelector('[data-part="label"]')
    this.search = this.el.querySelector('[data-part="search-input"]')
    this.noResults = this.el.querySelector('[data-part="no-results"]')
    this.multiple = this.el.hasAttribute("data-multiple")
    this.max = parseInt(this.el.dataset.max || "0", 10) || null
    this.cleanup = []
    this.open = false

    this.el.addEventListener("click", (e) => {
      if (e.target.closest('[data-part="clear"]')) {
        e.stopPropagation()
        this.clear()
        return
      }
      if (e.target.closest('[data-part="toggle"]')) this.open ? this.hide() : this.show()
      const opt = e.target.closest('[data-part="option"]')
      if (opt) this.select(opt)
    })

    this.el.addEventListener("keydown", (e) => this.onKey(e))
    if (this.search) {
      this.search.addEventListener("input", () => this.filter())
    }
  },

  options(visibleOnly = false) {
    const all = [...this.el.querySelectorAll('[data-part="option"]')]
    return visibleOnly ? all.filter((o) => !o.hidden) : all
  },

  values() {
    return this.native
      ? [...this.native.selectedOptions].map((o) => o.value).filter((v) => v !== "")
      : []
  },

  // Reflect the chosen values onto the hidden native <select> (the real form
  // control) and fire input+change so LiveView — and LiveViewTest's form/3 —
  // see them. Mirrors Fluxon, which drives a hidden <select> from its custom UI.
  setNative(values) {
    if (!this.native) return
    const set = new Set(values.map(String))
    let changed = false
    for (const opt of this.native.options) {
      const sel = set.has(opt.value)
      if (opt.selected !== sel) {
        opt.selected = sel
        changed = true
      }
    }
    if (changed) {
      this.native.dispatchEvent(new Event("input", { bubbles: true }))
      this.native.dispatchEvent(new Event("change", { bubbles: true }))
    }
  },

  show() {
    this.open = true
    this.panel.hidden = false
    position(this.toggle, this.panel, { placement: "bottom-start" })
    this.panel.style.minWidth = `${this.toggle.offsetWidth}px`
    this.toggle.setAttribute("aria-expanded", "true")
    if (this.search) {
      this.search.value = ""
      this.filter()
      this.search.focus()
    } else {
      const current =
        this.options().find((o) => o.getAttribute("aria-selected") === "true") ||
        this.options()[0]
      current?.focus()
    }
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.toggle }))
  },

  hide(refocus = true) {
    if (!this.open) return
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.toggle.setAttribute("aria-expanded", "false")
    if (refocus) this.toggle.focus()
  },

  filter() {
    const q = (this.search?.value || "").trim().toLowerCase()
    let any = false
    this.options().forEach((o) => {
      const hit = q === "" || o.textContent.trim().toLowerCase().includes(q)
      o.hidden = !hit
      any = any || hit
    })
    if (this.noResults) this.noResults.hidden = any
  },

  select(opt) {
    const value = opt.dataset.value
    if (this.multiple) {
      const selected = opt.getAttribute("aria-selected") === "true"
      if (!selected && this.max && this.values().length >= this.max) return
      opt.setAttribute("aria-selected", String(!selected))
      this.syncMultiple()
      // multi-select stays open for further picks
    } else {
      this.setNative([value])
      this.options().forEach((o) => o.setAttribute("aria-selected", String(o === opt)))
      this.setLabel(opt.querySelector(".lui-select-option-label")?.textContent.trim())
      this.hide()
    }
  },

  syncMultiple() {
    const picked = this.options().filter((o) => o.getAttribute("aria-selected") === "true")
    this.setNative(picked.map((o) => o.dataset.value))
    const labels = picked.map((o) =>
      o.querySelector(".lui-select-option-label")?.textContent.trim()
    )
    this.setLabel(
      labels.length === 0 ? null : labels.length === 1 ? labels[0] : `${labels.length} selected`
    )
  },

  clear() {
    this.setNative([])
    this.options().forEach((o) => o.setAttribute("aria-selected", "false"))
    this.setLabel(null)
    // Hide the clear affordance immediately; a phx-change re-render will drop it
    // from the DOM, but inline display covers the no-phx-change case too.
    const clearBtn = this.el.querySelector('[data-part="clear"]')
    if (clearBtn) clearBtn.style.display = "none"
    if (this.open) this.hide()
  },

  setLabel(text) {
    if (!this.label) return
    if (text) {
      this.label.textContent = text
      this.label.removeAttribute("data-empty")
    } else {
      this.label.textContent = this.label.dataset.placeholder || ""
      this.label.setAttribute("data-empty", "")
    }
  },

  onKey(e) {
    const opts = this.options(true)
    if (!this.open) {
      if (["ArrowDown", "Enter", " "].includes(e.key) && e.target === this.toggle) {
        e.preventDefault()
        this.show()
      }
      return
    }
    const idx = opts.indexOf(document.activeElement)
    if (e.key === "ArrowDown") {
      e.preventDefault()
      opts[Math.min(idx + 1, opts.length - 1)]?.focus()
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      if (idx <= 0 && this.search) this.search.focus()
      else opts[Math.max(idx - 1, 0)]?.focus()
    } else if (e.key === "Home") {
      e.preventDefault()
      opts[0]?.focus()
    } else if (e.key === "End") {
      e.preventDefault()
      opts[opts.length - 1]?.focus()
    } else if (e.key === "Enter" || (e.key === " " && e.target !== this.search)) {
      e.preventDefault()
      if (idx >= 0) this.select(opts[idx])
      else if (this.search && e.key === "Enter" && opts[0]) this.select(opts[0])
    } else if (e.key.length === 1 && /\S/.test(e.key) && e.target !== this.search) {
      const q = e.key.toLowerCase()
      const start = idx + 1
      const hit =
        opts.slice(start).find((o) => o.textContent.trim().toLowerCase().startsWith(q)) ||
        opts.find((o) => o.textContent.trim().toLowerCase().startsWith(q))
      hit?.focus()
    }
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
  },
}

// Autocomplete listbox: static matching or debounced LiveView search. The
// input keeps DOM focus and exposes the highlighted option through
// aria-activedescendant, including across LiveView result patches.
const LanternAutocomplete = {
  mounted() {
    this.open = false
    this.activeIndex = -1
    this.loading = false
    this.dismissRelease = null
    this.pendingSearch = null
    this.inFlightSearches = []
    this.searchSequence = 0
    this.captureElements()

    this.onClick = (e) => {
      const clear = e.target.closest('[data-part="clear"]')
      if (clear) {
        e.preventDefault()
        e.stopPropagation()
        this.clear()
        return
      }
      const opt = e.target.closest('[data-part="option"]')
      if (opt) {
        this.select(opt)
        return
      }
      if (!this.input?.disabled && e.target.closest(".lui-autocomplete-control")) {
        this.input.focus()
        this.show()
      }
    }
    this.onInput = (e) => {
      if (e.target !== this.input || this.input.disabled) return
      this.activeIndex = -1
      this.show()
      this.search()
    }
    this.onFocus = (e) => {
      if (e.target === this.input && this.el.dataset.openOnFocus === "true") this.show()
    }
    this.onKeydown = (e) => this.onKey(e)

    // These listeners stay on the hook root, which LiveView retains. Delegation
    // means patched inputs/options never need their own listeners reattached.
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("focusin", this.onFocus)
    this.el.addEventListener("keydown", this.onKeydown)
    this.updateResults()
  },

  captureElements() {
    this.input = this.el.querySelector('[data-part="input"]')
    this.hidden = this.el.querySelector('[data-part="value"]')
    this.control = this.el.querySelector(".lui-autocomplete-control")
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.resultsContainer = this.el.querySelector('[data-part="options"]')
    this.loadingEl = this.el.querySelector('[data-part="loading"]')
    this.noResults = this.el.querySelector('[data-part="no-results"]')
    this.clearButton = this.el.querySelector('[data-part="clear"]')
  },

  resultSignature() {
    return JSON.stringify({
      options: this.options().map((option) => [
        option.id,
        option.dataset.value,
        this.optionLabel(option),
        option.getAttribute("aria-selected"),
      ]),
      groups: [...this.el.querySelectorAll('[data-part="group"]')].map((group) => [
        group.dataset.depth,
        group.textContent.trim(),
      ]),
      empty: this.noResults?.textContent.trim() || "",
    })
  },

  beforeUpdate() {
    this.patchState = {
      activeValue: this.activeOption()?.dataset.value,
      focused: document.activeElement === this.input,
      hiddenValue: this.hidden?.value || "",
      inputValue: this.input?.value || "",
      selectedLabel: this.selectedLabel(),
      resultsContainer: this.resultsContainer,
      noResults: this.noResults,
      resultSignature: this.resultSignature(),
    }
    // onDismiss closes over the old panel/control. Release it before morphdom
    // can detach those nodes; updated() re-arms against the current pair.
    if (this.open) this.releaseDismissal()
  },

  updated() {
    const state = this.patchState || {}
    this.captureElements()

    const resultsPatched =
      state.resultsContainer !== this.resultsContainer ||
      state.noResults !== this.noResults ||
      state.resultSignature !== this.resultSignature()

    // A hook update can be caused by validation chrome or another unrelated
    // patch. Record result-surface changes, but do not clear loading here: the
    // exact pushEvent reply completes the matching token below, so an older or
    // unrelated patch cannot acknowledge a newer query.
    if (resultsPatched && this.inFlightSearches.length > 0) {
      this.inFlightSearches[0].resultsPatched = true
    }

    if (state.hiddenValue && state.hiddenValue === (this.hidden?.value || "") && !this.selectedOption()) {
      this.retainedValue = state.hiddenValue
      this.retainedLabel = state.selectedLabel
    } else if (this.selectedOption()) {
      this.retainedValue = this.hidden.value
      this.retainedLabel = this.optionLabel(this.selectedOption())
    }

    const pendingQuery = this.pendingSearch?.query
    if (this.input && pendingQuery != null) this.input.value = pendingQuery
    else if (state.focused && this.input) this.input.value = state.inputValue
    else if (this.input && this.retainedValue === (this.hidden?.value || "")) {
      this.input.value = this.retainedLabel || ""
    }

    // Server markup always renders loading/closed. Reapply client-owned state
    // after capturing the replacement nodes without changing pending timers.
    this.setLoading(this.loading)
    if (this.open) {
      this.panel.hidden = false
      this.input?.setAttribute("aria-expanded", "true")
      this.positionPanel()
      this.armDismissal()
    }
    this.updateResults()

    const byValue = this.options(true).find((option) => option.dataset.value === state.activeValue)
    if (byValue) this.setActive(this.options(true).indexOf(byValue))
    else this.setActive(Math.min(this.activeIndex, this.options(true).length - 1))
    if (state.focused) this.input?.focus()
  },

  options(visibleOnly = false) {
    const all = [...this.el.querySelectorAll('[data-part="option"]')]
    return visibleOnly ? all.filter((option) => !option.hidden) : all
  },

  optionLabel(option) {
    return option?.dataset.label || option?.textContent.trim() || ""
  },

  selectedOption() {
    const value = this.hidden?.value || ""
    return this.options().find((option) => option.dataset.value === value)
  },

  selectedLabel() {
    const selected = this.selectedOption()
    if (selected) return this.optionLabel(selected)
    if (this.retainedValue === (this.hidden?.value || "")) return this.retainedLabel || ""
    return ""
  },

  activeOption() {
    return this.options(true)[this.activeIndex]
  },

  positionPanel() {
    if (!this.panel || !this.input) return
    position(this.control || this.input, this.panel, { placement: "bottom-start" })
    this.panel.style.minWidth = `${(this.control || this.input).offsetWidth}px`
  },

  armDismissal() {
    this.releaseDismissal()
    if (!this.panel || !this.control) return
    this.dismissRelease = onDismiss(
      this.panel,
      (reason) => this.hide({ refocus: false, restore: reason === "outside" }),
      { anchor: this.control }
    )
  },

  releaseDismissal() {
    this.dismissRelease?.()
    this.dismissRelease = null
  },

  show() {
    if (!this.input || !this.panel || this.input.disabled) return
    if (!this.open) {
      this.open = true
      this.armDismissal()
    } else if (!this.dismissRelease) {
      this.armDismissal()
    }
    this.panel.hidden = false
    this.input.setAttribute("aria-expanded", "true")
    this.positionPanel()
    this.updateResults()
  },

  hide({ refocus = true, restore = false } = {}) {
    if (!this.open) return
    this.open = false
    this.releaseDismissal()
    this.panel.hidden = true
    this.input?.setAttribute("aria-expanded", "false")
    this.setActive(-1)
    if (restore && this.input) this.input.value = this.selectedLabel()
    if (refocus) this.input?.focus()
  },

  search() {
    const query = (this.input?.value || "").trim()
    const threshold = Math.max(0, parseInt(this.el.dataset.searchThreshold || "0", 10))
    clearTimeout(this.searchTimer)

    if (this.input?.disabled) {
      this.pendingSearch = null
      this.setLoading(false)
      return
    }

    if (query.length < threshold) {
      this.pendingSearch = null
      this.setLoading(false)
      this.updateResults()
      return
    }

    const event = this.el.dataset.serverSearch
    if (!event) {
      this.pendingSearch = null
      this.updateResults()
      return
    }

    const request = { query, token: ++this.searchSequence, phase: "debouncing" }
    this.pendingSearch = request
    this.setLoading(true)
    const debounce = Math.max(0, parseInt(this.el.dataset.debounce || "200", 10))
    this.searchTimer = setTimeout(() => {
      if (this.input?.disabled || this.pendingSearch?.token !== request.token) return
      request.phase = "waiting"
      this.inFlightSearches.push(request)
      this.pushEvent(event, { query }, () => {
        // LiveView applies the event reply's diff in the same turn. Defer one
        // task so loading remains visible through that result patch; this also
        // completes identical/empty results whose DOM signature cannot change.
        setTimeout(() => this.completeSearch(request), 0)
      })
    }, debounce)
  },

  completeSearch(request) {
    this.inFlightSearches = this.inFlightSearches.filter((item) => item.token !== request.token)
    if (this.pendingSearch?.token !== request.token) return
    this.pendingSearch = null
    this.setLoading(false)
    this.updateResults()
  },

  matches(label, query) {
    const candidate = label.toLocaleLowerCase()
    const needle = query.toLocaleLowerCase()
    if (this.el.dataset.searchMode === "exact") return candidate === needle
    if (this.el.dataset.searchMode === "starts-with") return candidate.startsWith(needle)
    return candidate.includes(needle)
  },

  updateResults() {
    if (!this.input) return
    const query = this.input.value.trim()
    const threshold = Math.max(0, parseInt(this.el.dataset.searchThreshold || "0", 10))
    const server = !!this.el.dataset.serverSearch

    this.options().forEach((option) => {
      option.hidden = query.length < threshold || (!server && !this.matches(this.optionLabel(option), query))
    })
    this.updateGroups()

    const any = this.options(true).length > 0
    if (this.noResults) {
      this.noResults.hidden = this.loading || query.length < threshold || any
      if (!this.noResults.hidden && this.noResults.dataset.defaultText !== "false") {
        const template = this.el.dataset.emptyTemplate || "No results"
        if (!this.noResults.querySelector("*")) this.noResults.textContent = template.replaceAll("%{query}", query)
      }
    }
    this.setActive(Math.min(this.activeIndex, this.options(true).length - 1))
  },

  updateGroups() {
    const children = [...(this.resultsContainer?.children || [])]
    children.forEach((item, index) => {
      if (item.dataset.part !== "group") return
      const depth = parseInt(item.dataset.depth || "0", 10)
      let any = false
      for (let i = index + 1; i < children.length; i++) {
        const child = children[i]
        const childDepth = parseInt(child.dataset.depth || "0", 10)
        if (child.dataset.part === "group" && childDepth <= depth) break
        if (child.dataset.part === "option" && !child.hidden) any = true
      }
      item.hidden = !any
    })
  },

  setLoading(loading) {
    this.loading = loading
    if (this.loadingEl) this.loadingEl.hidden = !loading
    this.el.toggleAttribute("data-loading", loading)
    if (loading && this.noResults) this.noResults.hidden = true
  },

  setActive(index) {
    const options = this.options(true)
    this.activeIndex = options.length === 0 ? -1 : Math.max(-1, Math.min(index, options.length - 1))
    options.forEach((option, optionIndex) => option.toggleAttribute("data-active", optionIndex === this.activeIndex))
    const active = options[this.activeIndex]
    if (active) {
      this.input?.setAttribute("aria-activedescendant", active.id)
      active.scrollIntoView?.({ block: "nearest" })
    } else {
      this.input?.removeAttribute("aria-activedescendant")
    }
  },

  select(option) {
    const value = option.dataset.value || ""
    const label = this.optionLabel(option)
    if (this.hidden) {
      this.hidden.value = value
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }))
      this.hidden.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.retainedValue = value
    this.retainedLabel = label
    this.options().forEach((item) => item.setAttribute("aria-selected", String(item === option)))
    if (this.input) this.input.value = label
    if (this.clearButton) this.clearButton.hidden = false
    this.hide()
  },

  clear() {
    clearTimeout(this.searchTimer)
    this.pendingSearch = null
    this.inFlightSearches = []
    this.setLoading(false)
    if (this.hidden) {
      this.hidden.value = ""
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }))
      this.hidden.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.retainedValue = ""
    this.retainedLabel = ""
    this.options().forEach((option) => option.setAttribute("aria-selected", "false"))
    if (this.input) this.input.value = ""
    if (this.clearButton) this.clearButton.hidden = true
    this.hide()
  },

  onKey(e) {
    if (e.target !== this.input || !this.input || this.input.disabled) return
    if (e.key === "Escape" && this.open) {
      e.preventDefault()
      e.stopPropagation()
      this.hide({ restore: true })
      return
    }
    if (!["ArrowDown", "ArrowUp", "Enter"].includes(e.key)) return
    if (!this.open) this.show()

    const options = this.options(true)
    if (e.key === "ArrowDown") {
      e.preventDefault()
      this.setActive(options.length ? (this.activeIndex + 1) % options.length : -1)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this.setActive(options.length ? (this.activeIndex <= 0 ? options.length - 1 : this.activeIndex - 1) : -1)
    } else if (e.key === "Enter" && this.activeOption()) {
      e.preventDefault()
      this.select(this.activeOption())
    }
  },

  destroyed() {
    clearTimeout(this.searchTimer)
    this.releaseDismissal()
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("focusin", this.onFocus)
    this.el.removeEventListener("keydown", this.onKeydown)
  },
}

// Generic collapsible section (data-part="collapse-toggle" flips
// data-collapsed on the hook root; persisted per element id).
const LanternCollapse = {
  key() {
    return `lui-collapse:${this.el.id}`
  },

  restore() {
    const stored = localStorage.getItem(this.key())
    if (stored === "true") this.el.setAttribute("data-collapsed", "")
    if (stored === "false") this.el.removeAttribute("data-collapsed")
  },

  mounted() {
    this.restore()
    this.onClick = (e) => {
      if (!e.target.closest('[data-part="collapse-toggle"]')) return
      const collapsed = this.el.toggleAttribute("data-collapsed")
      try {
        localStorage.setItem(this.key(), String(collapsed))
      } catch (_) {}
    }
    this.el.addEventListener("click", this.onClick)
  },

  // LiveView patches strip client-set attributes — re-apply after every patch.
  updated() {
    this.restore()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
  },
}

// data_table chrome: the built-in search box (debounced) and filter selects
// build Flop filter params client-side and patch the URL — zero page-level
// handlers. Patching goes through a synthetic data-phx-link anchor so we ride
// LiveView's own patch navigation (version-safe).
const LanternTableChrome = {
  mounted() {
    this.path = this.el.dataset.path
    this.base = JSON.parse(this.el.dataset.params || "{}")

    this.onInput = (e) => {
      const t = e.target
      if (t.matches('[data-part="search"]')) {
        clearTimeout(this.debounce)
        this.debounce = setTimeout(() => this.apply(), 300)
      }
    }
    this.onChange = (e) => {
      if (e.target.matches('[data-part="filter"]') || e.target.closest('[data-part="filter-rich"]'))
        this.apply()
    }
    this.onClick = (e) => {
      if (!e.target.closest('[data-part="clear-filters"]')) return
      this.el.querySelectorAll('[data-part="filter"]').forEach((sel) => (sel.value = ""))
      this.el
        .querySelectorAll('[data-part="filter-rich"] input[data-part="value"]')
        .forEach((i) => i.remove())
      this.apply()
    }
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("click", this.onClick)
  },

  apply() {
    const filters = []
    const search = this.el.querySelector('[data-part="search"]')
    if (search && search.value.trim() !== "") {
      filters.push({ field: search.dataset.field, op: search.dataset.op, value: search.value.trim() })
    }
    this.el.querySelectorAll('[data-part="filter"]').forEach((sel) => {
      if (sel.value !== "") {
        filters.push({ field: sel.dataset.field, op: sel.dataset.op, value: sel.value })
      }
    })
    this.el.querySelectorAll('[data-part="filter-rich"]').forEach((wrap) => {
      const values = [...wrap.querySelectorAll('input[data-part="value"]')]
        .map((i) => i.value)
        .filter((v) => v !== "")
      if (values.length === 0) return
      if (wrap.dataset.op === "in") {
        filters.push({ field: wrap.dataset.field, op: "in", values })
      } else {
        filters.push({ field: wrap.dataset.field, op: wrap.dataset.op, value: values[0] })
      }
    })

    const params = { ...this.base }
    delete params.page
    filters.forEach((f, i) => {
      params[`filters[${i}][field]`] = f.field
      if (f.op && f.op !== "==") params[`filters[${i}][op]`] = f.op
      if (f.values) params[`filters[${i}][value]`] = f.values
      else params[`filters[${i}][value]`] = f.value
    })

    const query = Object.entries(params)
      .flatMap(([k, v]) =>
        Array.isArray(v)
          ? v.map((item) => `${encodeURIComponent(k)}[]=${encodeURIComponent(item)}`)
          : [`${encodeURIComponent(k)}=${encodeURIComponent(v)}`]
      )
      .join("&")

    this.patch(`${this.path}?${query}`)
  },

  patch(url) {
    const a = document.createElement("a")
    a.href = url
    a.setAttribute("data-phx-link", "patch")
    a.setAttribute("data-phx-link-state", "push")
    a.style.display = "none"
    this.el.appendChild(a)
    a.click()
    a.remove()
  },

  destroyed() {
    clearTimeout(this.debounce)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("change", this.onChange)
  },
}

// Runtime theming: loads persisted --lantern-* overrides and injects them as a
// stylesheet (light overrides on :root/.light, dark overrides on .dark and the
// system media query), so user-selected themes track the active theme instead
// of clobbering both. Update via window "lantern:set-theme" CustomEvent or the
// server push_event of the same name ({reset: true} clears). Persisted per
// data-storage-key in localStorage.
const LanternTheme = {
  mounted() {
    this.key = this.el.dataset.storageKey || "lui-theme"
    try {
      this.config = JSON.parse(localStorage.getItem(this.key) || "null")
    } catch (_) {
      this.config = null
    }
    this.apply()

    this.onSet = (e) => this.set(e.detail)
    window.addEventListener("lantern:set-theme", this.onSet)
    this.handleEvent("lantern:set-theme", (config) => this.set(config))
  },

  set(config) {
    if (!config || config.reset) {
      this.config = null
      try {
        localStorage.removeItem(this.key)
      } catch (_) {}
    } else {
      this.config = { ...(this.config || {}), ...config }
      try {
        localStorage.setItem(this.key, JSON.stringify(this.config))
      } catch (_) {}
    }
    this.apply()
  },

  vars(map) {
    return Object.entries(map || {})
      .map(([k, v]) => `--lantern-${k.replace(/_/g, "-")}: ${v};`)
      .join(" ")
  },

  apply() {
    let styleEl = document.getElementById("lantern-theme-overrides")
    const html = document.documentElement
    if (!this.config) {
      styleEl?.remove()
      html.removeAttribute("data-lantern-density")
      return
    }
    if (!styleEl) {
      styleEl = document.createElement("style")
      styleEl.id = "lantern-theme-overrides"
      document.head.appendChild(styleEl)
    }
    const light = { ...(this.config.light || {}) }
    if (this.config.radius) light.radius = this.config.radius
    const dark = { ...(this.config.dark || {}) }
    if (this.config.radius) dark.radius = this.config.radius

    styleEl.textContent = [
      `:root, .light { ${this.vars(light)} }`,
      `.dark { ${this.vars(dark)} }`,
      `@media (prefers-color-scheme: dark) { :root:not(.light) { ${this.vars(dark)} } }`,
    ].join("\n")

    if (this.config.density) html.setAttribute("data-lantern-density", this.config.density)
    else html.removeAttribute("data-lantern-density")
  },

  destroyed() {
    window.removeEventListener("lantern:set-theme", this.onSet)
  },
}

export const runtime = { position, trapFocus, onDismiss }

// ── Modal ────────────────────────────────────────────────────────────────────
//
// Dialog on the shared runtime. Opens/closes via DOM events dispatched by
// LanternUI.open_dialog/close_dialog (JS commands target the element; server
// pushes arrive as LiveView events carrying the id).
const LanternModal = {
  mounted() {
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.cleanup = []

    this.el.addEventListener("lantern:dialog:open", () => this.show())
    this.el.addEventListener("lantern:dialog:close", () => this.hide())
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show())
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide())

    this.el.querySelectorAll('[data-part="close"]').forEach((btn) =>
      btn.addEventListener("click", () => this.hide())
    )

    if (this.el.dataset.open != null) this.show()
  },

  show() {
    if (this.open) return
    this.open = true
    this.el.hidden = false
    document.body.style.overflow = "hidden"
    this.cleanup.push(trapFocus(this.panel, this.el.dataset.initialFocus))
    const esc = this.el.dataset.closeOnEsc === "true"
    const outside = this.el.dataset.closeOnOutside === "true"
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc) return
        if (reason === "outside" && !outside) return
        this.hide()
      })
    )
  },

  hide() {
    if (!this.open) return
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    this.el.hidden = true
    document.body.style.overflow = ""
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
    document.body.style.overflow = ""
  },
}

// Sheet: same dialog runtime as the modal, but the panel slides from an edge.
// Exit plays the slide-out keyframe (data-closing) before hiding.
const LanternSheet = {
  mounted() {
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.cleanup = []
    this.el.addEventListener("lantern:dialog:open", () => this.show())
    this.el.addEventListener("lantern:dialog:close", () => this.hide())
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show())
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide())
    this.el.querySelectorAll('[data-part="close"]').forEach((btn) =>
      btn.addEventListener("click", () => this.hide())
    )
    if (this.el.dataset.open != null) this.show()
  },

  show() {
    if (this.open) return
    this.open = true
    clearTimeout(this.closeTimer)
    this.el.removeAttribute("data-closing")
    this.el.hidden = false
    document.body.style.overflow = "hidden"
    this.cleanup.push(trapFocus(this.panel))
    const esc = this.el.dataset.closeOnEsc === "true"
    const outside = this.el.dataset.closeOnOutside === "true"
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc) return
        if (reason === "outside" && !outside) return
        this.hide()
      })
    )
  },

  hide() {
    if (!this.open) return
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    document.body.style.overflow = ""
    // Play the slide-out, then hide. Reduced-motion users get the 0ms path.
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce) {
      this.el.hidden = true
      return
    }
    this.el.setAttribute("data-closing", "")
    this.closeTimer = setTimeout(() => {
      this.el.hidden = true
      this.el.removeAttribute("data-closing")
    }, 200)
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
    clearTimeout(this.closeTimer)
    document.body.style.overflow = ""
  },
}

// ── Dropdown menu ────────────────────────────────────────────────────────────
//
// LanternOverlay behavior + WAI-ARIA menu keyboard interaction: ArrowUp/Down
// move through [role=menuitem]s, Home/End jump, any item click closes.
const LanternDropdown = {
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

    this.panel.addEventListener("click", (e) => {
      if (e.target.closest('[role="menuitem"]')) this.hide()
    })

    this.panel.addEventListener("keydown", (e) => {
      const items = this.items()
      if (items.length === 0) return
      const idx = items.indexOf(document.activeElement)
      if (e.key === "ArrowDown") {
        e.preventDefault()
        items[Math.min(idx + 1, items.length - 1)].focus()
      } else if (e.key === "ArrowUp") {
        e.preventDefault()
        items[Math.max(idx - 1, 0)].focus()
      } else if (e.key === "Home") {
        e.preventDefault()
        items[0].focus()
      } else if (e.key === "End") {
        e.preventDefault()
        items[items.length - 1].focus()
      }
    })
  },

  items() {
    return [...this.panel.querySelectorAll('[role="menuitem"]:not([disabled]):not([data-disabled])')]
  },

  show() {
    this.open = true
    this.panel.hidden = false
    position(this.trigger, this.panel, { placement: this.el.dataset.placement })
    this.trigger.querySelector("[aria-haspopup]")?.setAttribute("aria-expanded", "true")
    const first = this.items()[0]
    if (first) first.focus()
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.trigger }))
  },

  hide() {
    if (!this.open) return
    this.open = false
    this.cleanup.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.trigger.querySelector("[aria-haspopup]")?.setAttribute("aria-expanded", "false")
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
  },
}

// ── Tooltip ────────────────────────────────────────────────────────────────
//
// Hover/focus tooltip. Top/bottom reuse the shared vertical placement helper;
// left/right are fixed-positioned directly because the shared helper only
// supports vertical sides.
const LanternTooltip = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]')
    this.panel = this.el.querySelector('[data-part="panel"]')
    if (!this.trigger || !this.panel) return

    this.open = false
    this.delay = parseInt(this.el.dataset.delay || "200", 10)
    this.onEnter = () => this.scheduleShow()
    this.onLeave = () => this.hide()
    this.onFocusOut = (e) => {
      if (!this.trigger.contains(e.relatedTarget)) this.hide()
    }
    this.onKey = (e) => {
      if (e.key === "Escape") this.hide()
    }
    this.reposition = () => {
      if (this.open) this.place()
    }

    this.trigger.addEventListener("mouseenter", this.onEnter)
    this.trigger.addEventListener("focusin", this.onEnter)
    this.trigger.addEventListener("mouseleave", this.onLeave)
    this.trigger.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("keydown", this.onKey)
  },

  scheduleShow() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.show(), this.delay)
  },

  show() {
    clearTimeout(this.timer)
    if (!this.open) {
      this.open = true
      this.panel.hidden = false
      window.addEventListener("scroll", this.reposition, true)
      window.addEventListener("resize", this.reposition)
    }
    this.place()
  },

  hide() {
    clearTimeout(this.timer)
    if (!this.open) return
    this.open = false
    this.panel.hidden = true
    window.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
  },

  place() {
    const placement = this.el.dataset.placement || "top"
    if (placement === "left" || placement === "right") {
      this.placeSide(placement)
    } else {
      const chosen = position(this.trigger, this.panel, { placement: `${placement}-start`, gap: 6 })
      this.centerHorizontal(chosen.split("-")[0])
    }
  },

  centerHorizontal(side) {
    const a = this.trigger.getBoundingClientRect()
    const f = this.panel.getBoundingClientRect()
    const vw = document.documentElement.clientWidth
    const left = Math.min(Math.max(a.left + (a.width - f.width) / 2, 8), vw - f.width - 8)
    this.panel.style.left = `${left}px`
    this.panel.dataset.placement = side
    this.panel.style.setProperty("--lui-tooltip-arrow-x", `${a.left + a.width / 2 - left}px`)
    this.panel.style.removeProperty("--lui-tooltip-arrow-y")
  },

  placeSide(preferred) {
    const gap = 6
    const a = this.trigger.getBoundingClientRect()
    const f = this.panel.getBoundingClientRect()
    const vw = document.documentElement.clientWidth
    const vh = document.documentElement.clientHeight
    const fitsLeft = a.left - gap - f.width >= 8
    const fitsRight = a.right + gap + f.width <= vw - 8
    let side = preferred
    if (side === "left" && !fitsLeft && fitsRight) side = "right"
    if (side === "right" && !fitsRight && fitsLeft) side = "left"

    let left = side === "left" ? a.left - gap - f.width : a.right + gap
    let top = a.top + (a.height - f.height) / 2
    left = Math.min(Math.max(left, 8), vw - f.width - 8)
    top = Math.min(Math.max(top, 8), vh - f.height - 8)

    this.panel.style.position = "fixed"
    this.panel.style.left = `${left}px`
    this.panel.style.top = `${top}px`
    this.panel.dataset.placement = side
    this.panel.style.setProperty("--lui-tooltip-arrow-y", `${a.top + a.height / 2 - top}px`)
    this.panel.style.removeProperty("--lui-tooltip-arrow-x")
  },

  destroyed() {
    clearTimeout(this.timer)
    this.hide()
    if (!this.trigger) return
    this.trigger.removeEventListener("mouseenter", this.onEnter)
    this.trigger.removeEventListener("focusin", this.onEnter)
    this.trigger.removeEventListener("mouseleave", this.onLeave)
    this.trigger.removeEventListener("focusout", this.onFocusOut)
    document.removeEventListener("keydown", this.onKey)
  },
}

// ── Toasts ─────────────────────────────────────────────────────────────────
//
// Notification stack driven by LiveView push_event("lantern:toast", payload).
const LanternToast = {
  mounted() {
    this.timers = new Set()
    this.toastTimers = new Map()
    this.handleEvent("lantern:toast", (toast) => this.add(toast))
  },

  add({ kind = "info", message = "", title = null, duration = 4000 } = {}) {
    const toast = document.createElement("div")
    toast.className = "lui-toast lui-toast-in"
    toast.dataset.kind = kind || "info"

    const dot = document.createElement("span")
    dot.className = "lui-toast-dot"
    dot.setAttribute("aria-hidden", "true")

    const body = document.createElement("div")
    body.className = "lui-toast-body"
    if (title) {
      const heading = document.createElement("strong")
      heading.className = "lui-toast-title"
      heading.textContent = String(title)
      body.appendChild(heading)
    }

    const copy = document.createElement("p")
    copy.className = "lui-toast-message"
    copy.textContent = message == null ? "" : String(message)
    body.appendChild(copy)

    const close = document.createElement("button")
    close.type = "button"
    close.className = "lui-toast-close"
    close.dataset.part = "close"
    close.setAttribute("aria-label", "Close")
    close.textContent = "×"
    close.addEventListener("click", () => this.remove(toast))

    toast.append(dot, body, close)
    this.el.appendChild(toast)

    const rawDuration = duration == null ? 4000 : Number(duration)
    const ms = Number.isFinite(rawDuration) ? rawDuration : 4000
    if (ms > 0) {
      const timer = this.setTimer(() => this.remove(toast), ms)
      this.toastTimers.set(toast, timer)
    }
  },

  remove(toast) {
    if (!toast || !toast.parentNode) return
    if (toast.classList.contains("lui-toast-out")) return
    this.clearTimer(this.toastTimers.get(toast))
    this.toastTimers.delete(toast)
    toast.classList.remove("lui-toast-in")
    toast.classList.add("lui-toast-out")
    this.setTimer(() => toast.remove(), 150)
  },

  setTimer(callback, ms) {
    const timer = setTimeout(() => {
      this.timers.delete(timer)
      callback()
    }, ms)
    this.timers.add(timer)
    return timer
  },

  clearTimer(timer) {
    if (!timer) return
    clearTimeout(timer)
    this.timers.delete(timer)
  },

  destroyed() {
    this.timers.forEach((timer) => clearTimeout(timer))
    this.timers.clear()
    this.toastTimers.clear()
  },
}

// ── Accordion ─────────────────────────────────────────────────────────────
//
// Client driver for `LanternUI.Components.Accordion`. The server renders the
// full anatomy (headers, panels, idrefs) and the initial open state; this hook
// owns toggling and the WAI-ARIA APG accordion keyboard model — arrow-key focus
// movement between headers can't be delivered server-side. Panels stay in the
// DOM and are shown/hidden via the `hidden` attribute (idrefs always resolve;
// collapsed content leaves the tab order + a11y tree). Open state is client-
// owned after mount and re-applied across LiveView patches (which strip
// hook-set attributes).
const LanternAccordion = {
  // A nested accordion's triggers are descendants of the outer root too. Every
  // query and delegated event must therefore verify which hook root owns it.
  ownedTrigger(node) {
    const trigger = node && node.closest && node.closest('[data-part="trigger"]')
    if (!trigger || trigger.disabled) return null
    return trigger.closest('[phx-hook="LanternAccordion"]') === this.el ? trigger : null
  },

  triggers() {
    return Array.from(this.el.querySelectorAll('[data-part="trigger"]')).filter(
      (trigger) => this.ownedTrigger(trigger) === trigger
    )
  },

  isMultiple() {
    return this.el.dataset.multiple === "true"
  },

  preventsAllClosed() {
    return this.el.dataset.preventAllClosed === "true"
  },

  panelFor(trigger) {
    const item = trigger.closest('[data-part="item"]')
    if (!item || item.closest('[phx-hook="LanternAccordion"]') !== this.el) return null
    return Array.from(item.querySelectorAll('[data-part="panel"]')).find(
      (panel) => panel.closest('[data-part="item"]') === item
    )
  },

  remember(trigger, open) {
    if (trigger.id) this.stateById.set(trigger.id, open)
    const position = this.triggers().indexOf(trigger)
    if (position !== -1) this.stateByPosition[position] = open
  },

  setOpen(trigger, open) {
    const item = trigger.closest('[data-part="item"]')
    const panel = this.panelFor(trigger)
    trigger.setAttribute("aria-expanded", String(open))
    if (panel) panel.hidden = !open
    if (item) item.setAttribute("data-state", open ? "open" : "closed")
    this.remember(trigger, open)
  },

  syncAriaDisabled() {
    const triggers = this.triggers()
    const open = triggers.filter((trigger) => trigger.getAttribute("aria-expanded") === "true")
    const inoperable = this.preventsAllClosed() && open.length === 1 ? open[0] : null
    triggers.forEach((trigger) => {
      if (trigger === inoperable) trigger.setAttribute("aria-disabled", "true")
      else trigger.removeAttribute("aria-disabled")
    })
  },

  enforceConstraints() {
    const triggers = this.triggers()
    const open = triggers.filter((trigger) => trigger.getAttribute("aria-expanded") === "true")
    if (!this.isMultiple()) open.slice(1).forEach((trigger) => this.setOpen(trigger, false))
    const allClosed = this.triggers().every(
      (trigger) => trigger.getAttribute("aria-expanded") !== "true"
    )
    if (this.preventsAllClosed() && allClosed) {
      const first = triggers[0]
      if (first) this.setOpen(first, true)
    }
    this.syncAriaDisabled()
  },

  toggle(trigger) {
    const open = trigger.getAttribute("aria-expanded") === "true"
    if (open && trigger.getAttribute("aria-disabled") === "true") return
    if (!open && !this.isMultiple()) {
      this.triggers().forEach((item) => item !== trigger && this.setOpen(item, false))
    }
    this.setOpen(trigger, !open)
    this.enforceConstraints()
  },

  focusBy(current, delta) {
    const items = this.triggers()
    const i = items.indexOf(current)
    if (i === -1) return
    const next = (i + delta + items.length) % items.length
    items[next].focus()
  },

  captureFocus() {
    const active = this.ownedTrigger(document.activeElement)
    this.focusedId = active && active.id
    this.focusedPosition = active ? this.triggers().indexOf(active) : -1
  },

  restoreFocus() {
    if (this.focusedPosition < 0) return
    const triggers = this.triggers()
    const byId = triggers.find((item) => item.id === this.focusedId)
    const trigger = byId || triggers[this.focusedPosition]
    if (trigger) trigger.focus()
  },

  restoreState() {
    const previousById = this.stateById
    const previousByPosition = this.stateByPosition
    this.stateById = new Map()
    this.stateByPosition = []
    this.triggers().forEach((trigger, position) => {
      const serverOpen = trigger.getAttribute("aria-expanded") === "true"
      const open = previousById.has(trigger.id)
        ? previousById.get(trigger.id)
        : (previousByPosition[position] ?? serverOpen)
      this.setOpen(trigger, open)
    })
    this.enforceConstraints()
  },

  mounted() {
    // State is keyed by stable item id when available and mirrored by owned
    // item position so Fluxon's optional/generated ids can change on a patch.
    this.stateById = new Map()
    this.stateByPosition = []
    this.focusedId = null
    this.focusedPosition = -1
    this.triggers().forEach((trigger) => {
      this.remember(trigger, trigger.getAttribute("aria-expanded") === "true")
    })
    this.enforceConstraints()

    this.onClick = (event) => {
      const trigger = this.ownedTrigger(event.target)
      if (trigger) this.toggle(trigger)
    }

    this.onKeydown = (event) => {
      const trigger = this.ownedTrigger(event.target)
      if (!trigger) return
      const items = this.triggers()
      switch (event.key) {
        case "ArrowDown":
          event.preventDefault()
          this.focusBy(trigger, 1)
          break
        case "ArrowUp":
          event.preventDefault()
          this.focusBy(trigger, -1)
          break
        case "Home":
          event.preventDefault()
          items[0] && items[0].focus()
          break
        case "End":
          event.preventDefault()
          items[items.length - 1] && items[items.length - 1].focus()
          break
      }
    }

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKeydown)
  },

  beforeUpdate() {
    this.captureFocus()
  },

  // LiveView patches re-render the server's initial state and may regenerate
  // optional ids. Reapply client-owned state by stable id, then item position.
  updated() {
    this.restoreState()
    this.restoreFocus()
  },

  disconnected() {
    this.captureFocus()
  },

  reconnected() {
    this.restoreState()
    this.restoreFocus()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKeydown)
  },
}

export const Hooks = {
  ChartHover,
  LineHover,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternSheet,
  LanternDropdown,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternSelect,
  LanternAutocomplete,
  LanternCollapse,
  LanternAccordion,
  LanternTableChrome,
  LanternTheme,
}
export {
  ChartHover,
  LineHover,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternSheet,
  LanternDropdown,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternSelect,
  LanternAutocomplete,
  LanternCollapse,
  LanternAccordion,
  LanternTableChrome,
  LanternTheme,
}
export default Hooks
