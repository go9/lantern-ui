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
  - Rows can be links: `row_navigate={&~p"/orders/\#{&1.id}"}` (or `row_patch`) stretches
    one real anchor over each row — keyboard Enter, middle-click and open-in-new-tab
    work, and checkboxes, buttons, menus and links inside the row keep their own
    clicks. `row_click={fn row -> JS.push("open", value: %{id: row.id}) end}` runs a
    command on click/Enter instead, for rows that are not links.
  - Selection is server-owned: rows emit `toggle_select` (`phx-value-id`),
    the header checkbox emits `select_all_page`, the bulk bar emits
    `select_all_matching`, `clear_selection`, and each `bulk_action`'s `event`
    — all to `target` (defaults to the parent LiveView). Set `all_matching?`
    with `excluded_ids` to represent every result without materializing IDs.

  The built-in search box keeps every other active filter (tab presets, filter
  panel values) in the URL it patches.

  Filter chips, quick filters, and the Filters & view popover share one chrome
  row. Filter changes are staged in the popover until Apply; search and quick
  filter navigation remain immediate. A collapsible `:overview` slot accepts
  arbitrary content; `:stat` remains available for simple metric cards. Saved-view
  controls emit a generic consumer event and do not prescribe persistence.
  Filter chips and quick filters share the toolbar row with separate Filters,
  Display, and Views controls. Filters opens a field list, then a compact editor
  with one Apply filter action; applied filters appear as removable chips.
  Search and quick-filter navigation remain immediate. Saved-view entries use
  `:view` slots and emit generic consumer events without prescribing persistence.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button
  alias LanternUI.Components.EmptyState
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Menu
  alias LanternUI.Components.Badge
  alias LanternUI.Components.Pagination
  alias LanternUI.Components.Popover
  alias LanternUI.Components.Select
  alias LanternUI.Components.Stat
  alias LanternUI.Components.Tabs

  attr(:id, :string, required: true, doc: "Stable DOM id for the table root and chrome.")
  attr(:rows, :list, required: true, doc: "Current page of row structs/maps to render.")
  attr(:meta, :map, required: true, doc: "Flop.Meta (or same-shaped map)")
  attr(:path, :string, required: true, doc: "base path for sort/pagination patches")

  attr(:selected_ids, :any,
    default: MapSet.new(),
    doc: "MapSet (or enumerable) of selected row ids."
  )

  attr(:all_matching?, :boolean,
    default: false,
    doc: "Whether all results matching the current query are selected."
  )

  attr(:excluded_ids, :any,
    default: MapSet.new(),
    doc: "MapSet of matching row ids explicitly excluded while `all_matching?` is true."
  )

  attr(:selection_label, :string,
    default: "%{count} selected",
    doc: "Bulk selection summary; `%{count}` is replaced with the selected count."
  )

  attr(:select_all_label, :string,
    default: "Select all %{count}",
    doc: "Action to select every result matching the current query; `%{count}` is replaced."
  )

  attr(:clear_label, :string, default: "Clear", doc: "Bulk selection clear action label.")

  attr(:row_id, :any, default: nil, doc: "row -> id fn; defaults to & &1.id")

  attr(:row_navigate, :any,
    default: nil,
    doc:
      "row -> path fn; makes the whole row a `navigate` link (list and table views). " <>
        "Rendered as a real anchor stretched over the row, so Enter, middle-click and " <>
        "\"open in new tab\" work; checkboxes, buttons, menus and links inside the row stay clickable."
  )

  attr(:row_patch, :any,
    default: nil,
    doc:
      "row -> path fn; like `row_navigate` but a `patch` link. Ignored when `row_navigate` is set."
  )

  attr(:row_click, :any,
    default: nil,
    doc:
      "row -> `Phoenix.LiveView.JS` fn; the whole row runs the command on click or Enter " <>
        "(clicks on interactive children are ignored). Use when the row is not a link. " <>
        "Ignored when `row_navigate` or `row_patch` is set."
  )

  attr(:show_checkboxes, :boolean,
    default: true,
    doc: "Show row selection checkboxes and bulk bar."
  )

  attr(:target, :any, default: nil, doc: "LiveView target for selection and bulk events.")
  attr(:title, :string, default: nil, doc: "Optional table heading above the toolbar.")
  attr(:subtitle, :string, default: nil, doc: "Secondary line under the table title.")

  attr(:info_modal_id, :string,
    default: nil,
    doc: "modal id the title's info button opens (LanternUI.open_dialog)"
  )

  attr(:page_size_options, :list,
    default: [10, 25, 50, 100],
    doc: "Choices for the page-size control."
  )

  attr(:search_field, :atom,
    default: nil,
    doc: "Flop filter field the built-in search box binds to"
  )

  attr(:search_op, :string, default: "ilike", doc: "Flop op for the search filter")

  attr(:search_placeholder, :string,
    default: "Search…",
    doc: "Placeholder for the toolbar search input."
  )

  attr(:filters_label, :string,
    default: "Filters",
    doc: "Label for the filters popover."
  )

  attr(:quick_filters_label, :string,
    default: "Quick filters",
    doc: "Accessible label for the quick filter tabs."
  )

  attr(:active_filters_label, :string,
    default: "Active filters",
    doc: "Accessible label for the active filter chips."
  )

  attr(:view_label, :string, default: "Display", doc: "Label for the view switcher.")

  attr(:save_view_label, :string,
    default: "Save current view",
    doc: "Label for saving the current view."
  )

  attr(:load_view_label, :string,
    default: "Load saved view",
    doc: "Label for opening saved views."
  )

  attr(:apply_label, :string, default: "Apply", doc: "Label for applying filter changes.")
  attr(:reset_label, :string, default: "Reset", doc: "Label for resetting filter controls.")

  attr(:clear_filters_label, :string,
    default: "Clear filters",
    doc: "Label for clearing active filters."
  )

  attr(:saved_view_event, :string,
    default: nil,
    doc: "Optional LiveView event for generic saved-view actions."
  )

  attr(:saved_views_label, :string,
    default: "Saved views",
    doc: "Heading for saved-view event hooks."
  )

  attr(:available_views, :list,
    default: nil,
    doc:
      "Available layout views, equivalent to `views`; intersected with layouts supplied by slots."
  )

  attr(:active_saved_view, :string,
    default: nil,
    doc: "Id or name of the currently active saved view."
  )

  attr(:hidden_columns, :list,
    default: [],
    doc: "Initially hidden table column keys (field names or column-N keys)."
  )

  attr(:density, :string,
    default: "comfortable",
    values: ~w(compact comfortable),
    doc: "Initial table row density."
  )

  attr(:display_event, :string,
    default: nil,
    doc: "Optional event receiving hidden_columns and density changes."
  )

  attr(:views, :list,
    default: nil,
    doc:
      "Allowed views, as strings. Intersected with the views that have slots " <>
        "(`:col` → table, `:list_item` → list, `:card` → cards). Omit to accept " <>
        "every slotted view. Use e.g. `[\"list\"]` to pin a page that still " <>
        "declares `:col` to list-only."
  )

  attr(:flush, :boolean,
    default: false,
    doc:
      "Drop the panel chrome — border, radius, shadow, raised surface — and pull " <>
        "the header, toolbar, cells and pagination out to the page gutter, so the " <>
        "table reads as the page rather than as a card sitting on it. This is what " <>
        "the list and card views already do for themselves; `flush` is how a table " <>
        "view asks for it. Use it when the table IS the page."
  )

  attr(:bordered, :boolean,
    default: true,
    doc:
      "Render the table chrome inside one bordered card. Set false when embedding without a card."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:fill, :boolean,
    default: false,
    doc:
      "Stretch to the parent's height (the parent must be a flex column with a definite height). " <>
        "The rows area — table body, list, or cards — scrolls internally; overview, chrome, and " <>
        "pagination stay pinned. Without it the table is its natural content height."
  )

  attr(:expandable, :boolean,
    default: false,
    doc: "Render an Expand control and enable the Shift+E / Escape shortcuts."
  )

  attr(:expanded, :boolean,
    default: false,
    doc: "URL-owned expanded state; set from handle_params when `expand=1`."
  )

  attr(:expand_label, :string,
    default: "Expand table",
    doc: "Tooltip shown on the expand control."
    doc: "Tooltip text for the expand control."
  )

  attr(:expanded_label, :string,
    default: "Exit expand",
    doc: "Tooltip text shown while the table is expanded."
  )

  attr(:expand_aria_label, :string,
    default: "Expand table",
    doc: "Accessible label for the expand control."
  )

  attr(:expanded_aria_label, :string,
    default: "Exit expand",
    doc: "Accessible label for the control while the table is expanded."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:header_action, doc: "Actions rendered in the title row (right side).")
  slot(:toolbar, doc: "Extra controls in the filter/search toolbar.")

  slot :col,
    doc:
      "One data column; body is rendered per row via :let. Optional when view is list or cards." do
    attr(:label, :string, doc: "Header label for the column.")
    attr(:field, :atom, doc: "Flop sort field when sortable.")
    attr(:sortable, :boolean, doc: "Enable sort patch links on the header.")
    attr(:class, :any, doc: "Extra classes on the header cell.")
    attr(:td_class, :any, doc: "Extra classes on body cells for this column.")
  end

  slot :bulk_action, doc: "Action shown in the bulk bar when rows are selected." do
    attr(:label, :string, doc: "Button label for the bulk action.")
    attr(:icon, :string, doc: "Optional leading icon name.")
    attr(:event, :string, doc: "phx-click event name fired to target.")
    attr(:color, :string, doc: "Button color token (e.g. danger).")
  end

  slot(:row_action, doc: "Per-row trailing actions cell; receives the row via :let.")
  slot(:empty, doc: "Empty-state content when there are no rows.")

  slot(:overview, doc: "Arbitrary collapsible overview content above the table.")

  slot :stat, doc: "Overview metric card above the table." do
    attr(:label, :string, doc: "Stat caption under or beside the value.")
    attr(:value, :any, doc: "Primary metric value to display.")
    attr(:icon, :string, doc: "Optional heroicon name shown top-right of the label row.")
    attr(:subtitle, :string, doc: "Optional muted caption under the value.")
    attr(:href, :string, doc: "Optional link target wrapping the stat.")
    attr(:class, :any, doc: "Extra classes on this stat card.")
  end

  slot :tab, doc: "Filter preset tab in the table chrome." do
    attr(:label, :string, doc: "Tab label text.")
    attr(:count, :integer, doc: "Optional badge count beside the label.")

    attr(:filters, :list,
      doc:
        ~S|Flop filter preset, e.g. [%{field: "status", value: "pending"}]; omit for the unfiltered tab|
    )
  end

  slot :filter, doc: "Toolbar filter control bound to a Flop field." do
    attr(:field, :atom, doc: "Flop filter field atom.")
    attr(:label, :string, doc: "Accessible/visible label for the control.")
    attr(:type, :atom, doc: ":select (default) | :text | :range")
    attr(:op, :string, doc: "Flop filter op (e.g. ==, ilike); defaults by type.")
    attr(:options, :list, doc: "Select options as values or {label, value} tuples.")
    attr(:prompt, :string, doc: "Blank/prompt option label for select filters.")
    attr(:placeholder, :string, doc: "Placeholder for text filters.")
    attr(:multiple, :boolean, doc: "multi-select filter (Flop op: in)")
    attr(:searchable, :boolean, doc: "search box in the filter's listbox")
  end

  slot(:card, doc: "per-row card rendering for the cards view; enables the view toggle")

  slot(:list_item, doc: "per-row simple list rendering; enables the list view")

  slot :view, doc: "A saved view with a name and optional id and params." do
    attr(:id, :string, doc: "Saved view identifier emitted with the apply event.")
    attr(:name, :string, required: true, doc: "Visible saved view name.")
    attr(:params, :map, doc: "Saved view parameters supplied to the consumer event.")
  end

  def data_table(assigns) do
    # Phoenix stores the new :view slot in assigns.view. Keep accepting the old
    # string-valued view attr while the slot uses the same public name.
    legacy_view = if is_binary(assigns.view), do: assigns.view, else: "table"
    saved_view_slots = if is_list(assigns.view), do: assigns.view, else: []

    assigns =
      assigns
      |> assign(:saved_view_slots, saved_view_slots)
      |> assign(:view, legacy_view)
      |> assign(:row_id_fn, assigns.row_id || (& &1.id))
      |> assign(:row_click?, !assigns.row_navigate && !assigns.row_patch && !!assigns.row_click)
      |> assign(:selected_id_set, MapSet.new(assigns.selected_ids))
      |> assign(:excluded_id_set, MapSet.new(assigns.excluded_ids))
      |> assign(:page_ids, Enum.map(assigns.rows, assigns.row_id || (& &1.id)))
      |> assign(
        :active_filters,
        active_filters(assigns.meta, assigns.search_field, assigns.filter)
      )
      |> assign(:total_count, Map.get(assigns.meta, :total_count) || 0)
      |> assign(:selection_count, selection_count(assigns))

    assigns =
      assign(
        assigns,
        :all_selected?,
        assigns.page_ids != [] and
          Enum.all?(assigns.page_ids, &selected_id?(&1, assigns))
      )

    assigns = resolve_views(assigns)

    ~H"""
    <div
      id={@id}
      class={
        Class.merge([
          "lui-datatable",
          (!@bordered || @flush) && "lui-datatable-borderless",
          @fill && "lui-datatable-fill",
          @flush && "lui-datatable-flush",
          @expandable && @expanded && "lui-datatable-expanded",
          @class
        ])
      }
      data-view={@view}
      data-density={@density}
      data-hidden-columns={Jason.encode!(@hidden_columns)}
      data-expanded={if @expandable && @expanded, do: "true"}
      phx-hook={@row_click? && "LanternRowClick"}
      {@rest}
    >
      <section
        :if={@overview != [] || @stat != []}
        id={"#{@id}-overview"}
        class="lui-dt-overview"
        phx-hook="LanternCollapse"
      >
        <button
          type="button"
          class="lui-dt-overview-head"
          data-part="collapse-toggle"
          aria-controls={"#{@id}-overview-body"}
        >
          <span>Overview</span>
          <Icon.icon name="chevron-down" class="lui-dt-overview-chev" />
        </button>
        <div id={"#{@id}-overview-body"} class="lui-dt-overview-body" data-part="collapse-body">
          {render_slot(@overview)}
          <div :if={@stat != []} class="lui-dt-stats">
            <Stat.stat_card
              :for={stat <- @stat}
              label={stat[:label]}
              value={if stat[:inner_block], do: render_slot(stat), else: stat[:value]}
              icon={stat[:icon]}
              subtitle={stat[:subtitle]}
              href={stat[:href]}
              class={stat[:class]}
            />
          </div>
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

      <div
        :if={
          @tab != [] || @toolbar != [] || @search_field || @filter != [] || @saved_view_event ||
            @card != [] || @list_item != [] || @expandable || @col != []
        }
        id={"#{@id}-chrome"}
        class="lui-dt-chromerow"
        phx-hook="LanternTableChrome"
        data-path={@path}
        data-table-id={@id}
        data-expandable={if @expandable, do: "true"}
        data-expanded={if @expandable && @expanded, do: "true"}
        data-params={
          Jason.encode!(chrome_base_params(@meta, @view, @card != [] || @list_item != [], @expanded))
        }
        data-keep-filters={Jason.encode!(unowned_filters(@meta, @search_field, @filter))}
        data-display-event={@display_event}
      >
        <div :if={@tab != []} class="lui-dt-quickfilters" aria-label={@quick_filters_label}>
          <Tabs.tabs_list active_tab={active_tab(@tab, @meta, @search_field)} size="sm">
            <:tab
              :for={{tab, i} <- Enum.with_index(@tab)}
              name={"tab-#{i}"}
              patch={tab_path(@path, @meta, tab[:filters] || [], @search_field)}
            >
              {tab[:label]}
              <Badge.badge
                :if={tab[:count] && to_string(tab[:count]) != to_string(@total_count)}
                size="sm"
                color="neutral"
              >
                {tab[:count]}
              </Badge.badge>
            </:tab>
          </Tabs.tabs_list>
        </div>

        <div :if={@active_filters != []} class="lui-dt-chips" aria-label={@active_filters_label}>
          <.link
            :for={filter <- @active_filters}
            patch={
              remove_filter_path(@path, @meta, filter.index, @view, @card != [] || @list_item != [])
            }
            class="lui-dt-chip"
            aria-label={"Remove #{filter.label} filter: #{filter.value}"}
          >
            <span>{filter.label}: {filter.value}</span>
            <Icon.icon name="x-mark" />
          </.link>
        </div>

        <div class="lui-dt-spacer"></div>

        {render_slot(@toolbar)}

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

        <Popover.popover
          :if={@filter != []}
          id={"#{@id}-filters"}
          class="lui-dt-filterpanel lui-dt-filterpanel-filters"
          placement="bottom-end"
        >
          <Button.button size="sm" variant="outline" type="button" aria-label={@filters_label}>
            <Icon.icon name="funnel" /> {@filters_label}
          </Button.button>
          <:content>
            <div class="lui-dt-filterpanel-inner">
              <div class="lui-dt-addfilter">
                <div :if={length(@filter) > 7} class="lui-dt-searchline">
                  <Icon.icon name="magnifying-glass" />
                  <input
                    id={"#{@id}-filter-search"}
                    type="search"
                    placeholder="Search fields…"
                    aria-label="Search fields"
                    data-part="filter-search"
                  />
                </div>
                <div class="lui-command-listbox" role="listbox" aria-label="Available filters">
                  <button
                    :for={filter <- @filter}
                    type="button"
                    class="lui-command-item"
                    role="option"
                    data-part="add-filter"
                    data-field={filter[:field]}
                    data-filter-option
                  >{filter[:label] || to_string(filter[:field])}</button>
                </div>
              </div>
              <div
                :for={filter <- @filter}
                class="lui-dt-filterrow"
                data-filter-editor={filter[:field]}
                hidden
              >
                <div class="lui-dt-filterhead">
                  <label class="lui-dt-filterlabel" for={"#{@id}-filter-value-#{filter[:field]}"}>{filter[
                    :label
                  ] || to_string(filter[:field])}</label>
                  <select
                    :if={filter[:type] == :text || filter[:type] == :select}
                    class="lui-dt-operator"
                    data-part="filter-op"
                    data-field={filter[:field]}
                    aria-label={"#{filter[:label] || filter[:field]} operator"}
                  >
                    <option value={filter[:op] || if(filter[:type] == :text, do: "ilike", else: "==")}>
                      Matches
                    </option>
                    <option :if={filter[:type] == :text} value="==">Is</option>
                    <option :if={filter[:type] == :text} value="not_ilike">Does not contain</option>
                    <option :if={filter[:type] == :select} value="!=">Is not</option>
                  </select>
                </div>
                <%= case filter[:type] || :select do %>
                  <% :text -> %>
                    <input
                      id={"#{@id}-filter-value-#{filter[:field]}"}
                      type="text"
                      class="lui-dt-filtertext"
                      data-part="filter"
                      data-field={filter[:field]}
                      data-op={filter[:op] || "ilike"}
                      value={filter_value(@meta, filter[:field])}
                      placeholder={filter[:placeholder] || "Any"}
                    />
                  <% :range -> %>
                    <div class="lui-dt-filterrange">
                      <input
                        type="number"
                        class="lui-dt-filtertext"
                        data-part="filter"
                        data-field={filter[:field]}
                        data-op=">="
                        value={filter_value(@meta, filter[:field], ">=")}
                        placeholder="Min"
                        aria-label={"#{filter[:label]} min"}
                      />
                      <span class="lui-dt-rangesep">–</span>
                      <input
                        type="number"
                        class="lui-dt-filtertext"
                        data-part="filter"
                        data-field={filter[:field]}
                        data-op="<="
                        value={filter_value(@meta, filter[:field], "<=")}
                        placeholder="Max"
                        aria-label={"#{filter[:label]} max"}
                      />
                    </div>
                  <% _ -> %>
                    <%= if filter[:multiple] || filter[:searchable] do %>
                      <div
                        data-part="filter-rich"
                        data-field={filter[:field]}
                        data-op={if filter[:multiple], do: "in", else: filter[:op] || "=="}
                      >
                        <Select.select
                          id={"#{@id}-filter-#{filter[:field]}"}
                          name={"_dt_filter_#{filter[:field]}"}
                          value={
                            if filter[:multiple],
                              do: filter_values(@meta, filter[:field]),
                              else: filter_value(@meta, filter[:field])
                          }
                          options={filter[:options] || []}
                          placeholder={filter[:prompt] || "Any"}
                          multiple={filter[:multiple] || false}
                          searchable={filter[:searchable] || false}
                          size="sm"
                        />
                      </div>
                    <% else %>
                      <div class="lui-select-native-wrap">
                        <select
                          id={"#{@id}-filter-value-#{filter[:field]}"}
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
                            selected={
                              to_string(opt_value(opt)) == filter_value(@meta, filter[:field])
                            }
                          >
                            {opt_label(opt)}
                          </option>
                        </select>
                        <Icon.icon name="chevron-up-down" class="lui-select-caret" />
                      </div>
                    <% end %>
                <% end %>
              </div>
              <footer class="lui-dt-filterfooter" data-part="filter-actions" hidden>
                <button type="button" class="lui-dt-applyfilters" data-part="apply-filters">Apply filter</button>
              </footer>
            </div>
          </:content>
        </Popover.popover>

        <Popover.popover
          :if={@col != []}
          id={"#{@id}-display"}
          class="lui-dt-displaypanel"
          placement="bottom-end"
        >
          <Button.button size="sm" variant="outline" type="button" aria-label={@view_label}><Icon.icon name="view-columns" />
          {@view_label}</Button.button>
          <:content>
            <div class="lui-dt-display-content" data-part="display-settings">
              <input
                :if={length(@col) > 6}
                type="search"
                class="lui-dt-column-search"
                placeholder="Search columns…"
                aria-label="Search columns"
                data-part="column-search"
              />
              <div class="lui-dt-column-list" role="group" aria-label="Column visibility">
                <label :for={{col, index} <- Enum.with_index(@col)} class="lui-dt-column-option">
                  <input
                    type="checkbox"
                    data-part="column-toggle"
                    data-column-key={column_key(col, index)}
                    checked={column_key(col, index) not in @hidden_columns}
                  />
                  <span>{col[:label] || column_key(col, index)}</span>
                </label>
              </div>
              <div class="lui-dt-density">
                <span class="lui-dt-filterlabel">Density</span>
                <div
                  class="lui-segmented lui-dt-density-switch"
                  role="radiogroup"
                  aria-label="Density"
                >
                  <button
                    type="button"
                    role="radio"
                    aria-checked={to_string(@density == "compact")}
                    data-part="density"
                    data-density="compact"
                  >Compact</button>
                  <button
                    type="button"
                    role="radio"
                    aria-checked={to_string(@density == "comfortable")}
                    data-part="density"
                    data-density="comfortable"
                  >Comfortable</button>
                </div>
              </div>
              <button type="button" class="lui-dt-reset-display" data-part="reset-display">Reset</button>
            </div>
          </:content>
        </Popover.popover>

        <Menu.menu
          :if={length(@layout_views) > 1 || @saved_view_event || @saved_view_slots != []}
          id={"#{@id}-views"}
          label="Views"
          trigger_class="lui-dt-views-trigger"
        >
          <:trigger><Icon.icon name="chevron-down" /> Views</:trigger>
          <Menu.menu_item
            :for={layout_view <- @layout_views}
            :if={length(@layout_views) > 1}
            patch={view_path(@path, @meta, layout_view)}
          >
            <Icon.icon :if={@view == layout_view} name="check" /> {layout_view_label(layout_view)}
          </Menu.menu_item>
          <Menu.menu_separator :if={@saved_view_slots != []} />
          <div :for={saved_view <- @saved_view_slots} class="lui-dt-saved-view-row">
            <% saved_id = saved_view[:id] || saved_view[:name] %>
            <button
              type="button"
              class="lui-dt-savedview"
              data-part="saved-view"
              data-view-id={saved_id}
              phx-click={@saved_view_event}
              phx-value-action="apply"
              phx-value-id={saved_id}
              phx-value-params={Jason.encode!(saved_view[:params] || %{})}
            >
              <Icon.icon
                :if={to_string(@active_saved_view) == to_string(saved_id)}
                name="check"
              /> {saved_view[:name]}
            </button>
            <button
              :if={@saved_view_event}
              type="button"
              class="lui-dt-savedview-action lui-dt-rename-view"
              data-view-id={saved_view[:id] || saved_view[:name]}
              phx-click={@saved_view_event}
              phx-value-action="rename"
              phx-value-id={saved_view[:id] || saved_view[:name]}
            >Rename</button>
            <button
              :if={@saved_view_event}
              type="button"
              class="lui-dt-savedview-action"
              phx-click={@saved_view_event}
              phx-value-action="delete"
              phx-value-id={saved_view[:id] || saved_view[:name]}
            >Delete</button>
          </div>
          <Menu.menu_separator :if={@saved_view_event} />
          <Menu.menu_item :if={@saved_view_event} class="lui-dt-save-view-open">
            {@save_view_label}…
          </Menu.menu_item>
          <Menu.menu_item
            :if={@saved_view_event}
            phx-click={@saved_view_event}
            phx-value-action="list"
            phx-value-params={Jason.encode!(saved_view_params(@meta, @view))}
          >
            {@load_view_label}
          </Menu.menu_item>
        </Menu.menu>
        <dialog
          :if={@saved_view_event}
          class="lui-dt-save-dialog"
          data-part="save-view-dialog"
          aria-label={@saved_views_label}
        >
          <h3 data-part="save-view-title">Save current view</h3>
          <input
            type="text"
            class="lui-dt-view-name"
            placeholder="View name"
            aria-label="View name"
            data-part="view-name"
          />
          <div class="lui-dt-save-actions">
            <button type="button" data-part="save-view-cancel">Cancel</button>
            <button
              type="button"
              class="lui-dt-save-confirm"
              data-part="save-view-confirm"
              phx-click={@saved_view_event}
              phx-value-action="save"
              phx-value-params={Jason.encode!(saved_view_params(@meta, @view))}
            >Save</button>
          </div>
        </dialog>
        <.link
          :if={@expandable}
          patch={expand_path(@path, @meta, @expanded)}
          class="lui-dt-expand"
          aria-label={if @expanded, do: @expanded_aria_label, else: @expand_aria_label}
          title={if @expanded, do: @expanded_label, else: @expand_label}
          data-part="expand"
        >
          <Icon.icon name={if @expanded, do: "arrows-pointing-in", else: "arrows-pointing-out"} />
        </.link>
        <dialog
          :if={@saved_view_event}
          class="lui-dt-save-dialog"
          data-part="rename-view-dialog"
          aria-label="Rename view"
        >
          <h3>Rename view</h3><input
            type="text"
            class="lui-dt-view-name"
            placeholder="View name"
            aria-label="New view name"
            data-part="view-name"
          />
          <div class="lui-dt-save-actions">
            <button type="button" data-part="rename-view-cancel">Cancel</button><button
              type="button"
              class="lui-dt-save-confirm"
              data-part="rename-view-confirm"
              phx-click={@saved_view_event}
              phx-value-action="rename"
            >Save</button>
          </div>
        </dialog>

        <.link
          :if={@expandable}
          patch={expand_path(@path, @meta, @expanded)}
          class="lui-dt-expand"
          aria-label={if @expanded, do: @expanded_aria_label, else: @expand_aria_label}
          title={if @expanded, do: @expanded_label, else: @expand_label}
          data-part="expand"
        >
          <Icon.icon name={if @expanded, do: "arrows-pointing-in", else: "arrows-pointing-out"} />
        </.link>
      </div>

      <div :if={@selection_count > 0} class="lui-dt-bulkbar">
        <span class="lui-dt-bulkcount">{label_with_count(@selection_label, @selection_count)}</span>
        <button
          :if={!@all_matching? && @selection_count < @total_count}
          type="button"
          class="lui-dt-selectall"
          phx-click="select_all_matching"
          phx-target={@target}
        >
          {label_with_count(@select_all_label, @total_count)}
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
          {@clear_label}
        </Button.button>
      </div>

      <div :if={@card != [] && @view == "cards"} class="lui-dt-cards">
        <%= if @rows == [] do %>
          <%= if @empty != [] do %>
            {render_slot(@empty)}
          <% else %>
            <EmptyState.empty_state icon="inbox" title="Nothing here yet" />
          <% end %>
        <% else %>
          <div :for={row <- @rows} class="lui-dt-card">{render_slot(@card, row)}</div>
        <% end %>
      </div>

      <div :if={@list_item != [] && @view == "list"} class="lui-dt-list">
        <%= if @rows == [] do %>
          <%= if @empty != [] do %>
            {render_slot(@empty)}
          <% else %>
            <EmptyState.empty_state icon="inbox" title="Nothing here yet" />
          <% end %>
        <% else %>
          <div
            :for={row <- @rows}
            class={Class.merge(["lui-dt-list-row", row_linked?(assigns, row) && "lui-row-linked"])}
            data-lantern-list-item={row_linked?(assigns, row) || nil}
            {row_click_attrs(assigns, row)}
          >
            <div id={"#{@id}-row-#{@row_id_fn.(row)}-main"} class="lui-dt-list-main">
              {render_slot(@list_item, row)}
            </div>
            <div :if={@row_action != []} class="lui-dt-list-actions">
              {render_slot(@row_action, row)}
            </div>
            <.row_anchor
              :if={row_link(assigns, row)}
              link={row_link(assigns, row)}
              labelledby={"#{@id}-row-#{@row_id_fn.(row)}-main"}
            />
          </div>
        <% end %>
      </div>

      <div
        :if={!(@card != [] && @view == "cards") && !(@list_item != [] && @view == "list")}
        class="lui-table-wrap"
      >
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
              <th
                :for={{col, index} <- Enum.with_index(@col)}
                class={Class.merge(["lui-th", col[:class]])}
                data-column-key={column_key(col, index)}
                data-column-label={col[:label] || column_key(col, index)}
                scope="col"
                aria-sort={col[:sortable] && col[:field] && sort_direction(@meta, col.field)}
              >
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
              class={
                Class.merge([
                  "lui-tr",
                  selected_id?(@row_id_fn.(row), assigns) && "lui-tr-selected",
                  row_linked?(assigns, row) && "lui-row-linked"
                ])
              }
              {row_click_attrs(assigns, row)}
            >
              <td :if={@show_checkboxes} class="lui-td lui-td-check">
                <input
                  type="checkbox"
                  class="lui-checkbox"
                  checked={selected_id?(@row_id_fn.(row), assigns)}
                  phx-click="toggle_select"
                  phx-value-id={@row_id_fn.(row)}
                  phx-target={@target}
                  aria-label="Select row"
                />
              </td>
              <td
                :for={{col, i} <- Enum.with_index(@col)}
                data-column-key={column_key(col, i)}
                id={i == 0 && row_link(assigns, row) && "#{@id}-row-#{@row_id_fn.(row)}-main"}
                class={Class.merge(["lui-td", col[:td_class]])}
              >
                {render_slot(col, row)}
                <.row_anchor
                  :if={i == 0 && row_link(assigns, row)}
                  link={row_link(assigns, row)}
                  labelledby={"#{@id}-row-#{@row_id_fn.(row)}-main"}
                />
              </td>
              <td :if={@row_action != []} class="lui-td lui-td-actions">
                {render_slot(@row_action, row)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <%!-- Shown whenever there are rows, not only when there is more than one
            page. The bar is not just a pager: it carries the result count and the
            page size, and on a single page those are the two things that tell a
            reader nothing is hidden below the fold. Withholding it there reads as
            a table that has not finished loading. An empty table has no count to
            report, so that is where it goes. --%>
      <Pagination.pagination
        :if={@rows != []}
        id={"#{@id}-pagination"}
        meta={@meta}
        patch_fn={&page_path(@path, @meta, &1)}
        page_size_options={@page_size_options}
        class="lui-dt-pagination"
      />
    </div>
    """
  end

  defp column_key(col, index),
    do: if(col[:field], do: to_string(col[:field]), else: "column-#{index}")

  defp selection_count(%{all_matching?: true, meta: meta, excluded_ids: excluded_ids}) do
    max((Map.get(meta, :total_count) || 0) - MapSet.size(MapSet.new(excluded_ids)), 0)
  end

  defp selection_count(%{selected_ids: selected_ids}), do: MapSet.size(MapSet.new(selected_ids))

  defp selected_id?(id, %{all_matching?: true, excluded_id_set: excluded_ids}),
    do: not MapSet.member?(excluded_ids, id)

  defp selected_id?(id, %{selected_id_set: selected_ids}), do: MapSet.member?(selected_ids, id)

  defp label_with_count(label, count),
    do: String.replace(label, "%{count}", Integer.to_string(count))

  # The row's destination: `{:navigate | :patch, path}` or nil. Link wins over
  # `row_click`, which is a hook-driven fallback for rows that run a JS command.
  defp row_link(%{row_navigate: f}, row) when is_function(f, 1), do: {:navigate, f.(row)}
  defp row_link(%{row_patch: f}, row) when is_function(f, 1), do: {:patch, f.(row)}
  defp row_link(_assigns, _row), do: nil

  defp row_linked?(assigns, row), do: !!row_link(assigns, row) or assigns.row_click?

  defp row_click_attrs(%{row_click?: true, row_click: f}, row) do
    [{"data-row-click", Jason.encode!(f.(row))}, {"tabindex", "0"}]
  end

  defp row_click_attrs(_assigns, _row), do: []

  # A real anchor stretched over the row (see `.lui-row-link`): it is what makes
  # Enter, middle-click and "open in new tab" work, and the row's first cell
  # names it. Interactive children sit above it, so they keep their own clicks.
  attr(:link, :any, required: true)
  attr(:labelledby, :string, required: true)

  defp row_anchor(assigns) do
    {kind, to} = assigns.link
    assigns = assign(assigns, :link_attrs, [{kind, to}])

    ~H"""
    <.link {@link_attrs} class="lui-row-link" aria-labelledby={@labelledby}></.link>
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

  @doc """
  The `aria-sort` value for a sortable column: `"ascending"`, `"descending"`, or
  `"none"`.

  ARIA requires this on the header *cell* (the `<th>`), not on the inner sort
  link, and only on columns that are actually sortable — `"none"` means "sortable
  but not the current sort key", which is a different claim from a plain column
  with no sort affordance at all.
  """
  def sort_direction(meta, field) do
    field_s = to_string(field)
    {current_by, current_dirs} = current_order(meta)

    if current_by == [field_s] do
      if to_string(List.first(current_dirs)) == "desc", do: "descending", else: "ascending"
    else
      "none"
    end
  end

  @doc false
  def sort_indicator(meta, field) do
    case sort_direction(meta, field) do
      "ascending" -> "↑"
      "descending" -> "↓"
      "none" -> ""
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
  # The chrome hook rebuilds the URL from these on every search/filter/clear, so
  # anything omitted here is silently dropped. `view` lives outside Flop's params,
  # which is why searching used to bounce you back to the default view.
  defp chrome_base_params(meta, view, toggleable?, expanded?) do
    base = base_params(meta) |> Map.drop(["filters", "page"])

    base = if toggleable?, do: Map.put(base, "view", view), else: base
    if expanded?, do: Map.put(base, "expand", "1"), else: base
  end

  # The chrome row rebuilds `filters` from the controls it can see, so anything
  # a control cannot show has to be handed back to the hook or a keystroke in the
  # search box would drop it — a tab preset, or a preset on a field whose panel
  # select has no matching option. Every filter except the search term goes
  # back, flagged `owned` when a panel control exists for its field: the hook
  # lets an owned control override its filter, and drops it only when that
  # control is the one the reader just changed or cleared.
  defp unowned_filters(meta, search_field, filter_slots) do
    owned = MapSet.new(filter_slots, &to_string(&1[:field]))
    search = search_field && to_string(search_field)

    base_params(meta)
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.reject(&(to_string(&1["field"]) == search))
    |> Enum.map(fn f ->
      %{
        "field" => f["field"],
        "op" => f["op"],
        "value" => f["value"],
        "owned" => to_string(f["field"]) in owned
      }
    end)
  end

  defp filter_value(meta, field, op \\ nil) do
    field_s = to_string(field)

    base_params(meta)
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.find_value("", fn f ->
      f["field"] == field_s and (is_nil(op) or f["op"] == op) and to_string(f["value"] || "")
    end)
  end

  defp keep_search(filters, _meta, nil), do: filters

  defp keep_search(filters, meta, search_field) do
    field_s = to_string(search_field)

    current =
      base_params(meta)
      |> Map.get("filters", %{})
      |> normalize_filters()
      |> Enum.find(&(&1["field"] == field_s and to_string(&1["value"] || "") != ""))

    case current do
      nil -> filters
      found -> Map.put(filters, to_string(map_size(filters)), found)
    end
  end

  defp normalize_filters(filters) when is_map(filters) do
    filters
    |> Enum.sort_by(fn {key, _value} ->
      case Integer.parse(to_string(key)) do
        {index, ""} -> {0, index}
        _ -> {1, to_string(key)}
      end
    end)
    |> Enum.map(&elem(&1, 1))
  end

  defp normalize_filters(filters) when is_list(filters), do: filters
  defp normalize_filters(_), do: []

  defp active_filters(meta, search_field, filter_slots) do
    search = search_field && to_string(search_field)

    meta
    |> base_params()
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.with_index()
    |> Enum.flat_map(fn {filter, index} ->
      field = to_string(filter["field"] || "")
      value = filter["value"]

      if is_nil(value) or value == "" do
        []
      else
        slot = Enum.find(filter_slots, &(to_string(&1[:field]) == field))
        label = if field == search, do: "Search", else: (slot && slot[:label]) || field
        values = List.wrap(value) |> Enum.map(&option_name(slot, &1)) |> Enum.join(", ")
        [%{index: index, label: label, value: values}]
      end
    end)
  end

  defp option_name(nil, value), do: to_string(value)

  defp option_name(slot, value) do
    case Enum.find(slot[:options] || [], &(to_string(opt_value(&1)) == to_string(value))) do
      nil -> to_string(value)
      option -> opt_label(option)
    end
  end

  defp remove_filter_path(path, meta, index, view, toggleable?) do
    params =
      base_params(meta)
      |> Map.delete("page")
      |> then(fn params -> if toggleable?, do: Map.put(params, "view", view), else: params end)

    filters =
      params
      |> Map.get("filters", %{})
      |> normalize_filters()
      |> Enum.with_index()
      |> Enum.reject(fn {_filter, filter_index} -> filter_index == index end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.with_index()
      |> Map.new(fn {filter, filter_index} -> {to_string(filter_index), filter} end)

    params =
      if filters == %{},
        do: Map.delete(params, "filters"),
        else: Map.put(params, "filters", filters)

    path <> "?" <> Plug.Conn.Query.encode(params)
  end

  defp saved_view_params(meta, view) do
    base_params(meta)
    |> Map.delete("page")
    |> Map.put("view", view)
  end

  # A tab is active when its filter preset matches the current filters exactly
  # (both normalized to field=>value); the presetless tab is active otherwise
  # when no filters are applied. The search filter is not part of that
  # comparison — see `tab_path/4`.
  defp active_tab(tabs, meta, search_field) do
    current =
      base_params(meta)
      |> Map.get("filters", %{})
      |> normalize_filters()
      |> Map.new(fn f -> {to_string(f["field"]), to_string(f["value"] || "")} end)
      |> Map.drop([to_string(search_field)])

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

  # A tab is a preset: picking one replaces whatever was in the filter panel.
  # The search box is the exception, because it is not a slice — it is the
  # reader still looking for the same thing, one tab over. Wiping it on every
  # tab click makes the tabs feel like they undo your work.
  defp tab_path(path, meta, preset, search_field) do
    filters =
      preset
      |> Enum.map(&normalize_preset/1)
      |> Enum.with_index()
      |> Map.new(fn {f, i} ->
        base = %{"field" => f.field, "value" => f.value}
        {to_string(i), if(f.op, do: Map.put(base, "op", f.op), else: base)}
      end)
      |> keep_search(meta, search_field)

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

  defp expand_path(path, meta, expanded?) do
    params = base_params(meta)
    params = if expanded?, do: Map.delete(params, "expand"), else: Map.put(params, "expand", "1")
    if map_size(params) == 0, do: path, else: path <> "?" <> Plug.Conn.Query.encode(params)
  end

  defp filter_values(meta, field) do
    field_s = to_string(field)

    base_params(meta)
    |> Map.get("filters", %{})
    |> normalize_filters()
    |> Enum.find_value([], fn f -> f["field"] == field_s && List.wrap(f["value"] || []) end)
  end

  defp layout_view_label("cards"), do: "Grid"
  defp layout_view_label(view), do: String.capitalize(view)

  defp resolve_views(assigns) do
    available =
      assigns
      |> slotted_views()
      |> restrict_views(assigns.available_views || assigns.views)

    view =
      cond do
        assigns.view in available -> assigns.view
        available != [] -> hd(available)
        true -> assigns.view
      end

    assign(assigns, layout_views: available, view: view)
  end

  defp slotted_views(assigns) do
    has_list? = assigns.list_item != []
    has_cards? = assigns.card != []
    has_table? = assigns.col != []

    cond do
      has_list? and has_cards? -> ["list", "cards"]
      has_list? and has_table? -> ["list", "table"]
      has_cards? and has_table? -> ["table", "cards"]
      has_list? -> ["list"]
      has_cards? -> ["cards"]
      has_table? -> ["table"]
      true -> []
    end
  end

  defp restrict_views(from_slots, nil), do: from_slots

  defp restrict_views(from_slots, allowed) when is_list(allowed) do
    allowed = Enum.map(allowed, &to_string/1)
    Enum.filter(from_slots, &(&1 in allowed))
  end

  defp opt_value({_label, value}), do: value
  defp opt_value(value), do: value
  defp opt_label({label, _value}), do: label
  defp opt_label(value), do: to_string(value)
end
