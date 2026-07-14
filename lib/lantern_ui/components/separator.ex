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

  attr(:text, :string, default: nil)
  attr(:vertical, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

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
