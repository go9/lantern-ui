defmodule LanternUI.Components.SidePanel do
  @moduledoc """
  Collapsible right-hand panel plus a toggle that remembers open/closed in
  `localStorage`.

      <.side_panel_toggle
        id="tickets-panel-toggle"
        panel_id="tickets-panel"
        panel_key="tickets"
        open={@panel_open}
        phx-click="toggle_panel"
      />

      <.side_panel id="tickets-panel" open={@panel_open} aria-label="Project panel">
        <.inspector>…</.inspector>
      </.side_panel>

  The toggle owns the `LanternSidePanel` hook. On mount, with no stored choice,
  the panel defaults open at ≥1280px and closed below. After that the viewer's
  last choice wins. The LiveView still owns `open` — the hook pushes
  `set_panel` (override with `event`) when the stored value disagrees with
  `aria-pressed`.

  Not resizable. Not the app-shell sidebar (`LanternSidebar`).
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.IconButton

  attr(:id, :string, required: true, doc: "DOM id; referenced by the toggle's aria-controls.")
  attr(:open, :boolean, default: false, doc: "Whether the panel is shown.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the panel.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Panel body.")

  def side_panel(assigns) do
    ~H"""
    <aside
      id={@id}
      class={Class.merge(["lui-side-panel", @class])}
      hidden={!@open}
      {@rest}
    >
      {render_slot(@inner_block)}
    </aside>
    """
  end

  attr(:id, :string, required: true, doc: "DOM id for the hook.")

  attr(:panel_id, :string,
    required: true,
    doc: "id of the `side_panel/1` this toggle controls."
  )

  attr(:panel_key, :string,
    required: true,
    doc: "localStorage key suffix, e.g. `tickets`. Stored as `lui-side-panel:<key>`."
  )

  attr(:open, :boolean, default: false, doc: "Current open state; mirrored to aria-pressed.")

  attr(:event, :string,
    default: "set_panel",
    doc: "LiveView event the hook pushes on restore: `%{open: boolean}`."
  )

  attr(:persist_event, :string,
    default: "side_panel",
    doc: "Optional server event name the hook listens to for an explicit persist."
  )

  attr(:label, :string, default: "Toggle panel", doc: "Accessible name and tooltip.")
  attr(:kbd, :string, default: nil, doc: "Optional keyboard hint in the tooltip.")
  attr(:variant, :string, default: "outline", values: ~w(ghost outline primary))
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the button.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, doc: "Override the default panel-split glyph.")

  def side_panel_toggle(assigns) do
    ~H"""
    <IconButton.icon_button
      id={@id}
      label={@label}
      kbd={@kbd}
      variant={@variant}
      size={@size}
      class={@class}
      phx-hook="LanternSidePanel"
      aria-pressed={to_string(@open)}
      aria-controls={@panel_id}
      data-panel-key={@panel_key}
      data-event={@event}
      data-persist-event={@persist_event}
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <svg viewBox="0 0 16 16" fill="none" aria-hidden="true" class="lui-icon">
          <rect
            x="1.5"
            y="2.5"
            width="13"
            height="11"
            rx="2"
            stroke="currentColor"
            stroke-width="1.3"
          />
          <path d="M10 2.5v11" stroke="currentColor" stroke-width="1.3" />
        </svg>
      <% end %>
    </IconButton.icon_button>
    """
  end
end
