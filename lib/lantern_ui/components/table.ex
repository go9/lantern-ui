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

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def table(assigns) do
    ~H"""
    <div class={Class.merge(["lui-table-wrap", @class])} {@rest}>
      <table class="lui-table">
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col do
    attr(:class, :any)
  end

  slot(:inner_block)

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

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def table_body(assigns) do
    ~H"""
    <tbody class={Class.merge(["lui-tbody", @class])} {@rest}>
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  attr(:selected, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-value-id phx-target))

  slot :cell do
    attr(:class, :any)
  end

  slot(:inner_block)

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
