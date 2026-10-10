defmodule LanternUI.ThumbnailTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias LanternUI.Components.Thumbnail

  test "image source gets an accessible focusable preview trigger" do
    html =
      render_component(&Thumbnail.thumbnail/1,
        id: "item-photo",
        src: "/item.jpg",
        alt: "Item",
        size: "md"
      )

    assert html =~ ~s(id="item-photo")
    assert html =~ ~s(phx-hook="LanternThumbnail")
    assert html =~ ~s(data-preview-src="/item.jpg")
    assert html =~ ~s(aria-label="Preview Item")
    assert html =~ ~s(data-size="md")
  end

  test "missing source keeps a non-interactive placeholder" do
    html = render_component(&Thumbnail.thumbnail/1, id: "missing-photo", src: nil, alt: "Item")

    assert html =~ ~s(id="missing-photo")
    assert html =~ ~s(class="lui-thumbnail lui-thumbnail-empty")
    assert html =~ ~s(aria-label="No image")
    refute html =~ "phx-hook"
    refute html =~ "<button"
  end
end
