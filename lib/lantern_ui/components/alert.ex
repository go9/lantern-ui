defmodule LanternUI.Components.Alert do
  @moduledoc """
  Inline status alert. Mirrors Fluxon's `alert/1` surface.

      <.alert color="success" title="Saved">Your changes were stored.</.alert>
      <.alert color="warning" title="Unsaved" hide_close={false}>
        Discard or save before leaving.
      </.alert>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Icon
  alias Phoenix.LiveView.JS

  attr(:id, :string, default: nil, doc: "Element id; auto-generated when omitted.")
  attr(:title, :string, default: nil, doc: "Primary heading shown next to the icon.")
  attr(:subtitle, :string, default: nil, doc: "Secondary line under the title.")

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral info success warning danger),
    doc: "Semantic color; also picks the default status icon."
  )

  attr(:hide_icon, :boolean, default: false, doc: "Omit the leading status icon.")
  attr(:hide_close, :boolean, default: true, doc: "Hide the dismiss button (default).")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:icon, doc: "Custom leading icon; overrides the color default.")
  slot(:inner_block, doc: "Alert body content below the title.")

  def alert(assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "lui-alert-#{System.unique_integer([:positive])}" end)
      |> assign(:icon_name, default_icon(assigns.color))

    ~H"""
    <div
      id={@id}
      role="alert"
      class={Class.merge(["lui-alert", @class])}
      data-color={@color}
      {@rest}
    >
      <div :if={!@hide_icon} class="lui-alert-icon">
        <%= if @icon != [] do %>
          {render_slot(@icon)}
        <% else %>
          <Icon.icon name={@icon_name} />
        <% end %>
      </div>

      <div class="lui-alert-body">
        <strong :if={@title} class="lui-alert-title">{@title}</strong>
        <p :if={@subtitle} class="lui-alert-subtitle">{@subtitle}</p>
        {render_slot(@inner_block)}
      </div>

      <button
        :if={!@hide_close}
        type="button"
        class="lui-alert-close"
        aria-label="Close"
        phx-click={JS.hide(to: "##{@id}")}
      >
        <Icon.icon name="x-mark" />
      </button>
    </div>
    """
  end

  defp default_icon("success"), do: "check-circle"
  defp default_icon("warning"), do: "exclamation-circle"
  defp default_icon("danger"), do: "exclamation-circle"
  defp default_icon(_), do: "information-circle"
end
