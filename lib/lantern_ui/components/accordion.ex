defmodule LanternUI.Components.Accordion do
  @moduledoc """
  Accordion — a vertically stacked set of headers that each toggle an
  associated content panel. Fluxon-compatible surface where applicable:
  `<.accordion>` wrapping `<:item title=...>` slots.

      <.accordion id="faq">
        <:item title="Shipping">We ship worldwide.</:item>
        <:item title="Returns" expanded>30-day, no questions asked.</:item>
        <:item title="Warranty" disabled>Coming soon.</:item>
      </.accordion>

      <.accordion id="settings" multiple heading_level={2}>
        <:item title="Profile">…</:item>
        <:item title="Billing">…</:item>
      </.accordion>

  ## Behavior

  Server-rendered anatomy; the `LanternAccordion` JS hook owns open/close and the
  WAI-ARIA APG keyboard model (this is client behavior a server round-trip can't
  provide — arrow-key focus movement between headers is impossible without JS):

    * `Enter` / `Space` on a header toggles its panel (native `<button>`).
    * `ArrowDown` / `ArrowUp` move focus between headers (wrapping).
    * `Home` / `End` move focus to the first / last header.
    * By default one panel is open at a time; `multiple` allows many.

  Panels are always in the DOM (toggled via `hidden`), so `aria-controls` /
  `aria-labelledby` idrefs always resolve and collapsed content is removed from
  the tab order and the accessibility tree. Initial open state comes from each
  item's `expanded`; after mount the open state is client-owned (the hook
  re-applies it across LiveView patches).

  ## Accessibility (WAI-ARIA APG: Accordion)

    * Each header is a `<button aria-expanded aria-controls>` wrapped in a
      `role="heading"` element with `aria-level` (`heading_level`).
    * Each panel is a `role="region"` labelled by its header (`aria-labelledby`).
    * `aria-expanded` is a server-rendered literal that the hook flips at runtime
      (declared hook-owned in the ARIA conformance gate).
    * The chevron animation respects `prefers-reduced-motion`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string,
    required: true,
    doc: "Stable id for the accordion root and its item id namespace."
  )

  attr(:multiple, :boolean,
    default: false,
    doc: "When true, more than one panel may be open at once. Defaults to single-open."
  )

  attr(:heading_level, :integer,
    default: 3,
    values: [1, 2, 3, 4, 5, 6],
    doc: "aria-level of each header's heading wrapper; pick to fit the page outline."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :item,
    required: true,
    doc: "One accordion section: a header (`title`) and a panel (inner block)." do
    attr(:title, :string, doc: "Header label text.")
    attr(:expanded, :boolean, doc: "When true, this panel starts open.")
    attr(:disabled, :boolean, doc: "When true, the header is not focusable and cannot toggle.")
    attr(:class, :any, doc: "Extra classes merged onto this item.")
  end

  def accordion(assigns) do
    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-accordion", @class])}
      phx-hook="LanternAccordion"
      data-multiple={to_string(@multiple)}
      {@rest}
    >
      <div
        :for={{item, i} <- Enum.with_index(@item)}
        class={Class.merge(["lui-accordion-item", item[:class]])}
        data-part="item"
        data-state={if item[:expanded], do: "open", else: "closed"}
      >
        <div class="lui-accordion-header" role="heading" aria-level={@heading_level}>
          <button
            type="button"
            id={"#{@id}-#{i}-trigger"}
            class="lui-accordion-trigger"
            data-part="trigger"
            aria-expanded={to_string(!!item[:expanded])}
            aria-controls={"#{@id}-#{i}-panel"}
            disabled={item[:disabled]}
          >
            <span class="lui-accordion-title">{item[:title]}</span>
            <svg class="lui-accordion-icon" viewBox="0 0 20 20" fill="none" aria-hidden="true">
              <path
                d="M6 8l4 4 4-4"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </button>
        </div>
        <div
          id={"#{@id}-#{i}-panel"}
          class="lui-accordion-panel"
          data-part="panel"
          role="region"
          aria-labelledby={"#{@id}-#{i}-trigger"}
          hidden={!item[:expanded]}
        >
          <div class="lui-accordion-body">{render_slot(item)}</div>
        </div>
      </div>
    </div>
    """
  end
end
