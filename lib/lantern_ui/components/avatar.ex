defmodule LanternUI.Components.Avatar do
  @moduledoc """
  Compact initials or fallback-content avatar. No Fluxon equivalent.

  The avatar renders `initials` when no inner content is supplied. Use the inner
  block for an image or other host-provided content:

      <.avatar initials="AL" />

      <.avatar size="lg" shape="square">
        <img src={@profile_image_url} alt="" />
      </.avatar>

  `size` accepts `xs`, `sm`, `md`, or `lg`; `shape` accepts `circle` or `square`.
  """

  use Phoenix.Component
  alias LanternUI.Class

  attr(:size, :string, values: ~w(xs sm md lg), default: "md")
  attr(:shape, :string, values: ~w(circle square), default: "circle")
  attr(:initials, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def avatar(assigns) do
    ~H"""
    <span
      class={Class.merge(["lui-avatar", @class])}
      data-part="avatar"
      data-size={@size}
      data-shape={@shape}
      {@rest}
    >
      {if @inner_block != [], do: render_slot(@inner_block), else: @initials}
    </span>
    """
  end
end
