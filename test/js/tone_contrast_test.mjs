import assert from "node:assert/strict"
import test from "node:test"

const luminance = (hex) => {
  const [r, g, b] = hex.match(/[0-9a-f]{2}/gi).map((channel) => parseInt(channel, 16) / 255)
  const linear = (value) => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
}

const contrast = (foreground, background) => {
  const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a)
  return (values[0] + 0.05) / (values[1] + 0.05)
}

test("warm accent text sample meets WCAG AA on the documented light surfaces", (t) => {
  const sample = "#8a5e20"
  const surfaces = [
    ["canvas", "#ffffff"],
    ["card", "#ffffff"],
    ["muted", "#f4f4f5"],
  ]
  const ratios = surfaces.map(([surface, color]) => ({ surface, ratio: contrast(sample, color) }))

  for (const { surface, ratio } of ratios) {
    assert.ok(ratio >= 4.5, `${sample} contrast on ${surface} is ${ratio.toFixed(2)}:1`)
    t.diagnostic(`${surface}: ${ratio.toFixed(2)}:1`)
  }
})
