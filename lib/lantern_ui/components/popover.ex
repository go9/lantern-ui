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

  The panel is Zag-driven (a `@zag-js/popover` state machine, loaded on
  demand): the hook root carries `data-zag` plus `data-scope="popover"` /
  `data-part` anatomy, and Zag owns open state, focus return, and
  Escape/outside-click dismissal. Styling stays `lui-*` tokens. Two modes:

    * client (default) — Zag owns open state.
    * server-driven (`controlled`) — the server value (`open`) is truth;
      opens flow out through `on_change`, patches flow in.

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
  alias Phoenix.LiveView.JS

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

  attr(:controlled, :boolean,
    default: false,
    doc: "Server-driven open state: `open` is truth, patches flow into the machine."
  )

  attr(:open, :boolean,
    default: nil,
    doc: "Open state for `controlled` mode (client mode ignores it)."
  )

  attr(:on_change, :string,
    default: nil,
    doc: "Server event pushed on open change (`lantern:popover:set-open` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on open change."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:inner_block, required: true, doc: "The trigger element.")
  slot(:content, required: true, doc: "Panel content.")

  def popover(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || "lui-popover-#{System.unique_integer([:positive])}")
      |> assign(:open_json, Jason.encode!(assigns.open || false))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-popover", @container_class])}
      phx-hook="LanternOverlay"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"popover\"]")}
      data-zag
      data-placement={@placement}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: @open_json}
      data-default-value={unless @controlled, do: @open_json}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      {@rest}
    >
      <div data-scope="popover" data-part="trigger" class="lui-popover-trigger">
        {render_slot(@inner_block)}
      </div>

      <div data-scope="popover" data-part="positioner" popover="manual">
        <div
          data-scope="popover"
          data-part="content"
          hidden
          role="dialog"
          class={Class.merge(["lui-popover-panel", @class])}
        >
          {render_slot(@content)}
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
