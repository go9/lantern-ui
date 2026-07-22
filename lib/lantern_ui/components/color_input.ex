defmodule LanternUI.Components.ColorInput do
  @moduledoc """
  Native color picker paired with a hex readout. Mirrors Fluxon's `color_input/1`
  and matches `Form.input` chrome (label, description, help, errors).

      <.color_input field={@form[:brand]} label="Brand color" />
      <.color_input name="theme[primary]" value="#4f46e5" label="Primary" />

  Renders a real `<input type="color">` as the submitted control (styled as a
  swatch) alongside a read-only monospace hex display, so it works with no JS.
  The public surface — `field`/`name`/`value`, `label`/`sublabel`/`description`,
  `help_text`, `errors`, `size`, `disabled` — matches the sibling inputs, so a
  `use Fluxon` app can swap imports without template changes.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Form

  @sizes ~w(xs sm md lg xl)

  attr(:id, :any, default: nil, doc: "Element id; derived from field when omitted.")
  attr(:name, :any, default: nil, doc: "Form input name; derived from field when omitted.")
  attr(:value, :any, default: nil, doc: "Current color as a `#rrggbb` hex string.")
  attr(:label, :string, default: nil, doc: "Primary label above the control.")
  attr(:sublabel, :string, default: nil, doc: "Secondary label line under the primary label.")
  attr(:description, :string, default: nil, doc: "Helper text under the label stack.")

  attr(:help_text, :string,
    default: nil,
    doc: "Trailing help line under the field when no errors."
  )

  attr(:errors, :list, default: [], doc: "Validation messages; derived from field when used.")
  attr(:size, :string, default: "md", values: @sizes, doc: "Control density / type scale.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root element.")

  attr(:field, Phoenix.HTML.FormField,
    default: nil,
    doc: "Form field; derives id, name, value, and errors."
  )

  attr(:disabled, :boolean, default: false, doc: "Render disabled and non-interactive.")

  attr(:rest, :global,
    include: ~w(autofocus required form list phx-change phx-blur phx-focus phx-target),
    doc: "Arbitrary HTML/`phx-*` attributes passed through to the color input."
  )

  def color_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(:field, nil)
    |> assign(:id, assigns.id || field.id)
    |> assign(:name, assigns.name || field.name)
    |> assign(:value, assigns.value || field.value)
    |> assign(:errors, Enum.map(errors, &Form.translate_error/1))
    |> color_input()
  end

  def color_input(assigns) do
    assigns = assign(assigns, :invalid?, assigns.errors != [])

    ~H"""
    <div class={Class.merge(["lui-field", @class])} data-size={@size}>
      <Form.label :if={@label} for={@id} sublabel={@sublabel}>{@label}</Form.label>
      <p :if={@description} class="lui-description">{@description}</p>

      <div class="lui-color-wrap" data-invalid={@invalid? || nil} data-disabled={@disabled || nil}>
        <input
          type="color"
          id={@id}
          name={@name}
          value={@value}
          disabled={@disabled}
          class="lui-color-swatch"
          aria-invalid={@invalid? && "true"}
          aria-describedby={@invalid? && @id && "#{@id}-error"}
          {@rest}
        />
        <input
          type="text"
          value={@value}
          class="lui-color-hex"
          readonly
          tabindex="-1"
          aria-hidden="true"
        />
      </div>

      <p :if={@help_text && !@invalid?} class="lui-help">{@help_text}</p>
      <Form.error :for={msg <- @errors} id={@id && "#{@id}-error"}>{msg}</Form.error>
    </div>
    """
  end
end
