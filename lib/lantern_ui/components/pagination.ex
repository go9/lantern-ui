defmodule LanternUI.Components.Pagination do
  @moduledoc """
  Pager + page-size control for paginated collections (a lantern-ui extension;
  Fluxon has no pagination component — this replaces flop_phoenix's pager).

  Meta is duck-typed against `Flop.Meta`'s shape (`current_page`,
  `total_pages`, `page_size`, `total_count`), so lantern_ui needs no flop
  dependency — pass a `Flop.Meta` struct or any map with those keys.

      <.pagination meta={@meta} patch_fn={fn params -> ~p"/orders?\#{params}" end} />

  `patch_fn` receives `%{page: n}` or `%{page: 1, page_size: s}` and returns
  the patch path — the caller owns URL construction. Everything is
  patch-navigation, so pagination state lives in the URL.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Dropdown
  alias LanternUI.Components.Icon

  attr(:meta, :map,
    required: true,
    doc: "Flop.Meta or any map with current_page/total_pages/page_size/total_count"
  )

  attr(:patch_fn, :any, required: true, doc: "fn %{page: n} | %{page: 1, page_size: s} -> path")
  attr(:id, :string, default: "pagination", doc: "Base id for the page-size dropdown.")

  attr(:page_size_options, :list,
    default: [10, 25, 50, 100],
    doc: "Choices in the page-size menu."
  )

  attr(:show_page_size, :boolean, default: true, doc: "Show the page-size dropdown control.")
  attr(:sibling_count, :integer, default: 1, doc: "Page numbers shown on each side of current.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  def pagination(assigns) do
    page = Map.get(assigns.meta, :current_page) || 1
    total = max(Map.get(assigns.meta, :total_pages) || 1, 1)

    assigns =
      assigns
      |> assign(:page, page)
      |> assign(:total, total)
      |> assign(:pages, window(page, total, assigns.sibling_count))
      |> assign(:page_size, Map.get(assigns.meta, :page_size))
      |> assign(:total_count, Map.get(assigns.meta, :total_count))

    ~H"""
    <nav class={Class.merge(["lui-pagination", @class])} aria-label="Pagination" {@rest}>
      <span :if={@total_count} class="lui-pagination-count">
        {@total_count} {if @total_count == 1, do: "result", else: "results"}
      </span>

      <Dropdown.dropdown :if={@show_page_size && @page_size} id={"#{@id}-size"} placement="top-end">
        <:toggle>
          <button type="button" class="lui-pg lui-pg-size">
            {@page_size} / page <Icon.icon name="chevron-up-down" />
          </button>
        </:toggle>
        <Dropdown.dropdown_link
          :for={size <- @page_size_options}
          patch={@patch_fn.(%{page: 1, page_size: size})}
          data-selected={size == @page_size || nil}
        >
          {size} / page
        </Dropdown.dropdown_link>
      </Dropdown.dropdown>

      <div class="lui-pager">
        <.pg_link disabled={@page <= 1} patch={@patch_fn.(%{page: @page - 1})} label="Previous page">
          <Icon.icon name="chevron-left" />
        </.pg_link>
        <%= for p <- @pages do %>
          <span :if={p == :gap} class="lui-pg-gap" aria-hidden="true">…</span>
          <.link
            :if={p != :gap}
            patch={@patch_fn.(%{page: p})}
            class={Class.merge(["lui-pg", p == @page && "lui-pg-current"])}
            aria-current={if p == @page, do: "page"}
          >
            {p}
          </.link>
        <% end %>
        <.pg_link disabled={@page >= @total} patch={@patch_fn.(%{page: @page + 1})} label="Next page">
          <Icon.icon name="chevron-right" />
        </.pg_link>
      </div>
    </nav>
    """
  end

  attr(:disabled, :boolean, required: true, doc: "Render as a non-interactive span.")
  attr(:patch, :string, required: true, doc: "LiveView patch path for this control.")
  attr(:label, :string, required: true, doc: "Accessible label for the control.")
  slot(:inner_block, required: true, doc: "Control contents (usually an icon).")

  defp pg_link(%{disabled: true} = assigns) do
    ~H"""
    <span class="lui-pg lui-pg-disabled" aria-disabled="true" aria-label={@label}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp pg_link(assigns) do
    ~H"""
    <.link patch={@patch} class="lui-pg" aria-label={@label}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc false
  # Page window with :gap markers: 1 … (page±sibling_count) … total.
  def window(page, total, sib) do
    ([1] ++ Enum.to_list(max(page - sib, 1)..min(page + sib, total)) ++ [total])
    |> Enum.filter(&(&1 in 1..total))
    |> Enum.uniq()
    |> Enum.sort()
    |> insert_gaps()
  end

  defp insert_gaps([a, b | rest]) when b - a > 1, do: [a, :gap | insert_gaps([b | rest])]
  defp insert_gaps([a | rest]), do: [a | insert_gaps(rest)]
  defp insert_gaps([]), do: []
end
