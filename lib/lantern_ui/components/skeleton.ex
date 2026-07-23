defmodule LanternUI.Components.Skeleton do
  @moduledoc """
  Decorative, CSS-only placeholder for content that is still loading.

  The default block is full width and one line high. Use `class` or `style` to
  match the geometry of the content it replaces. The skeleton is hidden from
  assistive technology; put `aria-busy="true"` and an accessible loading label
  on the surrounding content region when an announcement is needed.

      <.skeleton />
      <.skeleton class="avatar-placeholder" />
      <.skeleton style="width: 12rem; height: 6rem;" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:style, :any, default: nil, doc: "Inline CSS for custom placeholder geometry.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def skeleton(assigns) do
    ~H"""
    <span
      class={Class.merge(["lui-skeleton", @class])}
      style={@style}
      aria-hidden="true"
      {@rest}
    ></span>
    """
  end
end
