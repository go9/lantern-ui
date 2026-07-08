defmodule LanternUI.Components.Modal do
  @moduledoc """
  Modal dialog on the shared overlay runtime (focus trap, Escape/outside
  dismissal, `prefers-reduced-motion`-aware fade).

      <.modal id="confirm-delete">
        <h2>Delete 3 objects?</h2>
        <p>This cannot be undone.</p>
        <.button phx-click={LanternUI.close_dialog("confirm-delete")}>Cancel</.button>
        <.button variant="solid" color="danger" phx-click="delete">Delete</.button>
      </.modal>

      <.button phx-click={LanternUI.open_dialog("confirm-delete")}>Delete…</.button>

  The API mirrors Fluxon's `modal/1`; open/close from the client with
  `LanternUI.open_dialog/1` / `close_dialog/1` (JS commands) or from the server
  with `LanternUI.open_dialog(socket, id)` / `close_dialog(socket, id)`.
  Animation-tuning attrs (`animation*`) are accepted for Fluxon compatibility;
  the fade duration comes from the `--lantern-duration` token.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true)
  attr(:open, :boolean, default: false, doc: "render already open (server-driven modals)")
  attr(:on_open, Phoenix.LiveView.JS, default: nil)
  attr(:on_close, Phoenix.LiveView.JS, default: nil)
  attr(:class, :any, default: nil)
  attr(:container_class, :any, default: nil)
  attr(:backdrop_class, :any, default: nil)
  attr(:close_on_esc, :boolean, default: true)
  attr(:close_on_outside_click, :boolean, default: true)
  attr(:prevent_closing, :boolean, default: false)
  attr(:hide_close_button, :boolean, default: false)
  attr(:placement, :string, default: "center", values: ~w(center top))
  attr(:animation, :string, default: nil, doc: "accepted for Fluxon compat; fade is token-driven")
  attr(:animation_enter, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:animation_leave, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-modal", @container_class])}
      phx-hook="LanternModal"
      data-open={@open || nil}
      data-close-on-esc={to_string(@close_on_esc and not @prevent_closing)}
      data-close-on-outside={to_string(@close_on_outside_click and not @prevent_closing)}
      data-placement={@placement}
      hidden={!@open}
      {@rest}
    >
      <div class={Class.merge(["lui-modal-backdrop", @backdrop_class])} data-part="backdrop"></div>
      <div
        class={Class.merge(["lui-modal-panel", @class])}
        data-part="panel"
        role="dialog"
        aria-modal="true"
      >
        <button
          :if={!@hide_close_button and !@prevent_closing}
          type="button"
          class="lui-modal-close"
          data-part="close"
          aria-label="Close"
        >
          <LanternUI.Components.Icon.icon name="x-mark" />
        </button>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
