defmodule LanternUI.Components.ResourceList do
  @moduledoc """
  Resource list: a simple index of resources (projects, apps, databases,
  buckets). No Fluxon equivalent. Pure presentational server render; no JS hook.

      <.resource_list layout={:list}>
        <.resource_list_item
          :for={p <- @projects}
          navigate={"/projects/" <> p.slug}
          title={p.name}
          subtitle={p.slug}
        >
          <.badge>Setup required</.badge>
          <.badge>4 configs</.badge>
        </.resource_list_item>
      </.resource_list>

  Prefer this over `data_table` when the page lists a handful of resources and
  does not need column headers, sort, pagination, or selection. The host owns
  any list/grid toggle; pass `layout={:list}` or `layout={:grid}`. Search,
  sort, and pagination stay out of scope on purpose.

  The root is an unordered list (`<ul>`); each item is an `<li>`. `layout`
  lands as `data-layout` and CSS switches between full-width rows (hairline
  separators between items) and a card grid. When `navigate`, `patch`, or
  `href` is set, the whole row is the link hit target. The optional
  `inner_block` holds trailing meta (badges, counts): right-aligned in list
  layout, stacked under the title in grid layout.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @layouts [:list, :grid]

  attr(:layout, :atom,
    values: @layouts,
    default: :list,
    doc: "List (full-width rows) or grid (card layout). Rendered as data-layout."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "One or more `resource_list_item/1` children.")

  def resource_list(assigns) do
    ~H"""
    <ul class={Class.merge(["lui-resource-list", @class])} data-layout={@layout} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr(:title, :string, required: true, doc: "Primary line (resource name).")

  attr(:subtitle, :string,
    default: nil,
    doc: "Optional secondary line (e.g. a slug). Class only; face is CSS-owned."
  )

  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; whole row is a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; whole row is a link.")
  attr(:href, :string, default: nil, doc: "External or full-page href; whole row is a link.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the item root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Trailing meta (badges, counts).")

  def resource_list_item(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <li class={Class.merge(["lui-resource-list-item", @class])} {@rest}>
      <.link
        :if={@link?}
        class="lui-resource-list-row"
        navigate={@navigate}
        patch={@patch}
        href={@href}
      >
        <div class="lui-resource-list-main">
          <span class="lui-resource-list-title">{@title}</span>
          <span :if={@subtitle} class="lui-resource-list-subtitle">{@subtitle}</span>
        </div>
        <div :if={@inner_block != []} class="lui-resource-list-meta">
          {render_slot(@inner_block)}
        </div>
      </.link>
      <div :if={!@link?} class="lui-resource-list-row">
        <div class="lui-resource-list-main">
          <span class="lui-resource-list-title">{@title}</span>
          <span :if={@subtitle} class="lui-resource-list-subtitle">{@subtitle}</span>
        </div>
        <div :if={@inner_block != []} class="lui-resource-list-meta">
          {render_slot(@inner_block)}
        </div>
      </div>
    </li>
    """
  end
end
