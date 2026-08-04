defmodule LanternUI.Components.Layout do
  @moduledoc """
  App shell — a full-width top bar (brand + inline context + actions) over a
  fixed, collapsible left sidebar and a main content column. Breadcrumb chrome
  is a first-class layout region (goprint-style sticky trail under the appbar),
  not a per-app one-off.

      <.app_shell id="app">
        <:brand><.icon name="bolt" /> <span class="lui-brand-name">Acme</span></:brand>
        <:header>…switchers…</:header>
        <:actions>…user menu…</:actions>
        <:breadcrumb>
          <.breadcrumb items={@breadcrumbs} />
        </:breadcrumb>
        <:sidebar>
          <.nav_group label="Workspace">
            <.nav_item label="Dashboard" icon="chart-bar" navigate="/" active />
            <.nav_item label="Buckets" icon="cloud" navigate="/buckets" />
          </.nav_group>
        </:sidebar>

        <.page_header title="Buckets" description="Object storage.">
          <:actions><.button>New</.button></:actions>
        </.page_header>
        main content…
      </.app_shell>

  `page_header/1` can also be used on its own. `breadcrumb_bar/1` is the
  standalone breadcrumb region used by `app_shell/1` and can wrap a
  `breadcrumb/1` plus an optional actions slot.

  The brand sits top-left; `:header` is inline context in the appbar (switchers);
  `:breadcrumb` is the compact sticky trail under the appbar; optional
  `:breadcrumb_actions` are right-aligned on that same bar (Linear pattern);
  `:actions` is top-right of the appbar. A collapse control at the sidebar's
  foot toggles the icon rail; the state persists per `id` in localStorage via
  the `LanternSidebar` hook.

  On narrow viewports the sidebar becomes an off-canvas drawer opened by the
  hamburger in the bar, over a scrim. It closes on scrim click, Escape, and on
  tapping a nav item — so a `navigate` link doesn't leave the drawer covering
  the page it just went to.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Menu
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "stable id — the collapse state is persisted per id")
  attr(:collapsed, :boolean, default: false, doc: "Initial sidebar collapsed (icon-rail) state.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:brand, required: true, doc: "logo/name, top-left corner")
  slot(:header, doc: "inline context after the brand (switchers, etc.)")
  slot(:actions, doc: "top-right of the bar (user menu, etc.)")
  slot(:breadcrumb, doc: "compact sticky trail under the appbar (pass <.breadcrumb>)")

  slot :breadcrumb_actions,
    doc:
      "Right-side actions on the breadcrumb bar (same region as breadcrumb_bar/1 :actions). " <>
        "Omitted when empty so existing call sites stay unchanged." do
    attr(:label, :string,
      doc: "Label used when this entry collapses into the breadcrumb overflow menu."
    )

    attr(:"phx-click", :string, doc: "LiveView click event on the overflow menu item.")
    attr(:"phx-value-id", :string, doc: "Optional phx-value-id for the overflow menu item.")
    attr(:"phx-target", :any, doc: "LiveView target for the overflow menu item.")
    attr(:disabled, :boolean, doc: "Disable the overflow menu item.")

    attr(:navigate, :string,
      doc:
        "Destination for a NAVIGATING entry. REQUIRED on any entry whose inline " <>
          "button navigates: a folded item renders from these attrs, not from the " <>
          "slot body, so an entry carrying a path only on its inner button becomes " <>
          "a menu item with no click target and silently does nothing."
    )

    attr(:patch, :string, doc: "Live-patch destination for a folded navigating entry.")
    attr(:href, :any, doc: "Plain href for a folded navigating entry.")

    attr(:"data-confirm", :string,
      doc:
        "Confirmation prompt for the folded menu item. REQUIRED on destructive " <>
          "entries: a folded item renders from these attrs, not from the slot body, " <>
          "so a confirm set only on an inner button is lost once the entry passes " <>
          ":max_inline."
    )
  end

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
        <button
          type="button"
          class="lui-appbar-toggle"
          data-part="sidebar-toggle"
          aria-label="Open navigation"
          aria-expanded="false"
          aria-controls={"#{@id}-sidebar"}
        >
          <Icon.icon name="bars-3" />
        </button>
        <div class="lui-appbar-brand">{render_slot(@brand)}</div>
        <div :if={@header != []} class="lui-appbar-header">{render_slot(@header)}</div>
        <div :if={@actions != []} class="lui-appbar-actions">{render_slot(@actions)}</div>
      </header>

      <div class="lui-app-body">
        <div class="lui-app-scrim" data-part="sidebar-scrim" aria-hidden="true"></div>
        <aside id={"#{@id}-sidebar"} class="lui-app-sidebar" data-part="sidebar">
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
          <.breadcrumb_bar :if={@breadcrumb != [] || @breadcrumb_actions != []}>
            {render_slot(@breadcrumb)}
            <:actions
              :for={action <- @breadcrumb_actions}
              label={action[:label]}
              navigate={action[:navigate]}
              patch={action[:patch]}
              href={action[:href]}
              phx-click={action[:"phx-click"]}
              phx-value-id={action[:"phx-value-id"]}
              phx-target={action[:"phx-target"]}
              data-confirm={action[:"data-confirm"]}
              disabled={action[:disabled]}
            >
              {render_slot(action)}
            </:actions>
          </.breadcrumb_bar>
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

  Pass a `:subnav` slot of nested `nav_item`s to make it an expandable section
  (Fluxon parity): the item becomes a toggle with a chevron, and the subnav
  slides open/closed client-side. Use `expanded` for the initial open state
  (e.g. `expanded={@in_this_section?}`). The subnav is hidden on the icon rail.
  """
  attr(:label, :string, required: true, doc: "Nav label; becomes the collapsed-rail tooltip.")

  attr(:expanded, :boolean,
    default: false,
    doc: "Initial open state when a `:subnav` is present."
  )

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

  slot(:subnav, doc: "Nested nav_items. When present the item becomes an expandable section.")

  def nav_item(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <div :if={@subnav != []} class="lui-nav-sub">
      <button
        type="button"
        class={Class.merge(["lui-nav-item", @active && "lui-nav-item-active", @class])}
        title={@label}
        aria-expanded={to_string(@expanded)}
        data-expanded={@expanded || nil}
        phx-click={JS.toggle_attribute({"data-expanded", ""})}
        {@rest}
      >
        <.nav_item_icon :if={@icon} name={@icon} />
        <span class="lui-nav-item-label">{@label}</span>
        <Icon.icon name="chevron-right" class="lui-nav-sub-chevron" />
      </button>
      <div class="lui-nav-sub-panel">
        <div class="lui-nav-sub-inner">{render_slot(@subnav)}</div>
      </div>
    </div>
    <.link
      :if={@subnav == [] && @link?}
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
      :if={@subnav == [] && !@link?}
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

  @doc """
  Compact sticky breadcrumb region for use outside `app_shell` (or when the
  host app still owns the outer shell). Same chrome `app_shell`'s
  `:breadcrumb` slot renders.

  With an `:actions` slot, the bar is the Linear-style action row: trail on
  the left, actions right-aligned. At most `:max_inline` entries (default 2)
  render as quick buttons; everything after that folds into a More menu (the
  APG `menu/1` — no extra JS).

  The cap is fixed, not width-based. A responsive cap would have to hide an
  inline button that is not in the menu, which makes that action unreachable
  at narrow widths; a fixed split keeps every action reachable at every size.

      <.breadcrumb_bar>
        <.breadcrumb home="/" items={@crumbs} />
        <:actions>
          <.button size="sm">New project</.button>
        </:actions>
      </.breadcrumb_bar>

      <.breadcrumb_bar>
        <.breadcrumb home="/" items={@crumbs} />
        <:actions><.button size="sm">New</.button></:actions>
        <:actions label="Import" phx-click="import">
          <.button size="sm" phx-click="import">Import</.button>
        </:actions>
        <:actions label="Export" phx-click="export">
          <.button size="sm" phx-click="export">Export</.button>
        </:actions>
      </.breadcrumb_bar>

  Without `:actions`, markup is unchanged from the trail-only chrome.
  """
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:id, :string,
    default: nil,
    doc:
      "Stable id for the overflow menu when multi-entry actions collapse; auto-generated when omitted."
  )

  attr(:max_inline, :integer,
    default: 2,
    doc: "How many entries render as quick buttons before the rest fold into the More menu."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Usually a single <.breadcrumb>.")

  slot :actions,
    doc:
      "Right-side actions. The first `:max_inline` entries render as quick " <>
        "buttons; the rest fold into a More menu." do
    attr(:label, :string,
      doc: "Label used for this entry when it is collapsed into the overflow menu."
    )

    attr(:"phx-click", :string, doc: "LiveView click event on the overflow menu item.")
    attr(:"phx-value-id", :string, doc: "Optional phx-value-id for the overflow menu item.")
    attr(:"phx-target", :any, doc: "LiveView target for the overflow menu item.")
    attr(:disabled, :boolean, doc: "Disable the overflow menu item.")

    attr(:navigate, :string,
      doc:
        "Destination for a NAVIGATING entry. REQUIRED on any entry whose inline " <>
          "button navigates: a folded item renders from these attrs, not from the " <>
          "slot body, so an entry carrying a path only on its inner button becomes " <>
          "a menu item with no click target and silently does nothing."
    )

    attr(:patch, :string, doc: "Live-patch destination for a folded navigating entry.")
    attr(:href, :any, doc: "Plain href for a folded navigating entry.")

    attr(:"data-confirm", :string,
      doc:
        "Confirmation prompt for the folded menu item. REQUIRED on destructive " <>
          "entries: a folded item renders from these attrs, not from the slot body, " <>
          "so a confirm set only on an inner button is lost once the entry passes " <>
          ":max_inline."
    )
  end

  # Trail-only clause keeps the original markup byte-identical when :actions is unused.
  def breadcrumb_bar(%{actions: []} = assigns) do
    ~H"""
    <div class={Class.merge(["lui-app-breadcrumb", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def breadcrumb_bar(assigns) do
    inline_count = min(assigns.max_inline, length(assigns.actions))

    assigns =
      assigns
      |> assign(:inline_actions, Enum.take(assigns.actions, inline_count))
      |> assign(:inline_count, inline_count)
      |> assign(:has_folded?, length(assigns.actions) > inline_count)
      |> assign(
        :overflow_id,
        assigns.id || "lui-bc-actions-#{System.unique_integer([:positive])}"
      )

    ~H"""
    <div class={Class.merge(["lui-app-breadcrumb", @class])} {@rest}>
      <div class="lui-app-breadcrumb-trail">{render_slot(@inner_block)}</div>
      <div class="lui-app-breadcrumb-actions">
        <span :for={action <- @inline_actions} class="lui-app-breadcrumb-action">
          {render_slot(action)}
        </span>
        <%!-- The menu always carries EVERY action, not just the folded ones.
              Entries that are quick buttons at normal width are marked
              data-inline and hidden here by CSS; when the bar gets too narrow
              the quick buttons hide and those same entries appear, so nothing
              becomes unreachable at any width and no action is ever visible
              twice at once. --%>
        <div class="lui-app-breadcrumb-overflow" data-has-folded={to_string(@has_folded?)}>
          <Menu.menu
            id={@overflow_id}
            placement="bottom-end"
            container_class="lui-app-breadcrumb-more"
            trigger_class="lui-app-breadcrumb-more-trigger"
          >
            <:trigger>
              <Icon.icon name="ellipsis-horizontal" />
              <span class="lui-sr-only">More actions</span>
            </:trigger>
            <Menu.menu_item
              :for={{action, i} <- Enum.with_index(@actions)}
              class="lui-app-breadcrumb-more-item"
              data-inline={to_string(i < @inline_count)}
              navigate={action[:navigate]}
              patch={action[:patch]}
              href={action[:href]}
              phx-click={action[:"phx-click"]}
              phx-value-id={action[:"phx-value-id"]}
              phx-target={action[:"phx-target"]}
              data-confirm={action[:"data-confirm"]}
              disabled={action[:disabled]}
            >
              {action[:label] || "Action"}
            </Menu.menu_item>
          </Menu.menu>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Page title row — compact, goprint-density. Renders under the breadcrumb bar
  inside main content. Title + optional description + right-side actions.
  """
  attr(:title, :string, default: nil, doc: "Page heading.")
  attr(:description, :string, default: nil, doc: "Optional supporting line under the title.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "Right-side actions (buttons, menus).")
  slot(:inner_block, doc: "Optional body under the title row (rarely needed).")

  def page_header(assigns) do
    ~H"""
    <div class={Class.merge(["lui-page-header", @class])} {@rest}>
      <div :if={@title} class="lui-page-header-row">
        <div class="lui-page-header-text">
          <h1 class="lui-page-title">{@title}</h1>
          <p :if={@description} class="lui-page-desc">{@description}</p>
        </div>
        <div :if={@actions != []} class="lui-page-header-actions">
          {render_slot(@actions)}
        </div>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
