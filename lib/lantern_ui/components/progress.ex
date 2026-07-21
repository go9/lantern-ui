defmodule LanternUI.Components.Progress do
  @moduledoc """
  Progress bar / meter — determinate or indeterminate. Pure server-render + CSS.

      <.progress value={40} />
      <.progress indeterminate label="Loading" />
      <.progress value={72} color="success" shimmer label="Uploading" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:value, :integer,
    default: nil,
    doc: "Percent complete 0–100; nil is indeterminate."
  )

  attr(:indeterminate, :boolean,
    default: false,
    doc: "Force indeterminate state (also true when value is nil)."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Track height (sm ~0.375rem … lg ~0.75rem)."
  )

  attr(:color, :string,
    default: "accent",
    values: ~w(primary accent success warning danger info neutral),
    doc: "Semantic fill color token."
  )

  attr(:shimmer, :boolean,
    default: false,
    doc: "Animated sheen on the determinate fill (e.g. active upload)."
  )

  attr(:label, :string,
    default: "Progress",
    doc: "Accessible name for aria-label."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def progress(assigns) do
    indeterminate? = is_nil(assigns.value) or assigns.indeterminate
    assigns = assign(assigns, :indeterminate?, indeterminate?)

    ~H"""
    <div
      class={Class.merge(["lui-progress", @class])}
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax="100"
      aria-valuenow={unless @indeterminate?, do: @value}
      data-size={@size}
      data-color={@color}
      data-state={if @indeterminate?, do: "indeterminate", else: "determinate"}
      data-shimmer={if @shimmer && not @indeterminate?, do: "true"}
      {@rest}
    >
      <div
        class="lui-progress-fill"
        style={unless @indeterminate?, do: "width: #{clamp(@value)}%"}
        aria-hidden="true"
      >
      </div>
    </div>
    """
  end

  defp clamp(nil), do: 0
  defp clamp(n) when is_integer(n) and n < 0, do: 0
  defp clamp(n) when is_integer(n) and n > 100, do: 100
  defp clamp(n) when is_integer(n), do: n
end
