defmodule LanternUI.MatrixTableTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  use LanternUI, only: [:matrix_table, :table, :topology_svg]

  defp render_matrix(assigns) do
    ~H"""
    <.matrix_table caption="Environments across components" corner="Environment">
      <:col kind="app">web</:col>
      <:col kind="database">primary</:col>
      <.matrix_row label="main" navigate="/e/main">
        <:meta>production</:meta>
        <.matrix_cell state="present" label="Ready" navigate="/apps/1" />
        <.matrix_cell state="in_rule" navigate="/e/main" />
      </.matrix_row>
      <.matrix_row label="staging" depth={1}>
        <.matrix_cell state="degraded" navigate="/apps/2" />
        <.matrix_cell state="failed" label="Deploy failed" />
      </.matrix_row>
      <.matrix_row label="dev/maya" depth={2}>
        <.matrix_cell
          state="absent"
          add_label="Add web to dev/maya"
          phx-click="add"
          phx-value-c="web"
        />
        <.matrix_cell state="absent" />
      </.matrix_row>
      <.table_placeholder_row colspan={3} icon="chevron-down" label="3 previews" phx-click="more" />
    </.matrix_table>
    """
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  setup do
    %{doc: render_matrix(%{})}
  end

  test "table semantics: caption, column and row headers", %{doc: doc} do
    assert Floki.text(Floki.find(doc, "caption.lui-sr-only")) == "Environments across components"

    assert Floki.find(doc, "thead th[scope=col]") |> length() == 3
    assert Floki.text(Floki.find(doc, "th .lui-matrix-col")) == "webprimary"
    assert Floki.text(Floki.find(doc, "th .lui-matrix-kind")) == "appdatabase"

    rows = Floki.find(doc, "tbody th[scope=row]")
    assert length(rows) == 3

    assert Floki.attribute(doc, "tbody th[scope=row]", "class")
           |> Enum.all?(&(&1 =~ "lui-matrix-head"))

    assert Floki.attribute(doc, "tbody tr", "data-depth") |> Enum.take(3) == ["0", "1", "2"]

    assert Floki.attribute(doc, "tbody th[scope=row]", "style") |> Enum.at(2) =~
             "--lui-matrix-depth: 2"
  end

  test "row head links when a target is given and shows the meta line", %{doc: doc} do
    assert [_] = Floki.find(doc, "th[scope=row] a.lui-matrix-name[href='/e/main']")
    assert Floki.text(Floki.find(doc, ".lui-matrix-meta")) =~ "production"
    assert Floki.find(doc, "th[scope=row] span.lui-matrix-name") |> length() == 2
  end

  test "every state has a dot and words, not colour alone", %{doc: doc} do
    states = Floki.attribute(doc, "td.lui-matrix-cell", "data-state")
    assert states == ~w(present in_rule degraded failed absent absent)

    text = fn n ->
      doc
      |> Floki.find("td.lui-matrix-cell")
      |> Enum.at(n)
      |> Floki.text()
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    end

    assert text.(0) == "Ready, present"
    assert text.(1) == "In rule"
    assert text.(2) == "Degraded"
    assert text.(3) == "Deploy failed, failed"
    assert text.(5) == "Absent"
    assert Floki.attribute(doc, ".lui-matrix-dot", "aria-hidden") |> Enum.uniq() == ["true"]
  end

  test "a cell is a link or an add button, never nested controls", %{doc: doc} do
    assert Floki.find(doc, "td a a, td a button, td button a, td button button") == []
    assert [_, _, _] = Floki.find(doc, "td a.lui-matrix-state")
    assert [button] = Floki.find(doc, "td.lui-matrix-cell button")
    assert Floki.attribute(button, "aria-label") == ["Add web to dev/maya"]
    assert Floki.attribute(button, "phx-click") == ["add"]
    assert Floki.attribute(button, "phx-value-c") == ["web"]
    # Absent without add_label has no control at all.
    assert Floki.find(
             doc,
             "td[data-state=absent]:last-child button, td[data-state=absent]:last-child a"
           ) == []
  end

  test "overflow is a real placeholder button spanning the grid", %{doc: doc} do
    assert [row] = Floki.find(doc, "tr[data-placeholder]")
    assert Floki.attribute(row, "td", "colspan") == ["3"]
    assert [_] = Floki.find(row, "button[aria-label='3 previews'], button")
  end

  test "unknown state fails loudly" do
    assigns = %{}

    assert_raise KeyError, fn ->
      rendered_to_string(~H"""
      <.matrix_table caption="x">
        <:col>a</:col>
        <.matrix_row label="r"><.matrix_cell state="bogus" /></.matrix_row>
      </.matrix_table>
      """)
    end
  end

  test "select_event turns row heads, cells and column heads into select buttons with a shared selection" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.matrix_table caption="c" corner="Env">
        <:col select_event="pick_col" select_values={%{ref: "app:1"}} selected>web</:col>
        <.matrix_row label="staging" selected select_event="pick_env" select_values={%{id: "7"}}>
          <.matrix_cell
            state="present"
            selected
            col_selected
            select_event="pick_cell"
            select_values={%{env: "7", ref: "app:1"}}
          />
        </.matrix_row>
      </.matrix_table>
      """)

    assert html =~ ~s(phx-click="pick_env")
    assert html =~ ~s(phx-value-id="7")
    assert html =~ ~s(phx-click="pick_cell")
    assert html =~ ~s(phx-value-ref="app:1")
    assert html =~ ~s(aria-current="true")
    assert html =~ "data-col-selected"
    refute html =~ "<a "
  end

  test "nested rows draw tree guides: one per ancestor level plus an elbow" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.matrix_table caption="c" corner="Env">
        <:col>web</:col>
        <.matrix_row label="dev" depth={2} trail={[true]} last>
          <.matrix_cell state="absent" />
        </.matrix_row>
      </.matrix_table>
      """)

    assert html =~ "lui-matrix-guide"
    assert html =~ "data-on"
    assert html =~ ~r/lui-matrix-elbow"[^>]*data-last/
  end

  test "topology edge labels sit on an opaque chip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.topology_svg
        id="t"
        label="g"
        on_select="pick"
        nodes={[%{id: "a", label: "a"}, %{id: "b", label: "b", column: 1}]}
        edges={[%{from: "a", to: "b", label: "API_URL"}]}
      />
      """)

    assert html =~ "lui-topology-edge-chip"
  end
end
