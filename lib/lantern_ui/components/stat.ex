defmodule LanternUI.Components.Stat do
  @moduledoc """
  Compact summary metrics extracted from the data table overview.

  Use `stat_card/1` for a single metric or compose one or more cards with the
  slot-driven `stat_grid/1`. Callers own calculations and formatting; these
  components only present concise labels, values, and optional context.

      <.stat_card label="Open orders" value={42} icon="hero-inbox" />

      <.stat_grid>
        <:stat label="Open" value={42} />
        <:stat label="Shipped" value={128} href="/orders?status=shipped" />
      </.stat_grid>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:label, :string, required: true, doc: "Short caption identifying the metric.")
  attr(:value, :any, required: true, doc: "Primary metric value to display.")
  attr(:icon, :string, default: nil, doc: "Optional host heroicon class shown by the label.")
  attr(:subtitle, :string, default: nil, doc: "Optional muted context below the value.")
  attr(:href, :string, default: nil, doc: "Optional LiveView navigation target.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the card.")

  @doc "Renders one compact summary metric."
  def stat_card(assigns) do
    assigns =
      assign(
        assigns,
        :card_class,
        Class.merge(["lui-dt-stat", !assigns.href && "lui-dt-stat-static", assigns.class])
      )

    ~H"""
    <.link :if={@href} navigate={@href} class={@card_class}>
      <.stat_card_content label={@label} value={@value} icon={@icon} subtitle={@subtitle} />
    </.link>
    <div :if={!@href} class={@card_class}>
      <.stat_card_content label={@label} value={@value} icon={@icon} subtitle={@subtitle} />
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:icon, :string, default: nil)
  attr(:subtitle, :string, default: nil)

  defp stat_card_content(assigns) do
    ~H"""
    <div class="lui-dt-stat-head">
      <span class="lui-dt-stat-label">{@label}</span>
      <span
        :if={@icon}
        class={Class.merge(["lui-dt-stat-icon", @icon])}
        aria-hidden="true"
      ></span>
    </div>
    <span class="lui-dt-stat-value">{@value}</span>
    <span :if={@subtitle} class="lui-dt-stat-sub">{@subtitle}</span>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the grid.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through to the grid.")

  slot :stat,
    doc: "A summary metric card; provide its value with the :value attribute or inner content." do
    attr(:label, :string, required: true, doc: "Short caption identifying the metric.")

    attr(:value, :any,
      doc: "Primary metric value; inner slot content takes precedence when present."
    )

    attr(:icon, :string, doc: "Optional host heroicon class shown by the label.")
    attr(:subtitle, :string, doc: "Optional muted context below the value.")
    attr(:href, :string, doc: "Optional LiveView navigation target.")
    attr(:class, :any, doc: "Extra classes merged onto this card.")
  end

  @doc "Renders a responsive collection of summary metrics; emits nothing when empty."
  def stat_grid(assigns) do
    ~H"""
    <div :if={@stat != []} class={Class.merge(["lui-dt-stats", "lui-stat-grid", @class])} {@rest}>
      <.stat_card
        :for={stat <- @stat}
        label={stat[:label]}
        value={if stat[:inner_block], do: render_slot(stat), else: stat[:value]}
        icon={stat[:icon]}
        subtitle={stat[:subtitle]}
        href={stat[:href]}
        class={stat[:class]}
      />
    </div>
    """
  end
end
