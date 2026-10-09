defmodule LanternUI.Components.MediaTile do
  @moduledoc """
  A generic, domain-agnostic media container cell for visual grids and cards.

  `media_tile/1` provides a structured, responsive media card with a fixed aspect
  ratio art well, top overlay banner slot, floating corner overlays, structured caption
  rows, and bottom footer actions. It supports loading skeletons, empty states,
  and accessible selection.

      <.media_tile
        image_src="/images/item.jpg"
        image_alt="Vintage Chronograph"
        aspect_ratio="5/7"
      >
        <:banner>
          <.badge variant="soft" color="info">New</.badge>
        </:banner>
        <:overlay>
          <span class="lui-badge">Featured</span>
        </:overlay>
        <:caption>
          <h3>Vintage Chronograph</h3>
          <p>Ref. 145.022 · 1971</p>
          <span>$4,250.00</span>
        </:caption>
        <:footer>
          <span>In Stock</span>
          <.button size="sm">View</.button>
        </:footer>
      </.media_tile>

  ## Aspect ratios

  The media well defaults to `5/7` (standard portrait grid), but any aspect ratio
  may be supplied (e.g. `"1/1"`, `"4/3"`, `"16/9"`, `"3/4"`). The value is normalized
  and passed as `--lui-media-tile-aspect` to CSS.

  ## States

  - `loading`: When `true`, renders a pulsing skeleton well with `aria-busy="true"`.
  - `empty`: When `true` (or when no image or inner content is provided), renders an
    empty media placeholder with an icon and accessible label.
  - `selectable`: When `true`, exposes an accessible selection affordance.
  - `selected`: When `true`, marks the tile with `data-selected` and `aria-selected="true"`.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Skeleton

  attr(:id, :string, default: nil, doc: "Stable DOM id for the tile root.")

  attr(:aspect_ratio, :string,
    default: "5/7",
    doc: "Aspect ratio of the media well (e.g. '5/7', '1/1', '16/9')."
  )

  attr(:image_src, :string, default: nil, doc: "Source URL for the media image.")
  attr(:image_alt, :string, default: "", doc: "Accessible alt text for the image.")

  attr(:image_fit, :string,
    default: "cover",
    values: ~w(cover contain fill none),
    doc: "CSS object-fit behavior."
  )

  attr(:selectable, :boolean, default: false, doc: "Whether the tile can be selected.")
  attr(:selected, :boolean, default: false, doc: "Whether the tile is currently selected.")
  attr(:on_select, :string, default: nil, doc: "LiveView event to emit when selection changes.")
  attr(:loading, :boolean, default: false, doc: "Display skeleton loading state.")
  attr(:empty, :boolean, default: false, doc: "Display empty state placeholder.")
  attr(:empty_text, :string, default: "No image", doc: "Accessible text and message when empty.")

  attr(:href, :string,
    default: nil,
    doc: "Optional navigation target making the tile interactive."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:rest, :global,
    include: ~w(role tabindex aria-label aria-selected aria-busy),
    doc: "Arbitrary HTML or LiveView attributes passed through."
  )

  slot(:banner, doc: "Top overlay banner across the media well.")
  slot(:overlay, doc: "Floating overlays inside the media well (chips, badges, quick actions).")
  slot(:inner_block, doc: "Custom media content inside the well (replaces image).")
  slot(:caption, doc: "Structured text content below the media well.")
  slot(:footer, doc: "Bottom strip below caption.")

  @doc "Renders a generic media tile cell."
  def media_tile(assigns) do
    normalized_ratio = normalize_aspect_ratio(assigns.aspect_ratio)

    is_empty =
      assigns.empty or
        (!assigns.loading and is_nil(assigns.image_src) and assigns.inner_block == [])

    assigns =
      assigns
      |> assign(:aspect_ratio_style, "--lui-media-tile-aspect: #{normalized_ratio};")
      |> assign(:empty?, is_empty)
      |> assign(
        :root_class,
        Class.merge([
          "lui-media-tile",
          assigns.href && "lui-media-tile-linked",
          assigns.selectable && "lui-media-tile-selectable",
          assigns.class
        ])
      )

    ~H"""
    <article
      id={@id}
      class={@root_class}
      phx-hook="LanternMediaTile"
      data-selectable={to_string(@selectable)}
      data-selected={to_string(@selected)}
      data-tile-select={@on_select}
      data-loading={to_string(@loading)}
      data-empty={to_string(@empty?)}
      aria-selected={if @selectable, do: to_string(@selected)}
      aria-busy={if @loading, do: "true"}
      {@rest}
    >
      <.link
        :if={@href}
        navigate={@href}
        class="lui-media-tile-link"
      ></.link>
      <div class="lui-media-tile-well" style={@aspect_ratio_style}>
        <div :if={@loading} class="lui-media-tile-skeleton" aria-hidden="true">
          <Skeleton.skeleton class="lui-media-tile-skeleton-body" />
        </div>

        <div
          :if={!@loading && (@empty? || (@image_src && @inner_block == []))}
          class="lui-media-tile-empty"
          data-part="empty"
          hidden={!@empty?}
          role="img"
          aria-label={@empty_text}
        >
          <svg
            class="lui-icon lui-media-tile-empty-icon"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
          </svg>
          <span class="lui-media-tile-empty-text">{@empty_text}</span>
        </div>

        <div :if={!@loading && !@empty? && @inner_block != []} class="lui-media-tile-content">
          {render_slot(@inner_block)}
        </div>

        <img
          :if={!@loading && !@empty? && @inner_block == [] && @image_src}
          src={@image_src}
          alt={@image_alt}
          class="lui-media-tile-image"
          data-fit={@image_fit}
          loading="lazy"
          data-part="image"
        />

        <div :if={@banner != []} class="lui-media-tile-banner">
          {render_slot(@banner)}
        </div>

        <div :if={@overlay != [] || @selectable} class="lui-media-tile-overlay">
          <div :if={@selectable} class="lui-media-tile-selection" data-part="selection">
            <button
              type="button"
              class="lui-media-tile-checkbox"
              data-checked={to_string(@selected)}
              role="checkbox"
              tabindex="0"
              aria-checked={to_string(@selected)}
              aria-label={"Select " <> (if @image_alt != "", do: @image_alt, else: "item")}
            >
              <svg
                :if={@selected}
                class="lui-icon lui-media-tile-check-icon"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
            </button>
          </div>
          <div :if={@overlay != []} class="lui-media-tile-overlay-content">
            {render_slot(@overlay)}
          </div>
        </div>
      </div>

      <div :if={@caption != []} class="lui-media-tile-caption">
        {render_slot(@caption)}
      </div>

      <div :if={@footer != []} class="lui-media-tile-footer">
        {render_slot(@footer)}
      </div>
    </article>
    """
  end

  @doc """
  Responsive grid container for `media_tile/1` components.

  Renders a CSS grid with consistent column sizing and gap tokens.
  """
  attr(:columns, :integer, default: nil, doc: "Explicit column count.")
  attr(:min, :string, default: "160px", doc: "Minimum tile width when auto-filling columns.")
  attr(:gap, :string, default: nil, doc: "Custom grid gap (e.g. '14px', '1rem').")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the grid container.")
  attr(:rest, :global, doc: "Arbitrary HTML attributes passed through.")
  slot(:inner_block, required: true, doc: "Media tiles to render.")

  def media_tile_grid(assigns) do
    style =
      [
        assigns.columns && "--lui-media-tile-columns: #{assigns.columns}",
        assigns.min && "--lui-media-tile-min: #{assigns.min}",
        assigns.gap && "--lui-media-tile-gap: #{assigns.gap}"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("; ")

    assigns = assign(assigns, :style, if(style != "", do: style, else: nil))

    ~H"""
    <div class={Class.merge(["lui-media-tile-grid", @class])} style={@style} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp normalize_aspect_ratio(ratio) when is_binary(ratio) do
    ratio
    |> String.trim()
    |> String.replace(":", " / ")
    |> case do
      trimmed ->
        if String.contains?(trimmed, "/") and not String.contains?(trimmed, " / ") do
          String.replace(trimmed, "/", " / ")
        else
          trimmed
        end
    end
  end

  defp normalize_aspect_ratio(ratio), do: to_string(ratio)
end
