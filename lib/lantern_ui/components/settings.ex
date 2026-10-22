defmodule LanternUI.Components.Settings do
  @moduledoc """
  Settings page building blocks: a titled page with optional tabs, two-column
  sections that each save on their own, and a danger zone at the bottom.

      <.settings_page title="Account" subtitle="Manage your profile and preferences.">
        <:tabs>
          <.tabs_list active_tab={@tab} aria-label="Settings">
            <:tab name="general" patch={~p"/settings"}>General</:tab>
            <:tab name="connection" patch={~p"/settings?tab=connection"}>Connection</:tab>
          </.tabs_list>
        </:tabs>

        <.settings_section id="profile" title="Profile" description="Your name and avatar.">
          <.input field={@form[:name]} label="Name" />
          <:actions><.button variant="solid" type="submit">Save</.button></:actions>
        </.settings_section>

        <.danger_zone>
          <.danger_zone_item title="Delete account" description="Removes all data. Cannot be undone.">
            <:action><.button variant="solid" color="danger">Delete</.button></:action>
          </.danger_zone_item>
        </.danger_zone>
      </.settings_page>

  Sections stack with a divider between them; each is a label column (title +
  one-line description) beside the fields, collapsing to one column when the
  page is narrower than 48rem. There is no card or border around a section.

  Give each section its own form so Save submits only that section's fields.
  The divider still draws when sections are wrapped (in a form or any other
  element whose direct child is the section):

      <.form for={@profile_form} phx-submit="save_profile">
        <.settings_section id="profile" title="Profile">…</.settings_section>
      </.form>
      <.form for={@password_form} phx-submit="save_password">
        <.settings_section id="password" title="Password">…</.settings_section>
      </.form>

  ## Stacked layout (the recipe)

  `layout="stacked"` is the settings recipe: a left-aligned container that lines
  up with the page header, a heading and lead, then sections stacked one under
  another, each a heading, one description line and its fields at the narrow
  measure. Use `settings_form/1` for each independent form: ONE Save per form,
  disabled until the form is dirty. Never a Save beside a single field. Add
  `:nav` entries only for genuinely separate, large areas (a vertical section
  list beside the panel); a page of about four small sections is stacked
  sections with no nav at all.

      <.settings_page layout="stacked" title="Settings" lead="Project identity and defaults.">
        <.settings_form for={@form} dirty={@dirty} title="Project" description="Name and slug."
          phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} label="Name" />
        </.settings_form>
        <.danger_zone>…</.danger_zone>
      </.settings_page>

  Render it inside `page_shell/1`, which owns the breadcrumb, page actions and
  the page's `h1`; the settings title is therefore an `h2`.

      <.page_shell id="settings" title="Settings">
        <.settings_page title="Account">…</.settings_page>
      </.page_shell>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:title, :string, required: true, doc: "Page heading.")
  attr(:subtitle, :string, default: nil, doc: "One supporting line under the title.")

  attr(:layout, :string,
    default: "split",
    values: ~w(split stacked),
    doc:
      "`\"split\"` (default): label column beside the fields. " <>
        "`\"stacked\"`: the recipe, heading over fields at the narrow measure, left-aligned."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "Right-side page actions (rarely needed: sections own their Save).")

  slot(:tabs,
    doc: "A `tabs_list` for related settings groups (patch tabs keep state in the URL)."
  )

  slot :nav,
    doc:
      "Section links for genuinely separate, large areas (`layout=\"stacked\"`): a vertical list beside the panel." do
    attr(:patch, :string)
    attr(:navigate, :string)
    attr(:active, :boolean)
    attr(:id, :string)
  end

  attr(:nav_label, :string, default: "Settings sections", doc: "Accessible name for `:nav`.")
  slot(:inner_block, required: true, doc: "settings_section / danger_zone children.")

  def settings_page(assigns) do
    ~H"""
    <div
      class={Class.merge(["lui-settings-page", @class])}
      data-layout={@layout}
      data-has-nav={@nav != [] && "true"}
      {@rest}
    >
      <header class="lui-settings-page-header">
        <div class="lui-settings-page-text">
          <h2 class="lui-settings-page-title">{@title}</h2>
          <p :if={@subtitle} class="lui-settings-page-subtitle">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="lui-settings-page-actions">{render_slot(@actions)}</div>
      </header>
      <div :if={@tabs != []} class="lui-settings-page-tabs">{render_slot(@tabs)}</div>
      <div class="lui-settings-page-body">
        <nav :if={@nav != []} class="lui-settings-nav" aria-label={@nav_label}>
          <.link
            :for={item <- @nav}
            id={item[:id]}
            patch={item[:patch]}
            navigate={item[:navigate]}
            aria-current={item[:active] && "page"}
            class="lui-settings-nav-item"
          >
            {render_slot(item)}
          </.link>
        </nav>
        <div class="lui-settings-panel">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  attr(:for, :any, required: true, doc: "The form (`to_form/2`) or params map.")
  attr(:title, :string, required: true, doc: "Section title.")
  attr(:description, :string, default: nil, doc: "One-line description under the title.")
  attr(:id, :string, default: nil, doc: "Element id; also labels the section.")

  attr(:dirty, :boolean,
    default: false,
    doc:
      "Server-owned: true once the fields differ from what is saved. Save stays disabled until then."
  )

  attr(:save_label, :string, default: "Save", doc: "The form's one Save button.")
  attr(:dirty_label, :string, default: "Unsaved changes", doc: "Shown beside Save while dirty.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the section.")
  attr(:rest, :global, include: ~w(phx-change phx-submit phx-target), doc: "Form attributes.")
  slot(:inner_block, required: true, doc: "The form's fields.")
  slot(:actions, doc: "Extra buttons left of Save (e.g. Cancel). Never a second Save.")

  @doc """
  One independent form as one settings section with ONE Save, disabled until
  `dirty`. Own the dirty flag on the server (compare `form.params` with the
  record in `handle_event("validate", …)`).
  """
  def settings_form(assigns) do
    ~H"""
    <.form for={@for} {@rest}>
      <.settings_section id={@id} title={@title} description={@description} class={@class}>
        {render_slot(@inner_block)}
        <:actions>
          <span class="lui-settings-dirty" role="status">{if @dirty, do: @dirty_label}</span>
          {render_slot(@actions)}
          <LanternUI.Components.Button.button
            type="submit"
            variant="solid"
            size="sm"
            disabled={!@dirty}
          >
            {@save_label}
          </LanternUI.Components.Button.button>
        </:actions>
      </.settings_section>
    </.form>
    """
  end

  attr(:title, :string, required: true, doc: "Section title, shown in the label column.")
  attr(:description, :string, default: nil, doc: "One-line description under the title.")
  attr(:id, :string, default: nil, doc: "Element id; also labels the section for assistive tech.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "The section's fields.")
  slot(:actions, doc: "Footer under the fields, right-aligned (the section's Save button).")

  def settings_section(assigns) do
    ~H"""
    <section
      id={@id}
      class={Class.merge(["lui-settings-section", @class])}
      aria-labelledby={@id && "#{@id}-title"}
      {@rest}
    >
      <div class="lui-settings-section-head">
        <h3 id={@id && "#{@id}-title"} class="lui-settings-section-title">{@title}</h3>
        <p :if={@description} class="lui-settings-section-desc">{@description}</p>
      </div>
      <div class="lui-settings-section-body">
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="lui-settings-section-actions">
          {render_slot(@actions)}
        </div>
      </div>
    </section>
    """
  end

  attr(:title, :string, default: "Danger zone", doc: "Label-column title.")
  attr(:description, :string, default: nil, doc: "Optional line under the title.")
  attr(:id, :string, default: nil, doc: "Element id; also labels the section for assistive tech.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "danger_zone_item rows.")

  @doc """
  The last section of a settings page: a `settings_section` whose body is one
  bordered list of destructive actions.
  """
  def danger_zone(assigns) do
    ~H"""
    <.settings_section
      id={@id}
      title={@title}
      description={@description}
      class={Class.merge(["lui-danger-zone", @class])}
      {@rest}
    >
      <div class="lui-danger-zone-list">{render_slot(@inner_block)}</div>
    </.settings_section>
    """
  end

  attr(:title, :string, required: true, doc: "What the action does.")
  attr(:description, :string, default: nil, doc: "Its consequence, in one line.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:action, required: true, doc: "The destructive control (e.g. a danger button).")

  @doc "One row of a `danger_zone`: title and consequence on the left, the action on the right."
  def danger_zone_item(assigns) do
    ~H"""
    <div class={Class.merge(["lui-danger-zone-item", @class])} {@rest}>
      <div class="lui-danger-zone-item-text">
        <div class="lui-danger-zone-item-title">{@title}</div>
        <p :if={@description} class="lui-danger-zone-item-desc">{@description}</p>
      </div>
      <div class="lui-danger-zone-item-action">{render_slot(@action)}</div>
    </div>
    """
  end
end
