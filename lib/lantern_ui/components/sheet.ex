defmodule LanternUI.Components.Sheet do
  @moduledoc """
  Slide-over panel (drawer) that enters from a screen edge. Mirrors Fluxon's
  `sheet/1`, and shares the dialog open/close runtime with `modal/1`, so it's
  driven by `LanternUI.open_dialog/1` / `close_dialog/1`.

      <.sheet id="edit-theme" placement="right">
        <h2>Edit theme</h2>
        <p>…</p>
        <.button phx-click={LanternUI.close_dialog("edit-theme")}>Done</.button>
      </.sheet>

      <.button phx-click={LanternUI.open_dialog("edit-theme")}>Edit…</.button>

  Focus trap, scroll lock, and Escape/backdrop dismissal come from the shared
  overlay runtime (the `LanternSheet` hook). `placement` slides the panel from
  `left` / `right` / `top` / `bottom`.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true, doc: "Stable DOM id used by open_dialog/close_dialog.")
  attr(:open, :boolean, default: false, doc: "render already open (server-driven sheets)")

  attr(:placement, :string,
    default: "right",
    values: ~w(left right top bottom),
    doc: "Screen edge the panel slides in from."
  )

  attr(:title, :string, default: nil, doc: "optional header title beside the close button")
  attr(:on_open, Phoenix.LiveView.JS, default: nil, doc: "JS command run when the sheet opens.")
  attr(:on_close, Phoenix.LiveView.JS, default: nil, doc: "JS command run when the sheet closes.")
  attr(:close_on_esc, :boolean, default: true, doc: "Close when Escape is pressed.")

  attr(:close_on_outside_click, :boolean,
    default: true,
    doc: "Close when the backdrop is clicked."
  )

  attr(:prevent_closing, :boolean, default: false, doc: "Block Escape and outside-click close.")
  attr(:hide_close_button, :boolean, default: false, doc: "Hide the built-in close control.")
  attr(:class, :any, default: nil, doc: "Extra classes on the sliding panel.")
  attr(:container_class, :any, default: nil, doc: "Extra classes on the overlay root.")
  attr(:backdrop_class, :any, default: nil, doc: "Extra classes on the dimmed backdrop.")
  # Accepted for Fluxon compat; the slide is token-driven.
  attr(:animation, :string,
    default: nil,
    doc: "Accepted for Fluxon compat; slide is token-driven."
  )

  attr(:animation_enter, :string, default: nil, doc: "Accepted for Fluxon compat.")
  attr(:animation_leave, :string, default: nil, doc: "Accepted for Fluxon compat.")

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

  slot(:header, doc: "custom header content (replaces `title`)")
  slot(:footer, doc: "sticky footer (action buttons)")
  slot(:inner_block, required: true, doc: "Sheet body content.")

  def sheet(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-sheet", @container_class])}
      phx-hook="LanternSheet"
      phx-mounted={JS.ignore_attributes(zag_ignored_attrs(), to: "[data-scope=\"dialog\"]")}
      data-zag
      data-open={@open || nil}
      data-controlled={@controlled || nil}
      data-value={if @controlled, do: to_string(@open)}
      data-default-value={unless @controlled, do: to_string(@open)}
      data-placement={@placement}
      data-close-on-esc={to_string(@close_on_esc and not @prevent_closing)}
      data-close-on-outside={to_string(@close_on_outside_click and not @prevent_closing)}
      data-prevent-closing={@prevent_closing || nil}
      data-on-open={@on_open}
      data-on-close={@on_close}
      data-on-change={@on_change}
      data-on-change-client={@on_change_client}
      hidden={!@open}
      {@rest}
    >
      <div
        class={Class.merge(["lui-sheet-backdrop", @backdrop_class])}
        data-scope="dialog"
        data-part="backdrop"
      >
      </div>
      <div data-scope="dialog" data-part="positioner">
        <div
          class={Class.merge(["lui-sheet-panel", @class])}
          data-scope="dialog"
          data-part="content"
          role="dialog"
          aria-modal="true"
          aria-label={@title}
        >
          <header :if={@header != [] || @title || !@hide_close_button} class="lui-sheet-header">
            <div class="lui-sheet-heading">
              <span :if={@title && @header == []} class="lui-sheet-title">{@title}</span>
              {render_slot(@header)}
            </div>
            <button
              :if={!@hide_close_button and !@prevent_closing}
              type="button"
              class="lui-sheet-close"
              data-scope="dialog"
              data-part="close-trigger"
              aria-label="Close"
            >
              <Icon.icon name="x-mark" />
            </button>
          </header>
          <div class="lui-sheet-body">{render_slot(@inner_block)}</div>
          <footer :if={@footer != []} class="lui-sheet-footer">{render_slot(@footer)}</footer>
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
