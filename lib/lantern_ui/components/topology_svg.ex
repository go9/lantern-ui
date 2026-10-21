defmodule LanternUI.Components.TopologySvg do
  @moduledoc """
  Server-rendered dependency graph: nodes in columns, labelled edges between
  them. Pure SVG, no JS.

      <.topology_svg
        id="topology"
        label="foodfeed resources on staging"
        on_select="pick_node"
        selected={@picked}
        nodes={[
          %{id: "web", label: "web", detail: "Flicker", state: :degraded},
          %{id: "worker", label: "worker", detail: "Flicker"},
          %{id: "primary", label: "primary", detail: "Neon", column: 1},
          %{id: "docs", label: "docs", detail: "not on staging", column: 1, state: :absent}
        ]}
        edges={[
          %{from: "web", to: "primary", label: "DATABASE_URL"},
          %{from: "worker", to: "docs", label: "DOCS_BUCKET"}
        ]}
      />

  The caller owns the graph, the environment lens (re-pass `nodes` with each
  node's `state` for the chosen environment) and the detail panel beside it
  (compose with `inspector`/`split_pane`). A node is `%{id, label}` plus optional
  `detail` (second line), `column` (integer, default 0; columns are laid out
  left to right in ascending order, rows in list order) and `state`: `:ok`
  (default), `:degraded`, `:failed` or `:absent`. Absent nodes are dashed and
  dimmed but stay selectable. An edge is `%{from, to}` plus an optional
  `label`; it must run from a lower column to a higher one and is dashed when
  either end is absent. Empty nodes, duplicate ids, blank labels, unknown edge
  ends or backward edges raise `ArgumentError`; show `empty_state` instead of an
  empty graph.

  Every node is a native `<button>` (`aria-pressed` when selected) that sends
  `on_select` with `phx-value-node`; state is spelled out in words, never colour
  alone. Edges are decorative; a screen-reader list names each connection. The
  graph lives in a focusable, labelled scroll region: it pans by scrollbar,
  touch, wheel or keyboard (no drag-to-pan hook). Nothing animates, including
  under reduced motion. Server patches own selection.
  """
  use Phoenix.Component

  alias LanternUI.Class

  # SVG user units, not CSS lengths.
  @node_w 168
  @node_h 56
  @gap_x 168
  @gap_y 28
  @pad 24
  @bend 60

  @state_words %{ok: nil, degraded: "degraded", failed: "failed", absent: "not present"}

  attr(:id, :string, required: true, doc: "DOM id of the scroll region.")
  attr(:label, :string, required: true, doc: "Accessible name for the graph.")
  attr(:nodes, :list, required: true, doc: "Nonempty `[%{id, label, detail?, column?, state?}]`.")
  attr(:edges, :list, default: [], doc: "`[%{from, to, label?}]`, lower column to higher.")
  attr(:selected, :string, default: nil, doc: "Selected node id; sets `aria-pressed`.")

  attr(:on_select, :string,
    required: true,
    doc: "Event pushed with `phx-value-node` on click/Enter/Space."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root.")
  attr(:rest, :global, doc: "HTML/`phx-*` attrs for the root.")

  def topology_svg(assigns) do
    g = layout!(assigns.nodes, assigns.edges)

    assigns =
      assigns
      |> assign(:g, g)
      |> assign(:node_w, @node_w)
      |> assign(:node_h, @node_h)

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-topology", @class])}
      role="region"
      aria-label={@label}
      tabindex="0"
      {@rest}
    >
      <svg class="lui-topology-svg" width={@g.w} height={@g.h} viewBox={"0 0 #{@g.w} #{@g.h}"}>
        <g
          :for={e <- @g.edges}
          class="lui-topology-edge"
          data-dashed={to_string(e.dashed)}
          aria-hidden="true"
        >
          <path d={e.path} fill="none" />
          <text :if={e.label} x={e.lx} y={e.ly} text-anchor="middle">{e.label}</text>
        </g>
        <foreignObject :for={n <- @g.nodes} x={n.x} y={n.y} width={@node_w} height={@node_h}>
          <button
            type="button"
            class="lui-topology-node"
            data-state={n.state}
            data-node={n.id}
            aria-pressed={to_string(n.id == @selected)}
            phx-click={@on_select}
            phx-value-node={n.id}
          >
            <span class="lui-topology-node-label">{n.label}</span>
            <span :if={n.detail} class="lui-topology-node-detail">{n.detail}</span>
            <span :if={n.word} class="lui-sr-only">, {n.word}</span>
          </button>
        </foreignObject>
      </svg>
      <ul :if={@g.edges != []} class="lui-sr-only" aria-label="Connections">
        <li :for={e <- @g.edges}>{e.from} connects to {e.to}{if e.label, do: " via " <> e.label}</li>
      </ul>
    </div>
    """
  end

  defp layout!([_ | _] = nodes, edges) do
    Enum.each(nodes, &validate_node!/1)
    ids = Enum.map(nodes, & &1.id)
    if length(Enum.uniq(ids)) != length(ids), do: invalid!("duplicate node ids")

    # Dense column index, so column values may be sparse.
    cols = nodes |> Enum.map(&Map.get(&1, :column, 0)) |> Enum.uniq() |> Enum.sort()
    col_index = cols |> Enum.with_index() |> Map.new()

    placed =
      nodes
      |> Enum.group_by(&Map.get(&1, :column, 0))
      |> Enum.flat_map(fn {col, group} ->
        ci = Map.fetch!(col_index, col)

        group
        |> Enum.with_index()
        |> Enum.map(fn {n, row} ->
          state = Map.get(n, :state, :ok)

          %{
            id: n.id,
            label: n.label,
            detail: Map.get(n, :detail),
            state: state,
            word: Map.fetch!(@state_words, state),
            ci: ci,
            x: @pad + ci * (@node_w + @gap_x),
            y: @pad + row * (@node_h + @gap_y)
          }
        end)
      end)

    by_id = Map.new(placed, &{&1.id, &1})
    rows = placed |> Enum.group_by(& &1.ci) |> Map.values() |> Enum.map(&length/1) |> Enum.max()

    %{
      w: @pad * 2 + length(cols) * @node_w + (length(cols) - 1) * @gap_x,
      h: @pad * 2 + rows * @node_h + (rows - 1) * @gap_y,
      nodes: Enum.map(nodes, &Map.fetch!(by_id, &1.id)),
      edges: edges |> Enum.with_index() |> Enum.map(fn {e, i} -> edge!(e, i, by_id) end)
    }
  end

  defp layout!(_, _), do: invalid!("nodes must be a nonempty list")

  defp validate_node!(%{id: id, label: label} = n)
       when is_binary(id) and is_binary(label) do
    if String.trim(id) == "" or String.trim(label) == "", do: invalid!("blank node id or label")
    if not is_map_key(@state_words, Map.get(n, :state, :ok)), do: invalid!("unknown node state")
    if not is_integer(Map.get(n, :column, 0)), do: invalid!("column must be an integer")
  end

  defp validate_node!(_), do: invalid!("node needs string id and label")

  defp edge!(%{from: from, to: to} = e, i, by_id) do
    a = Map.get(by_id, from) || invalid!("edge from unknown node #{inspect(from)}")
    b = Map.get(by_id, to) || invalid!("edge to unknown node #{inspect(to)}")
    if a.ci >= b.ci, do: invalid!("edge #{from} -> #{to} must run to a higher column")

    {x1, y1} = {a.x + @node_w, a.y + @node_h / 2}
    {x2, y2} = {b.x, b.y + @node_h / 2}
    t = if rem(i, 2) == 0, do: 0.3, else: 0.7
    u = 1 - t

    %{
      from: from,
      to: to,
      label: Map.get(e, :label),
      dashed: a.state == :absent or b.state == :absent,
      path: "M #{x1} #{y1} C #{x1 + @bend} #{y1}, #{x2 - @bend} #{y2}, #{x2} #{y2}",
      lx:
        Float.round(
          u * u * u * x1 + 3 * u * u * t * (x1 + @bend) + 3 * u * t * t * (x2 - @bend) +
            t * t * t * x2,
          1
        ),
      ly:
        Float.round(
          u * u * u * y1 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y2 - 6,
          1
        )
    }
  end

  defp edge!(_, _, _), do: invalid!("edge needs from and to")

  defp invalid!(why), do: raise(ArgumentError, "topology_svg: #{why}")
end
