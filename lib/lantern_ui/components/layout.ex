defmodule LanternUI.Components.Layout do
  @moduledoc """
  App-shell layout — a fixed, collapsible sidebar beside a main column with an
  optional topbar. The core navigation chrome for a dev-tool or app, and a
  drop-in-shaped replacement for a Fluxon sidebar layout.

      <.sidebar_layout id="app" current="dashboard">
        <:sidebar>
          <.sidebar_header>
            <.icon name="bolt" /> <span class="lui-brand-name">Acme</span>
          </.sidebar_header>
          <.sidebar_nav>
            <.nav_group label="Workspace">
              <.nav_item label="Dashboard" icon="chart-bar" navigate="/" active />
              <.nav_item label="Buckets" icon="archive-box" navigate="/buckets" />
            </.nav_group>
          </.sidebar_nav>
        </:sidebar>

        <:topbar>
          <.sidebar_toggle />
          <.breadcrumb>…</.breadcrumb>
        </:topbar>

        main content…
      </.sidebar_layout>

  The `<.sidebar_toggle>` collapses the sidebar to an icon rail; the state is
  persisted in `localStorage` per `id` via the `LanternSidebar` hook. On narrow
  viewports the sidebar drops to a horizontal strip above the content.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "stable id — the collapse state is persisted per id")

  attr(:collapsed, :boolean,
    default: false,
    doc: "initial collapsed state (before the hook restores)"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:sidebar, required: true)
  slot(:topbar)
  slot(:inner_block, required: true)

  def sidebar_layout(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-shell", @class])}
      phx-hook="LanternSidebar"
      data-collapsed={@collapsed || nil}
      {@rest}
    >
      <aside class="lui-sidebar" data-part="sidebar">
        {render_slot(@sidebar)}
      </aside>
      <div class="lui-shell-main">
        <header :if={@topbar != []} class="lui-topbar">
          {render_slot(@topbar)}
        </header>
        <main class="lui-shell-content">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>
    """
  end

  @doc "Brand/logo area, pinned to the top of the sidebar."
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def sidebar_header(assigns) do
    ~H"""
    <div class={Class.merge(["lui-sidebar-header", @class])}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Scrollable nav region of the sidebar. Wrap `nav_group`/`nav_item` in it."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_nav(assigns) do
    ~H"""
    <nav class={Class.merge(["lui-sidebar-nav", @class])} {@rest}>
      {render_slot(@inner_block)}
    </nav>
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
  button when given `phx-click`. The label collapses to an icon-only rail item
  (with a tooltip) when the sidebar is collapsed.
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

  @doc "Collapse toggle — flips the sidebar between full width and the icon rail."
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      class={Class.merge(["lui-sidebar-toggle", @class])}
      data-part="toggle"
      aria-label="Toggle sidebar"
      {@rest}
    >
      <Icon.icon name="bars-3" class="lui-sidebar-toggle-icon" />
    </button>
    """
  end
end
