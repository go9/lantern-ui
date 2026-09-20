defmodule LanternUI.Components.IconButton do
  @moduledoc """
  Deprecated alias of `LanternUI.Components.Button.button/1` with `label` on an
  `icon-*` size. Removed in 0.9.0.

      <.button size="icon" label="Toggle panel" kbd="]">
        <.icon name="view-columns" />
      </.button>
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button
  alias LanternUI.Deprecated

  @variants ~w(ghost outline primary)
  @sizes ~w(sm md lg)

  attr(:label, :string, required: true, doc: "Accessible name and tooltip copy. Required.")

  attr(:kbd, :string,
    default: nil,
    doc: "Optional keyboard hint shown in the tooltip after the label."
  )

  attr(:variant, :string,
    default: "ghost",
    values: @variants,
    doc: "ghost is transparent; outline has a hairline; primary is solid."
  )

  attr(:size, :string,
    default: "md",
    values: @sizes,
    doc: "Maps onto button icon sizes (sm/md/lg)."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:tooltip, :boolean,
    default: true,
    doc: "Wrap with `tooltip/1`. Turn off when the parent already tips."
  )

  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; renders as a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; renders as a link.")
  attr(:href, :any, default: nil, doc: "External/full-page href; renders as a link.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the button.")

  attr(:rest, :global,
    include: ~w(id type form name value),
    doc: "HTML/`phx-*` attrs on the button."
  )

  slot(:inner_block, required: true, doc: "The icon.")

  @deprecated "Use button/1 with size=\"icon\" and label. Removed in 0.9.0."
  def icon_button(assigns) do
    Deprecated.warn(:icon_button, ~s|<.button size="icon" label={...}>|)

    assigns =
      assigns
      |> assign(:btn_variant, btn_variant(assigns.variant))
      |> assign(:btn_size, btn_size(assigns.size))
      |> assign(:btn_class, Class.merge(["lui-icon-btn", assigns.class]))

    ~H"""
    <Button.button
      :if={@tooltip}
      class={@btn_class}
      variant={@btn_variant}
      size={@btn_size}
      disabled={@disabled}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      label={@label}
      kbd={@kbd}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Button.button>
    <Button.button
      :if={!@tooltip}
      class={@btn_class}
      variant={@btn_variant}
      size={@btn_size}
      disabled={@disabled}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Button.button>
    """
  end

  defp btn_variant("primary"), do: "solid"
  defp btn_variant(other), do: other

  defp btn_size("sm"), do: "icon-sm"
  defp btn_size("lg"), do: "icon-lg"
  defp btn_size(_), do: "icon"
end
