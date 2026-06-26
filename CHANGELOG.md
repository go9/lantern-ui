# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com), and the project adheres to
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Added
- Initial chart set as native Phoenix LiveView function components under
  `LanternUI.Charts`: `area_chart/1`, `sparkline/1`, `bar_chart/1`.
- `LanternUI.Charts.Geometry` — pure scaling, "nice" tick, and SVG path helpers.
- `ChartHover` LiveView JS hook (`priv/static/lantern_ui_hooks.js`) for the
  crosshair + tooltip on `area_chart`.
- Optional standalone theme (`priv/static/lantern_ui.css`); components otherwise
  inherit host CSS variables (Fluxon-compatible).

[Unreleased]: https://github.com/go9/lantern-ui
