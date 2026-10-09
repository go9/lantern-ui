defmodule LanternUI.QA.TilesLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"

    {:ok,
     assign(socket,
       theme: theme,
       selected_ids: ["tile-2"],
       page_title: "Media Tile QA"
     ), layout: false}
  end

  def handle_event("toggle_tile", %{"id" => id, "selected" => selected}, socket) do
    new_selected =
      if selected do
        Enum.uniq([id | socket.assigns.selected_ids])
      else
        List.delete(socket.assigns.selected_ids, id)
      end

    {:noreply, assign(socket, selected_ids: new_selected)}
  end

  def render(assigns) do
    ~H"""
    <style>
      .lui-tiles-qa { width: 100%; min-height: 100vh; box-sizing: border-box; margin: 0; padding: 2rem; background: var(--lantern-bg); color: var(--lantern-fg); }
      .lui-tiles-qa.dark { background: #09090b; color: #f4f4f5; color-scheme: dark; }
      .lui-tiles-qa header { max-width: 72rem; margin: 0 auto 1.5rem; }
      .lui-tiles-qa header h1 { margin: 0 0 .5rem; font-size: 1.5rem; }
      .lui-tiles-qa header p { margin: 0; color: var(--lantern-fg-muted); font-size: .875rem; }
      .lui-tiles-qa section { max-width: 72rem; margin: 0 auto 2.5rem; }
      .lui-tiles-qa section h2 { font-size: 1.125rem; margin-bottom: 1rem; border-bottom: 1px solid var(--lantern-border); padding-bottom: .5rem; }
      .sample-badge { display: inline-block; padding: 2px 8px; border-radius: 9999px; font-size: 11px; font-weight: 600; text-transform: uppercase; background: var(--lantern-primary); color: #fff; }
      .sample-chip { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 500; background: rgba(0,0,0,0.6); color: #fff; backdrop-filter: blur(4px); }
      @media (max-width: 40rem) { .lui-tiles-qa { padding: 1rem; } }
    </style>
    <main class={"lui-tiles-qa #{@theme}"}>
      <header>
        <h1>Media Tile Showcase</h1>
        <p>Generic cell primitive for visual inventory, media grids, and catalog browsing</p>
      </header>

      <section>
        <h2>Default Aspect Ratio (5/7) Grid</h2>
        <.media_tile_grid min="180px">
          <.media_tile
            id="tile-1"
            aspect_ratio="5/7"
            image_src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='250' height='350' viewBox='0 0 250 350'><rect width='250' height='350' fill='%236366f1'/><circle cx='125' cy='140' r='60' fill='%23818cf8'/><rect x='45' y='230' width='160' height='20' rx='4' fill='%23c7d2fe'/><rect x='75' y='265' width='100' height='15' rx='4' fill='%23e0e7ff'/></svg>"
            image_alt="Chronograph"
            selectable
            selected={"tile-1" in @selected_ids}
            on_select="toggle_tile"
          >
            <:banner>
              <div style="padding: 6px; text-align: center;">
                <span class="sample-badge">Featured</span>
              </div>
            </:banner>
            <:overlay>
              <span class="sample-chip">Featured item</span>
            </:overlay>
            <:caption>
              <strong style="font-size: 0.875rem;">Automatic Chronograph</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Reference 2915-1</span>
              <span style="font-weight: 600; font-size: 0.875rem; margin-top: 4px;">$14,500</span>
            </:caption>
            <:footer>
              <span>Quality checked</span>
              <.button size="sm" variant="ghost">View</.button>
            </:footer>
          </.media_tile>

          <.media_tile
            id="tile-2"
            aspect_ratio="5/7"
            image_src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='250' height='350' viewBox='0 0 250 350'><rect width='250' height='350' fill='%23059669'/><circle cx='125' cy='140' r='50' fill='%2334d399'/><rect x='45' y='230' width='160' height='20' rx='4' fill='%23a7f3d0'/></svg>"
            image_alt="Vintage Diver"
            selectable
            selected={"tile-2" in @selected_ids}
            on_select="toggle_tile"
          >
            <:overlay>
              <span class="sample-chip">SELECTED</span>
            </:overlay>
            <:caption>
              <strong style="font-size: 0.875rem;">Vintage Diver 300M</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Matte Dial · 1968</span>
              <span style="font-weight: 600; font-size: 0.875rem; margin-top: 4px;">$9,200</span>
            </:caption>
            <:footer>
              <span>Available</span>
              <.button size="sm" variant="outline">Inspect</.button>
            </:footer>
          </.media_tile>

          <.media_tile
            id="tile-3"
            aspect_ratio="5/7"
            loading
          >
            <:caption>
              <strong style="font-size: 0.875rem;">Loading Artifact...</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Fetching records</span>
            </:caption>
          </.media_tile>

          <.media_tile
            id="tile-4"
            aspect_ratio="5/7"
            empty
            empty_text="Pending Photography"
          >
            <:caption>
              <strong style="font-size: 0.875rem;">Uncataloged Item</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Intake in progress</span>
            </:caption>
            <:footer>
              <span>Awaiting Image</span>
            </:footer>
          </.media_tile>
        </.media_tile_grid>
      </section>

      <section>
        <h2>Alternative Aspect Ratios & Linked Tiles</h2>
        <.media_tile_grid min="220px">
          <.media_tile
            id="tile-square"
            aspect_ratio="1/1"
            href="#view-square"
            image_src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300' viewBox='0 0 300 300'><rect width='300' height='300' fill='%230284c7'/><polygon points='150,50 250,230 50,230' fill='%2338bdf8'/></svg>"
            image_alt="Square Artwork"
          >
            <:banner>
              <div style="padding: 4px 8px; background: rgba(0,0,0,0.4); color: white; font-size: 10px; font-weight: 600;">
                1:1 SQUARE
              </div>
            </:banner>
            <:caption>
              <strong style="font-size: 0.875rem;">Square Ratio (1/1)</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Linked Tile (Entire card clickable)</span>
            </:caption>
          </.media_tile>

          <.media_tile
            id="tile-wide"
            aspect_ratio="16/9"
            href="#view-wide"
            image_src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='320' height='180' viewBox='0 0 320 180'><rect width='320' height='180' fill='%23d97706'/><circle cx='80' cy='90' r='40' fill='%23fbbf24'/><circle cx='240' cy='90' r='40' fill='%23fef08a'/></svg>"
            image_alt="Widescreen Banner"
          >
            <:banner>
              <div style="padding: 4px 8px; background: rgba(0,0,0,0.4); color: white; font-size: 10px; font-weight: 600;">
                16:9 WIDESCREEN
              </div>
            </:banner>
            <:caption>
              <strong style="font-size: 0.875rem;">Widescreen (16/9)</strong>
              <span style="color: var(--lantern-fg-muted); font-size: 0.75rem;">Banner or landscape imagery</span>
            </:caption>
          </.media_tile>
        </.media_tile_grid>
      </section>
    </main>
    """
  end
end
