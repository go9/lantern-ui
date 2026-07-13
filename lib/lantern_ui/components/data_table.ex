defmodule LanternUI.Components.DataTable do
  @moduledoc """
  The admin data table — one Flop-driven table to replace the per-app
  `admin_table` copies. API deliberately mirrors the enventory/skusync
  baseline so swaps are mechanical.

      <.data_table id="orders" rows={@orders} meta={@meta} path={~p"/orders"}>
        <:col label="Order" field={:reference} sortable :let={o}>{o.reference}</:col>
        <:col label="Total" field={:total} sortable td_class="lui-td-num" :let={o}>
          {o.total}
        </:col>
        <:bulk_action label="Delete" icon="trash" event="bulk-delete" />
        <:row_action :let={o}>…</:row_action>
        <:empty>No orders yet.</:empty>
      </.data_table>

  - `meta` is a `Flop.Meta` (duck-typed — any map with `flop`, `params`,
    `current_page`, `total_pages`, `page_size`, `total_count` works), so
    lantern_ui carries no flop dependency.
  - Sorting, pagination, and page size are **patch navigation** against
    `path` — table state lives in the URL. Existing query params
    (`meta.params`, e.g. filters) are preserved.
  - Selection is server-owned: rows emit `toggle_select` (`phx-value-id`),
    the header checkbox emits `select_all_page`, the bulk bar emits
    `clear_selection` and each `bulk_action`'s `event` — all to `target`
    (defaults to the parent LiveView). Same contract as the baseline.

  Search, filter bar, tabs, and the stat overview arrive as chrome slots in a
  follow-up; this is the core.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button
  alias LanternUI.Components.EmptyState
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Pagination

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:meta, :map, required: true, doc: "Flop.Meta (or same-shaped map)")
  attr(:path, :string, required: true, doc: "base path for sort/pagination patches")
  attr(:selected_ids, :any, default: MapSet.new())
  attr(:row_id, :any, default: nil, doc: "row -> id fn; defaults to & &1.id")
  attr(:show_checkboxes, :boolean, default: true)
  attr(:target, :any, default: nil)
  attr(:title, :string, default: nil)
  attr(:page_size_options, :list, default: [10, 25, 50, 100])
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:header_action)
  slot(:toolbar)

  slot :col, required: true do
    attr(:label, :string)
    attr(:field, :atom)
    attr(:sortable, :boolean)
    attr(:class, :any)
    attr(:td_class, :any)
  end

  slot :bulk_action do
    attr(:label, :string)
    attr(:icon, :string)
    attr(:event, :string)
    attr(:color, :string)
  end

  slot(:row_action)
  slot(:empty)

  def data_table(assigns) do
    assigns =
      assigns
      |> assign(:row_id_fn, assigns.row_id || (& &1.id))
      |> assign(:selection_count, MapSet.size(assigns.selected_ids))
      |> assign(:page_ids, Enum.map(assigns.rows, assigns.row_id || (& &1.id)))

    assigns =
      assign(
        assigns,
        :all_selected?,
        assigns.page_ids != [] and Enum.all?(assigns.page_ids, &(&1 in assigns.selected_ids))
      )

    ~H"""
    <div id={@id} class={Class.merge(["lui-datatable", @class])} {@rest}>
      <div :if={@title || @header_action != []} class="lui-dt-header">
        <h2 :if={@title} class="lui-dt-title">{@title}</h2>
        <div class="lui-dt-header-actions">{render_slot(@header_action)}</div>
      </div>

      <div :if={@toolbar != []} class="lui-dt-toolbar">{render_slot(@toolbar)}</div>

      <div :if={@selection_count > 0} class="lui-dt-bulkbar">
        <span class="lui-dt-bulkcount">{@selection_count} selected</span>
        <Button.button
          :for={action <- @bulk_action}
          size="sm"
          variant={if action[:color] == "danger", do: "solid", else: "outline"}
          color={action[:color] || "primary"}
          phx-click={action[:event]}
          phx-target={@target}
        >
          <Icon.icon :if={action[:icon]} name={action[:icon]} /> {action[:label]}
        </Button.button>
        <Button.button size="sm" variant="ghost" phx-click="clear_selection" phx-target={@target}>
          Clear
        </Button.button>
      </div>

      <div class="lui-table-wrap">
        <table class="lui-table">
          <thead class="lui-thead">
            <tr>
              <th :if={@show_checkboxes} class="lui-th lui-th-check" scope="col">
                <input
                  type="checkbox"
                  class="lui-checkbox"
                  checked={@all_selected?}
                  phx-click="select_all_page"
                  phx-target={@target}
                  aria-label="Select all on page"
                />
              </th>
              <th :for={col <- @col} class={Class.merge(["lui-th", col[:class]])} scope="col">
                <.link
                  :if={col[:sortable] && col[:field]}
                  patch={sort_path(@path, @meta, col.field)}
                  class="lui-th-sort"
                >
                  {col[:label]}
                  <span class="lui-th-sort-icon">{sort_indicator(@meta, col.field)}</span>
                </.link>
                <span :if={!(col[:sortable] && col[:field])}>{col[:label]}</span>
              </th>
              <th :if={@row_action != []} class="lui-th lui-th-actions" scope="col"></th>
            </tr>
          </thead>
          <tbody class="lui-tbody">
            <tr :if={@rows == []}>
              <td class="lui-td lui-td-empty" colspan={colspan(assigns)}>
                <%= if @empty != [] do %>
                  {render_slot(@empty)}
                <% else %>
                  <EmptyState.empty_state icon="inbox" title="Nothing here yet" />
                <% end %>
              </td>
            </tr>
            <tr
              :for={row <- @rows}
              class={Class.merge(["lui-tr", @row_id_fn.(row) in @selected_ids && "lui-tr-selected"])}
            >
              <td :if={@show_checkboxes} class="lui-td lui-td-check">
                <input
                  type="checkbox"
                  class="lui-checkbox"
                  checked={@row_id_fn.(row) in @selected_ids}
                  phx-click="toggle_select"
                  phx-value-id={@row_id_fn.(row)}
                  phx-target={@target}
                  aria-label="Select row"
                />
              </td>
              <td :for={col <- @col} class={Class.merge(["lui-td", col[:td_class]])}>
                {render_slot(col, row)}
              </td>
              <td :if={@row_action != []} class="lui-td lui-td-actions">
                {render_slot(@row_action, row)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <Pagination.pagination
        :if={Map.get(@meta, :total_pages)}
        id={"#{@id}-pagination"}
        meta={@meta}
        patch_fn={&page_path(@path, @meta, &1)}
        page_size_options={@page_size_options}
        class="lui-dt-pagination"
      />
    </div>
    """
  end

  defp colspan(assigns) do
    length(assigns.col) + if(assigns.show_checkboxes, do: 1, else: 0) +
      if(assigns.row_action != [], do: 1, else: 0)
  end

  # ── URL builders ──────────────────────────────────────────────────────────
  # Start from meta.params (the current query string, incl. filters) and layer
  # page/order keys on top — the baseline admin_table's exact behavior.

  @doc false
  def page_path(path, meta, page_params) do
    params =
      base_params(meta)
      |> Map.put("page", Map.fetch!(page_params, :page))
      |> maybe_put("page_size", page_params[:page_size] || flop_get(meta, :page_size))

    path <> "?" <> Plug.Conn.Query.encode(params)
  end

  @doc false
  def sort_path(path, meta, field) do
    field_s = to_string(field)
    {current_by, current_dirs} = current_order(meta)

    {order_by, order_directions} =
      if current_by == [field_s] do
        dir = List.first(current_dirs) |> to_string()
        {[field_s], [if(dir == "asc", do: "desc", else: "asc")]}
      else
        {[field_s], ["asc"]}
      end

    params =
      base_params(meta)
      |> Map.put("order_by", order_by)
      |> Map.put("order_directions", order_directions)
      |> Map.delete("page")

    path <> "?" <> Plug.Conn.Query.encode(params)
  end

  @doc false
  def sort_indicator(meta, field) do
    field_s = to_string(field)
    {current_by, current_dirs} = current_order(meta)

    if current_by == [field_s] do
      if to_string(List.first(current_dirs)) == "desc", do: "↓", else: "↑"
    else
      ""
    end
  end

  defp base_params(meta) do
    meta |> Map.get(:params, %{}) |> Kernel.||(%{})
  end

  defp current_order(meta) do
    params = base_params(meta)

    by =
      (params["order_by"] || flop_get(meta, :order_by) || [])
      |> List.wrap()
      |> Enum.map(&to_string/1)

    dirs =
      (params["order_directions"] || flop_get(meta, :order_directions) || ["asc"])
      |> List.wrap()
      |> Enum.map(&to_string/1)

    {by, dirs}
  end

  defp flop_get(meta, key) do
    case Map.get(meta, :flop) do
      nil -> nil
      flop -> Map.get(flop, key)
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
