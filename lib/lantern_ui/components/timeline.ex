defmodule LanternUI.Components.Timeline do
  @moduledoc """
  Timeline: a vertical sequence of events with a marker rail. No Fluxon
  equivalent. Pure presentational server render; no JS hook.

      <.timeline label_position={:leading}>
        <.timeline_item status={:done} label="Deployed" at="2h ago" title="enventory" />
        <.timeline_item status={:active} label="Deploying" at="40s" title="foodfeed" open>
          <:detail>
            <pre>==> Building release
    Compiling 12 files (.ex)
    Generated foodfeed app</pre>
          </:detail>
        </.timeline_item>
        <.timeline_item status={:pending} label="Queued" at="just now" title="skusync">
          Waiting on the build.
        </.timeline_item>
      </.timeline>

  The root is an ordered list (`<ol>`): items are steps in sequence, which
  matters for screen readers. Each item paints a marker (dot, optional icon,
  or a custom `:marker` slot such as an avatar) on a left rail; a connector
  line runs between consecutive markers and is hidden on the last item via
  CSS `:last-child` (callers never pass a flag).

  `status` colors the marker through `data-status`. The `label` text is the
  state word (e.g. "Deployed", "Failed") and must be set whenever `status` is
  meaningful so state is never color-only. `at` is a preformatted
  timestamp/relative string from the caller; the component does not format
  time.

  `label_position={:leading}` on `timeline/1` places each item's `at` in a
  fixed-width column left of the marker rail (timestamps scan as a column).
  Items inherit that value and may override. Tune the column with
  `--lui-timeline-label-w`.

  When `:detail` is present the title/label/at row becomes a native
  `<details>`/`<summary>` disclosure (no accordion, no JS hook). `open`
  sets the initial expanded state.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  @statuses [:done, :active, :pending, :danger, :neutral]
  @label_positions [:inline, :leading]
  @label_position_key {__MODULE__, :label_position}

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:label_position, :atom,
    values: @label_positions,
    default: :inline,
    doc:
      "Where items place `at`: `:inline` (default, inside content) or `:leading` (fixed column left of the marker rail). Inherited by items unless overridden."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "One or more `timeline_item/1` children.")

  def timeline(assigns) do
    # HEEx defers slot evaluation until the tree is stringified, so a try/after
    # restore would clear this before items read it. Items resolve via Process
    # (or their own override); the next timeline/1 call overwrites the value.
    Process.put(@label_position_key, assigns.label_position)

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

  attr(:label_position, :atom,
    default: nil,
    doc:
      "Where to place `at` (`:inline` or `:leading`). Inherits from the parent `timeline/1` when omitted; parent defaults to `:inline`."
  )

  attr(:open, :boolean,
    default: false,
    doc: "When `:detail` is present, whether the disclosure starts open."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the item root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Optional body/description under the title.")

  slot(:detail,
    doc:
      "Collapsible body revealed under a native disclosure. When present, title/label/at become the summary."
  )

  slot(:marker,
    doc:
      "Custom marker content (e.g. an avatar). Replaces the status dot and `icon`. Sized by CSS so rail alignment is preserved."
  )

  def timeline_item(assigns) do
    label_position = assigns.label_position || Process.get(@label_position_key, :inline)

    assigns =
      assigns
      |> assign(:label_position, label_position)
      |> assign(:leading?, label_position == :leading)
      |> assign(:has_detail?, assigns.detail != [])
      |> assign(:has_marker?, assigns.marker != [])

    ~H"""
    <li
      class={Class.merge(["lui-timeline-item", @class])}
      data-status={@status}
      data-label-position={@leading? && "leading"}
      {@rest}
    >
      <span :if={@leading? && @at} class="lui-timeline-at">{@at}</span>
      <div class="lui-timeline-marker" aria-hidden="true">
        <%= cond do %>
          <% @has_marker? -> %>
            <span class="lui-timeline-dot" data-slot="marker">{render_slot(@marker)}</span>
          <% @icon -> %>
            <span class="lui-timeline-dot">
              <Icon.icon name={@icon} />
            </span>
          <% true -> %>
            <span class="lui-timeline-dot"></span>
        <% end %>
        <span class="lui-timeline-connector"></span>
      </div>
      <div class="lui-timeline-content">
        <%= if @has_detail? do %>
          <details class="lui-timeline-details" open={@open}>
            <summary class="lui-timeline-summary">
              <span :if={@title} class="lui-timeline-title">{@title}</span>
              <span :if={@label} class="lui-timeline-label">{@label}</span>
              <span :if={!@leading? && @at} class="lui-timeline-at">{@at}</span>
            </summary>
            <div class="lui-timeline-detail">{render_slot(@detail)}</div>
          </details>
        <% else %>
          <span :if={@title} class="lui-timeline-title">{@title}</span>
          <span :if={@label} class="lui-timeline-label">{@label}</span>
          <span :if={!@leading? && @at} class="lui-timeline-at">{@at}</span>
        <% end %>
        <div :if={@inner_block != []} class="lui-timeline-body">{render_slot(@inner_block)}</div>
      </div>
    </li>
    """
  end
end
