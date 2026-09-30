defmodule LanternUI.Components.Toast do
  @moduledoc """
  Toast notification stack. Render once in a LiveView layout and push messages
  with `LanternUI.send_toast/4`.

  `placement` positions the stack in any corner or edge-center; toasts enter
  from the nearest screen edge (sliding down from the top, up from the bottom).
  `max` controls how many cards remain visible while the stack is collapsed.
  Pass `flash` to bridge Phoenix `:info` and `:error` flashes into the deck.

      <.toast_group placement="bottom-center" />
      <.toast_group flash={@flash} />
  """
  use Phoenix.Component

  alias LanternUI.Class

  @placements ~w(top-left top-center top-right bottom-left bottom-center bottom-right)

  attr(:id, :string, default: "lantern-toasts", doc: "Stable DOM id for the toast stack hook.")

  attr(:placement, :string,
    default: "top-right",
    values: @placements,
    doc: "Corner or edge where the toast stack anchors."
  )

  attr(:max, :integer,
    default: 3,
    doc: "Maximum toast cards visible in the collapsed deck (1–10)."
  )

  attr(:flash, :map,
    default: %{},
    doc: "Phoenix flash map; `:info` and `:error` render as toasts."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def toast_group(assigns) do
    flash = assigns.flash || %{}

    assigns =
      assign(
        assigns,
        :flash_toasts,
        [
          %{kind: "info", key: "info", message: Map.get(flash, :info) || Map.get(flash, "info")},
          %{
            kind: "error",
            key: "error",
            message: Map.get(flash, :error) || Map.get(flash, "error")
          }
        ]
        |> Enum.reject(&is_nil(&1.message))
      )

    assigns = assign(assigns, :max, min(max(assigns.max || 3, 1), 10))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-toasts", @class])}
      phx-hook="LanternToast"
      data-placement={@placement}
      data-max={@max}
      aria-live="polite"
      {@rest}
    >
      <div class="lui-toast-layer" data-part="flashes">
        <div
          :for={toast <- @flash_toasts}
          class="lui-toast lui-toast-in"
          data-kind={toast.kind}
          data-flash-key={toast.key}
        >
          <div :if={toast.message} class="lui-toast-header">
            <strong class="lui-toast-title">{if toast.kind == "error", do: "Error", else: "Notice"}</strong>
            <button
              type="button"
              class="lui-toast-close"
              data-part="close"
              aria-label="Close"
              phx-click="lv:clear-flash"
              phx-value-key={toast.key}
            >×</button>
          </div>
          <div class="lui-toast-body">
            <p class="lui-toast-message">{toast.message}</p>
            <button
              :if={!toast.message}
              type="button"
              class="lui-toast-close"
              data-part="close"
              aria-label="Close"
              phx-click="lv:clear-flash"
              phx-value-key={toast.key}
            >×</button>
          </div>
        </div>
      </div>
      <div id={"#{@id}-client"} class="lui-toast-layer" data-part="client" phx-update="ignore"></div>
    </div>
    """
  end
end
