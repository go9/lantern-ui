defmodule LanternUI.Components.Waterfall do
  @moduledoc """
  Waterfall: horizontal spans laid out on ONE shared time axis, with a ruler.
  No Fluxon equivalent. Pure presentational server render; no JS hook.

      <.waterfall id="run-phases" ticks={@ticks} label="Phase">
        <.waterfall_lane label="plan" status={:done} left={0.0} width={31.4} bar_label="4m 12s" />
        <.waterfall_lane label="implement" status={:danger} left={31.4} width={52.1} bar_label="7m 02s" />
        <.waterfall_lane label="test" status={:pending} queued bar_label="queued" />
      </.waterfall>

  ## Why this is not `timeline/1`

  `timeline/1` is a VERTICAL sequence sized by its content: a marker rail, a
  connector, one row per event. A waterfall is horizontal and sized by
  DURATION — the whole claim it makes is that two lanes are comparable because
  their bars are measured against the same axis. Those are different layouts,
  not two modes of one component, and a component that tried to be both would
  have to choose which of the two its `status`, spacing and rail meant.

  ## The axis is the component's contract

  The caller supplies `left` and `width` as PERCENTAGES of a shared axis it
  computed, and `ticks` as percentages on that same axis. The component does
  no time math and formats no timestamps — it cannot, because only the caller
  knows whether the axis is wall-clock, CPU time, or bytes. What the component
  guarantees is that the ruler, the gridlines and every lane's bar are laid out
  in ONE track of identical width, so those percentages mean the same thing on
  every row. That is why the ticks live on the root and are drawn ONCE, as a
  grid layer behind every lane, rather than passed to each lane: two lanes
  cannot disagree about an axis neither of them owns.

  A lane with no position on the axis (never started) is `queued` — rendered as
  a dashed placeholder at the right edge rather than given a fabricated
  `left`. Inventing a position for work that has not happened is the one thing
  a waterfall must not do.

  `--lui-waterfall-label-w` tunes the label column.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  @statuses [:done, :active, :pending, :danger, :warning, :neutral]

  attr(:id, :string, default: nil, doc: "DOM id for the root element.")

  attr(:ticks, :list,
    default: [],
    doc:
      "Shared axis ruler marks: a list of `%{label: string, pct: number}`, where `pct` is a percentage of the same axis lanes position against. Also drawn as gridlines behind the lanes."
  )

  attr(:label, :string,
    default: nil,
    doc: "Heading for the label column, rendered above the lane labels."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "One or more `waterfall_lane/1` children.")

  def waterfall(assigns) do
    ~H"""
    <div id={@id} class={Class.merge(["lui-waterfall", @class])} {@rest}>
      <div class="lui-waterfall-ruler" aria-hidden="true">
        <span class="lui-waterfall-ruler-label">{@label}</span>
        <div class="lui-waterfall-ruler-track">
          <span :for={tick <- @ticks} class="lui-waterfall-tick" style={"left: #{tick.pct}%;"}>
            <span class="lui-waterfall-tick-label">{tick.label}</span>
          </span>
        </div>
      </div>
      <div class="lui-waterfall-body">
        <%!-- Drawn once, in the track column, behind every lane. Sharing one
              layer is what makes a tick mean the same thing on every row. --%>
        <div class="lui-waterfall-grid" aria-hidden="true">
          <span :for={tick <- @ticks} class="lui-waterfall-gridline" style={"left: #{tick.pct}%;"}></span>
        </div>
        <ol class="lui-waterfall-lanes">
          {render_slot(@inner_block)}
        </ol>
      </div>
    </div>
    """
  end

  attr(:label, :string, default: nil, doc: "Lane name, shown in the fixed label column.")

  attr(:at, :string,
    default: nil,
    doc: "Optional preformatted secondary line under the label; not formatted by the component."
  )

  attr(:status, :atom,
    values: @statuses,
    default: :neutral,
    doc: "Bar status, rendered as data-status for CSS coloring."
  )

  attr(:state_label, :string,
    default: nil,
    doc:
      "State word (e.g. \"Failed\"). Set whenever status is meaningful so state is never color-only; rendered for assistive tech."
  )

  attr(:left, :float, default: 0.0, doc: "Bar start as a percentage of the shared axis.")
  attr(:width, :float, default: 0.0, doc: "Bar length as a percentage of the shared axis.")

  attr(:bar_label, :string,
    default: nil,
    doc: "Text inside (or beside) the bar, typically a preformatted duration."
  )

  attr(:queued, :boolean,
    default: false,
    doc:
      "Lane has no position on the axis yet. Renders a dashed placeholder at the right edge instead of a positioned bar; `left`/`width` are ignored."
  )

  attr(:icon, :string, default: nil, doc: "Optional lantern icon name shown beside the label.")
  attr(:selected, :boolean, default: false, doc: "Marks this lane as the current selection.")

  attr(:navigate, :string, default: nil, doc: "When set, the whole lane is a navigation link.")
  attr(:patch, :string, default: nil, doc: "When set, the whole lane is a patch link.")

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the lane root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional trailing content in the label column (badges, counts).")

  def waterfall_lane(assigns) do
    assigns =
      assigns
      |> assign(:link?, assigns.navigate != nil or assigns.patch != nil)
      # A bar narrower than this is invisible; the floor keeps a very short
      # phase clickable and visible without lying about where it started.
      |> assign(:bar_width, max(assigns.width, 0.4))

    ~H"""
    <li
      class={Class.merge(["lui-waterfall-lane", @class])}
      data-status={@status}
      data-selected={@selected && "true"}
      data-queued={@queued && "true"}
      {@rest}
    >
      <.link :if={@link?} navigate={@navigate} patch={@patch} class="lui-waterfall-lane-inner">
        <.lane_content
          icon={@icon}
          label={@label}
          at={@at}
          state_label={@state_label}
          left={@left}
          bar_width={@bar_width}
          bar_label={@bar_label}
          queued={@queued}
          extra={@inner_block}
        />
      </.link>
      <div :if={!@link?} class="lui-waterfall-lane-inner">
        <.lane_content
          icon={@icon}
          label={@label}
          at={@at}
          state_label={@state_label}
          left={@left}
          bar_width={@bar_width}
          bar_label={@bar_label}
          queued={@queued}
          extra={@inner_block}
        />
      </div>
    </li>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:at, :string, required: true)
  attr(:state_label, :string, required: true)
  attr(:left, :float, required: true)
  attr(:bar_width, :float, required: true)
  attr(:bar_label, :string, required: true)
  attr(:queued, :boolean, required: true)
  attr(:extra, :any, required: true)

  defp lane_content(assigns) do
    ~H"""
    <span class="lui-waterfall-lane-label">
      <span class="lui-waterfall-lane-name">
        <Icon.icon :if={@icon} name={@icon} class="lui-waterfall-lane-icon" />
        {@label}
        <span :if={@state_label} class="lui-sr-only">{@state_label}</span>
      </span>
      <span :if={@at} class="lui-waterfall-lane-at">{@at}</span>
      <span :if={@extra != []} class="lui-waterfall-lane-extra">{render_slot(@extra)}</span>
    </span>
    <span class="lui-waterfall-lane-track">
      <span :if={@queued} class="lui-waterfall-bar" data-queued="true">
        <span class="lui-waterfall-bar-label">{@bar_label}</span>
      </span>
      <span
        :if={!@queued}
        class="lui-waterfall-bar"
        style={"left: #{@left}%; width: #{@bar_width}%;"}
        title={@bar_label}
      >
        <span class="lui-waterfall-bar-label">{@bar_label}</span>
      </span>
    </span>
    """
  end
end
