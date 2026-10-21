defmodule LanternUI.DataTableBandsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias LanternUI.Components.DataTable

  @rows [%{id: 1, name: "Ada"}, %{id: 2, name: "Zoe"}]
  @meta %{
    params: %{
      "view" => "cards",
      "page" => "2",
      "search" => "Ada",
      "order_by" => ["name"],
      "order_directions" => ["desc"]
    }
  }

  defp table(assigns) do
    ~H"""
    <DataTable.data_table
      id="bands"
      group={@groups}
      meta={@meta}
      path="/projects"
      active_view={@view}
      selected_ids={[1]}
      show_checkboxes
      pagination={false}
    >
      <:col :let={r} field={:name} label="Project" sortable>{r.name}</:col>
      <:col :let={r} field={:id} label="Tickets" sortable>{r.id}</:col>
      <:col :let={r} label="Plain">{r.id}</:col>
      <:card :let={r}>{r.name}</:card>
      <:row_action :let={r}><button id={"pin-#{r.id}"}>Pin</button></:row_action>
      <:placeholder label="Add project" event="add" />
    </DataTable.data_table>
    """
  end

  defp doc(groups, view \\ "table", meta \\ @meta) do
    table(%{__changed__: nil, groups: groups, meta: meta, view: view})
    |> rendered_to_string()
    |> Floki.parse_document!()
  end

  test "table bands are ordered named rowgroups with full-width headers and preserved row controls" do
    doc = doc([{"Pinned", [hd(@rows)]}, {"Empty", []}, {"All projects", [List.last(@rows)]}])
    assert Floki.attribute(doc, "tbody", "aria-label") == ["Pinned", "All projects"]
    assert Floki.attribute(doc, "tbody", "role") == ["rowgroup", "rowgroup"]
    assert Floki.attribute(doc, "th[scope=rowgroup]", "colspan") == ["5", "5"]

    assert Floki.find(doc, "tbody .lui-tr:not(.lui-tr-placeholder)")
           |> Enum.map(&(Floki.text(&1) |> String.replace(~r/\s+/, ""))) == [
             "Ada11Pin",
             "Zoe22Pin"
           ]

    assert length(Floki.find(doc, "tbody input[checked]")) == 1
    assert length(Floki.find(doc, "#pin-1")) == 1
    assert length(Floki.find(doc, ".lui-tr-placeholder")) == 1
    assert Floki.find(doc, "[data-part=sort]") == []
  end

  test "single populated band hides labels in table and cards; empty bands don't create headers" do
    for view <- ["table", "cards"],
        groups <- [[{"Pinned", @rows}], [{"Pinned", @rows}, {"Empty", []}]] do
      doc = doc(groups, view)
      assert Floki.find(doc, ".lui-dt-band") == []
      assert Floki.find(doc, "[aria-label=Pinned]") == []
      assert length(Floki.find(doc, "#pin-1")) == 1
    end

    assert Floki.find(doc([], "table"), ".lui-dt-band") == []
    assert Floki.text(doc([], "cards")) =~ "Nothing here yet"
  end

  test "card bands are named lists containing listitems in the supplied order" do
    doc = doc([{"Pinned", [List.last(@rows)]}, {"All", [hd(@rows)]}], "cards")
    assert Floki.attribute(doc, "[role=list]", "aria-label") == ["Pinned", "All"]

    assert Floki.find(doc, "[role=listitem]")
           |> Enum.map(&(Floki.text(&1) |> String.replace(~r/\s+/, ""))) == ["ZoePin", "AdaPin"]
  end

  test "non-table sort select and reverse link share header params, preserving view/search and dropping page" do
    doc = doc([{"All", @rows}], "cards")
    assert Floki.attribute(doc, "[data-part=sort] option", "value") == ["name", "id"]
    assert Floki.attribute(doc, "option[selected]", "value") == ["name"]
    [path] = Floki.attribute(doc, "option[value=id]", "data-sort-path")
    params = path |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()

    assert params == %{
             "view" => "cards",
             "search" => "Ada",
             "order_by" => ["id"],
             "order_directions" => ["asc"]
           }

    [reverse] = Floki.attribute(doc, "a[aria-label='Sort ascending']", "href")
    params = reverse |> URI.parse() |> Map.fetch!(:query) |> Plug.Conn.Query.decode()
    assert params["order_by"] == ["name"]
    assert params["order_directions"] == ["asc"]
    refute Map.has_key?(params, "page")
  end

  test "list view gets the same sort control; no sortable columns means no control" do
    assigns = %{__changed__: nil, meta: @meta}

    html =
      (fn assigns ->
         ~H"""
         <DataTable.data_table id="list-sort" rows={[]} meta={@meta} path="/projects" active_view="list">
           <:col field={:name} label="Project" sortable />
           <:list_item :let={row}>{row.name}</:list_item>
         </DataTable.data_table>
         <DataTable.data_table id="no-sort" rows={[]} meta={@meta} path="/projects" active_view="cards">
           <:card :let={row}>{row.name}</:card>
         </DataTable.data_table>
         """
       end).(assigns)
      |> rendered_to_string()
      |> Floki.parse_document!()

    assert length(Floki.find(html, "#list-sort [data-part=sort]")) == 1
    assert Floki.find(html, "#no-sort [data-part=sort]") == []
  end
end
