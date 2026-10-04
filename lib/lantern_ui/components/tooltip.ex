defmodule LanternUI.Components.Tooltip do
  @moduledoc """
  Tooltip - mirrors Fluxon's `tooltip/1` API.

  The tip is Zag-driven (a `@zag-js/tooltip` state machine, loaded on
  demand): the hook root carries `data-zag` plus `data-scope="tooltip"` /
  `data-part` anatomy, and Zag owns open state, hover/focus timing, and
  positioning. Styling stays `lui-*` tokens. Two modes:

    * client (default) — Zag owns open state; hover/focus timing is the
      machine's `openDelay` (`delay` attr).
    * server-driven (`controlled`) — the server value (`open`) is truth;
      opens flow out through `on_change`, patches flow in.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias Phoenix.LiveView.JS

  attr(:id, :string,
    default: nil,
    doc:
      "Stable DOM id for the tooltip hook; auto-generated when omitted, mirroring Fluxon's tooltip (drop-in parity)."
  )

  attr(:value, :string, default: nil, doc: "Plain-text tip when no :content slot is given.")

  attr(:placement, :string,
    default: "top",
    values: ~w(top bottom left right),
    doc: "Preferred side of the trigger; may flip for viewport fit."
  )

  attr(:delay, :integer, default: 200, doc: "Milliseconds before the tip appears on hover/focus.")
  attr(:arrow, :boolean, default: true, doc: "Show the small pointer arrow toward the trigger.")

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
    doc: "Server event pushed on open change (`lantern:tooltip:set-open` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on open change."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Trigger element that shows the tip.")
  slot(:content, doc: "Rich tip body; overrides `value` when present.")

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || "lui-tooltip-#{System.unique_integer([:positive])}")
      |> assign(:open_json, Jason.encode!(assigns.open || false))

    ~H"""
    <span
      id={@id}
      class={Class.merge(["lui-tooltip-wrap", @class])}
      phx-hook="LanternTooltip"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"tooltip\"]")}
      data-zag
      data-placement={@placement}
      data-delay={@delay}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: @open_json}
      data-default-value={unless @controlled, do: @open_json}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      {@rest}
    >
      <span data-scope="tooltip" data-part="trigger" class="lui-tooltip-trigger" tabindex="0">
        {render_slot(@inner_block)}
      </span>
      <span data-scope="tooltip" data-part="positioner" popover="manual">
        <span data-scope="tooltip" data-part="content" class="lui-tooltip" role="tooltip" hidden>
          <%= if @content != [] do %>
            {render_slot(@content)}
          <% else %>
            {@value}
          <% end %>
          <span
            :if={@arrow}
            class="lui-tooltip-arrow"
            data-scope="tooltip"
            data-part="arrow"
          ></span>
        </span>
      </span>
    </span>
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
