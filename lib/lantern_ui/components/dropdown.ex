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
  Hover-open and animation-tuning attrs are accepted for Fluxon compatibility;
  open/close is click/keyboard-driven and the fade is token-driven.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true, doc: "Stable DOM id for the dropdown hook.")
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
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:toggle, doc: "Custom trigger; defaults to a button using label.")
  slot(:inner_block, required: true, doc: "Menu items (buttons, links, separators).")

  def dropdown(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-dropdown", @container_class])}
      phx-hook="LanternDropdown"
      data-placement={@placement}
      {@rest}
    >
      <div data-part="trigger" class="lui-dropdown-trigger">
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

      <div data-part="panel" hidden role="menu" class={Class.merge(["lui-dropdown-menu", @class])}>
        {render_slot(@inner_block)}
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
end
