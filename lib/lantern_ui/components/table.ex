defmodule LanternUI.Components.Table do
  @moduledoc """
  Presentational table family — the styled substrate `data_table` composes.
  Mirrors Fluxon's `table`/`table_head`/`table_body`/`table_row` surface.

      <.table>
        <.table_head>
          <:col>Name</:col>
          <:col class="text-right">Total</:col>
        </.table_head>
        <.table_body>
          <.table_row :for={o <- @orders} selected={o.id in @selected}>
            <:cell>{o.name}</:cell>
            <:cell class="lui-td-num">{o.total}</:cell>
          </.table_row>
        </.table_body>
      </.table>

  Sort affordances, pagination, selection state, and Flop wiring live in
  `data_table`; this family is pure markup + tokens.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "table_head and table_body children.")

  def table(assigns) do
    ~H"""
    <div class={Class.merge(["lui-table-wrap", @class])} {@rest}>
      <table class="lui-table">
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :col, doc: "Header cell content for one column." do
    attr(:class, :any, doc: "Extra classes on this header cell.")
  end

  slot(:inner_block, doc: "Optional raw thead row content after :col cells.")

  def table_head(assigns) do
    ~H"""
    <thead class={Class.merge(["lui-thead", @class])} {@rest}>
      <tr>
        <th :for={col <- @col} class={Class.merge(["lui-th", col[:class]])} scope="col">
          {render_slot(col)}
        </th>
        {render_slot(@inner_block)}
      </tr>
    </thead>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "table_row children.")

  def table_body(assigns) do
    ~H"""
    <tbody class={Class.merge(["lui-tbody", @class])} {@rest}>
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  attr(:selected, :boolean, default: false, doc: "Highlight the row as selected.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(phx-click phx-value-id phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  slot :cell, doc: "One body cell in column order." do
    attr(:class, :any, doc: "Extra classes on this cell.")
  end

  slot(:inner_block, doc: "Optional raw row content after :cell cells.")

  def table_row(assigns) do
    ~H"""
    <tr
      class={Class.merge(["lui-tr", @selected && "lui-tr-selected", @class])}
      {@rest}
    >
      <td :for={cell <- @cell} class={Class.merge(["lui-td", cell[:class]])}>
        {render_slot(cell)}
      </td>
      {render_slot(@inner_block)}
    </tr>
    """
  end
end
