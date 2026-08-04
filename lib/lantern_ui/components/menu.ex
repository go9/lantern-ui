defmodule LanternUI.Components.Menu do
  @moduledoc """
  Menu button and menubar — no Fluxon equivalent. Clean-room implementations
  of the WAI-ARIA APG menu-button and menubar patterns.

      <.menu id="file-actions" label="File">
        <.menu_item phx-click="new">New</.menu_item>
        <.menu_item phx-click="open">Open…</.menu_item>
        <.menu_separator />
        <.menu_item phx-click="delete" data-danger>Delete</.menu_item>
      </.menu>

      <.menubar label="Editor">
        <.menubar_menu label="File">
          <.menu_item phx-click="new">New</.menu_item>
        </.menubar_menu>
        <.menubar_menu label="Edit">
          <.menu_item phx-click="undo">Undo</.menu_item>
        </.menubar_menu>
      </.menubar>

  How this differs from `dropdown`: the component owns the trigger button, so
  `aria-haspopup`/`aria-expanded`/`aria-controls` are always wired (a custom
  trigger is content *inside* the button via the `:trigger` slot, never a
  replacement button), the popup is an `aria-labelledby`-named `role="menu"`,
  and the hooks run the full APG keyboard model — wrapping ArrowUp/Down,
  Home/End, roving tabindex, and (for the menubar) horizontal ArrowLeft/Right
  across top-level items that carries an open submenu along.

  ARIA ownership split: the server renders `aria-expanded="false"` as a static
  literal and every popup item `tabindex="-1"`; the `LanternMenu` /
  `LanternMenubar` hooks own both at runtime (expanded state and the roving
  tabindex). Focus moves by roving DOM focus, the library-wide model — not
  `aria-activedescendant`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string,
    default: nil,
    doc: "Stable DOM id for the menu hook; auto-generated when omitted."
  )

  attr(:label, :string, default: nil, doc: "Trigger button text when no :trigger slot.")
  attr(:class, :any, default: nil, doc: "Extra classes on the popup menu panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the menu root wrapper.")
  attr(:trigger_class, :any, default: nil, doc: "Extra classes on the trigger button.")
  attr(:disabled, :boolean, default: false, doc: "Render the trigger disabled.")

  attr(:placement, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc: "Where the menu anchors relative to the trigger."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:trigger,
    doc: "Custom trigger content, rendered inside the component-owned button."
  )

  slot(:inner_block, required: true, doc: "Menu items and separators.")

  def menu(assigns) do
    assigns = assign(assigns, :id, assigns.id || "lui-menu-#{System.unique_integer([:positive])}")

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-menu", @container_class])}
      phx-hook="LanternMenu"
      data-placement={@placement}
      {@rest}
    >
      <LanternUI.Components.Button.button
        type="button"
        id={"#{@id}-trigger"}
        disabled={@disabled}
        class={@trigger_class}
        data-part="trigger"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-menu"}
      >
        <%= if @trigger == [] do %>
          {@label}
          <LanternUI.Components.Icon.icon name="chevron-down" />
        <% else %>
          {render_slot(@trigger)}
        <% end %>
      </LanternUI.Components.Button.button>

      <div
        id={"#{@id}-menu"}
        data-part="menu"
        hidden
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        class={Class.merge(["lui-menu-panel", @class])}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:disabled, :boolean, default: false, doc: "Render disabled and skipped by arrow keys.")

  attr(:navigate, :string,
    default: nil,
    doc: "Live-navigate here on activation. Renders the item as a link, not a button."
  )

  attr(:patch, :string,
    default: nil,
    doc: "Live-patch here on activation. Renders the item as a link, not a button."
  )

  attr(:href, :any,
    default: nil,
    doc: "Plain href. Renders the item as a link, not a button."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Menu item label.")

  @doc """
  A menu item.

  Renders a `<button>` by default. Given `navigate`, `patch` or `href` it
  renders a `<.link>` instead, because a menu that cannot contain a link forces
  every caller with a navigating entry to fake one — and a menu item with
  neither a click handler nor an href is a dead control that fails silently.
  (Found in flicker: overflow-menu entries that only carried a path rendered as
  buttons with no target, so the whole dropdown looked broken.)

  Both variants keep `role="menuitem"` and `tabindex="-1"`, which is what the
  hooks' roving-focus model selects on — so the keyboard contract is identical
  either way. `disabled` on a link becomes `data-disabled` + `aria-disabled`,
  since anchors have no `disabled` attribute; the hooks' item query already
  skips both.
  """
  def menu_item(assigns) do
    assigns = assign(assigns, :link?, assigns.navigate || assigns.patch || assigns.href)

    ~H"""
    <.link
      :if={@link?}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={Class.merge(["lui-menu-item", @class])}
      role="menuitem"
      tabindex="-1"
      data-disabled={@disabled && "true"}
      aria-disabled={@disabled && "true"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@link?}
      type="button"
      class={Class.merge(["lui-menu-item", @class])}
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

  def menu_separator(assigns) do
    ~H"""
    <div class={Class.merge(["lui-menu-separator", @class])} role="separator" {@rest}></div>
    """
  end

  attr(:id, :string,
    default: nil,
    doc: "Stable DOM id for the menubar hook; auto-generated when omitted."
  )

  attr(:label, :string,
    required: true,
    doc: "Accessible name for the menubar (`aria-label`); required by the APG."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "`menubar_menu` entries.")

  def menubar(assigns) do
    assigns =
      assign(assigns, :id, assigns.id || "lui-menubar-#{System.unique_integer([:positive])}")

    ~H"""
    <div
      id={@id}
      role="menubar"
      aria-label={@label}
      class={Class.merge(["lui-menubar", @class])}
      phx-hook="LanternMenubar"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:id, :string,
    default: nil,
    doc: "Stable DOM id for this entry; auto-generated when omitted."
  )

  attr(:label, :string, required: true, doc: "Top-level menubar item text.")
  attr(:class, :any, default: nil, doc: "Extra classes on the popup menu panel.")
  attr(:trigger_class, :any, default: nil, doc: "Extra classes on the top-level item button.")
  attr(:disabled, :boolean, default: false, doc: "Render the entry disabled.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Menu items and separators.")

  def menubar_menu(assigns) do
    assigns =
      assign(assigns, :id, assigns.id || "lui-menubar-menu-#{System.unique_integer([:positive])}")

    ~H"""
    <div class="lui-menubar-entry" data-part="entry" {@rest}>
      <button
        type="button"
        id={"#{@id}-trigger"}
        data-part="trigger"
        role="menuitem"
        disabled={@disabled}
        class={Class.merge(["lui-menubar-trigger", @trigger_class])}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-menu"}
      >
        {@label}
      </button>

      <div
        id={"#{@id}-menu"}
        data-part="menu"
        hidden
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        class={Class.merge(["lui-menu-panel", @class])}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
