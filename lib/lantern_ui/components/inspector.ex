defmodule LanternUI.Components.Inspector do
  @moduledoc """
  Sticky right-rail inspector: optional section headings and a dense
  `description_list`.

      <.inspector aria-label="Ticket">
        <.inspector_section title="Properties">
          <.description_list layout="dense">
            <:item label="Repo">enventory_new</:item>
            <:item label="Status">
              <.select id="status" name="status" value="in_progress" options={@statuses} />
            </:item>
          </.description_list>
        </.inspector_section>
      </.inspector>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.DescriptionList
  alias LanternUI.Deprecated

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the rail.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:inner_block,
    required: true,
    doc: "`inspector_section/1` and `description_list` / `property_row/1` children."
  )

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
  slot(:inner_block, required: true, doc: "Section body, usually a dense `description_list`.")

  def inspector_section(assigns) do
    ~H"""
    <section class={Class.merge(["lui-inspector-section", @class])} {@rest}>
      <h3 :if={@title} class="lui-inspector-heading">{@title}</h3>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:label, :string, required: true, doc: "Row label (left column).")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Value: text or any inline control.")

  @deprecated "Use description_list/1 with layout=\"dense\" and <:item>. Removed in 0.9.0."
  def property_row(assigns) do
    Deprecated.warn(:property_row, ~s|<.description_list layout="dense"> with <:item>|)

    ~H"""
    <DescriptionList.description_list layout="dense" class={@class} {@rest}>
      <:item label={@label}>{render_slot(@inner_block)}</:item>
    </DescriptionList.description_list>
    """
  end
end
