defmodule LanternUI.Components.Button do
  @moduledoc """
  Buttons — Fluxon-compatible API, shadcn-caliber styling.

      <.button>Save</.button>
      <.button variant="solid">Deploy</.button>
      <.button variant="solid" color="danger">Delete</.button>
      <.button size="icon"><.icon name="plus" /></.button>

  The API mirrors Fluxon's `button/1` (`color` × `variant` × `size`), so a
  consumer migrates by swapping imports. Styling is LanternUI's own: token-driven
  (`--lantern-*`), 32px `md` control height, hairline borders, coral focus ring.

  Colors set a per-button `--lui-c` custom property; variants derive their
  background/border/text from it, so every color works with every variant
  without a compiled class matrix.
  """

  use Phoenix.Component

  alias LanternUI.Class

  @colors ~w(primary danger warning success info)
  @variants ~w(solid soft surface outline dashed ghost)
  @sizes ~w(xs sm md lg xl icon-xs icon-sm icon-md icon icon-lg icon-xl)

  attr(:color, :string,
    default: "primary",
    values: @colors,
    doc: "Semantic color token for the button surface."
  )

  attr(:variant, :string,
    default: "outline",
    values: @variants,
    doc: "Surface style: solid fills, outline borders, ghost is transparent."
  )

  attr(:size, :string,
    default: "md",
    values: @sizes,
    doc: "Control height; icon-* sizes are square."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(type form name value),
    default: %{"data-part" => "button"},
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  slot(:inner_block, required: true, doc: "Button label or content.")

  def button(assigns) do
    assigns =
      assign(
        assigns,
        :computed_class,
        Class.merge(["lui-btn", assigns.class])
      )

    ~H"""
    <button
      class={@computed_class}
      data-variant={@variant}
      data-color={@color}
      data-size={@size}
      disabled={@disabled}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Groups buttons into a single segmented control (shared borders, joined radius).
  """
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Buttons to join into a segmented group.")

  def button_group(assigns) do
    ~H"""
    <div class={Class.merge(["lui-btn-group", @class])} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
