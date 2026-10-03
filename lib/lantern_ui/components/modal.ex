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

  The dialog is Zag-driven (a `@zag-js/dialog` state machine, loaded on
  demand): the hook root carries `data-zag` plus `data-scope="dialog"` /
  `data-part` anatomy, and Zag owns open state, focus trap + return, scroll
  lock, Escape/outside dismissal, and initial focus. Styling stays `lui-*`
  tokens. The server owns `open` via `data-open` (a patch asserting it
  re-opens, withdrawing it closes); `controlled` makes the server value
  strict truth with `on_change` fan-out.

  Hand-rolled `LanternModal` roots without `data-zag` keep the legacy hook
  behavior, so existing `open_dialog/close_dialog` call sites keep working;
  new markup should use this component.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "Stable DOM id used by open_dialog/close_dialog.")
  attr(:open, :boolean, default: false, doc: "render already open (server-driven modals)")
  attr(:on_open, Phoenix.LiveView.JS, default: nil, doc: "JS command run when the modal opens.")
  attr(:on_close, Phoenix.LiveView.JS, default: nil, doc: "JS command run when the modal closes.")
  attr(:class, :any, default: nil, doc: "Extra classes on the dialog panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the overlay root.")
  attr(:backdrop_class, :any, default: nil, doc: "Extra classes on the dimmed backdrop.")
  attr(:close_on_esc, :boolean, default: true, doc: "Close when Escape is pressed.")

  attr(:close_on_outside_click, :boolean,
    default: true,
    doc: "Close when the backdrop is clicked."
  )

  attr(:prevent_closing, :boolean, default: false, doc: "Block Escape and outside-click close.")
  attr(:hide_close_button, :boolean, default: false, doc: "Hide the built-in close control.")
  attr(:role, :string, default: "dialog", doc: "ARIA role for the dialog panel.")
  attr(:aria_label, :string, default: nil, doc: "Accessible name for the dialog panel.")
  attr(:aria_labelledby, :string, default: nil, doc: "Id of the dialog title element.")
  attr(:aria_describedby, :string, default: nil, doc: "Id of the dialog description element.")

  attr(:initial_focus, :string,
    default: nil,
    doc: "Selector for the element or region that receives focus when opened."
  )

  attr(:placement, :string,
    default: "center",
    values: ~w(center top),
    doc: "Vertical panel placement within the viewport."
  )

  attr(:animation, :string, default: nil, doc: "accepted for Fluxon compat; fade is token-driven")
  attr(:animation_enter, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:animation_leave, :string, default: nil, doc: "accepted for Fluxon compat")

  attr(:controlled, :boolean,
    default: false,
    doc: "Strict server-driven open state: `open` is truth, patches flow into the machine."
  )

  attr(:on_change, :string,
    default: nil,
    doc: "Server event pushed on open change (`lantern:dialog:open/close` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on open change."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Dialog body content.")

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-modal", @container_class])}
      phx-hook="LanternModal"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"dialog\"]")}
      data-zag
      data-role={@role}
      data-open={@open || nil}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: to_string(@open)}
      data-default-value={unless @controlled, do: to_string(@open)}
      data-close-on-esc={to_string(@close_on_esc and not @prevent_closing)}
      data-close-on-outside={to_string(@close_on_outside_click and not @prevent_closing)}
      data-prevent-closing={@prevent_closing || nil}
      data-on-open={@on_open}
      data-on-close={@on_close}
      data-title-id={@aria_labelledby}
      data-description-id={@aria_describedby}
      data-initial-focus={@initial_focus}
      data-placement={@placement}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      hidden={!@open}
      {@rest}
    >
      <div
        class={Class.merge(["lui-modal-backdrop", @backdrop_class])}
        data-scope="dialog"
        data-part="backdrop"
      >
      </div>
      <div data-scope="dialog" data-part="positioner">
        <div
          class={Class.merge(["lui-modal-panel", @class])}
          data-scope="dialog"
          data-part="content"
          role={@role}
          aria-modal="true"
          aria-label={@aria_label}
          aria-labelledby={@aria_labelledby}
          aria-describedby={@aria_describedby}
        >
          <button
            :if={!@hide_close_button and !@prevent_closing}
            type="button"
            class="lui-modal-close"
            data-scope="dialog"
            data-part="close-trigger"
            aria-label="Close"
          >
            <LanternUI.Components.Icon.icon name="x-mark" />
          </button>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  # Attributes Zag writes after mount. LiveView must not clobber them on
  # patches — the machine is the writer, the server copy is stale by design.
  # Same list as the select prototype's `zag_ignored_attrs/0`.
  defp zag_ignored_attrs do
    ~w(
      data-state data-orientation dir id data-disabled data-readonly
      data-invalid data-required data-open data-focus data-focus-visible
      data-active data-hover data-placement data-highlighted data-value
      aria-expanded aria-controls aria-haspopup aria-labelledby aria-label
      aria-selected aria-checked aria-disabled aria-multiselectable
      disabled hidden role tabindex style
    )
  end
end
