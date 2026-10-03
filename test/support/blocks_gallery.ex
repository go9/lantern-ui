defmodule LanternUI.BlocksGallery do
  @moduledoc """
  Static gallery of the eight step-2 page blocks (flicker #3420): app_shell,
  dashboard, index, detail, settings, form, login, destructive.

  Rendered by `LanternUI.BlocksTest` into `test/fixtures/blocks_gallery/`
  as full HTML documents (CSS inlined) in the default theme and the shadcn
  preset, light + dark — the visual baseline proving every block looks
  finished under both themes.
  """

  use Phoenix.Component

  alias LanternUI.Blocks

  attr(:block, :atom,
    required: true,
    doc: "One of LanternUI.Blocks.names/0; rendered with the shared fixture assigns."
  )

  attr(:theme, :string, default: nil, doc: "nil for default theme, \"shadcn\" for the preset.")
  attr(:dark, :boolean, default: false, doc: "Render the shell with the .dark class.")

  def document(assigns) do
    css =
      [
        "priv/static/lantern_ui.css",
        "priv/static/lantern_ui_theme.css"
      ]
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")

    block_assigns = Map.put(Blocks.fixture_assigns(), :__changed__, nil)
    assigns = assigns |> assign(:css, css) |> assign(:block_assigns, block_assigns)

    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-lantern-theme={@theme} class={@dark && "dark"}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>lantern-ui block: {@block}</title>
        {Phoenix.HTML.raw(
          "<style>body { margin: 0; padding: 2rem; background: var(--lantern-surface); }" <>
            @css <> "</style>"
        )}
      </head>
      <body>
        {apply(Blocks, @block, [@block_assigns])}
      </body>
    </html>
    """
  end
end
