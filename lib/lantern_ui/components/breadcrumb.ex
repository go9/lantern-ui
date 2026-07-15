defmodule LanternUI.Components.Breadcrumb do
  @moduledoc """
  Path breadcrumb for file/tree navigation (a lantern-ui extension — Fluxon has
  no equivalent).

      <.breadcrumb aria_label="Object path">
        <:item phx-click="close_bucket">my-bucket</:item>
        <:item phx-click="navigate" phx-value-prefix="photos/">photos</:item>
        <:item current>2026</:item>
      </.breadcrumb>

  Items with a `navigate`/`patch`/`href` render as links; items with `phx-*`
  attrs render as buttons; the `current` item renders as plain text with
  `aria-current="page"`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:separator, :string, default: "/", doc: "Glyph shown between breadcrumb items.")
  attr(:aria_label, :string, default: "Breadcrumb", doc: "Accessible name for the nav landmark.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :item, required: true, doc: "One path segment; link, button, or current page." do
    attr(:current, :boolean, doc: "Mark as the current page (plain text, aria-current).")
    attr(:navigate, :string, doc: "LiveView navigate target for this segment.")
    attr(:patch, :string, doc: "LiveView patch target for this segment.")
    attr(:href, :string, doc: "External or full-page href for this segment.")
    attr(:"phx-click", :string, doc: "LiveView click event when rendering as a button.")
    attr(:"phx-value-prefix", :string, doc: "Optional phx-value-prefix for the click event.")
    attr(:"phx-target", :any, doc: "LiveView target for the click event.")
  end

  def breadcrumb(assigns) do
    ~H"""
    <nav class={Class.merge(["lui-breadcrumb", @class])} aria-label={@aria_label} {@rest}>
      <ol class="lui-breadcrumb-list">
        <li :for={{item, i} <- Enum.with_index(@item)} class="lui-breadcrumb-item">
          <span :if={i > 0} class="lui-breadcrumb-sep" aria-hidden="true">{@separator}</span>
          <%= cond do %>
            <% item[:current] -> %>
              <span class="lui-breadcrumb-current" aria-current="page">{render_slot(item)}</span>
            <% item[:navigate] || item[:patch] || item[:href] -> %>
              <.link
                class="lui-breadcrumb-link"
                navigate={item[:navigate]}
                patch={item[:patch]}
                href={item[:href]}
              >
                {render_slot(item)}
              </.link>
            <% true -> %>
              <button
                type="button"
                class="lui-breadcrumb-link"
                phx-click={item[:"phx-click"]}
                phx-value-prefix={item[:"phx-value-prefix"]}
                phx-target={item[:"phx-target"]}
              >
                {render_slot(item)}
              </button>
          <% end %>
        </li>
      </ol>
    </nav>
    """
  end
end
