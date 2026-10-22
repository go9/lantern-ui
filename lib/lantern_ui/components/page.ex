defmodule LanternUI.Components.Page do
  @moduledoc """
  Page-body geometry shared by the index, detail and settings recipes: one
  container (named width, gutters), one body heading, one section, the index
  toolbar and the detail layout. The shell owns chrome, the table owns row
  geometry; these own width, gutters and section rhythm.

      <.page_shell id="projects" layout="bare" title="Projects">
        <.page_container>
          <.page_heading title="Projects" lead="Everything Flicker is watching for you.">
            <:actions><.button size="sm" variant="solid">New project</.button></:actions>
          </.page_heading>
          <.index_toolbar>
            <:search><.input id="q" name="q" type="search" placeholder="Search projects" /></:search>
            <:filters><.button size="sm" variant="outline">Filters</.button></:filters>
          </.index_toolbar>
          <.data_table …/>
        </.page_container>
      </.page_shell>

  Widths are named tokens (`--lui-page-w-*`), not per-page maxima: `narrow`
  (forms, settings), `default`, `wide` (overviews) and `full`. The body heading
  is an `h2`: `page_shell` owns the page's `h1`.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:width, :string,
    default: "default",
    values: ~w(narrow default wide full),
    doc: "Named max width; `full` removes the cap."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Page content: heading, toolbar, sections.")

  @doc "The page container: left-aligned, named max width, page gutters, one section gap."
  def page_container(assigns) do
    ~H"""
    <div class={Class.merge(["lui-page-container", @class])} data-page-width={@width} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:title, :string, required: true, doc: "Body heading (an `h2`).")
  attr(:lead, :string, default: nil, doc: "One supporting sentence under the title.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "The page's primary action(s), right-aligned.")

  @doc "Body heading with an optional lead and the page's primary action."
  def page_heading(assigns) do
    ~H"""
    <header class={Class.merge(["lui-page-heading", @class])} data-page-heading {@rest}>
      <div class="lui-page-heading-text">
        <h2 class="lui-page-heading-title">{@title}</h2>
        <p :if={@lead} class="lui-page-heading-lead">{@lead}</p>
      </div>
      <div :if={@actions != []} class="lui-page-heading-actions">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr(:title, :string, required: true, doc: "Section heading.")
  attr(:description, :string, default: nil, doc: "One supporting line.")
  attr(:id, :string, default: nil, doc: "Element id; also labels the section.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "Quiet actions beside the heading.")
  slot(:inner_block, required: true, doc: "The section's content.")

  @doc "A titled section for detail pages: small heading, one line of description, content."
  def page_section(assigns) do
    ~H"""
    <section
      id={@id}
      class={Class.merge(["lui-page-section", @class])}
      aria-labelledby={@id && "#{@id}-title"}
      {@rest}
    >
      <div class="lui-page-section-head">
        <div class="lui-page-section-text">
          <h3 id={@id && "#{@id}-title"} class="lui-page-section-title">{@title}</h3>
          <p :if={@description} class="lui-page-section-desc">{@description}</p>
        </div>
        <div :if={@actions != []} class="lui-page-section-actions">{render_slot(@actions)}</div>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:search, doc: "The search input (a fixed, compact width).")
  slot(:views, doc: "A view toggle (`tabs_list variant=\"segmented\"`).")
  slot(:filters, doc: "Filter controls; keep to one button or chip row.")

  slot(:actions,
    doc: "Secondary actions, right-aligned. The primary action lives in the heading."
  )

  @doc "One toolbar row: search, view toggle, filters, then actions pushed right."
  def index_toolbar(assigns) do
    ~H"""
    <div class={Class.merge(["lui-index-toolbar", @class])} role="toolbar" {@rest}>
      <div :if={@search != []} class="lui-index-toolbar-search">{render_slot(@search)}</div>
      <div :if={@views != []} class="lui-index-toolbar-views">{render_slot(@views)}</div>
      <div :if={@filters != []} class="lui-index-toolbar-filters">{render_slot(@filters)}</div>
      <div :if={@actions != []} class="lui-index-toolbar-actions">{render_slot(@actions)}</div>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Main column: `page_section`s.")
  slot(:rail, doc: "Optional right rail (properties). Stacks under the main column when narrow.")

  @doc "Main column plus an optional right rail; the rail is a sibling, not a second page."
  def detail_layout(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-detail-layout", @rail != [] && "lui-detail-layout-rail", @class])}
      {@rest}
    >
      <div class="lui-detail-main">{render_slot(@inner_block)}</div>
      <aside :if={@rail != []} class="lui-detail-rail">{render_slot(@rail)}</aside>
    </div>
    """
  end
end
