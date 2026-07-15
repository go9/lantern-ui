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
  """
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
