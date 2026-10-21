defmodule LanternUI.QA.CiteChipLive do
  @moduledoc false
  use Phoenix.LiveView
  use LanternUI

  def mount(_params, _session, socket), do: {:ok, assign(socket, source: nil)}

  def handle_event("preview", %{"source" => source}, socket) do
    {:noreply, assign(socket, :source, source)}
  end

  def render(assigns) do
    ~H"""
    <.page_shell
      id="cite-chip-demo"
      title="Citation chips"
      style="background: var(--lantern-surface); color: var(--lantern-fg); min-height: 100vh; padding: var(--lantern-space-lg);"
    >
      <p>
        Search uses the project corpus
        <.cite_chip
          id="cite-file"
          number={1}
          label="Open citation: lib/search.ex, lines 12–18"
          active={@source == "file"}
          phx-click="preview"
          phx-value-source="file"
          aria-controls="source-preview"
        >
          search.ex:12–18
        </.cite_chip>
        and links the matching ticket <.cite_chip
          id="cite-ticket"
          number={2}
          label="Open citation: ticket 212, Search scope"
          active={@source == "ticket"}
          phx-click="preview"
          phx-value-source="ticket"
          aria-controls="source-preview"
        >#212</.cite_chip>.
      </p>
      <p>
        Attached context:
        <.cite_chip
          id="cite-memory"
          label="Open citation: memory 167, Project scope policy"
          active={@source == "memory"}
          phx-click="preview"
          phx-value-source="memory"
          aria-controls="source-preview"
        >
          memory
        </.cite_chip>
      </p>
      <aside id="source-preview" aria-label="Source preview" aria-live="polite">
        <p :if={is_nil(@source)}>Choose a citation to preview its source.</p>
        <p :if={@source == "file"}>lib/search.ex:12–18 — Search is scoped to the project corpus.</p>
        <p :if={@source == "ticket"}>#212 — Search scope: keep retrieval within this project.</p>
        <p :if={@source == "memory"}>Memory 167 — Project scope policy.</p>
      </aside>
    </.page_shell>
    """
  end
end
