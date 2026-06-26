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

export const Hooks = { ChartHover }
export { ChartHover }
export default Hooks
