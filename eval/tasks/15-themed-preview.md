# Task 15 — Themed preview (shadcn preset + light/dark correctness)

Add a theming preview page to the demo app proving the shadcn preset renders
correctly in both modes. No DB.

- Route: `live("/eval/themed", EvalThemedLive, :index)`
- Module: `LanternDemoWeb.EvalThemedLive`

Requirements:

1. Render the lantern `theme` component with `preset="shadcn"` on the page
   (this sets `data-lantern-theme="shadcn"` on `<html>` via its hook — do
   NOT hand-roll the attribute when the component covers it).
2. A **light/dark mode switch** (segmented control or buttons: Light / Dark)
   that flips the page between modes through the supported mechanism
   (theme override / `data-theme` / class on `<html>`), persisted for the
   session. The switch visibly works: backgrounds, cards, and text invert.
3. **Side-by-side preview panels**: two bordered panels on one screen, one
   forced light and one forced dark (set the theme attribute by hand on each
   panel subtree — the supported per-subtree mechanism), each rendering the
   same sample: two `stat_card`s, a 3-row mini table (`table` /
   `data_table`), a primary + a secondary `button`, and one labeled `input`.
4. Both panels must look finished: readable contrast, no unstyled raw
   elements, no hardcoded palette colors, no arbitrary pixel values.
5. Heading ("Themed preview") + description line in the breadcrumb bar.

Deliverables: the LiveView module file(s) + the route registration.
