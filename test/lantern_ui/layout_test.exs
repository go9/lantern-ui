defmodule LanternUI.LayoutTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.DataTable
  alias LanternUI.Components.Layout

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "app_shell/1" do
    test "renders the top bar (brand/header/actions), sidebar, main, collapse control + hook" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="app">
            <:brand>BRAND</:brand>
            <:header>CTX</:header>
            <:actions>MENU</:actions>
            <:sidebar>NAV</:sidebar>
            BODY
          </Layout.app_shell>
          """
        end)

      assert html =~ ~s(id="app")
      assert html =~ ~s(phx-hook="LanternSidebar")
      assert html =~ ~s(class="lui-appbar")
      assert html =~ ~s(class="lui-appbar-brand")
      assert html =~ "BRAND"
      assert html =~ ~s(class="lui-appbar-header")
      assert html =~ "CTX"
      assert html =~ ~s(class="lui-appbar-actions")
      assert html =~ "MENU"
      assert html =~ ~s(class="lui-app-sidebar")
      assert html =~ "NAV"
      assert html =~ ~s(class="lui-app-sidebar-foot")
      assert html =~ ~s(data-part="sidebar-collapse")
      assert html =~ ~s(class="lui-app-main")
      assert html =~ "BODY"
    end

    test "renders the mobile drawer trigger, scrim, and the sidebar it controls" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="app">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      assert html =~ ~s(data-part="sidebar-toggle")
      assert html =~ ~s(aria-controls="app-sidebar")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(id="app-sidebar")
      assert html =~ ~s(data-part="sidebar-scrim")
    end

    test "collapsed sets data-collapsed; omitting it does not" do
      collapsed =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="a" collapsed>
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      assert collapsed =~ ~s(data-collapsed)

      open =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="b">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute open =~ ~s(data-collapsed)
    end

    test "compact is opt-in and marks only the opted-in shell" do
      compact =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="compact" compact>
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      assert compact =~ ~s(id="compact")
      assert compact =~ ~s(data-compact)

      default =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="default">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute default =~ ~s(data-compact)
    end

    test "header and actions bars are omitted when their slots are empty" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="c">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute html =~ "lui-appbar-header"
      refute html =~ "lui-appbar-actions"
    end
  end

  describe "page_shell/1" do
    test "renders one breadcrumb row, one hidden h1, one actions region, and content hooks" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.page_shell
            id="inventory"
            title="Inventory"
            breadcrumbs={[%{label: "Workspace", navigate: "/workspace"}]}
            actions={[%{id: "create", label: "Create", priority: 1}]}
          >
            PAGE BODY
          </Layout.page_shell>
          """
        end)

      assert html =~ ~s(data-page-shell)
      assert html =~ ~s(data-page-breadcrumb)
      assert html =~ ~s(data-page-title)
      assert html =~ ~s(data-page-actions)
      assert html =~ ~s(data-page-content)
      assert html =~ ~s(href="/workspace")
      assert html =~ ~s(aria-current="page")
      assert html =~ "Inventory"
      assert html =~ "PAGE BODY"
      assert length(Regex.scan(~r/<h1\b/, html)) == 1
      assert length(Regex.scan(~r/data-page-breadcrumb/, html)) == 1
      assert length(Regex.scan(~r/data-page-actions/, html)) == 1
    end

    test "accepts legacy path keys and omits the empty floating action row" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.page_shell id="empty" title="Empty" breadcrumbs={[%{label: "Legacy", path: "/legacy"}]}>
            Content
          </Layout.page_shell>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, ".lui-breadcrumb-link[href='/legacy']") != []
      assert Floki.find(doc, "h1[data-page-title]") != []
      assert Floki.find(doc, "[data-page-actions]") == []
      assert Floki.find(doc, "[phx-hook='LanternActionBar']") == []
      assert Floki.find(doc, "[data-page-content]") != []
      assert Floki.find(doc, "[data-page-shell][data-page-has-actions]") == []
    end

    test "keeps every column of a wide table rendered inside the page shell" do
      meta = %{
        flop: %{},
        params: %{},
        current_page: 1,
        total_pages: 1,
        page_size: 1,
        total_count: 1
      }

      html =
        render(fn assigns ->
          assigns = assign(assigns, :meta, meta)

          ~H"""
          <Layout.page_shell id="wide-page" title="Wide table">
            <DataTable.data_table
              id="wide-table"
              rows={[%{id: 1, name: "Every row remains available"}]}
              meta={@meta}
              path="/wide"
              show_checkboxes={false}
            >
              <:col :let={row} label="Identifier">{row.id}</:col>
              <:col label="Current status">Ready</:col>
              <:col label="Owner or assignee">Operations</:col>
              <:col label="Location or region">Northwest</:col>
              <:col label="Category and classification">Inventory</:col>
              <:col label="Last synchronized date">2026-10-07</:col>
              <:col label="Visibility and access scope">Workspace</:col>
              <:col label="External reference identifier">REF-0001</:col>
              <:col label="Additional metadata and details">Available</:col>
            </DataTable.data_table>
          </Layout.page_shell>
          """
        end)

      doc = Floki.parse_fragment!(html)
      assert Floki.find(doc, "#wide-table") != []
      assert [wrapper] = Floki.find(doc, "#wide-table .lui-table-wrap")
      assert Floki.attribute(wrapper, "class") |> hd() =~ "lui-table-wrap"
      assert length(Floki.find(wrapper, "thead th")) == 9
      assert Floki.text(Floki.find(wrapper, "thead")) =~ "Additional metadata and details"

      css = File.read!("priv/static/lantern_ui.css")
      assert css =~ ~r/\.lui-table-wrap\s*\{[^}]*overflow-x:\s*auto/s

      assert css =~
               ~r/\.lui-page-shell \[data-page-content\].*?\.lui-th \{\s*position: sticky;\s*top: var\(--lui-shell-h\);/s

      assert css =~ ~r/\.lui-table-wrap \.lui-th,.*?\{\s*top: 0;/s
    end
  end

  describe "nav_item/1" do
    test "renders a link with active state, aria-current, icon and label" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Dashboard" icon="chart-bar" navigate="/dash" active />
          """
        end)

      assert html =~ ~s(href="/dash")
      assert html =~ "lui-nav-item-active"
      assert html =~ ~s(aria-current="page")
      assert html =~ ~s(title="Dashboard")
      assert html =~ ~s(class="lui-nav-item-label")
      assert html =~ "Dashboard"
      assert html =~ "<svg"
    end

    test "renders a button (not a link) when given phx-click" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Act" phx-click="go" />
          """
        end)

      assert html =~ ~s(<button)
      assert html =~ ~s(phx-click="go")
      refute html =~ ~s(href=)
    end

    test "a hero-* icon renders as a host CSS-mask span, not a lantern svg" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Home" icon="hero-home" navigate="/" />
          """
        end)

      # host heroicon: a span carrying its own hero-* class + the mask marker
      assert html =~ "hero-home"
      assert html =~ "lui-nav-item-icon-mask"
      assert html =~ "lui-nav-item-icon"
      # not lantern's inline svg (which has no such glyph anyway)
      refute html =~ "<svg"
    end

    test "a :subnav slot makes it an expandable toggle over a slide panel" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Org Settings" icon="hero-cog-6-tooth" expanded>
            <:subnav>
              <Layout.nav_item label="General" navigate="/s/general" active />
              <Layout.nav_item label="eBay" navigate="/s/ebay" />
            </:subnav>
          </Layout.nav_item>
          """
        end)

      # a toggle button (not a link) carrying the client-side toggle + initial state
      assert html =~ ~s(<button)
      assert html =~ "phx-click"
      assert html =~ ~s(data-expanded)
      assert html =~ "lui-nav-sub-chevron"
      # the slide panel + nested items
      assert html =~ "lui-nav-sub-panel"
      assert html =~ "General"
      assert html =~ "eBay"
      assert html =~ ~s(href="/s/general")
    end

    test "the toggle is marked a disclosure and keeps aria-expanded with it" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Org Settings" icon="hero-cog-6-tooth">
            <:subnav>
              <Layout.nav_item label="General" navigate="/s/general" />
            </:subnav>
          </Layout.nav_item>
          """
        end)

      # The shell's sidebar hook closes the mobile drawer on a nav item, which
      # is right for a destination and wrong for a disclosure — it would shut
      # the menu in the same click that opened the section. This is how the
      # hook tells the two apart, so the parent must carry it.
      assert html =~ ~s(data-part="nav-disclosure")

      # One click moves both the styling hook and what a screen reader is told.
      assert html =~ ~s(data-expanded)
      assert html =~ ~s(aria-expanded)
      assert html =~ ~s(&quot;aria-expanded&quot;,&quot;true&quot;,&quot;false&quot;)
    end

    test "without a :subnav it is a plain link (no toggle/panel)" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Dashboard" navigate="/" />
          """
        end)

      refute html =~ "lui-nav-sub-panel"
      refute html =~ "lui-nav-sub-chevron"
      assert html =~ ~s(href="/")
    end

    test "a lantern icon-set name still renders an inline svg" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_item label="Charts" icon="chart-bar" navigate="/" />
          """
        end)

      assert html =~ "<svg"
      refute html =~ "lui-nav-item-icon-mask"
    end
  end

  describe "nav_group/1" do
    test "renders the group label" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_group label="Workspace">
            <Layout.nav_item label="Home" navigate="/" />
          </Layout.nav_group>
          """
        end)

      assert html =~ "lui-nav-group-label"
      assert html =~ "Workspace"
    end
  end

  describe "breadcrumb slot + breadcrumb_bar/1 + page_header/1" do
    test "app_shell renders the breadcrumb region when the slot is filled" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="bc">
            <:brand>b</:brand>
            <:breadcrumb>TRAIL</:breadcrumb>
            <:sidebar>n</:sidebar>
            BODY
          </Layout.app_shell>
          """
        end)

      assert html =~ "lui-app-breadcrumb"
      assert html =~ "TRAIL"
      assert html =~ "BODY"
    end

    test "app_shell omits the breadcrumb region when the slot is empty" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="nobc">
            <:brand>b</:brand><:sidebar>n</:sidebar>x
          </Layout.app_shell>
          """
        end)

      refute html =~ "lui-app-breadcrumb"
    end

    test "app_shell breadcrumb_actions render on the same bar as the trail" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="bca">
            <:brand>b</:brand>
            <:breadcrumb>TRAIL</:breadcrumb>
            <:breadcrumb_actions>ACT</:breadcrumb_actions>
            <:sidebar>n</:sidebar>
            BODY
          </Layout.app_shell>
          """
        end)

      assert html =~ "lui-app-breadcrumb"
      assert html =~ "lui-app-breadcrumb-trail"
      assert html =~ "lui-app-breadcrumb-actions"
      assert html =~ "TRAIL"
      assert html =~ "ACT"
      # The menu element always renders (narrow bars fold the quick buttons into
      # it), but with nothing past the cap it is marked not-folded and stays
      # hidden at normal width.
      assert html =~ ~s(data-has-folded="false")
    end

    # The folded item renders from the SLOT ATTRS, not the slot body, so an
    # entry whose inner button navigates needs the destination on the slot too.
    # Without forwarding it, such an entry became a menu item with no click
    # target — it rendered, it was clickable, and nothing happened.
    test "a folded navigating action reaches the overflow menu as a real link" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar>
            TRAIL
            <:actions label="One" navigate="/one">One</:actions>
            <:actions label="Two" navigate="/two">Two</:actions>
            <:actions label="Folded" navigate="/folded/target">Folded</:actions>
            <:actions label="Evented" phx-click="do_thing">Evented</:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      # Past :max_inline, so this one is only reachable through the menu.
      assert html =~ ~s(href="/folded/target")
      assert html =~ ~s(data-has-folded="true")

      # Event-based entries still work the way they always did.
      assert html =~ ~s(phx-click="do_thing")
    end

    test "breadcrumb_bar/1 wraps its contents in the same chrome class" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar>TRAIL</Layout.breadcrumb_bar>
          """
        end)

      assert html =~ "lui-app-breadcrumb"
      assert html =~ "TRAIL"
    end

    test "breadcrumb_bar/1 without actions is byte-identical to the trail-only chrome" do
      # Additive contract: unused :actions must not change markup for existing call sites.
      # Mirror the pre-slot component shape exactly (same Class.merge root + inner block).
      expected =
        render(fn assigns ->
          ~H"""
          <div class={LanternUI.Class.merge(["lui-app-breadcrumb", nil])}>
            TRAIL
          </div>
          """
        end)

      actual =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar>TRAIL</Layout.breadcrumb_bar>
          """
        end)

      assert actual == expected
    end

    test "breadcrumb_bar/1 with free-form actions is a flex row: trail left, actions right" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar>
            TRAIL
            <:actions><button type="button">New</button></:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert html =~ ~s(class="lui-app-breadcrumb")
      assert html =~ ~s(class="lui-app-breadcrumb-trail")
      assert html =~ "TRAIL"
      assert html =~ ~s(class="lui-app-breadcrumb-actions")
      assert html =~ "New"
      # single free-form entry: no automatic overflow menu
      # The menu element always renders (narrow bars fold the quick buttons into
      # it), but with nothing past the cap it is marked not-folded and stays
      # hidden at normal width.
      assert html =~ ~s(data-has-folded="false")
      # The menu (and its hook) always mount, since a narrow bar folds the quick
      # buttons into it; only its visibility is conditional.
      assert html =~ ~s(phx-hook="LanternMenu")

      # DOM order: trail before actions (tab order follows)
      trail_at = :binary.match(html, "lui-app-breadcrumb-trail") |> elem(0)
      actions_at = :binary.match(html, "lui-app-breadcrumb-actions") |> elem(0)
      assert trail_at < actions_at
    end

    test "breadcrumb_bar/1 multi-entry actions overflow into an APG menu" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar id="bc-more">
            TRAIL
            <:actions><button type="button">Primary</button></:actions>
            <:actions label="Import" phx-click="import">
              <button type="button" phx-click="import">Import</button>
            </:actions>
            <:actions label="Export" phx-click="export">
              <button type="button" phx-click="export">Export</button>
            </:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert html =~ "lui-app-breadcrumb-action"
      assert html =~ "Primary"
      assert html =~ "Import"
      assert html =~ "Export"
      assert html =~ "lui-app-breadcrumb-overflow"
      assert html =~ ~s(phx-hook="LanternMenu")
      assert html =~ ~s(id="bc-more")
      assert html =~ ~s(data-placement="bottom-end")
      assert html =~ "More actions"
      # overflow menu items carry the slot labels + events (APG menu_item)
      assert html =~ ~s(role="menu")
      assert html =~ ~s(role="menuitem")
      assert html =~ ~s(phx-click="import")
      assert html =~ ~s(phx-click="export")
    end

    test "breadcrumb_bar/1 keeps at most :max_inline entries as quick buttons" do
      # Exactly at the cap: both inline, and no More menu is rendered at all.
      at_cap =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar>
            TRAIL
            <:actions><button type="button">One</button></:actions>
            <:actions label="Two"><button type="button">Two</button></:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert at_cap =~ "One"
      assert at_cap =~ "Two"
      # The menu still renders (mobile needs it) but is hidden while nothing is folded.
      assert at_cap =~ ~s(data-has-folded="false")

      # Past the cap: the third folds into the menu and is reachable there.
      over_cap =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar id="bc-cap">
            TRAIL
            <:actions><button type="button">One</button></:actions>
            <:actions label="Two"><button type="button">Two</button></:actions>
            <:actions label="Three" phx-click="three">
              <button type="button" phx-click="three">Three</button>
            </:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert over_cap =~ "lui-app-breadcrumb-overflow"
      assert over_cap =~ ~s(role="menuitem")
      assert over_cap =~ ~s(phx-click="three")
      assert length(String.split(over_cap, "lui-app-breadcrumb-action\"")) - 1 == 2
    end

    # A folded entry renders from the slot ATTRS; its body is never rendered.
    # A destructive action whose data-confirm lives only on an inner button
    # therefore loses its guard the moment it passes the cap, which is a
    # delete-without-confirmation bug. The attr must survive folding.
    test "breadcrumb_bar/1 carries data-confirm onto a folded destructive entry" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar id="bc-danger">
            TRAIL
            <:actions><button type="button">One</button></:actions>
            <:actions label="Two"><button type="button">Two</button></:actions>
            <:actions label="Delete" phx-click="delete" data-confirm="Delete this? Cannot be undone.">
              <button type="button" phx-click="delete" data-confirm="Delete this? Cannot be undone.">
                Delete
              </button>
            </:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert html =~ ~s(role="menuitem")
      assert html =~ ~s(phx-click="delete")
      assert html =~ ~s(data-confirm="Delete this? Cannot be undone.")
    end

    test "breadcrumb_bar/1 honours an explicit :max_inline" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.breadcrumb_bar id="bc-one" max_inline={1}>
            TRAIL
            <:actions><button type="button">One</button></:actions>
            <:actions label="Two"><button type="button">Two</button></:actions>
          </Layout.breadcrumb_bar>
          """
        end)

      assert html =~ "lui-app-breadcrumb-overflow"
      assert length(String.split(html, "lui-app-breadcrumb-action\"")) - 1 == 1
    end

    test "page_header/1 renders a compact title, description, and actions" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.page_header title="Buckets" description="Object storage.">
            <:actions>NEW</:actions>
          </Layout.page_header>
          """
        end)

      assert html =~ "lui-page-header"
      assert html =~ "lui-page-title"
      assert html =~ "Buckets"
      assert html =~ "Object storage."
      assert html =~ "lui-page-header-actions"
      assert html =~ "NEW"
    end
  end

  describe "breadcrumb actions CSS region" do
    test "stylesheet defines the actions region" do
      css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))

      assert css =~ ~r/\.lui-app-breadcrumb-trail\s*\{/
      assert css =~ ~r/\.lui-app-breadcrumb-actions\s*\{/
      assert css =~ ~r/\.lui-app-breadcrumb-overflow\s*\{/
      assert css =~ "margin-left: auto"
    end

    # The split is fixed, not width-based. The component renders the overflow
    # wrapper only when there are folded actions, and those actions exist
    # nowhere else, so CSS must never hide it: a `display: none` here (as an
    # earlier width-based draft had) makes every action past the cap invisible.
    test "the overflow wrapper is never hidden by CSS" do
      css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))

      refute css =~ ~r/\.lui-app-breadcrumb-overflow\s*\{\s*display:\s*none/

      # Narrow bar: quick buttons hide and their menu entries reveal, so nothing
      # becomes unreachable. Both halves must be present or actions are lost.
      assert css =~ "@container lui-breadcrumb"

      assert css =~
               ~r/\.lui-app-breadcrumb-more-item\[data-inline="true"\]\s*\{\s*display:\s*flex/
    end
  end

  describe "nav_link/1 and the :sidebar_footer slot" do
    test "the footer region only renders when the slot is given" do
      without =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="s">
            <:brand>Acme</:brand>
            <:sidebar>nav</:sidebar>
            main
          </Layout.app_shell>
          """
        end)

      refute without =~ "lui-app-sidebar-links"

      with_footer =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="s">
            <:brand>Acme</:brand>
            <:sidebar>nav</:sidebar>
            <:sidebar_footer>
              <Layout.nav_link label="Terms" href="/terms" />
            </:sidebar_footer>
            main
          </Layout.app_shell>
          """
        end)

      assert with_footer =~ "lui-app-sidebar-links"
      assert with_footer =~ "Terms"
    end

    test "the footer sits above the collapse control, not below it" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.app_shell id="s">
            <:brand>Acme</:brand>
            <:sidebar>nav</:sidebar>
            <:sidebar_footer>
              <Layout.nav_link label="Docs" href="/docs" />
            </:sidebar_footer>
            main
          </Layout.app_shell>
          """
        end)

      assert :binary.match(html, "lui-app-sidebar-links") <
               :binary.match(html, "lui-app-sidebar-foot")
    end

    test "an external link opens in a new tab with a safe rel and an outbound glyph" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_link label="Docs" href="https://example.com" external />
          """
        end)

      assert html =~ ~s(target="_blank")
      assert html =~ "noopener"
      assert html =~ "lui-nav-link-out"
    end

    test "an internal link carries neither target nor the outbound glyph" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.nav_link label="Help" navigate="/help" icon="hero-lifebuoy" />
          """
        end)

      refute html =~ ~s(target="_blank")
      refute html =~ "lui-nav-link-out"
      assert html =~ "hero-lifebuoy"
    end

    # The rail is icon-only and these links are text; leaving them visible
    # spills them past the collapsed width.
    test "the stylesheet hides the footer links on the collapsed rail" do
      css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))

      assert css =~
               ~r/\.lui-app\[data-collapsed\]\s+\.lui-app-sidebar-links\s*\{\s*display:\s*none/

      assert css =~ ~r/\.lui-nav-link\s*\{/
    end
  end

  describe "stack/1" do
    test "renders a vertical stack with a gap scale and class merge" do
      html =
        render(fn assigns ->
          ~H"""
          <Layout.stack gap="lg" class="extra">
            <span>one</span>
            <span>two</span>
          </Layout.stack>
          """
        end)

      assert html =~ "lui-stack"
      assert html =~ ~s(data-gap="lg")
      assert html =~ "extra"
      assert html =~ "one"
    end

    test "the stylesheet gives stacks gaps and rows their inner gaps" do
      css = File.read!(Path.join(:code.priv_dir(:lantern_ui), "static/lantern_ui.css"))

      assert css =~ ~r/\.lui-stack\[data-gap="lg"\]/
      # Link-rendered buttons must never underline.
      assert css =~ ~r/\.lui-btn\s*\{[^}]*text-decoration:\s*none/s
      # Glyph + label pairs sit in flex rows that used to butt together.
      assert css =~ ~r/\.lui-list-row-leading\s*\{[^}]*gap:/s
      assert css =~ ~r/\.lui-property-value\s*\{[^}]*gap:/s
      # Card footers lay status text and actions on one row.
      assert css =~ ~r/\.lui-card-foot\s*\{[^}]*justify-content:\s*space-between/s
    end
  end
end
