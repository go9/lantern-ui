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

  `table_body/1` is the body wrapper in the anatomy above. It accepts
  `table_row/1` children and keeps row rendering separate from the header.

  `table_placeholder_row/1` is the add/intent row — a real control spanning
  the table, not a fake disabled record.

      <.table_body>
        <.table_row :for={o <- @orders}>…</.table_row>
        <.table_placeholder_row colspan={2} label="Add order" kbd="A" phx-click="add" />
      </.table_body>

  `table_head/1` is one header row. Multi-row matrix heads (`colspan` /
  `rowspan` / `headers` associations and extra sticky offsets) are reserved
  for a later API; do not encode them in `data_table`.

  Sort affordances, pagination, selection state, and Flop wiring live in
  `data_table`; this family is pure markup + tokens.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Kbd

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

  attr(:colspan, :integer,
    default: 1,
    doc: "Number of columns this intent row spans (match the header)."
  )

  attr(:label, :string, required: true, doc: "Accessible name and visible add/intent copy.")

  attr(:kbd, :string,
    default: nil,
    doc: "Optional keycap hint; binds window keydown with phx-click."
  )

  attr(:icon, :string, default: "plus", doc: "Leading icon name; pass nil to hide.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")

  attr(:navigate, :string,
    default: nil,
    doc: "LiveView navigate target; the control renders as a link."
  )

  attr(:patch, :string,
    default: nil,
    doc: "LiveView patch target; the control renders as a link."
  )

  attr(:href, :any, default: nil, doc: "External/full-page href; the control renders as a link.")

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through to the control.")

  slot(:inner_block, doc: "Optional control contents; defaults to icon, label, and keycap.")

  def table_placeholder_row(assigns) do
    assigns = assign(assigns, :action_rest, shortcut_rest(assigns))

    ~H"""
    <tr class={Class.merge(["lui-tr", "lui-tr-placeholder", @class])} data-placeholder>
      <td class="lui-td lui-td-placeholder" colspan={@colspan}>
        <Button.button
          variant="ghost"
          size="sm"
          class="lui-placeholder-action"
          label={@label}
          navigate={@navigate}
          patch={@patch}
          href={@href}
          aria-keyshortcuts={@kbd}
          {@action_rest}
        >
          <%= if @inner_block != [] do %>
            {render_slot(@inner_block)}
          <% else %>
            <Icon.icon :if={@icon} name={@icon} />
            <span>{@label}</span>
            <Kbd.kbd :if={@kbd} size="xs" variant="ghost" aria-hidden="true">{@kbd}</Kbd.kbd>
          <% end %>
        </Button.button>
      </td>
    </tr>
    """
  end

  defp shortcut_rest(assigns) do
    rest = assigns.rest
    click = rest["phx-click"] || rest[:"phx-click"]
    kbd = assigns.kbd

    if is_binary(click) and is_binary(kbd) and is_nil(rest["phx-window-keydown"]) and
         is_nil(rest[:"phx-window-keydown"]) do
      Map.merge(rest, %{
        "phx-window-keydown" => click,
        "phx-key" => String.downcase(kbd)
      })
    else
      rest
    end
  end
end
