// LanternUI LiveView hooks.
//
// Import and merge into your LiveSocket hooks:
//
//   import LanternHooks from "../../deps/lantern_ui/priv/static/lantern_ui_hooks.js"
//   let Hooks = { ...LanternHooks /* , ...yourHooks */ }
//   let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, ... })
//
// The file you import is the esbuild bundle of `assets/js/`. Rebuild with
// `npm run build`. Data-attribute behaviours (list nav, persist)
// install themselves on import — no page-local hook.
//
// `ChartHover` draws a crosshair + tooltip over a server-rendered LanternUI chart.
// All geometry is computed in Elixir; the hook only reads the embedded point list
// (viewBox coordinates) and paints the hover layer. No chart library, no React.

import { computePosition, flip, offset, shift, size, autoUpdate } from "@floating-ui/dom"
import { enterLayer, leaveLayer, FLOATING } from "./layer.js"
import { installBehaviours } from "./behaviours.js"

export { installBehaviours }


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

// Shared-x interaction for the generic series-first chart. The server renders
// every overlay and focus target; this hook only updates their attributes and
// text, so LiveView owns the tree and can patch/destroy it at any time.
const ChartInteraction = {
  mounted() {
    this.setup()
  },

  updated() {
    this.cleanup()
    this.setup()
  },

  setup() {
    this.points = JSON.parse(this.el.dataset.interaction || "[]")
    this.seriesLabels = JSON.parse(this.el.dataset.seriesLabel || "[]")
    this.seriesIds = JSON.parse(this.el.dataset.seriesId || "[]")
    this.selectEvent = this.el.dataset.selectEvent
    this.hoverEvent = this.el.dataset.hoverEvent
    this.isBar = ["bar", "stacked_bar", "grouped_bar"].includes(this.el.dataset.chartType)
    this.horizontalBars = this.isBar && this.el.dataset.orientation === "horizontal"
    this.svg = this.el.querySelector("svg")
    this.overlay = this.el.querySelector(".lui-time-series-chart__interaction")
    this.tooltip = this.el.querySelector('[data-part="html-tooltip"]')
    this.live = this.el.querySelector('[data-part="live"]')
    this.focusPoints = [...this.el.querySelectorAll("[data-chart-point]")]
    if (!this.svg || !this.overlay || !this.points.length) return
    this.baseWidth = this.svg.viewBox.baseVal.width
    this.baseLeft = Number(this.el.dataset.plotLeft) || 46
    this.baseRight = Number(this.el.dataset.plotRight) || this.baseWidth - 14
    this.layoutX = (x) => x
    this.layoutNodes = [...this.svg.querySelectorAll('.lui-time-series-chart__grid line, .lui-time-series-chart__zero, .lui-time-series-chart__labels text, .lui-time-series-chart__series path, .lui-time-series-chart__series rect, .lui-time-series-chart__series circle, .lui-time-series-chart__comparison path, .lui-time-series-chart__annotation line, .lui-time-series-chart__annotation text, .lui-time-series-chart__reference line, .lui-time-series-chart__reference text, [data-chart-point]')]
      .map((node) => ({
        node,
        d: node.getAttribute('d'),
        x: Object.fromEntries(["x", "x1", "x2", "cx", "width"].filter((attr) => node.hasAttribute(attr)).map((attr) => [attr, Number(node.getAttribute(attr))]))
      }))
    this.scheduleLayout = () => {
      if (this.layoutFrame) return
      this.layoutFrame = this.el.ownerDocument.defaultView.requestAnimationFrame(() => {
        this.layoutFrame = null
        this.fitWidth()
      })
    }
    const win = this.el.ownerDocument.defaultView
    if (win.ResizeObserver) {
      this.resizeObserver = new win.ResizeObserver(this.scheduleLayout)
      this.resizeObserver.observe(this.el)
    } else {
      win.addEventListener("resize", this.scheduleLayout)
    }
    this.scheduleLayout()

    this.onPointerMove = (event) => {
      this.pendingClientX = event.clientX
      this.pendingClientY = event.clientY
      if (this.frame) return
      this.frame = this.el.ownerDocument.defaultView.requestAnimationFrame(() => {
        this.frame = null
        const point = this.showAtPointer(this.pendingClientX, this.pendingClientY, this.pendingBar)
        if (point) this.scheduleHover(point)
      })
    }
    this.onPointerMove = ((original) => (event) => {
      this.pendingBar = event.target.closest?.('.lui-time-series-chart__bar') || null
      original(event)
    })(this.onPointerMove)
    this.onClick = (event) => {
      const point = this.showAtPointer(event.clientX, event.clientY, event.target.closest?.('.lui-time-series-chart__bar'))
      if (point) this.pushChartEvent(this.selectEvent, point)
    }
    this.onPointerDown = (event) => {
      this.onPointerMove(event)
      this.touchActive = event.pointerType === "touch"
    }
    this.onPointerLeave = (event) => {
      if (!this.touchActive && !this.el.contains(event.relatedTarget)) {
        this.cancelHover()
        this.hide()
      }
    }
    this.onPointerUp = (event) => {
      if (event.pointerType === "touch") {
        this.touchActive = false
        this.touchTimer = setTimeout(() => this.hide(), 2200)
      }
    }
    this.onPointerCancel = () => {
      this.touchActive = false
      if (this.frame) this.el.ownerDocument.defaultView.cancelAnimationFrame(this.frame)
      this.frame = null
      if (this.touchTimer) clearTimeout(this.touchTimer)
      this.touchTimer = null
      this.cancelHover()
      this.hide()
    }
    this.onFocusIn = (event) => {
      const target = event.target.closest?.("[data-chart-point]")
      if (target && this.el.contains(target)) this.show(this.points[Number(target.dataset.chartPoint)], target, true)
    }
    this.onFocusOut = (event) => {
      if (!this.el.contains(event.relatedTarget)) this.hide()
    }
    this.onKeyDown = (event) => {
      const target = event.target.closest?.("[data-chart-point]")
      if (!target || !this.el.contains(target)) return
      const index = Number(target.dataset.chartPoint)
      if (event.key === "Escape") {
        event.preventDefault()
        this.hide()
        target.blur()
      } else if (event.key === "Enter" || event.key === " " || event.key === "Spacebar") {
        event.preventDefault()
        this.pushChartEvent(this.selectEvent, this.points[index])
      } else if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
        event.preventDefault()
        const next = event.key === "Home" ? 0 : event.key === "End" ? this.focusPoints.length - 1 :
          Math.max(0, Math.min(this.focusPoints.length - 1, index + (event.key === "ArrowRight" ? 1 : -1)))
        this.focusPoints[next]?.focus()
      }
    }
    this.svg.addEventListener("pointermove", this.onPointerMove, { passive: true })
    this.svg.addEventListener("pointerdown", this.onPointerDown, { passive: true })
    this.svg.addEventListener("pointerleave", this.onPointerLeave)
    this.svg.addEventListener("pointerup", this.onPointerUp)
    this.svg.addEventListener("pointercancel", this.onPointerCancel)
    this.svg.addEventListener("click", this.onClick)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("keydown", this.onKeyDown)
  },

  fitWidth() {
    const width = Math.round(this.el.getBoundingClientRect().width || this.svg.getBoundingClientRect().width)
    if (width <= 0) return
    const yTicks = [...this.svg.querySelectorAll('.lui-time-series-chart__y-tick')]
    const yLabelWidth = Math.max(0, ...yTicks.map((tick) => typeof tick.getBBox === "function" ? tick.getBBox().width : 0))
    const left = Math.min(Math.max(this.baseLeft, yLabelWidth + 12), width * 0.38)
    const right = Math.max(left + 24, width - 14)
    const ratio = (right - left) / (this.baseRight - this.baseLeft)
    this.layoutX = (x) => left + (x - this.baseLeft) * ratio
    this.svg.setAttribute("viewBox", `0 0 ${width} ${this.svg.viewBox.baseVal.height}`)
    this.svg.setAttribute("preserveAspectRatio", "xMinYMin meet")
    this.svg.style.removeProperty("--chart-text-scale-x")
    for (const { node, d, x } of this.layoutNodes) {
      if (node.classList.contains('lui-time-series-chart__y-tick')) {
        node.setAttribute('x', left - 8)
      } else if (d !== null) {
        let command = ''
        let coordinate = 0
        const path = d.match(/[A-Za-z]|[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?/g)
        node.setAttribute('d', path.map((token) => {
          if (/^[A-Za-z]$/.test(token)) {
            command = token
            coordinate = 0
            return token
          }
          const xCoordinate = command === 'H' || (['M', 'L', 'C'].includes(command) && coordinate % 2 === 0)
          coordinate++
          return xCoordinate ? String(Math.round(this.layoutX(Number(token)) * 10) / 10) : token
        }).join(' '))
      } else {
        for (const [attr, value] of Object.entries(x)) node.setAttribute(attr, attr === 'width' ? value * ratio : this.layoutX(value))
      }
    }
    let previousRight = -Infinity
    for (const tick of this.svg.querySelectorAll('.lui-time-series-chart__x-tick')) {
      tick.removeAttribute('hidden')
      const box = typeof tick.getBBox === 'function' ? tick.getBBox() : null
      if (!box) continue
      const collides = box.x < previousRight + 8 || box.x < 0 || box.x + box.width > width
      if (collides) tick.setAttribute('hidden', '')
      else previousRight = box.x + box.width
    }
    if (this.activePoint) this.show(this.activePoint, null, false, this.activeBar)
  },

  showAtPointer(clientX, clientY, bar = null) {
    const rect = this.svg.getBoundingClientRect()
    if (!rect.width) return
    const width = this.svg.viewBox.baseVal.width
    const x = ((clientX - rect.left) / rect.width) * width
    let nearest = this.points[0]
    if (this.isBar && bar) {
      nearest = this.points[Number(bar.dataset.bandIndex)] || nearest
    } else if (this.horizontalBars) {
      const bars = [...this.svg.querySelectorAll('.lui-time-series-chart__bar')]
      const closest = bars.reduce((best, candidate) => {
        const y = candidate.getBoundingClientRect().top + candidate.getBoundingClientRect().height / 2
        return !best || Math.abs(y - clientY) < Math.abs(best.y - clientY) ? { bar: candidate, y } : best
      }, null)
      if (closest) {
        bar = closest.bar
        nearest = this.points[Number(bar.dataset.bandIndex)] || nearest
      }
    } else {
      for (const point of this.points) if (Math.abs(this.layoutX(point.x) - x) < Math.abs(this.layoutX(nearest.x) - x)) nearest = point
    }
    this.show(nearest, null, false, bar)
    return nearest
  },

  eventPayload(point) {
    return {
      chart_id: this.el.id,
      x: point.x_value,
      values: Object.fromEntries(this.seriesIds.map((id, index) => [id, point.raw_values?.[index] ?? null])),
    }
  },

  pushChartEvent(eventName, point) {
    if (!eventName || !point || typeof this.pushEvent !== "function") return
    this.pushEvent(eventName, this.eventPayload(point))
  },

  scheduleHover(point) {
    if (!this.hoverEvent) return
    if (this.hoverTimer) clearTimeout(this.hoverTimer)
    this.hoverTimer = setTimeout(() => {
      this.hoverTimer = null
      this.pushChartEvent(this.hoverEvent, point)
    }, 150)
  },

  show(point, focusTarget = null, announce = false, bar = null) {
    if (!point) return
    this.activePoint = point
    this.activeBar = bar
    const crosshair = this.overlay.querySelector('[data-part="crosshair"]')
    const bandIndex = this.points.indexOf(point)
    const bars = [...this.svg.querySelectorAll('.lui-time-series-chart__bar')]
    const activeBar = bar || bars.find((candidate) => Number(candidate.dataset.bandIndex) === bandIndex)
    bars.forEach((candidate) => candidate.toggleAttribute('data-active', candidate === activeBar))
    const anchorX = activeBar
      ? Number(activeBar.getAttribute('x')) + Number(activeBar.getAttribute('width')) * (this.horizontalBars ? 1 : 0.5)
      : this.layoutX(point.x)
    if (crosshair) {
      crosshair.setAttribute("x1", anchorX)
      crosshair.setAttribute("x2", anchorX)
    }
    this.overlay.querySelectorAll('[data-part="series-point"]').forEach((circle) => {
      if (this.isBar) {
        circle.setAttribute('hidden', '')
        return
      }
      const index = Number(circle.dataset.seriesIndex)
      const position = point.positions?.[index]
      const y = position?.y ?? point.coords?.[index]
      if (y == null || (position && position.x == null)) {
        circle.setAttribute("hidden", "")
      } else {
        circle.removeAttribute("hidden")
        circle.setAttribute("cx", this.layoutX(position?.x ?? point.x))
        circle.setAttribute("cy", y)
      }
    })
    if (this.tooltip) {
      this.tooltip.querySelector('[data-part="html-tooltip-date"]').textContent = point.label
      this.tooltip.querySelectorAll('[data-part="html-tooltip-value"]').forEach((value, index) => {
        value.textContent = point.values[index] ?? "—"
      })
      this.tooltip.removeAttribute('hidden')
      const tooltipWidth = this.tooltip.offsetWidth || 196
      const tooltipHeight = this.tooltip.offsetHeight || 55
      const chartWidth = this.svg.viewBox.baseVal.width
      const chartHeight = this.svg.viewBox.baseVal.height
      const anchorY = activeBar
        ? Number(activeBar.getAttribute('y')) + Number(activeBar.getAttribute('height')) * (this.horizontalBars ? 0.5 : 0)
        : point.positions?.find((position) => position)?.y ?? point.coords?.find((y) => y != null) ?? 18
      const preferredX = anchorX + 12 + tooltipWidth <= chartWidth ? anchorX + 12 : anchorX - tooltipWidth - 12
      this.tooltip.style.left = `${Math.max(0, Math.min(Math.max(4, preferredX), chartWidth - tooltipWidth - 4))}px`
      const above = anchorY - tooltipHeight - 8
      const preferredY = above >= 4 ? above : anchorY + 16
      this.tooltip.style.top = `${Math.max(4, Math.min(preferredY, chartHeight - tooltipHeight - 4))}px`
    }
    this.overlay.removeAttribute("hidden")
    if (announce) {
      this.live.textContent = `${point.label}. ${this.seriesLabels.map((label, index) => `${label}: ${point.values[index] ?? "no data"}`).join(". ") || point.values.join(". ")}`
    }
    if (focusTarget) {
      this.focusPoints.forEach((target) => target.setAttribute("tabindex", target === focusTarget ? "0" : "-1"))
      const position = point.positions?.[0]
      if (position?.x != null) focusTarget.setAttribute("cx", this.layoutX(position.x))
      if (position?.y != null) focusTarget.setAttribute("cy", position.y)
    }
  },

  hide() {
    this.cancelHover()
    this.overlay?.setAttribute("hidden", "")
    this.tooltip?.setAttribute('hidden', '')
    this.svg?.querySelectorAll('.lui-time-series-chart__bar[data-active]').forEach((bar) => bar.removeAttribute('data-active'))
    this.activePoint = null
    this.activeBar = null
  },

  cancelHover() {
    if (this.hoverTimer) clearTimeout(this.hoverTimer)
    this.hoverTimer = null
  },

  cleanup() {
    if (this.frame) this.el.ownerDocument.defaultView.cancelAnimationFrame(this.frame)
    if (this.layoutFrame) this.el.ownerDocument.defaultView.cancelAnimationFrame(this.layoutFrame)
    this.resizeObserver?.disconnect()
    this.el.ownerDocument.defaultView.removeEventListener("resize", this.scheduleLayout)
    if (this.touchTimer) clearTimeout(this.touchTimer)
    this.cancelHover()
    this.frame = null
    this.svg?.removeEventListener("pointermove", this.onPointerMove)
    this.svg?.removeEventListener("pointerdown", this.onPointerDown)
    this.svg?.removeEventListener("pointerleave", this.onPointerLeave)
    this.svg?.removeEventListener("pointerup", this.onPointerUp)
    this.svg?.removeEventListener("pointercancel", this.onPointerCancel)
    this.svg?.removeEventListener("click", this.onClick)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    this.el.removeEventListener("keydown", this.onKeyDown)
  },

  destroyed() {
    this.cleanup()
  },
}

// ── Runtime core ──────────────────────────────────────────────────────────
//
// Shared substrate for LanternUI's interactive components (popover, dropdown,
// select, date picker). Three pieces:
//
//   position(anchor, floating, opts) — @floating-ui/dom flip+shift placement
//   trapFocus(container)             — dialog-style focus containment
//   onDismiss(el, cb)                — Escape / outside-click dismissal
//
// Component hooks compose these; nothing here touches LiveView state. All
// motion respects prefers-reduced-motion via the --lantern-duration token.

function canFloat() {
  return typeof window !== "undefined" && typeof window.getComputedStyle === "function"
}

// Panels that match their trigger's width (searchable select, autocomplete):
// live-tracks the trigger, but never wider than the room on screen.
const TRIGGER_WIDTH = "min(var(--reference-width, 0px), var(--available-width, 100vw))"

// Position `floating` relative to `anchor` via @floating-ui/dom (flip + shift).
// Placement is "bottom-start" | "bottom-end" | "top-start" | "top-end". Returns
// a promise of the chosen placement. `trackPosition` keeps it attached while
// the overlay is open (scroll / resize / layout).
function position(anchor, floating, { placement = "bottom-start", gap = FLOATING.gutter } = {}) {
  if (!anchor || !floating) return Promise.resolve(placement)
  // Fix before measuring. A panel still in normal flow takes space next to its
  // trigger and the first open lands in the wrong place (see the previous
  // hand-rolled position()). Zeroing offsets first stops a stale one near the
  // viewport edge from squeezing shrink-to-fit.
  floating.style.position = "fixed"
  floating.style.top = "0px"
  floating.style.left = "0px"
  if (!canFloat()) return Promise.resolve(placement)

  const pad = FLOATING.overflowPadding
  return computePosition(anchor, floating, {
    placement,
    strategy: FLOATING.strategy,
    middleware: [
      offset(gap),
      flip({ padding: pad }),
      shift({ padding: pad }),
      // Cap the panel to the room left on the chosen side; it scrolls inside.
      size({
        padding: pad,
        apply({ availableHeight, availableWidth, rects }) {
          floating.style.setProperty("--reference-width", `${Math.round(rects.reference.width)}px`)
          floating.style.setProperty("--available-height", `${Math.max(Math.floor(availableHeight), 96)}px`)
          floating.style.setProperty("--available-width", `${Math.floor(availableWidth)}px`)
        },
      }),
    ],
  }).then(({ x, y, placement: placed }) => {
    floating.style.left = `${x}px`
    floating.style.top = `${y}px`
    return placed
  })
}

// Keeps `floating` attached to `anchor` while open: top layer (never clipped by
// an ancestor), re-placed on scroll of any ancestor, resize, and layout shift
// (including LiveView patches that move the trigger). Returns the cleanup.
function trackPosition(anchor, floating, opts) {
  enterLayer(floating)
  if (!canFloat()) {
    position(anchor, floating, opts)
    return () => leaveLayer(floating)
  }
  const stop = autoUpdate(anchor, floating, () => {
    position(anchor, floating, opts)
  })
  return () => {
    stop()
    leaveLayer(floating)
  }
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
// panel (`data-part="panel"`), positioned via `trackPosition`, focus-trapped,
// dismissed by Escape/outside-click. Component hooks (popover, dropdown,
// date picker) extend this shape or use the primitives directly.
const LanternOverlayLegacy = {
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
    this.cleanup.push(trackPosition(this.trigger, this.panel, { placement: this.el.dataset.placement }))
    this.trigger.setAttribute("aria-expanded", "true")
    this.cleanup.push(trapFocus(this.panel))
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.trigger }))
  },

  hide() {
    this.open = false
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.trigger.setAttribute("aria-expanded", "false")
  },

  destroyed() {
    this.cleanup?.forEach((fn) => fn())
  },
}

// `LanternOverlay` serves two implementations behind one public hook name.
// Roots carrying `data-zag` (popover) run the Zag state machine, loaded on
// demand so pages that render no Zag popover ship no Zag code. Everything
// else stays on the legacy hook.
//
// The legacy methods are spread into this object (not `.call`ed across) so
// their `this.show()` / `this.hide()` cross-calls resolve.
const LanternOverlay = {
  ...LanternOverlayLegacy,

  mounted() {
    if (this.el.hasAttribute("data-zag")) {
      import("./zag/popover.js").then((m) => {
        if (!this.el.isConnected) return
        this._zagDelegate = m.mountZagPopover(this)
      })
    } else {
      LanternOverlayLegacy.mounted.call(this)
    }
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
    else if (!this.el.hasAttribute("data-zag")) LanternOverlayLegacy.destroyed.call(this)
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
    this.cleanup.push(trackPosition(this.toggle, this.panel, { placement: "bottom-end", gap: 6 }))
    this.toggle.setAttribute("aria-expanded", "true")
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.el }))
    // Focus the calendar's roving-tabindex day for immediate keyboard nav.
    this.panel.querySelector('.lui-cal-day[tabindex="0"]')?.focus()
  },

  hide() {
    if (!this.open) return
    this.open = false
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    this.panel.hidden = true
    this.toggle.setAttribute("aria-expanded", "false")
    this.toggle.focus()
  },

  destroyed() {
    this.cleanup?.forEach((fn) => fn())
  },
}

// App-shell sidebar. Two independent states:
//
//   data-collapsed — desktop icon rail, persisted per element id in
//     localStorage. Triggered by the sidebar's own collapse control
//     ([data-part="sidebar-collapse"]) — deliberately NOT the generic
//     [data-part="toggle"], which other components (date picker, dropdown)
//     use inside the shell.
//   data-nav-open — the mobile off-canvas drawer, opened by the bar's
//     hamburger. Ephemeral: closes on scrim click, Escape, widening past the
//     drawer breakpoint, and on any nav item click that is a destination —
//     that last one is what stops a `navigate` link from leaving the drawer
//     over the new page. A disclosure parent is not a destination and is
//     excluded, or opening a section would close the drawer around it.
//
// The drawer attribute is re-asserted in updated() because a LiveView patch
// re-renders the root without it.
const MOBILE_NAV_MQ = "(min-width: 769px)"

const LanternSidebar = {
  key() {
    return `lui-sidebar:${this.el.id}`
  },

  mounted() {
    this.navOpen = false
    this.transientTables = new Set()
    this.transientCollapse = null
    this.sessionCollapseChoice = null
    this.syncCollapsed()

    this.onClick = (e) => {
      if (e.target.closest('[data-part="sidebar-collapse"]')) {
        return this.setCollapsed(!this.el.hasAttribute("data-collapsed"), true)
      }
      if (e.target.closest('[data-part="sidebar-toggle"]')) return this.setNav(!this.navOpen)
      if (e.target.closest('[data-part="sidebar-scrim"]')) return this.setNav(false)

      // A disclosure parent wears .lui-nav-item but is not a destination: it
      // reveals its children in place. Closing the drawer on it would shut the
      // menu in the same click that opened the section, so it is handled here
      // and never falls through to the nav-item rule below.
      const disclosure = e.target.closest('[data-part="nav-disclosure"]')
      if (disclosure) {
        if (!this.el.hasAttribute("data-collapsed")) return
        // On the icon rail the panel is hidden, so the markup's own toggle
        // would flip a section nobody can see — and it would still be flipped
        // when the rail comes back. Take the click instead: open the rail with
        // the section showing. Stopping propagation is what keeps the markup's
        // phx-click from toggling it straight back.
        e.stopPropagation()
        this.setCollapsed(false)
        disclosure.setAttribute("data-expanded", "")
        disclosure.setAttribute("aria-expanded", "true")
        return
      }

      if (e.target.closest('[data-part="sidebar"] .lui-nav-item')) this.setNav(false)
    }
    this.el.addEventListener("click", this.onClick)

    this.showSidebarTooltip = (target) => {
      if (!this.el.hasAttribute("data-collapsed") || !target || !this.el.contains(target)) return
      this.hideFocusTooltip()
      const tooltip = document.createElement("div")
      tooltip.className = "lui-sidebar-tooltip"
      tooltip.setAttribute("role", "tooltip")
      tooltip.textContent = target.dataset.tooltip
      document.body.append(tooltip)
      const rect = target.getBoundingClientRect()
      tooltip.style.left = `${Math.round(rect.right + 8)}px`
      tooltip.style.top = `${Math.round(rect.top + rect.height / 2)}px`
      target.setAttribute("aria-describedby", "lui-sidebar-focus-tooltip")
      tooltip.id = "lui-sidebar-focus-tooltip"
      this.focusTooltipTarget = target
      this.focusTooltip = tooltip
    }
    this.onPointerOver = (e) => {
      const target = e.target.closest("[data-tooltip]")
      if (!target || target === this.focusTooltipTarget) return
      this.showSidebarTooltip(target)
    }
    this.onPointerOut = (e) => {
      const target = e.target.closest("[data-tooltip]")
      if (target && target === this.focusTooltipTarget && !target.contains(e.relatedTarget)) this.hideFocusTooltip()
    }
    this.onFocusIn = (e) => {
      const target = e.target.closest("[data-tooltip]")
      if (!target || !target.matches(":focus-visible")) return
      this.showSidebarTooltip(target)
    }
    this.onFocusOut = (e) => {
      if (e.target === this.focusTooltipTarget || this.focusTooltipTarget?.contains(e.target)) this.hideFocusTooltip()
    }
    this.el.addEventListener("pointerover", this.onPointerOver)
    this.el.addEventListener("pointerout", this.onPointerOut)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)

    this.onTableExpand = (e) => {
      const { tableId, expanded } = e.detail || {}
      if (!tableId) return
      if (expanded) this.transientTables.add(tableId)
      else this.transientTables.delete(tableId)
      this.syncTransientCollapse()
    }
    this.el.addEventListener("lantern:table-expand", this.onTableExpand)
    this.syncTablesFromDOM()

    this.onKey = (e) => e.key === "Escape" && this.setNav(false)
    document.addEventListener("keydown", this.onKey)

    this.mq = window.matchMedia(MOBILE_NAV_MQ)
    this.onMq = () => this.mq.matches && this.setNav(false)
    this.mq.addEventListener("change", this.onMq)
  },

  setCollapsed(collapsed, manual = true) {
    this.el.toggleAttribute("data-collapsed", collapsed)
    if (manual && this.transientCollapse) {
      this.transientCollapse.userChoice = collapsed
      this.sessionCollapseChoice = collapsed
      this.el.toggleAttribute("data-table-expand-sidebar-open", !collapsed)
      return
    }
    if (manual) {
      this.sessionCollapseChoice = null
      this.persistCollapsed(collapsed)
    }
  },

  persistCollapsed(collapsed) {
    try {
      localStorage.setItem(this.key(), String(collapsed))
    } catch (_) {}
  },

  syncTransientCollapse() {
    if (this.transientTables.size > 0) {
      if (!this.transientCollapse) {
        this.transientCollapse = {
          wasCollapsed: this.el.hasAttribute("data-collapsed"),
          userChoice: null,
        }
      }
      this.el.setAttribute("data-table-expand", "")
      const userChoice = this.transientCollapse.userChoice
      this.el.toggleAttribute("data-table-expand-sidebar-open", userChoice === false)
      this.el.toggleAttribute("data-collapsed", userChoice ?? true)
      return
    }
    if (!this.transientCollapse) return
    this.el.removeAttribute("data-table-expand")
    this.el.removeAttribute("data-table-expand-sidebar-open")
    this.el.toggleAttribute(
      "data-collapsed",
      this.transientCollapse.userChoice ?? this.transientCollapse.wasCollapsed,
    )
    this.transientCollapse = null
  },

  syncTablesFromDOM() {
    const expanded = new Set(
      [...this.el.querySelectorAll('[data-expandable="true"][data-expanded="true"]')]
        .map((table) => table.dataset.tableId)
        .filter(Boolean)
    )
    this.transientTables = expanded
    this.syncTransientCollapse()
  },

  setNav(open) {
    if (this.navOpen === open) return
    this.navOpen = open
    this.el.toggleAttribute("data-nav-open", open)
    const btn = this.el.querySelector('[data-part="sidebar-toggle"]')
    if (btn) btn.setAttribute("aria-expanded", String(open))
    // Only the drawer touches the scroll lock, and only on a real transition —
    // re-asserting it every patch would stomp an open modal's lock.
    document.body.style.overflow = open ? "hidden" : ""
  },

  syncCollapsed() {
    const stored = localStorage.getItem(this.key())
    if (stored === "true") this.el.setAttribute("data-collapsed", "")
    if (stored === "false") this.el.removeAttribute("data-collapsed")
  },

  hideFocusTooltip() {
    this.focusTooltip?.remove()
    this.focusTooltip = null
    this.focusTooltipTarget?.removeAttribute("aria-describedby")
    this.focusTooltipTarget = null
  },

  updated() {
    this.syncTablesFromDOM()
    if (this.transientCollapse) {
      const userChoice = this.transientCollapse.userChoice
      this.el.toggleAttribute("data-table-expand-sidebar-open", userChoice === false)
      this.el.toggleAttribute("data-collapsed", userChoice ?? true)
    } else if (this.sessionCollapseChoice !== null) {
      this.el.toggleAttribute("data-collapsed", this.sessionCollapseChoice)
    } else {
      this.syncCollapsed()
    }
    this.el.toggleAttribute("data-nav-open", this.navOpen)
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("pointerover", this.onPointerOver)
    this.el.removeEventListener("pointerout", this.onPointerOut)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    this.hideFocusTooltip()
    this.el.removeEventListener("lantern:table-expand", this.onTableExpand)
    this.transientTables.clear()
    this.syncTransientCollapse()
    document.removeEventListener("keydown", this.onKey)
    this.mq.removeEventListener("change", this.onMq)
    if (this.navOpen) document.body.style.overflow = ""
  },
}

// Select listbox: toggle opens a positioned listbox; ↑/↓/Home/End move,
// Enter/click selects, Esc/outside closes, printable keys type-ahead. With
// data-multiple, options toggle without closing and one hidden name[] input
// is maintained per selection; with a search input, options filter as you
// type and navigation skips hidden options.
const LanternSelectLegacy = {
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
    this.cleanup.push(trackPosition(this.toggle, this.panel, { placement: "bottom-start" }))
    this.panel.style.minWidth = TRIGGER_WIDTH
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
    this.cleanup?.forEach((fn) => fn())
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
    this.cleanup?.forEach((fn) => fn())
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
    this.positionStop = null
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
    this.panel.style.minWidth = TRIGGER_WIDTH
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
      this.positionStop?.()
      this.positionStop = trackPosition(this.control || this.input, this.panel, { placement: "bottom-start" })
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
    this.positionStop?.()
    this.positionStop = null
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
    this.positionStop?.()
    this.positionStop = null
    this.releaseDismissal()
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("focusin", this.onFocus)
    this.el.removeEventListener("keydown", this.onKeydown)
  },
}

// Slider: Zag-driven (`@zag-js/slider`, on-demand chunk). The hook root
// carries `data-zag`; the machine owns the value, pointer drag, and keyboard
// stepping while the native hidden input stays the form surface. Drag moves
// update visuals only, the release commits; keyboard steps commit
// immediately. No legacy path: every slider renders `data-zag`.
const LanternSlider = {
  mounted() {
    import("./zag/slider.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagSlider(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

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
    this.cleanup?.forEach((fn) => fn())
  },
}

// `LanternSelect` serves two implementations behind one public hook name.
// Roots carrying `data-zag` (the non-searchable rich path) run the Zag state
// machine, loaded on demand so pages that render no Zag select ship no Zag
// code. Everything else — notably `searchable` — stays on the legacy hook.
const LanternSelect = {
  // Spread so the legacy path's `this.show()` / `this.hide()` cross-calls
  // resolve (mounted/updated/destroyed below override the spread copies).
  ...LanternSelectLegacy,

  mounted() {
    if (this.el.hasAttribute("data-zag")) {
      import("./zag/select.js").then((m) => {
        if (!this.el.isConnected) return
        this._zagDelegate = m.mountZagSelect(this)
      })
    } else {
      LanternSelectLegacy.mounted.call(this)
    }
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
    else if (!this.el.hasAttribute("data-zag")) LanternSelectLegacy.destroyed.call(this)
  },
}

// data_table chrome: the built-in search box (debounced) and filter selects
// build Flop filter params client-side and patch the URL — zero page-level
// handlers. Patching goes through a synthetic data-phx-link anchor so we ride
// LiveView's own patch navigation (version-safe).
const LanternTableChrome = {
  mounted() {
    this.path = this.el.dataset.path
    this.expanded = this.el.dataset.expanded === "true"
    this.dispatchExpanded()

    this.onInput = (e) => {
      const t = e.target
      if (t.matches('[data-part="search"]')) {
        clearTimeout(this.debounce)
        this.debounce = setTimeout(() => this.apply(t.dataset.field), 300)
      }
    }
    this.onChange = (e) => {
      const rich = e.target.closest('[data-part="filter-rich"]')
      // Filter controls are drafts until Apply. Search and quick-filter links
      // remain immediate so the toolbar stays useful without opening the panel.
      if (
        (e.target.matches('[data-part="filter"]') || rich) &&
        !e.target.closest(".lui-dt-filterpanel-inner")
      ) {
        this.apply((rich || e.target).dataset.field)
      }
    }
    this.onClick = (e) => {
      const apply = e.target.closest('[data-part="apply-filters"]')
      if (apply) {
        this.apply("*")
        return
      }

      const reset = e.target.closest('[data-part="reset-filters"], [data-part="clear-filters"]')
      if (!reset) return
      // Each rich filter clears through its own control, so it can reset its
      // label and aria state; that fires a change we do not want to act on
      // once per filter, hence the suspend.
      this.suspended = true
      this.el.querySelectorAll('[data-part="filter"]').forEach((sel) => (sel.value = ""))
      this.el
        .querySelectorAll('[data-part="filter-rich"] input[data-part="value"]')
        .forEach((i) => i.remove())
      this.el
        .querySelectorAll('[data-part="filter-rich"] [data-part="clear"]')
        .forEach((btn) => btn.click())
      this.suspended = false
      this.apply("*")
    }
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("click", this.onClick)
    this.onKeydown = (e) => {
      if (!this.el.dataset.expandable || e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return
      const owner = e.target?.closest?.('[data-expandable="true"]')
      if (owner && owner !== this.el) return
      if (!owner && e.__lanternTableExpandHandled) return
      if (e.key === "Escape" && this.expanded) {
        // Focused controls and open popovers/dialogs get first use of Escape.
        if (e.target?.closest?.(
          'input, textarea, select, [contenteditable]:not([contenteditable="false"]), [role="textbox"], [role="dialog"], [role="menu"], [role="listbox"], [data-part="content"], [data-part="positioner"], [aria-expanded="true"]'
        )) return
        e.__lanternTableExpandHandled = true
        e.preventDefault()
        this.patch(this.expandedUrl(false))
        return
      }
      if (e.key.toLowerCase() !== "e" || !e.shiftKey) return
      if (e.target?.closest?.('input, textarea, select, [contenteditable]:not([contenteditable="false"]), [role="textbox"]')) return
      e.__lanternTableExpandHandled = true
      e.preventDefault()
      this.patch(this.expandedUrl(!this.expanded))
    }
    document.addEventListener("keydown", this.onKeydown)
  },

  expandedUrl(expanded) {
    const url = new URL(window.location.href)
    if (expanded) url.searchParams.set("expand", "1")
    else url.searchParams.delete("expand")
    return `${url.pathname}${url.search}${url.hash}`
  },

  dispatchExpanded() {
    this.el.dispatchEvent(new CustomEvent("lantern:table-expand", {
      bubbles: true,
      detail: { tableId: this.el.dataset.tableId, expanded: this.expanded },
    }))
  },

  updated() {
    const expanded = this.el.dataset.expanded === "true"
    if (expanded === this.expanded) return
    this.expanded = expanded
    this.dispatchExpanded()
  },

  // `source` is the field the reader just changed, or "*" for clear-all: the
  // one case where a filter a control owns is allowed to disappear.
  apply(source) {
    if (this.suspended) return
    // Read the dataset now rather than at mount: a patch rewrites these, and a
    // cached copy would send back the sort and tab state the page had when it
    // first loaded.
    const base = JSON.parse(this.el.dataset.params || "{}")
    // Filters the URL already carries (a tab preset, a chip). Rebuilding only
    // what the search box and filter panel can show would silently drop them,
    // so a search would knock you out of the tab you were in.
    const kept = JSON.parse(this.el.dataset.keepFilters || "[]")
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
      // A rich filter keeps its value on the hidden <select> the select
      // component drives, whether it is single or multiple. The hidden-input
      // form is what the datetime and autocomplete controls use.
      const native = wrap.querySelector('select[data-part="native"]')
      const values = native
        ? [...native.selectedOptions].map((o) => o.value).filter((v) => v !== "")
        : [...wrap.querySelectorAll('input[data-part="value"]')]
            .map((i) => i.value)
            .filter((v) => v !== "")
      if (values.length === 0) return
      if (wrap.dataset.op === "in") {
        filters.push({ field: wrap.dataset.field, op: "in", values })
      } else {
        filters.push({ field: wrap.dataset.field, op: wrap.dataset.op, value: values[0] })
      }
    })

    // A kept filter stays unless a control already supplies that field, or it is
    // a panel-owned filter the reader just changed or cleared. Kept filters go
    // first so the URL keeps its order.
    const supplied = new Set(filters.map((f) => f.field))
    const survivors = kept.filter(
      (f) => !supplied.has(f.field) && !(f.owned && (source === "*" || source === f.field))
    )
    survivors.forEach((f) => delete f.owned)
    filters.unshift(...survivors)

    const params = { ...base }
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
    this.el.removeEventListener("click", this.onClick)
    document.removeEventListener("keydown", this.onKeydown)
    if (this.expanded) {
      this.expanded = false
      this.dispatchExpanded()
    }
  },
}

// data_table `row_click`: the whole row runs a JS command. Rows that link use a
// real anchor instead (see `.lui-row-link`); this is only for rows that do not.
// A click or Enter that lands on something interactive inside the row belongs to
// that thing, so it is ignored here.
const ROW_INTERACTIVE =
  'a, button, input, select, textarea, label, summary, [role="button"], [data-row-ignore]'

const LanternRowClick = {
  mounted() {
    this.run = (e, row) => {
      const code = row.dataset.rowClick
      if (code) this.liveSocket.execJS(row, code)
    }
    this.target = (e) => {
      const row = e.target.closest("[data-row-click]")
      if (!row || !this.el.contains(row)) return null
      const hit = e.target.closest(ROW_INTERACTIVE)
      return hit && hit !== row && row.contains(hit) ? null : row
    }
    this.onClick = (e) => {
      if (e.defaultPrevented || e.button !== 0) return
      const row = this.target(e)
      if (row) this.run(e, row)
    }
    this.onKeydown = (e) => {
      if (e.key !== "Enter" || e.target.closest("[data-row-click]") !== e.target) return
      this.run(e, e.target)
    }
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKeydown)
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKeydown)
  },
}

const TILE_INTERACTIVE =
  'a, button, input, select, textarea, label, summary, [role="button"], [data-tile-ignore]'

const LanternMediaTile = {
  mounted() {
    this.toggle = () => {
      if (this.el.dataset.selectable !== "true") return
      const nextSelected = this.el.dataset.selected !== "true"
      const eventName = this.el.dataset.tileSelect

      if (eventName && this.pushEvent) {
        this.pushEvent(eventName, { id: this.el.id, selected: nextSelected })
      } else {
        const checkbox = this.el.querySelector('[data-part="selection"] [role="checkbox"]')
        if (checkbox) {
          checkbox.setAttribute("data-checked", String(nextSelected))
          checkbox.setAttribute("aria-checked", String(nextSelected))
        }
        this.el.dataset.selected = String(nextSelected)
        this.el.setAttribute("aria-selected", String(nextSelected))
        this.el.dispatchEvent(
          new CustomEvent("lantern:tile:select", {
            bubbles: true,
            detail: { id: this.el.id, selected: nextSelected },
          })
        )
      }
    }

    this.onClick = (e) => {
      if (e.defaultPrevented || e.button !== 0) return
      const checkbox = e.target.closest('[data-part="selection"] [role="checkbox"]')
      if (checkbox) {
        this.toggle()
        return
      }
      const interactive = e.target.closest(TILE_INTERACTIVE)
      if (interactive && interactive !== this.el) return

      if (this.el.dataset.selectable === "true") {
        this.toggle()
      }
    }

    this.onKeydown = (e) => {
      if (!e.target.closest('[data-part="selection"] [role="checkbox"]')) return
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault()
        this.toggle()
      }
    }

    this.onImageError = (e) => {
      const image = e.target.closest('[data-part="image"]')
      if (!image) return
      image.hidden = true
      const empty = this.el.querySelector('[data-part="empty"]')
      if (empty) empty.hidden = false
      this.el.dataset.empty = "true"
    }

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKeydown)
    this.el.addEventListener("error", this.onImageError, true)
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKeydown)
    this.el.removeEventListener("error", this.onImageError, true)
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
    this.applyPreset()

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

  updated() {
    this.applyPreset()
  },

  // Built-in preset from `<Theme.theme preset="...">`: a data attribute on
  // <html> that the preset scope in lantern_ui_theme.css keys off. Independent
  // of persisted overrides; a nil preset removes only the value it set.
  applyPreset() {
    const html = document.documentElement
    const preset = this.el.dataset.preset
    if (preset) html.setAttribute("data-lantern-theme", preset)
    else if (html.getAttribute("data-lantern-theme")) html.removeAttribute("data-lantern-theme")
  },

  destroyed() {
    this.cleanup?.forEach((fn) => fn())
  },
}

export const runtime = { position, trackPosition, trapFocus, onDismiss, installBehaviours }

const LanternModalLegacy = {
  // The SERVER owns `open` for this overlay: the component renders
  // `data-open={@open || nil}` and `hidden={!@open}` from an assign. Without
  // this, the hook only ever learns about opening in `mounted()`, so a sheet
  // opened by a LiveView patch leaves `this.open === false` — and `hide()`
  // starts with `if (!this.open) return`, so the close button, Escape, and the
  // backdrop ALL silently no-op. The overlay is visible and unclosable.
  //
  // Follow the DOM rather than assert over it (the opposite of LanternCommand,
  // where the hook owns the state and re-asserts `hidden`).
  updated() {
    const wantOpen = this.el.dataset.open != null
    if (wantOpen === this.open) return

    if (wantOpen) {
      this.show()
      return
    }

    // Server closed it. Reconcile WITHOUT running `data-on-close`: the server
    // already knows, so firing it again is an echo back to the process that
    // just told us.
    this.open = false
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    document.body.style.overflow = ""
    clearTimeout(this.closeTimer)
    this.el.hidden = true
    this.el.removeAttribute("data-closing")
  },
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
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    this.el.hidden = true
    document.body.style.overflow = ""
  },

  destroyed() {
    this.cleanup?.forEach((fn) => fn())
    document.body.style.overflow = ""
  },
}


// ── Modal ────────────────────────────────────────────────────────────────────
//
// `LanternModal` serves two implementations behind one public hook name.
// Roots carrying `data-zag` (every `<.modal>` and `<.alert_dialog>`) run the
// Zag state machine, loaded on demand. Everything else — notably hand-rolled
// dialog markup such as enventory_new's dismantle-modal — stays on the
// legacy hook, so `LanternUI.open_dialog/close_dialog` keep working there.
// `LanternModal` serves two implementations behind one public hook name.
// Roots carrying `data-zag` (every `<.modal>` and `<.alert_dialog>`) run the
// Zag state machine, loaded on demand. Everything else — notably hand-rolled
// dialog markup such as enventory_new's dismantle-modal — stays on the
// legacy hook, so `LanternUI.open_dialog/close_dialog` keep working there.
//
// The legacy methods are spread into this object (not `.call`ed across) so
// their `this.show()` / `this.hide()` cross-calls resolve.
const LanternModal = {
  ...LanternModalLegacy,

  mounted() {
    if (this.el.hasAttribute("data-zag")) {
      import("./zag/dialog.js").then((m) => {
        if (!this.el.isConnected) return
        this._zagDelegate = m.mountZagDialog(this)
      })
    } else {
      LanternModalLegacy.mounted.call(this)
    }
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
    else LanternModalLegacy.updated.call(this)
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
    else if (!this.el.hasAttribute("data-zag")) LanternModalLegacy.destroyed.call(this)
  },
}

// ── Command palette ──────────────────────────────────────────────────────────
//
// Modal combobox over a listbox. Same dialog runtime as the modal (focus trap,
// scroll lock, Escape/backdrop dismissal) plus a global Meta/Ctrl+<hotkey>.
//
// The hook NEVER filters items — the server renders exactly what it wants
// shown. The hook owns: the query push (debounced), the highlight, and
// aria-activedescendant. It also pushes selection, so the component carries no
// phx-change/phx-submit and no <form> that could collide with a host app's own
// test selectors.
const LanternCommand = {
  mounted() {
    this.open = false
    this.activeIndex = -1
    this.cleanup = []
    this.capture()

    this.onClick = (e) => {
      const item = e.target.closest('[data-part="item"]')
      if (item && !item.disabled && this.el.contains(item)) this.select(item)
    }
    this.onInput = (e) => {
      if (e.target !== this.input) return
      this.activeIndex = -1
      this.search()
    }
    this.onKeydown = (e) => this.onKey(e)
    this.onHotkey = (e) => {
      const key = this.el.dataset.hotkey
      if (!key || e.key.toLowerCase() !== key.toLowerCase()) return
      if (!e.metaKey && !e.ctrlKey) return
      e.preventDefault()
      this.open ? this.hide() : this.show()
    }

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("keydown", this.onKeydown)
    document.addEventListener("keydown", this.onHotkey)

    this.el.addEventListener("lantern:dialog:open", () => this.show())
    this.el.addEventListener("lantern:dialog:close", () => this.hide())
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show())
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide())

    this.el.querySelectorAll('[data-part="close"]').forEach((btn) =>
      btn.addEventListener("click", () => this.hide())
    )

    this.syncEmpty()
    if (this.el.dataset.open != null) this.show()
  },

  capture() {
    this.panel = this.el.querySelector('[data-part="panel"]')
    this.input = this.el.querySelector('[data-part="input"]')
    this.list = this.el.querySelector('[data-part="list"]')
    this.emptyEl = this.el.querySelector('[data-part="empty"]')
  },

  beforeUpdate() {
    this.patchState = {
      activeValue: this.items()[this.activeIndex]?.dataset.value,
      focused: document.activeElement === this.input,
      query: this.input?.value || "",
    }
  },

  updated() {
    const state = this.patchState || {}
    this.capture()
    // Re-assert visibility. The server renders `hidden={!@open}` and @open
    // defaults to false, so EVERY patch caused by on_search re-adds the
    // attribute and the palette disappears mid-typing — while the hook still
    // believes it is open, so the next hotkey press "closes" an already
    // invisible palette and you have to press it twice.
    //
    // Other overlay hooks omit this safely because their contents are rarely
    // server-patched while open. A search palette's contents are patched on
    // every keystroke, so here it is the normal case rather than an edge one.
    this.el.hidden = !this.open
    // The server re-renders the input without a value attribute; morphdom can
    // still drop the live value when the node is replaced outright.
    if (this.input && this.input.value !== state.query) this.input.value = state.query
    this.syncEmpty()
    const byValue = this.items().findIndex((i) => i.dataset.value === state.activeValue)
    this.setActive(byValue >= 0 ? byValue : Math.min(this.activeIndex, this.items().length - 1))
    if (state.focused && this.open) this.input?.focus()
  },

  // pushEvent goes to the parent LiveView. When the palette is rendered from a
  // LiveComponent that is the wrong target — the parent would have to define
  // handlers it does not own — so route to the component when data-target is
  // present.
  //
  // Keep this name distinct from every other method on the hook. An object
  // literal silently keeps only the LAST definition of a duplicated key, so a
  // second `push` further down shadowed this router entirely: the LiveComponent
  // routing became dead code and the surviving method recursed into itself on
  // every keystroke.
  pushTo(event, payload) {
    const target = this.el.dataset.target
    if (target) {
      this.pushEventTo(target, event, payload)
    } else {
      this.pushEvent(event, payload)
    }
  },

  items() {
    return [...this.el.querySelectorAll('[data-part="item"]')].filter((i) => !i.disabled)
  },

  // Visibility only, never filtering: an explicit empty state must not sit
  // alongside results when a patch races the consumer's own `:if`.
  syncEmpty() {
    if (this.emptyEl) this.emptyEl.hidden = this.items().length > 0
  },

  show() {
    if (this.open) return
    this.open = true
    this.el.hidden = false
    enterLayer(this.el)
    document.body.style.overflow = "hidden"
    if (this.input) this.input.value = ""
    this.setActive(-1)
    this.cleanup.push(trapFocus(this.panel, '[data-part="input"]'))
    const esc = this.el.dataset.closeOnEsc === "true"
    const outside = this.el.dataset.closeOnOutside === "true"
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc) return
        if (reason === "outside" && !outside) return
        this.hide()
      })
    )
    if (this.el.dataset.searchOnOpen === "true") this.pushSearch()
  },

  hide() {
    if (!this.open) return
    this.open = false
    clearTimeout(this.searchTimer)
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    this.setActive(-1)
    leaveLayer(this.el)
    this.el.hidden = true
    document.body.style.overflow = ""
  },

  search() {
    clearTimeout(this.searchTimer)
    const debounce = Math.max(0, parseInt(this.el.dataset.debounce || "200", 10))
    this.searchTimer = setTimeout(() => this.pushSearch(), debounce)
  },

  pushSearch() {
    const event = this.el.dataset.onSearch
    if (!event) return
    this.pushTo(event, { query: (this.input?.value || "").trim() })
  },

  select(item) {
    // An item carrying its own phx-click is already handled by LiveView —
    // pushing on_select too would fire the consumer's handler twice.
    const event = this.el.dataset.onSelect
    if (event && !item.hasAttribute("phx-click")) {
      this.pushTo(event, { value: item.dataset.value ?? null })
    }
    if (this.el.dataset.closeOnSelect === "true") this.hide()
  },

  setActive(index) {
    const items = this.items()
    this.activeIndex = items.length === 0 ? -1 : Math.max(-1, Math.min(index, items.length - 1))
    items.forEach((item, i) => {
      const active = i === this.activeIndex
      item.toggleAttribute("data-active", active)
      item.setAttribute("aria-selected", active ? "true" : "false")
    })
    const active = items[this.activeIndex]
    if (active) {
      this.input?.setAttribute("aria-activedescendant", active.id)
      active.scrollIntoView({ block: "nearest" })
    } else {
      this.input?.removeAttribute("aria-activedescendant")
    }
  },

  onKey(e) {
    if (!this.open) return
    const items = this.items()
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault()
        this.setActive(this.activeIndex + 1 >= items.length ? 0 : this.activeIndex + 1)
        break
      case "ArrowUp":
        e.preventDefault()
        this.setActive(this.activeIndex <= 0 ? items.length - 1 : this.activeIndex - 1)
        break
      case "Home":
        e.preventDefault()
        this.setActive(0)
        break
      case "End":
        e.preventDefault()
        this.setActive(items.length - 1)
        break
      case "Enter": {
        const active = items[this.activeIndex]
        if (!active) return
        e.preventDefault()
        // Dispatch a real click so a per-item phx-click binding still fires;
        // the delegated listener above turns it into select().
        active.click()
        break
      }
    }
  },

  destroyed() {
    clearTimeout(this.searchTimer)
    this.cleanup?.forEach((fn) => fn())
    document.removeEventListener("keydown", this.onHotkey)
    document.body.style.overflow = ""
  },
}

// Sheet: Zag-driven (`@zag-js/dialog`, on-demand chunk) with the slide-from-
// edge panel and the `data-closing` exit keyframe. Same open/close contracts
// as the modal (`lantern:dialog:*` DOM + server events, server `data-open`
// ownership). No legacy path: every sheet renders `data-zag`.
const LanternSheet = {
  mounted() {
    import("./zag/sheet.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagSheet(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// ── Dropdown menu ────────────────────────────────────────────────────────────
//
// Zag-driven (`@zag-js/menu`, on-demand chunk, shared with `LanternMenu`).
// The hook root carries `data-zag`; the machine owns open state, arrow-key /
// Home/End navigation, typeahead, and positioning. Any `[role="menuitem"]`
// click still closes. No legacy path: every dropdown renders `data-zag`.
const LanternDropdown = {
  mounted() {
    import("./zag/menu.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagDropdown(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// Menu button: Zag-driven (`@zag-js/menu`, same on-demand chunk as the
// dropdown). The component owns the trigger button, so the machine `ids`
// override keeps its stable `…-trigger` / `…-menu` ids. No legacy path:
// every menu renders `data-zag`. Menubar below stays on its dedicated hook.
const LanternMenu = {
  mounted() {
    import("./zag/menu.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagMenu(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// Menubar: one horizontal row of role=menuitem triggers with roving tabindex
// (ArrowLeft/ArrowRight wrap, Home/End jump). ArrowDown/Enter/Space open the
// submenu on its first item, ArrowUp on its last. While a submenu is open,
// ArrowRight/ArrowLeft move to the adjacent top-level item and open its
// submenu; Escape closes and returns focus to the top-level item.
const LanternMenubar = {
  mounted() {
    this.openTrigger = null
    this.cleanup = []

    const triggers = this.triggers()
    triggers.forEach((t, i) => t.setAttribute("tabindex", i === 0 ? "0" : "-1"))

    this.el.addEventListener("click", (e) => {
      const trigger = e.target.closest('[data-part="trigger"]')
      if (trigger) {
        this.openTrigger === trigger ? this.close() : this.openMenu(trigger)
      } else if (e.target.closest('[role="menuitem"]')) {
        // Closing via activation returns focus to the top-level trigger
        // (close() hides while focus is inside, which would drop it on <body>).
        const opener = this.openTrigger
        this.close()
        if (opener) opener.focus()
      }
    })

    this.el.addEventListener("keydown", (e) => {
      const triggers = this.triggers()
      const onTrigger = e.target.closest('[data-part="trigger"]')

      if (onTrigger) {
        let next = null
        const idx = triggers.indexOf(onTrigger)
        if (e.key === "ArrowRight") next = triggers[(idx + 1) % triggers.length]
        else if (e.key === "ArrowLeft") next = triggers[(idx - 1 + triggers.length) % triggers.length]
        else if (e.key === "Home") next = triggers[0]
        else if (e.key === "End") next = triggers[triggers.length - 1]
        else if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault()
          this.openMenu(onTrigger, e.key === "ArrowUp" ? "last" : "first")
          return
        }
        if (next) {
          e.preventDefault()
          const wasOpen = this.openTrigger !== null
          rove(triggers, next)
          if (wasOpen) this.openMenu(next)
        }
        return
      }

      const menu = e.target.closest('[data-part="menu"]')
      if (!menu || !this.openTrigger) return
      const items = menuItems(menu)
      const next = items.length > 0 && menuNav(e.key, items)
      if (next) {
        e.preventDefault()
        rove(items, next)
      } else if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
        e.preventDefault()
        const dir = e.key === "ArrowRight" ? 1 : -1
        const idx = triggers.indexOf(this.openTrigger)
        const adjacent = triggers[(idx + dir + triggers.length) % triggers.length]
        rove(triggers, adjacent)
        this.openMenu(adjacent)
      } else if (e.key === "Tab") {
        this.close()
      }
    })
  },

  triggers() {
    return [...this.el.querySelectorAll('[data-part="trigger"]:not([disabled])')]
  },

  menuFor(trigger) {
    return document.getElementById(trigger.getAttribute("aria-controls"))
  },

  openMenu(trigger, focusTarget = "first") {
    this.close()
    const menu = this.menuFor(trigger)
    if (!menu) return
    this.openTrigger = trigger
    // Keep the roving tabindex in sync on every open path (mouse click
    // included): the focused menubar item must be the single tab stop.
    rove(this.triggers(), trigger)
    menu.hidden = false
    this.cleanup.push(trackPosition(trigger, menu, { placement: "bottom-start" }))
    trigger.setAttribute("aria-expanded", "true")
    const items = menuItems(menu)
    const target = focusTarget === "last" ? items[items.length - 1] : items[0]
    if (target) rove(items, target)
    this.cleanup.push(
      onDismiss(
        menu,
        (reason) => {
          this.close()
          // Rove, not just focus: the trigger must also become the single
          // tab stop so tabbing away and back lands on it.
          if (reason === "escape") rove(this.triggers(), trigger)
        },
        { anchor: trigger },
      ),
    )
  },

  close() {
    if (!this.openTrigger) return
    const menu = this.menuFor(this.openTrigger)
    this.cleanup?.forEach((fn) => fn())
    this.cleanup = []
    if (menu) menu.hidden = true
    this.openTrigger.setAttribute("aria-expanded", "false")
    this.openTrigger = null
  },

  destroyed() {
    this.cleanup?.forEach((fn) => fn())
  },
}

// ── Tooltip ────────────────────────────────────────────────────────────────
//
// Zag-driven (`@zag-js/tooltip`, on-demand chunk). The hook root carries
// `data-zag`; the machine owns open state, hover/focus timing, and
// positioning. There is no legacy path — every tooltip renders `data-zag`.
const LanternTooltip = {
  mounted() {
    import("./zag/tooltip.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagTooltip(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// ── Switch ─────────────────────────────────────────────────────────────────
//
// Zag-driven (`@zag-js/switch`, on-demand chunk). Native inputs stay the form
// surface; the machine owns checked state. No legacy path — the switch was
// hook-free before, every instance renders `data-zag`.
const LanternSwitch = {
  mounted() {
    import("./zag/switch.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagSwitch(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// ── Radio group ────────────────────────────────────────────────────────────
//
// Zag-driven (`@zag-js/radio-group`, on-demand chunk). Native radio inputs
// stay the form surface; the machine owns the value and arrow-key nav.
// No legacy path — the radio group was hook-free before, every instance
// renders `data-zag`.
const LanternRadio = {
  mounted() {
    import("./zag/radio_group.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagRadioGroup(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

// ── Toasts ─────────────────────────────────────────────────────────────────
//
// Notification stack driven by LiveView push_event("lantern:toast", payload).
const LanternToast = {
  mounted() {
    this.timers = new Set()
    this.toastTimers = new Map()
    this.toastOrder = Date.now() * 1000
    this.clientEl = this.el.querySelector('[data-part="client"]')
    this.expanded = false
    this.hovered = false
    this.focusWithin = false
    this.onPointerEnter = () => { this.hovered = true; this.syncExpanded() }
    this.onPointerLeave = () => { this.hovered = false; this.syncExpanded() }
    this.onFocusIn = () => { this.focusWithin = true; this.syncExpanded() }
    this.onFocusOut = (event) => {
      if (!this.el.contains(event.relatedTarget)) { this.focusWithin = false; this.syncExpanded() }
    }
    this.onVisibilityChange = () => document.visibilityState === "hidden" ? this.pauseAll() : this.resumeAll()
    this.onClick = (event) => {
      const close = event.target.closest?.('[data-part="close"]')
      if (close && this.el.contains(close)) {
        const toast = close.closest(".lui-toast")
        if (!toast?.dataset.flashKey) this.remove(toast)
        return
      }
      const action = event.target.closest?.('[data-part="action"]')
      if (!action || !this.el.contains(action)) return
      const toast = action.closest(".lui-toast")
      if (action.dataset.event) this.pushEvent(action.dataset.event, {})
      this.remove(toast)
    }
    this.el.addEventListener("pointerenter", this.onPointerEnter)
    this.el.addEventListener("pointerleave", this.onPointerLeave)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("click", this.onClick)
    document.addEventListener("visibilitychange", this.onVisibilityChange)
    this.handleEvent("lantern:toast", (toast) => this.add(toast))
    this.el.querySelectorAll(".lui-toast").forEach((toast) => this.initializeToast(toast))
    this.syncTimers()
    // Top layer, like every other overlay; re-raised above panels opened later.
    enterLayer(this.el)
  },

  updated() {
    this.el.querySelectorAll(".lui-toast").forEach((toast) => this.initializeToast(toast))
    const current = new Set(this.el.querySelectorAll(".lui-toast"))
    for (const [toast, state] of this.toastTimers) {
      if (current.has(toast)) continue
      this.clearTimer(state.timer)
      this.toastTimers.delete(toast)
    }
    this.enforceLimit()
    this.syncTimers()
  },

  add({ kind = "info", message = "", title = null, duration = 4000, action = null } = {}) {
    const toast = document.createElement("div")
    toast.className = "lui-toast lui-toast-in"
    toast.dataset.kind = kind || "info"
    if (title) {
      const header = document.createElement("div")
      header.className = "lui-toast-header"
      const heading = document.createElement("strong")
      heading.className = "lui-toast-title"
      heading.textContent = String(title)
      header.append(heading, this.closeButton())
      toast.appendChild(header)
    }

    const body = document.createElement("div")
    body.className = "lui-toast-body"
    const copy = document.createElement("p")
    copy.className = "lui-toast-message"
    copy.textContent = message == null ? "" : String(message)
    body.appendChild(copy)
    if (!title) body.appendChild(this.closeButton())
    toast.appendChild(body)

    if (action && typeof action.label === "string" && typeof action.event === "string") {
      const actions = document.createElement("div")
      actions.className = "lui-toast-actions"
      const button = document.createElement("button")
      button.type = "button"
      button.className = "lui-btn"
      button.dataset.part = "action"
      button.dataset.size = "sm"
      button.dataset.variant = "solid"
      button.dataset.color = "primary"
      button.dataset.event = action.event
      button.textContent = action.label
      actions.appendChild(button)
      toast.appendChild(actions)
    }

    this.clientEl.insertBefore(toast, this.clientEl.firstChild)
    this.initializeToast(toast, duration)
    this.enforceLimit()
    this.syncTimers()
  },

  closeButton() {
    const close = document.createElement("button")
    close.type = "button"
    close.className = "lui-toast-close"
    close.dataset.part = "close"
    close.setAttribute("aria-label", "Close notification")
    close.textContent = "×"
    return close
  },

  initializeToast(toast, duration = 4000) {
    if (toast.dataset.initialized) return
    toast.dataset.initialized = "true"
    const ms = toast.dataset.flashKey
      ? 0
      : Number.isInteger(duration) && duration >= 0 ? duration : 4000
    toast.dataset.createdAt ||= String(++this.toastOrder)
    toast.style.setProperty("--duration", `${ms}ms`)
    if (ms === 0) return
    const progress = document.createElement("span")
    progress.className = "lui-toast-progress"
    progress.setAttribute("aria-hidden", "true")
    toast.appendChild(progress)
    this.toastTimers.set(toast, { remaining: ms, timer: null, startedAt: null })
  },

  startTimer(toast) {
    const state = this.toastTimers.get(toast)
    if (!state || state.timer || state.remaining <= 0) return
    state.startedAt = Date.now()
    state.timer = this.setTimer(() => this.remove(toast), state.remaining)
  },

  pauseTimer(toast) {
    const state = this.toastTimers.get(toast)
    if (!state?.timer) return
    state.remaining = Math.max(0, state.remaining - (Date.now() - state.startedAt))
    this.clearTimer(state.timer)
    state.timer = null
    state.startedAt = null
  },

  pauseAll() {
    this.el.dataset.paused = "true"
    this.syncTimers()
  },

  resumeAll() {
    if (this.expanded || document.visibilityState === "hidden") return
    delete this.el.dataset.paused
    this.syncTimers()
  },

  // Only the newest timed toast counts down; the ones behind it keep their full
  // time and take over one at a time as the front one leaves.
  syncTimers() {
    const running = !this.expanded && document.visibilityState !== "hidden"
    const front = [...this.toastTimers.keys()]
      .filter((toast) => toast.isConnected && !toast.classList.contains("lui-toast-out"))
      .sort((a, b) => Number(b.dataset.createdAt) - Number(a.dataset.createdAt))[0]
    this.activeToast = running ? front : null
    for (const toast of this.toastTimers.keys()) {
      if (toast === this.activeToast) this.startTimer(toast)
      else this.pauseTimer(toast)
    }
    this.updateDeck()
  },

  syncExpanded() {
    const expanded = this.hovered || this.focusWithin
    this.expanded = expanded
    this.el.dataset.expanded = expanded ? "true" : "false"
    if (expanded) this.pauseAll()
    else this.resumeAll()
  },

  updateDeck() {
    const max = Math.min(Math.max(Number(this.el.dataset.max) || 3, 1), 10)
    const toasts = [...this.el.querySelectorAll(".lui-toast")]
      .sort((a, b) => Number(b.dataset.createdAt) - Number(a.dataset.createdAt))
    toasts.forEach((toast, index) => {
      toast.style.setProperty("--toast-index", index)
      toast.dataset.stackBack = index > 0 ? "true" : "false"
      toast.dataset.stackHidden = !this.expanded && index >= max ? "true" : "false"
      toast.dataset.paused = toast === this.activeToast ? "false" : "true"
    })
  },

  enforceLimit() {
    const toasts = [...this.el.querySelectorAll(".lui-toast")]
    while (toasts.length > 10) {
      const toast = toasts.slice(10).reverse().find((item) => !item.dataset.flashKey)
      if (!toast) break
      this.clearTimer(this.toastTimers.get(toast)?.timer)
      this.toastTimers.delete(toast)
      toast.remove()
      toasts.splice(toasts.indexOf(toast), 1)
    }
  },

  remove(toast) {
    if (!toast || !toast.parentNode) return
    if (toast.classList.contains("lui-toast-out")) return
    this.clearTimer(this.toastTimers.get(toast)?.timer)
    this.toastTimers.delete(toast)
    toast.classList.remove("lui-toast-in")
    toast.classList.add("lui-toast-out")
    this.syncTimers()
    this.setTimer(() => {
      toast.remove()
      this.updateDeck()
    }, 400)
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
    this.el.removeEventListener("pointerenter", this.onPointerEnter)
    this.el.removeEventListener("pointerleave", this.onPointerLeave)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    this.el.removeEventListener("click", this.onClick)
    document.removeEventListener("visibilitychange", this.onVisibilityChange)
    this.timers?.forEach((timer) => clearTimeout(timer))
    this.timers.clear()
    this.toastTimers.clear()
  },
}

// ── Accordion ─────────────────────────────────────────────────────────────
//
// Zag-driven (`@zag-js/accordion`, on-demand chunk). The hook root carries
// `data-zag`; the machine owns expanded state, single/multiple-open
// enforcement, and arrow-key navigation. Item identity is the stable
// server-rendered item id; nested accordions stay isolated. No legacy path:
// every accordion renders `data-zag`.
const LanternAccordion = {
  mounted() {
    import("./zag/accordion.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagAccordion(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

const LanternActionBar = {
  mounted() {
    this._syncPromotion = () => {
      const width = this.el.getBoundingClientRect().width
      // Keep these CSS-pixel cutoffs aligned with the action-bar container queries.
      const promoted = width > 1100 ? 3 : width >= 740 ? 2 : 1
      this.el.setAttribute("data-promoted", String(promoted))
    }

    this._syncNoticeDismissal = () => {
      const notice = this.el.querySelector("[data-action-bar-notice]")
      if (!notice || this.el.dataset.dismissalEvent) return

      const key = notice.dataset.dismissalKey
      const serverDismissed = notice.dataset.serverDismissed === "true"
      if (serverDismissed) {
        notice.hidden = true
        return
      }

      let stored = false
      if (key) {
        try {
          stored = localStorage.getItem(`lantern:notice:${key}`) === "dismissed"
        } catch (_) {
          // Private browsing and storage quotas do not prevent this page from working.
        }
      }

      notice.hidden = stored || this._fallbackDismissedKey === key
    }

    this._onDismissClick = (event) => {
      const dismiss = event.target.closest?.("[data-part='dismiss']")
      const notice = this.el.querySelector("[data-action-bar-notice]")
      if (!dismiss || !notice || !notice.contains(dismiss) || this.el.dataset.dismissalEvent) return

      const key = notice.dataset.dismissalKey
      if (!key) return
      this._fallbackDismissedKey = key
      try {
        localStorage.setItem(`lantern:notice:${key}`, "dismissed")
      } catch (_) {
        // Keep the dismissal for this mounted page even if storage is unavailable.
      }
      notice.hidden = true
    }

    this._syncPromotion()
    if (typeof ResizeObserver !== "undefined") {
      this._promotionObserver = new ResizeObserver(this._syncPromotion)
      this._promotionObserver.observe(this.el)
    } else {
      this.el.ownerDocument.defaultView.addEventListener("resize", this._syncPromotion)
    }

    this.el.addEventListener("click", this._onDismissClick)
    this._syncNoticeDismissal()
  },

  updated() {
    this._syncPromotion?.()
    this._syncNoticeDismissal?.()
  },

  destroyed() {
    this._promotionObserver?.disconnect()
    this.el.ownerDocument.defaultView.removeEventListener("resize", this._syncPromotion)
    this.el.removeEventListener("click", this._onDismissClick)
  },
}

export const Hooks = {
  ChartHover,
  LineHover,
  ChartInteraction,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternCommand,
  LanternSheet,
  LanternDropdown,
  LanternMenu,
  LanternMenubar,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternActionBar,
  LanternSelect,
  LanternSwitch,
  LanternRadio,
  LanternSlider,
  LanternAutocomplete,
  LanternCollapse,
  LanternAccordion,
  LanternTableChrome,
  LanternRowClick,
  LanternMediaTile,
  LanternTheme,
}
export {
  ChartHover,
  LineHover,
  ChartInteraction,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternCommand,
  LanternSheet,
  LanternDropdown,
  LanternMenu,
  LanternMenubar,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternActionBar,
  LanternSelect,
  LanternSwitch,
  LanternRadio,
  LanternSlider,
  LanternAutocomplete,
  LanternCollapse,
  LanternAccordion,
  LanternTableChrome,
  LanternRowClick,
  LanternMediaTile,
  LanternTheme,
}
export default Hooks

const LanternMessageScroller = {
  mounted() {
    this.viewport = this.el.querySelector('[data-part="viewport"]')
    this.content = this.el.querySelector('[data-part="content"]')
    this.button = this.el.querySelector('[data-part="jump-latest"]')
    this.following = this.el.dataset.follow === "true"
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false
    this.atBottom = true
    this.updateState = () => {
      this.atBottom = this.viewport.scrollHeight - this.viewport.scrollTop - this.viewport.clientHeight <= 32
      this.el.dataset.scrollable = this.atBottom ? "false" : "true"
      this.button.dataset.active = String(!this.atBottom)
      this.button.setAttribute("aria-hidden", this.atBottom ? "true" : "false")
      this.button.setAttribute("tabindex", this.atBottom ? "-1" : "0")
    }
    this.scroll = () => {
      this.updateState()
      if (this.atBottom) this.following = true
      else if (this.following) this.following = false
    }
    this.viewport.addEventListener("scroll", this.scroll)
    this._onRootClick = (event) => {
      if (!event.target.closest('[data-part="jump-latest"]')) return
      this.following = true
      this.scrollToBottom()
    }
    this.el.addEventListener("click", this._onRootClick)
    this.observer = new MutationObserver((records) => {
      const anchor = records.flatMap((record) => [...record.addedNodes]).flatMap((node) => {
        if (node.nodeType !== 1) return []
        return [node, ...(node.querySelectorAll?.('[data-scroll-anchor]') || [])]
      }).find((node) => node.hasAttribute?.("data-scroll-anchor"))
      const following = this.following
      if (anchor && following) {
        this.viewport.scrollTop = Math.max(0, (anchor.offsetTop || 0) - Number(this.el.dataset.peek || 40))
        this.updateState()
      } else if (following) this.scrollToBottom()
      else this.updateState()
    })
    this.observer.observe(this.content, { childList: true, subtree: true, characterData: true })
    this.resize = () => { if (this.following) this.scrollToBottom() }
    window.addEventListener("resize", this.resize)
    requestAnimationFrame(() => { if (this.following) this.scrollToBottom(); else this.updateState() })
  },
  scrollToBottom() {
    this.el.dataset.autoscrolling = "true"
    this.viewport.scrollTop = this.viewport.scrollHeight
    this.updateState()
    if (this.reducedMotion) this.el.removeAttribute("data-autoscrolling")
    else requestAnimationFrame(() => this.el.removeAttribute("data-autoscrolling"))
  },
  destroyed() {
    this.viewport?.removeEventListener("scroll", this.scroll)
    this.el.removeEventListener("click", this._onRootClick)
    this.observer?.disconnect()
    window.removeEventListener("resize", this.resize)
  },
}

Hooks.LanternMessageScroller = LanternMessageScroller
export { LanternMessageScroller }

// Right-hand inspector panel (#2861). Port of flicker's TicketPanel: the
// LiveView owns `open`; this hook remembers the viewer's last choice in
// localStorage and restores it on mount. With no stored choice the panel
// opens on a wide viewport (≥1280px) and stays closed below.
const LanternSidePanel = {
  storageKey() {
    return `lui-side-panel:${this.el.dataset.panelKey || this.el.id}`
  },

  readStored() {
    try {
      const stored = window.localStorage.getItem(this.storageKey())
      if (stored === "open") return true
      if (stored === "closed") return false
    } catch (_e) {}
    return null
  },

  writeStored(open) {
    try {
      window.localStorage.setItem(this.storageKey(), open ? "open" : "closed")
    } catch (_e) {}
  },

  isOpen() {
    return this.el.getAttribute("aria-pressed") === "true"
  },

  eventName() {
    return this.el.dataset.event || "set_panel"
  },

  persistEventName() {
    return this.el.dataset.persistEvent || "side_panel"
  },

  mounted() {
    let open = this.readStored()
    if (open === null) open = window.innerWidth >= 1280
    if (open !== this.isOpen()) this.pushEvent(this.eventName(), { open })
    this.handleEvent(this.persistEventName(), ({ open }) => this.writeStored(!!open))
  },

  updated() {
    this.writeStored(this.isOpen())
  },
}

Hooks.LanternSidePanel = LanternSidePanel
export { LanternSidePanel }

// Tabs / segmented control: Left/Right/Up/Down/Home/End move and activate.
// Legacy keyboard path, kept for `role="radiogroup"` lists (Zag's tab
// machine queries `role=tab`) and any other root without `data-zag`.
const LanternTabsLegacy = {
  mounted() {
    this.onKey = (event) => this.onKeydown(event)
    this.el.addEventListener("keydown", this.onKey)
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
  },

  segments() {
    return [...this.el.querySelectorAll('[data-part="segment"], [data-part="tab"]')].filter((el) => {
      if (el.disabled || el.getAttribute("aria-disabled") === "true") return false
      return true
    })
  },

  onKeydown(event) {
    const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End"]
    if (!keys.includes(event.key)) return
    const segs = this.segments()
    if (segs.length === 0) return
    const current = segs.findIndex((el) => el === event.target || el.contains(event.target))
    if (current < 0) return
    event.preventDefault()
    let next = current
    if (event.key === "Home") next = 0
    else if (event.key === "End") next = segs.length - 1
    else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      next = (current - 1 + segs.length) % segs.length
    } else {
      next = (current + 1) % segs.length
    }
    const el = segs[next]
    el.focus()
    el.click()
  },
}

// `LanternTabs` serves two implementations behind one public hook name.
// Roots carrying `data-zag` (hooked tablists) run the Zag tabs machine,
// loaded on demand; patch/navigate/URL stay the source of truth and the
// machine never intercepts activation. Radiogroup lists and anything else
// without `data-zag` stay on the legacy keyboard hook.
//
// The legacy methods are spread into this object (not `.call`ed across) so
// any `this.*` cross-calls resolve.
const LanternTabs = {
  ...LanternTabsLegacy,

  mounted() {
    if (this.el.hasAttribute("data-zag")) {
      import("./zag/tabs.js").then((m) => {
        if (!this.el.isConnected) return
        this._zagDelegate = m.mountZagTabs(this)
      })
    } else {
      LanternTabsLegacy.mounted.call(this)
    }
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else if (this.el.hasAttribute("data-zag")) this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
    else if (!this.el.hasAttribute("data-zag")) LanternTabsLegacy.destroyed.call(this)
  },
}

const LanternSegmented = LanternTabs

// Pager: Zag-driven (`@zag-js/pagination`, on-demand chunk). The `<nav>`
// root carries `data-zag`; the machine owns the page value, arrow-key
// navigation, and aria-current bookkeeping. Links keep their
// server-rendered patch hrefs and the machine never intercepts activation,
// so the URL stays the source of truth (controlled). No legacy path:
// every pager renders `data-zag`.
const LanternPagination = {
  mounted() {
    import("./zag/pagination.js").then((m) => {
      if (!this.el.isConnected) return
      this._zagDelegate = m.mountZagPagination(this)
    })
  },

  beforeUpdate() {
    if (this._zagDelegate) this._zagDelegate.beforeUpdate()
    else this._zagPendingUpdate = true
  },

  updated() {
    if (this._zagDelegate) this._zagDelegate.updated()
    else this._zagPendingUpdate = true
  },

  destroyed() {
    if (this._zagDelegate) this._zagDelegate.destroyed()
  },
}

if (typeof document !== "undefined") installBehaviours(document)
Hooks.LanternTabs = LanternTabs
Hooks.LanternSegmented = LanternSegmented
Hooks.LanternPagination = LanternPagination
export { LanternTabs, LanternSegmented, LanternPagination }
