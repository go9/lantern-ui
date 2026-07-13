defmodule LanternUI.TablePrimitivesTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.Badge
  alias LanternUI.Components.Pagination
  alias LanternUI.Components.Select
  alias LanternUI.Components.Table
  alias LanternUI.Components.Tabs

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "badge/1" do
    test "renders color/variant/size data attrs" do
      html =
        render(fn assigns ->
          ~H"""
          <Badge.badge color="success" variant="soft" size="sm">Shipped</Badge.badge>
          """
        end)

      assert html =~ ~s(data-color="success")
      assert html =~ ~s(data-variant="soft")
      assert html =~ ~s(data-size="sm")
      assert html =~ "Shipped"
    end
  end

  describe "table family" do
    test "renders head cols, body rows, selected state" do
      html =
        render(fn assigns ->
          ~H"""
          <Table.table>
            <Table.table_head>
              <:col>Name</:col>
              <:col class="lui-th-num">Total</:col>
            </Table.table_head>
            <Table.table_body>
              <Table.table_row selected>
                <:cell>Ada</:cell>
                <:cell class="lui-td-num">$42</:cell>
              </Table.table_row>
            </Table.table_body>
          </Table.table>
          """
        end)

      assert html =~ ~s(<table class="lui-table")
      assert html =~ ~s(scope="col")
      assert html =~ "lui-th-num"
      assert html =~ "lui-tr-selected"
      assert html =~ "lui-td-num"
      assert html =~ "Ada"
    end
  end

  describe "tabs family" do
    test "active tab gets active class + aria-selected; patch tabs are links" do
      html =
        render(fn assigns ->
          ~H"""
          <Tabs.tabs id="t">
            <Tabs.tabs_list active_tab="all">
              <:tab name="all" patch="/orders?tab=all">All</:tab>
              <:tab name="pending" patch="/orders?tab=pending">Pending</:tab>
            </Tabs.tabs_list>
            <Tabs.tabs_panel name="all" active>CONTENT</Tabs.tabs_panel>
            <Tabs.tabs_panel name="pending" active={false}>HIDDEN</Tabs.tabs_panel>
          </Tabs.tabs>
          """
        end)

      assert html =~ ~s(role="tablist")
      assert html =~ "lui-tab-active"
      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(href="/orders?tab=all")
      assert html =~ "CONTENT"
      refute html =~ "HIDDEN"
    end

    test "click tabs render buttons with phx-value-tab defaulting to name" do
      html =
        render(fn assigns ->
          ~H"""
          <Tabs.tabs_list active_tab="a">
            <:tab name="b" phx-click="set_tab">B</:tab>
          </Tabs.tabs_list>
          """
        end)

      assert html =~ "<button"
      assert html =~ ~s(phx-click="set_tab")
      assert html =~ ~s(phx-value-tab="b")
    end
  end

  describe "select/1" do
    test "rich path: hidden input, toggle, listbox options, selected label" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select
            id="ch"
            name="channel"
            value="ebay"
            label="Channel"
            options={[{"eBay", "ebay"}, {"Shopify", "shopify"}]}
          />
          """
        end)

      assert html =~ ~s(phx-hook="LanternSelect")
      assert html =~ ~s(type="hidden" name="channel" value="ebay")
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(data-value="shopify")
      # selected option label shows in the toggle
      assert html =~ "eBay"
      assert html =~ ~s(aria-selected="true")
    end

    test "placeholder shows when no value" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="s" name="s" options={["a"]} placeholder="Pick one" />
          """
        end)

      assert html =~ "Pick one"
      assert html =~ "data-empty"
    end

    test "native path renders a real select with options + prompt" do
      html =
        render(fn assigns ->
          ~H"""
          <Select.select id="n" name="n" native value={25} options={[10, 25]} prompt="Any" />
          """
        end)

      assert html =~ "<select"
      assert html =~ ~s(<option value="">Any</option>)
      assert html =~ ~s(value="25" selected)
      refute html =~ "LanternSelect"
    end

    test "FormField clause extracts id/name/value" do
      form = Phoenix.Component.to_form(%{"status" => "active"}, as: :thing)

      html =
        render(
          fn assigns ->
            ~H"""
            <Select.select field={@form[:status]} options={[{"Active", "active"}]} />
            """
          end,
          %{form: form}
        )

      assert html =~ ~s(name="thing[status]")
      assert html =~ ~s(value="active")
    end
  end

  describe "pagination/1" do
    defp patch_fn, do: fn params -> "/orders?" <> URI.encode_query(params) end

    test "renders pager window with current page and gaps" do
      html =
        render(
          fn assigns ->
            ~H"""
            <Pagination.pagination
              id="pg"
              meta={%{current_page: 5, total_pages: 20, page_size: 25, total_count: 500}}
              patch_fn={@pf}
            />
            """
          end,
          %{pf: patch_fn()}
        )

      assert html =~ "500 results"
      assert html =~ ~s(aria-current="page")
      assert html =~ "lui-pg-current"
      assert html =~ "lui-pg-gap"
      assert html =~ "/orders?page=6"
      assert html =~ "/orders?page=4"
      assert html =~ "25 / page"
      # page-size options patch back to page 1
      assert html =~ "page_size=50"
      assert html =~ ~s(data-selected)
    end

    test "prev disabled on first page, next disabled on last" do
      html =
        render(
          fn assigns ->
            ~H"""
            <Pagination.pagination id="pg" meta={%{current_page: 1, total_pages: 1}} patch_fn={@pf} />
            """
          end,
          %{pf: patch_fn()}
        )

      assert html =~ "lui-pg-disabled"
    end

    test "window/3 builds correct sequences" do
      assert Pagination.window(1, 1, 1) == [1]
      assert Pagination.window(1, 5, 1) == [1, 2, :gap, 5]
      assert Pagination.window(5, 20, 1) == [1, :gap, 4, 5, 6, :gap, 20]
      assert Pagination.window(20, 20, 1) == [1, :gap, 19, 20]
      assert Pagination.window(2, 3, 1) == [1, 2, 3]
    end
  end
end
