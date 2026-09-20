defmodule LanternUI.Components.Inspector do
  @moduledoc """
  Sticky right-rail inspector: optional section headings and label/value rows
  whose value may be any inline control.

      <.inspector aria-label="Ticket">
        <.inspector_section title="Properties">
          <.property_row label="Repo">enventory_new</.property_row>
          <.property_row label="Status">
            <.select id="status" name="status" value="in_progress" options={@statuses} />
          </.property_row>
        </.inspector_section>
      </.inspector>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the rail.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "`inspector_section/1` and `property_row/1` children.")

  def inspector(assigns) do
    ~H"""
    <aside class={Class.merge(["lui-inspector", @class])} {@rest}>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  attr(:title, :string, default: nil, doc: "Optional uppercase section heading.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the section.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Section body, usually `property_row/1`.")

  def inspector_section(assigns) do
    ~H"""
    <section class={Class.merge(["lui-inspector-section", @class])} {@rest}>
      <h3 :if={@title} class="lui-inspector-heading">{@title}</h3>
      <dl class="lui-inspector-list">{render_slot(@inner_block)}</dl>
    </section>
    """
  end

  attr(:label, :string, required: true, doc: "Row label (left column).")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Value: text or any inline control.")

  def property_row(assigns) do
    ~H"""
    <div class={Class.merge(["lui-property-row", @class])} {@rest}>
      <dt class="lui-property-label">{@label}</dt>
      <dd class="lui-property-value">{render_slot(@inner_block)}</dd>
    </div>
    """
  end
end
