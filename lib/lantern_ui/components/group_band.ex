defmodule LanternUI.Components.GroupBand do
  @moduledoc """
  Tinted full-width group header: chevron · glyph · name · count · trailing
  action (the `+`).

      <.group_band name="In progress" count={12}>
        <:glyph><.status_glyph status={:in_progress} /></:glyph>
        <:action navigate="/tickets/new?status=in_progress" label="New ticket in In progress">
          <.icon name="plus" />
        </:action>
      </.group_band>

      <.group_band name="Done" count={40} collapsed patch="/tickets?show_done=1">
        <:glyph><.status_glyph status={:done} /></:glyph>
      </.group_band>

  A collapsed band with `navigate`/`patch`/`href` makes the name row the expand
  control (chevron points right). Expanded bands show a down chevron.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:name, :string, required: true, doc: "Group label (status name, section title).")
  attr(:count, :any, default: nil, doc: "Optional count shown after the name.")
  attr(:collapsed, :boolean, default: false, doc: "When true, chevron points right.")
  attr(:navigate, :string, default: nil, doc: "LiveView navigate on the name row.")
  attr(:patch, :string, default: nil, doc: "LiveView patch on the name row.")
  attr(:href, :any, default: nil, doc: "Href on the name row.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the band.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:glyph, doc: "Leading glyph (status circle, etc.).")

  slot :action,
    doc: "Trailing control, typically a + that files into this group." do
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:href, :any)
    attr(:label, :string)
    attr(:class, :any)
  end

  def group_band(assigns) do
    assigns =
      assigns
      |> assign(:link?, assigns.navigate || assigns.patch || assigns.href)
      |> assign(:chevron, if(assigns.collapsed, do: "chevron-right", else: "chevron-down"))

    ~H"""
    <div class={Class.merge(["lui-group-band", @class])} data-collapsed={@collapsed || nil} {@rest}>
      <.link
        :if={@link?}
        class="lui-group-band-main"
        navigate={@navigate}
        patch={@patch}
        href={@href}
      >
        <span class="lui-group-band-chevron" aria-hidden="true">
          <Icon.icon name={@chevron} />
        </span>
        <span :if={@glyph != []} class="lui-group-band-glyph">{render_slot(@glyph)}</span>
        <span class="lui-group-band-name">{@name}</span>
        <span :if={not is_nil(@count)} class="lui-group-band-count">{@count}</span>
      </.link>
      <span :if={!@link?} class="lui-group-band-main">
        <span class="lui-group-band-chevron" aria-hidden="true">
          <Icon.icon name={@chevron} />
        </span>
        <span :if={@glyph != []} class="lui-group-band-glyph">{render_slot(@glyph)}</span>
        <span class="lui-group-band-name">{@name}</span>
        <span :if={not is_nil(@count)} class="lui-group-band-count">{@count}</span>
      </span>
      <%= for action <- @action do %>
        <.link
          :if={action[:navigate] || action[:patch] || action[:href]}
          class={Class.merge(["lui-group-band-action", action[:class]])}
          navigate={action[:navigate]}
          patch={action[:patch]}
          href={action[:href]}
          aria-label={action[:label]}
        >
          {render_slot(action)}
        </.link>
        <span
          :if={!(action[:navigate] || action[:patch] || action[:href])}
          class={Class.merge(["lui-group-band-action", action[:class]])}
        >
          {render_slot(action)}
        </span>
      <% end %>
    </div>
    """
  end
end
