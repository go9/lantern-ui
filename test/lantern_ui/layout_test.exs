defmodule LanternUI.LayoutTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

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
end
