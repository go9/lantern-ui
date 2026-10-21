// WCAG AA contract for the default theme's shipped fallbacks: text-bearing
// tokens must reach 4.5:1 on every surface they sit on. Hosts that supply
// their own `--primary`, `--warning`, `--foreground-softest`, … override
// these fallbacks and own their contrast (see CHANGELOG).
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import test from "node:test"

const css = readFileSync(new URL("../../priv/static/lantern_ui_theme.css", import.meta.url), "utf8")

const srgb = (value) => {
  if (value.startsWith("#")) return value.match(/[0-9a-f]{2}/gi).map((c) => parseInt(c, 16) / 255)
  const [L, C, H] = value.match(/oklch\(([\d.]+) ([\d.]+) ([\d.]+)\)/).slice(1).map(Number)
  const a = C * Math.cos((H * Math.PI) / 180)
  const b = C * Math.sin((H * Math.PI) / 180)
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3
  return [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  ].map((v) => {
    v = Math.min(1, Math.max(0, v))
    return v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055
  })
}

const luminance = (value) => {
  const [r, g, b] = srgb(value).map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4))
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi + 0.05) / (lo + 0.05)
}

// Body of the first rule whose selector line starts with `selector {`.
const block = (selector) => {
  const start = css.indexOf(`${selector} {`)
  assert.notEqual(start, -1, `theme CSS must declare ${selector}`)
  return css.slice(css.indexOf("{", start) + 1, css.indexOf("\n}", start))
}

// Last literal colour in `--token: var(--host, … literal)` or `--token: literal`.
const literal = (body, token) => {
  const line = body.match(new RegExp(`${token}:\\s*([^;]+);`))
  assert.ok(line, `${token} must be declared`)
  const found = line[1].match(/#[0-9a-f]{6}|oklch\([\d.]+ [\d.]+ [\d.]+\)/gi)
  assert.ok(found, `${token} must keep a literal fallback`)
  return found.at(-1)
}

const TEXT = ["fg", "fg-muted", "fg-subtle", "accent", "danger", "success", "warning", "info"]
const SURFACES = ["surface", "surface-raised", "surface-sunken"]

const themes = {
  light: block(":root"),
  ".light": block(".light"),
  dark: block(".dark"),
  "system dark": block(":root:not(.light)").replace(/^/, ""),
}

for (const [name, body] of Object.entries(themes)) {
  test(`${name}: text tokens reach 4.5:1 on every surface`, () => {
    for (const token of TEXT) {
      for (const surface of SURFACES) {
        const ratio = contrast(literal(body, `--lantern-${token}`), literal(body, `--lantern-${surface}`))
        assert.ok(ratio >= 4.5, `${name} --lantern-${token} on --lantern-${surface} is ${ratio.toFixed(2)}:1`)
      }
    }
  })

  test(`${name}: accent-fg on accent reaches 4.5:1`, () => {
    const ratio = contrast(literal(body, "--lantern-accent-fg"), literal(body, "--lantern-accent"))
    assert.ok(ratio >= 4.5, `${name} accent-fg on accent is ${ratio.toFixed(2)}:1`)
  })
}

test("shadcn preset: subtle text reaches 4.5:1 on its surfaces", () => {
  const light = block('[data-lantern-theme="shadcn"]')
  const subtle = literal(light, "--lantern-fg-subtle")
  for (const token of ["--background", "--muted"]) {
    const ratio = contrast(subtle, literal(light, token))
    assert.ok(ratio >= 4.5, `light preset subtle on ${token} is ${ratio.toFixed(2)}:1`)
  }
  const dark = block('.dark[data-lantern-theme="shadcn"],\n[data-lantern-theme="shadcn"].dark,\n.dark [data-lantern-theme="shadcn"],\n[data-lantern-theme="shadcn"] .dark')
  const darkSubtle = literal(dark, "--lantern-fg-subtle")
  for (const token of ["--background", "--muted"]) {
    const ratio = contrast(darkSubtle, literal(dark, token))
    assert.ok(ratio >= 4.5, `dark preset subtle on ${token} is ${ratio.toFixed(2)}:1`)
  }
})
