defmodule LanternUI.Components.CockpitDock do
  @moduledoc """
  Right-hand conversation dock: a `side_panel/1` with a header, a conversation
  list and one open thread. It fetches nothing and opens nothing; the host owns
  `open` and `view`.

      <.side_panel_toggle id="dock-toggle" panel_id="dock" panel_key="cockpit"
        label="Cockpit" open={@dock_open} />

      <.cockpit_dock id="dock" label="Cockpit" open={@dock_open} view={@dock_view}>
        <:header><h2>Cockpit</h2></:header>
        <:list><.list_row title="Needs you" /></:list>
        <:thread><.message_scroller id="dock-messages">…</.message_scroller></:thread>
      </.cockpit_dock>

  Collapse/restore is the existing `side_panel_toggle/1` (stored choice, hook).
  Both views stay mounted and the inactive one is `hidden`, so a draft survives
  a trip to the list. Put the Back button and focus handling in your content.
  Pair with `split_pane/1` for a resizable main/cockpit layout. Static: no
  animation, so nothing changes under reduced motion.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.SidePanel

  attr(:id, :string, required: true, doc: "Root id; part ids derive from it.")
  attr(:label, :string, required: true, doc: "Accessible name of the complementary landmark.")
  attr(:open, :boolean, default: true, doc: "Whether the dock is shown (host-owned).")

  attr(:view, :string,
    values: ~w(list thread),
    default: "list",
    doc: "Visible view; `thread` falls back to the list when no `:thread` slot is given."
  )

  attr(:class, :any, default: nil, doc: "Extra root classes.")
  attr(:rest, :global, doc: "Global attributes passed to the root.")
  slot(:header, doc: "Title and controls, always visible.")
  slot(:list, required: true, doc: "Conversation list.")
  slot(:thread, doc: "The open conversation, e.g. a `message_scroller/1` and composer.")

  @doc "Render a collapsible right dock that switches between a list and a thread."
  def cockpit_dock(assigns) do
    assigns = assign(assigns, :thread_view?, assigns.view == "thread" and assigns.thread != [])

    ~H"""
    <SidePanel.side_panel
      id={@id}
      open={@open}
      aria-label={@label}
      class={Class.merge(["lui-cockpit-dock", @class])}
      data-view={if @thread_view?, do: "thread", else: "list"}
      {@rest}
    >
      <div :if={@header != []} class="lui-cockpit-dock-header" data-part="header">
        {render_slot(@header)}
      </div>
      <div id={"#{@id}-list"} class="lui-cockpit-dock-body" data-part="list" hidden={@thread_view?}>
        {render_slot(@list)}
      </div>
      <div
        :if={@thread != []}
        id={"#{@id}-thread"}
        class="lui-cockpit-dock-body"
        data-part="thread"
        hidden={!@thread_view?}
      >
        {render_slot(@thread)}
      </div>
    </SidePanel.side_panel>
    """
  end
end
