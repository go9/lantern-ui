defmodule LanternUI.Components.CiteChip do
  @moduledoc """
  Inline citation button for evidence in prose or attached context.

      <.cite_chip number={1} label="Open citation: lib/search.ex, lines 12–18"
        active={@citation == "search"} phx-click="preview" phx-value-source="search">
        search.ex:12–18
      </.cite_chip>

  The required `label` names the full source for assistive technology; the slot
  holds its compact file:line, ticket number, or memory label. `number` is optional
  for unnumbered attached context. Keep source identity, numbering and preview
  content in the host app. Do not place interactive content inside the slot.

  This reuses `button/1`: a native non-submit button, activated with Enter or
  Space, with the same focus ring. `active` is server-owned `aria-pressed` state
  identifying the source currently shown in the host's preview rail. A stable
  `id` may be passed through for focus restoration when that rail closes.
  Only pass `aria-controls` when its target is rendered. There is no hook,
  animation, tooltip, source lookup, or built-in preview.

  See `docs/cite-chip.md` and the citation recipe in `docs/recipes.md`.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button

  attr(:label, :string,
    required: true,
    doc: "Full accessible name, including the source location."
  )

  attr(:number, :integer, default: nil, doc: "Optional citation number within the answer.")

  attr(:active, :boolean,
    default: false,
    doc: "Whether this source is shown in the preview rail."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the button.")
  attr(:rest, :global, doc: "HTML/ARIA and phx-* attrs, including id and preview click events.")
  slot(:inner_block, required: true, doc: "Compact source label; no interactive descendants.")

  def cite_chip(assigns) do
    ~H"""
    <Button.button
      type="button"
      label={@label}
      pressed={@active}
      class={Class.merge(["lui-cite-chip", @class])}
      {@rest}
    >
      <span :if={@number} class="lui-cite-chip-number" aria-hidden="true">{@number}</span>
      {render_slot(@inner_block)}
    </Button.button>
    """
  end
end
