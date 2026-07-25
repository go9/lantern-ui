defmodule LanternUI.Components.Breadcrumb do
  @moduledoc """
  Compact path breadcrumb — layout chrome + file/tree navigation.

  Two call shapes:

      # Slot API (interactive / S3 explorer)
      <.breadcrumb aria_label="Object path">
        <:item navigate="/b">my-bucket</:item>
        <:item phx-click="navigate" phx-value-prefix="photos/">photos</:item>
        <:item current>2026</:item>
      </.breadcrumb>

      # Items list (product app chrome — goprint/flicker)
      <.breadcrumb items={[
        %{label: "Acme", path: "/o/acme"},
        %{label: "Apps", path: nil}
      ]} />

  Links: `navigate` / `patch` / `href` / `path`. Buttons: `phx-*` attrs.
  Last / `current` item is plain text with `aria-current="page"`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:items, :list,
    default: [],
    doc: "Optional list of `%{label:, path: | nil}` maps (alternative to `:item` slots)."
  )

  attr(:separator, :string, default: "›", doc: "Glyph shown between breadcrumb items.")
  attr(:aria_label, :string, default: "Breadcrumb", doc: "Accessible name for the nav landmark.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :item, doc: "One path segment; link, button, or current page." do
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
      <ol class="lui-breadcrumb-list" role="list">
        <%= if @item != [] do %>
          <li :for={{item, i} <- Enum.with_index(@item)} class="lui-breadcrumb-item">
            <span :if={i > 0} class="lui-breadcrumb-sep" aria-hidden="true">{@separator}</span>
            <%= cond do %>
              <% item[:current] || i == length(@item) - 1 -> %>
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
        <% else %>
          <li :for={{item, i} <- Enum.with_index(@items)} class="lui-breadcrumb-item">
            <span :if={i > 0} class="lui-breadcrumb-sep" aria-hidden="true">{@separator}</span>
            <%= if item_path(item) && i < length(@items) - 1 do %>
              <.link class="lui-breadcrumb-link" navigate={item_path(item)}>
                {item_label(item)}
              </.link>
            <% else %>
              <span
                class="lui-breadcrumb-current"
                aria-current={i == length(@items) - 1 && "page"}
              >
                {item_label(item)}
              </span>
            <% end %>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp item_label(item), do: item[:label] || item["label"] || ""
  defp item_path(item), do: item[:path] || item["path"]
end
