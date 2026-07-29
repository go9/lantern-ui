defmodule LanternUI.Components.Timeline do
  @moduledoc """
  Timeline — a vertical sequence of events with a marker rail. No Fluxon
  equivalent. Pure presentational server render; no JS hook.

      <.timeline>
        <.timeline_item status={:done} label="Deployed" at="2h ago" title="enventory" />
        <.timeline_item status={:active} label="Deploying" at="40s" title="foodfeed" />
        <.timeline_item status={:pending} label="Queued" at="just now" title="skusync">
          Waiting on the build.
        </.timeline_item>
      </.timeline>

  The root is an ordered list (`<ol>`): items are steps in sequence, which
  matters for screen readers. Each item paints a marker (dot, or optional
  icon) on a left rail; a connector line runs between consecutive markers and
  is hidden on the last item via CSS `:last-child` (callers never pass a flag).

  `status` colors the marker through `data-status`. The `label` text is the
  state word (e.g. "Deployed", "Failed") and must be set whenever `status` is
  meaningful so state is never color-only. `at` is a preformatted
  timestamp/relative string from the caller; the component does not format
  time.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  @statuses [:done, :active, :pending, :danger, :neutral]

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "One or more `timeline_item/1` children.")

  def timeline(assigns) do
    ~H"""
    <ol class={Class.merge(["lui-timeline", @class])} {@rest}>
      {render_slot(@inner_block)}
    </ol>
    """
  end

  attr(:title, :string, default: nil, doc: "Primary line (e.g. app or event name).")

  attr(:label, :string,
    default: nil,
    doc: "State word (e.g. \"Deployed\", \"Failed\"). Set whenever status is meaningful."
  )

  attr(:at, :string,
    default: nil,
    doc: "Preformatted timestamp or relative string; not formatted by the component."
  )

  attr(:status, :atom,
    values: @statuses,
    default: :neutral,
    doc: "Marker status; rendered as data-status for CSS coloring."
  )

  attr(:icon, :string,
    default: nil,
    doc: "Optional lantern icon name rendered inside the marker instead of the plain dot."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the item root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional body/description under the title.")

  def timeline_item(assigns) do
    ~H"""
    <li
      class={Class.merge(["lui-timeline-item", @class])}
      data-status={@status}
      {@rest}
    >
      <div class="lui-timeline-marker" aria-hidden="true">
        <%= if @icon do %>
          <span class="lui-timeline-dot">
            <Icon.icon name={@icon} />
          </span>
        <% else %>
          <span class="lui-timeline-dot"></span>
        <% end %>
        <span class="lui-timeline-connector"></span>
      </div>
      <div class="lui-timeline-content">
        <span :if={@title} class="lui-timeline-title">{@title}</span>
        <span :if={@label} class="lui-timeline-label">{@label}</span>
        <span :if={@at} class="lui-timeline-at">{@at}</span>
        <div :if={@inner_block != []} class="lui-timeline-body">{render_slot(@inner_block)}</div>
      </div>
    </li>
    """
  end
end
