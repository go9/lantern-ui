defmodule LanternUI.QA.MatrixLive do
  @moduledoc false
  # One floating component (`?cmp=`) rendered inside one hostile layout
  # context (`?ctx=`). test/qa/run.mjs drives it in headless Chrome and asserts
  # the open panel is anchored to its trigger and not clipped.
  use Phoenix.LiveView
  use LanternUI

  @cmps ~w(select select_search dropdown menu popover tooltip autocomplete date_picker command user_menu)
  @ctxs ~w(plain card card_transform scroll table modal sheet side_panel scroll_area data_table page_shell action_bar app_page_shell app_page_shell_compact edge_br edge_bl sticky tall patch nested)
  def cmps, do: @cmps
  def ctxs, do: @ctxs

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(
       ctx: params["ctx"] || "plain",
       cmp: params["cmp"] || "select",
       n: 0,
       shell_empty?: params["shell_empty"] == "1",
       shell_dismissed_notice?: params["shell_dismissed_notice"] == "1",
       dismissed: false
     )
     |> assign(:page_title, "QA matrix"), layout: false}
  end

  def handle_event("dismiss_notice", _params, socket),
    do: {:noreply, assign(socket, :dismissed, true)}

  def handle_event("bump", _, socket), do: {:noreply, update(socket, :n, &(&1 + 1))}
  def handle_event(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div id="qa-root" style="padding:12px;min-height:100vh;box-sizing:border-box;">
      <button
        :if={@ctx not in ["page_shell", "action_bar"]}
        id="qa-patch"
        type="button"
        phx-click="bump"
        style="font-size:11px"
      >
        patch {@n}
      </button>
      <.ctx
        name={@ctx}
        cmp={@cmp}
        n={@n}
        dismissed={@dismissed}
        shell_empty?={@shell_empty?}
        shell_dismissed_notice?={@shell_dismissed_notice?}
      />
    </div>
    """
  end

  attr(:name, :string, required: true)
  attr(:cmp, :string, required: true)
  attr(:n, :integer, default: 0)
  attr(:dismissed, :boolean, default: false)
  attr(:shell_empty?, :boolean, default: false)
  attr(:shell_dismissed_notice?, :boolean, default: false)

  defp ctx(%{name: "plain"} = assigns) do
    ~H"""
    <div style="padding:120px 0 0 40px"><.sub cmp={@cmp} n={@n} /></div>
    """
  end

  defp ctx(%{name: "card"} = assigns) do
    ~H"""
    <.card title="Hidden overflow" style="width:340px;height:150px;overflow:hidden">
      <div style="padding-top:60px"><.sub cmp={@cmp} n={@n} /></div>
    </.card>
    """
  end

  defp ctx(%{name: "card_transform"} = assigns) do
    ~H"""
    <.card
      title="Transformed card"
      style="width:340px;height:150px;overflow:hidden;transform:translateZ(0);will-change:transform"
    >
      <div style="padding-top:60px"><.sub cmp={@cmp} n={@n} /></div>
    </.card>
    """
  end

  defp ctx(%{name: "scroll"} = assigns) do
    ~H"""
    <div id="qa-scroller" style="width:340px;height:160px;overflow:auto;border:1px solid #ccc">
      <div style="height:90px">above</div>
      <div style="padding:0 8px"><.sub cmp={@cmp} n={@n} /></div>
      <div style="height:300px">below</div>
    </div>
    """
  end

  defp ctx(%{name: "table"} = assigns) do
    ~H"""
    <div style="width:420px;height:170px;overflow:auto">
      <.table>
        <.table_head>
          <:col>Name</:col>
          <:col>Action</:col>
        </.table_head>
        <.table_body>
          <.table_row :for={i <- 1..3}>
            <:cell>row {i}</:cell>
            <:cell>
              <.sub :if={i == 3} cmp={@cmp} n={@n} />
              <span :if={i != 3}>—</span>
            </:cell>
          </.table_row>
        </.table_body>
      </.table>
    </div>
    """
  end

  defp ctx(%{name: "scroll_area"} = assigns) do
    ~H"""
    <.scroll_area label="Scrolled" orientation="both" style="width:340px;max-height:150px">
      <div style="height:80px">above</div>
      <div style="width:520px;padding:0 8px"><.sub cmp={@cmp} n={@n} /></div>
      <div style="height:240px">below</div>
    </.scroll_area>
    """
  end

  defp ctx(%{name: "data_table"} = assigns) do
    assigns =
      assign(assigns,
        rows: for(i <- 1..3, do: %{id: i, name: "row #{i}"}),
        meta: %{
          flop: %{},
          params: %{},
          current_page: 1,
          total_pages: 1,
          page_size: 10,
          total_count: 3
        }
      )

    ~H"""
    <div style="height:240px;display:flex;flex-direction:column;width:560px">
      <.data_table id="qa-dt" rows={@rows} meta={@meta} path="/qa" fill>
        <:col :let={r} label="Name">{r.name}</:col>
        <:col :let={r} label="Action">
          <.sub :if={r.id == 3} cmp={@cmp} n={@n} />
        </:col>
      </.data_table>
    </div>
    """
  end

  defp ctx(%{name: "page_shell"} = assigns) do
    assigns =
      assign(assigns,
        rows:
          for(
            i <- 1..24,
            do: %{id: i, name: "Item #{i}"}
          ),
        meta: %{
          flop: %{},
          params: %{},
          current_page: 1,
          total_pages: 1,
          page_size: 24,
          total_count: 24
        },
        actions:
          if(assigns.shell_empty? or assigns.shell_dismissed_notice?, do: [], else: qa_actions())
      )

    ~H"""
    <div style="background:var(--lantern-surface);color:var(--lantern-fg);">
      <.page_shell
        id="qa-page-shell"
        title="Inventory"
        breadcrumbs={[
          %{label: "Workspace", navigate: "/workspace"},
          %{label: "Items", href: "/items"}
        ]}
        actions={@actions}
        notice={
          if(@shell_empty?,
            do: nil,
            else: %{
              id: "qa-update",
              tone: "info",
              title: "Sync complete",
              body: "All items are up to date."
            }
          )
        }
        dismissed={@dismissed or @shell_dismissed_notice?}
        on_dismiss="dismiss_notice"
      >
        <div class="lui-sr-only" aria-hidden="true">
          <.alert id="qa-default-info-alert" color="info" title="Legacy info alert" />
          <div id="qa-scoped-theme" class="dark">
            <.alert id="qa-scoped-info-alert" color="info" title="Scoped legacy info alert" />
          </div>
        </div>
        <.data_table
          id="qa-shell-table"
          rows={@rows}
          meta={@meta}
          path="/qa"
          show_checkboxes={false}
        >
          <:col :let={row} label="Item">{row.name}</:col>
          <:col :let={row} label="Current status">Ready {row.id}</:col>
          <:col :let={row} label="Owner or assignee">Team {rem(row.id, 4)}</:col>
          <:col :let={row} label="Location or region">Region {rem(row.id, 3)}</:col>
          <:col :let={row} label="Category and classification">Class {rem(row.id, 5)}</:col>
          <:col :let={row} label="Last synchronized date">2026-10-{rem(row.id, 28) + 1}</:col>
          <:col label="Visibility and access scope">Workspace</:col>
          <:col :let={row} label="External reference identifier">REF-00{row.id}</:col>
          <:col :let={row} label="Additional metadata and details">
            More details for item {row.id}
          </:col>
        </.data_table>
      </.page_shell>
    </div>
    """
  end

  defp ctx(%{name: "action_bar"} = assigns) do
    assigns =
      assign(
        assigns,
        :actions,
        qa_actions() ++
          [
            %{
              id: "publish",
              label: "Publish",
              icon: "sparkles",
              priority: 10,
              enabled: false,
              disabled_reason: "Connect a channel first"
            }
          ]
      )

    ~H"""
    <div style="width:100%;min-height:calc(100vh - 1.5rem);padding-top:var(--lui-topline-h);box-sizing:border-box;background:var(--lantern-surface);color:var(--lantern-fg);">
      <.action_bar
        id="qa-action-bar"
        actions={@actions}
        notice={
          %{id: "qa-update", tone: "info", title: "Sync complete", body: "All items are up to date."}
        }
        dismissed={@dismissed}
        on_dismiss="dismiss_notice"
      />
      <div style="height:600px;padding:16px 0;">Scroll content</div>
    </div>
    """
  end

  defp ctx(%{name: name} = assigns) when name in ["app_page_shell", "app_page_shell_compact"] do
    assigns =
      assigns
      |> assign(:compact?, name == "app_page_shell_compact")
      |> assign(:rows, for(i <- 1..32, do: %{id: i, name: "Record #{i}"}))
      |> assign(:meta, %{
        flop: %{},
        params: %{},
        current_page: 1,
        total_pages: 1,
        page_size: 32,
        total_count: 32
      })

    ~H"""
    <.app_shell id={if(@compact?, do: "qa-app-compact", else: "qa-app-default")} compact={@compact?}>
      <:brand>Lantern QA</:brand>
      <:sidebar><.nav_item label="Inventory" navigate="/qa" /></:sidebar>
      <.page_shell
        id="qa-app-page-shell"
        title="Inventory"
        actions={qa_actions()}
        notice={%{id: "sync", tone: "info", title: "Sync complete", body: "All records are current."}}
        style="flex:none"
      >
        <div style="height:180px;flex:none">Content before the table</div>
        <div style="height:320px;min-height:0;display:flex;flex-direction:column;flex:none">
          <.data_table
            id="qa-app-shell-table"
            fill
            rows={@rows}
            meta={@meta}
            path="/qa"
            show_checkboxes={false}
          >
            <:col :let={row} label="Record">{row.name}</:col>
            <:col :let={row} label="Status">Ready {row.id}</:col>
            <:col :let={row} label="Owner">Team {rem(row.id, 4)}</:col>
          </.data_table>
        </div>
        <div style="height:900px;flex:none">Long page content after the table</div>
      </.page_shell>
    </.app_shell>
    """
  end

  defp ctx(%{name: "modal"} = assigns) do
    ~H"""
    <.modal id="qa-modal" open>
      <h2>Dialog</h2>
      <div style="padding:8px 0"><.sub cmp={@cmp} n={@n} /></div>
    </.modal>
    """
  end

  defp ctx(%{name: "sheet"} = assigns) do
    ~H"""
    <.sheet id="qa-sheet" open placement="right" title="Sheet">
      <div style="padding:8px 0"><.sub cmp={@cmp} n={@n} /></div>
    </.sheet>
    """
  end

  defp ctx(%{name: "side_panel"} = assigns) do
    ~H"""
    <div style="display:flex;height:80vh;overflow:hidden;border:1px solid #ccc">
      <div style="flex:1;padding:12px">main</div>
      <.side_panel id="qa-panel" open aria-label="Inspector" style="overflow:auto">
        <div style="padding:12px;width:100%;box-sizing:border-box"><.sub cmp={@cmp} n={@n} /></div>
      </.side_panel>
    </div>
    """
  end

  defp ctx(%{name: "edge_br"} = assigns) do
    ~H"""
    <div style="position:fixed;right:8px;bottom:8px"><.sub cmp={@cmp} n={@n} /></div>
    """
  end

  defp ctx(%{name: "edge_bl"} = assigns) do
    ~H"""
    <div style="position:fixed;left:8px;bottom:8px"><.sub cmp={@cmp} n={@n} /></div>
    """
  end

  defp ctx(%{name: "sticky"} = assigns) do
    ~H"""
    <div style="height:2400px">
      <div style="position:sticky;top:0;z-index:10;overflow:hidden;height:44px;display:flex;justify-content:flex-end;align-items:center;gap:8px;background:#fff;border-bottom:1px solid #ccc;padding:0 12px">
        <.sub cmp={@cmp} n={@n} />
      </div>
      <p style="margin-top:40px">scroll content</p>
    </div>
    """
  end

  defp ctx(%{name: "tall"} = assigns) do
    ~H"""
    <div style="height:2400px;padding-top:500px;padding-left:40px"><.sub cmp={@cmp} n={@n} /></div>
    """
  end

  defp ctx(%{name: "patch"} = assigns) do
    ~H"""
    <div style="padding:120px 0 0 40px">
      <p>patched {@n}</p>
      <.sub cmp={@cmp} n={@n} />
    </div>
    """
  end

  defp ctx(%{name: "nested"} = assigns) do
    ~H"""
    <div style="width:300px;height:120px;overflow:hidden;transform:translateZ(0)">
      <.modal id="qa-modal" open>
        <h2>Dialog</h2>
        <.card title="Inner" style="overflow:hidden;height:150px">
          <div style="padding-top:40px"><.sub cmp={@cmp} n={@n} /></div>
        </.card>
      </.modal>
    </div>
    """
  end

  defp qa_actions do
    [
      %{
        :"phx-click" => "create",
        id: "create",
        label: "Create item",
        icon: "plus",
        priority: 100
      },
      %{
        :"phx-click" => "import",
        id: "import",
        label: "Import",
        icon: "arrow-down-tray",
        priority: 80
      },
      %{
        :"phx-click" => "export",
        id: "export",
        label: "Export",
        icon: "arrow-up-tray",
        priority: 60
      },
      %{
        :"phx-click" => "archive",
        id: "archive",
        label: "Archive",
        icon: "document",
        priority: 20
      },
      %{:"phx-click" => "delete", id: "delete", label: "Delete", icon: "trash", destructive: true}
    ]
  end

  attr(:cmp, :string, required: true)
  attr(:n, :integer, default: 0)

  defp sub(%{cmp: "select"} = assigns) do
    ~H"""
    <.select
      id="qa-sub"
      name="s"
      options={~w(One Two Three Four Five Six Seven Eight Nine Ten)}
      value="One"
    />
    """
  end

  defp sub(%{cmp: "select_search"} = assigns) do
    ~H"""
    <.select
      id="qa-sub"
      name="s"
      searchable
      options={~w(One Two Three Four Five Six Seven Eight Nine Ten)}
      value="One"
    />
    """
  end

  defp sub(%{cmp: "dropdown"} = assigns) do
    ~H"""
    <.dropdown id="qa-sub">
      <:toggle><button type="button" class="lui-btn">Dropdown</button></:toggle>
      <.dropdown_button :for={i <- 1..6}>Item {i}</.dropdown_button>
    </.dropdown>
    """
  end

  defp sub(%{cmp: "menu"} = assigns) do
    ~H"""
    <.menu id="qa-sub" label="Menu">
      <.menu_item :for={i <- 1..6}>Item {i}</.menu_item>
    </.menu>
    """
  end

  defp sub(%{cmp: "user_menu"} = assigns) do
    ~H"""
    <.menu id="qa-sub" label="AO" placement="bottom-end">
      <.menu_item>Profile</.menu_item>
      <.menu_item>Settings</.menu_item>
      <.menu_item>Sign out</.menu_item>
    </.menu>
    """
  end

  defp sub(%{cmp: "popover"} = assigns) do
    ~H"""
    <.popover id="qa-sub">
      <button type="button" class="lui-btn">Popover</button>
      <:content>
        <div style="padding:12px;width:220px">
          Popover body<br />with several<br />lines<br />of text
        </div>
      </:content>
    </.popover>
    """
  end

  defp sub(%{cmp: "tooltip"} = assigns) do
    ~H"""
    <.tooltip id="qa-sub" value="Tooltip text that is fairly long to wrap">
      <button type="button" class="lui-btn">Hover</button>
    </.tooltip>
    """
  end

  defp sub(%{cmp: "autocomplete"} = assigns) do
    ~H"""
    <.autocomplete
      id="qa-sub"
      name="a"
      options={~w(Apple Apricot Avocado Banana Cherry Date Elderberry Fig Grape Kiwi)}
    />
    """
  end

  defp sub(%{cmp: "date_picker"} = assigns) do
    ~H"""
    <.date_picker id="qa-sub" name="d" />
    """
  end

  defp sub(%{cmp: "command"} = assigns) do
    ~H"""
    <button
      id="qa-sub-trigger"
      type="button"
      class="lui-btn"
      phx-click={LanternUI.open_dialog("qa-sub")}
    >Open command</button>
    <.command id="qa-sub">
      <.command_group label="Things">
        <.command_item :for={i <- 1..6} value={i}>Thing {i}</.command_item>
      </.command_group>
    </.command>
    """
  end
end
