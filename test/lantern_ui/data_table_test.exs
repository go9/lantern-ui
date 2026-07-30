defmodule LanternUI.DataTableTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.DataTable

  @meta %{
    flop: %{page_size: 25, order_by: [:name], order_directions: [:asc]},
    params: %{"filters" => %{"0" => %{"field" => "status", "value" => "active"}}},
    current_page: 2,
    total_pages: 4,
    page_size: 25,
    total_count: 100
  }

  defp render(fun, assigns) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  defp rows, do: [%{id: 1, name: "Ada"}, %{id: 2, name: "Alan"}]

  defp table(assigns) do
    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      selected_ids={@selected}
      title="Orders"
    >
      <:col :let={r} label="Name" field={:name} sortable>{r.name}</:col>
      <:col :let={r} label="ID">{r.id}</:col>
      <:bulk_action label="Delete" icon="trash" event="bulk-delete" color="danger" />
      <:row_action :let={r}>ACT-{r.id}</:row_action>
      <:empty>NOTHING</:empty>
    </DataTable.data_table>
    """
  end

  test "renders title, sortable header, rows, row actions, pagination" do
    html = render(&table/1, %{rows: rows(), meta: @meta, selected: MapSet.new()})

    assert html =~ "Orders"
    # sortable header toggles :name asc -> desc, keeps filters, drops page
    assert html =~ "order_directions[]=desc"
    assert html =~ "filters[0][field]=status"
    refute html =~ ~r/lui-th-sort[^>]*href="[^"]*page=/
    # sort indicator on the active column
    assert html =~ "↑"
    assert html =~ "Ada"
    assert html =~ "ACT-1"
    # pagination present with meta paging
    assert html =~ "100 results"
    assert html =~ "page=3"
  end

  test "fill mode adds lui-datatable-fill; default does not" do
    off = render(&table/1, %{rows: rows(), meta: @meta, selected: MapSet.new()})
    refute off =~ "lui-datatable-fill"

    on =
      render(
        fn assigns ->
          ~H"""
          <DataTable.data_table id="t" fill rows={@rows} meta={@meta} path="/o" selected_ids={@selected}>
            <:col :let={r} label="Name">{r.name}</:col>
          </DataTable.data_table>
          """
        end,
        %{rows: rows(), meta: @meta, selected: MapSet.new()}
      )

    assert on =~ "lui-datatable-fill"
  end

  test "selection: checkboxes, selected row class, bulk bar + events" do
    html = render(&table/1, %{rows: rows(), meta: @meta, selected: MapSet.new([1])})

    assert html =~ ~s(phx-click="toggle_select")
    assert html =~ ~s(phx-value-id="1")
    assert html =~ ~s(phx-click="select_all_page")
    assert html =~ "lui-tr-selected"
    assert html =~ "1 selected"
    assert html =~ ~s(phx-click="bulk-delete")
    assert html =~ ~s(phx-click="clear_selection")
  end

  test "no bulk bar when nothing selected" do
    html = render(&table/1, %{rows: rows(), meta: @meta, selected: MapSet.new()})
    refute html =~ "lui-dt-bulkbar"
  end

  test "empty slot renders across full colspan" do
    html = render(&table/1, %{rows: [], meta: @meta, selected: MapSet.new()})
    assert html =~ "NOTHING"
    # 2 cols + checkbox + row_action = 4
    assert html =~ ~s(colspan="4")
  end

  test "sort_path toggles and resets direction" do
    assert DataTable.sort_path("/x", @meta, :name) =~ "order_directions[]=desc"
    assert DataTable.sort_path("/x", @meta, :other) =~ "order_directions[]=asc"
    assert DataTable.sort_path("/x", @meta, :other) =~ "order_by[]=other"
  end

  test "page_path preserves filters and page_size" do
    path = DataTable.page_path("/x", @meta, %{page: 3})
    assert path =~ "page=3"
    assert path =~ "page_size=25"
    assert path =~ "filters[0][value]=active"
  end

  defp stat_table(assigns) do
    ~H"""
    <DataTable.data_table id="s" rows={@rows} meta={@meta} path="/orders" selected_ids={@selected}>
      <:stat label="Total" value="42" icon="hero-check-circle" subtitle="Last 24 hours" />
      <:stat label="Linked" href="/orders/linked" class="custom-stat">{@linked_value}</:stat>
      <:col :let={r} label="Name">{r.name}</:col>
    </DataTable.data_table>
    """
  end

  test "stat slot preserves its DOM, appearance classes, attributes, and inner content" do
    html =
      render(&stat_table/1, %{
        rows: rows(),
        meta: @meta,
        selected: MapSet.new(),
        linked_value: "custom value"
      })

    assert Floki.find(Floki.parse_fragment!(html), ".lui-dt-stats") == [
             {"div", [{"class", "lui-dt-stats"}, {"data-part", "collapse-body"}],
              [
                {"div", [{"class", "lui-dt-stat lui-dt-stat-static"}],
                 [
                   {"div", [{"class", "lui-dt-stat-head"}],
                    [
                      {"span", [{"class", "lui-dt-stat-label"}], ["Total"]},
                      {"span",
                       [
                         {"class", "lui-dt-stat-icon hero-check-circle"},
                         {"aria-hidden", "true"}
                       ], []}
                    ]},
                   {"span", [{"class", "lui-dt-stat-value"}], ["42"]},
                   {"span", [{"class", "lui-dt-stat-sub"}], ["Last 24 hours"]}
                 ]},
                {"a",
                 [
                   {"href", "/orders/linked"},
                   {"data-phx-link", "redirect"},
                   {"data-phx-link-state", "push"},
                   {"class", "lui-dt-stat custom-stat"}
                 ],
                 [
                   {"div", [{"class", "lui-dt-stat-head"}],
                    [{"span", [{"class", "lui-dt-stat-label"}], ["Linked"]}]},
                   {"span", [{"class", "lui-dt-stat-value"}], ["custom value"]}
                 ]}
              ]}
           ]
  end

  test "meta without flop/params still works (plain maps)" do
    meta = %{current_page: 1, total_pages: 1, page_size: nil, total_count: 0}

    html =
      render(&table/1, %{rows: [], meta: meta, selected: MapSet.new()})

    assert html =~ "lui-datatable"
    assert DataTable.sort_path("/x", meta, :name) =~ "order_by[]=name"
  end

  # Frozen baseline for the no-:list_item path. Captured from the pre-list-view
  # markup so additive list work cannot change default table rendering.
  @baseline_meta %{
    flop: %{page_size: 25, order_by: [:name], order_directions: [:asc]},
    params: %{},
    current_page: 1,
    total_pages: 1,
    page_size: 25,
    total_count: 2
  }

  defp baseline_table(assigns) do
    ~H"""
    <DataTable.data_table
      id="baseline"
      rows={@rows}
      meta={@meta}
      path="/orders"
      selected_ids={@selected}
      show_checkboxes={false}
    >
      <:col :let={r} label="Name" field={:name} sortable>{r.name}</:col>
      <:col :let={r} label="ID">{r.id}</:col>
      <:row_action :let={r}>ACT-{r.id}</:row_action>
    </DataTable.data_table>
    """
  end

  # Whitespace-normalized freeze of the default table body. Captured from the
  # pre-list-view path; any change to headers/rows/actions without :list_item
  # fails this test.
  @baseline_table_html """
  <table class="lui-table"><thead class="lui-thead"><tr><th class="lui-th" scope="col"><a href="/orders?order_by[]=name&amp;order_directions[]=desc" data-phx-link="patch" data-phx-link-state="push" class="lui-th-sort">Name<span class="lui-th-sort-icon">↑</span></a></th><th class="lui-th" scope="col"><span>ID</span></th><th class="lui-th lui-th-actions" scope="col"></th></tr></thead><tbody class="lui-tbody"><tr class="lui-tr"><td class="lui-td">Ada</td><td class="lui-td">1</td><td class="lui-td lui-td-actions">ACT-1</td></tr><tr class="lui-tr"><td class="lui-td">Alan</td><td class="lui-td">2</td><td class="lui-td lui-td-actions">ACT-2</td></tr></tbody></table>
  """

  defp squash_html(html) do
    html
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r" (?=<)", "")
    |> String.replace(~r"(?<=>) ", "")
    |> String.trim()
  end

  test "without :list_item the table path is unchanged (baseline freeze)" do
    html =
      render(&baseline_table/1, %{
        rows: rows(),
        meta: @baseline_meta,
        selected: MapSet.new()
      })

    # No list chrome or list body
    refute html =~ "lui-dt-list"
    refute html =~ "List view"
    refute html =~ "view=list"
    refute html =~ "lui-dt-viewtoggle"

    # Classic table chrome only
    assert html =~ ~s(class="lui-table-wrap")
    assert html =~ ~s(class="lui-thead")
    assert html =~ ~s(class="lui-tbody")
    assert html =~ "Ada"
    assert html =~ "ACT-1"
    assert html =~ "ACT-2"

    # Byte-identical freeze of the table markup (whitespace-normalized so HEEx
    # indentation noise does not mask real structure changes).
    [_, table_inner] = Regex.run(~r/<table class="lui-table">(.*?)<\/table>/s, html)
    table = squash_html(~s(<table class="lui-table">#{table_inner}</table>))
    assert table == squash_html(@baseline_table_html)
  end

  defp list_table(assigns) do
    ~H"""
    <DataTable.data_table
      id="list"
      rows={@rows}
      meta={@meta}
      path="/orders"
      selected_ids={@selected}
      view={@view}
      search_field={:search}
    >
      <:col :let={r} label="Name">{r.name}</:col>
      <:list_item :let={r}>
        <span class="name">{r.name}</span>
      </:list_item>
      <:row_action :let={r}>
        <button type="button" phx-click="delete" phx-value-id={r.id}>Del-{r.id}</button>
      </:row_action>
      <:empty>NOTHING</:empty>
    </DataTable.data_table>
    """
  end

  test "view=list with :list_item renders lui-dt-list and no thead" do
    html =
      render(&list_table/1, %{
        rows: rows(),
        meta: @meta,
        selected: MapSet.new(),
        view: "list"
      })

    assert html =~ "lui-dt-list"
    assert html =~ "lui-dt-list-row"
    assert html =~ ~s(class="name")
    assert html =~ "Ada"
    assert html =~ "Alan"
    refute html =~ "lui-thead"
    refute html =~ "lui-table-wrap"
    refute html =~ "lui-dt-cards"
    # toolbar chrome still present in list view
    assert html =~ "lui-dt-search"
    assert html =~ "lui-dt-pagination"
  end

  test ":row_action content still renders in list view" do
    html =
      render(&list_table/1, %{
        rows: rows(),
        meta: @meta,
        selected: MapSet.new(),
        view: "list"
      })

    assert html =~ "lui-dt-list-actions"
    assert html =~ "Del-1"
    assert html =~ "Del-2"
    assert html =~ ~s(phx-click="delete")
    # actions sit in their own container, not nested under a row-level anchor
    refute html =~ ~r/lui-dt-list-row[^>]*>\s*<a/
  end

  test "list toggle is absent when no :list_item is given" do
    html = render(&table/1, %{rows: rows(), meta: @meta, selected: MapSet.new()})
    refute html =~ "List view"
    refute html =~ "view=list"
    refute html =~ "lui-dt-viewtoggle"
  end

  test "list toggle appears only when :list_item is given" do
    html =
      render(&list_table/1, %{
        rows: rows(),
        meta: @meta,
        selected: MapSet.new(),
        view: "table"
      })

    assert html =~ "lui-dt-viewtoggle"
    assert html =~ ~s(aria-label="List view")
    assert html =~ "view=list"
    # cards toggle stays absent without :card
    refute html =~ ~s(aria-label="Card view")
  end

  test "exactly one view renders at a time" do
    base = %{rows: rows(), meta: @meta, selected: MapSet.new()}

    list_html = render(&list_table/1, Map.put(base, :view, "list"))
    assert list_html =~ "lui-dt-list"
    refute list_html =~ "lui-table-wrap"
    refute list_html =~ "lui-dt-cards"

    table_html = render(&list_table/1, Map.put(base, :view, "table"))
    assert table_html =~ "lui-table-wrap"
    refute table_html =~ "lui-dt-list"
    refute table_html =~ "lui-dt-cards"

    both =
      render(
        fn assigns ->
          ~H"""
          <DataTable.data_table
            id="both"
            rows={@rows}
            meta={@meta}
            path="/orders"
            selected_ids={@selected}
            view={@view}
          >
            <:col :let={r} label="Name">{r.name}</:col>
            <:card :let={r}>CARD-{r.name}</:card>
            <:list_item :let={r}>LIST-{r.name}</:list_item>
          </DataTable.data_table>
          """
        end,
        Map.put(base, :view, "cards")
      )

    assert both =~ "CARD-Ada"
    assert both =~ "lui-dt-cards"
    refute both =~ "lui-dt-list"
    refute both =~ "lui-table-wrap"
    refute both =~ "LIST-Ada"
  end
end
