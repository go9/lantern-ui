defmodule LanternUI.Components.DescriptionList do
  @moduledoc """
  Label/value pairs for a record's detail view — the `<dl>` every show page
  hand-rolls.

      <.description_list>
        <:item label="Created">Jan 4, 2026</:item>
        <:item label="Host">Alex Smith</:item>
        <:item label="Description" wide>Long free text…</:item>
      </.description_list>

      <.description_list layout="dense">
        <:item label="Repo">enventory_new</:item>
        <:item label="Status">{@status}</:item>
      </.description_list>

  `columns` sets how many pairs sit side by side on a wide viewport; it always
  collapses to one column on narrow screens. `layout="inline"` puts the label
  beside its value instead of above it. `layout="dense"` is the inspector-rail
  grid (label column + value).
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:columns, :integer, default: 2, values: [1, 2, 3], doc: "Pairs per row on wide viewports.")

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked inline dense),
    doc:
      "`stacked` puts the label above the value; `inline` puts it alongside; `dense` is the inspector rail."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")

  slot :item, required: true, doc: "One label/value pair." do
    attr(:label, :string, required: true, doc: "The pair's label.")
    attr(:wide, :boolean, doc: "Span every column — for long free text.")
    attr(:class, :any, doc: "Extra classes merged onto this pair.")
  end

  def description_list(assigns) do
    dense? = assigns.layout == "dense"
    assigns = assign(assigns, :dense?, dense?)

    ~H"""
    <dl
      class={
        Class.merge([
          "lui-dl",
          "lui-dl-#{@layout}",
          not @dense? && "lui-dl-cols-#{@columns}",
          @dense? && "lui-inspector-list",
          @class
        ])
      }
      {@rest}
    >
      <div
        :for={item <- @item}
        class={
          Class.merge([
            "lui-dl-row",
            @dense? && "lui-property-row",
            item[:wide] && "lui-dl-wide",
            item[:class]
          ])
        }
      >
        <dt class={Class.merge(["lui-dl-label", @dense? && "lui-property-label"])}>
          {item[:label]}
        </dt>
        <dd class={Class.merge(["lui-dl-value", @dense? && "lui-property-value"])}>
          {render_slot(item)}
        </dd>
      </div>
    </dl>
    """
  end
end
