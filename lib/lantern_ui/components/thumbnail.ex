defmodule LanternUI.Components.Thumbnail do
  @moduledoc """
  Fixed square image for dense rows. A missing source keeps the same footprint;
  an available image opens a larger preview on hover or keyboard focus.

      <.thumbnail id="row-image" src={@image_url} alt={@name} size="sm" />
  """
  use Phoenix.Component

  alias LanternUI.Components.Icon

  attr(:id, :string, required: true, doc: "Stable DOM id for the preview hook.")
  attr(:src, :string, default: nil, doc: "Image URL, or nil for a neutral placeholder.")
  attr(:alt, :string, default: "", doc: "Image description and preview button label.")
  attr(:size, :string, default: "sm", values: ~w(sm md), doc: "Square thumbnail size.")
  attr(:class, :any, default: nil, doc: "Extra classes on the thumbnail.")

  def thumbnail(assigns) do
    ~H"""
    <button
      :if={@src}
      id={@id}
      type="button"
      class={["lui-thumbnail", @class]}
      data-size={@size}
      data-preview-src={@src}
      data-preview-alt={@alt}
      aria-label={"Preview #{@alt}"}
      phx-hook="LanternThumbnail"
    >
      <img src={@src} alt="" loading="lazy" />
    </button>
    <span
      :if={!@src}
      id={@id}
      class={["lui-thumbnail", "lui-thumbnail-empty", @class]}
      data-size={@size}
      role="img"
      aria-label="No image"
    >
      <Icon.icon name="photo" />
    </span>
    """
  end
end
