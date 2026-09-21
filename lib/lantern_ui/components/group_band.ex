defmodule LanternUI.Components.GroupBand do
  @moduledoc """
  Tinted full-width group header: chevron · glyph · name · count · trailing
  action (the `+`).

      <.group_band name="In progress" count={12} group="tickets:in_progress">
        <:glyph><.status_glyph status={:in_progress} /></:glyph>
        <:action navigate="/tickets/new?status=in_progress" label="New ticket in In progress">
          <.icon name="plus" />
        </:action>
      </.group_band>

      <.group_band name="Done" count={40} collapsed patch="/tickets?show_done=1">
        <:glyph><.status_glyph status={:done} /></:glyph>
      </.group_band>

  Pass `group` (and no `navigate`/`patch`/`href`) to make the name row a
  client-side collapse control: `data-lantern-collapse` plus `aria-expanded`.
  Matching `[data-lantern-group]` nodes in the collapse scope hide (see
  `list_row/1` and `docs/behaviours.md`). Put `data-lantern-persist` on the
  band with the same key so the collapsed set survives LiveView patches.

  A collapsed band with `navigate`/`patch`/`href` stays a link (chevron points
  right). Interactive bands always render the down chevron; CSS rotates it
  when `[data-collapsed]` is set so a client toggle needs no re-render.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon

  attr(:name, :string, required: true, doc: "Group label (status name, section title).")
  attr(:count, :any, default: nil, doc: "Optional count shown after the name.")
  attr(:collapsed, :boolean, default: false, doc: "When true, chevron points right.")

  attr(:group, :string,
    default: nil,
    doc: "Collapse key. Renders the name row as a button when there is no link target."
  )

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
    link? = assigns.navigate || assigns.patch || assigns.href
    collapse? = collapse?(assigns.group, link?)

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:collapse?, collapse?)
      |> assign(
        :chevron,
        if(assigns.collapsed and not collapse?, do: "chevron-right", else: "chevron-down")
      )

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
      <button
        :if={@collapse?}
        type="button"
        class="lui-group-band-main"
        aria-expanded={to_string(not @collapsed)}
        data-lantern-collapse={@group}
      >
        <span class="lui-group-band-chevron" aria-hidden="true">
          <Icon.icon name={@chevron} />
        </span>
        <span :if={@glyph != []} class="lui-group-band-glyph">{render_slot(@glyph)}</span>
        <span class="lui-group-band-name">{@name}</span>
        <span :if={not is_nil(@count)} class="lui-group-band-count">{@count}</span>
      </button>
      <span :if={!@link? and !@collapse?} class="lui-group-band-main">
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

  defp collapse?(group, link?) when is_binary(group), do: group != "" and !link?
  defp collapse?(_group, _link?), do: false
end
