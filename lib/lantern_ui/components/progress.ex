defmodule LanternUI.Components.Progress do
  @moduledoc """
  Progress bar or completion ring. Pure server-render + CSS.

      <.progress value={40} />
      <.progress indeterminate label="Loading" />
      <.progress shape="ring" value={7} max={19} label="Completion">7 / 19</.progress>
      <.progress shape="ring" completed={7} scope={19} />
  """
  use Phoenix.Component

  alias LanternUI.Class

  @radius 14
  @circumference 2 * :math.pi() * @radius

  attr(:shape, :string,
    default: "bar",
    values: ~w(bar ring),
    doc: "`bar` is a track fill; `ring` is the SVG completion circle."
  )

  attr(:value, :integer,
    default: nil,
    doc: "Bar: percent 0–100 (nil is indeterminate). Ring: completed amount."
  )

  attr(:max, :integer,
    default: nil,
    doc: "Ring total. Defaults to 100 when only `value` is set. Ignored on bars."
  )

  attr(:completed, :integer,
    default: nil,
    doc: "Flicker alias of ring `value`; used with `scope`."
  )

  attr(:scope, :integer, default: nil, doc: "Flicker alias of ring `max`.")

  attr(:indeterminate, :boolean,
    default: false,
    doc: "Force indeterminate bar (also true when bar value is nil)."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Bar track height, or ring diameter (sm 28px, md 40px, lg 48px)."
  )

  attr(:color, :string,
    default: "accent",
    values: ~w(primary accent success warning danger info neutral),
    doc: "Semantic fill / stroke color token."
  )

  attr(:shimmer, :boolean,
    default: false,
    doc: "Animated sheen on the determinate bar fill (e.g. active upload)."
  )

  attr(:label, :string,
    default: nil,
    doc: """
    Accessible name. Bars use \"Progress\" when omitted. A ring without a label
    or caption is decorative (`aria-hidden`).
    """
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional caption beside a ring (counts, short copy).")

  def progress(assigns) do
    if assigns.shape == "ring" do
      render_ring(assigns)
    else
      render_bar(assigns)
    end
  end

  defp render_ring(assigns) do
    {raw_value, raw_max} = amounts(assigns)
    maxv = max(raw_max, 0)
    value = clamp_ring(raw_value, maxv)
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
        <circle class="lui-progress-ring-track" cx="18" cy="18" r="14" />
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

  defp render_bar(assigns) do
    indeterminate? = is_nil(assigns.value) or assigns.indeterminate
    assigns = assign(assigns, :indeterminate?, indeterminate?)

    ~H"""
    <div
      class={Class.merge(["lui-progress", @class])}
      role="progressbar"
      aria-label={@label || "Progress"}
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
        style={unless @indeterminate?, do: "width: #{clamp_bar(@value)}%"}
        aria-hidden="true"
      >
      </div>
    </div>
    """
  end

  defp amounts(%{scope: scope} = assigns) when is_integer(scope),
    do: {assigns.completed || 0, scope}

  defp amounts(%{max: max} = assigns) when is_integer(max),
    do: {assigns.value || 0, max}

  defp amounts(%{value: value}) when is_integer(value), do: {value, 100}
  defp amounts(_), do: {0, 0}

  defp clamp_bar(nil), do: 0
  defp clamp_bar(n) when is_integer(n) and n < 0, do: 0
  defp clamp_bar(n) when is_integer(n) and n > 100, do: 100
  defp clamp_bar(n) when is_integer(n), do: n

  defp clamp_ring(n, _maxv) when not is_integer(n), do: 0
  defp clamp_ring(n, _maxv) when n < 0, do: 0
  defp clamp_ring(n, maxv) when n > maxv, do: maxv
  defp clamp_ring(n, _maxv), do: n

  defp pct(_value, 0), do: 0
  defp pct(value, max), do: round(value * 100 / max)
end
