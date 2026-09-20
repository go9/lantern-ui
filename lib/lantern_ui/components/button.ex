defmodule LanternUI.Components.Button do
  @moduledoc """
  Buttons — Fluxon-compatible API, shadcn-caliber styling.

      <.button>Save</.button>
      <.button variant="solid">Deploy</.button>
      <.button variant="solid" color="danger">Delete</.button>
      <.button size="icon"><.icon name="plus" /></.button>
      <.button size="icon" label="Toggle panel" kbd="]">
        <.icon name="view-columns" />
      </.button>

  The API mirrors Fluxon's `button/1` (`color` × `variant` × `size`), so a
  consumer migrates by swapping imports. Styling is LanternUI's own: token-driven
  (`--lantern-*`), 32px `md` control height, hairline borders, coral focus ring.

  Colors set a per-button `--lui-c` custom property; variants derive their
  background/border/text from it, so every color works with every variant
  without a compiled class matrix.

  `label` is the accessible name. On `icon-*` sizes it also wraps the control
  in `tooltip/1` (with optional `kbd`), the same chrome `icon_button/1` used.
  """

  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Tooltip

  @colors ~w(primary danger warning success info)
  @variants ~w(solid soft surface outline dashed ghost)
  @sizes ~w(xs sm md lg xl icon-xs icon-sm icon-md icon icon-lg icon-xl)

  attr(:color, :string,
    default: "primary",
    values: @colors,
    doc: "Semantic color token for the button surface."
  )

  attr(:variant, :string,
    default: "outline",
    values: @variants,
    doc: "Surface style: solid fills, outline borders, ghost is transparent."
  )

  attr(:size, :string,
    default: "md",
    values: @sizes,
    doc: "Control height; icon-* sizes are square."
  )

  attr(:label, :string,
    default: nil,
    doc: """
    Accessible name (`aria-label`). On `icon-*` sizes the control is also
    wrapped in `tooltip/1` with this copy.
    """
  )

  attr(:kbd, :string,
    default: nil,
    doc: "Optional keyboard hint shown in the tooltip after `label`."
  )

  attr(:disabled, :boolean,
    default: false,
    doc: """
    Render disabled and non-interactive. A `<button>` gets the real `disabled`
    attribute; a link (`navigate`/`patch`/`href`) has no such attribute, so it
    gets `data-disabled` + `aria-disabled="true"` + `tabindex="-1"` — CSS then
    removes pointer events, matching the `<button>` behavior.
    """
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:navigate, :string, default: nil, doc: "LiveView navigate target; renders as a link.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target; renders as a link.")
  attr(:href, :any, default: nil, doc: "External/full-page href; renders as a link.")

  attr(:rest, :global,
    include: ~w(type form name value method download target rel),
    default: %{"data-part" => "button"},
    doc: "Arbitrary HTML/`phx-*` attributes passed through."
  )

  slot(:inner_block, required: true, doc: "Button label or content.")

  def button(assigns) do
    assigns =
      assigns
      |> assign(:computed_class, Class.merge(["lui-btn", assigns.class]))
      |> assign(:link?, !!(assigns.navigate || assigns.patch || assigns.href))
      |> assign(:tip?, icon_tip?(assigns.label, assigns.size))

    ~H"""
    <Tooltip.tooltip :if={@tip?} placement="bottom" class="lui-icon-btn-tip">
      <:content>
        <span>{@label}</span>
        <kbd :if={@kbd} class="lui-icon-btn-kbd">{@kbd}</kbd>
      </:content>
      <.link
        :if={@link?}
        class={@computed_class}
        data-variant={@variant}
        data-color={@color}
        data-size={@size}
        data-disabled={@disabled || nil}
        aria-disabled={@disabled && "true"}
        tabindex={@disabled && "-1"}
        navigate={@navigate}
        patch={@patch}
        href={@href}
        aria-label={@label}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.link>
      <button
        :if={!@link?}
        class={@computed_class}
        data-variant={@variant}
        data-color={@color}
        data-size={@size}
        disabled={@disabled}
        aria-label={@label}
        {@rest}
      >
        {render_slot(@inner_block)}
      </button>
    </Tooltip.tooltip>
    <.link
      :if={!@tip? and @link?}
      class={@computed_class}
      data-variant={@variant}
      data-color={@color}
      data-size={@size}
      data-disabled={@disabled || nil}
      aria-disabled={@disabled && "true"}
      tabindex={@disabled && "-1"}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@tip? and not @link?}
      class={@computed_class}
      data-variant={@variant}
      data-color={@color}
      data-size={@size}
      disabled={@disabled}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Groups buttons into a single segmented control (shared borders, joined radius).
  """
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through.")
  slot(:inner_block, required: true, doc: "Buttons to join into a segmented group.")

  def button_group(assigns) do
    ~H"""
    <div class={Class.merge(["lui-btn-group", @class])} role="group" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp icon_tip?(label, size) when is_binary(label) and is_binary(size),
    do: String.starts_with?(size, "icon")

  defp icon_tip?(_label, _size), do: false
end
