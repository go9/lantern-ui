defmodule LanternUI.Components.Message do
  @moduledoc """
  Chat message rows with optional avatar, metadata, and footer. No Fluxon
  equivalent.

  The component provides visual alignment and tone. The host owns the semantic
  author label and the message content:

      <.message align="end" tone="primary">
        <:avatar><.avatar initials="AL" /></:avatar>
        <:header>You</:header>
        Your message text.
        <:footer>Just now</:footer>
      </.message>

  `align` accepts `start` or `end`, and `tone` accepts `surface` or `primary`.
  """

  use Phoenix.Component
  alias LanternUI.Class

  attr(:align, :string, values: ~w(start end), default: "start")
  attr(:tone, :string, values: ~w(primary surface), default: "surface")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:avatar)
  slot(:header)
  slot(:footer)
  slot(:inner_block)

  def message(assigns) do
    ~H"""
    <div class={Class.merge(["lui-message", @class])} data-part="message" data-align={@align} {@rest}>
      <div :if={@avatar != []} class="lui-message-avatar">{render_slot(@avatar)}</div>
      <div class="lui-message-body">
        <div :if={@header != []} class="lui-message-header">{render_slot(@header)}</div>
        <div class="lui-message-bubble" data-tone={@tone}>{render_slot(@inner_block)}</div>
        <div :if={@footer != []} class="lui-message-footer">{render_slot(@footer)}</div>
      </div>
    </div>
    """
  end
end
