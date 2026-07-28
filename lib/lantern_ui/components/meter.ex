defmodule LanternUI.Components.Meter do
  @moduledoc """
  Meter — a scalar measurement within a known range (`role="meter"`, WAI-ARIA
  APG Meter pattern). Distinct from `progress`, which conveys task completion.
  Pure server-render + CSS; no Fluxon equivalent.

      <.meter value={68} label="Battery" />
      <.meter value={7.2} min={0} max={14} label="pH" value_text="7.2 pH" />
      <.meter value={92} low={20} high={80} optimum={50} label="CPU load" />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:value, :any, required: true, doc: "Current measurement (number).")
  attr(:min, :any, default: 0, doc: "Lower bound of the range.")
  attr(:max, :any, default: 100, doc: "Upper bound of the range.")

  attr(:low, :any,
    default: nil,
    doc: "Upper bound of the low region; enables optimum-based state coloring."
  )

  attr(:high, :any,
    default: nil,
    doc: "Lower bound of the high region; enables optimum-based state coloring."
  )

  attr(:optimum, :any,
    default: nil,
    doc:
      "Optimal value; region distance drives data-state (optimal/suboptimal/critical). " <>
        "Defaults to the range midpoint, (min + max) / 2, per HTML <meter>."
  )

  attr(:value_text, :string,
    default: nil,
    doc: "Human-readable value for aria-valuetext (e.g. \"7.2 pH\")."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Track height (sm ~0.375rem … lg ~0.75rem)."
  )

  attr(:label, :string,
    default: "Meter",
    doc: "Accessible name for aria-label."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def meter(assigns) do
    assigns =
      assigns
      |> assign(:percent, percent(assigns.value, assigns.min, assigns.max))
      |> assign(:state, state(assigns))

    ~H"""
    <div
      class={Class.merge(["lui-meter", @class])}
      role="meter"
      aria-label={@label}
      aria-valuemin={@min}
      aria-valuemax={@max}
      aria-valuenow={@value}
      aria-valuetext={@value_text}
      data-size={@size}
      data-state={@state}
      {@rest}
    >
      <div class="lui-meter-fill" style={"width: #{@percent}%"} aria-hidden="true"></div>
    </div>
    """
  end

  defp percent(value, min, max) when is_number(value) and is_number(min) and is_number(max) do
    span = max - min

    cond do
      span <= 0 ->
        0

      true ->
        ((value - min) / span * 100) |> Kernel.max(0.0) |> Kernel.min(100.0) |> Float.round(2)
    end
  end

  defp percent(_, _, _), do: 0

  # HTML <meter>-style regions: below `low`, between, above `high`. The state is
  # the region distance between the value and the optimum: same region →
  # optimal, adjacent → suboptimal, opposite ends → critical.
  defp state(%{low: low, high: high} = assigns) when is_number(low) or is_number(high) do
    optimum = assigns.optimum || (assigns.min + assigns.max) / 2
    distance = abs(region(assigns.value, low, high) - region(optimum, low, high))

    case distance do
      0 -> "optimal"
      1 -> "suboptimal"
      _ -> "critical"
    end
  end

  defp state(_assigns), do: nil

  defp region(v, low, _high) when is_number(low) and v < low, do: 1
  defp region(v, _low, high) when is_number(high) and v > high, do: 3
  defp region(_v, _low, _high), do: 2
end
