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
  alias LanternUI.Components.Dropdown
  alias LanternUI.Components.EmptyState
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Badge
  alias LanternUI.Components.Pagination
  alias LanternUI.Components.Tabs

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:meta, :map, required: true, doc: "Flop.Meta (or same-shaped map)")
  attr(:path, :string, required: true, doc: "base path for sort/pagination patches")
  attr(:selected_ids, :any, default: MapSet.new())
  attr(:row_id, :any, default: nil, doc: "row -> id fn; defaults to & &1.id")
  attr(:show_checkboxes, :boolean, default: true)
  attr(:target, :any, default: nil)
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil)

  attr(:info_modal_id, :string,
    default: nil,
    doc: "modal id the title's info button opens (LanternUI.open_dialog)"
  )

  attr(:page_size_options, :list, default: [10, 25, 50, 100])

  attr(:search_field, :atom,
    default: nil,
    doc: "Flop filter field the built-in search box binds to"
  )

  attr(:search_op, :string, default: "ilike", doc: "Flop op for the search filter")
  attr(:search_placeholder, :string, default: "Search…")

  attr(:view, :string,
    default: "table",
    values: ~w(table cards),
    doc: "active view when a :card slot is given"
  )

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

  slot :stat do
    attr(:label, :string)
    attr(:value, :any)
    attr(:href, :string)
    attr(:class, :any)
  end

  slot :tab do
    attr(:label, :string)
    attr(:count, :integer)

    attr(:filters, :list,
      doc:
        ~S|Flop filter preset, e.g. [%{field: "status", value: "pending"}]; omit for the unfiltered tab|
    )
  end

  slot :filter do
    attr(:field, :atom)
    attr(:label, :string)
    attr(:op, :string)
    attr(:options, :list)
    attr(:prompt, :string)
  end

  slot(:card, doc: "per-row card rendering for the cards view; enables the view toggle")

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
      <section
        :if={@stat != []}
        id={"#{@id}-overview"}
        class="lui-dt-overview"
        phx-hook="LanternCollapse"
      >
        <button type="button" class="lui-dt-overview-head" data-part="collapse-toggle">
          <span>Overview</span>
          <Icon.icon name="chevron-down" class="lui-dt-overview-chev" />
        </button>
        <div class="lui-dt-stats" data-part="collapse-body">
          <.link
            :for={stat <- @stat}
            navigate={stat[:href]}
            class={Class.merge(["lui-dt-stat", !stat[:href] && "lui-dt-stat-static", stat[:class]])}
          >
            <span class="lui-dt-stat-label">{stat[:label]}</span>
            <span class="lui-dt-stat-value">
              {if stat[:inner_block], do: render_slot(stat), else: stat[:value]}
            </span>
          </.link>
        </div>
      </section>

      <div :if={@title || @header_action != []} class="lui-dt-header">
        <div :if={@title} class="lui-dt-titles">
          <div class="lui-dt-titlerow">
            <h2 class="lui-dt-title">{@title}</h2>
            <button
              :if={@info_modal_id}
              type="button"
              class="lui-dt-info"
              phx-click={LanternUI.open_dialog(@info_modal_id)}
              aria-label="About this table"
            >
              <Icon.icon name="information-circle" />
            </button>
          </div>
          <p :if={@subtitle} class="lui-dt-subtitle">{@subtitle}</p>
        </div>
        <div class="lui-dt-header-actions">{render_slot(@header_action)}</div>
      </div>

      <div :if={@tab != [] || (@card != [] && @view)} class="lui-dt-tabsrow">
        <Tabs.tabs_list :if={@tab != []} active_tab={active_tab(@tab, @meta)} size="sm">
          <:tab
            :for={{tab, i} <- Enum.with_index(@tab)}
            name={"tab-#{i}"}
            patch={tab_path(@path, @meta, tab[:filters] || [])}
          >
            {tab[:label]}
            <Badge.badge :if={tab[:count]} size="sm" color="neutral">{tab[:count]}</Badge.badge>
          </:tab>
        </Tabs.tabs_list>
        <div :if={@card != []} class="lui-dt-viewtoggle">
          <.link
            patch={view_path(@path, @meta, "table")}
            class={["lui-vt", @view == "table" && "lui-vt-active"]}
            aria-label="Table view"
          >☰</.link>
          <.link
            patch={view_path(@path, @meta, "cards")}
            class={["lui-vt", @view == "cards" && "lui-vt-active"]}
            aria-label="Card view"
          >▦</.link>
        </div>
      </div>

      <div :if={@toolbar != [] || @search_field || @filter != []} class="lui-dt-toolbar">
        <div
          :if={@search_field || @filter != []}
          id={"#{@id}-chrome"}
          class="lui-dt-chrome"
          phx-hook="LanternTableChrome"
          data-path={@path}
          data-params={Jason.encode!(chrome_base_params(@meta))}
        >
          <Dropdown.dropdown :if={@filter != []} id={"#{@id}-filters"} placement="bottom-end">
            <:toggle>
              <Button.button size="sm" variant="outline" type="button">
                <Icon.icon name="funnel" /> Filters
                <Badge.badge :if={active_filter_count(@meta, @filter) > 0} size="sm" color="accent">
                  {active_filter_count(@meta, @filter)}
                </Badge.badge>
              </Button.button>
            </:toggle>
            <Dropdown.dropdown_custom>
              <div class="lui-dt-filterpanel">
                <div :for={filter <- @filter} class="lui-dt-filterrow">
                  <label class="lui-dt-filterlabel">{filter[:label] || to_string(filter[:field])}</label>
                  <div class="lui-select-native-wrap">
                    <select
                      class="lui-select-native"
                      data-part="filter"
                      data-field={filter[:field]}
                      data-op={filter[:op] || "=="}
                      aria-label={filter[:label] || to_string(filter[:field])}
                    >
                      <option value="">{filter[:prompt] || "Any"}</option>
                      <option
                        :for={opt <- filter[:options] || []}
                        value={opt_value(opt)}
                        selected={to_string(opt_value(opt)) == filter_value(@meta, filter[:field])}
                      >
                        {opt_label(opt)}
                      </option>
                    </select>
                    <Icon.icon name="chevron-up-down" class="lui-select-caret" />
                  </div>
                </div>
                <button
                  :if={active_filter_count(@meta, @filter) > 0}
                  type="button"
                  class="lui-dt-clearfilters"
                  data-part="clear-filters"
                >
                  <Icon.icon name="x-mark" /> Clear filters
                </button>
              </div>
            </Dropdown.dropdown_custom>
          </Dropdown.dropdown>

          <div :if={@search_field} class="lui-dt-search">
            <Icon.icon name="magnifying-glass" />
            <input
              type="text"
              placeholder={@search_placeholder}
              value={filter_value(@meta, @search_field)}
              data-part="search"
              data-field={@search_field}
              data-op={@search_op}
              aria-label={@search_placeholder}
            />
          </div>
        </div>
        {render_slot(@toolbar)}
      </div>

      <div :if={@selection_count > 0} class="lui-dt-bulkbar">
        <span class="lui-dt-bulkcount">{@selection_count} selected</span>
        <button
          :if={Map.get(@meta, :total_count) && @selection_count < Map.get(@meta, :total_count)}
          type="button"
          class="lui-dt-selectall"
          phx-click="select_all_matching"
          phx-target={@target}
        >
          Select all {Map.get(@meta, :total_count)}
        </button>
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

      <div :if={@card != [] && @view == "cards"} class="lui-dt-cards">
        <%= if @rows == [] do %>
          <EmptyState.empty_state icon="inbox" title="Nothing here yet" />
        <% else %>
          <div :for={row <- @rows} class="lui-dt-card">{render_slot(@card, row)}</div>
        <% end %>
      </div>

      <div :if={@card == [] || @view == "table"} class="lui-table-wrap">
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

  # ── Chrome helpers ────────────────────────────────────────────────────────

  # Params the client-side chrome hook layers filters onto: everything except
  # filters and page (a filter change resets to page 1).
  defp chrome_base_params(meta) do
    base_params(meta) |> Map.drop(["filters", "page"])
  end

  defp filter_value(meta, field) do
    field_s = to_string(field)

    base_params(meta)
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.find_value("", fn f -> f["field"] == field_s && to_string(f["value"] || "") end)
  end

  defp normalize_filters(filters) when is_map(filters), do: Map.values(filters)
  defp normalize_filters(filters) when is_list(filters), do: filters
  defp normalize_filters(_), do: []

  # A tab is active when its filter preset matches the current filters exactly
  # (both normalized to field=>value); the presetless tab is active otherwise
  # when no filters are applied.
  defp active_tab(tabs, meta) do
    current =
      base_params(meta)
      |> Map.get("filters", %{})
      |> normalize_filters()
      |> Map.new(fn f -> {to_string(f["field"]), to_string(f["value"] || "")} end)

    idx =
      Enum.find_index(tabs, fn tab ->
        preset =
          (tab[:filters] || [])
          |> Enum.map(&normalize_preset/1)
          |> Map.new(fn f -> {f.field, f.value} end)

        preset == current
      end)

    if idx, do: "tab-#{idx}"
  end

  defp normalize_preset(%{} = f) do
    %{
      field: to_string(f[:field] || f["field"]),
      value: to_string(f[:value] || f["value"] || ""),
      op: f[:op] || f["op"]
    }
  end

  defp tab_path(path, meta, preset) do
    filters =
      preset
      |> Enum.map(&normalize_preset/1)
      |> Enum.with_index()
      |> Map.new(fn {f, i} ->
        base = %{"field" => f.field, "value" => f.value}
        {to_string(i), if(f.op, do: Map.put(base, "op", f.op), else: base)}
      end)

    params =
      base_params(meta)
      |> Map.delete("page")
      |> then(fn p ->
        if filters == %{}, do: Map.delete(p, "filters"), else: Map.put(p, "filters", filters)
      end)

    path <> "?" <> Plug.Conn.Query.encode(params)
  end

  defp view_path(path, meta, view) do
    params = base_params(meta) |> Map.put("view", view)
    path <> "?" <> Plug.Conn.Query.encode(params)
  end

  defp active_filter_count(meta, filter_slots) do
    fields = MapSet.new(filter_slots, &to_string(&1[:field]))

    base_params(meta)
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.count(fn f -> to_string(f["field"]) in fields and f["value"] not in [nil, ""] end)
  end

  defp opt_value({_label, value}), do: value
  defp opt_value(value), do: value
  defp opt_label({label, _value}), do: label
  defp opt_label(value), do: to_string(value)
end
