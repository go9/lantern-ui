# topology_svg QA

The `/topology_svg` page in `test/qa/server.exs` shows a degraded node, an absent (dashed) node and labelled edges. Run the QA host, then `node test/qa/topology_svg.mjs` (override `BASE`, `CHROME_PATH`, `QA_SHOTS`). It checks region focus, node Tab order, Enter selection and `aria-pressed` at 960 and 390 px, light and dark, reduced motion.
