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
  attr(:collapsed, :boolean, default: false, doc: "Initial sidebar collapsed (icon-rail) state.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:brand, required: true, doc: "logo/name, top-left corner")
  slot(:header, doc: "inline context after the brand (breadcrumbs, switchers)")
  slot(:actions, doc: "top-right of the bar (user menu, etc.)")
  slot(:sidebar, required: true, doc: "nav_group / nav_item")
  slot(:inner_block, required: true, doc: "Main content column.")

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
              data-part="sidebar-collapse"
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
  attr(:label, :string, default: nil, doc: "Group heading; hides when the rail is collapsed.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  slot(:inner_block, required: true, doc: "nav_item children in this group.")

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
  attr(:label, :string, required: true, doc: "Nav label; becomes the collapsed-rail tooltip.")

  attr(:icon, :string,
    default: nil,
    doc:
      "Leading icon. A lantern icon-set name (e.g. `chart-bar`), or a host heroicon " <>
        "name (`hero-*`) rendered as a CSS-mask span so an app can keep its own icons."
  )

  attr(:active, :boolean, default: false, doc: "Highlight as the current page.")
  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; renders as a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; renders as a link.")
  attr(:href, :string, default: nil, doc: "External or full-page href; renders as a link.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(phx-click phx-value-id phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

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
      <.nav_item_icon :if={@icon} name={@icon} />
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
      <.nav_item_icon :if={@icon} name={@icon} />
      <span class="lui-nav-item-label">{@label}</span>
    </button>
    """
  end

  # Renders a nav icon by name. A `hero-*` name is a host heroicon, rendered as a
  # CSS-mask span (same convention Phoenix apps use for `<.icon name="hero-…">`),
  # so an app can keep its own icon set without lantern owning every glyph. Any
  # other name resolves against lantern's built-in icon set.
  attr(:name, :string, required: true)

  defp nav_item_icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={["lui-nav-item-icon", "lui-nav-item-icon-mask", @name]} aria-hidden="true" />
    """
  end

  defp nav_item_icon(assigns) do
    ~H"""
    <Icon.icon name={@name} class="lui-nav-item-icon" />
    """
  end
end
