defmodule LanternUI.QA.ConsistencyLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  @button_sizes ~w(xs sm md lg xl icon-xs icon-sm icon-md icon icon-lg icon-xl)
  @button_variants ~w(solid soft surface outline dashed ghost)
  @segment_cases for size <- ~w(sm md lg), position <- ~w(first middle last), do: {size, position}

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"
    legacy? = params["legacy"] == "1"

    {:ok,
     socket
     |> assign(:theme, theme)
     |> assign(:legacy?, legacy?)
     |> assign(:button_sizes, @button_sizes)
     |> assign(:button_variants, @button_variants)
     |> assign(:segment_cases, @segment_cases)
     |> assign(:rows, for(i <- 1..3, do: %{id: i, name: "Item #{i}"}))
     |> assign(:meta, %{
       flop: %{},
       params: %{
         "filters" => %{"0" => %{"field" => "status", "value" => "open"}},
         "order_by" => ["name"]
       },
       current_page: 1,
       total_pages: 3,
       page_size: 10,
       total_count: 24
     })
     |> assign(:page_title, "Control consistency QA"), layout: false}
  end

  def render(assigns) do
    ~H"""
    <main
      id="qa-consistency"
      class={["lui-consistency-qa", @theme, @legacy? && "legacy"]}
      data-lui-control-scale={@legacy? && "legacy"}
    >
      <style>
        .lui-consistency-qa { min-height:100vh; padding:24px; background:var(--lantern-surface); color:var(--lantern-fg); font-family:var(--lantern-font); }
        .lui-consistency-head { margin:0 auto 20px; max-width:1200px; }
        .lui-consistency-head h1 { margin:0; font-size:24px; }
        .lui-consistency-head p { margin:4px 0 0; color:var(--lantern-fg-muted); font-size:13px; }
        .lui-consistency-section { display:flex; flex-direction:column; gap:12px; max-width:1200px; margin:24px auto; }
        .lui-consistency-section h2 { margin:0; font-size:16px; }
        .lui-consistency-line { display:flex; align-items:center; gap:8px; min-width:0; overflow-x:auto; padding:4px 2px; }
        .lui-consistency-line > [data-qa-size-row] { display:flex; flex:none; align-items:center; gap:8px; }
        .lui-consistency-label { position:sticky; left:0; flex:none; min-width:120px; padding-right:8px; background:var(--lantern-surface); color:var(--lantern-fg-muted); font-size:12px; }
        .lui-consistency-formrow { display:flex; align-items:flex-end; gap:12px; overflow-x:auto; padding:4px 2px; }
        .lui-consistency-formrow > .lui-field { flex:1 0 190px; min-width:170px; }
        .lui-consistency-popover-content { min-width:180px; padding:12px; }
        .lui-consistency-overview { display:grid; grid-template-columns:minmax(0, 1fr) auto; align-items:center; gap:16px; min-height:80px; }
        .lui-consistency-overview-chart { height:64px; position:relative; border-bottom:1px solid var(--lantern-border); background:linear-gradient(160deg, transparent 55%, var(--lantern-accent-soft) 56%); }
        .lui-consistency-overview-stats { display:flex; gap:16px; color:var(--lantern-fg-muted); font-size:12px; }
        @media (max-width:600px) { .lui-consistency-overview { grid-template-columns:1fr; gap:8px; } .lui-consistency-overview-stats { gap:12px; } }
        .lui-consistency-wrap-button { width:150px; height:auto; min-height:var(--lui-control-h-md); white-space:normal; line-height:1.15; }
        .lui-consistency-density { display:flex; align-items:flex-start; gap:12px; overflow-x:auto; padding:4px 2px; }
        .lui-consistency-qa .lui-dt-chromerow { flex-wrap:nowrap; }
        @media (max-width:600px) { .lui-consistency-qa { padding:12px; } .lui-consistency-head h1 { font-size:20px; } }
      </style>
      <header class="lui-consistency-head">
        <h1>Control size consistency</h1>
        <p>
          Kitchen sink · {@theme} theme · {(@legacy? && "legacy compatibility") || "standard scale"}
        </p>
      </header>

      <.page_shell
        id="qa-consistency-shell"
        layout="strip"
        title="Controls"
        breadcrumbs={[%{label: "QA", href: "/qa"}]}
        actions={[
          %{id: "save", label: "Save changes", icon: "check", priority: 1},
          %{id: "export", label: "Export", icon: "arrow-down-tray", priority: 2}
        ]}
      >
        <section class="lui-consistency-section">
          <h2>Buttons · variant × size</h2>
          <div
            :for={variant <- @button_variants}
            class="lui-consistency-line"
            data-qa-row={"button-#{variant}"}
          >
            <span class="lui-consistency-label">{variant}</span>
            <div :for={size <- @button_sizes} class="lui-consistency-items" data-qa-size-row={size}>
              <.button
                :for={button_variant <- [variant]}
                size={size}
                variant={button_variant}
                label={(String.starts_with?(size, "icon") && "Add item") || nil}
                data-qa-control="button"
                data-qa-size={normalize_size(size)}
                aria-label={(String.starts_with?(size, "icon") && "Add item") || nil}
              >
                <.icon :if={String.starts_with?(size, "icon")} name="plus" />
                <span :if={!String.starts_with?(size, "icon")}>{size}</span>
              </.button>
            </div>
          </div>
          <div class="lui-consistency-formrow" data-qa-toolbar-row="textarea-md">
            <.textarea
              id="qa-textarea"
              name="notes"
              label="Notes"
              size="md"
              rows={3}
              value="A multiline control\nwith a second line."
              data-qa-control="textarea"
              data-qa-size="md"
            />
            <.select
              id="qa-multiselect"
              name="tags"
              label="Tags with chips"
              size="md"
              multiple
              searchable
              options={[{"Operations", "ops"}, {"Finance", "finance"}, {"Engineering", "engineering"}]}
              value={["ops", "finance"]}
              data-qa-control="multiselect"
              data-qa-size="md"
            />
          </div>
          <div class="lui-consistency-line" data-qa-toolbar-row="wrapped-button">
            <span class="lui-consistency-label">Wrapping label</span>
            <.button
              class="lui-consistency-wrap-button"
              size="md"
              variant="outline"
              data-qa-control="wrap-button"
              data-qa-size="md"
            >Apply these changes to all selected items</.button>
          </div>

          <div class="lui-consistency-line" data-qa-row="split-buttons">
            <span class="lui-consistency-label">Split actions</span>
            <.button_group>
              <.button size="sm" variant="outline" data-qa-control="split" data-qa-size="sm">Save</.button>
              <.button
                size="sm"
                variant="outline"
                aria-label="More save actions"
                data-qa-control="split"
                data-qa-size="sm"
              ><.icon name="chevron-down" /></.button>
            </.button_group>
            <.menu
              id="qa-consistency-menu"
              label="Actions"
              trigger_class="lui-btn"
              data-qa-control="menu-trigger"
              data-qa-size="md"
            >
              <.menu_item>Duplicate</.menu_item>
              <.menu_item>Archive</.menu_item>
            </.menu>
          </div>
        </section>

        <section class="lui-consistency-section">
          <h2>Form controls</h2>
          <div
            :for={size <- ~w(sm md lg)}
            class="lui-consistency-formrow"
            data-qa-toolbar-row={"form-#{size}"}
          >
            <.input
              id={"qa-input-#{size}"}
              name="name"
              label="Name"
              size={size}
              value="Sample item"
              data-qa-control="input"
              data-qa-size={size}
            />
            <.input
              id={"qa-search-#{size}"}
              name="q"
              label="Search"
              type="search"
              size={size}
              value="Order"
              data-qa-control="search"
              data-qa-size={size}
            >
              <:inner_prefix><.icon name="magnifying-glass" /></:inner_prefix>
            </.input>
            <.select
              id={"qa-select-#{size}"}
              name="status"
              label="Status"
              size={size}
              native
              options={[{"Open", "open"}, {"Closed", "closed"}]}
              data-qa-control="select"
              data-qa-size={size}
            />
            <.select
              id={"qa-rich-select-#{size}"}
              name={"rich_status_#{size}"}
              label="Custom select"
              size={size}
              options={[{"Open", "open"}, {"Closed", "closed"}]}
              data-qa-control="custom-select"
              data-qa-size={size}
            />
            <.autocomplete
              id={"qa-combobox-#{size}"}
              name="owner"
              label="Owner"
              size={size}
              options={~w(Ada Grace Linus)}
              data-qa-control="combobox"
              data-qa-size={size}
            />
          </div>
          <div class="lui-consistency-line" data-qa-toolbar-row="segments-md">
            <span class="lui-consistency-label">Segments / tabs</span>
            <.tabs_list
              id="qa-consistency-tabs"
              active_tab="all"
              size="md"
              data-qa-control="tabs"
              data-qa-size="md"
            >
              <:tab name="all">All items</:tab>
              <:tab name="open">Open</:tab>
              <:tab name="closed">Closed</:tab>
            </.tabs_list>
          </div>
          <section class="lui-consistency-section" aria-label="Segmented control inset geometry">
            <h2>Segmented inset · first / middle / last</h2>
            <div :for={{size, position} <- @segment_cases} class="lui-consistency-line">
              <span class="lui-consistency-label">{size} · {position}</span>
              <.tabs_list
                id={"qa-segment-#{size}-#{position}"}
                active_tab={position}
                size={size}
                data-segment-geometry={"#{size}-#{position}"}
                aria-label={"#{size} segmented #{position}"}
              >
                <:tab name="first">One</:tab>
                <:tab name="middle">Two</:tab>
                <:tab name="last">Three</:tab>
              </.tabs_list>
            </div>
          </section>
          <div
            :for={size <- ~w(sm md lg)}
            class="lui-consistency-line"
            data-qa-toolbar-row={"toggle-#{size}"}
          >
            <span class="lui-consistency-label">Toggle · {size}</span>
            <.switch
              id={"qa-consistency-switch-#{size}"}
              name={"available_#{size}"}
              label="Available"
              size={size}
              checked
              data-qa-control="toggle"
              data-qa-size={size}
            />
          </div>
          <div
            :for={size <- ~w(sm md lg)}
            class="lui-consistency-line"
            data-qa-toolbar-row={"badge-#{size}"}
          >
            <span class="lui-consistency-label">Badge · {size}</span>
            <.badge
              size={size}
              color="success"
              data-qa-control="badge"
              data-qa-size={normalize_size(size)}
            >
              Ready · {size}
            </.badge>
          </div>
          <div class="lui-consistency-line" data-qa-toolbar-row="pills-md">
            <span class="lui-consistency-label">Pills / chips</span>
            <button type="button" class="lui-dt-chip" data-qa-control="pill" data-qa-size="md"><span>Status: open</span><.icon name="x-mark" /></button>
          </div>
          <div
            :for={size <- ~w(xs sm md lg)}
            class="lui-consistency-line"
            data-qa-toolbar-row={"kbd-#{size}"}
          >
            <span class="lui-consistency-label">Keycap · {size}</span>
            <.kbd size={size} data-qa-control="kbd" data-qa-size={normalize_size(size)}>⌘ K</.kbd>
          </div>
        </section>

        <section class="lui-consistency-section">
          <h2>Toolbar and page actions</h2>
          <div class="lui-consistency-line" data-qa-toolbar-row="date-actions-md">
            <span class="lui-consistency-label">Date range / popover</span>
            <.date_range_popover id="qa-consistency-date" preset="30D" trigger_label="Last 30 days" />
            <.popover id="qa-consistency-popover">
              <.button size="md" variant="outline" data-qa-control="popover-trigger" data-qa-size="md">View settings</.button>
              <:content>
                <div class="lui-consistency-popover-content">View settings</div>
              </:content>
            </.popover>
          </div>

          <.action_bar
            id="qa-consistency-action-bar"
            actions={[
              %{id: "apply", label: "Apply", icon: "check", priority: 1},
              %{id: "share", label: "Export", icon: "arrow-down-tray", priority: 2}
            ]}
            data-qa-row="action-bar"
          />

          <.data_table
            id="qa-consistency-table"
            rows={@rows}
            meta={@meta}
            path="/consistency"
            search_field={:name}
            search_placeholder="Search items"
            expandable
          >
            <:overview>
              <div class="lui-consistency-overview" aria-label="Overview chart and statistics">
                <div class="lui-consistency-overview-chart" aria-hidden="true"><span></span></div>
                <div class="lui-consistency-overview-stats">
                  <span>24 results</span><span>Updated today</span>
                </div>
              </div>
            </:overview>
            <:tab label="All" count={24} />
            <:tab label="Open" count={12} filters={[%{field: "status", value: "open"}]} />
            <:filter
              field={:status}
              label="Status"
              options={[{"Open", "open"}, {"Closed", "closed"}]}
            />
            <:col :let={row} label="Item">{row.name}</:col>
          </.data_table>

          <div class="lui-consistency-line" data-qa-toolbar-row="remaining-controls">
            <span class="lui-consistency-label">Settings / toast</span>
            <button type="button" class="lui-chart-settings__trigger" data-qa-control="chart-settings">Chart settings</button>
            <label class="lui-chart-settings__field"><span>Chart range</span><select
              data-qa-control="chart-settings-select"
              data-qa-size="md"
            ><option>30 days</option></select></label>
            <div class="lui-toast-actions">
              <.button size="sm" data-qa-control="toast-button" data-qa-size="sm">Undo</.button>
            </div>
            <button
              type="button"
              class="lui-dt-resetfilters"
              data-qa-control="filter-action"
              data-qa-size="sm"
            >Reset filters</button>
            <button
              type="button"
              class="lui-dt-applyfilters"
              data-qa-control="filter-action"
              data-qa-size="sm"
            >Apply filters</button>
          </div>

          <div
            :for={density <- ~w(compact comfortable)}
            class="lui-consistency-density"
            data-qa-toolbar-row={"density-#{density}"}
            data-lantern-density={density}
          >
            <span class="lui-consistency-label">Table density · {density}</span>
            <.data_table
              id={"qa-consistency-table-#{density}"}
              rows={@rows}
              meta={@meta}
              path="/consistency"
              search_field={:name}
              search_placeholder="Search items"
              expandable
              data-qa-density={density}
            >
              <:tab label="All" count={24} />
              <:filter
                field={:status}
                label="Status"
                options={[{"Open", "open"}, {"Closed", "closed"}]}
              />
              <:col :let={row} label="Item">{row.name}</:col>
            </.data_table>
          </div>

          <.pagination
            id="qa-consistency-pagination"
            meta={@meta}
            patch_fn={fn _ -> "/consistency" end}
            show_page_size
          />
        </section>
      </.page_shell>
    </main>
    """
  end

  defp normalize_size(size) when size in ["xs", "sm", "icon-xs", "icon-sm"], do: "sm"
  defp normalize_size(size) when size in ["lg", "xl", "icon-lg", "icon-xl"], do: "lg"
  defp normalize_size(_), do: "md"
end
