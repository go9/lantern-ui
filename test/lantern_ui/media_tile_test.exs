defmodule LanternUI.MediaTileTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LanternUI.Components.MediaTile

  defp render(fun, assigns \\ %{}) do
    fun.(Map.put(assigns, :__changed__, nil)) |> rendered_to_string()
  end

  describe "media_tile/1" do
    test "renders standard media tile with image and aspect ratio" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile
            id="item-1"
            image_src="/images/item.jpg"
            image_alt="Chronograph"
            aspect_ratio="5/7"
          />
          """
        end)

      assert html =~ ~s(id="item-1")
      assert html =~ ~s(class="lui-media-tile")
      assert html =~ ~s(src="/images/item.jpg")
      assert html =~ ~s(alt="Chronograph")
      assert html =~ "--lui-media-tile-aspect: 5 / 7;"
      assert html =~ ~s(data-selectable="false")
      assert html =~ ~s(data-selected="false")
      assert html =~ ~s(data-loading="false")
      assert html =~ ~s(data-empty="false")
    end

    test "normalizes colon and slash aspect ratios" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile aspect_ratio="16:9" />
          """
        end)

      assert html =~ "--lui-media-tile-aspect: 16 / 9;"

      html_square =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile aspect_ratio="1/1" />
          """
        end)

      assert html_square =~ "--lui-media-tile-aspect: 1 / 1;"
    end

    test "renders slots: :banner, :overlay, :caption, and :footer" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile image_src="/item.png" image_alt="Item">
            <:banner>
              <span class="banner-tag">NEW RELEASE</span>
            </:banner>
            <:overlay>
              <span class="corner-chip">TOP</span>
            </:overlay>
            <:caption>
              <h3 class="tile-title">Title Here</h3>
              <span class="tile-price">$120.00</span>
            </:caption>
            <:footer>
              <span class="stock-status">In Stock</span>
              <button type="button">Buy</button>
            </:footer>
          </MediaTile.media_tile>
          """
        end)

      assert html =~ "banner-tag"
      assert html =~ "NEW RELEASE"
      assert html =~ "corner-chip"
      assert html =~ "TOP"
      assert html =~ "tile-title"
      assert html =~ "Title Here"
      assert html =~ "tile-price"
      assert html =~ "$120.00"
      assert html =~ "stock-status"
      assert html =~ "In Stock"
      assert html =~ "lui-media-tile-banner"
      assert html =~ "lui-media-tile-overlay"
      assert html =~ "lui-media-tile-caption"
      assert html =~ "lui-media-tile-footer"
    end

    test "renders custom inner content in place of image" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile>
            <div class="custom-media">SVG Artwork</div>
          </MediaTile.media_tile>
          """
        end)

      assert html =~ "lui-media-tile-content"
      assert html =~ "custom-media"
      assert html =~ "SVG Artwork"
      refute html =~ "<img"
    end

    test "loading state renders skeleton placeholder and aria-busy" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile loading image_src="/item.jpg" />
          """
        end)

      assert html =~ ~s(data-loading="true")
      assert html =~ ~s(aria-busy="true")
      assert html =~ "lui-media-tile-skeleton"
      assert html =~ "lui-skeleton"
      refute html =~ "<img"
    end

    test "empty state renders placeholder with icon and text" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile empty empty_text="No preview available" />
          """
        end)

      assert html =~ ~s(data-empty="true")
      assert html =~ "lui-media-tile-empty"
      assert html =~ ~s(aria-label="No preview available")
      assert html =~ "No preview available"
      refute html =~ "<img"
    end

    test "auto-detects empty state when no image or inner content is provided" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile />
          """
        end)

      assert html =~ ~s(data-empty="true")
      assert html =~ "lui-media-tile-empty"
    end

    test "selectable and selected state renders selection affordance and aria attributes" do
      html_unselected =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile selectable={true} selected={false} image_src="/pic.jpg" image_alt="Item 1" />
          """
        end)

      assert html_unselected =~ ~s(data-selectable="true")
      assert html_unselected =~ ~s(data-selected="false")
      assert html_unselected =~ ~s(aria-selected="false")
      assert html_unselected =~ "lui-media-tile-selection"
      assert html_unselected =~ ~s(role="checkbox")
      assert html_unselected =~ ~s(type="button")
      assert html_unselected =~ ~s(tabindex="0")
      assert html_unselected =~ ~s(phx-hook="LanternMediaTile")
      assert html_unselected =~ ~s(aria-checked="false")
      refute html_unselected =~ "lui-media-tile-check-icon"

      html_selected =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile selectable={true} selected={true} image_src="/pic.jpg" image_alt="Item 1" />
          """
        end)

      assert html_selected =~ ~s(data-selectable="true")
      assert html_selected =~ ~s(data-selected="true")
      assert html_selected =~ ~s(aria-selected="true")
      assert html_selected =~ ~s(aria-checked="true")
      assert html_selected =~ "lui-media-tile-check-icon"
    end

    test "renders the consumer selection event on its hooked root" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile id="item-1" selectable on_select="toggle_item" />
          """
        end)

      assert html =~ ~s(data-tile-select="toggle_item")
      assert html =~ ~s(phx-hook="LanternMediaTile")
    end

    test "linked tile renders navigation link and linked class" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile href="/items/42" image_src="/pic.jpg" image_alt="Item 42" />
          """
        end)

      assert html =~ "lui-media-tile-linked"
      assert html =~ ~s(href="/items/42")
      assert html =~ "lui-media-tile-link"
    end
  end

  describe "media_tile_grid/1" do
    test "renders responsive grid with min width and columns styles" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile_grid min="180px" gap="1rem">
            <MediaTile.media_tile id="t1" />
            <MediaTile.media_tile id="t2" />
          </MediaTile.media_tile_grid>
          """
        end)

      assert html =~ "lui-media-tile-grid"
      assert html =~ "--lui-media-tile-min: 180px"
      assert html =~ "--lui-media-tile-gap: 1rem"
      assert html =~ ~s(id="t1")
      assert html =~ ~s(id="t2")
    end

    test "renders fixed columns when requested" do
      html =
        render(fn assigns ->
          ~H"""
          <MediaTile.media_tile_grid columns={4}>
            <MediaTile.media_tile id="t1" />
          </MediaTile.media_tile_grid>
          """
        end)

      assert html =~ "--lui-media-tile-columns: 4"
    end
  end
end
