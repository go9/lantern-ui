defmodule LanternUI.Components.Tree do
  @moduledoc """
  Accessible tree — a WAI-ARIA APG treeview for nested navigation (environments,
  source choosers, file trees). No drag-and-drop, no multi-select.

      <.tree id="envs" label="Environments" current_id={@current_id} expanded_ids={@expanded_ids}
        on_select="tree_select" on_toggle="tree_toggle">
        <.tree_item id="prod" label="Production">
          <.tree_item id="prod-api" label="api" />
          <.tree_item id="prod-web" label="web" />
        </.tree_item>
        <.tree_item id="staging" label="Staging" />
      </.tree>

  The server owns `current_id` and `expanded_ids` (and therefore `aria-current`,
  `aria-expanded`, and which groups are `hidden`). `current_id` is the node the
  app is showing — it stays put while the keyboard moves. The `LanternTree` hook
  owns roving tabindex, `aria-selected` (single-select follows focus), typeahead,
  and the APG keys (Arrows, Home, End, Enter/Space). Expand/collapse and
  activation are pushed to the server so focus can survive a LiveView patch.

  Expand the ancestors of `current_id` yourself; a current node inside a
  collapsed group is not keyboard-reachable until those parents are expanded.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  @tree_key {__MODULE__, :tree}
  @tab_taken_key {__MODULE__, :tab_taken}

  attr(:id, :string, required: true, doc: "Stable tree id. Required; the hook root.")

  attr(:label, :string,
    required: true,
    doc: "Accessible name for the tree (`aria-label`)."
  )

  attr(:current_id, :string,
    default: nil,
    doc: "Id of the node the app is showing (`aria-current`). Distinct from keyboard focus."
  )

  attr(:expanded_ids, :list,
    default: [],
    doc: "Ids of expanded parent nodes. Collapsed groups stay in the DOM with `hidden`."
  )

  attr(:on_select, :string,
    default: nil,
    doc: "Server event pushed on activate (`%{id}`). Enter, Space, or a row click."
  )

  attr(:on_toggle, :string,
    default: nil,
    doc: "Server event pushed on expand/collapse (`%{id, expanded}`)."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the tree root.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "One or more `tree_item/1` children.")

  slot(:empty,
    doc: "Empty state. Rendered as a non-treeitem child; omit when the tree has items."
  )

  @doc """
  Accessible nested tree for environments and source choosers.
  """
  def tree(assigns) do
    Process.put(@tree_key, %{
      current_id: assigns.current_id,
      expanded_ids: MapSet.new(Enum.map(assigns.expanded_ids || [], &to_string/1))
    })

    Process.put(@tab_taken_key, false)

    ~H"""
    <ul
      id={@id}
      class={Class.merge(["lui-tree", @class])}
      role="tree"
      aria-label={@label}
      phx-hook="LanternTree"
      phx-mounted={JS.ignore_attributes(["tabindex", "aria-selected"], to: "[data-part=\"item\"]")}
      data-on-select={@on_select}
      data-on-toggle={@on_toggle}
      {@rest}
    >
      <li :if={@empty != []} role="none" class="lui-tree-empty">
        {render_slot(@empty)}
      </li>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr(:id, :string,
    required: true,
    doc: "Stable node id. Unique within the page; used as the DOM id."
  )

  attr(:label, :string, required: true, doc: "Accessible name; also the typeahead target.")

  attr(:disabled, :boolean,
    default: false,
    doc: "Skip this node in keyboard navigation and activation."
  )

  attr(:state, :string,
    default: nil,
    values: [nil, "error"],
    doc: "Optional visual state. `error` tints the row; keep a text label in `:trailing` too."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the treeitem.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:icon, doc: "Leading glyph before the label.")
  slot(:trailing, doc: "Trailing status, count, or error text.")
  slot(:inner_block, doc: "Child `tree_item/1` nodes. Presence makes this a parent.")

  @doc """
  One node in a tree. Nest `tree_item/1` children to build parentage.
  """
  def tree_item(assigns) do
    ctx = tree_ctx()
    has_children = children?(assigns.inner_block)
    node_id = to_string(assigns.id)
    expanded = has_children and MapSet.member?(ctx.expanded_ids, node_id)
    current = ctx.current_id != nil and to_string(ctx.current_id) == node_id

    tabindex =
      cond do
        current ->
          Process.put(@tab_taken_key, true)
          0

        ctx.current_id ->
          -1

        not Process.get(@tab_taken_key, false) ->
          Process.put(@tab_taken_key, true)
          0

        true ->
          -1
      end

    assigns =
      assign(assigns,
        has_children: has_children,
        expanded: expanded,
        current: current,
        tabindex: tabindex
      )

    ~H"""
    <li
      id={@id}
      class={Class.merge(["lui-tree-item", @class])}
      role="treeitem"
      data-part="item"
      data-id={@id}
      data-label={@label}
      data-state={@state}
      aria-expanded={if @has_children, do: to_string(@expanded)}
      aria-selected={to_string(@tabindex == 0)}
      aria-current={@current && "true"}
      aria-disabled={@disabled && "true"}
      tabindex={@tabindex}
      {@rest}
    >
      <span class="lui-tree-row" data-part="row">
        <span :if={@has_children} class="lui-tree-expander" data-part="expander" aria-hidden="true">
          <Icon.icon name="chevron-right" class="lui-tree-expander-icon" />
        </span>
        <span :if={!@has_children} class="lui-tree-expander-spacer" aria-hidden="true"></span>
        <span :if={@icon != []} class="lui-tree-icon">{render_slot(@icon)}</span>
        <span class="lui-tree-label" data-part="label">{@label}</span>
        <span :if={@trailing != []} class="lui-tree-trailing">{render_slot(@trailing)}</span>
      </span>
      <ul
        :if={@has_children}
        role="group"
        class="lui-tree-group"
        data-part="group"
        hidden={!@expanded}
      >
        {render_slot(@inner_block)}
      </ul>
    </li>
    """
  end

  defp tree_ctx do
    Process.get(@tree_key) || %{current_id: nil, expanded_ids: MapSet.new()}
  end

  # Named slots (:icon, :trailing) still produce a default inner_block whose
  # HEEx static is empty / whitespace. Real children add dynamics, so static
  # has more than one part (length = dynamics + 1).
  defp children?([]), do: false

  defp children?(slots) when is_list(slots) do
    Enum.any?(slots, &slot_children?/1)
  end

  defp slot_children?(%{inner_block: %Phoenix.LiveView.Rendered{static: static}}) do
    parts = List.wrap(static)

    Enum.any?(parts, fn
      bin when is_binary(bin) -> String.trim(bin) != ""
      _ -> true
    end) or length(parts) > 1
  end

  defp slot_children?(%{inner_block: fun}) when is_function(fun), do: true
  defp slot_children?(_), do: true
end
