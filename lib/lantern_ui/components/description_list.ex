defmodule LanternUI.Components.DescriptionList do
  @moduledoc """
  Label/value pairs for a record's detail view — the `<dl>` every show page
  hand-rolls.

      <.description_list>
        <:item label="Created">Jan 4, 2026</:item>
        <:item label="Host">Alex Smith</:item>
        <:item label="Description" wide>Long free text…</:item>
      </.description_list>

  `columns` sets how many pairs sit side by side on a wide viewport; it always
  collapses to one column on narrow screens. `layout="inline"` puts the label
  beside its value instead of above it, for dense side panels.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:columns, :integer, default: 2, values: [1, 2, 3], doc: "Pairs per row on wide viewports.")

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked inline),
    doc: "`stacked` puts the label above the value; `inline` puts it alongside."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")

  slot :item, required: true, doc: "One label/value pair." do
    attr(:label, :string, required: true, doc: "The pair's label.")
    attr(:wide, :boolean, doc: "Span every column — for long free text.")
    attr(:class, :any, doc: "Extra classes merged onto this pair.")
  end

  def description_list(assigns) do
    ~H"""
    <dl
      class={
        Class.merge([
          "lui-dl",
          "lui-dl-#{@layout}",
          "lui-dl-cols-#{@columns}",
          @class
        ])
      }
      {@rest}
    >
      <div
        :for={item <- @item}
        class={Class.merge(["lui-dl-row", item[:wide] && "lui-dl-wide", item[:class]])}
      >
        <dt class="lui-dl-label">{item[:label]}</dt>
        <dd class="lui-dl-value">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end
end
