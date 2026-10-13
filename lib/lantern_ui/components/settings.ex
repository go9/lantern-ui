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
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:actions, doc: "Right-side page actions (rarely needed: sections own their Save).")

  slot(:tabs,
    doc: "A `tabs_list` for related settings groups (patch tabs keep state in the URL)."
  )

  slot(:inner_block, required: true, doc: "settings_section / danger_zone children.")

  def settings_page(assigns) do
    ~H"""
    <div class={Class.merge(["lui-settings-page", @class])} {@rest}>
      <header class="lui-settings-page-header">
        <div class="lui-settings-page-text">
          <h2 class="lui-settings-page-title">{@title}</h2>
          <p :if={@subtitle} class="lui-settings-page-subtitle">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="lui-settings-page-actions">{render_slot(@actions)}</div>
      </header>
      <div :if={@tabs != []} class="lui-settings-page-tabs">{render_slot(@tabs)}</div>
      {render_slot(@inner_block)}
    </div>
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
