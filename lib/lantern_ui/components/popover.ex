defmodule LanternUI.Components.Popover do
  @moduledoc """
  Click-triggered floating panel holding arbitrary content.

      <.popover placement="bottom-start">
        <.button variant="outline">Filters</.button>
        <:content>
          <div class="w-96 p-4">
            <.input field={@form[:name]} label="Name" />
          </div>
        </:content>
      </.popover>

  The default slot is the trigger; `:content` is the panel.

  ## Popover vs dropdown

  A dropdown is a *menu*: `role="menu"`, arrow-key item navigation, and it
  closes when an item is chosen. A popover is a *surface*: it holds inputs and
  arbitrary markup, so clicking inside must NOT close it — you have to be able
  to type in a field or tick a checkbox without the panel vanishing. Both ride
  the shared `LanternOverlay` runtime (anchored placement, focus return,
  Escape/outside-click dismissal); only these semantics differ.

  ## Fluxon compatibility

  Mirrors Fluxon's `popover/1`: `id`, `target`, `class`, `placement`,
  `open_on_hover`, `open_on_focus`, and the trigger/`:content` slot shape.
  `open_on_hover` / `open_on_focus` are accepted for drop-in compatibility but
  not honored — open/close is click- and keyboard-driven, which keeps a panel
  containing form fields usable (a hover-close would fight the pointer on its
  way to an input).
  """

  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string,
    default: nil,
    doc:
      "Stable DOM id for the overlay hook; auto-generated when omitted, mirroring Fluxon's popover (drop-in parity)."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the popover root wrapper.")

  attr(:placement, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "Where the panel anchors relative to the trigger."
  )

  attr(:target, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:open_on_hover, :boolean, default: false, doc: "accepted for Fluxon compat; click only")
  attr(:open_on_focus, :boolean, default: false, doc: "accepted for Fluxon compat; click only")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:inner_block, required: true, doc: "The trigger element.")
  slot(:content, required: true, doc: "Panel content.")

  def popover(assigns) do
    assigns =
      assign(assigns, :id, assigns.id || "lui-popover-#{System.unique_integer([:positive])}")

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-popover", @container_class])}
      phx-hook="LanternOverlay"
      data-placement={@placement}
      {@rest}
    >
      <div data-part="trigger" class="lui-popover-trigger">
        {render_slot(@inner_block)}
      </div>

      <div
        data-part="panel"
        hidden
        role="dialog"
        class={Class.merge(["lui-popover-panel", @class])}
      >
        {render_slot(@content)}
      </div>
    </div>
    """
  end
end
