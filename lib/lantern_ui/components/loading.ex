defmodule LanternUI.Components.Loading do
  @moduledoc """
  Inline loading indicator — ring spinner or staggered dots. Mirrors Fluxon's
  `loading/1` (server-render + CSS only, no JS).

      <.loading />
      <.loading variant="dots-bounce" size="sm" label="Saving" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:variant, :string,
    default: "ring",
    values: ~w(ring dots-bounce dots-fade dots-scale),
    doc: "Spinner style: rotating ring or three-dot bounce/fade/scale."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Scales ring diameter / dot size (xs ~0.75rem … xl ~2rem)."
  )

  attr(:label, :string,
    default: "Loading",
    doc: "Accessible label for aria-label and screen-reader text."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def loading(assigns) do
    ~H"""
    <span
      class={Class.merge(["lui-loading", @class])}
      data-variant={@variant}
      data-size={@size}
      role="status"
      aria-label={@label}
      {@rest}
    >
      <span class="lui-sr-only">{@label}</span>
      <span :if={@variant == "ring"} class="lui-loading-ring" aria-hidden="true"></span>
      <span :if={@variant != "ring"} class="lui-loading-dots" aria-hidden="true">
        <span class="lui-loading-dot"></span>
        <span class="lui-loading-dot"></span>
        <span class="lui-loading-dot"></span>
      </span>
    </span>
    """
  end
end
