defmodule LanternUI.Components.LogView do
  @moduledoc """
  Log view: monospace lines with a timestamp gutter and per-line severity.
  No Fluxon equivalent. Pure presentational server render; no JS hook.

      <.log_view id="run-trace" label="Trace">
        <.log_line at="12:04:03" channel="bash" severity={:neutral}>ls -la src</.log_line>
        <.log_line at="12:04:05" channel="bash" severity={:error} meta="412ms">
          No such file or directory
          <:detail>{@stack}</:detail>
        </.log_line>
      </.log_view>

  ## Why this is not an editor, and not a `<pre>`

  Command output keeps arriving in read-only code EDITORS across this
  portfolio, and it reads wrong every time: an editor offers a caret, a
  selection model and a gutter that implies you may type, for content nobody
  can edit. A bare `<pre>` has the opposite problem — no timestamps, no
  severity, and it pushes the page sideways the moment one line is long.

  This component takes the third position. Lines are data: each carries an
  optional preformatted `at`, a `channel` (the tool, stream or subsystem that
  produced it), a `severity`, and trailing `meta` such as a duration. Severity
  bands the line with a colored left edge AND is announced to assistive tech,
  so it is never color-only.

  ## Containment is the load-bearing rule

  The scroll lives on the log view, never on the page: the root is the
  `overflow: auto` box, so a 400-character line scrolls INSIDE the component
  and the document body never scrolls horizontally. `wrap` flips individual
  lines to soft-wrapping when reading beats fidelity. Set a height on the root
  (or let a flex parent give it one) and the header stays pinned while the
  lines scroll under it.

  `--lui-log-view-gutter-w` tunes the timestamp column.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @severities [:neutral, :info, :success, :warning, :error]

  @severity_labels %{
    neutral: nil,
    info: "Info",
    success: "Success",
    warning: "Warning",
    error: "Error"
  }

  attr(:id, :string, default: nil, doc: "DOM id for the root element.")

  attr(:label, :string,
    default: nil,
    doc: "Optional heading pinned above the lines while they scroll."
  )

  attr(:wrap, :boolean,
    default: false,
    doc:
      "Soft-wrap long lines instead of scrolling them horizontally. Inherited by lines unless overridden."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "Controls rendered at the right of the header (filters, toggles).")
  slot(:inner_block, required: true, doc: "One or more `log_line/1` children.")

  def log_view(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-log-view", @class])}
      data-wrap={@wrap && "true"}
      {@rest}
    >
      <div :if={@label || @actions != []} class="lui-log-view-header">
        <span :if={@label} class="lui-log-view-label">{@label}</span>
        <span :if={@actions != []} class="lui-log-view-actions">{render_slot(@actions)}</span>
      </div>
      <ol class="lui-log-view-lines">
        {render_slot(@inner_block)}
      </ol>
    </div>
    """
  end

  attr(:at, :string,
    default: nil,
    doc: "Preformatted timestamp for the gutter; the component does not format time."
  )

  attr(:channel, :string,
    default: nil,
    doc: "What produced the line — a tool name, stream, or subsystem."
  )

  attr(:severity, :atom,
    values: @severities,
    default: :neutral,
    doc: "Line severity. Bands the line and is announced to assistive tech."
  )

  attr(:meta, :string, default: nil, doc: "Trailing detail, typically a duration.")
  attr(:selected, :boolean, default: false, doc: "Marks this line as the current selection.")
  attr(:open, :boolean, default: false, doc: "When `:detail` is present, start expanded.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the line root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "The line body.")

  slot(:detail,
    doc:
      "Collapsible body revealed under a native disclosure. When present, the line is a summary."
  )

  def log_line(assigns) do
    assigns =
      assigns
      |> assign(:has_detail?, assigns.detail != [])
      |> assign(:severity_label, Map.fetch!(@severity_labels, assigns.severity))

    ~H"""
    <li
      class={Class.merge(["lui-log-line", @class])}
      data-severity={@severity}
      data-selected={@selected && "true"}
      {@rest}
    >
      <%= if @has_detail? do %>
        <details class="lui-log-line-details" open={@open}>
          <summary class="lui-log-line-row">
            <.log_line_cells
              at={@at}
              channel={@channel}
              meta={@meta}
              severity_label={@severity_label}
              body={@inner_block}
            />
          </summary>
          <div class="lui-log-line-detail">{render_slot(@detail)}</div>
        </details>
      <% else %>
        <div class="lui-log-line-row">
          <.log_line_cells
            at={@at}
            channel={@channel}
            meta={@meta}
            severity_label={@severity_label}
            body={@inner_block}
          />
        </div>
      <% end %>
    </li>
    """
  end

  attr(:at, :string, required: true)
  attr(:channel, :string, required: true)
  attr(:meta, :string, required: true)
  attr(:severity_label, :string, required: true)
  attr(:body, :any, required: true)

  defp log_line_cells(assigns) do
    ~H"""
    <span :if={@severity_label} class="lui-sr-only">{@severity_label}:</span>
    <time :if={@at} class="lui-log-line-at">{@at}</time>
    <span :if={@channel} class="lui-log-line-channel">{@channel}</span>
    <span class="lui-log-line-body">{render_slot(@body)}</span>
    <span :if={@meta} class="lui-log-line-meta">{@meta}</span>
    """
  end
end
