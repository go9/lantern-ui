defmodule LanternUI.Components.Navlist do
  @moduledoc """
  Vertical nav list — heading + links. Mirrors Fluxon's `navlist` / `navheading`
  / `navlink` surface (server-render only, no JS).

      <.navlist heading="Workspace">
        <.navlink navigate="/" active>Dashboard</.navlink>
        <.navlink navigate="/settings" icon="cog">Settings</.navlink>
      </.navlist>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:heading, :string, default: nil, doc: "Optional top heading rendered above the links.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "navlink / navheading children.")

  def navlist(assigns) do
    ~H"""
    <nav class={Class.merge(["lui-navlist", @class])} {@rest}>
      <div :if={@heading} class="lui-navlist-heading">{@heading}</div>
      {render_slot(@inner_block)}
    </nav>
    """
  end

  @doc "A section heading inside a navlist."
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Heading label content.")

  def navheading(assigns) do
    ~H"""
    <div class={Class.merge(["lui-navlist-heading", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A nav list item. Renders a link when given `navigate`/`patch`/`href`, otherwise
  a button (e.g. for `phx-click`).

  Give it `:item` entries to make it a collapsible group of child links (a
  native `<details>`, no JS). The group renders open when `expanded` is set or
  any child is `active`; after mount the browser owns the open state, so a
  LiveView patch does not re-open a group the user closed. A group's own
  `navigate`/`patch`/`href` are ignored: its label is the toggle.

      <.navlink icon="adjustments-horizontal">
        Settings
        <:item navigate="/settings" active={@page == :general}>General</:item>
        <:item navigate="/settings/workspace" active={@page == :workspace}>Workspace</:item>
      </.navlink>
  """
  attr(:expanded, :boolean,
    default: false,
    doc: "Render an `:item` group open even when no child is active."
  )

  attr(:active, :boolean, default: false, doc: "Highlight as the current page.")
  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; renders as a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; renders as a link.")
  attr(:href, :string, default: nil, doc: "External or full-page href; renders as a link.")
  attr(:icon, :string, default: nil, doc: "Leading icon name from the icon set.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(phx-click phx-value-id phx-target method),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  slot(:inner_block, required: true, doc: "Link or button label content.")

  slot :item, doc: "Child links; when present the navlink becomes a collapsible group." do
    attr(:navigate, :string, doc: "LiveView navigate target.")
    attr(:patch, :string, doc: "LiveView patch target.")
    attr(:href, :string, doc: "External or full-page href.")
    attr(:active, :boolean, doc: "Highlight as the current page; opens the group.")
  end

  def navlink(%{item: [_ | _]} = assigns) do
    assigns = assign(assigns, :open, assigns.expanded || Enum.any?(assigns.item, & &1[:active]))

    ~H"""
    <details
      class={Class.merge(["lui-navlink-group", @class])}
      open={@open}
      phx-mounted={JS.ignore_attributes(["open"])}
      {@rest}
    >
      <summary class={["lui-navlink", @active && "lui-navlink-active"]}>
        <Icon.icon :if={@icon} name={@icon} class="lui-navlink-icon" />
        {render_slot(@inner_block)}
        <Icon.icon name="chevron-right" class="lui-navlink-chevron" />
      </summary>
      <div class="lui-navlink-items">
        <.link
          :for={item <- @item}
          class={["lui-navlink", item[:active] && "lui-navlink-active"]}
          navigate={item[:navigate]}
          patch={item[:patch]}
          href={item[:href]}
          aria-current={item[:active] && "page"}
        >
          {render_slot(item)}
        </.link>
      </div>
    </details>
    """
  end

  def navlink(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <.link
      :if={@link?}
      class={Class.merge(["lui-navlink", @active && "lui-navlink-active", @class])}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      aria-current={@active && "page"}
      {@rest}
    >
      <Icon.icon :if={@icon} name={@icon} class="lui-navlink-icon" />
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@link?}
      type="button"
      class={Class.merge(["lui-navlink", @active && "lui-navlink-active", @class])}
      aria-current={@active && "page"}
      {@rest}
    >
      <Icon.icon :if={@icon} name={@icon} class="lui-navlink-icon" />
      {render_slot(@inner_block)}
    </button>
    """
  end
end
