defmodule LanternUI.DataTableChromeTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.DataTable

  @meta %{
    flop: %{page_size: 25},
    params: %{
      "filters" => %{"0" => %{"field" => "status", "value" => "pending"}},
      "order_by" => ["name"]
    },
    current_page: 1,
    total_pages: 2,
    page_size: 25,
    total_count: 30
  }

  defp render(fun, assigns) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp table(assigns) do
    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      search_field={:search}
      search_placeholder="Search orders…"
      view={@view}
    >
      <:stat label="Revenue" value="$12k" href="/rev" />
      <:stat label="Open" value="18" />
      <:tab label="All" count={30} />
      <:tab label="Pending" count={12} filters={[%{field: "status", value: "pending"}]} />
      <:filter field={:channel} label="Channel" options={[{"eBay", "ebay"}]} />
      <:col :let={r} label="Name" field={:name}>{r.name}</:col>
      <:card :let={r}>CARD-{r.name}</:card>
    </DataTable.data_table>
    """
  end

  # Same table, but declaring a :list_item slot as converted index pages do.
  defp table_with_list(assigns) do
    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      search_field={:search}
      view={@view}
    >
      <:col :let={r} label="Name" field={:name}>{r.name}</:col>
      <:card :let={r}>CARD-{r.name}</:card>
      <:list_item :let={r}>LIST-{r.name}</:list_item>
    </DataTable.data_table>
    """
  end

  # An index that offers a list but no grid — admin organizations' shape.
  defp table_list_only(assigns) do
    ~H"""
    <DataTable.data_table id="t" rows={@rows} meta={@meta} path="/orders" view={@view}>
      <:col :let={r} label="Name" field={:name}>{r.name}</:col>
      <:list_item :let={r}>LIST-{r.name}</:list_item>
    </DataTable.data_table>
    """
  end

  defp base, do: %{rows: [%{id: 1, name: "Ada"}], meta: @meta, view: "table"}

  test "stat overview renders with collapse hook and linked/static stats" do
    html = render(&table/1, base())

    assert html =~ ~s(phx-hook="LanternCollapse")
    assert html =~ ~s(data-part="collapse-toggle")
    assert html =~ "Revenue"
    assert html =~ "$12k"
    assert html =~ ~s(href="/rev")
    assert html =~ "lui-dt-stat-static"
  end

  test "tabs render with counts; preset matching current filters is active" do
    html = render(&table/1, base())

    assert html =~ "lui-tab-active"
    # the Pending tab (matches current filters) is active, not All
    assert html =~ ~r/lui-tab-active[^>]*>\s*Pending/s
    # All tab drops filters entirely
    assert html =~ ~r/href="\/orders\?[^"]*order_by/
    refute html =~ ~r/lui-tab-active[^>]*>\s*All\b/s
    # tab counts as badges
    assert html =~ ~r/lui-badge[^>]*>\s*30\s*</
    assert html =~ ~r/lui-badge[^>]*>\s*12\s*</
  end

  test "search + filter chrome renders with hook, base params, current values" do
    html = render(&table/1, base())

    assert html =~ ~s(phx-hook="LanternTableChrome")
    assert html =~ ~s(data-path="/orders")
    # base params exclude filters and page but keep order_by
    assert html =~ "order_by"
    refute html =~ ~r/data-params="[^"]*filters/
    assert html =~ ~s(placeholder="Search orders…")
    assert html =~ ~s(data-field="search")
    assert html =~ ~s(data-field="channel")
    assert html =~ "eBay"
  end

  test "search input carries the current filter value" do
    meta = put_in(@meta.params["filters"], %{"0" => %{"field" => "search", "value" => "char"}})
    html = render(&table/1, %{base() | meta: meta})
    assert html =~ ~s(value="char")
  end

  test "cards view renders :card slot instead of the table" do
    html = render(&table/1, %{base() | view: "cards"})
    assert html =~ "CARD-Ada"
    refute html =~ "lui-table-wrap"
    # view toggle present with a patch link carrying the view param
    assert html =~ "view=cards"
    assert html =~ "lui-vt-active"
  end

  test "the view switcher offers exactly two views, never three" do
    # This fixture declares only a :card slot, so the grid's counterpart is the
    # table — otherwise the grid is a dead end with no way back.
    html = render(&table/1, %{base() | view: "cards"})

    assert html =~ ~s(aria-label="Grid view")
    assert html =~ ~s(aria-label="Table view")
    refute html =~ ~s(aria-label="List view")
    assert count(html, ~s(class="lui-vt)) == 2
  end

  test "a page with a :list_item slot pairs list with grid and drops table" do
    html = render(&table_with_list/1, %{base() | view: "list"})

    assert html =~ ~s(aria-label="List view")
    assert html =~ ~s(aria-label="Grid view")
    refute html =~ ~s(aria-label="Table view")
    refute html =~ "view=table"
    assert count(html, ~s(class="lui-vt)) == 2
  end

  test "search and filter chrome carries the active view" do
    # The chrome hook rebuilds the URL from data-params on every search, so a
    # missing view here silently bounces the user back to the default view.
    html = render(&table/1, %{base() | view: "cards"})
    assert html =~ ~s(&quot;view&quot;:&quot;cards&quot;)
  end

  test "a page with only a :list_item slot pairs list with table, not one button" do
    html = render(&table_list_only/1, %{base() | view: "list"})

    assert html =~ ~s(aria-label="List view")
    assert html =~ ~s(aria-label="Table view")
    refute html =~ ~s(aria-label="Grid view")
    assert count(html, ~s(class="lui-vt)) == 2
  end

  defp count(h, n), do: length(String.split(h, n)) - 1

  test "filters live in the settings popover with active-count badge and clear button" do
    html = render(&table/1, base())

    # settings popover wraps the filter controls
    assert html =~ ~s(id="t-filters")
    assert html =~ ~s(aria-label="Table settings")
    assert html =~ "lui-dt-filterpanel"
    # status filter is active in @meta but channel (the declared filter) is not,
    # so no badge and no clear button
    refute html =~ "lui-dt-clearfilters"

    meta = put_in(@meta.params["filters"], %{"0" => %{"field" => "channel", "value" => "ebay"}})
    html = render(&table/1, %{base() | meta: meta})
    assert html =~ ~r/lui-badge[^>]*>\s*1\s*</
    assert html =~ ~s(data-part="clear-filters")
  end

  test "multiple/searchable filter renders a rich select with in-op wrapper" do
    assigns = %{__changed__: nil}

    html =
      (fn a ->
         ~H"""
         <DataTable.data_table
           id="t"
           rows={[]}
           meta={
             %{
               current_page: 1,
               total_pages: 1,
               params: %{
                 "filters" => %{
                   "0" => %{"field" => "channel", "op" => "in", "value" => ["eBay", "Direct"]}
                 }
               }
             }
           }
           path="/x"
         >
           <:filter field={:channel} multiple searchable options={["eBay", "Shopify", "Direct"]} />
           <:col :let={r} label="Name">{r}</:col>
         </DataTable.data_table>
         """
       end).(assigns)
      |> rendered_to_string()

    assert html =~ ~s(data-part="filter-rich")
    assert html =~ ~s(data-op="in")
    assert html =~ ~s(data-part="search-input")
    # both current values marked selected on the hidden native <select>
    assert html =~ ~s(<option value="eBay" selected>)
    assert html =~ ~s(<option value="Direct" selected>)
    assert html =~ "2 selected"
  end

  test "chrome row orders: tabs, search, then settings popover (rightmost)" do
    html = render(&table/1, base())
    {tabs, _} = :binary.match(html, "lui-tabs-list")
    {search, _} = :binary.match(html, ~s(data-part="search"))
    {settings, _} = :binary.match(html, ~s(id="t-filters"))
    assert tabs < search
    assert search < settings
  end

  test "card shell wraps everything; typed filters render text and range controls" do
    assigns = %{__changed__: nil}

    html =
      (fn a ->
         ~H"""
         <DataTable.data_table
           id="t"
           rows={[]}
           meta={%{current_page: 1, total_pages: 1, params: %{}}}
           path="/x"
         >
           <:filter field={:buyer} type={:text} label="Buyer" />
           <:filter field={:total} type={:range} label="Total" />
           <:col :let={r} label="Name">{r}</:col>
         </DataTable.data_table>
         """
       end).(assigns)
      |> rendered_to_string()

    assert html =~ ~s(class="lui-datatable")
    assert html =~ ~s(data-field="buyer")
    assert html =~ ~s(data-op="ilike")
    assert html =~ ~s(placeholder="Min")
    assert html =~ ~s(placeholder="Max")
    assert html =~ ~s(data-op=">=")
    assert html =~ ~s(data-op="<=")
  end

  test "bulk bar offers select-all-matching when not everything is selected" do
    html =
      render(&table/1, %{rows: [%{id: 1, name: "Ada"}], meta: @meta, view: "table"})
      |> then(fn _ -> render_with_selection() end)

    assert html =~ ~s(phx-click="select_all_matching")
    assert html =~ "Select all 30"
  end

  defp render_with_selection do
    assigns = %{__changed__: nil, rows: [%{id: 1, name: "Ada"}], meta: @meta, view: "table"}

    fn a ->
      ~H"""
      <DataTable.data_table
        id="t"
        rows={a.rows}
        meta={a.meta}
        path="/orders"
        selected_ids={MapSet.new([1])}
      >
        <:col :let={r} label="Name">{r.name}</:col>
        <:bulk_action label="Archive" event="bulk-archive" />
      </DataTable.data_table>
      """
    end
    |> then(& &1.(assigns))
    |> rendered_to_string()
  end

  test "title section renders subtitle and info button opening the modal" do
    assigns = %{__changed__: nil}

    html =
      (fn a ->
         ~H"""
         <DataTable.data_table
           id="t"
           rows={[]}
           meta={%{current_page: 1, total_pages: 1}}
           path="/x"
           title="Orders"
           subtitle="All channels, last 90 days"
           info_modal_id="orders-info"
         >
           <:col :let={r} label="Name">{r}</:col>
         </DataTable.data_table>
         """
       end).(assigns)
      |> rendered_to_string()

    assert html =~ "Orders"
    assert html =~ "All channels, last 90 days"
    assert html =~ ~s(aria-label="About this table")
    assert html =~ "lantern:dialog:open"
    assert html =~ "orders-info"
  end

  test "table view renders the table and the toggle" do
    html = render(&table/1, base())
    assert html =~ "lui-table-wrap"
    refute html =~ "CARD-Ada"
    assert html =~ "view=cards"
  end
end
