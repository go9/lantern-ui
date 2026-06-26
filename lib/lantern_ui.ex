defmodule LanternUI do
  @moduledoc """
  LanternUI — native Phoenix LiveView UI components.

  Server-rendered SVG/HEEx components with minimal JS hooks and no React or JS
  charting libraries. Charts live in `LanternUI.Charts`; pure geometry helpers in
  `LanternUI.Charts.Geometry`.

  Components inherit their colors from host CSS variables (Fluxon-compatible) with
  sensible fallbacks, so they match a host design system automatically and still
  render standalone via the optional theme in `priv/static/lantern_ui.css`. See the
  README for installation, theming, and JS hook setup.
  """
end
