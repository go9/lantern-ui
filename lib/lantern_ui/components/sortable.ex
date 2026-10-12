defmodule LanternUI.Components.Sortable do
  @moduledoc """
  Drag-and-drop between lists (board columns, bins, groups) and the landing
  area at the top of each list.

      <.sortable id="col-12" key="12" group="board" event="drop" reorder>
        <.drop_zone variant="target">Scans land here</.drop_zone>
        <ul>
          <li :for={item <- @items} data-part="item" data-id={item.id} draggable="true"
              data-selected={item.id in @selected}>…</li>
        </ul>
      </.sortable>

  The `LanternSortable` hook pushes `event` with
  `%{"ids" => [...], "from" => from_key, "to" => key, "before_id" => id | nil}`
  when something is dropped:

    * on a `drop_zone/1` (or on the list's empty space): `before_id` is `nil`,
      meaning "add to the end";
    * between rows, when `reorder` is set: `before_id` is the row the items
      land in front of (`nil` after the last row).

  Dragging a row marked `data-selected` drags every selected row of the same
  `group`, in page order. Drops are accepted only from the same `group`.

  The hook only reports the drop; the server owns the order. Drag needs a
  pointer, so give keyboard and touch users another way to move (e.g. a
  "Move to…" menu).
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "Stable hook root id.")
  attr(:key, :string, required: true, doc: "Sent as `to` (and `from` on drags out of this list).")
  attr(:group, :string, default: "default", doc: "Only lists with the same group exchange items.")
  attr(:event, :string, default: "sortable:drop", doc: "LiveView event pushed on drop.")
  attr(:reorder, :boolean, default: false, doc: "Allow drops between rows (`before_id`).")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(phx-target))
  slot(:inner_block, required: true)

  def sortable(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-sortable", @class])}
      phx-hook="LanternSortable"
      data-key={@key}
      data-group={@group}
      data-event={@event}
      data-reorder={@reorder}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The landing area of a `sortable/1` list: dropping here adds to the end.
  `variant="target"` keeps the same dashed drop shape with an accent border
  and fill, for the list that also receives scans.
  """
  attr(:variant, :string, default: "default", values: ~w(default target))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true, doc: "Label, e.g. \"Drop here to add to the end\".")
  slot(:action, doc: "Optional trailing control, e.g. a link that makes this the target.")

  def drop_zone(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-drop-zone", @class])}
      data-part="drop-zone"
      data-variant={@variant}
      {@rest}
    >
      <Icon.icon
        name={if @variant == "target", do: "map-pin", else: "plus"}
        class="lui-drop-zone-icon"
      />
      <span class="lui-drop-zone-label">{render_slot(@inner_block)}</span>
      <span :if={@action != []} class="lui-drop-zone-action">{render_slot(@action)}</span>
    </div>
    """
  end
end
