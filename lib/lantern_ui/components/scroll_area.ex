defmodule LanternUI.Components.ScrollArea do
  @moduledoc """
  ScrollArea — themed scrollbar wrapper around native overflow scrolling. No
  Fluxon equivalent.

  Pure CSS: the browser keeps ownership of wheel, touch, momentum, and
  scrollbar auto-hide behavior; LanternUI only themes the scrollbar
  (`scrollbar-width`/`scrollbar-color` plus the `::-webkit-scrollbar`
  pseudo-elements) through `--lantern-*` tokens. No JS hook.

      <.scroll_area label="Recent activity" class="feed" style="max-height: 20rem;">
        <p :for={item <- @items}>{item}</p>
      </.scroll_area>

  The consumer constrains the box (`max-height`, `height`, grid track, …);
  without a constraint nothing overflows and no scrollbar appears.

  ## Accessibility

  Per the WAI-ARIA guidance for scrollable containers, a region whose content
  is reachable only by scrolling must be operable from the keyboard. When
  `label` is set the wrapper renders `role="region"`, `aria-label`, and
  `tabindex="0"` so keyboard users can focus it and scroll with the arrow
  keys. Omit `label` only when the scrolled content manages focus itself
  (e.g. it wraps an interactive widget with its own tab stops).
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:label, :string,
    default: nil,
    doc:
      "Accessible name; when set the wrapper becomes a focusable, keyboard-scrollable " <>
        "`role=\"region\"`. Omit only when the content manages focus itself."
  )

  attr(:orientation, :string,
    default: "vertical",
    values: ~w(vertical horizontal both),
    doc: "Which axis may scroll; the other axis hides its overflow."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Scrolled content.")

  def scroll_area(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-scroll-area", @class])}
      data-orientation={@orientation}
      role={@label && "region"}
      aria-label={@label}
      tabindex={@label && "0"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
