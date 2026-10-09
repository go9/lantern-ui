defmodule LanternUI.QA.KbdLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(params, _session, socket) do
    theme = if params["theme"] == "dark", do: "dark", else: "light"
    {:ok, assign(socket, theme: theme)}
  end

  def handle_event("toggle_theme", _params, socket) do
    next_theme = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, :theme, next_theme)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="qa-kbd-root"
      data-lantern-theme={@theme}
      style="min-height: 100vh; padding: 2rem; background: var(--lantern-bg); color: var(--lantern-fg); box-sizing: border-box;"
    >
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 2rem;">
        <div>
          <h1 style="font-size: 1.5rem; font-weight: 700; margin: 0 0 0.25rem 0;">
            Keyboard Shortcut Badge (&lt;.kbd&gt;) QA Matrix
          </h1>
          <p style="margin: 0; color: var(--lantern-fg-muted); font-size: 0.875rem;">
            Verifying sizes (xs/sm/md/lg), variants (outline/subtle/solid/ghost), composite keys, and groups
          </p>
        </div>
        <button
          type="button"
          id="theme-toggle"
          phx-click="toggle_theme"
          style="padding: 0.5rem 1rem; border-radius: 6px; border: 1px solid var(--lantern-border); background: var(--lantern-surface); color: var(--lantern-fg); cursor: pointer;"
        >
          Theme: {@theme}
        </button>
      </div>

      <div style="display: flex; flex-direction: column; gap: 2rem;">
        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            1. Variants (sm size)
          </h2>
          <div style="display: flex; align-items: center; gap: 2rem; flex-wrap: wrap;">
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">Outline:</span>
              <.kbd variant="outline">⌘K</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">Subtle:</span>
              <.kbd variant="subtle">⌘K</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">Solid:</span>
              <.kbd variant="solid">⌘K</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">Ghost:</span>
              <.kbd variant="ghost">⌘K</.kbd>
            </div>
          </div>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            2. Size Scale (xs, sm, md, lg)
          </h2>
          <div style="display: flex; align-items: center; gap: 2rem; flex-wrap: wrap;">
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">xs:</span>
              <.kbd size="xs">Esc</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">sm:</span>
              <.kbd size="sm">Esc</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">md:</span>
              <.kbd size="md">Esc</.kbd>
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">lg:</span>
              <.kbd size="lg">Esc</.kbd>
            </div>
          </div>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            3. Composite Keys and Symbol Mapping
          </h2>
          <div style="display: flex; align-items: center; gap: 2rem; flex-wrap: wrap;">
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">{"keys=[:command, \"K\"]:"}</span>
              <.kbd keys={[:command, "K"]} />
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">{"keys=[:ctrl, :shift, \"P\"]:"}</span>
              <.kbd keys={[:ctrl, :shift, "P"]} />
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">{"keys=[:alt, \"Tab\"]:"}</span>
              <.kbd keys={[:alt, "Tab"]} />
            </div>
            <div style="display: flex; align-items: center; gap: 0.5rem;">
              <span style="font-size: 0.875rem; color: var(--lantern-fg-muted);">{"keys=[:up, :down, :left, :right]:"}</span>
              <.kbd keys={[:up, :down, :left, :right]} />
            </div>
          </div>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            4. Keyboard Groups with Separator
          </h2>
          <div style="display: flex; align-items: center; gap: 2rem; flex-wrap: wrap;">
            <.kbd_group>
              <.kbd>⌘</.kbd>
              <span class="lui-kbd-sep">+</span>
              <.kbd>Shift</.kbd>
              <span class="lui-kbd-sep">+</span>
              <.kbd>E</.kbd>
            </.kbd_group>
            <.kbd_group>
              <.kbd>Ctrl</.kbd>
              <span class="lui-kbd-sep">+</span>
              <.kbd>Alt</.kbd>
              <span class="lui-kbd-sep">+</span>
              <.kbd>Del</.kbd>
            </.kbd_group>
          </div>
        </section>

        <section style="background: var(--lantern-surface); border: 1px solid var(--lantern-border); border-radius: 8px; padding: 1.5rem;">
          <h2 style="font-size: 1.1rem; font-weight: 600; margin-top: 0; margin-bottom: 1rem;">
            5. In-Context Usage (Command palette triggers and shortcuts)
          </h2>
          <div style="display: flex; flex-direction: column; gap: 0.75rem; max-width: 420px;">
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem 0.85rem; background: var(--lantern-surface-raised); border: 1px solid var(--lantern-border); border-radius: 6px;">
              <span style="font-size: 0.875rem;">Quick open file</span>
              <.kbd keys={[:command, "P"]} />
            </div>
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem 0.85rem; background: var(--lantern-surface-raised); border: 1px solid var(--lantern-border); border-radius: 6px;">
              <span style="font-size: 0.875rem;">Toggle terminal</span>
              <.kbd keys={[:ctrl, "`"]} />
            </div>
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.6rem 0.85rem; background: var(--lantern-surface-raised); border: 1px solid var(--lantern-border); border-radius: 6px;">
              <span style="font-size: 0.875rem;">Close active tab</span>
              <.kbd keys={[:command, "W"]} />
            </div>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
