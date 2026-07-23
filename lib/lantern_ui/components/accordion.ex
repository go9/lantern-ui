defmodule LanternUI.Components.Accordion do
  @moduledoc """
  Accordion — a WAI-ARIA APG accordion with the Fluxon 2.3.1 composition API.

      <.accordion id="faq">
        <.accordion_item id="shipping" expanded>
          <:header>Shipping</:header>
          <:panel>We ship worldwide.</:panel>
        </.accordion_item>
        <.accordion_item id="returns" icon={false}>
          <:header class="font-bold">Returns</:header>
          <:panel class="prose">Thirty days, no questions asked.</:panel>
        </.accordion_item>
      </.accordion>

  The server renders the complete accessible anatomy and initial state. The
  `LanternAccordion` hook owns toggling, single/multiple-open enforcement, and
  the optional ArrowUp/ArrowDown/Home/End header navigation from the APG.
  Panels remain in the DOM and use `hidden` when collapsed, keeping ARIA idrefs
  valid while removing collapsed content from the tab order and accessibility
  tree. Hook-owned state is restored after LiveView patches.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, doc: "Stable accordion id. A unique id is generated when omitted.")

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the accordion root.")

  attr(:multiple, :boolean,
    default: false,
    doc: "Allow more than one item to be expanded at once."
  )

  attr(:prevent_all_closed, :boolean,
    default: false,
    doc: "Keep at least one enabled item expanded."
  )

  attr(:animation_duration, :integer,
    default: 300,
    doc: "Expand/collapse indicator transition duration in milliseconds."
  )

  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "One or more `accordion_item/1` components.")

  def accordion(assigns) do
    assigns = assign_new(assigns, :id, fn -> generated_id("accordion") end)

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-accordion", @class])}
      phx-hook="LanternAccordion"
      data-multiple={to_string(@multiple)}
      data-prevent-all-closed={to_string(@prevent_all_closed)}
      data-animation-duration={@animation_duration}
      style={"--lui-accordion-duration: #{@animation_duration}ms"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:id, :string,
    doc:
      "Stable item id used to connect its header and panel. A unique id is generated when omitted."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the item root.")
  attr(:expanded, :boolean, default: false, doc: "Whether this item starts expanded.")
  attr(:icon, :boolean, default: true, doc: "Whether to render the built-in chevron.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :header, required: true, doc: "Always-visible header content." do
    attr(:class, :any, doc: "Extra classes merged onto the header button.")
  end

  slot :panel, required: true, doc: "Expandable panel content." do
    attr(:class, :any, doc: "Extra classes merged onto the panel content wrapper.")
  end

  def accordion_item(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> generated_id("accordion-item") end)
      |> assign(:header_classes, Enum.map(assigns.header, & &1[:class]))
      |> assign(:panel_classes, Enum.map(assigns.panel, & &1[:class]))

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-accordion-item", @class])}
      data-part="item"
      data-state={if @expanded, do: "open", else: "closed"}
      {@rest}
    >
      <div class="lui-accordion-header" role="heading" aria-level="3">
        <button
          type="button"
          id={"#{@id}-trigger"}
          class={Class.merge(["lui-accordion-trigger", @header_classes])}
          data-part="trigger"
          aria-expanded={to_string(@expanded)}
          aria-controls={"#{@id}-panel"}
        >
          <span class="lui-accordion-title">{render_slot(@header)}</span>
          <svg
            :if={@icon}
            class="lui-accordion-icon"
            viewBox="0 0 20 20"
            fill="none"
            aria-hidden="true"
          >
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
        id={"#{@id}-panel"}
        class="lui-accordion-panel"
        data-part="panel"
        role="region"
        aria-labelledby={"#{@id}-trigger"}
        hidden={!@expanded}
      >
        <div class={Class.merge(["lui-accordion-body", @panel_classes])}>{render_slot(@panel)}</div>
      </div>
    </div>
    """
  end

  defp generated_id(prefix) do
    "#{prefix}-#{System.unique_integer([:positive, :monotonic])}"
  end
end
