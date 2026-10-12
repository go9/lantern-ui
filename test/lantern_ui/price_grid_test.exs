defmodule LanternUI.PriceGridTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.PriceGrid

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  test "price_cell renders a pressed-state button with label and price" do
    html =
      render(fn assigns ->
        ~H"""
        <PriceGrid.price_cell label="NM" price="$42" selected phx-click="pick" phx-value-id="1" />
        """
      end)

    assert html =~ ~s(type="button")
    assert html =~ ~s(class="lui-price-cell")
    assert html =~ ~s(aria-pressed="true")
    assert html =~ ~s(data-selected="true")
    assert html =~ ~s(phx-click="pick")
    assert html =~ ~s(phx-value-id="1")
    assert html =~ "NM"
    assert html =~ "$42"
  end

  test "an unpriced cell shows an em dash; show_price=false hides the price line" do
    html = render(fn assigns -> ~H|<PriceGrid.price_cell label="LP" />| end)
    assert html =~ ~s(aria-pressed="false")
    refute html =~ "data-selected"
    assert html =~ "—"

    html =
      render(fn assigns -> ~H|<PriceGrid.price_cell label="Standard" show_price={false} />| end)

    refute html =~ "lui-price-cell-price"
  end

  test "price_cell_group captions and names its row" do
    html =
      render(fn assigns ->
        ~H"""
        <PriceGrid.price_cell_group label="Raw">
          <PriceGrid.price_cell label="NM" price="$42" />
        </PriceGrid.price_cell_group>
        """
      end)

    assert html =~ ~s(class="lui-price-caption")
    assert html =~ ~s(role="group" aria-label="Raw")
  end

  test "price_grid renders headers, cells with row/column values, selection and empty slots" do
    assigns = %{
      rows: [%{key: "psa", label: "PSA"}, %{key: "cgc", label: "CGC"}],
      columns: [%{key: "10", label: "10"}, %{key: "9", label: "9"}],
      cells: %{
        {"psa", "10"} => %{price: "$410"},
        {"psa", "9"} => %{price: "$120"},
        {"cgc", "10"} => %{price: "$300"}
      }
    }

    html =
      render(
        fn assigns ->
          ~H"""
          <PriceGrid.price_grid
            label="Graded"
            rows={@rows}
            columns={@columns}
            cells={@cells}
            selected={{"psa", "10"}}
            on_pick="pick_grade"
          />
          """
        end,
        assigns
      )

    assert html =~ ~s(<table class="lui-price-grid" aria-label="Graded">)
    assert html =~ ~s(<th scope="col">10</th>)
    assert html =~ ~s(<th scope="row">PSA</th>)
    assert html =~ ~s(phx-value-row="psa")
    assert html =~ ~s(phx-value-column="10")
    assert html =~ "$410"
    assert length(Regex.scan(~r/aria-pressed="true"/, html)) == 1
    # cgc / 9 has no price point: an empty slot, no button.
    assert length(Regex.scan(~r/<button/, html)) == 3
  end
end
