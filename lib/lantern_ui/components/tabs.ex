defmodule LanternUI.Components.Tabs do
  @moduledoc """
  Tabs — segmented tab list + panels. Mirrors Fluxon's `tabs`/`tabs_list`/
  `tabs_panel` surface, server-driven: the active tab is an assign, tabs emit
  `phx-click` (or `patch`/`navigate`) and panels render with `active`.

      <.tabs id="orders-tabs">
        <.tabs_list active_tab={@tab}>
          <:tab name="all" phx-click="set_tab" phx-value-tab="all">
            All <.badge size="sm">{@counts.all}</.badge>
          </:tab>
          <:tab name="pending" phx-click="set_tab" phx-value-tab="pending">Pending</:tab>
        </.tabs_list>
        <.tabs_panel name="all" active={@tab == "all"}>…</.tabs_panel>
        <.tabs_panel name="pending" active={@tab == "pending"}>…</.tabs_panel>
      </.tabs>

  Tabs given `patch`/`navigate` render as links — the pattern `data_table`
  uses so tab state lives in the URL.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, default: nil, doc: "Element id for the tabs root.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "tabs_list and tabs_panel children.")

  def tabs(assigns) do
    ~H"""
    <div id={@id} class={Class.merge(["lui-tabs", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:active_tab, :string, default: nil, doc: "Name of the currently selected tab.")

  attr(:variant, :string,
    default: "segmented",
    values: ~w(segmented underline),
    doc: "segmented is pill-style; underline is text tabs."
  )

  attr(:size, :string, default: "md", values: ~w(sm md), doc: "Tab control density.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :tab,
    required: true,
    doc: "One tab trigger; link via patch/navigate or button via phx-click." do
    attr(:name, :string, doc: "Stable tab key; matched against active_tab.")
    attr(:patch, :string, doc: "LiveView patch URL; renders the tab as a link.")
    attr(:navigate, :string, doc: "LiveView navigate URL; renders the tab as a link.")
    attr(:class, :any, doc: "Extra classes on this tab trigger.")
    attr(:"phx-click", :string, doc: "LiveView click event when not using patch/navigate.")
    attr(:"phx-value-tab", :string, doc: "phx-value-tab payload; defaults to name.")
    attr(:"phx-target", :any, doc: "LiveView target for the click event.")
  end

  slot(:inner_block, doc: "Optional extra content inside the tab list.")

  def tabs_list(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-tabs-list", @class])}
      data-variant={@variant}
      data-size={@size}
      role="tablist"
      {@rest}
    >
      <%= for tab <- @tab do %>
        <.link
          :if={tab[:patch] || tab[:navigate]}
          patch={tab[:patch]}
          navigate={tab[:navigate]}
          class={Class.merge(["lui-tab", tab[:name] == @active_tab && "lui-tab-active", tab[:class]])}
          role="tab"
          aria-selected={to_string(tab[:name] == @active_tab)}
        >
          {render_slot(tab)}
        </.link>
        <button
          :if={!(tab[:patch] || tab[:navigate])}
          type="button"
          class={Class.merge(["lui-tab", tab[:name] == @active_tab && "lui-tab-active", tab[:class]])}
          role="tab"
          aria-selected={to_string(tab[:name] == @active_tab)}
          phx-click={tab[:"phx-click"]}
          phx-value-tab={tab[:"phx-value-tab"] || tab[:name]}
          phx-target={tab[:"phx-target"]}
        >
          {render_slot(tab)}
        </button>
      <% end %>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:name, :string, required: true, doc: "Tab key this panel belongs to.")
  attr(:active, :boolean, default: false, doc: "When true, the panel is rendered.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Panel body content.")

  def tabs_panel(assigns) do
    ~H"""
    <div
      :if={@active}
      class={Class.merge(["lui-tabs-panel", @class])}
      role="tabpanel"
      data-tab={@name}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
