defmodule LanternUI.Components.Passage do
  @moduledoc """
  A commentable passage of prose with a stable id and its comment counts.

      <.passage id="plan-p3" open={2} resolved={1} on_comment="comment_passage">
        The migration runs before the deploy.
      </.passage>

  The Comment button sends `phx-click` with `phx-value-passage={id}`. Omit
  `on_comment` for a read-only passage that still shows its counts.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true, doc: "Stable passage id; also the `passage` event value.")
  attr(:open, :integer, default: 0)
  attr(:resolved, :integer, default: 0)
  attr(:on_comment, :string, default: nil)
  attr(:target, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def passage(assigns) do
    ~H"""
    <div id={@id} class={Class.merge(["lui-passage", @class])} data-passage-id={@id} {@rest}>
      <div class="lui-passage-body">{render_slot(@inner_block)}</div>
      <button
        :if={@on_comment}
        type="button"
        class="lui-passage-comment"
        phx-click={@on_comment}
        phx-value-passage={@id}
        phx-target={@target}
      >
        Comment
        <span :if={@open + @resolved > 0} class="lui-passage-count">
          {@open} open, {@resolved} resolved
        </span>
      </button>
      <span :if={!@on_comment && @open + @resolved > 0} class="lui-passage-count">
        {@open} open, {@resolved} resolved
      </span>
    </div>
    """
  end
end
