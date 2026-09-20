defmodule LanternUI.Components.Segmented do
  @moduledoc """
  Compact segmented control (All · Active · Backlog). Not tabs — there is no
  panel. Arrow keys move and activate the next segment.

      <.segmented id="scope" value={@scope} aria-label="View">
        <:segment value="all" patch={~p"/tickets"}>All</:segment>
        <:segment value="active" patch={~p"/tickets?scope=active"}>Active</:segment>
        <:segment value="backlog" phx-click="set_scope" phx-value="backlog">Backlog</:segment>
      </.segmented>
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:id, :string, required: true, doc: "Stable id for the `LanternSegmented` hook.")
  attr(:value, :any, default: nil, doc: "Value of the active segment (atom or string).")
  attr(:size, :string, default: "sm", values: ~w(sm md), doc: "Control density.")

  attr(:label, :string,
    default: nil,
    doc: "Accessible name of the group (aria-label). Prefer this over a visual legend."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the group.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")

  slot :segment,
    required: true,
    doc: "One segment; link via patch/navigate/href or button via phx-click." do
    attr(:value, :any, required: true)
    attr(:patch, :string)
    attr(:navigate, :string)
    attr(:href, :any)
    attr(:disabled, :boolean)
    attr(:class, :any)
    attr(:"phx-click", :string)
    attr(:"phx-value", :string)
    attr(:"phx-target", :any)
  end

  def segmented(assigns) do
    current = token(assigns.value)
    has_current? = not is_nil(current)

    items =
      assigns.segment
      |> Enum.with_index()
      |> Enum.map(fn {segment, index} ->
        active? = has_current? and token(segment[:value]) == current

        {segment,
         %{
           active?: active?,
           link?: segment[:patch] || segment[:navigate] || segment[:href],
           tabindex: tab_index(active?, index, has_current?)
         }}
      end)

    assigns = assign(assigns, :items, items)

    ~H"""
    <div
      id={@id}
      class={Class.merge(["lui-segmented", @class])}
      data-size={@size}
      role="radiogroup"
      aria-label={@label}
      phx-hook="LanternSegmented"
      {@rest}
    >
      <%= for {segment, meta} <- @items do %>
        <.link
          :if={meta.link?}
          class={
            Class.merge([
              "lui-segmented-item",
              meta.active? && "lui-segmented-item-active",
              segment[:class]
            ])
          }
          data-part="segment"
          data-value={token(segment[:value])}
          role="radio"
          aria-checked={to_string(meta.active?)}
          aria-disabled={segment[:disabled] && "true"}
          tabindex={meta.tabindex}
          patch={segment[:patch]}
          navigate={segment[:navigate]}
          href={segment[:href]}
        >
          {render_slot(segment)}
        </.link>
        <button
          :if={!meta.link?}
          type="button"
          class={
            Class.merge([
              "lui-segmented-item",
              meta.active? && "lui-segmented-item-active",
              segment[:class]
            ])
          }
          data-part="segment"
          data-value={token(segment[:value])}
          role="radio"
          aria-checked={to_string(meta.active?)}
          disabled={segment[:disabled]}
          tabindex={meta.tabindex}
          phx-click={segment[:"phx-click"]}
          phx-value-segment={segment[:"phx-value"] || token(segment[:value])}
          phx-target={segment[:"phx-target"]}
        >
          {render_slot(segment)}
        </button>
      <% end %>
    </div>
    """
  end

  defp token(nil), do: nil
  defp token(value) when is_atom(value), do: Atom.to_string(value)
  defp token(value) when is_binary(value), do: value
  defp token(value), do: to_string(value)

  # Active segment is in the tab order; if nothing is selected, the first one is.
  defp tab_index(true, _index, _has_current?), do: "0"
  defp tab_index(_active?, 0, false), do: "0"
  defp tab_index(_active?, _index, _has_current?), do: "-1"
end
