defmodule LanternUI.Components.Stat do
  @moduledoc """
  Compact summary metrics extracted from the data table overview.

  Use `stat_card/1` for a single metric or compose one or more cards with the
  slot-driven `stat_grid/1`. Callers own calculations and formatting; these
  components only present concise labels, values, and optional context.

      <.stat_card label="Open orders" value={42} icon="hero-inbox" />

      <.stat_card label="Revenue" value="$42,500" tone="success">
        <:sparkline>
          <.sparkline id="rev-spark" series={[12, 18, 15, 24, 32]} />
        </:sparkline>
      </.stat_card>

      <.stat_grid>
        <:stat label="Open" value={42} tone="neutral" />
        <:stat label="Shipped" value={128} href="/orders?status=shipped" tone="info" />
      </.stat_grid>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, default: nil, doc: "Stable DOM id for the card.")
  attr(:label, :string, required: true, doc: "Short caption identifying the metric.")
  attr(:value, :any, required: true, doc: "Primary metric value to display.")
  attr(:icon, :string, default: nil, doc: "Optional host heroicon class shown by the label.")
  attr(:subtitle, :string, default: nil, doc: "Optional muted context below the value.")

  attr(:tone, :string,
    default: nil,
    values: ~w(neutral info success warning danger promo) ++ [nil],
    doc: "Optional semantic tone for subtle card tinting and sparkline accent."
  )

  attr(:sparkline_series, :list,
    default: nil,
    doc: "Optional numeric list rendered as a trend sparkline when no :sparkline slot is passed."
  )

  attr(:href, :string, default: nil, doc: "Optional LiveView navigation target.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the card.")

  slot(:sparkline, doc: "Optional trend sparkline slot rendered with the metric.")

  @doc "Renders one compact summary metric."
  def stat_card(assigns) do
    tone = if assigns[:tone], do: to_string(assigns[:tone]), else: nil

    assigns =
      assigns
      |> assign(:tone, tone)
      |> assign(
        :card_class,
        Class.merge(["lui-dt-stat", !assigns.href && "lui-dt-stat-static", assigns.class])
      )

    ~H"""
    <.link :if={@href} id={@id} navigate={@href} class={@card_class} data-tone={@tone}>
      <.stat_card_content
        id={@id}
        label={@label}
        value={@value}
        icon={@icon}
        subtitle={@subtitle}
        tone={@tone}
        sparkline={@sparkline}
        sparkline_series={@sparkline_series}
      />
    </.link>
    <div :if={!@href} id={@id} class={@card_class} data-tone={@tone}>
      <.stat_card_content
        id={@id}
        label={@label}
        value={@value}
        icon={@icon}
        subtitle={@subtitle}
        tone={@tone}
        sparkline={@sparkline}
        sparkline_series={@sparkline_series}
      />
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:icon, :string, default: nil)
  attr(:subtitle, :string, default: nil)
  attr(:tone, :string, default: nil)
  attr(:sparkline, :list, default: [])
  attr(:sparkline_series, :list, default: nil)

  defp stat_card_content(assigns) do
    spark_id =
      if assigns.id do
        "#{assigns.id}-spark"
      else
        "lui-stat-spark-#{System.unique_integer([:positive])}"
      end

    assigns = assign(assigns, :spark_id, spark_id)

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
    <div :if={@sparkline != [] or @sparkline_series} class="lui-dt-stat-sparkline">
      <%= if @sparkline != [] do %>
        {render_slot(@sparkline)}
      <% else %>
        <LanternUI.Charts.sparkline
          id={@spark_id}
          series={@sparkline_series}
          color={if @tone, do: "currentColor", else: nil}
        />
      <% end %>
    </div>
    <span :if={@subtitle} class="lui-dt-stat-sub">{@subtitle}</span>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the grid.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through to the grid.")

  slot :stat,
    doc: "A summary metric card; provide its value with the :value attribute or inner content." do
    attr(:id, :string, doc: "Stable DOM id for the card.")
    attr(:label, :string, required: true, doc: "Short caption identifying the metric.")

    attr(:value, :any,
      doc: "Primary metric value; inner slot content takes precedence when present."
    )

    attr(:icon, :string, doc: "Optional host heroicon class shown by the label.")
    attr(:subtitle, :string, doc: "Optional muted context below the value.")
    attr(:tone, :string, doc: "Optional semantic tone for tinting and sparkline accent.")
    attr(:sparkline_series, :list, doc: "Optional numeric list rendered as a trend sparkline.")
    attr(:href, :string, doc: "Optional LiveView navigation target.")
    attr(:class, :any, doc: "Extra classes merged onto this card.")
  end

  @doc "Renders a responsive collection of summary metrics; emits nothing when empty."
  def stat_grid(assigns) do
    ~H"""
    <div
      :if={@stat != []}
      class={Class.merge(["lui-dt-stats", "lui-stat-grid", @class])}
      {@rest}
    >
      <.stat_card
        :for={stat <- @stat}
        id={stat[:id]}
        label={stat[:label]}
        value={if stat[:inner_block], do: render_slot(stat), else: stat[:value]}
        icon={stat[:icon]}
        subtitle={stat[:subtitle]}
        tone={stat[:tone]}
        sparkline_series={stat[:sparkline_series]}
        href={stat[:href]}
        class={stat[:class]}
      />
    </div>
    """
  end
end
