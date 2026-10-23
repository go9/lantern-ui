defmodule LanternUI.Components.AgentRail do
  @moduledoc """
  Slim right rail of agent bubbles. Presentational: takes agents, emits events.

      <.agent_rail id="rail" agents={@agents} open={@rail_open}
        on_toggle="toggle_rail" on_select="select_agent" on_ask="ask" on_more="rail_more" />

  Each agent is `%{id, name, initials, status: :working | :waiting | :idle,
  count: 0, kind: :epic | :worker, parent_id: nil}`. Epics sort waiting-on-you,
  then working, then idle; at most `max` show, the rest collapse into a `+N`
  button (so idle epics fall there). Workers render smaller under their epic.
  `variant="top_bar"` renders only the toggle button with the total, for phones.
  The toggle's number is the agent count unless `total` is given (an app may
  pass what needs the person, so the toggle and its badges count one list).
  """
  use Phoenix.Component

  alias LanternUI.Class

  @order %{waiting: 0, working: 1, idle: 2}
  @words %{waiting: "waiting on you", working: "working", idle: "idle"}

  attr(:id, :string, required: true)
  attr(:agents, :list, required: true)
  attr(:open, :boolean, default: true)
  attr(:max, :integer, default: 8)
  attr(:total, :integer, default: nil, doc: "the toggle's number; default the agent count")
  attr(:variant, :string, default: "rail", values: ~w(rail top_bar))
  attr(:on_toggle, :string, default: "toggle_rail")
  attr(:on_select, :string, default: "select_agent")
  attr(:on_ask, :string, default: "ask")
  attr(:on_more, :string, default: "rail_more")
  attr(:target, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def agent_rail(assigns) do
    epics =
      assigns.agents
      |> Enum.filter(&(Map.get(&1, :kind, :epic) == :epic))
      |> Enum.sort_by(&Map.get(@order, &1.status, 2))

    workers = Enum.filter(assigns.agents, &(Map.get(&1, :kind, :epic) == :worker))
    {shown, hidden} = Enum.split(epics, assigns.max)

    assigns =
      assign(assigns,
        shown: shown,
        hidden: length(hidden),
        workers: workers,
        total: assigns.total || length(assigns.agents),
        words: @words
      )

    ~H"""
    <aside
      id={@id}
      class={Class.merge(["lui-agent-rail", @class])}
      data-variant={@variant}
      data-open={to_string(@open)}
      aria-label="Agents"
      {@rest}
    >
      <button
        type="button"
        class="lui-agent-rail-toggle"
        phx-click={@on_toggle}
        phx-target={@target}
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-list"}
      >
        Agents <span class="lui-agent-rail-total">{@total}</span>
      </button>
      <div :if={@open && @variant == "rail"} id={"#{@id}-list"} class="lui-agent-rail-list">
        <div :for={a <- @shown} class="lui-agent-rail-group">
          <.bubble agent={a} words={@words} on_select={@on_select} target={@target} />
          <.bubble
            :for={w <- Enum.filter(@workers, &(&1[:parent_id] == a.id))}
            agent={w}
            words={@words}
            on_select={@on_select}
            target={@target}
            small
          />
        </div>
        <button
          :if={@hidden > 0}
          type="button"
          class="lui-agent-rail-more"
          phx-click={@on_more}
          phx-target={@target}
        >
          +{@hidden}
        </button>
        <button
          type="button"
          class="lui-agent-rail-ask"
          phx-click={@on_ask}
          phx-target={@target}
        >
          Ask
        </button>
      </div>
    </aside>
    """
  end

  attr(:agent, :map, required: true)
  attr(:words, :map, required: true)
  attr(:on_select, :string, required: true)
  attr(:target, :any, default: nil)
  attr(:small, :boolean, default: false)

  defp bubble(assigns) do
    assigns = assign(assigns, count: Map.get(assigns.agent, :count, 0))

    ~H"""
    <button
      type="button"
      class="lui-agent-bubble"
      data-size={if @small, do: "sm", else: "md"}
      data-status={@agent.status}
      phx-click={@on_select}
      phx-value-id={@agent.id}
      phx-target={@target}
      title={@agent.name}
    >
      <span class="lui-agent-bubble-initials" aria-hidden="true">{@agent.initials}</span>
      <span class="lui-agent-bubble-dot" aria-hidden="true"></span>
      <span :if={@count > 0} class="lui-agent-bubble-count" aria-hidden="true">{@count}</span>
      <span class="lui-sr-only">{spoken(@agent, @count, @words)}</span>
    </button>
    """
  end

  defp spoken(agent, count, words) do
    base = "#{agent.name}, #{Map.get(words, agent.status, "idle")}"
    if count > 0, do: "#{base}, #{count} waiting", else: base
  end
end
