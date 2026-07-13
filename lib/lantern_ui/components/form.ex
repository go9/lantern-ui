defmodule LanternUI.Components.Form do
  @moduledoc """
  Form chrome — `label`, `error`, and a Fluxon-compatible `input`.

      <.input field={@form[:email]} label="Email" help_text="Used for billing." />
      <.input name="q" value="" placeholder="Search…">
        <:inner_prefix><.icon name="magnifying-glass" /></:inner_prefix>
      </.input>

  `input/1` mirrors Fluxon's surface: `field` (a `Phoenix.HTML.FormField`) or
  explicit `name`/`value`, plus `label`, `sublabel`, `description`, `help_text`,
  `errors`, `size`, and the four `inner/outer_prefix/suffix` slots. Styling is
  LanternUI's shadcn-density look; errors flip the border to danger and get
  announced via `aria-describedby`/`aria-invalid`.
  """

  use Phoenix.Component

  alias LanternUI.Class

  @sizes ~w(xs sm md lg xl)

  attr(:for, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class={Class.merge(["lui-label", @class])} {@rest}>
      {render_slot(@inner_block)}
      <span :if={@sublabel} class="lui-sublabel">{@sublabel}</span>
    </label>
    """
  end

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class={Class.merge(["lui-error", @class])} {@rest}>
      <LanternUI.Components.Icon.icon name="exclamation-circle" class="lui-error-icon" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr(:id, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:sublabel, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:description, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:size, :string, default: "md", values: @sizes)
  attr(:disabled, :boolean, default: false)
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:value, :any, default: nil)
  attr(:name, :any, default: nil)
  attr(:errors, :list, default: [])
  attr(:type, :string, default: "text")

  attr(:rest, :global,
    include: ~w(placeholder autocomplete autofocus readonly required min max step
                minlength maxlength pattern inputmode list form)
  )

  slot(:inner_prefix)
  slot(:outer_prefix)
  slot(:inner_suffix)
  slot(:outer_suffix)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(assigns) do
    assigns = assign(assigns, :invalid?, assigns.errors != [])

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div class="lui-input-row">
        <span :for={slot <- @outer_prefix} class="lui-outer-affix">{render_slot(slot)}</span>

        <div class="lui-input-wrap" data-invalid={@invalid?} data-disabled={@disabled}>
          <span :for={slot <- @inner_prefix} class="lui-inner-affix">{render_slot(slot)}</span>
          <input
            type={@type}
            id={@id}
            name={@name}
            value={Phoenix.HTML.Form.normalize_value(@type, @value)}
            disabled={@disabled}
            class="lui-input"
            aria-invalid={@invalid? && "true"}
            aria-describedby={@invalid? && "#{@id}-error"}
            {@rest}
          />
          <span :for={slot <- @inner_suffix} class="lui-inner-affix">{render_slot(slot)}</span>
        </div>

        <span :for={slot <- @outer_suffix} class="lui-outer-affix">{render_slot(slot)}</span>
      </div>

      <p :if={@help_text && !@invalid?} class="lui-help">{@help_text}</p>
      <.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</.error>
    </div>
    """
  end

  # Minimal error translation: apply interpolated bindings. Hosts with gettext
  # can pre-translate and pass `errors` explicitly.
  @doc "Interpolate a changeset error tuple into a message string."
  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  def translate_error(msg) when is_binary(msg), do: msg
end
