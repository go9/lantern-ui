defmodule LanternUI.Components.PriceGrid do
  @moduledoc """
  Priced, selectable permutation cells: the price matrix a holding picks its
  condition, grade or contents from.

    * `price_cell/1`: one cell, a label over its price, a hairline at rest and
      the accent fill when selected. Renders a `<button>` with `aria-pressed`.
    * `price_cell_group/1`: a captioned, wrapping row of cells (a card's raw
      conditions, a game's editions, contents or conditions).
    * `price_grid/1`: a rows x columns table of cells (grading companies x
      grades). Missing permutations leave an empty slot.

  Callers own the prices and their formatting; cells only present them.

      <.price_cell_group label="Raw">
        <.price_cell label="NM" price="$42" selected phx-click="pick" phx-value-id="1" />
        <.price_cell label="LP" price="$35" phx-click="pick" phx-value-id="2" />
      </.price_cell_group>

      <.price_grid
        label="Graded"
        columns={[%{key: "10", label: "10"}, %{key: "9", label: "9"}]}
        rows={[%{key: "psa", label: "PSA"}]}
        cells={%{{"psa", "10"} => %{price: "$410"}, {"psa", "9"} => %{price: "$120"}}}
        selected={{"psa", "10"}}
        on_pick="pick_grade"
      />
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:label, :string, required: true, doc: "Permutation name (condition, grade, contents).")
  attr(:price, :string, default: nil, doc: "Formatted price; nil renders an em dash.")
  attr(:show_price, :boolean, default: true, doc: "Hide the price line (e.g. edition cells).")
  attr(:selected, :boolean, default: false, doc: "The picked permutation (accent fill).")
  attr(:disabled, :boolean, default: false, doc: "Not pickable.")

  attr(:count, :integer,
    default: nil,
    doc: "Copies held at this permutation: a corner `×N` badge and an outline. nil/0 hides it."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the cell.")

  attr(:rest, :global,
    include: ~w(name value form),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  @doc "Renders one priced, selectable cell."
  def price_cell(assigns) do
    ~H"""
    <button
      type="button"
      class={Class.merge(["lui-price-cell", @class])}
      aria-pressed={to_string(@selected)}
      data-selected={@selected && "true"}
      data-counted={counted?(@count) && "true"}
      disabled={@disabled}
      {@rest}
    >
      <span class="lui-price-cell-label">{@label}</span>
      <span :if={@show_price} class="lui-price-cell-price">{@price || "—"}</span>
      <span :if={counted?(@count)} class="lui-price-cell-count">
        <span aria-hidden="true">×{@count}</span><span class="lui-sr-only">, {@count} held</span>
      </span>
    </button>
    """
  end

  defp counted?(count), do: is_integer(count) and count > 0

  attr(:label, :string, default: nil, doc: "Caption above the row; also the group's name.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the group.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")
  slot(:inner_block, required: true, doc: "The `price_cell/1`s.")

  @doc "Renders a captioned, wrapping row of price cells."
  def price_cell_group(assigns) do
    ~H"""
    <div class={Class.merge(["lui-price-group", @class])} {@rest}>
      <p :if={@label} class="lui-price-caption">{@label}</p>
      <div class="lui-price-row" role="group" aria-label={@label}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:label, :string, default: nil, doc: "Caption above the grid; also the table's name.")
  attr(:rows, :list, required: true, doc: "Row headers: `%{key, label}` (e.g. companies).")
  attr(:columns, :list, required: true, doc: "Column headers: `%{key, label}` (e.g. grades).")

  attr(:cells, :map,
    required: true,
    doc:
      "`%{{row_key, column_key} => %{price, disabled, count}}`; a missing key is an empty slot."
  )

  attr(:selected, :any, default: nil, doc: "`{row_key, column_key}` of the picked cell.")

  attr(:on_pick, :any,
    default: nil,
    doc: "`phx-click` for every cell; sends `row` and `column` as phx-values."
  )

  attr(:target, :any, default: nil, doc: "`phx-target` for the pick event.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the wrapper.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")

  @doc "Renders a rows x columns table of price cells."
  def price_grid(assigns) do
    ~H"""
    <div class={Class.merge(["lui-price-group", @class])} {@rest}>
      <p :if={@label} class="lui-price-caption">{@label}</p>
      <div class="lui-price-grid-scroll">
        <table class="lui-price-grid" aria-label={@label}>
          <thead>
            <tr>
              <td></td>
              <th :for={column <- @columns} scope="col">{column.label}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows}>
              <th scope="row">{row.label}</th>
              <td :for={column <- @columns}>
                <.price_cell
                  :if={cell = Map.get(@cells, {row.key, column.key})}
                  label={"#{row.label} #{column.label}"}
                  price={cell[:price]}
                  selected={@selected == {row.key, column.key}}
                  disabled={cell[:disabled] || false}
                  count={cell[:count]}
                  class="lui-price-cell-compact"
                  phx-click={@on_pick}
                  phx-target={@target}
                  phx-value-row={row.key}
                  phx-value-column={column.key}
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
