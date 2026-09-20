defmodule LanternUI.Components.Segmented do
  @moduledoc """
  Deprecated alias of `LanternUI.Components.Tabs.tabs_list/1` with
  `variant="segmented"`. Removed in 0.9.0.

      <.tabs_list id="scope" variant="segmented" size="sm" active_tab={@scope} aria-label="View">
        <:tab name="all" patch={~p"/tickets"}>All</:tab>
        <:tab name="active" patch={~p"/tickets?scope=active"}>Active</:tab>
      </.tabs_list>
  """
  use Phoenix.Component

  alias LanternUI.Components.Tabs
  alias LanternUI.Deprecated

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

  @deprecated "Use tabs_list/1 with variant=\"segmented\". Removed in 0.9.0."
  def segmented(assigns) do
    Deprecated.warn(:segmented, ~s|<.tabs_list variant="segmented"> with <:tab> slots|)

    assigns = assign(assigns, :active_tab, token(assigns.value))

    ~H"""
    <Tabs.tabs_list
      id={@id}
      active_tab={@active_tab}
      variant="segmented"
      size={@size}
      class={@class}
      role="radiogroup"
      aria-label={@label}
      phx-hook="LanternSegmented"
      {@rest}
    >
      <:tab
        :for={segment <- @segment}
        name={token(segment[:value])}
        patch={segment[:patch]}
        navigate={segment[:navigate]}
        href={segment[:href]}
        disabled={segment[:disabled]}
        class={segment[:class]}
        phx-click={segment[:"phx-click"]}
        phx-value-tab={segment[:"phx-value"] || token(segment[:value])}
        phx-target={segment[:"phx-target"]}
      >
        {render_slot(segment)}
      </:tab>
    </Tabs.tabs_list>
    """
  end

  defp token(nil), do: nil
  defp token(value) when is_atom(value), do: Atom.to_string(value)
  defp token(value) when is_binary(value), do: value
  defp token(value), do: to_string(value)
end
