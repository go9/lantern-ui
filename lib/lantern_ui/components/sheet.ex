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
      data-open={@open || nil}
      data-placement={@placement}
      data-close-on-esc={to_string(@close_on_esc and not @prevent_closing)}
      data-close-on-outside={to_string(@close_on_outside_click and not @prevent_closing)}
      hidden={!@open}
      {@rest}
    >
      <div class={Class.merge(["lui-sheet-backdrop", @backdrop_class])} data-part="backdrop"></div>
      <div
        class={Class.merge(["lui-sheet-panel", @class])}
        data-part="panel"
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
            data-part="close"
            aria-label="Close"
          >
            <Icon.icon name="x-mark" />
          </button>
        </header>
        <div class="lui-sheet-body">{render_slot(@inner_block)}</div>
        <footer :if={@footer != []} class="lui-sheet-footer">{render_slot(@footer)}</footer>
      </div>
    </div>
    """
  end
end
