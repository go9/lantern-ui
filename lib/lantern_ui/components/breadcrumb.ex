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

  attr(:class, :any, default: nil)
  attr(:separator, :string, default: "/")
  attr(:aria_label, :string, default: "Breadcrumb")
  attr(:rest, :global)

  slot :item, required: true do
    attr(:current, :boolean)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:href, :string)
    attr(:"phx-click", :string)
    attr(:"phx-value-prefix", :string)
    attr(:"phx-target", :any)
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
