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
    # view toggle present with patch links carrying view param
    assert html =~ "view=table"
    assert html =~ "lui-vt-active"
  end

  test "table view renders the table and the toggle" do
    html = render(&table/1, base())
    assert html =~ "lui-table-wrap"
    refute html =~ "CARD-Ada"
    assert html =~ "view=cards"
  end
end
