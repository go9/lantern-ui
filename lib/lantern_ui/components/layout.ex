defmodule LanternUI.Components.Layout do
  @moduledoc """
  App shell — a full-width top bar (brand in the corner + inline context +
  right-side actions) over a fixed, collapsible left sidebar and a main content
  column. Mirrors the shape of a typical product app layout (top bar +
  sidebar), so an app can migrate its Fluxon layout onto it.

      <.app_shell id="app">
        <:brand><.icon name="bolt" /> <span class="lui-brand-name">Acme</span></:brand>
        <:header>…breadcrumb / switchers…</:header>
        <:actions>…user menu…</:actions>
        <:sidebar>
          <.nav_group label="Workspace">
            <.nav_item label="Dashboard" icon="chart-bar" navigate="/" active />
            <.nav_item label="Buckets" icon="cloud" navigate="/buckets" />
          </.nav_group>
        </:sidebar>

        main content…
      </.app_shell>

  The brand sits top-left; `:header` holds inline context (breadcrumbs,
  switchers) and `:actions` the top-right. A collapse control at the sidebar's
  foot toggles the icon rail; the state persists per `id` in localStorage via
  the `LanternSidebar` hook. Narrow viewports drop the sidebar to a strip below
  the bar.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "stable id — the collapse state is persisted per id")
  attr(:collapsed, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:brand, required: true, doc: "logo/name, top-left corner")
  slot(:header, doc: "inline context after the brand (breadcrumbs, switchers)")
  slot(:actions, doc: "top-right of the bar (user menu, etc.)")
  slot(:sidebar, required: true, doc: "nav_group / nav_item")
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-app", @class])}
      phx-hook="LanternSidebar"
      data-collapsed={@collapsed || nil}
      {@rest}
    >
      <header class="lui-appbar">
        <div class="lui-appbar-brand">{render_slot(@brand)}</div>
        <div :if={@header != []} class="lui-appbar-header">{render_slot(@header)}</div>
        <div :if={@actions != []} class="lui-appbar-actions">{render_slot(@actions)}</div>
      </header>

      <div class="lui-app-body">
        <aside class="lui-app-sidebar" data-part="sidebar">
          <div class="lui-app-nav">{render_slot(@sidebar)}</div>
          <div class="lui-app-sidebar-foot">
            <button
              type="button"
              class="lui-collapse-btn"
              data-part="toggle"
              aria-label="Collapse sidebar"
            >
              <Icon.icon name="chevron-left" class="lui-collapse-icon" />
              <span class="lui-collapse-label">Collapse</span>
            </button>
          </div>
        </aside>

        <main class="lui-app-main">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end

  @doc "A labelled group of nav items. The label hides when the rail is collapsed."
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def nav_group(assigns) do
    ~H"""
    <div class={Class.merge(["lui-nav-group", @class])}>
      <div :if={@label} class="lui-nav-group-label">{@label}</div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A sidebar nav item. Renders a link when given `navigate`/`patch`/`href`, or a
  button when given `phx-click`. Collapses to an icon-only rail item (with a
  tooltip) when the sidebar is collapsed.
  """
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:active, :boolean, default: false)
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-click phx-value-id phx-target))

  def nav_item(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <.link
      :if={@link?}
      class={Class.merge(["lui-nav-item", @active && "lui-nav-item-active", @class])}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      title={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <Icon.icon :if={@icon} name={@icon} class="lui-nav-item-icon" />
      <span class="lui-nav-item-label">{@label}</span>
    </.link>
    <button
      :if={!@link?}
      type="button"
      class={Class.merge(["lui-nav-item", @active && "lui-nav-item-active", @class])}
      title={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <Icon.icon :if={@icon} name={@icon} class="lui-nav-item-icon" />
      <span class="lui-nav-item-label">{@label}</span>
    </button>
    """
  end
end
