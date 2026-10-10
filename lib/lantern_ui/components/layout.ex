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
        <:sidebar_footer>
          <.nav_link label="Documentation" icon="book-open" href="/docs" />
          <.nav_link label="Terms" href="/terms" />
        </:sidebar_footer>

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
  alias LanternUI.Components.ActionBar
  alias LanternUI.Components.Breadcrumb
  alias LanternUI.Components.Icon
  alias LanternUI.Components.Menu
  alias LanternUI.Deprecated
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "stable id — the collapse state is persisted per id")
  attr(:collapsed, :boolean, default: false, doc: "Initial sidebar collapsed (icon-rail) state.")
  attr(:compact, :boolean, default: false, doc: "Opt in to the slim shell topline height.")
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

  slot(:sidebar_header,
    doc:
      "Top of the sidebar, above the nav groups: an org or workspace switcher, for " <>
        "example a dropdown. On the icon rail it stays visible, so the content should " <>
        "collapse to an avatar: style it with `.lui-app[data-collapsed] .your-class`."
  )

  slot(:sidebar, required: true, doc: "nav_group / nav_item")

  slot(:sidebar_footer,
    doc:
      "Persistent links pinned below the nav and above the collapse control " <>
        "(support, docs, legal). Pass `nav_link/1`s. Hidden on the icon rail, " <>
        "where there is no room for text-only links."
  )

  slot(:inner_block, required: true, doc: "Main content column.")

  def app_shell(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-app", @class])}
      phx-hook="LanternSidebar"
      data-collapsed={@collapsed || nil}
      data-compact={@compact || nil}
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
          <div :if={@sidebar_header != []} class="lui-app-sidebar-header">
            {render_slot(@sidebar_header)}
          </div><div class="lui-app-nav">{render_slot(@sidebar)}</div>
          <div :if={@sidebar_footer != []} class="lui-app-sidebar-links">
            {render_slot(@sidebar_footer)}
          </div>
          <div class="lui-app-sidebar-foot">
            <button
              type="button"
              class="lui-collapse-btn"
              data-part="sidebar-collapse"
              data-tooltip="Collapse sidebar"
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

  @doc """
  Page shell with breadcrumb-owned page identity, a visually hidden semantic
  title, a floating action bar, and the page content region.

  Ancestor breadcrumb maps accept `label` and optional `navigate`, `patch`, or
  `href` targets. The current page title is always appended as the last crumb.
  When nested in `app_shell/1`, the sticky breadcrumb and action row sit below
  its fixed app bar. Non-fill data table headers remain in their horizontal
  `.lui-table-wrap` scroll region; they do not stick to the viewport while the
  page scrolls. Fill tables pin their header within the table's own scroll area.

  `layout="strip"` (opt-in) puts the breadcrumb trail, the dismissible notice and
  the actions on ONE solid row under the app bar: the trail on the left, the
  actions on the right. The row is sticky with the same offset as the default
  topline. Below ~40rem of strip width the trail keeps its last two crumbs and
  folds the rest into a `…` menu; the actions keep the same promotion tiers as the
  floating row. The strip is hidden in print. A page with no actions and no notice
  shows the trail alone, with no action region.

      <.app_shell id="app">
        <:brand>Acme</:brand>
        <:sidebar_header>…workspace switcher…</:sidebar_header>
        <:sidebar>…</:sidebar>
        <.page_shell id="inventory" layout="strip" title="Inventory" breadcrumbs={@crumbs} actions={@actions}>
          …
        </.page_shell>
      </.app_shell>
  """
  attr(:id, :string, required: true, doc: "Stable id for the page shell and action hook.")
  attr(:title, :string, required: true, doc: "Current page label and semantic h1 text.")

  attr(:layout, :string,
    default: "stacked",
    values: ~w(stacked strip),
    doc:
      "`\"stacked\"` (default): a breadcrumb topline above a floating action row. " <>
        "`\"strip\"`: one solid row with the trail on the left and the actions on the right."
  )

  attr(:breadcrumbs, :list,
    default: [],
    doc: "Ancestor crumb maps with a label and optional navigation target."
  )

  attr(:home, :string, default: nil, doc: "Optional leading home link destination.")
  attr(:home_label, :string, default: "Home", doc: "Accessible name for the home link.")
  attr(:home_title, :string, default: nil, doc: "Optional native tooltip for the home link.")
  attr(:home_icon, :string, default: nil, doc: "Optional host icon name for the home link.")

  attr(:actions, :list, default: [], doc: "Action descriptor maps rendered by action_bar/1.")
  attr(:notice, :map, default: nil, doc: "Optional dismissible notice descriptor.")
  attr(:dismissed, :boolean, default: false, doc: "Server-owned notice dismissal state.")
  attr(:on_dismiss, :string, default: nil, doc: "LiveView event for notice dismissal.")

  attr(:breadcrumb_label, :string,
    default: "Breadcrumb",
    doc: "Accessible name for the breadcrumb navigation."
  )

  attr(:more_breadcrumbs_label, :string,
    default: "More breadcrumbs",
    doc: "Accessible label for the strip's folded breadcrumb menu (`layout=\"strip\"`)."
  )

  attr(:more_actions_label, :string,
    default: "More actions",
    doc: "Accessible label for the overflow action menu."
  )

  attr(:dismiss_label, :string,
    default: "Dismiss notice",
    doc: "Accessible label for the notice dismiss control."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the page shell.")
  attr(:content_class, :any, default: nil, doc: "Extra classes merged onto the content region.")
  attr(:rest, :global, doc: "Arbitrary HTML and LiveView attributes passed through.")
  slot(:inner_block, required: true, doc: "Page content.")

  def page_shell(assigns) do
    assigns =
      assigns
      |> assign(:ancestor_breadcrumbs, normalize_breadcrumbs(assigns.breadcrumbs))
      |> assign(
        :has_actions?,
        assigns.actions != [] or (not is_nil(assigns.notice) and not assigns.dismissed)
      )

    if assigns.layout == "strip" do
      page_shell_strip(assigns)
    else
      page_shell_stacked(assigns)
    end
  end

  defp page_shell_stacked(assigns) do
    ~H"""
    <section
      id={@id}
      class={Class.merge(["lui-page-shell", @class])}
      data-page-shell
      data-page-has-actions={@has_actions? && "true"}
      {@rest}
    >
      <div class="lui-page-topline" data-page-breadcrumb>
        <Breadcrumb.breadcrumb
          home={@home}
          home_label={@home_label}
          home_title={@home_title}
          home_icon={@home_icon}
          aria_label={@breadcrumb_label}
        >
          <:item
            :for={crumb <- @ancestor_breadcrumbs}
            navigate={crumb.navigate}
            patch={crumb.patch}
            href={crumb.href}
          >
            {crumb.label}
          </:item>
          <:item current>{@title}</:item>
        </Breadcrumb.breadcrumb>
        <h1 class="lui-sr-only" data-page-title>{@title}</h1>
      </div>

      <ActionBar.action_bar
        :if={@has_actions?}
        id={"#{@id}-actions"}
        actions={@actions}
        notice={@notice}
        dismissed={@dismissed}
        on_dismiss={@on_dismiss}
        more_actions_label={@more_actions_label}
        dismiss_label={@dismiss_label}
        data-page-actions
      />

      <div class={Class.merge(["lui-page-content", @content_class])} data-page-content>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  defp page_shell_strip(assigns) do
    ~H"""
    <section
      id={@id}
      class={Class.merge(["lui-page-shell lui-page-shell-strip", @class])}
      data-page-shell
      data-page-layout="strip"
      data-page-has-actions={@has_actions? && "true"}
      {@rest}
    >
      <div class="lui-page-strip" data-page-strip>
        <div class="lui-page-strip-trail" data-page-breadcrumb>
          <Breadcrumb.breadcrumb
            home={@home}
            home_label={@home_label}
            home_title={@home_title}
            home_icon={@home_icon}
            aria_label={@breadcrumb_label}
          >
            <:after_home :if={length(@ancestor_breadcrumbs) > 1}>
              <Menu.menu
                id={"#{@id}-crumbs"}
                placement="bottom-start"
                container_class="lui-page-strip-more"
                trigger_class="lui-page-strip-more-trigger"
              >
                <:trigger>
                  <Icon.icon name="ellipsis-horizontal" />
                  <span class="lui-sr-only">{@more_breadcrumbs_label}</span>
                </:trigger>
                <Menu.menu_item
                  :for={crumb <- Enum.drop(@ancestor_breadcrumbs, -1)}
                  navigate={crumb.navigate}
                  patch={crumb.patch}
                  href={crumb.href}
                >
                  {crumb.label}
                </Menu.menu_item>
              </Menu.menu>
            </:after_home>
            <:item
              :for={crumb <- @ancestor_breadcrumbs}
              navigate={crumb.navigate}
              patch={crumb.patch}
              href={crumb.href}
            >
              {crumb.label}
            </:item>
            <:item current>{@title}</:item>
          </Breadcrumb.breadcrumb>
          <h1 class="lui-sr-only" data-page-title>{@title}</h1>
        </div>

        <ActionBar.action_bar
          :if={@has_actions?}
          id={"#{@id}-actions"}
          class="lui-page-strip-actions"
          actions={@actions}
          notice={@notice}
          dismissed={@dismissed}
          on_dismiss={@on_dismiss}
          more_actions_label={@more_actions_label}
          dismiss_label={@dismiss_label}
          data-page-actions
        />
      </div>

      <div class={Class.merge(["lui-page-content", @content_class])} data-page-content>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  defp normalize_breadcrumbs(breadcrumbs) do
    Enum.map(breadcrumbs, fn crumb ->
      %{
        label: crumb_value(crumb, :label, ""),
        navigate: crumb_value(crumb, :navigate),
        patch: crumb_value(crumb, :patch),
        href: crumb_value(crumb, :href) || crumb_value(crumb, :path)
      }
    end)
  end

  defp crumb_value(crumb, key, default \\ nil) do
    Map.get(crumb, key, Map.get(crumb, Atom.to_string(key), default))
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

  Pass `badge` to hang a count off the item — how many things are waiting behind
  the link. It sits at the end of the row and becomes a dot on the collapsed
  rail, where there is no room for a number and none is needed: the point of a
  count on a rail is that there is something.

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

  attr(:badge, :any,
    default: nil,
    doc:
      "A count or short marker for what is waiting behind this link. Sits at the end " <>
        "of the row, and shrinks to a dot on the collapsed rail. Pass `nil` for none — " <>
        "a badge reading `0` is a badge saying there is nothing to see."
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
        data-tooltip={@label}
        aria-expanded={to_string(@expanded)}
        data-expanded={@expanded || nil}
        data-part="nav-disclosure"
        phx-click={
          JS.toggle_attribute({"data-expanded", ""})
          |> JS.toggle_attribute({"aria-expanded", "true", "false"})
        }
        {@rest}
      >
        <.nav_item_icon :if={@icon} name={@icon} />
        <span class="lui-nav-item-label">{@label}</span>
        <span :if={@badge} class="lui-nav-item-badge">{@badge}</span>
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
      data-tooltip={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <.nav_item_icon :if={@icon} name={@icon} />
      <span class="lui-nav-item-label">{@label}</span>
      <span :if={@badge} class="lui-nav-item-badge">{@badge}</span>
    </.link>
    <button
      :if={@subnav == [] && !@link?}
      type="button"
      class={Class.merge(["lui-nav-item", @active && "lui-nav-item-active", @class])}
      title={@label}
      data-tooltip={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <.nav_item_icon :if={@icon} name={@icon} />
      <span class="lui-nav-item-label">{@label}</span>
      <span :if={@badge} class="lui-nav-item-badge">{@badge}</span>
    </button>
    """
  end

  @doc """
  A quiet link for the shell's `:sidebar_footer` — support, docs, legal.

  Deliberately not a `nav_item`: these are standing links that never represent
  the current page, so they carry no active state and sit at a smaller,
  lower-contrast weight than the nav above them.

      <.nav_link label="Contact us" icon="hero-lifebuoy" navigate="/help" />
      <.nav_link label="Terms" href="/terms" external />
  """
  attr(:label, :string, required: true, doc: "Link text.")

  attr(:icon, :string,
    default: nil,
    doc: "Optional leading icon — a lantern icon-set name or a host `hero-*` name."
  )

  attr(:navigate, :string, default: nil, doc: "LiveView navigate target.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target.")
  attr(:href, :string, default: nil, doc: "Plain href.")

  attr(:external, :boolean,
    default: false,
    doc: "Marks the link as leaving the app: opens in a new tab and shows an outbound glyph."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def nav_link(assigns) do
    ~H"""
    <.link
      class={Class.merge(["lui-nav-link", @class])}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      target={@external && "_blank"}
      rel={@external && "noopener noreferrer"}
      {@rest}
    >
      <.nav_item_icon :if={@icon} name={@icon} />
      <span class="lui-nav-link-label">{@label}</span>
      <Icon.icon :if={@external} name="arrow-right" class="lui-nav-link-out" />
    </.link>
    """
  end

  # Renders a nav icon by name. A `hero-*` name is a host heroicon, rendered as a
  # CSS-mask span (same convention Phoenix apps use for `<.icon name="hero-…">`),
  # so an app can keep its own icon set without lantern owning every glyph. Any
  # other name resolves against lantern's built-in icon set.
  attr(:name, :string, required: true)

  defp nav_item_icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class="lui-nav-item-icon-hitarea" aria-hidden="true">
      <span class={["lui-nav-item-icon", "lui-nav-item-icon-mask", @name]} />
    </span>
    """
  end

  defp nav_item_icon(assigns) do
    ~H"""
    <span class="lui-nav-item-icon-hitarea" aria-hidden="true">
      <Icon.icon name={@name} class="lui-nav-item-icon" />
    </span>
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

  @deprecated "Use page_shell/1 instead. page_header/1 is removed in 1.0."
  def page_header(assigns) do
    Deprecated.warn(:page_header, "<.page_shell>", "1.0")

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

  @doc """
  Vertical stack — one gap for a run of fields, sections, or cards, so a page
  never depends on margin collapsing or host utilities for its rhythm.

      <.stack gap="lg">
        <.page_header title="Settings" />
        <.card title="Profile">…</.card>
        <.card title="Notifications">…</.card>
      </.stack>
  """
  attr(:gap, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Space between children: sm 0.5rem, md 0.75rem, lg 1.25rem."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Stacked children.")

  def stack(assigns) do
    ~H"""
    <div class={Class.merge(["lui-stack", @class])} data-gap={@gap} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
