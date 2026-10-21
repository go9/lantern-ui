# Stage strip evidence

The `/stage_strip` page in `test/qa/server.exs` shows a Suggestions report row
and the six state treatments. Screenshots cover light/dark at 960 CSS pixels
and light at 390 CSS pixels, all with reduced motion requested.

Run the QA host, then `node test/qa/stage_strip.mjs` (override `BASE` and
`CHROME_PATH` if needed). The script checks pip order/count, visible borders,
static motion styles, keyboard access to the report link, and no page overflow.

- [Light](light-960.png)
- [Dark](dark-960.png)
- [Mobile](light-390.png)

Design source: `prototypes/shadcn-f/NOTES.md`, “Suggestions v3” and
“Suggestions reconcile”, and `app/src/pages/suggestions/Split.tsx` on
`design/suggestions-reconcile` in `orlando-umbrella/flicker-design-prototypes`.
The supplied Apps/Databases, Ask/Sources, Buckets/Sources and migration specs
contain no `stage_strip` mention. The coordinator confirmed Projects is not
needed for this component. Verified consumer: the Suggestions list summary;
the trace uses timeline detail. No second consumer was invented.

Subtraction pass: one function, no slots, no color/size variants, no click or
selection model, no animation, no hardcoded stage count or app state derivation.
Existing timeline, waterfall and progress cover detail, duration and amounts.
