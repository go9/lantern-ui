defmodule LanternUI.Components.Badge do
  @moduledoc """
  Status badge / pill. Mirrors Fluxon's `badge/1` surface.

      <.badge>Default</.badge>
      <.badge color="success" variant="soft">Shipped</.badge>
      <.badge color="danger" size="sm">Failed</.badge>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary accent info success warning danger),
    doc: "Semantic color token for the badge surface."
  )

  attr(:variant, :string,
    default: "soft",
    values: ~w(soft solid outline),
    doc: "Surface style: soft tint, solid fill, or outline border."
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg), doc: "Badge padding and type scale.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Badge label content.")

  def badge(assigns) do
    ~H"""
    <span
      class={Class.merge(["lui-badge", @class])}
      data-color={@color}
      data-variant={@variant}
      data-size={@size}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
