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
    assigns =
      Map.merge(
        %{
          quick_filters_label: "Quick filters",
          active_filters_label: "Active filters",
          view_label: "View",
          save_view_label: "Save current view",
          load_view_label: "Load saved view",
          saved_view_event: nil
        },
        assigns
      )

    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      search_field={:search}
      search_placeholder="Search orders…"
      quick_filters_label={@quick_filters_label}
      active_filters_label={@active_filters_label}
      view_label={@view_label}
      save_view_label={@save_view_label}
      load_view_label={@load_view_label}
      view={@view}
      saved_view_event={@saved_view_event}
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

  defp table_with_saved_view_event(assigns) do
    ~H"""
    <DataTable.data_table
      id="saved"
      rows={@rows}
      meta={@meta}
      path="/orders"
      saved_view_event="saved-view"
    >
      <:col :let={row} label="Name">{row.name}</:col>
    </DataTable.data_table>
    """
  end

  defp expandable_table(assigns) do
    assigns =
      Map.merge(
        %{
          expand_label: "Expand",
          expanded_label: "Exit expand",
          expand_aria_label: "Expand table",
          expanded_aria_label: "Exit expanded view"
        },
        assigns
      )

    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      expandable
      expanded={@expanded}
      expand_label={@expand_label}
      expanded_label={@expanded_label}
      expand_aria_label={@expand_aria_label}
      expanded_aria_label={@expanded_aria_label}
    >
      <:col :let={r} label="Name">{r.name}</:col>
    </DataTable.data_table>
    """
  end

  defp base do
    %{
      rows: [%{id: 1, name: "Ada"}],
      meta: @meta,
      view: "table",
      quick_filters_label: "Quick filters",
      active_filters_label: "Active filters",
      view_label: "View",
      save_view_label: "Save current view",
      load_view_label: "Load saved view",
      saved_view_event: nil
    }
  end

  test "search-only tables do not render an empty filters and view popover" do
    assigns = %{__changed__: nil, meta: @meta}

    html =
      (fn a ->
         ~H"""
         <DataTable.data_table id="search-only" rows={[]} meta={@meta} path="/orders" search_field={:name}>
           <:col :let={row} label="Name">{row.name}</:col>
         </DataTable.data_table>
         """
       end).(assigns)
      |> rendered_to_string()

    assert html =~ ~s(id="search-only-chrome")
    refute html =~ ~s(id="search-only-filters")
  end

  test "stat overview renders with collapse hook and linked/static stats" do
    html = render(&table/1, base())

    assert html =~ ~s(phx-hook="LanternCollapse")
    assert html =~ ~s(data-part="collapse-toggle")
    assert html =~ "Revenue"
    assert html =~ "$12k"
    assert html =~ ~s(href="/rev")
    assert html =~ "lui-dt-stat-static"
  end

  test "expand control preserves current query params and reflects URL-owned state" do
    meta = %{params: %{"order_by" => ["name"], "view" => "cards"}}

    html =
      render(&expandable_table/1, %{rows: [%{id: 1, name: "Ada"}], meta: meta, expanded: false})

    assert html =~ ~s(class="lui-dt-expand")
    assert html =~ ~s(aria-label="Expand table")
    assert html =~ ~s(data-expandable="true")
    assert html =~ ~s(href="/orders?expand=1&amp;order_by[]=name&amp;view=cards")

    expanded_html =
      render(&expandable_table/1, %{
        rows: [%{id: 1, name: "Ada"}],
        meta: Map.put(meta, :params, Map.put(meta.params, "expand", "1")),
        expanded: true
      })

    assert expanded_html =~ "lui-datatable-expanded"
    assert expanded_html =~ ~s(aria-label="Exit expanded view")
    assert expanded_html =~ ~s(&quot;expand&quot;:&quot;1&quot;)
    [_, exit_href] = Regex.run(~r/<a href="([^"]+)"[^>]*class="lui-dt-expand"/, expanded_html)

    exit_query =
      exit_href
      |> String.replace("&amp;", "&")
      |> URI.parse()
      |> Map.fetch!(:query)
      |> URI.decode_query()

    refute Map.has_key?(exit_query, "expand")
    assert exit_query["view"] == "cards"
  end

  test "expand control text and accessible labels can be translated" do
    html =
      render(&expandable_table/1, %{
        rows: [],
        meta: @meta,
        expanded: true,
        expand_label: "Agrandir",
        expanded_label: "Quitter le plein écran",
        expand_aria_label: "Agrandir le tableau",
        expanded_aria_label: "Quitter le tableau agrandi"
      })

    assert html =~ ~s(aria-label="Quitter le tableau agrandi")
    assert html =~ "Quitter le plein écran"
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

  test "filters live in the Zag filters and view popover with active-count badge and clear button" do
    html = render(&table/1, base())

    # settings popover wraps the filter controls
    assert html =~ ~s(id="t-filters")
    assert html =~ ~s(aria-label="Filters &amp; view")
    assert html =~ ~s(data-zag)
    assert html =~ ~s(data-part="apply-filters")
    assert html =~ ~s(data-part="reset-filters")
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

  test "active filters render removable chips that preserve unrelated query state" do
    meta =
      put_in(@meta.params["filters"], %{
        "0" => %{"field" => "status", "value" => "pending"},
        "1" => %{"field" => "search", "value" => "ada"}
      })

    html = render(&table/1, %{base() | meta: meta})

    assert html =~ "lui-dt-chip"
    assert html =~ "status: pending"
    assert html =~ "Search: ada"
    assert html =~ ~s(href="/orders?filters[0][field]=search)
    assert html =~ "order_by"
    assert html =~ "view=table"
  end

  test "filter indexes sort numerically when there are ten or more filters" do
    filters =
      Map.new(0..11, fn index ->
        {Integer.to_string(index), %{"field" => "field_#{index}", "value" => "value_#{index}"}}
      end)

    html = render(&table/1, %{base() | meta: put_in(@meta.params["filters"], filters)})
    positions = Enum.map(0..11, &(:binary.match(html, "field_#{&1}: value_#{&1}") |> elem(0)))

    assert positions == Enum.sort(positions)
  end

  test "chrome labels can be translated by the caller" do
    html =
      render(&table/1, %{
        base()
        | quick_filters_label: "Fast filters",
          active_filters_label: "Current filters",
          view_label: "Display",
          save_view_label: "Store this view",
          load_view_label: "Open stored views",
          saved_view_event: "saved-view"
      })

    assert html =~ ~s(aria-label="Fast filters")
    assert html =~ ~s(aria-label="Current filters")
    assert html =~ ">Display</span>"
    assert html =~ ">Store this view</button>"
    assert html =~ ">Open stored views</button>"
  end

  test "saved view hooks emit generic consumer events with current URL configuration" do
    html = render(&table_with_saved_view_event/1, base())

    assert html =~ ~s(aria-label="Filters &amp; view")
    assert html =~ ~s(phx-click="saved-view")
    assert html =~ ~s(phx-value-action="save")
    assert html =~ ~s(phx-value-action="list")
    assert html =~ "order_by"
    assert html =~ "view"
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

  test "all-matching selection stays compact across pages and excludes unchecked ids" do
    html =
      render(
        fn assigns ->
          ~H"""
          <DataTable.data_table
            id="t"
            rows={@rows}
            meta={@meta}
            path="/orders"
            all_matching?
            excluded_ids={MapSet.new([2])}
            selection_label="%{count} chosen"
            select_all_label="Choose all %{count} results"
            clear_label="Deselect"
          >
            <:col :let={row} label="Name">{row.name}</:col>
          </DataTable.data_table>
          """
        end,
        %{rows: [%{id: 1, name: "Ada"}, %{id: 2, name: "Alan"}], meta: @meta}
      )

    assert html =~ "29 chosen"
    assert html =~ "Deselect"
    refute html =~ "Choose all 30 results"
    assert html =~ ~s(aria-label="Select all on page")

    assert html =~ ~r/<input[^>]+phx-value-id="1"[^>]+checked/ or
             html =~ ~r/<input[^>]+checked[^>]+phx-value-id="1"/

    refute html =~ ~r/<input[^>]+phx-value-id="2"[^>]+checked/ or
             html =~ ~r/<input[^>]+checked[^>]+phx-value-id="2"/
  end

  test "empty all-matching selection does not render the bulk bar or its actions" do
    for {total_count, excluded_ids} <- [{0, [1]}, {2, [1, 2]}] do
      html =
        render(
          fn assigns ->
            ~H"""
            <DataTable.data_table
              id="empty-selection"
              rows={[]}
              meta={%{total_count: @total_count, current_page: 1, total_pages: 1, params: %{}}}
              path="/orders"
              all_matching?
              excluded_ids={MapSet.new(@excluded_ids)}
            >
              <:col :let={row} label="Name">{row.name}</:col>
              <:bulk_action label="Archive" event="bulk-archive" />
            </DataTable.data_table>
            """
          end,
          %{total_count: total_count, excluded_ids: excluded_ids}
        )

      refute html =~ "lui-dt-bulkbar"
      refute html =~ "bulk-archive"
      refute html =~ "0 selected"
    end
  end

  test "selection labels are caller-translatable and select-all emits its generic event" do
    html = render_with_selection()
    assert html =~ "1 selected"
    assert html =~ "Select all 30"
    assert html =~ ~s(phx-click="select_all_matching")
    assert html =~ ~s(phx-click="clear_selection")
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

  describe "filters the chrome row does not own" do
    test "every filter is handed back to the hook, flagged owned when a panel control has its field" do
      # status comes from a tab, channel from the filter panel.
      meta = %{
        @meta
        | params: %{
            "filters" => %{
              "0" => %{"field" => "status", "value" => "pending"},
              "1" => %{"field" => "channel", "value" => "ebay"}
            }
          }
      }

      html = render(&table/1, %{rows: [], meta: meta, view: "table"})

      [keep] = Regex.run(~r/data-keep-filters="([^"]*)"/, html, capture: :all_but_first)
      keep = keep |> String.replace("&quot;", ~s(")) |> Jason.decode!()

      assert keep == [
               %{"field" => "status", "op" => nil, "value" => "pending", "owned" => false},
               %{"field" => "channel", "op" => nil, "value" => "ebay", "owned" => true}
             ]
    end

    test "only the search term is never handed back" do
      meta = %{
        @meta
        | params: %{"filters" => %{"0" => %{"field" => "search", "value" => "ada"}}}
      }

      html = render(&table/1, %{rows: [], meta: meta, view: "table"})

      assert html =~ ~s(data-keep-filters="[]")
    end
  end

  describe "keep-filters for the hook" do
    test "a filter with a panel control is handed back flagged owned, the search term is not" do
      meta = %{
        @meta
        | params: %{
            "filters" => %{
              "0" => %{"field" => "status", "value" => "pending"},
              "1" => %{"field" => "search", "op" => "ilike", "value" => "ada"}
            }
          }
      }

      html = render(&table_status_filter/1, %{rows: [], meta: meta})

      [keep] = Regex.run(~r/data-keep-filters="([^"]*)"/, html, capture: :all_but_first)
      keep = keep |> String.replace("&quot;", ~s(")) |> Jason.decode!()

      assert keep == [%{"field" => "status", "op" => nil, "value" => "pending", "owned" => true}]
    end
  end

  defp table_status_filter(assigns) do
    ~H"""
    <DataTable.data_table
      id="t"
      rows={@rows}
      meta={@meta}
      path="/orders"
      search_field={:search}
      views={["list"]}
    >
      <:tab label="Pending" filters={[%{field: "status", value: "pending"}]} />
      <:filter field={:status} label="Status" options={[{"Active", "active"}]} />
      <:list_item :let={r}>LIST-{r.name}</:list_item>
    </DataTable.data_table>
    """
  end

  describe "row links and row click" do
    defp linked(assigns) do
      ~H"""
      <DataTable.data_table
        id="t"
        rows={@rows}
        meta={@meta}
        path="/orders"
        view={@view}
        row_navigate={@row_navigate}
        row_patch={@row_patch}
        row_click={@row_click}
      >
        <:col :let={r} label="Name">{r.name}</:col>
        <:list_item :let={r}>LIST-{r.name}</:list_item>
        <:row_action :let={_r}><button type="button">More</button></:row_action>
      </DataTable.data_table>
      """
    end

    defp linked_assigns(extra) do
      Map.merge(
        %{
          rows: [%{id: 7, name: "Ada"}],
          meta: @meta,
          view: "table",
          row_navigate: nil,
          row_patch: nil,
          row_click: nil
        },
        extra
      )
    end

    test "row_navigate renders one real anchor over each table row, named by the first cell" do
      html = render(&linked/1, linked_assigns(%{row_navigate: &"/orders/#{&1.id}"}))

      assert html =~ ~s(class="lui-row-link")
      assert html =~ ~s(href="/orders/7")
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(aria-labelledby="t-row-7-main")
      assert html =~ ~s(id="t-row-7-main")
      assert html =~ "lui-row-linked"
      refute html =~ "data-row-click"
      # row actions stay a separate, clickable cell
      assert html =~ "More"
    end

    test "row_patch renders a patch anchor, in the list view too" do
      html =
        render(
          &linked/1,
          linked_assigns(%{view: "list", row_patch: &"/orders?open=#{&1.id}"})
        )

      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="/orders?open=7")
      assert html =~ ~s(aria-labelledby="t-row-7-main")
      assert html =~ ~s(id="t-row-7-main" class="lui-dt-list-main")
    end

    test "row_navigate wins over row_patch and row_click" do
      html =
        render(
          &linked/1,
          linked_assigns(%{
            row_navigate: &"/a/#{&1.id}",
            row_patch: &"/b/#{&1.id}",
            row_click: fn _ -> Phoenix.LiveView.JS.push("open") end
          })
        )

      assert html =~ ~s(href="/a/7")
      refute html =~ "/b/7"
      refute html =~ "data-row-click"
      refute html =~ ~s(phx-hook="LanternRowClick")
    end

    test "row_click puts the command on the row and mounts the hook, with no anchor" do
      html =
        render(
          &linked/1,
          linked_assigns(%{
            row_click: fn r -> Phoenix.LiveView.JS.push("open", value: %{id: r.id}) end
          })
        )

      assert html =~ ~s(phx-hook="LanternRowClick")
      assert html =~ "data-row-click="
      assert html =~ ~s(tabindex="0")
      assert html =~ "lui-row-linked"
      refute html =~ "lui-row-link\""
    end

    test "no row link attrs, no row link markup" do
      html = render(&linked/1, linked_assigns(%{}))

      refute html =~ "lui-row-link"
      refute html =~ "LanternRowClick"
    end
  end
end
