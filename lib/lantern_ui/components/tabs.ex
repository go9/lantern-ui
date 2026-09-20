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

      <.tabs_list id="scope" variant="segmented" size="sm" active_tab={@scope} aria-label="View">
        <:tab name="all" patch={~p"/tickets"}>All</:tab>
        <:tab name="active" patch={~p"/tickets?scope=active"}>Active</:tab>
      </.tabs_list>

  Tabs given `patch`/`navigate`/`href` render as links — the pattern `data_table`
  uses so tab state lives in the URL. A `tabs_list` with an `id` mounts
  `LanternTabs` for arrow-key activation. Pass `role="radiogroup"` when the
  list is a standalone control with no panels.
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

  attr(:id, :string,
    default: nil,
    doc: "Stable id; required to mount `LanternTabs` for arrow-key activation."
  )

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
    doc: "One tab trigger; link via patch/navigate/href or button via phx-click." do
    attr(:name, :string, doc: "Stable tab key; matched against active_tab.")
    attr(:patch, :string, doc: "LiveView patch URL; renders the tab as a link.")
    attr(:navigate, :string, doc: "LiveView navigate URL; renders the tab as a link.")
    attr(:href, :any, doc: "External/full-page href; renders the tab as a link.")
    attr(:disabled, :boolean, doc: "Disable this trigger.")
    attr(:class, :any, doc: "Extra classes on this tab trigger.")
    attr(:"phx-click", :string, doc: "LiveView click event when not using patch/navigate.")
    attr(:"phx-value-tab", :string, doc: "phx-value-tab payload; defaults to name.")

    attr(:"phx-value-segment", :string,
      doc: "Legacy segmented alias payload; sent as params[\"segment\"]."
    )

    attr(:"phx-target", :any, doc: "LiveView target for the click event.")
  end

  slot(:inner_block, doc: "Optional extra content inside the tab list.")

  def tabs_list(assigns) do
    rest = assigns.rest
    radio? = radiogroup?(rest)
    segmented? = assigns.variant == "segmented"
    roving? = segmented? and is_binary(assigns.id)
    has_current? = not is_nil(assigns.active_tab)

    hooked? = is_binary(assigns.id)

    hook =
      Map.get(rest, "phx-hook") ||
        Map.get(rest, :"phx-hook") ||
        if(hooked?, do: "LanternTabs")

    items =
      assigns.tab
      |> Enum.with_index()
      |> Enum.map(fn {tab, index} ->
        active? = tab[:name] == assigns.active_tab

        {tab,
         %{
           active?: active?,
           link?: tab[:patch] || tab[:navigate] || tab[:href],
           tabindex: if(roving?, do: tab_index(active?, index, has_current?)),
           class:
             Class.merge([
               "lui-tab",
               segmented? && "lui-segmented-item",
               active? && "lui-tab-active",
               segmented? && active? && "lui-segmented-item-active",
               tab[:class]
             ]),
           part: if(hooked?, do: if(segmented?, do: "segment", else: "tab")),
           value: if(hooked?, do: tab[:name])
         }}
      end)

    assigns =
      assign(assigns,
        items: items,
        radio?: radio?,
        segmented?: segmented?,
        hook: hook,
        list_role: if(radio?, do: "radiogroup", else: "tablist"),
        rest: Map.drop(rest, ["role", :role, "phx-hook", :"phx-hook"])
      )

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-tabs-list", @segmented? && "lui-segmented", @class])}
      data-variant={@variant}
      data-size={@size}
      role={@list_role}
      phx-hook={@hook}
      {@rest}
    >
      <%= for {tab, meta} <- @items do %>
        <.link
          :if={meta.link?}
          patch={tab[:patch]}
          navigate={tab[:navigate]}
          href={tab[:href]}
          class={meta.class}
          data-part={meta.part}
          data-value={meta.value}
          role={if @radio?, do: "radio", else: "tab"}
          aria-checked={@radio? && to_string(meta.active?)}
          aria-disabled={tab[:disabled] && "true"}
          tabindex={meta.tabindex}
          aria-selected={unless @radio?, do: to_string(meta.active?)}
        >
          {render_slot(tab)}
        </.link>
        <button
          :if={!meta.link?}
          type="button"
          class={meta.class}
          data-part={meta.part}
          data-value={meta.value}
          role={if @radio?, do: "radio", else: "tab"}
          aria-checked={@radio? && to_string(meta.active?)}
          disabled={tab[:disabled]}
          tabindex={meta.tabindex}
          phx-click={tab[:"phx-click"]}
          phx-value-tab={tab[:"phx-value-tab"] || unless(tab[:"phx-value-segment"], do: tab[:name])}
          phx-value-segment={tab[:"phx-value-segment"]}
          phx-target={tab[:"phx-target"]}
          aria-selected={unless @radio?, do: to_string(meta.active?)}
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

  defp radiogroup?(rest) when is_map(rest) do
    Map.get(rest, "role") == "radiogroup" or Map.get(rest, :role) == "radiogroup"
  end

  defp radiogroup?(_), do: false

  defp tab_index(true, _index, _has_current?), do: "0"
  defp tab_index(_active?, 0, false), do: "0"
  defp tab_index(_active?, _index, _has_current?), do: "-1"
end
