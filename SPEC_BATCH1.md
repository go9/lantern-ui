# Spec: switch, radio, textarea, alert, separator (lantern_ui form/feedback batch 1)

## 1. Objective

Add five server-rendered Phoenix components to the lantern_ui library, mirroring
Fluxon v2's public API (function names + attrs below) so a consumer can swap
`use Fluxon` → `use LanternUI` without template changes. No JavaScript. Match
the repo's existing component style exactly (study the reference files first).

## 2. Files to create/modify

Create:
- lib/lantern_ui/components/switch.ex        (module LanternUI.Components.Switch, fn switch/1)
- lib/lantern_ui/components/radio.ex         (module LanternUI.Components.Radio, fns radio_group/1 — Fluxon calls it radio/1 with a :radio slot; implement radio/1)
- lib/lantern_ui/components/textarea.ex      (module LanternUI.Components.Textarea, fn textarea/1)
- lib/lantern_ui/components/alert.ex         (module LanternUI.Components.Alert, fn alert/1)
- lib/lantern_ui/components/separator.ex     (module LanternUI.Components.Separator, fn separator/1)
- test/lantern_ui/form_feedback_test.exs     (one test module covering all five)

Modify:
- lib/lantern_ui.ex — add to the @components registry map:
    switch: LanternUI.Components.Switch,
    radio: LanternUI.Components.Radio,
    textarea: LanternUI.Components.Textarea,
    alert: LanternUI.Components.Alert,
    separator: LanternUI.Components.Separator
- test/lantern_ui/components_test.exs — the "exposes the new component groups"
  test asserts the exact sorted key list; add :switch, :radio, :textarea,
  :alert, :separator in sorted positions.
- priv/static/lantern_ui.css — append styles (see section 4).

## 3. Interfaces (Fluxon v2 parity)

### switch/1
attrs: id, name, value, field (Phoenix.HTML.FormField, default nil), checked (boolean),
checked_value (default "true"), unchecked_value (default "false"), label, sublabel,
description, size ("sm"|"md"|"lg", default "md"), color (default "accent"),
disabled, class, rest (:global, include: ~w(form phx-change phx-target phx-click)).
Render: label.lui-switch wrapper > hidden input (unchecked_value) + checkbox input
(class "lui-switch-input", sr-only) + span.lui-switch-track > span.lui-switch-thumb,
then label/sublabel/description via LanternUI.Components.Form.label — follow
checkbox.ex's FormField clause pattern exactly (used_input?/errors/translate_error).

### radio/1
attrs: id, name, value (current value), field, label, sublabel, description,
errors (list), variant ("list"|"cards", default "list"), disabled, class, rest.
slot :radio with attrs: value, label, sublabel, description, disabled.
Render: fieldset.lui-radio-group[data-variant] with legend from label; each :radio
slot renders label.lui-radio > input[type=radio] (class lui-radio-input, checked when
to_string(slot value)==to_string(current value)) + span.lui-radio-dot + texts.
FormField clause like checkbox.ex.

### textarea/1
attrs: id, name, value, field, label, sublabel, description, help_text, errors,
rows (default 4), size ("xs".."xl", default "md"), disabled, class,
rest (:global include placeholder phx-* form).
Render like Form.input (study form.ex input/1): div.lui-field > label >
textarea.lui-textarea + error/help. FormField clause.

### alert/1
attrs: id, title, subtitle, color ("neutral"|"info"|"success"|"warning"|"danger",
default "neutral"), hide_icon (boolean), hide_close (boolean, default true —
close button only renders when hide_close == false; clicking it hides the alert
client-side via Phoenix.LiveView.JS.hide(to: "##{id}")), class, rest.
slot :icon (optional custom icon), slot :inner_block.
Render: div.lui-alert[data-color][role="alert"] > icon (default from color:
info→information-circle, success→check-circle, warning→exclamation-circle,
danger→exclamation-circle, neutral→information-circle; via
LanternUI.Components.Icon.icon) > div: strong.lui-alert-title, p.lui-alert-subtitle,
inner_block; optional close button (Icon x-mark).

### separator/1
attrs: text (optional label), vertical (boolean), class, rest.
Render: div.lui-separator[data-vertical] with optional span.lui-separator-text
(hr semantics: role="separator", aria-orientation).

## 4. Constraints & conventions (MANDATORY)

- Study these reference files FIRST and imitate them precisely:
  lib/lantern_ui/components/checkbox.ex (FormField pattern, hidden input),
  lib/lantern_ui/components/form.ex (label/error/translate_error — call
  Form.translate_error/1, it is public), lib/lantern_ui/components/badge.ex
  (data-attr variants), lib/lantern_ui/components/icon.ex (icon names available).
- attr syntax with parens: `attr(:name, :string, default: nil)` — match file style.
- NO grouped aliases (one `alias` per line). No defdelegate. No new deps.
- All colors/sizes via the CSS custom properties already defined
  (--lantern-accent, --lantern-danger, --lantern-fg-muted, --lantern-control-h,
  --lantern-text, --lantern-radius etc.). Append CSS to priv/static/lantern_ui.css
  under a comment banner per component, namespaced lui-*, following the visual
  style of existing blocks (hairline borders, shadcn density, focus-visible ring
  using --lantern-ring-soft). Alert soft backgrounds via
  color-mix(in oklab, var(--lantern-<color>) 10%, transparent).
- Switch track: pill, --lantern-border background unchecked, --lantern-accent
  checked (use :checked ~ sibling selector on .lui-switch-input); thumb white,
  translates on checked; sizes sm/md/lg = 1.1rem/1.35rem/1.6rem track heights.
- Moduledocs: short, with a usage example like other components.
- Icon names that EXIST: information-circle, check-circle... VERIFY in icon.ex;
  check-circle exists; if an icon name is missing, use exclamation-circle or
  check — do NOT invent icon names.

## 5. Verification (run all, must pass)

    mix deps.get
    mix compile --warnings-as-errors
    mix format
    mix test

All tests green (currently 105 + your new ones). Test at minimum: each component
renders; switch FormField clause extracts name/value and renders hidden
unchecked_value input; radio marks the matching option checked; textarea shows
errors over help_text; alert data-color + close button only when hide_close={false};
separator vertical + text variants; registry test updated and passing.
