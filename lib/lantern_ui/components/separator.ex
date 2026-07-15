defmodule LanternUI.Components.Separator do
  @moduledoc """
  Visual divider — horizontal, vertical, or labeled. Mirrors Fluxon's
  `separator/1`.

      <.separator />
      <.separator text="or" />
      <.separator vertical />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:text, :string, default: nil, doc: "Optional centered label on a horizontal rule.")

  attr(:vertical, :boolean,
    default: false,
    doc: "Render a vertical divider instead of horizontal."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def separator(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-separator", @class])}
      data-vertical={@vertical || nil}
      role="separator"
      aria-orientation={if(@vertical, do: "vertical", else: "horizontal")}
      {@rest}
    >
      <span :if={@text && !@vertical} class="lui-separator-text">{@text}</span>
    </div>
    """
  end
end
