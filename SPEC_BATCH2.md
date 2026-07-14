# Spec: tooltip + toast (lantern_ui feedback batch 2 — JS-hook components)

## 1. Objective

Two interactive components for the lantern_ui Phoenix library. `tooltip`
mirrors Fluxon v2's API. `toast` is a lantern extension (Fluxon v2 has none):
a flash/notification stack driven by LiveView push_events. Both use the
existing JS runtime helpers in priv/static/lantern_ui_hooks.js (`position` is
already defined at the top of that file — reuse it, do not reimplement).

## 2. Files to create/modify

Create:
- lib/lantern_ui/components/tooltip.ex   (LanternUI.Components.Tooltip, fn tooltip/1)
- lib/lantern_ui/components/toast.ex     (LanternUI.Components.Toast, fn toast_group/1)
- test/lantern_ui/feedback_js_test.exs   (render tests for both)

Modify:
- priv/static/lantern_ui_hooks.js — add hooks `LanternTooltip` and `LanternToast`
  following the existing hook style (const X = { mounted() ... }); add BOTH to the
  `export const Hooks = {...}` object AND the named `export {...}` list.
- lib/lantern_ui.ex — registry: tooltip: LanternUI.Components.Tooltip,
  toast: LanternUI.Components.Toast; ALSO add public helper:
      def send_toast(%Phoenix.LiveView.Socket{} = socket, kind, message, opts \\ []) do
        Phoenix.LiveView.push_event(socket, "lantern:toast", %{
          kind: to_string(kind), message: message,
          title: opts[:title], duration: opts[:duration] || 4000
        })
      end
- test/lantern_ui/components_test.exs — registry key list gains :tooltip, :toast (sorted).
- priv/static/lantern_ui.css — styles appended, lui-* namespaced, token-based.

## 3. Interfaces

### tooltip/1 (Fluxon v2 parity)
attrs: id (required), value (string, simple text content), placement
("top"|"bottom"|"left"|"right", default "top"), delay (integer ms, default 200),
arrow (boolean, default true), class, rest (:global).
slots: inner_block (required — the trigger content), :content (optional rich
content; wins over value).
Render:
    <span id={@id} class={merge "lui-tooltip-wrap"} phx-hook="LanternTooltip"
          data-placement={@placement} data-delay={@delay}>
      <span data-part="trigger" class="lui-tooltip-trigger" tabindex="0">{inner_block}</span>
      <span data-part="panel" class="lui-tooltip" role="tooltip" hidden>
        {content slot or @value}<span :if={@arrow} class="lui-tooltip-arrow" data-part="arrow"></span>
      </span>
    </span>
LanternTooltip hook: show after `delay` ms on mouseenter/focusin of trigger;
hide immediately on mouseleave/focusout/Escape. Position with the existing
`position(trigger, panel, { placement: mapped })` helper — map top→"top-start"?
NO: position() only supports top/bottom sides with start/end align; for
placement "top" use {placement: "top-start"} then center manually:
after positioning, set panel.style.left so the panel is horizontally centered
on the trigger (clamp 8px to viewport). For left/right placements, position
manually via getBoundingClientRect (fixed positioning, gap 6px, vertical
center, flip if offscreen). Keep it small and readable. Panel must have
position:fixed (CSS) and hidden attr guard (see constraint below).

### toast_group/1 (lantern extension)
attrs: id (default "lantern-toasts"), placement ("top-right"|"bottom-right"|
"top-center", default "top-right"), class, rest.
Render: <div id={@id} class={merge "lui-toasts"} phx-hook="LanternToast"
data-placement={@placement} aria-live="polite"></div>
LanternToast hook:
  mounted: this.handleEvent("lantern:toast", (t) => this.add(t))
  add({kind, message, title, duration}): build DOM node
    div.lui-toast[data-kind] > (icon span per kind using inline SVG cloned from
    an existing rendered icon is NOT available — instead render a colored dot
    span.lui-toast-dot) + div(strong title if present, p message) + close button
    (data-part="close", text "×"), appended to the group; entrance CSS class
    .lui-toast-in; auto-remove after duration ms (default 4000; duration 0 =
    sticky); close button removes immediately; removal adds .lui-toast-out then
    removes node after 150ms.
  destroyed: clear timers.

## 4. Constraints & conventions (MANDATORY)

- Imitate existing files: hook style + exports in lantern_ui_hooks.js
  (see LanternSelect/LanternCollapse), component style in
  lib/lantern_ui/components/*.ex, attr(...) with parens, one alias per line.
- Icons: only names existing in lib/lantern_ui/components/icon.ex.
- CSS: append with banner comments; use tokens (--lantern-surface-raised,
  --lantern-border, --lantern-shadow-md, --lantern-radius-lg, --lantern-text-sm,
  --lantern-duration, kind colors via --lantern-accent/success/warning/danger).
- CRITICAL KNOWN BUG CLASS: any element whose class sets `display:` and which
  is toggled via the `hidden` attribute MUST have an explicit
  `.<class>[hidden] { display: none; }` guard (CSS display beats the hidden
  attribute). The tooltip panel and toasts need this if their classes set display.
- Toast colors: left border 3px in the kind color; dot in kind color;
  neutral surface background. z-index 80 for toasts, 70 for tooltip.
- `mix format` everything; JS must pass `node --check`.

## 5. Verification (run all; all must pass)

    mix compile --warnings-as-errors
    mix format --check-formatted
    mix test
    node --check priv/static/lantern_ui_hooks.js

Tests must cover: tooltip renders trigger/panel/role/data attrs, content slot
wins over value, arrow toggles; toast_group renders hook + aria-live +
placement; registry test updated. (Hook behavior is browser-side — render
coverage only.)
