defmodule LanternUI.Components.Theme do
  @moduledoc """
  Runtime theming — persisted `--lantern-*` token overrides.

  Render `<.theme />` once (e.g. in the root layout). The `LanternTheme` hook
  loads persisted overrides from localStorage and injects them as a stylesheet,
  so user-selected themes apply instantly on every page and survive reloads.

      <Theme.theme />

  Change the theme from the client:

      window.dispatchEvent(new CustomEvent("lantern:set-theme", {detail: {
        light: {accent: "oklch(0.637 0.192 38)"},
        dark:  {accent: "oklch(0.72 0.15 250)"},
        radius: "0.75rem",
        density: "comfortable"
      }}))

  or from the server: `LanternUI.set_theme(socket, %{...})` /
  `LanternUI.reset_theme(socket)`. Keys in `light`/`dark` become
  `--lantern-<key>` custom properties scoped to the matching theme (class or
  system); `radius` maps to `--lantern-radius`; `density` sets
  `data-lantern-density` on `<html>`. A `nil`/empty detail resets.
  """
  use Phoenix.Component

  attr(:id, :string, default: "lantern-theme")
  attr(:storage_key, :string, default: "lui-theme")

  def theme(assigns) do
    ~H"""
    <span id={@id} phx-hook="LanternTheme" data-storage-key={@storage_key} hidden></span>
    """
  end
end
