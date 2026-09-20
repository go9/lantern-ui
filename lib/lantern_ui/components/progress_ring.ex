defmodule LanternUI.Components.ProgressRing do
  @moduledoc """
  SVG completion ring with a visible muted track and a thicker progress stroke.

  The flicker original used the same stroke width for track and value, and a
  track colour that disappeared on the page background — 7/19 read as an empty
  circle. Here the track is `--lantern-border-strong` and the value stroke is
  thicker, so partial progress is obvious.

      <.progress_ring value={7} max={19} />
      <.progress_ring completed={7} scope={19}>
        7 / 19
      </.progress_ring>

  `value`/`max` is the generic API. `completed`/`scope` is the flicker-shaped
  alias so a consuming page does not have to remap.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @radius 14
  @circumference 2 * :math.pi() * @radius

  attr(:value, :integer, default: nil, doc: "Completed amount. Ignored when `scope` is set.")

  attr(:max, :integer,
    default: nil,
    doc: "Total amount. Defaults to 100 when only `value` is set."
  )

  attr(:completed, :integer,
    default: nil,
    doc: "Flicker alias of `value`; used with `scope`."
  )

  attr(:scope, :integer, default: nil, doc: "Flicker alias of `max`.")

  attr(:size, :string, default: "md", values: ~w(sm md), doc: "sm is 28px; md is 40px.")

  attr(:color, :string,
    default: "success",
    values: ~w(success accent primary danger warning info),
    doc: "Semantic colour of the progress stroke."
  )

  attr(:label, :string,
    default: nil,
    doc: "Accessible name. Decorative (aria-hidden) when omitted and no inner slot."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional caption beside the ring (counts, short copy).")

  def progress_ring(assigns) do
    {raw_value, raw_max} = amounts(assigns)
    maxv = max(raw_max, 0)
    value = clamp(raw_value, maxv)
    frac = if maxv == 0, do: 0.0, else: value / maxv
    dash = frac * @circumference
    named? = not is_nil(assigns.label) or assigns.inner_block != []

    assigns =
      assigns
      |> assign(:value_now, value)
      |> assign(:max_now, maxv)
      |> assign(:dash, dash)
      |> assign(:circumference, @circumference)
      |> assign(:named?, named?)

    ~H"""
    <span
      class={Class.merge(["lui-progress-ring", @class])}
      data-size={@size}
      data-color={@color}
      data-progress-pct={pct(@value_now, @max_now)}
      role={@named? && "progressbar"}
      aria-label={@label}
      aria-valuemin={@named? && 0}
      aria-valuemax={@named? && @max_now}
      aria-valuenow={@named? && @value_now}
      aria-hidden={!@named? && "true"}
      {@rest}
    >
      <svg
        class="lui-progress-ring-svg"
        viewBox="0 0 36 36"
        fill="none"
        aria-hidden="true"
      >
        <circle
          class="lui-progress-ring-track"
          cx="18"
          cy="18"
          r="14"
        />
        <circle
          class="lui-progress-ring-value"
          cx="18"
          cy="18"
          r="14"
          stroke-dasharray={"#{@dash} #{@circumference}"}
        />
      </svg>
      <span :if={@inner_block != []} class="lui-progress-ring-label">
        {render_slot(@inner_block)}
      </span>
    </span>
    """
  end

  defp amounts(%{scope: scope} = assigns) when is_integer(scope),
    do: {assigns.completed || 0, scope}

  defp amounts(%{max: max} = assigns) when is_integer(max),
    do: {assigns.value || 0, max}

  defp amounts(%{value: value}) when is_integer(value), do: {value, 100}
  defp amounts(_), do: {0, 0}

  defp clamp(n, _maxv) when not is_integer(n), do: 0
  defp clamp(n, _maxv) when n < 0, do: 0
  defp clamp(n, maxv) when n > maxv, do: maxv
  defp clamp(n, _maxv), do: n

  defp pct(_value, 0), do: 0
  defp pct(value, max), do: round(value * 100 / max)
end
