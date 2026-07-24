defmodule LanternUI.Components.AlertDialog do
  @moduledoc """
  Semantic confirmation dialog composed on the shared modal runtime.

  Alert dialogs require a title, description, cancel control, and action
  control. The cancel slot is rendered before the action slot, so it receives
  initial focus when the dialog opens. Escape still closes and restores focus;
  clicking outside never dismisses the dialog.

      <.button phx-click={LanternUI.open_dialog("delete-project")}>Delete…</.button>

      <.alert_dialog id="delete-project">
        <:title>Delete this project?</:title>
        <:description>This action cannot be undone.</:description>
        <:cancel>
          <.button phx-click={LanternUI.close_dialog("delete-project")}>Cancel</.button>
        </:cancel>
        <:action>
          <.button color="danger" phx-click="delete-project">Delete project</.button>
        </:action>
      </.alert_dialog>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Modal

  attr(:id, :string, required: true, doc: "Stable DOM id used by open_dialog/close_dialog.")
  attr(:open, :boolean, default: false, doc: "Render already open.")
  attr(:close_on_esc, :boolean, default: true, doc: "Close when Escape is pressed.")
  attr(:class, :any, default: nil, doc: "Extra classes on the dialog panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the overlay root.")
  attr(:backdrop_class, :any, default: nil, doc: "Extra classes on the dimmed backdrop.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:title, required: true, doc: "Concise statement of the consequence.")
  slot(:description, required: true, doc: "Explanation of the irreversible action.")
  slot(:cancel, required: true, doc: "Safe cancellation control; receives initial focus.")
  slot(:action, required: true, doc: "Confirmation control for the destructive action.")

  def alert_dialog(assigns) do
    assigns =
      assigns
      |> assign(:title_id, "#{assigns.id}-title")
      |> assign(:description_id, "#{assigns.id}-description")

    ~H"""
    <Modal.modal
      id={@id}
      open={@open}
      close_on_esc={@close_on_esc}
      close_on_outside_click={false}
      hide_close_button
      role="alertdialog"
      aria_labelledby={@title_id}
      aria_describedby={@description_id}
      initial_focus="[data-part='alert-dialog-cancel']"
      class={Class.merge(["lui-alert-dialog", @class])}
      container_class={@container_class}
      backdrop_class={@backdrop_class}
      {@rest}
    >
      <h2 id={@title_id} class="lui-alert-dialog-title">{render_slot(@title)}</h2>
      <div id={@description_id} class="lui-alert-dialog-description">
        {render_slot(@description)}
      </div>
      <div class="lui-alert-dialog-actions">
        <div class="lui-alert-dialog-cancel" data-part="alert-dialog-cancel">
          {render_slot(@cancel)}
        </div>
        <div class="lui-alert-dialog-action">{render_slot(@action)}</div>
      </div>
    </Modal.modal>
    """
  end
end
