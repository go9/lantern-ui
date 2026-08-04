defmodule LanternUI.Components.MessageScroller do
  @moduledoc """
  Accessible, follow-aware transcript viewport for chat messages. No Fluxon
  equivalent.

  Compose it with `message_scroller_item/1` and `message/1`:

      <.message_scroller id="conversation" label="Conversation" follow={true}>
        <.message_scroller_item id="message-1">
          <.message>Welcome.</.message>
        </.message_scroller_item>
      </.message_scroller>

  `follow` starts at the bottom and follows appended content while the user is
  at the bottom. `peek` controls the context left above a newly appended item
  marked with `scroll_anchor`. `busy` sets `aria-busy` on the log. The
  `LanternMessageScroller` hook observes appended nodes and streamed text
  patches, so the host updates content instead of issuing manual scroll
  commands. The viewport is labelled and the jump-to-latest button becomes
  keyboard reachable when the user scrolls away.

  See the [Chat Kit guide](chat-kit.html) for the composed API and accessibility
  behavior.
  """

  use Phoenix.Component
  alias LanternUI.Class

  attr(:id, :string, required: true)
  attr(:label, :string, default: "Messages")
  attr(:follow, :boolean, default: true, doc: "Follow the latest message and mount at the bottom")
  attr(:peek, :integer, default: 40)
  attr(:busy, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def message_scroller(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-message-scroller", @class])}
      phx-hook="LanternMessageScroller"
      data-part="scroller"
      data-follow={to_string(@follow)}
      data-peek={@peek}
      {@rest}
    >
      <div
        class="lui-message-scroller-viewport"
        data-part="viewport"
        role="region"
        aria-label={@label}
        tabindex="0"
      >
        <div
          class="lui-message-scroller-content"
          data-part="content"
          role="log"
          aria-live="polite"
          aria-relevant="additions"
          aria-busy={to_string(@busy)}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
      <div class="lui-message-scroller-raft" data-part="raft">
        <button
          class="lui-message-scroller-button"
          data-part="jump-latest"
          type="button"
          aria-label="Jump to latest"
          aria-hidden="true"
          tabindex="-1"
          data-active="false"
        >
          <svg
            viewBox="0 0 16 16"
            width="14"
            height="14"
            aria-hidden="true"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
          ><path d="M3 6l5 5 5-5" /></svg>
          <span>Jump to latest</span>
        </button>
      </div>
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:message_id, :string, default: nil)
  attr(:scroll_anchor, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def message_scroller_item(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-message-scroller-item", @class])}
      data-part="item"
      data-message-id={@message_id}
      data-scroll-anchor={@scroll_anchor || nil}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  def message_scroller_button(assigns) do
    ~H"""
    <button
      class="lui-message-scroller-button"
      data-part="jump-latest"
      type="button"
      aria-label="Jump to latest"
      aria-hidden="true"
      tabindex="-1"
      data-active="false"
    >Jump to latest</button>
    """
  end
end
