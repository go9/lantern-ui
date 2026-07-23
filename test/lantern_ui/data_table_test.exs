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

    assert html =~ ~s(<div class="lui-dt-stats" data-part="collapse-body">)
    refute html =~ "lui-stat-grid"
    assert html =~ "lui-dt-stat-icon"
    assert html =~ "hero-check-circle"
    assert html =~ "lui-dt-stat-sub"
    assert html =~ "Last 24 hours"
    assert html =~ ">Total<"
    assert html =~ "42"
    assert html =~ ~s(href="/orders/linked")
    assert html =~ ~s(class="lui-dt-stat custom-stat")
    assert html =~ "custom value"
  end

  test "meta without flop/params still works (plain maps)" do
    meta = %{current_page: 1, total_pages: 1, page_size: nil, total_count: 0}

    html =
      render(&table/1, %{rows: [], meta: meta, selected: MapSet.new()})

    assert html =~ "lui-datatable"
    assert DataTable.sort_path("/x", meta, :name) =~ "order_by[]=name"
  end
end
