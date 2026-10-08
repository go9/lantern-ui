import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const themeCss = readFileSync(new URL("../../priv/static/lantern_ui_theme.css", import.meta.url), "utf8")

const luminance = (hex) => {
  const [r, g, b] = hex.match(/[0-9a-f]{2}/gi).map((channel) => parseInt(channel, 16) / 255)
  const linear = (value) => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
}

const contrast = (foreground, background) => {
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a)
  return (values[0] + 0.05) / (values[1] + 0.05)
}

const tokenBlock = (selector) => {
  const start = themeCss.indexOf(`${selector} {`)
  assert.notEqual(start, -1, `theme CSS must declare ${selector}`)
  const open = themeCss.indexOf("{", start)
  const close = themeCss.indexOf("}", open)
  return themeCss.slice(open + 1, close)
}

const fallback = (block, token) => {
  const declaration = block.match(new RegExp(`${token}:\\s*var\\([^,]+,\\s*(#[0-9a-f]{6})\\s*\\)`))
  assert.ok(declaration, `${token} must keep a shipped hex fallback`)
  return declaration[1]
}

test("default neutral text fallback meets WCAG AA on shipped light and dark surfaces", (t) => {
  const themes = [
    { name: "light", block: tokenBlock(":root") },
    { name: "dark", block: tokenBlock(".dark") },
  ]
  const surfaces = [
    ["canvas", "--lantern-surface"],
    ["card", "--lantern-surface-raised"],
    ["muted", "--lantern-surface-sunken"],
  ]

  for (const { name, block } of themes) {
    const text = fallback(block, "--lantern-fg")
    for (const [surface, token] of surfaces) {
      const background = fallback(block, token)
      const ratio = contrast(text, background)
      assert.ok(ratio >= 4.5, `${name} --lantern-fg on ${token} is ${ratio.toFixed(2)}:1`)
      t.diagnostic(`${name} ${surface}: ${ratio.toFixed(2)}:1`)
    }
  }
})
