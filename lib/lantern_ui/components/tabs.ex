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

  attr(:id, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tabs(assigns) do
    ~H"""
    <div id={@id} class={Class.merge(["lui-tabs", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:active_tab, :string, default: nil)
  attr(:variant, :string, default: "segmented", values: ~w(segmented underline))
  attr(:size, :string, default: "md", values: ~w(sm md))
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true do
    attr(:name, :string)
    attr(:patch, :string)
    attr(:navigate, :string)
    attr(:class, :any)
    attr(:"phx-click", :string)
    attr(:"phx-value-tab", :string)
    attr(:"phx-target", :any)
  end

  slot(:inner_block)

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

  attr(:name, :string, required: true)
  attr(:active, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

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
