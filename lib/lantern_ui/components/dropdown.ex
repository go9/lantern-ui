defmodule LanternUI.Components.Dropdown do
  @moduledoc """
  Dropdown menu on the shared overlay runtime (anchored placement, focus
  return, Escape/outside dismissal, arrow-key item navigation).

      <.dropdown id="row-actions" placement="bottom-end">
        <:toggle>
          <.button size="icon" aria-label="Actions"><.icon name="ellipsis-horizontal" /></.button>
        </:toggle>
        <.dropdown_header>object.png</.dropdown_header>
        <.dropdown_button phx-click="download">Download</.dropdown_button>
        <.dropdown_link navigate="/preview">Preview</.dropdown_link>
        <.dropdown_separator />
        <.dropdown_button phx-click="delete" data-danger>Delete</.dropdown_button>
      </.dropdown>

  The API mirrors Fluxon's dropdown family (`dropdown`, `dropdown_header`,
  `dropdown_separator`, `dropdown_link`, `dropdown_button`, `dropdown_custom`).
  `dropdown_header/1` labels a section, `dropdown_separator/1` divides sections,
  and `dropdown_custom/1` provides non-item content. Use `dropdown_link/1` for
  navigation and `dropdown_button/1` for actions.
  Hover-open and animation-tuning attrs are accepted for Fluxon compatibility;
  open/close is click/keyboard-driven and the fade is token-driven.

  The menu is Zag-driven (a `@zag-js/menu` state machine, loaded on demand):
  the hook root carries `data-zag` plus `data-scope="menu"` / `data-part`
  anatomy, and Zag owns open state, arrow-key/Home/End navigation,
  typeahead, and positioning. Styling stays `lui-*` tokens. Two modes:

    * client (default) — Zag owns open state.
    * server-driven (`controlled`) — the server value (`open`) is truth;
      opens flow out through `on_change`, patches flow in.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias Phoenix.LiveView.JS

  attr(:id, :string,
    default: nil,
    doc:
      "Stable DOM id for the dropdown hook; auto-generated when omitted, mirroring Fluxon's dropdown (drop-in parity)."
  )

  attr(:label, :string, default: nil, doc: "default toggle button text when no :toggle slot")
  attr(:class, :any, default: nil, doc: "classes for the menu panel")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the dropdown root wrapper.")
  attr(:toggle_class, :any, default: nil, doc: "Classes on the default toggle button.")
  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:placement, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "Where the menu anchors relative to the toggle."
  )

  attr(:animation, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:animation_enter, :string, default: nil, doc: "accepted for Fluxon compat")
  attr(:animation_leave, :string, default: nil, doc: "accepted for Fluxon compat")

  attr(:open_on_hover, :boolean,
    default: false,
    doc: "accepted for Fluxon compat; click/keyboard only"
  )

  attr(:hover_open_delay, :integer, default: nil, doc: "accepted for Fluxon compat")
  attr(:hover_close_delay, :integer, default: nil, doc: "accepted for Fluxon compat")

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
    doc: "Server event pushed on open change (`lantern:menu:set-open` replies)."
  )

  attr(:on_change_client, :string,
    default: nil,
    doc: "Bubbling DOM CustomEvent dispatched on open change."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:toggle, doc: "Custom trigger; defaults to a button using label.")
  slot(:inner_block, required: true, doc: "Menu items (buttons, links, separators).")

  def dropdown(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || "lui-dropdown-#{System.unique_integer([:positive])}")
      |> assign(:open_json, Jason.encode!(assigns.open || false))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-dropdown", @container_class])}
      phx-hook="LanternDropdown"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"menu\"]")}
      data-zag
      data-placement={@placement}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: @open_json}
      data-default-value={unless @controlled, do: @open_json}
      data-disabled={@disabled || nil}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      {@rest}
    >
      <div data-scope="menu" data-part="trigger" class="lui-dropdown-trigger">
        <%= if @toggle == [] do %>
          <LanternUI.Components.Button.button
            type="button"
            disabled={@disabled}
            class={@toggle_class}
            aria-haspopup="menu"
            aria-expanded="false"
          >
            {@label}
            <LanternUI.Components.Icon.icon name="chevron-down" />
          </LanternUI.Components.Button.button>
        <% else %>
          {render_slot(@toggle)}
        <% end %>
      </div>

      <div data-scope="menu" data-part="positioner">
        <div
          data-scope="menu"
          data-part="content"
          hidden
          role="menu"
          class={Class.merge(["lui-dropdown-menu", @class])}
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Header label content.")

  def dropdown_header(assigns) do
    ~H"""
    <div class={Class.merge(["lui-dropdown-header", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def dropdown_separator(assigns) do
    ~H"""
    <div class={Class.merge(["lui-dropdown-separator", @class])} role="separator" {@rest}></div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:rest, :global,
    include: ~w(navigate patch href method download target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  slot(:inner_block, required: true, doc: "Link menu item label.")

  def dropdown_link(assigns) do
    ~H"""
    <.link
      class={Class.merge(["lui-dropdown-item", @class])}
      role="menuitem"
      data-disabled={@disabled || nil}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Button menu item label.")

  def dropdown_button(assigns) do
    ~H"""
    <button
      type="button"
      class={Class.merge(["lui-dropdown-item", @class])}
      role="menuitem"
      disabled={@disabled}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Custom non-item content inside the menu.")

  def dropdown_custom(assigns) do
    ~H"""
    <div class={Class.merge(["lui-dropdown-custom", @class])} {@rest}>
      {render_slot(@inner_block)}
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
