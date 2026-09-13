defmodule LanternUI.Components.Card do
  @moduledoc """
  A bounded panel: a titled surface that groups related content on a page.

  Lantern had containers for *collections* — `data_table`, `resource_list`,
  `stat_grid` — but nothing for the ordinary case of "a titled box with some
  content in it", so apps were hand-rolling a div with a border and their own
  heading every time. This is that box.

      <.card title="Participants" description="Everyone on this settlement.">
        <:actions><.button size="sm">Invite</.button></:actions>
        …content…
        <:footer>3 of 4 have responded.</:footer>
      </.card>

  With no `title` and no `:header` the chrome disappears and it is simply a
  padded surface. Pass `flush` when the content draws its own edges (a table, a
  list) and should meet the card's border instead of sitting inside its padding.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:title, :string, default: nil, doc: "Card heading.")
  attr(:description, :string, default: nil, doc: "Muted line under the heading.")

  attr(:icon, :string,
    default: nil,
    doc: "Optional leading icon by the heading — a lantern icon name or a host `hero-*` name."
  )

  attr(:flush, :boolean,
    default: false,
    doc: "Drop the body padding, for content that draws its own edges (tables, lists)."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot(:header, doc: "Replaces the title/description block entirely.")
  slot(:actions, doc: "Right-aligned controls on the header row.")
  slot(:inner_block, required: true, doc: "Card body.")
  slot(:footer, doc: "Muted strip below the body, separated by a rule.")

  def card(assigns) do
    assigns =
      assign(
        assigns,
        :head?,
        assigns.header != [] || assigns.title || assigns.description || assigns.actions != []
      )

    ~H"""
    <section class={Class.merge(["lui-card", @class])} {@rest}>
      <div :if={@head?} class="lui-card-head">
        <div class="lui-card-headtext">
          {render_slot(@header)}
          <h2 :if={@header == [] && @title} class="lui-card-title">
            <.card_icon :if={@icon} name={@icon} />
            {@title}
          </h2>
          <p :if={@header == [] && @description} class="lui-card-desc">{@description}</p>
        </div>
        <div :if={@actions != []} class="lui-card-actions">{render_slot(@actions)}</div>
      </div>
      <div class={["lui-card-body", @flush && "lui-card-body-flush"]}>
        {render_slot(@inner_block)}
      </div>
      <div :if={@footer != []} class="lui-card-foot">{render_slot(@footer)}</div>
    </section>
    """
  end

  @doc """
  A responsive grid of cards. Cards flex from a common basis rather than a
  fixed column count, so the last row fills instead of leaving dead cells.
  """
  attr(:min, :string, default: "16rem", doc: "Minimum width a card may flex down to.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the grid.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")
  slot(:inner_block, required: true, doc: "`card/1` children.")

  def card_grid(assigns) do
    ~H"""
    <div class={Class.merge(["lui-card-grid", @class])} style={"--lui-card-min: #{@min}"} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:name, :string, required: true)

  defp card_icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={["lui-card-icon", "lui-card-icon-mask", @name]} aria-hidden="true" />
    """
  end

  defp card_icon(assigns) do
    ~H"""
    <Icon.icon name={@name} class="lui-card-icon" />
    """
  end
end
