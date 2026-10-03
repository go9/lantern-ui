defmodule LanternUI.Components.ListRow do
  @moduledoc """
  Dense issue/inbox row: leading glyph · muted mono id · truncating title ·
  meta · trailing. ~36px tall, hairline separators, hover tint.

      <.list_row identifier="#241" title="Visible progress ring" parent="Dense primitives" navigate="/tickets/241">
        <:leading><.status_glyph status={:in_progress} /></:leading>
        <:meta><.badge size="sm">ui</.badge></:meta>
        <:trailing>Sep 3</:trailing>
      </.list_row>

  Optional `parent` renders muted before the title with a › separator. The
  whole row is the hit target when `navigate`, `patch`, or `href` is set.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:identifier, :string,
    default: nil,
    doc: "Muted mono id shown after the leading glyph (e.g. `#241`)."
  )

  attr(:title, :string, required: true, doc: "Primary line; truncated.")

  attr(:parent, :string,
    default: nil,
    doc: "Optional parent title rendered muted with a › before `title`."
  )

  attr(:selected, :boolean, default: false, doc: "Selected/active row tint.")
  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; whole row is a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; whole row is a link.")
  attr(:href, :any, default: nil, doc: "External or full-page href; whole row is a link.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:leading, doc: "Leading glyph (status/priority/kind).")
  slot(:meta, doc: "Inline tags, counts, or other chips before the trailing column.")
  slot(:trailing, doc: "Trailing column (date, assignee).")

  def list_row(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <.link
      :if={@link?}
      class={Class.merge(["lui-list-row", @class])}
      data-selected={@selected || nil}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      {@rest}
    >
      <span :if={@leading != []} class="lui-list-row-leading">{render_slot(@leading)}</span>
      <span :if={@identifier} class="lui-list-row-id">{@identifier}</span>
      <span class="lui-list-row-title">
        <span :if={@parent} class="lui-list-row-parent">{@parent} ›</span>
        <span class="lui-list-row-name">{@title}</span>
      </span>
      <span :if={@meta != []} class="lui-list-row-meta">{render_slot(@meta)}</span>
      <span :if={@trailing != []} class="lui-list-row-trailing">{render_slot(@trailing)}</span>
    </.link>
    <div
      :if={!@link?}
      class={Class.merge(["lui-list-row", @class])}
      data-selected={@selected || nil}
      {@rest}
    >
      <span :if={@leading != []} class="lui-list-row-leading">{render_slot(@leading)}</span>
      <span :if={@identifier} class="lui-list-row-id">{@identifier}</span>
      <span class="lui-list-row-title">
        <span :if={@parent} class="lui-list-row-parent">{@parent} ›</span>
        <span class="lui-list-row-name">{@title}</span>
      </span>
      <span :if={@meta != []} class="lui-list-row-meta">{render_slot(@meta)}</span>
      <span :if={@trailing != []} class="lui-list-row-trailing">{render_slot(@trailing)}</span>
    </div>
    """
  end
end
