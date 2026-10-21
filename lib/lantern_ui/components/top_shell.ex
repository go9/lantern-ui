defmodule LanternUI.Components.TopShell do
  @moduledoc """
  Top-navigation app shell: a sticky top bar (brand, primary nav, a search
  slot, actions) over a content column, with no sidebar. Use it for
  consumer-facing tools where a sidebar is the wrong frame; `app_shell/1`
  stays the sidebar shell for admin and dev tools.

      <.top_shell id="web" width="wide">
        <:brand><img src="/logo.svg" alt="" /> Acme</:brand>
        <:nav>
          <.top_nav_item label="Recipes" navigate="/app" active />
          <.top_nav_item label="Settings" navigate="/app/settings" />
        </:nav>
        <:search>
          <.command_trigger target="cmd-k" label="Search recipes" />
        </:search>
        <:actions>…add button, user menu…</:actions>
        <:subheader>…optional sticky toolbar row…</:subheader>
        main content…
      </.top_shell>

      <.command id="cmd-k">…</.command>

  ## Regions

  The bar is `brand`, `nav` (inline links), `search` (centred, grows), then
  `actions` pushed right. `:subheader` is an optional second sticky row under
  the bar for a page toolbar (filters, view switch). The content column is
  centred and capped by `width`:

    * `"prose"` — a reading column (~46rem)
    * `"wide"` — the default workspace width (~84rem)
    * `"full"` — edge to edge (tables, split panes)

  The bar height is published as `--lantern-top-shell-h` on the root, so a
  sticky rail in the content can sit under it with
  `top: calc(var(--lantern-top-shell-h) + 1rem)`.

  ## Narrow viewports

  Below ~48rem the `nav` links move into a disclosure panel under the bar,
  opened by a menu button (`aria-expanded` / `aria-controls`). It is plain
  `Phoenix.LiveView.JS`, no hook: the button toggles the panel, Escape and a
  click on a link close it. The search slot collapses to its icon.

  ## Pattern sources

  Ported as patterns, not code: shadcn/ui's "stacked" application shells and
  `navigation-menu` / `command` blocks (MIT), Tailwind UI's stacked layouts,
  Radix NavigationMenu semantics (a `nav` landmark of links with
  `aria-current="page"`, not a menubar), and the Linear / NYT Cooking / Notion
  web pattern of a slim top bar with a centred ⌘K search.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "Stable id; child ids derive from it.")

  attr(:width, :string,
    default: "wide",
    values: ~w(prose wide full),
    doc: "Content column cap: `prose`, `wide` (default) or `full`."
  )

  attr(:nav_label, :string, default: "Main", doc: "Accessible name of the nav landmark.")

  attr(:menu_label, :string,
    default: "Menu",
    doc: "Accessible name of the narrow-screen nav button."
  )

  attr(:main_id, :string,
    default: nil,
    doc: "Id for `<main>` (skip-link target). Defaults to `<id>-main`."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root.")
  attr(:main_class, :any, default: nil, doc: "Extra classes merged onto `<main>`.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through to the root.")

  slot(:brand, required: true, doc: "Logo and name, top-left. Usually a link home.")
  slot(:nav, doc: "Primary links: `top_nav_item/1`s.")
  slot(:search, doc: "Centred search, usually `command_trigger/1`.")
  slot(:actions, doc: "Right side: primary action, user menu.")
  slot(:subheader, doc: "Optional sticky toolbar row under the bar.")
  slot(:inner_block, required: true, doc: "Page content.")

  def top_shell(assigns) do
    assigns = assign(assigns, :main_id, assigns.main_id || "#{assigns.id}-main")

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-top", @class])}
      data-width={@width}
      phx-window-keydown={close_nav(@id)}
      phx-key="Escape"
      {@rest}
    >
      <header class="lui-top-bar">
        <div class="lui-top-bar-inner">
          <button
            :if={@nav != []}
            type="button"
            id={"#{@id}-nav-toggle"}
            class="lui-top-nav-toggle"
            data-part="nav-toggle"
            aria-label={@menu_label}
            aria-expanded="false"
            aria-controls={"#{@id}-nav"}
            phx-click={toggle_nav(@id)}
          >
            <Icon.icon name="bars-3" />
          </button>
          <div class="lui-top-brand">{render_slot(@brand)}</div>
          <nav
            :if={@nav != []}
            id={"#{@id}-nav"}
            class="lui-top-nav"
            data-part="nav"
            aria-label={@nav_label}
            phx-click={close_nav(@id)}
          >
            {render_slot(@nav)}
          </nav>
          <div :if={@search != []} class="lui-top-search">{render_slot(@search)}</div>
          <div :if={@actions != []} class="lui-top-actions">{render_slot(@actions)}</div>
        </div>
      </header>
      <div :if={@subheader != []} class="lui-top-sub" data-part="subheader">
        <div class="lui-top-sub-inner">{render_slot(@subheader)}</div>
      </div>
      <main id={@main_id} class={Class.merge(["lui-top-main", @main_class])} tabindex="-1">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  defp toggle_nav(id) do
    JS.toggle_attribute({"data-nav-open", "true"}, to: "##{id}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-nav-toggle")
  end

  defp close_nav(id) do
    JS.remove_attribute("data-nav-open", to: "##{id}")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-nav-toggle")
  end

  @doc """
  A primary link in `top_shell/1`'s `:nav`. `active` marks the current section
  with `aria-current="page"`.
  """
  attr(:label, :string, required: true, doc: "Visible link text.")
  attr(:navigate, :string, default: nil, doc: "LiveView navigate target.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target.")
  attr(:href, :any, default: nil, doc: "Plain href.")
  attr(:active, :boolean, default: false, doc: "Current section.")
  attr(:icon, :string, default: nil, doc: "Optional leading icon.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the link.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def top_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={Class.merge(["lui-top-nav-item", @class])}
      aria-current={@active && "page"}
      data-active={@active || nil}
      {@rest}
    >
      <Icon.icon :if={@icon} name={@icon} />
      <span>{@label}</span>
    </.link>
    """
  end

  @doc """
  A search field look-alike that opens a `command/1` palette. It is a button
  (the palette owns the real input), labelled by `label`, with the hotkey shown
  as a hint. Pair it with `<.command id={target}>`, whose ⌘K hotkey is built in.
  """
  attr(:target, :string, required: true, doc: "Id of the `command/1` palette to open.")
  attr(:label, :string, default: "Search", doc: "Visible placeholder text and accessible name.")
  attr(:shortcut, :string, default: "⌘K", doc: "Hint shown at the end. `nil` hides it.")
  attr(:id, :string, default: nil, doc: "Optional DOM id.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the button.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def command_trigger(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      class={Class.merge(["lui-command-trigger", @class])}
      aria-haspopup="dialog"
      aria-controls={@target}
      phx-click={LanternUI.open_dialog(@target)}
      {@rest}
    >
      <Icon.icon name="magnifying-glass" />
      <span class="lui-command-trigger-label">{@label}</span>
      <kbd :if={@shortcut} class="lui-command-trigger-kbd" aria-hidden="true">{@shortcut}</kbd>
    </button>
    """
  end
end
