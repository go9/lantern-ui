defmodule LanternUI.Components.Breadcrumb do
  @moduledoc """
  Compact path breadcrumb — layout chrome + file/tree navigation.

  Product-app chrome (goprint-style: home icon + chevrons + labels):

      <.breadcrumb home="/" items={[
        %{label: "Acme", path: "/o/acme"},
        %{label: "Tickets", path: nil}
      ]} />

  Interactive / S3 explorer (slot API):

      <.breadcrumb aria_label="Object path">
        <:item navigate="/b">my-bucket</:item>
        <:item phx-click="navigate" phx-value-prefix="photos/">photos</:item>
        <:item current>2026</:item>
      </.breadcrumb>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:items, :list,
    default: [],
    doc: "Optional list of %{label:, path: | nil} maps (alternative to :item slots)."
  )

  attr(:home, :string,
    default: nil,
    doc: "When set, renders a leading home-icon crumb linking here (product chrome)."
  )

  attr(:separator, :string,
    default: nil,
    doc: "Optional text separator between items. Default is a chevron icon."
  )

  attr(:aria_label, :string, default: "Breadcrumb", doc: "Accessible name for the nav landmark.")
  attr(:rest, :global, doc: "Arbitrary HTML/phx-* attributes passed through.")

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
        <li :if={@home} class="lui-breadcrumb-item">
          <.link navigate={@home} class="lui-breadcrumb-home" aria-label="Home">
            <.home_icon />
          </.link>
        </li>

        <%= if @item != [] do %>
          <li :for={{item, i} <- Enum.with_index(@item)} class="lui-breadcrumb-item">
            <.sep :if={i > 0 or @home} separator={@separator} />
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
            <.sep :if={i > 0 or @home} separator={@separator} />
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

  attr(:separator, :string, default: nil)

  defp sep(%{separator: sep} = assigns) when is_binary(sep) and sep != "" do
    ~H"""
    <span class="lui-breadcrumb-sep" aria-hidden="true">{@separator}</span>
    """
  end

  defp sep(assigns) do
    ~H"""
    <span class="lui-breadcrumb-sep" aria-hidden="true"><.chevron_icon /></span>
    """
  end

  defp home_icon(assigns) do
    ~H"""
    <svg class="lui-breadcrumb-icon" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
      <path d="M9.293 2.293a1 1 0 0 1 1.414 0l7 7A1 1 0 0 1 17 11h-1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6H3a1 1 0 0 1-.707-1.707l7-7Z" />
    </svg>
    """
  end

  defp chevron_icon(assigns) do
    ~H"""
    <svg
      class="lui-breadcrumb-icon lui-breadcrumb-chevron"
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="true"
    >
      <path
        fill-rule="evenodd"
        d="M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  defp item_label(item), do: item[:label] || item["label"] || ""
  defp item_path(item), do: item[:path] || item["path"]
end
