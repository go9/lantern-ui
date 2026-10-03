defmodule LanternUI.ShadcnGallery do
  @moduledoc """
  Static gallery of the ten step-1 components (flicker #3420): button, input,
  textarea, select trigger, badge, card, alert, table, tabs, separator.

  Rendered by `LanternUI.ShadcnPresetTest` into `test/fixtures/shadcn_gallery/`
  as full HTML documents (CSS inlined) in the default theme and the shadcn
  preset, light + dark — the visual regression baseline for the preset.
  """

  use Phoenix.Component

  alias LanternUI.Components.Alert
  alias LanternUI.Components.Badge
  alias LanternUI.Components.Button
  alias LanternUI.Components.Card
  alias LanternUI.Components.Form
  alias LanternUI.Components.Select
  alias LanternUI.Components.Separator
  alias LanternUI.Components.Table
  alias LanternUI.Components.Tabs
  alias LanternUI.Components.Textarea

  attr(:theme, :string, default: nil, doc: "nil for default theme, \"shadcn\" for the preset.")
  attr(:dark, :boolean, default: false, doc: "Render the shell with the .dark class.")

  def document(assigns) do
    css =
      [
        "priv/static/lantern_ui.css",
        "priv/static/lantern_ui_theme.css"
      ]
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")

    assigns = assign(assigns, :css, css)

    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-lantern-theme={@theme} class={@dark && "dark"}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>lantern-ui shadcn preset gallery</title>
        {Phoenix.HTML.raw(
          "<style>body { margin: 0; padding: 2rem; background: var(--lantern-surface); }" <>
            @css <> "</style>"
        )}
      </head>
      <body>
        <.page />
      </body>
    </html>
    """
  end

  def page(assigns) do
    ~H"""
    <div style="max-width: 880px; margin: 0 auto; display: flex; flex-direction: column; gap: 2rem; font-family: var(--lantern-font); color: var(--lantern-fg);">
      <section data-gallery="button">
        <h2>Button</h2>
        <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: center;">
          <Button.button variant="solid">Default</Button.button>
          <Button.button variant="solid" size="sm">Small</Button.button>
          <Button.button variant="outline">Outline</Button.button>
          <Button.button variant="ghost">Ghost</Button.button>
          <Button.button variant="solid" color="danger">Destructive</Button.button>
          <Button.button variant="solid" disabled>Disabled</Button.button>
        </div>
      </section>

      <section data-gallery="input">
        <h2>Input</h2>
        <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
          <Form.input id="g-name" name="name" label="Name" placeholder="Ada Lovelace" />
          <Form.input id="g-name-sm" name="name_sm" size="sm" label="Small" placeholder="h-8" />
          <Form.input id="g-name-off" name="name_off" label="Disabled" value="read only" disabled />
        </div>
      </section>

      <section data-gallery="textarea">
        <h2>Textarea</h2>
        <Textarea.textarea
          id="g-bio"
          name="bio"
          label="Bio"
          placeholder="Tell us about yourself"
          value=""
        />
      </section>

      <section data-gallery="select">
        <h2>Select trigger</h2>
        <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
          <Select.select
            id="g-fruit"
            name="fruit"
            label="Fruit"
            options={[{"Apple", "apple"}, {"Banana", "banana"}, {"Cherry", "cherry"}]}
          />
          <Select.select
            id="g-fruit-sm"
            name="fruit_sm"
            size="sm"
            label="Small"
            options={[{"Apple", "apple"}, {"Banana", "banana"}]}
            value="banana"
          />
        </div>
      </section>

      <section data-gallery="badge">
        <h2>Badge</h2>
        <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: center;">
          <Badge.badge>Default</Badge.badge>
          <Badge.badge variant="solid" color="primary">Primary</Badge.badge>
          <Badge.badge variant="soft" color="success">Active</Badge.badge>
          <Badge.badge variant="soft" color="warning">Pending</Badge.badge>
          <Badge.badge variant="soft" color="danger">Failed</Badge.badge>
          <Badge.badge variant="outline">Outline</Badge.badge>
        </div>
      </section>

      <section data-gallery="card">
        <h2>Card</h2>
        <Card.card title="Card title" description="Muted description line.">
          <p style="margin: 0;">Body copy sits on the raised surface.</p>
          <:footer>Footer strip</:footer>
        </Card.card>
      </section>

      <section data-gallery="alert">
        <h2>Alert</h2>
        <div style="display: flex; flex-direction: column; gap: 0.75rem;">
          <Alert.alert color="info" title="Heads up">This is an informational alert.</Alert.alert>
          <Alert.alert color="success" title="Saved">Your changes were stored.</Alert.alert>
          <Alert.alert color="warning" title="Unsaved">Discard or save before leaving.</Alert.alert>
          <Alert.alert color="danger" title="Error">Something went wrong.</Alert.alert>
        </div>
      </section>

      <section data-gallery="table">
        <h2>Table</h2>
        <Table.table>
          <Table.table_head>
            <:col>Name</:col>
            <:col>Status</:col>
            <:col>Total</:col>
          </Table.table_head>
          <Table.table_body>
            <Table.table_row>
              <:cell>Ada Lovelace</:cell>
              <:cell>Active</:cell>
              <:cell>$1,200</:cell>
            </Table.table_row>
            <Table.table_row>
              <:cell>Grace Hopper</:cell>
              <:cell>Pending</:cell>
              <:cell>$850</:cell>
            </Table.table_row>
            <Table.table_row selected>
              <:cell>Alan Turing</:cell>
              <:cell>Active</:cell>
              <:cell>$2,040</:cell>
            </Table.table_row>
          </Table.table_body>
        </Table.table>
      </section>

      <section data-gallery="tabs">
        <h2>Tabs</h2>
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <Tabs.tabs_list active_tab="all" aria-label="Segmented example">
            <:tab name="all">All</:tab>
            <:tab name="active">Active</:tab>
            <:tab name="backlog">Backlog</:tab>
          </Tabs.tabs_list>
          <Tabs.tabs_list variant="underline" active_tab="all" aria-label="Underline example">
            <:tab name="all">All</:tab>
            <:tab name="active">Active</:tab>
          </Tabs.tabs_list>
        </div>
      </section>

      <section data-gallery="separator">
        <h2>Separator</h2>
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <Separator.separator />
          <Separator.separator text="or continue with" />
        </div>
      </section>
    </div>
    """
  end
end
