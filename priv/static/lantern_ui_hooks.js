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
    this.valuesWrap = this.el.querySelector('[data-part="values"]')
    this.label = this.el.querySelector('[data-part="label"]')
    this.search = this.el.querySelector('[data-part="search-input"]')
    this.noResults = this.el.querySelector('[data-part="no-results"]')
    this.multiple = this.el.hasAttribute("data-multiple")
    this.max = parseInt(this.el.dataset.max || "0", 10) || null
    this.cleanup = []
    this.open = false

    this.el.addEventListener("click", (e) => {
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
    return this.valuesWrap
      ? [...this.valuesWrap.querySelectorAll('[data-part="value"]')].map((i) => i.value)
      : []
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
      const hidden = this.valuesWrap?.querySelector('[data-part="value"]')
      if (hidden && hidden.value !== value) {
        hidden.value = value
        hidden.dispatchEvent(new Event("input", { bubbles: true }))
        hidden.dispatchEvent(new Event("change", { bubbles: true }))
      }
      this.options().forEach((o) => o.setAttribute("aria-selected", String(o === opt)))
      this.setLabel(opt.querySelector(".lui-select-option-label")?.textContent.trim())
      this.hide()
    }
  },

  syncMultiple() {
    const name = `${this.el.dataset.name}[]`
    const picked = this.options().filter((o) => o.getAttribute("aria-selected") === "true")
    this.valuesWrap.innerHTML = ""
    picked.forEach((o) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      input.value = o.dataset.value
      input.setAttribute("data-part", "value")
      this.valuesWrap.appendChild(input)
    })
    const labels = picked.map((o) =>
      o.querySelector(".lui-select-option-label")?.textContent.trim()
    )
    this.setLabel(
      labels.length === 0 ? null : labels.length === 1 ? labels[0] : `${labels.length} selected`
    )
    const first = this.valuesWrap.firstElementChild
    const target = first || this.valuesWrap
    target.dispatchEvent(new Event("input", { bubbles: true }))
    target.dispatchEvent(new Event("change", { bubbles: true }))
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
    this.el.hidden = true
    document.body.style.overflow = ""
  },

  destroyed() {
    this.cleanup.forEach((fn) => fn())
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

export const Hooks = {
  ChartHover,
  LineHover,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternDropdown,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternSelect,
  LanternCollapse,
  LanternTableChrome,
}
export {
  ChartHover,
  LineHover,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternDropdown,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternSelect,
  LanternCollapse,
  LanternTableChrome,
}
export default Hooks
